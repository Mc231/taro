import 'dart:io';

import 'package:taro_dart_tools/gen_coverage_all.dart' show findRepoRoot;
import 'package:taro_dart_tools/gen_state_inventory.dart';
import 'package:test/test.dart';

/// The repository root (tests run with the package as working directory).
final Directory _repoRoot = findRepoRoot(Directory.current)!;

const _source = r'''
import 'package:freezed_annotation/freezed_annotation.dart';

/// Not a union.
class Helper {
  const factory Helper.nope() = _Nope;
}

@freezed
sealed class FooState with _$FooState {
  /// The first
  ///   state.
  const factory FooState.first() = FooFirst;

  const factory FooState.second(int x) =
      FooSecond;
}

@freezed
sealed class BarPhase with _$BarPhase {
  /// A | piped doc.
  const factory BarPhase.idle() = BarIdle;
}
''';

const _glossary = '''
# Glossary

## 10. Screens S01–S33

| ID | Screen | Route | Analytics `screen` | Banner screen ID |
|---|---|---|---|---|
| S05 | Home ("Today" tab 1) | `/home` | `S05` | `home` |
| S10 | Out-of-readings sheet | modal | `S10` | — |

## 11. Flows
| S99 | Not a screen | x | y | z |
''';

Map<String, StateUnion> _unions() =>
    parseUnions({'apps/taro/lib/features/foo/foo.dart': _source});

void _copyDir(Directory from, Directory to) {
  for (final e in from.listSync(recursive: true)) {
    final rel = e.path.substring(from.path.length + 1);
    if (e is File) {
      File('${to.path}/$rel')
        ..parent.createSync(recursive: true)
        ..writeAsBytesSync(e.readAsBytesSync());
    }
  }
}

/// A throwaway repo with the real GLOSSARY and feature controllers.
Directory _makeRepo() {
  final tmp = Directory.systemTemp.createTempSync('state_inventory_');
  addTearDown(() => tmp.deleteSync(recursive: true));
  final repo = Directory('${tmp.path}/repo');
  Directory('${repo.path}/docs/specs').createSync(recursive: true);
  File(
    '${_repoRoot.path}/docs/specs/GLOSSARY.md',
  ).copySync('${repo.path}/docs/specs/GLOSSARY.md');
  _copyDir(
    Directory('${_repoRoot.path}/apps/taro/lib/features'),
    Directory('${repo.path}/apps/taro/lib/features'),
  );
  return repo;
}

(int, String, String) _run(List<String> args, {Directory? cwd}) {
  final out = StringBuffer();
  final err = StringBuffer();
  final code = genStateInventory(args, out: out, err: err, cwd: cwd);
  return (code, out.toString(), err.toString());
}

