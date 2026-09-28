/// Generator for `test/coverage_all_test.dart` (06 QA4, §5.1).
///
/// `flutter test --coverage` only reports files that a test imports, so an
/// untested file would silently leave the denominator. The generated test
/// imports every non-excluded `lib/**.dart` file of a package, which makes
/// untested files count as 0 %.
library;

import 'dart:io';

import 'package:taro_dart_tools/src/coverage_exclusions.dart';

export 'src/coverage_exclusions.dart';

/// Repo-relative path of the generated test inside a package.
const coverageAllTestPath = 'test/coverage_all_test.dart';

/// Repo-relative path of the exclusion list.
const exclusionsPath = 'tools/coverage_exclusions.txt';

const _usage = '''
Usage: dart run tools/dart_tools/bin/gen_coverage_all.dart [options] [<package_dir>]

Writes <package_dir>/test/coverage_all_test.dart importing every lib/**.dart
file not matched by tools/coverage_exclusions.txt (06 QA4).

Options:
  --repo-root <dir>     Repository root (default: nearest ancestor with docs/specs).
  --exclusions <file>   Exclusion list (default: <repo-root>/tools/coverage_exclusions.txt).
  --lcov-patterns       Print the `lcov --remove` patterns for the package, one
                        per line, instead of writing the test.
  -h, --help            Show this help.''';

/// Runs the generator with command-line [args] and returns the exit code
/// (0 ok, 1 failure, 64 usage error). Messages go to [out] and [err].
Future<int> genCoverageAll(
  List<String> args, {
  StringSink? out,
  StringSink? err,
}) async {
  final stdoutSink = out ?? stdout;
  final stderrSink = err ?? stderr;

  final _Options options;
  try {
    options = _Options.parse(args);
  } on FormatException catch (e) {
    stderrSink
      ..writeln('gen_coverage_all: ${e.message}')
      ..writeln(_usage);
    return 64;
  }
  if (options.help) {
    stdoutSink.writeln(_usage);
    return 0;
  }

  final packageDir = Directory(options.packageDir).absolute;
  final pubspec = File('${packageDir.path}/pubspec.yaml');
  if (!pubspec.existsSync()) {
    stderrSink.writeln(
      'gen_coverage_all: no pubspec.yaml in ${packageDir.path}',
    );
    return 1;
  }

  final repoRoot = options.repoRoot != null
      ? Directory(options.repoRoot!).absolute
      : findRepoRoot(packageDir);
  if (repoRoot == null) {
    stderrSink.writeln(
      'gen_coverage_all: no repository root (docs/specs) above '
      '${packageDir.path}; pass --repo-root',
    );
    return 1;
  }

  final exclusionsFile = File(
    options.exclusions ?? '${repoRoot.path}/$exclusionsPath',
  );
  if (!exclusionsFile.existsSync()) {
    stderrSink.writeln(
      'gen_coverage_all: exclusion list not found: ${exclusionsFile.path}',
    );
    return 1;
  }
  final exclusions = CoverageExclusions.parse(
    exclusionsFile.readAsStringSync(),
  );

  final unitPath = relativePath(packageDir.path, repoRoot.path);
  if (unitPath == null) {
    stderrSink.writeln(
      'gen_coverage_all: ${packageDir.path} is not inside ${repoRoot.path}',
    );
    return 1;
  }

  if (options.lcovPatterns) {
    exclusions.lcovPatterns(unitPath).forEach(stdoutSink.writeln);
    return 0;
  }

  final pubspecText = pubspec.readAsStringSync();
  final name = packageName(pubspecText);
  if (name == null) {
    stderrSink.writeln('gen_coverage_all: no `name:` in ${pubspec.path}');
    return 1;
  }

  final libFiles = coveredLibFiles(packageDir, unitPath, exclusions);
  final content = renderCoverageAll(
    packageName: name,
    libFiles: libFiles,
    useFlutterTest: usesFlutterTest(pubspecText),
  );
  File('${packageDir.path}/$coverageAllTestPath')
    ..parent.createSync(recursive: true)
    ..writeAsStringSync(content);
  stdoutSink.writeln(
    'gen_coverage_all: $unitPath/$coverageAllTestPath imports '
    '${libFiles.length} file(s)',
  );
  return 0;
}

/// Returns the nearest ancestor of [start] (inclusive) that holds
/// `docs/specs`, or null.
Directory? findRepoRoot(Directory start) {
  var current = start.absolute;
  while (true) {
    if (Directory('${current.path}/docs/specs').existsSync()) return current;
    final parent = current.parent;
    if (parent.path == current.path) return null;
    current = parent;
  }
}

/// The forward-slash path of [path] relative to [root], or null when [path]
/// is outside [root]. Returns `.` for the root itself.
String? relativePath(String path, String root) {
  final p = _normalize(path);
  final r = _normalize(root);
  if (p == r) return '.';
  if (!p.startsWith('$r/')) return null;
  return p.substring(r.length + 1);
}

