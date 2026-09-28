import 'package:taro_core/taro_core.dart';

import 'builders/defaults.dart';

/// A controllable [Clock] that is also the device [TimezoneProvider]
/// (TESTING.md: `FakeClock(DateTime, tz)` with [advance] and
/// [setTimeZone]).
///
/// The zone is a name plus a UTC offset (or an offset function for DST,
/// e.g. `kBoundaryZones`' `offsetAt`): `taro_core` has no timezone
/// database. [nowLocal] returns a non-UTC `DateTime` whose fields are the
/// wall-clock time in that zone; only its fields are meaningful (it is
/// built in the host zone, so avoid wall times inside a host DST gap).
final class FakeClock implements Clock, TimezoneProvider {
  /// A clock at [start] (default `kTestNow`) in [timeZone].
  FakeClock([
    DateTime? start,
    String timeZone = kTestTimeZone,
    Duration utcOffset = kTestUtcOffset,
  ]) : _now = (start ?? kTestNow).toUtc(),
       _timeZone = timeZone,
       _offsetAt = ((_) => utcOffset);

  /// A clock at [start] in UTC.
  FakeClock.utc([DateTime? start]) : this(start, 'UTC', Duration.zero);

  DateTime _now;
  String _timeZone;
  Duration Function(DateTime utc) _offsetAt;

  /// How often [now] or [nowLocal] was read.
  int reads = 0;

  @override
  DateTime now() {
    reads++;
    return _now;
  }

  @override
  DateTime nowLocal() {
    reads++;
    final wall = _now.add(_offsetAt(_now));
    return DateTime(
      wall.year,
      wall.month,
      wall.day,
      wall.hour,
      wall.minute,
      wall.second,
      wall.millisecond,
      wall.microsecond,
    );
  }

  @override
  Future<String> currentIana() async => _timeZone;

  /// The current zone name.
  String get timeZone => _timeZone;

  /// The UTC offset in force now.
  Duration get utcOffset => _offsetAt(_now);

  /// The device-local date now (`YYYY-MM-DD`).
  String get localDate => LocalDates.format(_now.add(_offsetAt(_now)));

  /// Moves time forward by [by] (backwards for a negative duration).
  void advance(Duration by) => _now = _now.add(by);

  /// Jumps to [instant].
  void setNow(DateTime instant) => _now = instant.toUtc();

  /// Moves the device to [iana] with a fixed [utcOffset], or a DST-aware
  /// [offsetAt].
  void setTimeZone(
    String iana, {
    Duration utcOffset = Duration.zero,
    Duration Function(DateTime utc)? offsetAt,
  }) {
    _timeZone = iana;
    _offsetAt = offsetAt ?? ((_) => utcOffset);
  }

  /// A `Delay` (see `EarnReward`) that advances this clock instead of
  /// waiting.
  Future<void> delay(Duration duration) async => advance(duration);
}

/// A [TimezoneProvider] with a settable zone (use [FakeClock] when the
/// clock must agree).
final class FakeTimezoneProvider implements TimezoneProvider {
  /// A provider reporting [iana].
  FakeTimezoneProvider([this.iana = kTestTimeZone]);

  /// The zone reported by [currentIana].
  String iana;

  @override
  Future<String> currentIana() async => iana;
}
