import 'dart:math' as math;

import 'package:taro_core/taro_core.dart';

/// A reproducible [RandomSource] over a seeded `dart:math` generator
/// (tests only; production uses `SecureRandomSource`).
final class SeededRandomSource implements RandomSource {
  /// A source seeded with [seed].
  SeededRandomSource([int seed = 42]) : _random = math.Random(seed);

  final math.Random _random;

  @override
  int nextInt(int max) {
    if (max < 1 || max > 1 << 32) {
      throw RangeError.range(max, 1, 1 << 32, 'max');
    }
    // dart:math's nextInt supports max <= 2^32; values above 2^31 need
    // two draws.
    if (max <= 1 << 31) return _random.nextInt(max);
    return ((_random.nextInt(1 << 16) << 16) | _random.nextInt(1 << 16)) % max;
  }

  @override
  bool nextBool() => _random.nextBool();
}

/// Returns scripted values in order; running out is a test bug and throws
/// a [StateError].
final class ScriptedRandomSource implements RandomSource {
  /// A source that answers `nextInt` with [ints] and `nextBool` with
  /// [bools].
  ScriptedRandomSource(Iterable<int> ints, {Iterable<bool> bools = const []})
    : _ints = [...ints],
      _bools = [...bools];

  final List<int> _ints;
  final List<bool> _bools;

  /// The `max` of every `nextInt` call, in order.
  final List<int> maxes = [];

  /// Number of `nextBool` calls.
  int boolCalls = 0;

  /// Scripted ints not used yet.
  int get remainingInts => _ints.length;

  /// Scripted bools not used yet.
  int get remainingBools => _bools.length;

  @override
  int nextInt(int max) {
    maxes.add(max);
    if (_ints.isEmpty) throw StateError('script exhausted at nextInt($max)');
    return _ints.removeAt(0);
  }

  @override
  bool nextBool() {
    boolCalls++;
    if (_bools.isEmpty) throw StateError('script exhausted at nextBool()');
    return _bools.removeAt(0);
  }
}

/// The fake of the `RandomSource` port.
typedef FakeRandomSource = SeededRandomSource;