void main() {
  group('parseUnions', () {
    test('sealed unions with cases and docs; other classes ignored', () {
      final unions = _unions();
      expect(unions.keys, unorderedEquals(['FooState', 'BarPhase']));
      final foo = unions['FooState']!;
      expect(foo.path, 'apps/taro/lib/features/foo/foo.dart');
      expect(foo.cases.map((c) => c.name), ['first', 'second']);
      expect(foo.cases.first.doc, 'The first state.');
      expect(foo.cases.last.doc, isEmpty);
    });

    test('files without a sealed class are skipped', () {
      expect(parseUnions({'a.dart': 'class A {}'}), isEmpty);
    });
  });

  group('parseGlossaryScreens', () {
    test('reads the §10 table only', () {
      final screens = parseGlossaryScreens(_glossary);
      expect(screens.keys, ['S05', 'S10']);
      expect(screens['S05']!.name, 'Home ("Today" tab 1)');
      expect(screens['S05']!.route, '`/home`');
      expect(screens['S05']!.banner, 'home');
      expect(screens['S10']!.banner, isNull);
    });

    test('a glossary without §10 is an error', () {
      expect(
        () => parseGlossaryScreens('# nothing'),
        throwsA(isA<InventoryException>()),
      );
    });

    test('the real glossary has all 33 screens and 3 banner screens', () {
      final screens = parseGlossaryScreens(
        File('${_repoRoot.path}/docs/specs/GLOSSARY.md').readAsStringSync(),
      );
      expect(screens, hasLength(33));
      expect(
        {
          for (final s in screens.values)
            if (s.banner != null) s.banner,
        },
        {'home', 'journal_list', 'learn_library'},
      );
    });
  });

  group('resolve', () {
    final glossary = parseGlossaryScreens(_glossary);

    test('only, starred, sub-unions and 01 §8.3 extras', () {
      final screens = resolve(
        const [
          ScreenSpec(
            'S05',
            unions: ['FooState', 'BarPhase'],
            only: {'first'},
            starred: {'first'},
            other: ['flag', 'variant'],
            otherStarred: {'variant'},
          ),
        ],
        _unions(),
        glossary,
      );
      final rows = screens.single.rows;
      expect(rows.map((r) => r.name), ['first', 'idle', 'flag', 'variant']);
      expect(rows.map((r) => r.union), ['FooState', 'BarPhase', null, null]);
      expect(screens.single.starred, ['first', 'variant']);
    });

    test('every stale mapping is reported at once', () {
      expect(
        () => resolve(
          const [
            ScreenSpec('S05', unions: ['Missing']),
            ScreenSpec('S10', unions: ['FooState'], starred: {'third'}),
            ScreenSpec('S42'),
          ],
          _unions(),
          glossary,
        ),
        throwsA(
          isA<InventoryException>().having(
            (e) => e.toString(),
            'message',
            allOf(
              contains('S05: union Missing not found'),
              contains('S10: FooState has no state "third"'),
              contains('S42: not in GLOSSARY §10'),
            ),
          ),
        ),
      );
    });
  });

  group('render', () {
    test('summary, per-screen tables, escaping and unmapped unions', () {
      final unions = _unions();
      final screens = resolve(
        const [
          ScreenSpec(
            'S05',
            unions: ['FooState'],
            starred: {'second'},
            other: ['a | b'],
          ),
          ScreenSpec('S10'),
        ],
        unions,
        parseGlossaryScreens(_glossary),
      );
      final md = render(screens, unions, command: 'gen');
      expect(md, startsWith('# State inventory (S01–S33)'));
      expect(md, contains('Generated by `gen`'));
      expect(
        md,
        contains(
          '| S05 Home ("Today" tab 1) | `/home` | `first`, `second`★ | '
          '`second` | ✅ `home` |',
        ),
      );
      expect(md, contains('| S10 Out-of-readings sheet | modal | — | — | — |'));
      expect(md, contains('## S05 · Home ("Today" tab 1)'));
      expect(
        md,
        contains(
          'Route `/home` · Banner ✅ `home` · Unions: `FooState` '
          '(`apps/taro/lib/features/foo/foo.dart`)',
        ),
      );
      expect(md, contains('Route modal · Banner none\n'));
      expect(md, contains(r'| a \| b |  | — (01 §8.3) |  |'));
      expect(md, contains('| `second` | ★ | `FooState` |  |'));
      expect(md, contains('## Other sealed unions in `features/`'));
      expect(md, contains('| `BarPhase` |'));
    });

    test('sub-union states are prefixed in the summary', () {
      final unions = _unions();
      final screens = resolve(
        const [
          ScreenSpec('S05', unions: ['FooState', 'BarPhase']),
        ],
        unions,
        parseGlossaryScreens(_glossary),
      );
      final md = render(screens, unions, command: 'gen');
      expect(md, contains('`first`, `second`, `BarPhase.idle`'));
      expect(md, isNot(contains('## Other sealed unions')));
    });
  });

  group('genStateInventory', () {
    test('help and usage errors', () {
      final (help, out, _) = _run(['--help']);
      expect(help, 0);
      expect(out, contains('Usage:'));
      final (bad, _, err) = _run(['--nope']);
      expect(bad, 64);
      expect(err, contains('unexpected argument "--nope"'));
    });

    test('no repository root', () {
      final tmp = Directory.systemTemp.createTempSync('no_repo_');
      addTearDown(() => tmp.deleteSync(recursive: true));
      final (code, _, err) = _run([], cwd: tmp);
      expect(code, 1);
      expect(err, contains('no repository root'));
      final (missing, _, _) = _run(['--repo-root', '${tmp.path}/absent']);
      expect(missing, 1);
    });

    test('writes, then --check passes; a stale file fails', () {
      final repo = _makeRepo();
      final (code, out, _) = _run(['--repo-root', repo.path]);
      expect(code, 0);
      expect(out, contains('wrote $stateInventoryPath'));
      final doc = File('${repo.path}/$stateInventoryPath');
      expect(doc.readAsStringSync(), contains('## S33 · Report reading'));
      final (ok, okOut, _) = _run(['--repo-root=${repo.path}', '--check']);
      expect(ok, 0);
      expect(okOut, contains('OK'));
      doc.writeAsStringSync('stale');
      final (stale, _, err) = _run(['--repo-root', repo.path, '--check']);
      expect(stale, 1);
      expect(err, contains('is stale'));
      doc.deleteSync();
      final (absent, _, _) = _run(['--repo-root', repo.path, '--check']);
      expect(absent, 1);
    });

    test('the cwd search finds the root', () {
      final repo = _makeRepo();
      final (code, _, _) = _run(
        ['--check'],
        cwd: Directory('${repo.path}/apps/taro/lib/features'),
      );
      expect(code, 1); // not generated yet
    });

    test('missing inputs and a stale map fail with a message', () {
      final repo = _makeRepo();
      File('${repo.path}/docs/specs/GLOSSARY.md').deleteSync();
      final (noGlossary, _, err1) = _run(['--repo-root', repo.path]);
      expect(noGlossary, 1);
      expect(err1, contains('GLOSSARY.md is missing'));

      final repo2 = _makeRepo();
      Directory('${repo2.path}/apps/taro/lib/features').deleteSync(
        recursive: true,
      );
      final (noFeatures, _, err2) = _run(['--repo-root', repo2.path]);
      expect(noFeatures, 1);
      expect(err2, contains('features is missing'));

      final repo3 = _makeRepo();
      final home = File(
        '${repo3.path}/apps/taro/lib/features/home/controller/'
        'home_controller.dart',
      );
      home.writeAsStringSync(
        home.readAsStringSync().replaceAll('HomeState', 'RenamedState'),
      );
      final (stale, _, err3) = _run(['--repo-root', repo3.path]);
      expect(stale, 1);
      expect(err3, contains('union HomeState not found'));
    });
  });

  test('the committed STATE_INVENTORY.md is current', () {
    expect(
      File('${_repoRoot.path}/$stateInventoryPath').readAsStringSync(),
      buildStateInventory(_repoRoot),
      reason: 'run $stateInventoryCommand',
    );
  });
}
