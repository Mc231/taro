/// The deck content pipeline `tools/content` (01 §11, Phase 5 Sprint 5.2):
/// `validate`, `build`, `translate`, `sync_check` and `placeholder_art` over
/// `apps/taro/content/source/` (format: that folder's README.md; schemas:
/// `tools/content/schema/`).
///
/// Each command is a function that takes the command-line arguments and
/// returns the exit code: 0 = OK, 1 = findings or failure, 64 = usage error.
/// `bin/content_*.dart` are thin entry points; `tools/content/<command>`
/// are the shell wrappers.
library;

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:args/args.dart';
import 'package:taro_dart_tools/src/content/banned.dart';
import 'package:taro_dart_tools/src/content/builder.dart';
import 'package:taro_dart_tools/src/content/claude_client.dart';
import 'package:taro_dart_tools/src/content/common.dart';
import 'package:taro_dart_tools/src/content/ids.dart';
import 'package:taro_dart_tools/src/content/placeholder_art.dart';
import 'package:taro_dart_tools/src/content/source.dart';
import 'package:taro_dart_tools/src/content/sync_check.dart';
import 'package:taro_dart_tools/src/content/translate.dart';
import 'package:taro_dart_tools/src/content/validator.dart';

export 'src/content/banned.dart';
export 'src/content/builder.dart';
export 'src/content/claude_client.dart';
export 'src/content/common.dart';
export 'src/content/ids.dart';
export 'src/content/pixel_font.dart';
export 'src/content/placeholder_art.dart';
export 'src/content/source.dart';
export 'src/content/sync_check.dart';
export 'src/content/text_rules.dart';
export 'src/content/translate.dart';
export 'src/content/validator.dart';
export 'src/content/yaml_writer.dart';

/// I/O and environment of one command run (injected by tests).
final class ContentIo {
  /// Creates the context; every field defaults to the real process.
  ContentIo({
    StringSink? out,
    StringSink? err,
    Directory? cwd,
    DateTime Function()? clock,
    Map<String, String>? environment,
  }) : out = out ?? stdout,
       err = err ?? stderr,
       cwd = cwd ?? Directory.current,
       clock = clock ?? DateTime.now,
       environment = environment ?? Platform.environment;

  /// Normal output.
  final StringSink out;

  /// Errors.
  final StringSink err;

  /// Where the repository root search starts.
  final Directory cwd;

  /// The current time.
  final DateTime Function() clock;

  /// Environment variables (ANTHROPIC_API_KEY).
  final Map<String, String> environment;

  /// Today's UTC date.
  DateTime get today => clock().toUtc();
}

ArgParser _parser() => ArgParser()
  ..addOption('repo-root', help: 'Repository root (default: search upward).')
  ..addFlag('help', abbr: 'h', negatable: false, help: 'Show this help.');

/// Parses [args]; returns the results or an exit code after printing.
(ArgResults?, int?) _parse(
  ArgParser parser,
  List<String> args,
  String name,
  String summary,
  ContentIo io,
) {
  try {
    final results = parser.parse(args);
    if (results.flag('help')) {
      io.out
        ..writeln('Usage: tools/content/$name [options]\n\n$summary\n')
        ..writeln(parser.usage);
      return (null, 0);
    }
    if (results.rest.isNotEmpty) {
      throw FormatException('unexpected argument "${results.rest.first}"');
    }
    return (results, null);
  } on FormatException catch (e) {
    io.err
      ..writeln('content $name: ${e.message}')
      ..writeln(parser.usage);
    return (null, 64);
  }
}

Directory? _root(ArgResults results, String name, ContentIo io) {
  final given = results.option('repo-root');
  final root = given != null ? Directory(given) : findRepoRoot(io.cwd);
  if (root == null || !Directory('${root.path}/docs/specs').existsSync()) {
    io.err.writeln('content $name: no repository root (docs/specs) found');
    return null;
  }
  return root;
}

BannedPhrases? _banned(Directory root, String name, ContentIo io) {
  try {
    if (!File('${root.path}/$kBannedPhrasesPath').existsSync()) {
      io.err.writeln('content $name: $kBannedPhrasesPath is missing');
      return null;
    }
    final required = File('${root.path}/$kRequiredSentencesPath');
    return BannedPhrases.parse(
      readYaml(root, kBannedPhrasesPath),
      required.existsSync() ? readYaml(root, kRequiredSentencesPath) : null,
    );
  } on ContentFormatException catch (e) {
    io.err.writeln('content $name: $e');
    return null;
  }
}

