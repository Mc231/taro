import 'dart:async';

import 'package:taro_core/taro_core.dart';

/// Creates a one-shot timer (injected in tests).
typedef TimerFactory = Timer Function(Duration delay, void Function() onFire);

Timer _realTimer(Duration delay, void Function() onFire) =>
    Timer(delay, onFire);

/// Fires a sync at the Worker's day boundary while the app is in the
/// foreground (02 §9.2, rule 6): at `free.resetsAt + 5 s` on the device
/// clock (the server skew applied, `ResetSchedule`). Cancelled on pause,
/// re-armed on resume and whenever a new balance arrives.
final class ResetTimer {
  /// A timer calling [onFire] (normally `SyncCoordinator.run(resetBoundary)`).
  ResetTimer({
    required Clock clock,
    required void Function() onFire,
    TimerFactory timer = _realTimer,
  }) : _clock = clock,
       _onFire = onFire,
       _timer = timer;

  /// The margin after `free.resetsAt` (the Worker applies the reset
  /// idempotently on `GET /v1/balance`).
  static const Duration margin = Duration(seconds: 5);

  final Clock _clock;
  final void Function() _onFire;
  final TimerFactory _timer;

  Timer? _pending;
  CreditBalance? _balance;
  bool _foreground = true;
  DateTime? _firedFor;

  /// Whether a timer is armed.
  bool get isArmed => _pending?.isActive ?? false;

  /// Arms (or re-arms) the timer for [balance]; a `null` balance or a
  /// backgrounded app only remembers it.
  void arm(CreditBalance? balance) {
    _balance = balance;
    _schedule();
  }

  /// The app came to the foreground: re-arm for the last balance.
  void resume() {
    _foreground = true;
    _schedule();
  }

  /// The app went to the background: nothing fires until [resume].
  void pause() {
    _foreground = false;
    _cancel();
  }

  /// Stops the timer for good.
  void dispose() => pause();

  void _schedule() {
    _cancel();
    final balance = _balance;
    if (!_foreground || balance == null) return;
    final resetsAt = balance.free.resetsAt;
    // Fire at most once per boundary: a stale balance whose boundary has
    // passed must not loop.
    if (_firedFor == resetsAt) return;
    final delay = ResetSchedule.delayUntilSync(balance, _clock.now()) + margin;
    _pending = _timer(delay, () {
      _pending = null;
      _firedFor = resetsAt;
      _onFire();
    });
  }

  void _cancel() {
    _pending?.cancel();
    _pending = null;
  }
}
