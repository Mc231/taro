/// Strict JSON readers shared by the model mappers (not exported).
///
/// Every reader throws a [FormatException] naming the offending key when a
/// value is missing or has the wrong type, so a mapper either returns a fully
/// typed model or fails loudly; the data layer maps the exception to a
/// `Failure`.
library;

/// A decoded JSON object.
typedef JsonMap = Map<String, Object?>;

/// Reads the required value at [key] as a [T].
T req<T extends Object>(JsonMap json, String key) {
  final value = json[key];
  if (value is T) return value;
  throw FormatException('"$key" must be a $T', value);
}

/// Reads the optional value at [key] as a [T]; `null` when absent or null.
T? opt<T extends Object>(JsonMap json, String key) {
  final value = json[key];
  if (value == null || value is T) return value as T?;
  throw FormatException('"$key" must be a $T or null', value);
}

/// Reads a required integer; a JSON number with no fraction is accepted.
int reqInt(JsonMap json, String key) => _toInt(key, req<num>(json, key));

/// Reads an optional integer.
int? optInt(JsonMap json, String key) {
  final value = opt<num>(json, key);
  return value == null ? null : _toInt(key, value);
}

int _toInt(String key, num value) {
  if (value is int) return value;
  if (value.isFinite && value == value.truncate()) return value.toInt();
  throw FormatException('"$key" must be an integer', value);
}

/// Reads a required nested object.
JsonMap reqMap(JsonMap json, String key) =>
    req<Map<String, Object?>>(json, key);

/// Reads an optional nested object.
JsonMap? optMap(JsonMap json, String key) =>
    opt<Map<String, Object?>>(json, key);

/// Reads a required list of objects.
List<JsonMap> reqMaps(JsonMap json, String key) => [
  for (final item in req<List<Object?>>(json, key))
    if (item is Map<String, Object?>)
      item
    else
      throw FormatException('"$key" must contain only objects', item),
];

/// Reads a required list of strings.
List<String> reqStrings(JsonMap json, String key) => [
  for (final item in req<List<Object?>>(json, key))
    if (item is String)
      item
    else
      throw FormatException('"$key" must contain only strings', item),
];

/// Reads a required UTC instant (ISO 8601).
DateTime reqInstant(JsonMap json, String key) =>
    parseInstant(key, req<String>(json, key));

/// Reads an optional UTC instant (ISO 8601).
DateTime? optInstant(JsonMap json, String key) {
  final raw = opt<String>(json, key);
  return raw == null ? null : parseInstant(key, raw);
}

/// Parses [raw] as an ISO 8601 date-time and converts it to UTC.
DateTime parseInstant(String key, String raw) {
  final parsed = DateTime.tryParse(raw);
  if (parsed == null) {
    throw FormatException('"$key" must be an ISO 8601 date-time', raw);
  }
  return parsed.toUtc();
}

/// Reads a required enum value by its wire name.
T reqEnum<T>(JsonMap json, String key, Map<String, T> byWire) {
  final raw = req<String>(json, key);
  return byWire[raw] ?? (throw FormatException('"$key" is unknown', raw));
}

/// Reads an optional enum value by its wire name.
T? optEnum<T>(JsonMap json, String key, Map<String, T> byWire) {
  final raw = opt<String>(json, key);
  if (raw == null) return null;
  return byWire[raw] ?? (throw FormatException('"$key" is unknown', raw));
}

/// Formats [instant] as UTC ISO 8601 with a `Z` suffix and no fraction when
/// the fraction is zero (`2026-09-26T08:15:00Z`), matching the wire and
/// backup examples (01 §7.11, 03 §5.1).
String formatInstant(DateTime instant) {
  final utc = instant.toUtc();
  String two(int n) => n.toString().padLeft(2, '0');
  final date =
      '${utc.year.toString().padLeft(4, '0')}-${two(utc.month)}-'
      '${two(utc.day)}T${two(utc.hour)}:${two(utc.minute)}:${two(utc.second)}';
  final ms = utc.millisecond;
  final us = utc.microsecond;
  if (ms == 0 && us == 0) return '${date}Z';
  final fraction = us == 0
      ? ms.toString().padLeft(3, '0')
      : (ms * 1000 + us).toString().padLeft(6, '0');
  return '$date.${fraction}Z';
}

/// A `YYYY-MM-DD` local date (01 §10.4, backup `localDate`).
final RegExp localDatePattern = RegExp(r'^\d{4}-\d{2}-\d{2}$');

/// Reads a required `YYYY-MM-DD` local date.
String reqLocalDate(JsonMap json, String key) {
  final raw = req<String>(json, key);
  if (!localDatePattern.hasMatch(raw)) {
    throw FormatException('"$key" must be YYYY-MM-DD', raw);
  }
  return raw;
}
