import 'dart:math' as math;

import 'package:taro_core/src/ports/random_source.dart';

/// The production [RandomSource] over the platform CSPRNG
/// (`Random.secure()`, 02 §4.1, PR7).
final class SecureRandomSource implements RandomSource {
  /// Creates a source over a fresh `Random.secure()`.
  SecureRandomSource() : _random = math.Random.secure();

  final math.Random _random;

  @override
  int nextInt(int max) => _random.nextInt(max);

  @override
  bool nextBool() => _random.nextBool();
}
