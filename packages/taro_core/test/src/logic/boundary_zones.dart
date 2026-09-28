/// The `kBoundaryZones` matrix of 06 §2.1 as fixed test data.
///
/// `taro_core` is pure Dart and has no timezone database, so each zone is
/// its UTC offset plus, for the DST zones, the 2026 transitions (from the
/// IANA rules: America/New_York 2026-03-08 02:00 EST → EDT and 2026-11-01
/// 02:00 EDT → EST; Europe/Kyiv 2026-03-29 03:00 EET → EEST and 2026-10-25
/// 04:00 EEST → EET). Tests that use it must stay inside 2026.
library;

import 'package:taro_core/src/logic/local_dates.dart';

/// One zone of the matrix.
final class BoundaryZone {
  const BoundaryZone(this.name, this.standard, [this.transitions = const []]);

  /// IANA name.
  final String name;

  /// The UTC offset before the first transition.
  final Duration standard;

  /// `(utc instant, offset from then on)`, ascending.
  final List<(DateTime, Duration)> transitions;

  /// The UTC offset in force at [utc].
  Duration offsetAt(DateTime utc) {
    var offset = standard;
    for (final (at, o) in transitions) {
      if (!utc.isBefore(at)) offset = o;
    }
    return offset;
  }

  /// The local wall-clock time at [utc] (as a UTC-flagged DateTime).
  DateTime wallClock(DateTime utc) => utc.add(offsetAt(utc));

  /// The local date at [utc].
  String localDate(DateTime utc) => LocalDates.format(wallClock(utc));

  /// The instant of the next local midnight after [utc].
  DateTime nextMidnight(DateTime utc) {
    final tomorrow = LocalDates.addDays(localDate(utc), 1);
    final wall = DateTime.parse('${tomorrow}T00:00:00Z');
    // Re-evaluate once in case the offset changed during the day.
    return wall.subtract(offsetAt(wall.subtract(offsetAt(utc))));
  }

  /// Length of the local day that contains [utc] (23, 24 or 25 h).
  Duration dayLength(DateTime utc) {
    final today = LocalDates.addDays(localDate(utc), -1);
    final start = nextMidnight(
      DateTime.parse('${today}T12:00:00Z').subtract(offsetAt(utc)),
    );
    return nextMidnight(utc).difference(start);
  }

  @override
  String toString() => name;
}

/// 06 §2.1 `kBoundaryZones`.
final List<BoundaryZone> kBoundaryZones = [
  const BoundaryZone('UTC', Duration.zero),
  const BoundaryZone('Pacific/Kiritimati', Duration(hours: 14)),
  const BoundaryZone('Pacific/Pago_Pago', Duration(hours: -11)),
  const BoundaryZone('Asia/Kolkata', Duration(hours: 5, minutes: 30)),
  const BoundaryZone('Asia/Kathmandu', Duration(hours: 5, minutes: 45)),
  BoundaryZone('America/New_York', const Duration(hours: -5), [
    (DateTime.utc(2026, 3, 8, 7), const Duration(hours: -4)),
    (DateTime.utc(2026, 11, 1, 6), const Duration(hours: -5)),
  ]),
  BoundaryZone('Europe/Kyiv', const Duration(hours: 2), [
    (DateTime.utc(2026, 3, 29, 1), const Duration(hours: 3)),
    (DateTime.utc(2026, 10, 25, 1), const Duration(hours: 2)),
  ]),
];

/// Instants spread over 2026, including both DST transition days of each
/// DST zone and times just around them.
final List<DateTime> kBoundaryInstants = [
  DateTime.utc(2026),
  DateTime.utc(2026, 3, 8, 6, 59),
  DateTime.utc(2026, 3, 8, 7),
  DateTime.utc(2026, 3, 8, 12),
  DateTime.utc(2026, 3, 29, 0, 30),
  DateTime.utc(2026, 3, 29, 1, 30),
  DateTime.utc(2026, 6, 30, 23, 59, 59),
  DateTime.utc(2026, 9, 26, 9, 12, 44),
  DateTime.utc(2026, 10, 25, 0, 59),
  DateTime.utc(2026, 10, 25, 1),
  DateTime.utc(2026, 11, 1, 5, 30),
  DateTime.utc(2026, 11, 1, 6, 30),
  DateTime.utc(2026, 12, 31, 10),
];
