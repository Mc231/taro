import 'package:taro_core/taro_core.dart';
import 'package:test/test.dart';

void main() {
  const failure = Failure.network();
  const ok = Result<int>.ok(2);
  const err = Result<int>.err(failure);

  group('Result', () {
    test('factories build Ok and Err', () {
      expect(ok, isA<Ok<int>>());
      expect(err, isA<Err<int>>());
      expect((ok as Ok<int>).value, 2);
      expect((err as Err<int>).failure, failure);
    });

    test('isOk / isErr', () {
      expect(ok.isOk, isTrue);
      expect(ok.isErr, isFalse);
      expect(err.isOk, isFalse);
      expect(err.isErr, isTrue);
    });

    test('valueOrNull and failureOrNull', () {
      expect(ok.valueOrNull, 2);
      expect(ok.failureOrNull, isNull);
      expect(err.valueOrNull, isNull);
      expect(err.failureOrNull, failure);
    });

    test('fold picks the matching branch', () {
      expect(ok.fold((v) => 'ok $v', (f) => 'err ${f.code}'), 'ok 2');
      expect(err.fold((v) => 'ok $v', (f) => 'err ${f.code}'), 'err NETWORK');
    });

    test('map transforms Ok and passes Err through', () {
      expect(ok.map((v) => v * 10), const Result<int>.ok(20));
      var called = false;
      final mapped = err.map((v) {
        called = true;
        return '$v';
      });
      expect(called, isFalse);
      expect(mapped, const Result<String>.err(failure));
    });

    test('then chains on Ok', () async {
      final next = await ok.then((v) async => Result.ok('v=$v'));
      expect(next, const Result<String>.ok('v=2'));
    });

    test('then propagates a failure from the next step', () async {
      const other = Failure.storage();
      final next = await ok.then<String>((v) async => const Result.err(other));
      expect(next, const Result<String>.err(other));
    });

    test('then short-circuits on Err', () async {
      var called = false;
      final next = await err.then<String>((v) async {
        called = true;
        return const Result.ok('x');
      });
      expect(called, isFalse);
      expect(next, const Result<String>.err(failure));
    });

    test('value equality, hashCode and toString', () {
      expect(const Ok(1), const Ok(1));
      expect(const Ok(1).hashCode, const Ok(1).hashCode);
      expect(const Ok(1), isNot(const Ok(2)));
      expect(const Err<int>(failure), const Err<int>(failure));
      expect(
        const Err<int>(failure).hashCode,
        const Err<int>(failure).hashCode,
      );
      expect(
        const Err<int>(failure),
        isNot(const Err<int>(Failure.timeout())),
      );
      expect(const Ok(1), isNot(const Err<int>(failure)));
      expect(const Ok(1).toString(), 'Ok(1)');
      expect(const Err<int>(failure).toString(), startsWith('Err('));
    });

    test('supports exhaustive switch', () {
      String describe(Result<int> r) => switch (r) {
        Ok(:final value) => 'ok $value',
        Err(:final failure) => 'err ${failure.code}',
      };
      expect(describe(ok), 'ok 2');
      expect(describe(err), 'err NETWORK');
    });
  });
}
