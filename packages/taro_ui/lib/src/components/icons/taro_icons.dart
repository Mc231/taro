import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:taro_ui/src/components/deck/taro_card_ornament.dart';
import 'package:taro_ui/src/theme/taro_tokens_extension.dart';
import 'package:taro_ui/src/tokens/taro_strokes.dart';

/// The custom Taro glyphs used next to Material Symbols Rounded (weight
/// 300): the four suits, the Major Arcana star, a card and a spread
/// (`docs/design/components.md` § SuitGlyph).
///
/// Drawn on the Material 24 × 24 grid with the Rounded 1.5 px stroke
/// ([TaroStrokes.control]), scaled with the icon size. Glyphs are art:
/// never mirrored in RTL.
enum TaroIcons {
  /// The Major Arcana eight-point star.
  majorStar,

  /// Wands: a budding staff.
  wand,

  /// Cups: a chalice.
  cup,

  /// Swords: an upright sword.
  sword,

  /// Pentacles: a pentagram in a ring.
  pentacle,

  /// A single card outline.
  card,

  /// Three cards in a row (spreads).
  spread,
}

/// Draws one [TaroIcons] glyph in the ambient icon colour.
class TaroIcon extends StatelessWidget {
  /// Creates the icon. Without [semanticsLabel] it is decorative.
  const TaroIcon(
    this.glyph, {
    this.size,
    this.color,
    this.semanticsLabel,
    super.key,
  });

  /// The glyph.
  final TaroIcons glyph;

  /// Edge length; defaults to `size.icon.md`.
  final double? size;

  /// Stroke colour; defaults to the `IconTheme` colour, else
  /// `color.text.primary`.
  final Color? color;

  /// Localised label; null excludes the icon from semantics.
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final extent = size ?? tokens.size.icon.md;
    final paint = CustomPaint(
      size: Size.square(extent),
      painter: TaroGlyphPainter(
        glyph,
        color:
            color ?? IconTheme.of(context).color ?? tokens.color.text.primary,
      ),
    );
    if (semanticsLabel == null) return ExcludeSemantics(child: paint);
    return Semantics(
      image: true,
      label: semanticsLabel,
      excludeSemantics: true,
      child: paint,
    );
  }
}

/// Paints a [TaroIcons] glyph scaled from the 24-unit grid.
class TaroGlyphPainter extends CustomPainter {
  /// Creates the painter.
  const TaroGlyphPainter(this.glyph, {required this.color});

  /// The glyph.
  final TaroIcons glyph;

  /// The stroke colour.
  final Color color;

  static const double _grid = 24;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.shortestSide / _grid;
    canvas
      ..save()
      ..scale(scale);
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = TaroStrokes.control
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    for (final path in pathsOf(glyph)) {
      canvas.drawPath(path, stroke);
    }
    canvas.restore();
  }

  /// The glyph's stroked paths on the 24-unit grid (the icon's art data).
  static List<Path> pathsOf(TaroIcons glyph) {
    const c = Offset(12, 12);
    Path line(double x1, double y1, double x2, double y2) => Path()
      ..moveTo(x1, y1)
      ..lineTo(x2, y2);
    RRect box(double l, double t, double r, double b, double radius) =>
        RRect.fromLTRBR(l, t, r, b, Radius.circular(radius));
    return switch (glyph) {
      TaroIcons.majorStar => [starPath(c, 9, 4, 8)],
      TaroIcons.wand => [
        line(6, 19, 16, 7),
        Path()..addOval(
          Rect.fromCircle(center: const Offset(17, 5.5), radius: 1.5),
        ),
        line(12.5, 11, 10.5, 9),
        line(14, 12.5, 16.5, 12.5),
      ],
      TaroIcons.cup => [
        Path()
          ..moveTo(6, 4)
          ..lineTo(18, 4)
          ..lineTo(18, 8)
          ..arcToPoint(const Offset(6, 8), radius: const Radius.circular(6))
          ..close(),
        line(12, 14, 12, 19),
        line(8, 20, 16, 20),
      ],
      TaroIcons.sword => [
        line(12, 3, 12, 15),
        line(8, 15, 16, 15),
        line(12, 15, 12, 19),
        Path()..addOval(
          Rect.fromCircle(center: const Offset(12, 20.5), radius: 1.5),
        ),
      ],
      TaroIcons.pentacle => [
        Path()..addOval(Rect.fromCircle(center: c, radius: 9)),
        _pentagram(c, 6.5),
      ],
      TaroIcons.card => [Path()..addRRect(box(7, 3, 17, 21, 2))],
      TaroIcons.spread => [
        Path()..addRRect(box(2.5, 7, 8, 17, 1.5)),
        Path()..addRRect(box(9.25, 7, 14.75, 17, 1.5)),
        Path()..addRRect(box(16, 7, 21.5, 17, 1.5)),
      ],
    };
  }

  static Path _pentagram(Offset center, double radius) {
    final path = Path();
    for (var i = 0; i <= 5; i++) {
      final angle = -math.pi / 2 + (i * 2 % 5) * 2 * math.pi / 5;
      final point =
          center + Offset(math.cos(angle) * radius, math.sin(angle) * radius);
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    return path;
  }

  @override
  bool shouldRepaint(TaroGlyphPainter oldDelegate) =>
      oldDelegate.glyph != glyph || oldDelegate.color != color;
}