Set<String>? _arbKeys(Directory root) {
  final file = File('${root.path}/apps/taro/lib/l10n/arb/app_en.arb');
  if (!file.existsSync()) return null;
  try {
    final value = jsonDecode(file.readAsStringSync());
    return value is Map<String, Object?> ? value.keys.toSet() : null;
  } on FormatException {
    return null;
  }
}

void _printReport(ValidationResult result, ContentIo io) {
  final reports = result.reports;
  final byLocale = <String, List<Issue>>{};
  for (final r in reports) {
    (byLocale[r.locale ?? '-'] ??= []).add(r);
  }
  for (final MapEntry(key: locale, value: lines) in byLocale.entries) {
    io.out.writeln('report [$locale]: ${lines.length} item(s)');
    for (final line in lines) {
      io.out.writeln('  ${line.path}: ${line.message}');
    }
  }
}

/// `tools/content/validate [--release] [--strict-locales] [--print-hashes]`.
int runContentValidate(List<String> args, {ContentIo? io}) {
  final ctx = io ?? ContentIo();
  final parser = _parser()
    ..addFlag(
      'release',
      negatable: false,
      help: 'Fail on crisis entries unverified or older than 200 days.',
    )
    ..addFlag(
      'strict-locales',
      negatable: false,
      help: 'Missing or stale translations are errors (Phase 18).',
    )
    ..addFlag(
      'print-hashes',
      negatable: false,
      help: 'Print the sourceHash of every en card, spreads and article.',
    );
  final (results, code) = _parse(
    parser,
    args,
    'validate',
    'Checks apps/taro/content/source/ (README.md there has the rules).',
    ctx,
  );
  if (results == null) return code!;
  final root = _root(results, 'validate', ctx);
  if (root == null) return 1;
  final banned = _banned(root, 'validate', ctx);
  if (banned == null) return 1;
  final source = ContentSource.load(root);
  final result = validate(
    source,
    banned,
    ValidateOptions(
      today: ctx.today,
      release: results.flag('release'),
      strictLocales: results.flag('strict-locales'),
      arbKeys: _arbKeys(root),
    ),
  );
  if (results.flag('print-hashes')) _printHashes(source, ctx);
  _printReport(result, ctx);
  final errors = result.errors..forEach(ctx.err.writeln);
  if (errors.isNotEmpty) {
    ctx.err.writeln('content validate: ${errors.length} error(s)');
    return 1;
  }
  final complete = result.completeLocales;
  ctx.out.writeln(
    'content validate: OK (complete locales: '
    '${complete.isEmpty ? 'none' : complete.join(', ')}; '
    '${result.reports.length} report item(s))',
  );
  return 0;
}

void _printHashes(ContentSource source, ContentIo io) {
  final en = source.cards[kSourceLocale] ?? const {};
  for (final id in kCardIds) {
    final card = en[id];
    if (card is Map<String, Object?>) {
      io.out.writeln('hash en/cards/$id.yaml ${cardSourceHash(card)}');
    }
  }
  final spreads = source.spreads[kSourceLocale];
  if (spreads is Map<String, Object?>) {
    io.out.writeln('hash en/spreads.yaml ${spreadsSourceHash(spreads)}');
  }
  for (final MapEntry(key: id, value: article)
      in (source.articles[kSourceLocale] ?? const <String, Article>{})
          .entries) {
    io.out.writeln(
      'hash en/articles/$id.md ${articleSourceHash(article.body)}',
    );
  }
}

