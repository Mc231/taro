/// Typed values parsed from DTCG `$value`s (colours, dimensions, durations,
/// cubic Béziers, shadows, font weights).
library;

import 'dart:math' as math;

import 'package:taro_dart_tools/src/tokens/token_set.dart';

/// An sRGB colour with alpha, channels 0–255.
final class TokenColor {
  /// Creates a colour.
  const TokenColor(this.r, this.g, this.b, [this.a = 255]);

  /// Parses `#RGB`, `#RRGGBB`, `#RRGGBBAA`, `rgb(r, g, b)` or
  /// `rgba(r, g, b, a)`; throws [TokenException] (naming [where]) otherwise.
  factory TokenColor.parse(Object? value, String where) {
    if (value is! String) {
      throw TokenException('$where: colour must be a string, got $value');
    }
    final text = value.trim();
    final hex = RegExp(
      r'^#([0-9a-fA-F]{3}|[0-9a-fA-F]{6}|[0-9a-fA-F]{8})$',
    ).firstMatch(text);
    if (hex != null) {
      var digits = hex.group(1)!;
      if (digits.length == 3) {
        digits = digits.split('').map((c) => '$c$c').join();
      }
      int channel(int i) => int.parse(digits.substring(i, i + 2), radix: 16);
      return TokenColor(
        channel(0),
        channel(2),
        channel(4),
        digits.length == 8 ? channel(6) : 255,
      );
    }
    final fn = RegExp(
      r'^rgba?\(\s*([\d.]+)\s*,\s*([\d.]+)\s*,\s*([\d.]+)\s*(?:,\s*([\d.]+)\s*)?\)$',
    ).firstMatch(text);
    if (fn != null) {
      int rgb(int i) {
        final v = double.parse(fn.group(i)!);
        if (v > 255) throw TokenException('$where: channel $v > 255 in $text');
        return v.round();
      }

      final alpha = fn.group(4) == null ? 1.0 : double.parse(fn.group(4)!);
      if (alpha > 1) throw TokenException('$where: alpha $alpha > 1 in $text');
      return TokenColor(rgb(1), rgb(2), rgb(3), (alpha * 255).round());
    }
    throw TokenException('$where: unsupported colour "$text"');
  }

  /// Red channel.
  final int r;

  /// Green channel.
  final int g;

  /// Blue channel.
  final int b;

  /// Alpha channel.
  final int a;

  /// `0xAARRGGBB`.
  int get argb => (a << 24) | (r << 16) | (g << 8) | b;

  /// Dart source, e.g. `Color(0xFFEEF0F4)`.
  String get dart =>
      'Color(0x${argb.toRadixString(16).toUpperCase().padLeft(8, '0')})';

  /// This colour composited over the opaque [background].
  TokenColor over(TokenColor background) {
    final alpha = a / 255;
    int mix(int f, int bg) => (f * alpha + bg * (1 - alpha)).round();
    return TokenColor(
      mix(r, background.r),
      mix(g, background.g),
      mix(b, background.b),
    );
  }

  /// WCAG 2.x relative luminance (alpha ignored).
  double get luminance {
    double lin(int channel) {
      final c = channel / 255;
      return c <= 0.03928
          ? c / 12.92
          : math.pow((c + 0.055) / 1.055, 2.4).toDouble();
    }

    return 0.2126 * lin(r) + 0.7152 * lin(g) + 0.0722 * lin(b);
  }

  /// WCAG contrast ratio of this colour (composited over [background])
  /// against [background].
  double contrastOn(TokenColor background) {
    final fg = over(background).luminance;
    final bg = background.luminance;
    final hi = fg > bg ? fg : bg;
    final lo = fg > bg ? bg : fg;
    return (hi + 0.05) / (lo + 0.05);
  }
}

/// Formats [value] as a short Dart numeric literal (`16`, `0.58`, `-0.5`).
String dartNum(num value) {
  final d = value.toDouble();
  if (d == d.roundToDouble() && d.abs() < 1e15) return d.toInt().toString();
  return d.toString();
}

/// Parses a dimension (`16px`, `0`, `0.58`, or a number) to logical pixels.
double parseDimension(Object? value, String where) {
  if (value is num) return value.toDouble();
  if (value is Map<String, Object?> && value['value'] is num) {
    final unit = value['unit'];
    if (unit != null && unit != 'px') {
      throw TokenException('$where: unsupported unit "$unit"');
    }
    return (value['value']! as num).toDouble();
  }
  if (value is String) {
    final m = RegExp(r'^(-?[\d.]+)(px)?$').firstMatch(value.trim());
    if (m != null) return double.parse(m.group(1)!);
  }
  throw TokenException('$where: unsupported dimension "$value"');
}

/// Parses a plain number (`0.38`, `"0.38"`).
double parseNumber(Object? value, String where) {
  if (value is num) return value.toDouble();
  if (value is String) {
    final parsed = double.tryParse(value.trim());
    if (parsed != null) return parsed;
  }
  throw TokenException('$where: not a number "$value"');
}

