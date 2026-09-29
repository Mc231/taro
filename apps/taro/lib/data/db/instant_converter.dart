import 'package:drift/drift.dart';

/// Stores an instant as UTC microseconds since the epoch in an `INT`
/// column (02 §6.1 `*_at INT`), so a stored `DateTime` reads back equal
/// (microsecond precision, always UTC).
final class InstantConverter extends TypeConverter<DateTime, int> {
  /// Creates the converter.
  const InstantConverter();

  @override
  DateTime fromSql(int fromDb) =>
      DateTime.fromMicrosecondsSinceEpoch(fromDb, isUtc: true);

  @override
  int toSql(DateTime value) => value.microsecondsSinceEpoch;
}
