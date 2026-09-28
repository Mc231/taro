/// `YYYY-MM-DD` local-date arithmetic (calendar days, no timezone).
abstract final class LocalDates {
  /// Days since 1970-01-01 of [localDate]; throws a [FormatException] if it
  /// is not a real `YYYY-MM-DD` date.
  static int toDay(String localDate) {
    final m = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(localDate);
    if (m != null) {
      final y = int.parse(m.group(1)!);
      final mo = int.parse(m.group(2)!);
      final d = int.parse(m.group(3)!);
      final dt = DateTime.utc(y, mo, d);
      if (dt.year == y && dt.month == mo && dt.day == d) {
        return dt.millisecondsSinceEpoch ~/ Duration.millisecondsPerDay;
      }
    }
    throw FormatException('Not a YYYY-MM-DD date', localDate);
  }

  /// The `YYYY-MM-DD` of a day number from [toDay].
  static String fromDay(int day) => format(
    DateTime.fromMillisecondsSinceEpoch(
      day * Duration.millisecondsPerDay,
      isUtc: true,
    ),
  );

  /// The `YYYY-MM-DD` of [wallClock]'s own year, month and day fields (pass
  /// a device-local time, e.g. `Clock.nowLocal()`).
  static String format(DateTime wallClock) =>
      '${wallClock.year.toString().padLeft(4, '0')}-'
      '${wallClock.month.toString().padLeft(2, '0')}-'
      '${wallClock.day.toString().padLeft(2, '0')}';

  /// [localDate] shifted by [days] calendar days.
  static String addDays(String localDate, int days) =>
      fromDay(toDay(localDate) + days);
}
