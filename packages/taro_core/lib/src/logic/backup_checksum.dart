import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:taro_core/src/model/backup.dart';

/// The backup checksum (01 §7.11, 02 §12, RC70): lowercase hex SHA-256 of
/// the RFC 8785 (JCS) canonical JSON of `data`.
abstract final class BackupChecksum {
  /// The checksum of decoded `data` JSON.
  static String ofJson(Object? data) =>
      sha256.convert(utf8.encode(canonicalize(data))).toString();

  /// The checksum of [data] as it would be exported.
  static String of(BackupData data) => ofJson(data.toJson());

  /// Whether [checksum] matches decoded `data` JSON.
  static bool matches(Object? data, String checksum) =>
      ofJson(data) == checksum;

  /// The RFC 8785 canonical form of a decoded JSON value.
  ///
  /// Object members are sorted by their UTF-16 code units, there is no
  /// whitespace, strings use the ECMAScript `JSON.stringify` escapes (only
  /// `"`, `\`, and U+0000–U+001F are escaped, lone surrogates as `\udxxx`),
  /// and numbers use the ECMAScript `Number.prototype.toString` form.
  ///
  /// Throws an [ArgumentError] for a non-JSON value, a non-string key or a
  /// non-finite number.
  static String canonicalize(Object? value) {
    final out = StringBuffer();
    _write(out, value);
    return out.toString();
  }

  static void _write(StringBuffer out, Object? value) {
    switch (value) {
      case null:
        out.write('null');
      case bool():
        out.write(value ? 'true' : 'false');
      case num():
        out.write(_number(value));
      case String():
        _string(out, value);
      case List<Object?>():
        out.write('[');
        for (var i = 0; i < value.length; i++) {
          if (i > 0) out.write(',');
          _write(out, value[i]);
        }
        out.write(']');
      case Map<Object?, Object?>():
        final keys = [
          for (final k in value.keys)
            if (k is String)
              k
            else
              throw ArgumentError.value(k, 'key', 'JSON keys must be strings'),
        ]..sort(_compareUtf16);
        out.write('{');
        for (var i = 0; i < keys.length; i++) {
          if (i > 0) out.write(',');
          _string(out, keys[i]);
          out.write(':');
          _write(out, value[keys[i]]);
        }
        out.write('}');
      default:
        throw ArgumentError.value(value, 'value', 'not a JSON value');
    }
  }

  /// Compares by UTF-16 code units (RFC 8785 §3.2.3). Dart strings are
  /// UTF-16, so this is a plain code-unit comparison.
  static int _compareUtf16(String a, String b) {
    final n = a.length < b.length ? a.length : b.length;
    for (var i = 0; i < n; i++) {
      final d = a.codeUnitAt(i) - b.codeUnitAt(i);
      if (d != 0) return d;
    }
    return a.length - b.length;
  }

  static String _number(num n) {
    if (n is int) return n.toString();
    if (!n.isFinite) {
      throw ArgumentError.value(n, 'value', 'JSON numbers must be finite');
    }
    if (n == 0) return '0';
    // Dart's double.toString follows ECMAScript Number::toString except
    // that integral values get a ".0" suffix.
    final s = n.toString();
    return s.endsWith('.0') ? s.substring(0, s.length - 2) : s;
  }

  static const Map<int, String> _shortEscapes = {
    0x08: r'\b',
    0x09: r'\t',
    0x0A: r'\n',
    0x0C: r'\f',
    0x0D: r'\r',
    0x22: r'\"',
    0x5C: r'\\',
  };

  static void _string(StringBuffer out, String s) {
    out.write('"');
    for (var i = 0; i < s.length; i++) {
      final unit = s.codeUnitAt(i);
      final short = _shortEscapes[unit];
      if (short != null) {
        out.write(short);
      } else if (unit < 0x20 || _isLoneSurrogate(s, i)) {
        out
          ..write(r'\u')
          ..write(unit.toRadixString(16).padLeft(4, '0'));
      } else {
        out.writeCharCode(unit);
      }
    }
    out.write('"');
  }

  static bool _isLoneSurrogate(String s, int i) {
    final unit = s.codeUnitAt(i);
    if (unit >= 0xD800 && unit <= 0xDBFF) {
      return i + 1 >= s.length || !_isLow(s.codeUnitAt(i + 1));
    }
    if (_isLow(unit)) {
      return i == 0 || !_isHigh(s.codeUnitAt(i - 1));
    }
    return false;
  }

  static bool _isHigh(int u) => u >= 0xD800 && u <= 0xDBFF;

  static bool _isLow(int u) => u >= 0xDC00 && u <= 0xDFFF;
}
