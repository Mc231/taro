/// Bias-free integer sampling for `RandomSource` adapters (06 §2.1).
library;

/// `2^32`, the range of one 32-bit random word.
const int kUint32Range = 0x100000000;

/// A uniformly distributed integer in `[0, max)` built from 32-bit random
/// words by rejection sampling, so there is no modulo bias (06 §2.1).
///
/// [nextUint32] must return independent uniform integers in `[0, 2^32)`.
/// Words at or above the largest multiple of [max] are rejected and drawn
/// again; the expected number of words is below 2 for every [max].
///
/// Throws a [RangeError] unless `1 <= max <= 2^32`, or if [nextUint32]
/// returns a value outside `[0, 2^32)`.
int uniformIntBelow(int max, int Function() nextUint32) {
  RangeError.checkValueInInterval(max, 1, kUint32Range, 'max');
  final limit = kUint32Range - kUint32Range % max;
  while (true) {
    final word = nextUint32();
    RangeError.checkValueInInterval(word, 0, kUint32Range - 1, 'nextUint32()');
    if (word < limit) return word % max;
  }
}
