import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:taro/lifecycle/reset_timer.dart';

import '../helpers/pump_app.dart';

final class _ManualTimer implements Timer {
  _ManualTimer(this.delay, this.onFire);

  final Duration delay;
  final void Function() onFire;
  bool _active = true;

  void fire() {
    _active = false;
    onFire();
  }

  @override
  void cancel() => _active = false;

  @override
  bool get isActive => _active;

  @override
  int get tick => 0;
}

void main() {
  late FakeClock clock;
  late List<_ManualTimer> timers;
  late int fired;
  late ResetTimer timer;

  setUp(() {
    clock = FakeClock();
    timers = [];
    fired = 0;
    timer = ResetTimer(
      clock: clock,
      onFire: () => fired++,
      timer: (delay, onFire) {
        final t = _ManualTimer(delay, onFire);
        timers.add(t);
        return t;
      },
    );
  });

  test('fires at free.resetsAt + 5 s', () {
    timer.arm(aCreditBalance().build());
    expect(timer.isArmed, isTrue);
    expect(
      timers.single.delay,
      kTestResetsAt.difference(kTestNow) + ResetTimer.margin,
    );
    timers.single.fire();
    expect(fired, 1);
    expect(timer.isArmed, isFalse);
  });

  test('fires at most once per boundary', () {
    final balance = aCreditBalance().build();
    timer.arm(balance);
    timers.single.fire();
    timer.arm(balance);
    expect(timers, hasLength(1));
    timer.arm(
      aCreditBalance()
          .withResetsAt(kTestResetsAt.add(const Duration(days: 1)))
          .build(),
    );
    expect(timers, hasLength(2));
  });

  test('a passed boundary fires after the margin only', () {
    clock.advance(const Duration(days: 1));
    timer.arm(aCreditBalance().build());
    expect(timers.single.delay, ResetTimer.margin);
  });

  test('paused: cancelled; resumed: re-armed', () {
    timer
      ..arm(aCreditBalance().build())
      ..pause();
    expect(timers.single.isActive, isFalse);
    timer.arm(aCreditBalance().build());
    expect(timers, hasLength(1));
    timer.resume();
    expect(timers, hasLength(2));
    expect(timer.isArmed, isTrue);
    timer.dispose();
    expect(timer.isArmed, isFalse);
  });

  test('no balance, no timer', () {
    timer.arm(null);
    expect(timers, isEmpty);
  });

  test('the default timer is a real one', () {
    final real = ResetTimer(clock: clock, onFire: () {})
      ..arm(aCreditBalance().build());
    expect(real.isArmed, isTrue);
    real.dispose();
  });
}
