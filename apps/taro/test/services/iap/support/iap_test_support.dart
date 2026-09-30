import 'dart:async';

import 'package:taro/services/iap/store_ownership.dart';
import 'package:taro_core/taro_core.dart';

/// A `Delay` whose waits complete only when the test fires them.
final class ManualDelay {
  final List<({Duration duration, Completer<void> done})> _waits = [];

  /// Every wait requested so far, oldest first.
  final List<Duration> requested = [];

  /// Starts a wait of [duration].
  Future<void> call(Duration duration) {
    final done = Completer<void>();
    _waits.add((duration: duration, done: done));
    requested.add(duration);
    return done.future;
  }

  /// The durations still waiting.
  List<Duration> get waiting => [for (final w in _waits) w.duration];

  /// Completes the oldest open wait of [duration] (any when `null`).
  /// Returns whether one was open.
  bool fire([Duration? duration]) {
    final i = _waits.indexWhere(
      (w) => duration == null || w.duration == duration,
    );
    if (i < 0) return false;
    _waits.removeAt(i).done.complete();
    return true;
  }
}

/// A scriptable [StoreOwnership]: answers [answer], or waits for
/// [release] when [hold] is set.
final class FakeStoreOwnership implements StoreOwnership {
  /// What the next query answers.
  Result<Set<ProductId>> answer = const Result.ok({});

  /// When set, queries wait until [release].
  bool hold = false;

  /// How often the store was asked.
  int queries = 0;

  final List<Completer<void>> _held = [];

  /// Lets held queries answer.
  void release() {
    for (final c in _held) {
      c.complete();
    }
    _held.clear();
  }

  @override
  Future<Result<Set<ProductId>>> queryOwnership() async {
    queries++;
    if (hold) {
      final c = Completer<void>();
      _held.add(c);
      await c.future;
    }
    return answer;
  }
}
