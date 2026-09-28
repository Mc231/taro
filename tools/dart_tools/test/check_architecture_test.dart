import 'dart:io';

import 'package:taro_dart_tools/check_architecture.dart';
import 'package:test/test.dart';

const _fixtures = 'test/fixtures/check_architecture';

({int code, String out, String err}) _run(List<String> args, {Directory? cwd}) {
  final out = StringBuffer();
  final err = StringBuffer();
  final code = checkArchitecture(args, out: out, err: err, cwd: cwd);
  return (code: code, out: out.toString(), err: err.toString());
}

Map<String, int> _ruleCounts(String output) {
  final counts = <String, int>{};
  for (final match in RegExp(r': \[([a-z-]+)\] ').allMatches(output)) {
    counts.update(match.group(1)!, (n) => n + 1, ifAbsent: () => 1);
  }
  return counts;
}

void main() {
  group('fixture trees', () {
    test('pass is clean', () {
      final result = _run(['--repo-root', '$_fixtures/pass']);
      expect(result.out, contains('check_architecture: OK'));
      expect(result.code, 0);
    });

    final expectations = <String, Map<String, int>>{
      'fail_packages': {'unknown-package': 2, 'package-dependency': 12},
      'fail_lib_src': {
        'lib-src': 2,
        'relative-cross-package': 1,
        'outside-lib': 1,
      },
      'fail_folders': {'folder-dependency': 16, 'package-dependency': 12},
      'fail_tests': {
        'lib-src': 1,
        'test-cross-package': 4,
        'package-dependency': 1,
      },
      'fail_layout': {'non-directional': 9},
    };
    for (final entry in expectations.entries) {
      test('${entry.key} reports every violation', () {
        final result = _run(['--repo-root=$_fixtures/${entry.key}']);
        expect(result.code, 1);
        expect(_ruleCounts(result.out), entry.value);
        expect(result.out, contains('check_architecture: FAILED'));
      });
    }

    test('violations carry file:line', () {
      final result = _run(['--repo-root', '$_fixtures/fail_layout']);
      expect(
        result.out,
        contains(
          'packages/taro_ui/lib/src/theme/taro_theme.dart:4: '
          '[non-directional] EdgeInsets.only(left/right:)',
        ),
      );
    });

    test('the root is found from a nested directory', () {
      final nested = Directory('$_fixtures/pass/apps/taro/lib/features');
      final result = _run(const [], cwd: nested);
      expect(result.code, 0);
    });
  });

  group('command line', () {
    test('--help prints usage', () {
      final result = _run(['--help']);
      expect(result.code, 0);
      expect(result.out, contains('Usage:'));
      expect(_run(['-h']).code, 0);
    });

    test('unknown argument is a usage error', () {
      final result = _run(['--bogus']);
      expect(result.code, 64);
      expect(result.err, contains('unexpected argument'));
      expect(_run(['--repo-root']).code, 64);
    });

    test('no repository root fails', () {
      final tmp = Directory.systemTemp.createTempSync('arch_');
      addTearDown(() => tmp.deleteSync(recursive: true));
      expect(_run(const [], cwd: tmp).code, 1);
      expect(_run(['--repo-root', '${tmp.path}/missing']).code, 1);
      expect(findTaroRoot(tmp), isNull);
    });

    test('this repository passes', () {
      final root = findTaroRoot(Directory.current);
      expect(root, isNotNull);
      final result = _run(['--repo-root', root!.path]);
      expect(result.out, contains('OK'));
      expect(result.code, 0);
    });
  });

  group('maskDart', () {
    test('blanks comments and strings but keeps offsets and lines', () {
      const source =
          "a // x\nb /* y /* z */ */ c 'str' \"q\" r'raw\\' "
          "'''t\nt''' 'esc\\'x'";
      final masked = maskDart(source);
      expect(masked.length, source.length);
      expect(masked.split('\n').length, source.split('\n').length);
      expect(masked, isNot(contains('x')));
      expect(masked, isNot(contains('str')));
      expect(masked, contains('c '));
      expect(masked, contains('rar'.substring(0, 1)));
    });

    test('handles unterminated strings and comments', () {
      expect(maskDart("'open\nnext").split('\n').last, 'next');
      expect(maskDart('x /* open').trim(), 'x');
      expect(maskDart("'''open").trim(), "'''");
      expect(maskDart('// only'), '       ');
    });
  });

  group('parseDirectives', () {
    test('reads imports, exports and conditional alternatives', () {
      const source = '''
// import 'commented.dart';
library;
import 'package:a/a.dart' as a;
export "b.dart" show B;
import 'c.dart'
    if (dart.library.io) 'c_io.dart';
import """d.dart""";
''';
      final directives = parseDirectives(source);
      expect(directives.map((d) => d.uri), [
        'package:a/a.dart',
        'b.dart',
        'c.dart',
        'c_io.dart',
        'd.dart',
      ]);
      expect(directives.map((d) => d.line), [3, 4, 5, 5, 7]);
      expect(directives.first.toString(), 'Directive(package:a/a.dart, 3)');
    });

    test('an unterminated directive does not crash', () {
      expect(parseDirectives("import 'a.dart'").single.uri, 'a.dart');
      expect(parseDirectives("import 'a.dart").single.uri, 'a.dart');
    });
  });

  group('findLayoutUses', () {
    test('ignores directional forms and nested named args', () {
      const source = '''
final a = EdgeInsetsDirectional.only(start: 1);
final b = EdgeInsets.only(top: f(left: 1));
final c = Positioned.fill(left: 1);
final d = myLeft ? TextAlign.start : TextAlign.end;
final e = EdgeInsets.only(top: 1, bottomleft: 2);
''';
      expect(findLayoutUses(source), isEmpty);
    });

    test('an unclosed call is scanned to the end', () {
      expect(findLayoutUses('EdgeInsets.only(left: 1').single.line, 1);
    });
  });

  group('rules', () {
    test('package table', () {
      expect(packageRuleViolation('taro_core', 'dart:math'), isNull);
      expect(packageRuleViolation('taro_core', 'meta'), isNull);
      expect(packageRuleViolation('taro_core', 'sky_engine'), isNotNull);
      expect(packageRuleViolation('taro_core', 'riverpod'), isNotNull);
      expect(packageRuleViolation('taro_core', 'taro_core'), isNull);
      expect(packageRuleViolation('taro_ui', 'flutter'), isNull);
      expect(packageRuleViolation('taro_attestation', 'flutter'), isNull);
      expect(packageRuleViolation('taro', 'taro_core'), isNull);
    });

    test('zones', () {
      expect(zoneOf('app.dart'), isNull);
      expect(zoneOf('data/content'), 'data');
      expect(zoneOf('data/content/x.dart'), 'data/content');
      expect(zoneOf('services/presentation/x.dart'), 'services/presentation');
      expect(zoneOf('services/x.dart'), 'services');
      expect(zoneOf('features/home/x.dart'), 'features/home');
      expect(zoneOf('features/x.dart'), 'features');
      expect(zoneOf('routing/router.dart'), isNull);
    });

    test('folder table edges', () {
      expect(folderRuleViolation('app.dart', 'data/x.dart'), isNull);
      expect(
        folderRuleViolation('routing/r.dart', 'features/a/x.dart'),
        isNull,
      );
      expect(folderRuleViolation('common/a.dart', 'l10n/x.dart'), isNull);
      expect(folderRuleViolation('app_state/a.dart', 'di/p.dart'), isNull);
      expect(
        folderRuleViolation('features/a/v.dart', 'routing/router.dart'),
        contains('features/a/ must not import routing/router.dart'),
      );
      expect(folderPackageViolation(null, 'dio'), isNull);
      expect(folderPackageViolation('app_state', 'flutter_riverpod'), isNull);
      expect(folderPackageViolation('services', 'google_mobile_ads'), isNull);
      expect(
        folderPackageViolation('features/a', 'sqlite3_flutter'),
        isNotNull,
      );
      expect(folderPackageViolation('features/a', 'go_router'), isNull);
    });

    test('normalizePath', () {
      expect(normalizePath('a/./b/../c'), 'a/c');
      expect(normalizePath('../../x'), '../../x');
      expect(normalizePath('/a//b/'), 'a/b');
    });

    test('violation ordering and rendering', () {
      const a = Violation('a.dart', 2, 'r', 'm');
      const b = Violation('a.dart', 10, 'r', 'm');
      const c = Violation('a.dart', 10, 'r', 'n');
      const d = Violation('b.dart', 0, 'r', 'm');
      expect([d, c, b, a]..sort(), [a, b, c, d]);
      expect(a.toString(), 'a.dart:2: [r] m');
      expect(d.toString(), 'b.dart: [r] m');
    });
  });
}
