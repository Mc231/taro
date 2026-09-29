import 'dart:async';
import 'dart:io';

import 'package:taro_core/taro_core.dart';

/// Keeps the current [ServerClockOffset] (02 §6.3, 04 §5.3).
///
/// Updated from the `Date` header of every Worker response and from every
/// `BalanceDto.serverTime`. Countdowns use it, never the raw device clock.
final class ServerClockTracker {
  /// A tracker starting at [ServerClockOffset.zero].
  ServerClockTracker({ServerClockOffset initial = ServerClockOffset.zero})
    : _current = initial;

  ServerClockOffset _current;
  final StreamController<ServerClockOffset> _changes =
      StreamController<ServerClockOffset>.broadcast(sync: true);

  /// The latest offset.
  ServerClockOffset get current => _current;

  /// Emits every changed offset.
  Stream<ServerClockOffset> get changes => _changes.stream;

  /// Records a response whose server time is [serverTime], received at
  /// device time [receivedAt].
  void record({required DateTime serverTime, required DateTime receivedAt}) {
    final next = ServerClockOffset.fromSample(
      serverTime: serverTime,
      receivedAt: receivedAt,
    );
    if (next == _current) return;
    _current = next;
    _changes.add(next);
  }

  /// Records the RFC 7231 `Date` header [value]; ignores a missing or
  /// malformed value.
  void recordDateHeader(String? value, {required DateTime receivedAt}) {
    if (value == null) return;
    final DateTime serverTime;
    try {
      serverTime = HttpDate.parse(value);
    } on Exception {
      return;
    }
    record(serverTime: serverTime, receivedAt: receivedAt);
  }

  /// Closes [changes].
  Future<void> dispose() => _changes.close();
}
