import 'package:test/test.dart';

import 'logic_support.dart';

int Function() _words(List<int> words) {
  var i = 0;
  return () => words[i++];
}

void main() {
  group('uniformIntBelow (rejection sampling, 06 §2.1)', () {
    test('accepts words below the largest multiple of max', () {
      // 2^32 % 3 == 1, so the limit is 2^32 - 1 and only 2^32 - 1 is
      // rejected.
      expect(uniformIntBelow(3, _words([7])), 1);
      expect(
        uniformIntBelow(3, _words([kUint32Range - 2])),
        (kUint32Range - 2) % 3,
      );
    });

    test('rejects the biased tail and draws again', () {
      var calls = 0;
      final words = [kUint32Range - 1, kUint32Range - 1, 5];
      final v = uniformIntBelow(3, () => words[calls++]);
      expect(v, 2);
      expect(calls, 3);
    });

    test('78 rejects exactly the top 2^32 % 78 words', () {
      const tail = kUint32Range % 78;
      const limit = kUint32Range - tail;
      expect(uniformIntBelow(78, _words([limit - 1])), (limit - 1) % 78);
      var calls = 0;
      expect(
        uniformIntBelow(78, () => [limit, kUint32Range - 1, 0][calls++]),
        0,
      );
      expect(calls, 3);
    });

    test('invalid max or word throws', () {
      expect(() => uniformIntBelow(0, _words([0])), throwsRangeError);
      expect(
        () => uniformIntBelow(kUint32Range + 1, _words([0])),
        throwsRangeError,
      );
      expect(() => uniformIntBelow(3, _words([-1])), throwsRangeError);
      expect(
        () => uniformIntBelow(3, _words([kUint32Range])),
        throwsRangeError,
      );
    });
  });
}
