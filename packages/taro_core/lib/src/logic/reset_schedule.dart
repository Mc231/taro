import 'package:taro_core/src/logic/server_clock.dart';
import 'package:taro_core/src/model/credit_balance.dart';

/// When the foreground reset timer fires (02 §4.1, `ResetTimer`).
///
/// The Worker owns the day boundary (`free.resetsAt`, computed from server
/// UTC and the install's IANA zone, 04 §5.4); the client only schedules a
/// `GET /v1/balance` at that instant, translated to the device clock.
abstract final class ResetSchedule {
  /// The device-clock instant (UTC) at which to sync: `free.resetsAt`
  /// shifted by [offset] (default: the skew recorded in [balance]), or
  /// [now] when that moment has already passed.
  static DateTime nextSyncAt(
    CreditBalance balance,
    DateTime now, {
    ServerClockOffset? offset,
  }) {
    final skew = offset ?? ServerClockOffset.fromBalance(balance);
    final at = skew.toDevice(balance.free.resetsAt);
    final nowUtc = now.toUtc();
    return at.isAfter(nowUtc) ? at : nowUtc;
  }

  /// The timer delay from device time [now] to [nextSyncAt]; zero when the
  /// sync is due.
  static Duration delayUntilSync(
    CreditBalance balance,
    DateTime now, {
    ServerClockOffset? offset,
  }) => nextSyncAt(balance, now, offset: offset).difference(now.toUtc());

  /// Time left until the next free reading as shown in the UI ("free
  /// reading in 3 h"), on the server clock; zero once it is due.
  static Duration untilNextFree(
    CreditBalance balance,
    DateTime now, {
    ServerClockOffset? offset,
  }) =>
      (offset ??
              ServerClockOffset.fromBalance(
                balance,
              ))
          .remainingUntil(balance.free.resetsAt, now);
}
