import 'dart:io';

import 'package:taro_dart_tools/gen_coverage_all.dart';
import 'package:test/test.dart';

/// The repository root (tests run with the package as working directory).
final Directory _repoRoot = findRepoRoot(Directory.current)!;

final Directory _fixture = Directory(
  '${_repoRoot.path}/tools/dart_tools/test/fixtures/sample_pkg',
);

void _copyDir(Directory from, Directory to) {
  to.createSync(recursive: true);
  for (final e in from.listSync(recursive: true)) {
    final rel = relativePath(e.path, from.path)!;
    if (e is Directory) {
      Directory('${to.path}/$rel').createSync(recursive: true);
    } else if (e is File) {
      File('${to.path}/$rel')
        ..parent.createSync(recursive: true)
        ..writeAsBytesSync(e.readAsBytesSync());
    }
  }
}

/// A throwaway repo: `docs/specs`, the real exclusion list plus one
/// unit-specific pattern, and the fixture at `packages/sample_pkg`.
Directory _makeRepo() {
  final tmp = Directory.systemTemp.createTempSync('gen_coverage_all_');
  addTearDown(() => tmp.deleteSync(recursive: true));
  final repo = Directory('${tmp.path}/repo');
  Directory('${repo.path}/docs/specs').createSync(recursive: true);
  final real = File('${_repoRoot.path}/$exclusionsPath').readAsStringSync();
  File('${repo.path}/$exclusionsPath')
    ..parent.createSync(recursive: true)
    ..writeAsStringSync(
      '$real\n# fixture-only\npackages/sample_pkg/lib/src/generated/**\n',
    );
  _copyDir(_fixture, Directory('${repo.path}/packages/sample_pkg'));
  return repo;
}

Future<(int, String, String)> _run(List<String> args) async {
  final out = StringBuffer();
  final err = StringBuffer();
  final code = await genCoverageAll(args, out: out, err: err);
  return (code, out.toString(), err.toString());
}

