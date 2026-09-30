import 'dart:math' as math;

import 'package:meta/meta.dart';
import 'package:taro_core/src/ports/random_source.dart';

/// The production [RandomSource] over the platform CSPRNG
/// (`Random.secure()`, 02 §4.1, PR7).
///
/// [nextInt] draws uniform 32-bit words and rejects the top
/// `2^32 mod max` of them, so `word % max` has no modulo bias for any
/// `max` in `1..2^32` (06 §2.1).
final class SecureRandomSource implements RandomSource {
  /// Creates a source over a fresh `Random.secure()`.
  SecureRandomSource() : this.withWords(math.Random.secure());

  /// A source whose 32-bit words come from [words]
  /// (`words.nextInt(2^32)`); tests script it to exercise rejection.
  @visibleForTesting
  SecureRandomSource.withWords(math.Random words) : _words = words;

  /// The word range, `2^32`.
  static const int wordRange = 1 << 32;

  final math.Random _words;

  @override
  int nextInt(int max) {
    RangeError.checkValueInInterval(max, 1, wordRange, 'max');
    // The largest multiple of max that fits in a word; words at or above
    // it would favour the low residues.
    final limit = wordRange - wordRange % max;
    while (true) {
      final word = _words.nextInt(wordRange);
      if (word < limit) return word % max;
    }
  }

  @override
  bool nextBool() => nextInt(2) == 1;
}