/// Parses a duration (`100ms`, `1.2s`, `{value, unit}`) to microseconds.
int parseDurationMicros(Object? value, String where) {
  double? amount;
  String? unit;
  if (value is String) {
    final m = RegExp(r'^([\d.]+)\s*(ms|s)$').firstMatch(value.trim());
    if (m != null) {
      amount = double.parse(m.group(1)!);
      unit = m.group(2);
    }
  } else if (value is Map<String, Object?> && value['value'] is num) {
    amount = (value['value']! as num).toDouble();
    unit = value['unit'] as String?;
  }
  if (amount == null || (unit != 'ms' && unit != 's')) {
    throw TokenException('$where: unsupported duration "$value"');
  }
  return (amount * (unit == 's' ? 1000000 : 1000)).round();
}

/// Dart source for a duration of [micros].
String dartDuration(int micros) => micros % 1000 == 0
    ? 'Duration(milliseconds: ${micros ~/ 1000})'
    : 'Duration(microseconds: $micros)';

/// Parses a cubic Bézier `[x1, y1, x2, y2]`.
List<double> parseCubicBezier(Object? value, String where) {
  if (value is List && value.length == 4 && value.every((v) => v is num)) {
    return [for (final v in value) (v as num).toDouble()];
  }
  throw TokenException('$where: cubicBezier needs four numbers, got $value');
}

/// Parses a font weight (`400`, `"600"`, `"bold"`) to 100…900.
int parseFontWeight(Object? value, String where) {
  const names = {
    'thin': 100,
    'extralight': 200,
    'light': 300,
    'normal': 400,
    'regular': 400,
    'medium': 500,
    'semibold': 600,
    'bold': 700,
    'extrabold': 800,
    'black': 900,
  };
  final weight = switch (value) {
    final num n => n.toInt(),
    final String s => int.tryParse(s) ?? names[s.toLowerCase()],
    _ => null,
  };
  if (weight == null || weight < 100 || weight > 900 || weight % 100 != 0) {
    throw TokenException('$where: unsupported font weight "$value"');
  }
  return weight;
}

/// One layer of a shadow.
final class TokenShadow {
  /// Creates a layer.
  const TokenShadow({
    required this.color,
    required this.x,
    required this.y,
    required this.blur,
    this.spread = 0,
  });

  /// Colour of the layer.
  final TokenColor color;

  /// Horizontal offset, logical pixels.
  final double x;

  /// Vertical offset, logical pixels.
  final double y;

  /// Blur radius, logical pixels.
  final double blur;

  /// Spread radius, logical pixels.
  final double spread;

  /// Dart source of a `BoxShadow`.
  String get dart {
    final spreadArg = spread == 0 ? '' : ', spreadRadius: ${dartNum(spread)}';
    return 'BoxShadow(color: ${color.dart}, '
        'offset: Offset(${dartNum(x)}, ${dartNum(y)}), '
        'blurRadius: ${dartNum(blur)}$spreadArg)';
  }
}

/// Parses a shadow: `none`, a CSS `box-shadow` list, or DTCG shadow
/// object(s).
List<TokenShadow> parseShadow(Object? value, String where) {
  if (value is String) {
    final text = value.trim();
    if (text == 'none' || text.isEmpty) return const [];
    return [for (final part in _splitTopLevel(text)) _cssShadow(part, where)];
  }
  if (value is Map<String, Object?>) return [_dtcgShadow(value, where)];
  if (value is List) {
    return [
      for (final v in value)
        if (v is Map<String, Object?>)
          _dtcgShadow(v, where)
        else
          throw TokenException('$where: unsupported shadow layer "$v"'),
    ];
  }
  throw TokenException('$where: unsupported shadow "$value"');
}

List<String> _splitTopLevel(String text) {
  final parts = <String>[];
  var depth = 0;
  var start = 0;
  for (var i = 0; i < text.length; i++) {
    final c = text[i];
    if (c == '(') depth++;
    if (c == ')') depth--;
    if (c == ',' && depth == 0) {
      parts.add(text.substring(start, i).trim());
      start = i + 1;
    }
  }
  parts.add(text.substring(start).trim());
  return parts;
}

TokenShadow _cssShadow(String part, String where) {
  final colorMatch = RegExp(
    r'(rgba?\([^)]*\)|#[0-9a-fA-F]{3,8})',
  ).firstMatch(part);
  if (colorMatch == null || part.contains('inset')) {
    throw TokenException('$where: unsupported shadow "$part"');
  }
  final color = TokenColor.parse(colorMatch.group(0), where);
  final lengths = part
      .replaceFirst(colorMatch.group(0)!, ' ')
      .trim()
      .split(RegExp(r'\s+'))
      .where((s) => s.isNotEmpty)
      .map((s) => parseDimension(s, where))
      .toList();
  if (lengths.length < 2 || lengths.length > 4) {
    throw TokenException('$where: shadow needs 2–4 lengths in "$part"');
  }
  return TokenShadow(
    color: color,
    x: lengths[0],
    y: lengths[1],
    blur: lengths.length > 2 ? lengths[2] : 0,
    spread: lengths.length > 3 ? lengths[3] : 0,
  );
}

TokenShadow _dtcgShadow(Map<String, Object?> v, String where) => TokenShadow(
  color: TokenColor.parse(v['color'], where),
  x: parseDimension(v['offsetX'] ?? 0, where),
  y: parseDimension(v['offsetY'] ?? 0, where),
  blur: parseDimension(v['blur'] ?? 0, where),
  spread: parseDimension(v['spread'] ?? 0, where),
);
