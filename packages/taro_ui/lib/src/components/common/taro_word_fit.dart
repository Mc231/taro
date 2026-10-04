import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// The text scaler at which the widest word of [text] fits in [maxWidth],
/// or null when it already fits at [scaler]. Internal to `taro_ui`.
///
/// Words are split at whitespace, so a label without spaces (a German
/// compound, a CJK phrase) counts as one word. Text drawn with the result
/// wraps only between words and never inside one ("Vergangen / heit",
/// BUG-05, BUG-08). [style] must be the full style the text is drawn with.
TextScaler? taroWordFitScaler({
  required String text,
  required TextStyle style,
  required TextScaler scaler,
  required double maxWidth,
  required TextDirection direction,
}) {
  if (!maxWidth.isFinite || maxWidth <= 0) return null;
  double widest(TextScaler s) {
    var result = 0.0;
    for (final word in text.split(RegExp(r'\s+'))) {
      if (word.isEmpty) continue;
      final painter = TextPainter(
        text: TextSpan(text: word, style: style),
        textDirection: direction,
        textScaler: s,
        maxLines: 1,
      )..layout();
      result = math.max(result, painter.maxIntrinsicWidth);
      painter.dispose();
    }
    return result;
  }

  final width = widest(scaler);
  if (width <= maxWidth) return null;
  final fontSize = style.fontSize ?? kDefaultFontSize;
  var factor = scaler.scale(fontSize) / fontSize * maxWidth / width;
  // Glyph metrics do not scale exactly linearly: step down until it fits.
  for (var i = 0; i < 8; i++) {
    if (widest(TextScaler.linear(factor)) <= maxWidth) break;
    factor *= 0.97;
  }
  return TextScaler.linear(factor);
}