String _normalize(String path) {
  var p = path.replaceAll(r'\', '/');
  final segments = <String>[];
  for (final s in p.split('/')) {
    if (s == '.' || (s.isEmpty && segments.isNotEmpty)) continue;
    if (s == '..' && segments.length > 1) {
      segments.removeLast();
      continue;
    }
    segments.add(s);
  }
  p = segments.join('/');
  return p.isEmpty ? '/' : p;
}

/// Reads the package `name:` from pubspec text.
String? packageName(String pubspec) {
  final match = RegExp(
    r'^name:\s*([A-Za-z_][A-Za-z0-9_]*)\s*$',
    multiLine: true,
  ).firstMatch(pubspec);
  return match?.group(1);
}

/// Whether the package tests with `flutter_test` rather than `package:test`.
bool usesFlutterTest(String pubspec) =>
    RegExp(r'^\s+flutter_test:', multiLine: true).hasMatch(pubspec);

/// Lib-relative paths (for example `src/a.dart`) of every Dart file under
/// `lib/` that is not excluded and is not a `part of` file, sorted.
List<String> coveredLibFiles(
  Directory packageDir,
  String unitPath,
  CoverageExclusions exclusions,
) {
  final lib = Directory('${packageDir.path}/lib');
  if (!lib.existsSync()) return const [];
  final prefix = unitPath == '.' ? '' : '$unitPath/';
  final result = <String>[];
  for (final entity in lib.listSync(recursive: true, followLinks: false)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    final libRelative = relativePath(entity.path, lib.path)!;
    if (exclusions.matches('${prefix}lib/$libRelative')) continue;
    if (_isPartFile(entity.readAsStringSync())) continue;
    result.add(libRelative);
  }
  return result..sort();
}

bool _isPartFile(String source) =>
    RegExp(r'^\s*part\s+of\b', multiLine: true).hasMatch(source);

/// Renders the generated test file, already `dart format`ted and with
/// imports in `directives_ordering` order.
String renderCoverageAll({
  required String packageName,
  required List<String> libFiles,
  required bool useFlutterTest,
}) {
  final testImport = useFlutterTest
      ? 'package:flutter_test/flutter_test.dart'
      : 'package:test/test.dart';
  final imports = <String>[
    for (var i = 0; i < libFiles.length; i++)
      _importLine("'package:$packageName/${libFiles[i]}'", ' as i$i;'),
    _importLine("'$testImport'", ';'),
  ]..sort();
  final buf = StringBuffer()
    ..writeln(
      '// GENERATED by tools/dart_tools/bin/gen_coverage_all.dart '
      '(06 QA4). Do not edit.',
    )
    ..writeln(
      '// Imports every non-excluded lib/ file so that untested files '
      'count as 0 %.',
    );
  if (libFiles.isNotEmpty) buf.writeln('// ignore_for_file: unused_import');
  buf.writeln();
  imports.forEach(buf.writeln);
  buf
    ..writeln()
    ..writeln('void main() {')
    ..writeln("  test('coverage_all imports every lib file', () {});")
    ..writeln('}');
  return buf.toString();
}

/// One import directive, wrapped the way `dart format` wraps it at 80 columns.
String _importLine(String uri, String tail) {
  final line = 'import $uri$tail';
  if (line.length <= 80 || tail == ';') return line;
  return 'import $uri\n    ${tail.trimLeft()}';
}

class _Options {
  _Options({
    required this.packageDir,
    required this.repoRoot,
    required this.exclusions,
    required this.lcovPatterns,
    required this.help,
  });

  factory _Options.parse(List<String> args) {
    String? packageDir;
    String? repoRoot;
    String? exclusions;
    var lcovPatterns = false;
    var help = false;
    for (var i = 0; i < args.length; i++) {
      final arg = args[i];
      String value() {
        if (i + 1 >= args.length) {
          throw FormatException('missing value for $arg');
        }
        return args[++i];
      }

      switch (arg) {
        case '--repo-root':
          repoRoot = value();
        case '--exclusions':
          exclusions = value();
        case '--lcov-patterns':
          lcovPatterns = true;
        case '-h' || '--help':
          help = true;
        default:
          if (arg.startsWith('-')) throw FormatException('unknown option $arg');
          if (packageDir != null) {
            throw FormatException('unexpected argument $arg');
          }
          packageDir = arg;
      }
    }
    return _Options(
      packageDir: packageDir ?? '.',
      repoRoot: repoRoot,
      exclusions: exclusions,
      lcovPatterns: lcovPatterns,
      help: help,
    );
  }

  final String packageDir;
  final String? repoRoot;
  final String? exclusions;
  final bool lcovPatterns;
  final bool help;
}
