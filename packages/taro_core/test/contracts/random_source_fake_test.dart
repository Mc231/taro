import 'package:taro_core/taro_core.dart';
import 'package:test/test.dart';

import '../fakes/fakes.dart';
import 'contracts.dart';

void main() {
  group('SeededRandomSource', () {
    runRandomSourceContract(SeededRandomSource.new);
  });
  group('SecureRandomSource', () {
    runRandomSourceContract(SecureRandomSource.new);
  });

  group('SeededRandomSource', () {
    test('is reproducible and rejects a bad max', () {
      final a = SeededRandomSource(7);
      final b = SeededRandomSource(7);
      expect(
        [for (var i = 0; i < 10; i++) a.nextInt(78)],
        [for (var i = 0; i < 10; i++) b.nextInt(78)],
      );
      expect(() => a.nextInt(0), throwsRangeError);
      expect(() => a.nextInt((1 << 32) + 1), throwsRangeError);
    });
  });

  group('ScriptedRandomSource', () {
    test('replays the script and records the calls', () {
      final random = ScriptedRandomSource([3, 1], bools: [true]);
      expect(random.nextInt(78), 3);
      expect(random.nextBool(), isTrue);
      expect(random.remainingInts, 1);
      expect(random.remainingBools, 0);
      expect(random.nextInt(2), 1);
      expect(random.maxes, [78, 2]);
      expect(random.boolCalls, 1);
      expect(() => random.nextInt(5), throwsStateError);
      expect(random.nextBool, throwsStateError);
    });
  });
}