/// `tools/content/build [--check]`.
int runContentBuild(List<String> args, {ContentIo? io}) {
  final ctx = io ?? ContentIo();
  final parser = _parser()
    ..addFlag(
      'check',
      negatable: false,
      help: 'Write nothing; fail when a generated file is out of date.',
    );
  final (results, code) = _parse(
    parser,
    args,
    'build',
    'Validates the source, then writes apps/taro/assets/deck/ and '
        'worker/src/generated/ (deterministic, idempotent).',
    ctx,
  );
  if (results == null) return code!;
  final root = _root(results, 'build', ctx);
  if (root == null) return 1;
  final banned = _banned(root, 'build', ctx);
  if (banned == null) return 1;
  final source = ContentSource.load(root);
  final result = validate(source, banned, ValidateOptions(today: ctx.today));
  if (result.errors.isNotEmpty) {
    result.errors.forEach(ctx.err.writeln);
    ctx.err.writeln(
      'content build: ${result.errors.length} validation error(s); nothing '
      'written',
    );
    return 1;
  }
  final buildPlan = plan(root, compile(source, result.completeLocales));
  if (results.flag('check')) {
    for (final path in buildPlan.write.keys) {
      ctx.err.writeln('out of date: $path');
    }
    for (final path in buildPlan.delete) {
      ctx.err.writeln('stale: $path');
    }
    if (!buildPlan.isClean) {
      ctx.err.writeln('content build --check: run tools/content/build');
      return 1;
    }
    ctx.out.writeln('content build --check: up to date');
    return 0;
  }
  apply(root, buildPlan);
  for (final path in buildPlan.write.keys) {
    ctx.out.writeln('wrote $path');
  }
  for (final path in buildPlan.delete) {
    ctx.out.writeln('deleted $path');
  }
  ctx.out.writeln(
    'content build: ${buildPlan.write.length} written, '
    '${buildPlan.delete.length} deleted, ${buildPlan.unchanged.length} '
    'unchanged (locales: ${result.completeLocales.join(', ')})',
  );
  return 0;
}

/// `tools/content/sync_check`.
int runContentSyncCheck(List<String> args, {ContentIo? io}) {
  final ctx = io ?? ContentIo();
  final (results, code) = _parse(
    _parser(),
    args,
    'sync_check',
    'Checks that the app assets and the Worker feeds agree.',
    ctx,
  );
  if (results == null) return code!;
  final root = _root(results, 'sync_check', ctx);
  if (root == null) return 1;
  final issues = syncCheck(root)..forEach(ctx.err.writeln);
  if (issues.isNotEmpty) {
    ctx.err.writeln('content sync_check: ${issues.length} problem(s)');
    return 1;
  }
  ctx.out.writeln('content sync_check: OK');
  return 0;
}

/// Creates the real client for an API key.
typedef ClaudeClientFactory = ClaudeClient Function(String apiKey);

/// The production client: the Messages API over HTTP.
ClaudeClient defaultClaudeClient(String apiKey) =>
    AnthropicHttpClient(apiKey: apiKey);

/// `tools/content/translate --locale LOCALE [--cards a,b] [--parts …]
/// [--force] [--dry-run] [--model ID]`.
Future<int> runContentTranslate(
  List<String> args, {
  ContentIo? io,
  ClaudeClientFactory? clientFactory,
}) async {
  final ctx = io ?? ContentIo();
  final parser = _parser()
    ..addOption(
      'locale',
      allowed: kTargetLocales,
      help: 'Target locale (required).',
    )
    ..addOption(
      'cards',
      help:
          'Comma-separated card IDs (default: all 78; implies '
          '--parts cards unless --parts is given).',
    )
    ..addMultiOption(
      'parts',
      allowed: [for (final p in TranslatePart.values) p.name],
      help: 'What to translate (default: cards,spreads,articles).',
    )
    ..addFlag(
      'force',
      negatable: false,
      help: 'Also re-translate current (non-stale) files.',
    )
    ..addFlag(
      'dry-run',
      negatable: false,
      help: 'Print the plan; no API call.',
    )
    ..addOption(
      'model',
      defaultsTo: kDefaultTranslateModel,
      help: 'Claude model ID.',
    )
    ..addFlag(
      'allow-unreviewed-glossary',
      negatable: false,
      help: 'Translate although glossary review.<locale> is not reviewed.',
    );
  final (results, code) = _parse(
    parser,
    args,
    'translate',
    'Machine-translates en content into one locale with Claude '
        '(ANTHROPIC_API_KEY from the environment).',
    ctx,
  );
  if (results == null) return code!;
  final locale = results.option('locale');
  if (locale == null) {
    ctx.err.writeln('content translate: --locale is required');
    return 64;
  }
  final cardsArg = results.option('cards');
  final cards = cardsArg
      ?.split(',')
      .map((c) => c.trim())
      .where((c) => c.isNotEmpty)
      .toList();
  final unknown = cards?.where((c) => !kCardIds.contains(c)).toList() ?? [];
  if (unknown.isNotEmpty || (cards != null && cards.isEmpty)) {
    ctx.err.writeln(
      'content translate: unknown card ID(s): ${unknown.join(', ')}',
    );
    return 64;
  }
  final partNames = results.multiOption('parts');
  final parts = partNames.isNotEmpty
      ? {for (final n in partNames) TranslatePart.values.byName(n)}
      : cards != null
      ? {TranslatePart.cards}
      : TranslatePart.values.toSet();
  final root = _root(results, 'translate', ctx);
  if (root == null) return 1;
  final banned = _banned(root, 'translate', ctx);
  if (banned == null) return 1;
  final factory = clientFactory ?? defaultClaudeClient;
  return translate(
    root,
    TranslateOptions(
      locale: locale,
      parts: parts,
      cards: cards,
      force: results.flag('force'),
      dryRun: results.flag('dry-run'),
      model: results.option('model')!,
      allowUnreviewedGlossary: results.flag('allow-unreviewed-glossary'),
    ),
    client: () {
      final key = ctx.environment['ANTHROPIC_API_KEY'];
      return key == null || key.isEmpty ? null : factory(key);
    },
    banned: banned,
    today: ctx.today,
    out: ctx.out,
    err: ctx.err,
  );
}

