import 'package:taro_core/taro_core.dart';
import 'package:test/test.dart';

import 'failure_samples.dart';

void main() {
  group('ErrorKind', () {
    test('has the 01 §8.2 kinds in order', () {
      expect(ErrorKind.values.map((e) => e.name), [
        'network',
        'server',
        'rateLimited',
        'deviceUnverified',
        'storage',
        'invalidFile',
        'unknown',
      ]);
    });

    for (final sample in failureSamples) {
      test(
        'fromFailure(${sample.failure.runtimeType}) -> ${sample.kind.name}',
        () {
          expect(ErrorKind.fromFailure(sample.failure), sample.kind);
        },
      );
    }

    test('every kind is reachable from some failure', () {
      final reached = failureSamples
          .map((s) => ErrorKind.fromFailure(s.failure))
          .toSet();
      expect(reached, ErrorKind.values.toSet());
    });
  });
}
