import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:taro_ui/src/tokens/taro_strokes.dart';

/// Paints the Taro card-back ornament: a blue field, an ochre double frame,
/// a ring and the eight-point star. Shared by `TaroCardBack` and
/// `TaroBrandMark` (the mark is the card back, 01 §14).
///
/// The geometry is the one of `docs/design/assets/splash/splash-mark.svg`
/// (a 96 × 164 artboard), expressed as fractions of the card width so the
/// ornament scales with every `size.card.*`. Strokes never go below
/// [TaroStrokes.hairline].
class TaroCardOrnamentPainter extends CustomPainter {
  /// Creates the painter with the `color.card.back` [field] and the
  /// `color.card.frame` [frame] colour.
  const TaroCardOrnamentPainter({required this.field, required this.frame});

  /// The field colour (`color.card.back`).
  final Color field;

  /// The ornament colour (`color.card.frame`).
  final Color frame;

  // Artboard geometry (splash-mark.svg), as fractions of the 96 px width.
  static const double _artboard = 96;
  static const double _outerInset = 6 / _artboard;
  static const double _outerRadius = 6 / _artboard;
  static const double _outerStroke = 2 / _artboard;
  static const double _innerInset = 10.5 / _artboard;
  static const double _innerRadius = 4 / _artboard;
  static const double _innerStroke = 0.75 / _artboard;
  static const double _ring = 31 / _artboard;
  static const double _ringStroke = 1 / _artboard;
  static const double _starOuter = 26 / _artboard;
  static const double _starInner = 11 / _artboard;
  static const int _starPoints = 8;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    canvas.drawRect(Offset.zero & size, Paint()..color = field);
    Paint stroke(double fraction) => Paint()
      ..color = frame
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(TaroStrokes.hairline, fraction * w);
    RRect inset(double fraction, double radius) => RRect.fromRectAndRadius(
      (Offset.zero & size).deflate(fraction * w),
      Radius.circular(radius * w),
    );
    canvas
      ..drawRRect(inset(_outerInset, _outerRadius), stroke(_outerStroke))
      ..drawRRect(inset(_innerInset, _innerRadius), stroke(_innerStroke));
    final center = size.center(Offset.zero);
    canvas
      ..drawCircle(center, _ring * w, stroke(_ringStroke))
      ..drawPath(
        starPath(center, _starOuter * w, _starInner * w, _starPoints),
        Paint()..color = frame,
      );
  }

  @override
  bool shouldRepaint(TaroCardOrnamentPainter oldDelegate) =>
      oldDelegate.field != field || oldDelegate.frame != frame;
}

/// A [points]-point star centred on [center], its first point straight up.
Path starPath(Offset center, double outer, double inner, int points) {
  final path = Path();
  final step = math.pi / points;
  for (var i = 0; i < points * 2; i++) {
    final radius = i.isEven ? outer : inner;
    final angle = -math.pi / 2 + i * step;
    final point =
        center + Offset(math.cos(angle) * radius, math.sin(angle) * radius);
    if (i == 0) {
      path.moveTo(point.dx, point.dy);
    } else {
      path.lineTo(point.dx, point.dy);
    }
  }
  return path..close();
}
