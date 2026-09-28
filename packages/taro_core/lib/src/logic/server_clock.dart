import 'package:meta/meta.dart';
import 'package:taro_core/src/model/credit_balance.dart';

/// The difference between Worker time and the device clock (02 §6.3,
/// 04 §5.3).
///
/// Updated from every response's `Date` header and `BalanceDto.serverTime`.
/// Countdowns ("free reading in 3 h") use `serverTime + (deviceNow −
/// receivedAt)` against `free.resetsAt`, never the raw device clock, so a
/// wrong device clock cannot move the reset.
@immutable
final class ServerClockOffset {
  /// Creates an offset; positive when the server is ahead of the device.
  const ServerClockOffset(this.offset);

  /// The offset of a response carrying [serverTime] that arrived at
  /// [receivedAt] (device clock).
  factory ServerClockOffset.fromSample({
    required DateTime serverTime,
    required DateTime receivedAt,
  }) => ServerClockOffset(serverTime.difference(receivedAt));

  /// The offset recorded by [balance] (`serverTime` vs `syncedAt`).
  factory ServerClockOffset.fromBalance(CreditBalance balance) =>
      ServerClockOffset.fromSample(
        serverTime: balance.serverTime,
        receivedAt: balance.syncedAt,
      );

  /// No skew: before the first response.
  static const ServerClockOffset zero = ServerClockOffset(Duration.zero);

  /// Server time minus device time.
  final Duration offset;

  /// The estimated server time (UTC) at device time [deviceNow].
  DateTime serverNow(DateTime deviceNow) => deviceNow.toUtc().add(offset);

  /// The device-clock instant (UTC) at which the server reaches
  /// [serverInstant]; what a device timer must be set to.
  DateTime toDevice(DateTime serverInstant) =>
      serverInstant.toUtc().subtract(offset);

  /// Time left until the server reaches [serverTarget], seen at device time
  /// [deviceNow]; never negative.
  Duration remainingUntil(DateTime serverTarget, DateTime deviceNow) =>
      _nonNegative(serverTarget.difference(serverNow(deviceNow)));

  /// The countdown of 04 §5.3 on a monotonic clock:
  /// `target − (serverTime + elapsedSinceResponse)`, never negative.
  /// [elapsedSinceResponse] comes from a monotonic stopwatch, so device
  /// wall-clock changes cannot move it.
  static Duration countdown({
    required DateTime target,
    required DateTime serverTime,
    required Duration elapsedSinceResponse,
  }) => _nonNegative(target.difference(serverTime.add(elapsedSinceResponse)));

  static Duration _nonNegative(Duration d) => d.isNegative ? Duration.zero : d;

  @override
  bool operator ==(Object other) =>
      other is ServerClockOffset && other.offset == offset;

  @override
  int get hashCode => offset.hashCode;

  @override
  String toString() => 'ServerClockOffset($offset)';
}
