/// The randomness source (02 §5, rule 5). `Random()` and `Random.secure()`
/// are banned outside the adapter files.
abstract interface class RandomSource {
  /// A uniformly distributed integer in `[0, max)`. [max] must be in
  /// `1..2^32`.
  int nextInt(int max);

  /// A uniformly distributed boolean.
  bool nextBool();
}