/// `tools/content/placeholder_art [--check]` (Sprint 5.4).
int runPlaceholderArt(List<String> args, {ContentIo? io}) {
  final ctx = io ?? ContentIo();
  final parser = _parser()
    ..addFlag(
      'check',
      negatable: false,
      help: 'Write nothing; fail when an art file is missing or out of date.',
    );
  final (results, code) = _parse(
    parser,
    args,
    'placeholder_art',
    'Generates the typographic placeholder deck (78 cards + card back) '
        'into $kPlaceholderArtDir/ (deterministic).',
    ctx,
  );
  if (results == null) return code!;
  final root = _root(results, 'placeholder_art', ctx);
  if (root == null) return 1;
  final Map<String, Uint8List> files;
  try {
    files = generatePlaceholderArt(
      englishCardNames(readYaml(root, '$kSourceDir/glossary.yaml')),
    );
  } on ContentFormatException catch (e) {
    ctx.err.writeln('content placeholder_art: $e');
    return 1;
  } on FileSystemException catch (e) {
    ctx.err.writeln('content placeholder_art: ${e.path}: ${e.message}');
    return 1;
  }
  final write = <String>[
    for (final MapEntry(key: path, value: bytes) in files.entries)
      if (!_sameBytes(File('${root.path}/$path'), bytes)) path,
  ];
  final dir = Directory('${root.path}/$kPlaceholderArtDir');
  final stale =
      dir.existsSync()
            ? ([
                for (final f in dir.listSync().whereType<File>())
                  '$kPlaceholderArtDir/${f.uri.pathSegments.last}',
              ]..removeWhere(files.containsKey))
            : <String>[]
        ..sort();
  if (results.flag('check')) {
    for (final path in write) {
      ctx.err.writeln('out of date: $path');
    }
    for (final path in stale) {
      ctx.err.writeln('stale: $path');
    }
    if (write.isNotEmpty || stale.isNotEmpty) {
      ctx.err.writeln(
        'content placeholder_art --check: run tools/content/placeholder_art',
      );
      return 1;
    }
    ctx.out.writeln('content placeholder_art --check: up to date');
    return 0;
  }
  for (final path in write) {
    File('${root.path}/$path')
      ..parent.createSync(recursive: true)
      ..writeAsBytesSync(files[path]!);
    ctx.out.writeln('wrote $path');
  }
  for (final path in stale) {
    File('${root.path}/$path').deleteSync();
    ctx.out.writeln('deleted $path');
  }
  ctx.out.writeln(
    'content placeholder_art: ${write.length} written, ${stale.length} '
    'deleted, ${files.length - write.length} unchanged',
  );
  return 0;
}

bool _sameBytes(File file, Uint8List bytes) {
  if (!file.existsSync()) return false;
  final current = file.readAsBytesSync();
  if (current.length != bytes.length) return false;
  for (var i = 0; i < bytes.length; i++) {
    if (current[i] != bytes[i]) return false;
  }
  return true;
}