void main() {
  group('globToRegExp', () {
    test('** spans segments, including none', () {
      final r = globToRegExp('**/test/**');
      expect(r.hasMatch('test/a.dart'), isTrue);
      expect(r.hasMatch('packages/x/test/a/b.dart'), isTrue);
      expect(r.hasMatch('packages/x/lib/contest/a.dart'), isFalse);
    });

    test('* and ? stay inside one segment', () {
      expect(globToRegExp('a/*.dart').hasMatch('a/b.dart'), isTrue);
      expect(globToRegExp('a/*.dart').hasMatch('a/b/c.dart'), isFalse);
      expect(globToRegExp('a/?.dart').hasMatch('a/b.dart'), isTrue);
      expect(globToRegExp('a/?.dart').hasMatch('a/bc.dart'), isFalse);
    });

    test('trailing ** matches everything below', () {
      final r = globToRegExp('worker/src/generated/**');
      expect(r.hasMatch('worker/src/generated/deck/en.ts'), isTrue);
      expect(r.hasMatch('worker/src/app.ts'), isFalse);
    });

    test('regex metacharacters are literal', () {
      expect(globToRegExp('a.b').hasMatch('a.b'), isTrue);
      expect(globToRegExp('a.b').hasMatch('axb'), isFalse);
    });
  });

  group('CoverageExclusions', () {
    test('parse skips comments and blank lines', () {
      final e = CoverageExclusions.parse('# c\n\n  **/*.g.dart  \nx/**\n');
      expect(e.patterns, ['**/*.g.dart', 'x/**']);
      expect(e.matches('lib/a.g.dart'), isTrue);
      expect(e.matches('lib/a.dart'), isFalse);
    });

    test('the real list matches 06 §5.3 examples', () {
      final e = CoverageExclusions.parse(
        File('${_repoRoot.path}/$exclusionsPath').readAsStringSync(),
      );
      expect(e.matches('apps/taro/lib/l10n/generated/l.dart'), isTrue);
      expect(e.matches('apps/taro/lib/main_dev.dart'), isTrue);
      expect(e.matches('apps/taro/lib/bootstrap/bootstrap.dart'), isFalse);
      expect(e.matches('packages/taro_core/lib/src/m.freezed.dart'), isTrue);
      expect(e.matches('apps/taro/lib/firebase_options_dev.dart'), isTrue);
      expect(e.matches('worker/scripts/seed.ts'), isFalse);
      expect(e.matches('worker/evals/lib/grader.ts'), isFalse);
      expect(e.matches('worker/evals/cases/a.yaml'), isTrue);
    });

    test('lcovPatterns keeps unit and global patterns, relative to unit', () {
      final e = CoverageExclusions([
        '**/*.g.dart',
        'apps/taro/lib/main_*.dart',
        'apps/taro/lib/l10n/generated/**',
        'worker/src/generated/**',
        '**/*.g.dart',
      ]);
      expect(e.lcovPatterns('apps/taro'), [
        '*.g.dart',
        '*/*.g.dart',
        'lib/main_*.dart',
        'lib/l10n/generated/*',
      ]);
      expect(e.lcovPatterns('packages/taro_core/'), [
        '*.g.dart',
        '*/*.g.dart',
      ]);
    });
  });

  group('helpers', () {
    test('packageName and usesFlutterTest read the pubspec', () {
      expect(packageName('name: foo_bar\n'), 'foo_bar');
      expect(packageName('description: x\n'), isNull);
      expect(
        usesFlutterTest('dev_dependencies:\n  flutter_test:\n    sdk: f\n'),
        isTrue,
      );
      expect(usesFlutterTest('dev_dependencies:\n  test: ^1.0.0\n'), isFalse);
    });

    test('relativePath handles root, children, outsiders and dots', () {
      expect(relativePath('/a/b', '/a/b'), '.');
      expect(relativePath('/a/b/c/d.dart', '/a/b'), 'c/d.dart');
      expect(relativePath('/a/bc/d.dart', '/a/b'), isNull);
      expect(relativePath('/a/b/./c/../d.dart', '/a/b/'), 'd.dart');
      expect(relativePath('/', '/'), '.');
    });

    test('findRepoRoot returns null outside a repository', () {
      final tmp = Directory.systemTemp.createTempSync('no_repo_');
      addTearDown(() => tmp.deleteSync(recursive: true));
      expect(findRepoRoot(tmp), isNull);
    });

    test('renderCoverageAll picks the flutter_test import', () {
      final text = renderCoverageAll(
        packageName: 'p',
        libFiles: const ['a.dart'],
        useFlutterTest: true,
      );
      expect(text, contains("import 'package:p/a.dart' as i0;"));
      expect(
        text,
        contains("import 'package:flutter_test/flutter_test.dart';"),
      );
      expect(text, contains('// ignore_for_file: unused_import'));
    });

    test('renderCoverageAll sorts imports and wraps like dart format', () {
      final long = '${'x' * 60}.dart';
      final text = renderCoverageAll(
        packageName: 'zed',
        libFiles: [long],
        useFlutterTest: false,
      );
      expect(
        text,
        contains(
          "import 'package:test/test.dart';\n"
          "import 'package:zed/$long'\n    as i0;\n",
        ),
      );
    });

    test('renderCoverageAll without lib files needs no ignore', () {
      final text = renderCoverageAll(
        packageName: 'p',
        libFiles: const [],
        useFlutterTest: false,
      );
      expect(text, isNot(contains('ignore_for_file')));
    });
  });

  group('genCoverageAll on the sample_pkg fixture', () {
    test(
      'writes an import for every non-excluded, non-part lib file',
      () async {
        final repo = _makeRepo();
        final pkg = '${repo.path}/packages/sample_pkg';
        final (code, out, err) = await _run([pkg]);
        expect(code, 0, reason: err);
        expect(out, contains('packages/sample_pkg/$coverageAllTestPath'));
        expect(out, contains('2 file(s)'));

        final text = File('$pkg/$coverageAllTestPath').readAsStringSync();
        expect(text, contains("import 'package:sample_pkg/sample_pkg.dart'"));
        expect(text, contains("import 'package:sample_pkg/src/model.dart'"));
        expect(text, isNot(contains('model_part.dart')));
        expect(text, isNot(contains('model.g.dart')));
        expect(text, isNot(contains('tokens.dart')));
        expect(text, contains("import 'package:test/test.dart';"));
        expect(text, contains('void main()'));
      },
    );

    test('--lcov-patterns prints unit-relative patterns', () async {
      final repo = _makeRepo();
      final (code, out, _) = await _run([
        '--lcov-patterns',
        '--repo-root',
        repo.path,
        '${repo.path}/packages/sample_pkg',
      ]);
      expect(code, 0);
      final lines = out.trim().split('\n');
      expect(lines, contains('lib/src/generated/*'));
      expect(lines, contains('*/*.freezed.dart'));
      expect(lines, isNot(contains('lib/main_*.dart')));
    });

    test('--exclusions overrides the default list', () async {
      final repo = _makeRepo();
      final list = File('${repo.path}/custom.txt')..writeAsStringSync('');
      final pkg = '${repo.path}/packages/sample_pkg';
      final (code, out, _) = await _run([
        '--exclusions',
        list.path,
        pkg,
      ]);
      expect(code, 0);
      expect(out, contains('4 file(s)'));
    });

    test('a package without lib/ gets an import-free test', () async {
      final repo = _makeRepo();
      final pkg = '${repo.path}/packages/sample_pkg';
      Directory('$pkg/lib').deleteSync(recursive: true);
      final (code, out, _) = await _run([pkg]);
      expect(code, 0);
      expect(out, contains('0 file(s)'));
    });

    test('runs from the working directory by default', () async {
      final repo = _makeRepo();
      final previous = Directory.current;
      Directory.current = '${repo.path}/packages/sample_pkg';
      addTearDown(() => Directory.current = previous);
      final (code, _, err) = await _run(const []);
      expect(code, 0, reason: err);
    });
  });

  group('genCoverageAll errors', () {
    test('--help prints usage', () async {
      final (code, out, _) = await _run(['--help']);
      expect(code, 0);
      expect(out, contains('Usage:'));
    });

    test(
      'unknown option, missing value and extra argument are usage errors',
      () async {
        for (final args in [
          ['--nope'],
          ['--repo-root'],
          ['a', 'b'],
        ]) {
          final (code, _, err) = await _run(args);
          expect(code, 64, reason: '$args');
          expect(err, contains('Usage:'));
        }
      },
    );

    test('missing pubspec', () async {
      final tmp = Directory.systemTemp.createTempSync('no_pubspec_');
      addTearDown(() => tmp.deleteSync(recursive: true));
      final (code, _, err) = await _run([tmp.path]);
      expect(code, 1);
      expect(err, contains('no pubspec.yaml'));
    });

    test('no repository root', () async {
      final tmp = Directory.systemTemp.createTempSync('no_root_');
      addTearDown(() => tmp.deleteSync(recursive: true));
      File('${tmp.path}/pubspec.yaml').writeAsStringSync('name: x\n');
      final (code, _, err) = await _run([tmp.path]);
      expect(code, 1);
      expect(err, contains('no repository root'));
    });

    test('missing exclusion list', () async {
      final repo = _makeRepo();
      File('${repo.path}/$exclusionsPath').deleteSync();
      final (code, _, err) = await _run(['${repo.path}/packages/sample_pkg']);
      expect(code, 1);
      expect(err, contains('exclusion list not found'));
    });

    test('package outside the repository root', () async {
      final repo = _makeRepo();
      final other = Directory.systemTemp.createTempSync('outside_');
      addTearDown(() => other.deleteSync(recursive: true));
      File('${other.path}/pubspec.yaml').writeAsStringSync('name: x\n');
      final (code, _, err) = await _run([
        '--repo-root',
        repo.path,
        other.path,
      ]);
      expect(code, 1);
      expect(err, contains('is not inside'));
    });

    test('pubspec without a name', () async {
      final repo = _makeRepo();
      final pkg = '${repo.path}/packages/sample_pkg';
      File('$pkg/pubspec.yaml').writeAsStringSync('publish_to: none\n');
      final (code, _, err) = await _run([pkg]);
      expect(code, 1);
      expect(err, contains('no `name:`'));
    });
  });
}
