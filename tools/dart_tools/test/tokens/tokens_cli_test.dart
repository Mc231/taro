import 'dart:io';

import 'package:taro_dart_tools/tokens.dart';
import 'package:test/test.dart';

/// A throwaway repository root with `docs/specs` and a token file.
final class _Repo {
  _Repo() : dir = Directory.systemTemp.createTempSync('taro_tokens_cli') {
    Directory('${dir.path}/docs/specs').createSync(recursive: true);
    Directory('${dir.path}/docs/design').createSync(recursive: true);
  }

  final Directory dir;

  void tokens(String fixture) => File(
    'test/fixtures/tokens/$fixture',
  ).copySync('${dir.path}/$kTokensPath');

  File get output => File('${dir.path}/$kTokensDartPath');

  void dispose() => dir.deleteSync(recursive: true);
}

(String, String) _formatted(String source) => ('// formatted\n$source', '');

(String?, String?) _fakeFormat(String source) => _formatted(source);

(String?, String?) _brokenFormat(String source) => (null, 'boom');

void main() {
  late _Repo repo;
  late StringBuffer out;
  late StringBuffer err;

  TokensIo io({DartFormatter formatter = _fakeFormat}) => TokensIo(
    out: out,
    err: err,
    cwd: repo.dir,
    formatter: formatter,
  );

  setUp(() {
    repo = _Repo();
    out = StringBuffer();
    err = StringBuffer();
  });
  tearDown(() => repo.dispose());

  TokenContract fixtureContract() => const TokenContract(
    names: [
      'color.bg.canvas',
      'color.text.primary',
      'color.text.link',
      'space.0',
      'space.4',
      'elevation.1.shadow',
      'elevation.1.overlay',
      'motion.duration.fast',
      'motion.easing.standard',
      'font.family.body.latin',
      'font.family.body.cyrillic',
      'font.family.body.arabic',
      'type.body',
      'haptic.pick',
    ],
  );

  group('generate', () {
    test('writes, then --check passes; a stale file fails --check', () {
      repo.tokens('pass.tokens.json');
      expect(
        runTokensGenerate(const [], io: io(), contract: fixtureContract()),
        0,
      );
      expect(repo.output.readAsStringSync(), startsWith('// formatted'));
      expect(out.toString(), contains('wrote $kTokensDartPath (14 tokens)'));
      expect(
        runTokensGenerate(
          const ['--check'],
          io: io(),
          contract: fixtureContract(),
        ),
        0,
      );
      expect(out.toString(), contains('is current'));
      repo.output.writeAsStringSync('stale');
      expect(
        runTokensGenerate(
          const ['--check'],
          io: io(),
          contract: fixtureContract(),
        ),
        1,
      );
      expect(err.toString(), contains('is stale'));
    });

    test('--check fails when the output is missing', () {
      repo.tokens('pass.tokens.json');
      expect(
        runTokensGenerate(
          const ['--check'],
          io: io(),
          contract: fixtureContract(),
        ),
        1,
      );
    });

    test('--input/--output/--repo-root are honoured', () {
      final input = File('${repo.dir.path}/other.json');
      File('test/fixtures/tokens/pass.tokens.json').copySync(input.path);
      final code = runTokensGenerate(
        [
          '--repo-root',
          repo.dir.path,
          '--input',
          input.path,
          '--output',
          'x.dart',
        ],
        io: TokensIo(out: out, err: err, formatter: _fakeFormat),
        contract: fixtureContract(),
      );
      expect(code, 0);
      expect(File('${repo.dir.path}/x.dart').existsSync(), isTrue);
    });

    test('fails on names outside the contract (02 §14.2)', () {
      repo.tokens('pass.tokens.json');
      expect(
        runTokensGenerate(
          const [],
          io: io(),
          contract: const TokenContract(names: ['color.bg.canvas', 'x.y']),
        ),
        1,
      );
      expect(err.toString(), contains('x.y: missing (01 §14)'));
      expect(err.toString(), contains('space.4: unknown name'));
      expect(repo.output.existsSync(), isFalse);
    });

    test('fails on the missing-mode fixture', () {
      repo.tokens('fail_missing_mode.tokens.json');
      expect(runTokensGenerate(const [], io: io()), 1);
      expect(err.toString(), contains('missing mode "dark"'));
    });

    test('fails on the alias-cycle fixture', () {
      repo.tokens('fail_alias_cycle.tokens.json');
      expect(
        runTokensGenerate(
          const [],
          io: io(),
          contract: const TokenContract(
            names: ['space.a', 'space.b', 'space.c'],
          ),
        ),
        1,
      );
      expect(err.toString(), contains('alias cycle'));
    });

    test('fails when dart format fails', () {
      repo.tokens('pass.tokens.json');
      expect(
        runTokensGenerate(
          const [],
          io: io(formatter: _brokenFormat),
          contract: fixtureContract(),
        ),
        1,
      );
      expect(err.toString(), contains('dart format failed: boom'));
    });

    test('dartExecutable keeps the Dart VM, else uses dart on the PATH', () {
      expect(dartExecutable('/sdk/bin/dart'), '/sdk/bin/dart');
      expect(dartExecutable(r'C:\sdk\bin\dart.exe'), r'C:\sdk\bin\dart.exe');
      expect(dartExecutable('/engine/flutter_tester'), 'dart');
    });

    test('the real formatter formats', () {
      final (formatted, error) = formatWithDart('void main(){}');
      expect(error, isNull);
      expect(formatted, 'void main() {}\n');
      final (none, message) = formatWithDart('void main(');
      expect(none, isNull);
      expect(message, isNotEmpty);
    });
  });

  group('validate_tokens', () {
    test('passes the fixture against its contract', () {
      repo.tokens('pass.tokens.json');
      expect(
        runTokensValidate(const [], io: io(), contract: fixtureContract()),
        0,
      );
      expect(out.toString(), contains('OK (14 tokens, modes light/dark)'));
    });

    test('reports issues', () {
      repo.tokens('pass.tokens.json');
      expect(runTokensValidate(const [], io: io()), 1);
      expect(err.toString(), contains('issue(s) in $kTokensPath'));
    });

    test('the repository token file passes with the real contract', () {
      expect(
        runTokensValidate(
          const [],
          io: TokensIo(out: out, err: err, cwd: Directory.current),
        ),
        0,
        reason: err.toString(),
      );
    });
  });

  group('usage and inputs', () {
    test('--help prints usage', () {
      expect(runTokensGenerate(const ['--help'], io: io()), 0);
      expect(out.toString(), contains('--check'));
      expect(runTokensValidate(const ['-h'], io: io()), 0);
    });

    test('bad arguments are usage errors', () {
      expect(runTokensGenerate(const ['--nope'], io: io()), 64);
      expect(runTokensValidate(const ['extra'], io: io()), 64);
      expect(err.toString(), contains('unexpected argument "extra"'));
    });

    test('no repository root', () {
      final code = runTokensValidate(
        const [],
        io: TokensIo(out: out, err: err, cwd: Directory.systemTemp),
      );
      expect(code, 1);
      expect(err.toString(), contains('no repository root'));
      expect(
        runTokensGenerate(
          const [],
          io: TokensIo(out: out, err: err, cwd: Directory.systemTemp),
        ),
        1,
      );
    });

    test('missing and malformed token files', () {
      expect(runTokensValidate(const [], io: io()), 1);
      expect(err.toString(), contains('not found'));
      File('${repo.dir.path}/$kTokensPath').writeAsStringSync('{');
      expect(runTokensValidate(const [], io: io()), 1);
      expect(err.toString(), contains('is not JSON'));
      expect(runTokensGenerate(const [], io: io()), 1);
    });
  });

  test('the committed generated file is current (--check)', () {
    expect(
      runTokensGenerate(
        const ['--check'],
        io: TokensIo(out: out, err: err, cwd: Directory.current),
      ),
      0,
      reason: err.toString(),
    );
  });
}
