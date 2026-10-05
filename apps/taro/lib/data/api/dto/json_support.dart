import 'package:json_annotation/json_annotation.dart';

/// A decoded JSON object as `json_serializable` expects it.
typedef JsonObject = Map<String, dynamic>;

/// ISO 8601 instants (03 §2.1: UTC with a `Z` suffix). A value without a
/// zone designator is rejected, so a local time never sneaks in.
final class UtcInstantConverter implements JsonConverter<DateTime, String> {
  /// Creates the converter.
  const UtcInstantConverter();

  @override
  DateTime fromJson(String json) => parseUtcInstant(json);

  @override
  String toJson(DateTime object) => formatUtcInstant(object);
}

/// The nullable form of [UtcInstantConverter].
final class NullableUtcInstantConverter
    implements JsonConverter<DateTime?, String?> {
  /// Creates the converter.
  const NullableUtcInstantConverter();

  @override
  DateTime? fromJson(String? json) =>
      json == null ? null : parseUtcInstant(json);

  @override
  String? toJson(DateTime? object) =>
      object == null ? null : formatUtcInstant(object);
}

/// A crisis resource's `verifiedAt` (03 §9.5): the source carries a
/// `YYYY-MM-DD` calendar date, read as UTC midnight; a zoned instant is also
/// accepted. `null` stays `null` (unverified).
final class NullableVerifiedDateConverter
    implements JsonConverter<DateTime?, String?> {
  /// Creates the converter.
  const NullableVerifiedDateConverter();

  @override
  DateTime? fromJson(String? json) {
    if (json == null) return null;
    if (!_localDate.hasMatch(json)) return parseUtcInstant(json);
    final [y, m, d] = json.split('-').map(int.parse).toList();
    return DateTime.utc(y, m, d);
  }

  @override
  String? toJson(DateTime? object) =>
      object?.toUtc().toIso8601String().substring(0, 10);
}

final RegExp _zoned = RegExp(r'(Z|[+-]\d\d:?\d\d)$');
final RegExp _localDate = RegExp(r'^\d{4}-\d{2}-\d{2}$');

/// Parses a zoned ISO 8601 instant into UTC; throws a [FormatException].
DateTime parseUtcInstant(String raw) {
  final parsed = DateTime.tryParse(raw);
  if (parsed == null || !_zoned.hasMatch(raw)) {
    throw FormatException('Not a zoned ISO 8601 instant', raw);
  }
  return parsed.toUtc();
}

/// Formats [instant] as UTC ISO 8601 with a `Z`; milliseconds only when
/// they are not zero (`2026-09-26T09:10:02Z`).
String formatUtcInstant(DateTime instant) {
  final iso = instant.toUtc().toIso8601String();
  return iso.endsWith('.000Z') ? '${iso.substring(0, iso.length - 5)}Z' : iso;
}

/// Checks a `YYYY-MM-DD` local date; throws a [FormatException].
String checkLocalDate(String raw) {
  if (!_localDate.hasMatch(raw)) {
    throw FormatException('Not a YYYY-MM-DD date', raw);
  }
  return raw;
}

/// Looks [wire] up in [values]; throws a [FormatException] naming [field]
/// for an unknown value.
T wireEnum<T>(Map<String, T> values, String wire, String field) =>
    values[wire] ??
    (throw FormatException('"$field" has an unknown value', wire));

/// [wireEnum] for an optional value.
T? optWireEnum<T>(Map<String, T> values, String? wire, String field) =>
    wire == null ? null : wireEnum(values, wire, field);
