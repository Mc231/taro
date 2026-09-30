/// The design-token pipeline `tools/tokens` (02 §14.1, Phase 15 Sprint 15.1):
/// `generate` turns `docs/design/taro.tokens.json` (W3C DTCG, light and dark
/// modes) into `packages/taro_ui/lib/src/tokens/generated/taro_tokens.g.dart`,
/// and `validate_tokens` checks the file against the 01 §14 contract
/// (names, modes, reduced motion, fonts per script, constraints, contrast).
///
/// Each command takes the command-line arguments and returns the exit code:
/// 0 = OK, 1 = findings or failure, 64 = usage error. `tools/tokens/*.dart`
/// are the thin entry points.
library;

import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:taro_dart_tools/src/content/common.dart' show findRepoRoot;
import 'package:taro_dart_tools/src/tokens/dart_emitter.dart';
import 'package:taro_dart_tools/src/tokens/token_set.dart';
import 'package:taro_dart_tools/src/tokens/validator.dart';

export 'src/tokens/contract.dart';
export 'src/tokens/dart_emitter.dart';
export 'src/tokens/token_set.dart';
export 'src/tokens/token_values.dart';
export 'src/tokens/validator.dart';

/// The token file, relative to the repository root.
const String kTokensPath = 'docs/design/taro.tokens.json';

/// The generated Dart file, relative to the repository root.
const String kTokensDartPath =
    'packages/taro_ui/lib/src/tokens/generated/taro_tokens.g.dart';

/// The package that bundles the token font families.
const String kTokensFontPackage = 'taro_ui';

/// Formats Dart [source]; returns null (and the error) when it cannot.
typedef DartFormatter = (String?, String?) Function(String source);

/// I/O of one command run (injected by tests).
final class TokensIo {
  /// Creates the context; every field defaults to the real process.
  TokensIo({
    StringSink? out,
    StringSink? err,
    Directory? cwd,
    DartFormatter? formatter,
  }) : out = out ?? stdout,
       err = err ?? stderr,
       cwd = cwd ?? Directory.current,
       formatter = formatter ?? formatWithDart;

  /// Normal output.
  final StringSink out;

  /// Errors.
  final StringSink err;

  /// Where the repository root search starts.
  final Directory cwd;

  /// `dart format` (stdin → stdout).
  final DartFormatter formatter;
}

/// The `dart` binary to run `dart format` with: [resolvedExecutable] when
/// it is the Dart VM (`dart run`), else `dart` on the PATH. Under
/// `flutter test` the running executable is `flutter_tester`, which does
/// not understand `format` and never exits.
String dartExecutable(String resolvedExecutable) {
  final name = resolvedExecutable.split(RegExp(r'[/\\]')).last;
  return name == 'dart' || name == 'dart.exe' ? resolvedExecutable : 'dart';
}

/// Runs `dart format` on [source] with the taro_ui language version.
(String?, String?) formatWithDart(String source) {
  final dir = Directory.systemTemp.createTempSync('taro_tokens');
  try {
    final file = File('${dir.path}/taro_tokens.g.dart')
      ..writeAsStringSync(source);
    final result = Process.runSync(
      dartExecutable(Platform.resolvedExecutable),
      ['format', '--language-version=3.9', file.path],
      stdoutEncoding: utf8,
      stderrEncoding: utf8,
    );
    return result.exitCode == 0
        ? (file.readAsStringSync(), null)
        : (null, '${result.stderr}${result.stdout}');
  } finally {
    dir.deleteSync(recursive: true);
  }
}

ArgParser _parser() => ArgParser()
  ..addOption('repo-root', help: 'Repository root (default: search upward).')
  ..addOption('input', help: 'Token file (default: $kTokensPath).')
  ..addFlag('help', abbr: 'h', negatable: false, help: 'Show this help.');

ArgResults? _parse(
  ArgParser parser,
  List<String> args,
  String name,
  String summary,
  TokensIo io,
  void Function(int) exit,
) {
  try {
    final results = parser.parse(args);
    if (results.flag('help')) {
      io.out
        ..writeln('Usage: dart run tools/tokens/$name.dart [options]\n')
        ..writeln('$summary\n')
        ..writeln(parser.usage);
      exit(0);
      return null;
    }
    if (results.rest.isNotEmpty) {
      throw FormatException('unexpected argument "${results.rest.first}"');
    }
    return results;
  } on FormatException catch (e) {
    io.err
      ..writeln('tokens $name: ${e.message}')
      ..writeln(parser.usage);
    exit(64);
    return null;
  }
}

Directory? _root(ArgResults results, String name, TokensIo io) {
  final given = results.option('repo-root');
  final root = given != null ? Directory(given) : findRepoRoot(io.cwd);
  if (root == null || !Directory('${root.path}/docs/specs').existsSync()) {
    io.err.writeln('tokens $name: no repository root (docs/specs) found');
    return null;
  }
  return root;
}

