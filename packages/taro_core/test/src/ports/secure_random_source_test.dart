import 'dart:math' as math;

import 'package:taro_core/taro_core.dart';
import 'package:test/test.dart';

import '../../contracts/contracts.dart';

/// Replays scripted 32-bit words and records every requested range.
final class _ScriptedWords implements math.Random {
  _ScriptedWords(this._words);

  final List<int> _words;
  final List<int> ranges = [];

  @override
  int nextInt(int max) {
    ranges.add(max);
    return _words.removeAt(0);
  }

  @override
  bool nextBool() => throw UnimplementedError();

  @override
  double nextDouble() => throw UnimplementedError();
}

void main() {
  const top = SecureRandomSource.wordRange - 1;

  group('SecureRandomSource', () {
    runRandomSourceContract(SecureRandomSource.new);

    test('draws full 32-bit words', () {
      final words = _ScriptedWords([5]);
      expect(SecureRandomSource.withWords(words).nextInt(78), 5);
      expect(words.ranges, [SecureRandomSource.wordRange]);
    });

    test('rejects the biased top words instead of folding them', () {
      // 2^32 mod 78 = 22: the top 22 words would favour residues 0..21.
      const limit =
          SecureRandomSource.wordRange - SecureRandomSource.wordRange % 78;
      final words = _ScriptedWords([top, limit, limit - 1]);
      expect(SecureRandomSource.withWords(words).nextInt(78), (limit - 1) % 78);
      expect(words.ranges, hasLength(3));
    });

    test('max 3 rejects only the single top word', () {
      final words = _ScriptedWords([top, top - 1]);
      expect(SecureRandomSource.withWords(words).nextInt(3), (top - 1) % 3);
      expect(words.ranges, hasLength(2));
    });

    test('powers of two and 2^32 never reject', () {
      expect(SecureRandomSource.withWords(_ScriptedWords([top])).nextInt(2), 1);
      expect(
        SecureRandomSource.withWords(
          _ScriptedWords([top]),
        ).nextInt(SecureRandomSource.wordRange),
        top,
      );
    });

    test('nextBool is the low bit of an accepted word', () {
      final random = SecureRandomSource.withWords(_ScriptedWords([6, 7]));
      expect(random.nextBool(), isFalse);
      expect(random.nextBool(), isTrue);
    });

    test('rejects a max outside 1..2^32', () {
      final random = SecureRandomSource();
      expect(() => random.nextInt(0), throwsRangeError);
      expect(
        () => random.nextInt(SecureRandomSource.wordRange + 1),
        throwsRangeError,
      );
    });

    test(
      'chi-square smoke: 1,000,000 draws of 0..77 are uniform (p > 0.001)',
      () {
        const cells = 78;
        const draws = 1000000;
        final counts = List<int>.filled(cells, 0);
        final random = SecureRandomSource();
        for (var i = 0; i < draws; i++) {
          counts[random.nextInt(cells)]++;
        }
        const expected = draws / cells;
        var chi2 = 0.0;
        for (final c in counts) {
          chi2 += (c - expected) * (c - expected) / expected;
        }
        // The 0.999 quantile of chi-square with 77 degrees of freedom.
        expect(chi2, lessThan(121.10));
      },
      tags: ['slow'],
    );
  });
}