File _resolve(Directory root, String path) =>
    File(path.startsWith('/') ? path : '${root.path}/$path');

/// Reads and parses the token file; prints and returns null on error.
TokenSet? loadTokenSet(File file, String name, TokensIo io) {
  if (!file.existsSync()) {
    io.err.writeln('tokens $name: ${file.path} not found');
    return null;
  }
  try {
    return TokenSet.parse(jsonDecode(file.readAsStringSync()));
  } on FormatException catch (e) {
    io.err.writeln('tokens $name: ${file.path} is not JSON: ${e.message}');
  } on TokenException catch (e) {
    io.err.writeln('tokens $name: $e');
  }
  return null;
}

/// Builds the formatted Dart source for [set], checking the names against
/// [contract] first (02 §14.2: fail on an unknown or missing name).
(String?, List<String>) generateTokensSource(
  TokenSet set, {
  required TokenContract contract,
  required DartFormatter formatter,
  EmitOptions options = const EmitOptions(fontPackage: kTokensFontPackage),
}) {
  final names = checkNames(set, contract);
  if (names.isNotEmpty) return (null, names);
  final String raw;
  try {
    raw = emitTokensDart(set, options: options);
  } on TokenException catch (e) {
    return (null, [e.message]);
  }
  final (formatted, error) = formatter(raw);
  if (formatted == null) return (null, ['dart format failed: $error']);
  return (formatted, const []);
}

/// `dart run tools/tokens/generate.dart [--check] [--input] [--output]`.
int runTokensGenerate(
  List<String> args, {
  TokensIo? io,
  TokenContract? contract,
}) {
  final ctx = io ?? TokensIo();
  var code = 0;
  final parser = _parser()
    ..addOption('output', help: 'Dart file (default: $kTokensDartPath).')
    ..addFlag(
      'check',
      negatable: false,
      help: 'Fail when the generated file is missing or stale (CI).',
    );
  final results = _parse(
    parser,
    args,
    'generate',
    'Generates TaroTokens constants from the DTCG token file (02 §14.1).',
    ctx,
    (c) => code = c,
  );
  if (results == null) return code;
  final root = _root(results, 'generate', ctx);
  if (root == null) return 1;
  final input = results.option('input') ?? kTokensPath;
  final set = loadTokenSet(_resolve(root, input), 'generate', ctx);
  if (set == null) return 1;
  final (source, issues) = generateTokensSource(
    set,
    contract: contract ?? TokenContract.product(),
    formatter: ctx.formatter,
    options: EmitOptions(source: input, fontPackage: kTokensFontPackage),
  );
  if (source == null) {
    for (final issue in issues) {
      ctx.err.writeln('tokens generate: $issue');
    }
    return 1;
  }
  final outPath = results.option('output') ?? kTokensDartPath;
  final output = _resolve(root, outPath);
  if (results.flag('check')) {
    if (!output.existsSync() || output.readAsStringSync() != source) {
      ctx.err.writeln(
        'tokens generate: $outPath is stale; run '
        'dart run tools/tokens/generate.dart',
      );
      return 1;
    }
    ctx.out.writeln('tokens generate: $outPath is current');
    return 0;
  }
  output
    ..createSync(recursive: true)
    ..writeAsStringSync(source);
  ctx.out.writeln(
    'tokens generate: wrote $outPath (${set.tokens.length} tokens)',
  );
  return 0;
}

/// `dart run tools/tokens/validate_tokens.dart [--input]`.
int runTokensValidate(
  List<String> args, {
  TokensIo? io,
  TokenContract? contract,
}) {
  final ctx = io ?? TokensIo();
  var code = 0;
  final results = _parse(
    _parser(),
    args,
    'validate_tokens',
    'Checks the token file against the 01 §14 contract: names in both '
        'modes, reduced motion, fonts per script, constraints and contrast.',
    ctx,
    (c) => code = c,
  );
  if (results == null) return code;
  final root = _root(results, 'validate_tokens', ctx);
  if (root == null) return 1;
  final input = results.option('input') ?? kTokensPath;
  final set = loadTokenSet(_resolve(root, input), 'validate_tokens', ctx);
  if (set == null) return 1;
  final issues = validateTokens(set, contract ?? TokenContract.product());
  for (final issue in issues) {
    ctx.err.writeln('validate_tokens: $issue');
  }
  if (issues.isNotEmpty) {
    ctx.err.writeln('validate_tokens: ${issues.length} issue(s) in $input');
    return 1;
  }
  ctx.out.writeln(
    'validate_tokens: $input OK (${set.tokens.length} tokens, '
    'modes ${set.modes.join('/')})',
  );
  return 0;
}
