import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:taro_ui/src/components/actions/taro_button.dart';
import 'package:taro_ui/src/motion/taro_motion.dart';
import 'package:taro_ui/src/theme/taro_tokens_extension.dart';
import 'package:taro_ui/src/tokens/taro_strokes.dart';

/// Where the arrow of a [TaroCoachmark] points.
enum TaroCoachmarkArrow {
  /// Up, at a target above the bubble.
  up,

  /// Down, at a target below the bubble.
  down,

  /// No arrow.
  none,
}

/// The single dismissible first-run coachmark bubble (S05 `firstRun`,
/// `TodayFirstRun.dc.html`): `color.bg.surfaceRaised`, `radius.md`,
/// `elevation.3`, a title, a body and the "Got it" button, with an arrow
/// towards the target.
///
/// Use it inside a [TaroCoachmarkLayer], which dims the content around the
/// target and positions the bubble. The bubble is announced as a live
/// region when it appears.
class TaroCoachmark extends StatelessWidget {
  /// Creates the bubble.
  const TaroCoachmark({
    required this.title,
    required this.body,
    required this.dismissLabel,
    required this.onDismiss,
    this.arrow = TaroCoachmarkArrow.none,
    this.arrowOffset,
    super.key,
  });

  /// Localised title.
  final String title;

  /// Localised body.
  final String body;

  /// Localised dismiss label ("Got it").
  final String dismissLabel;

  /// Dismisses the coachmark (the app persists that it was seen).
  final VoidCallback onDismiss;

  /// The arrow direction.
  final TaroCoachmarkArrow arrow;

  /// Distance of the arrow tip from the bubble's start edge (defaults to
  /// `space.9`).
  final double? arrowOffset;

  /// Returns a copy pointing [arrow] at [arrowOffset].
  TaroCoachmark pointing(TaroCoachmarkArrow arrow, double arrowOffset) =>
      TaroCoachmark(
        title: title,
        body: body,
        dismissLabel: dismissLabel,
        onDismiss: onDismiss,
        arrow: arrow,
        arrowOffset: arrowOffset,
        key: key,
      );

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final c = tokens.color;
    final arrowSize = tokens.space.s5;
    final bubble = Container(
      padding: EdgeInsetsDirectional.all(tokens.space.s5),
      decoration: BoxDecoration(
        color: c.bg.surfaceRaised,
        borderRadius: BorderRadius.circular(tokens.radius.md),
        border: Border.all(
          color: c.border.strong,
        ),
        boxShadow: tokens.elevation.e3.shadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            liveRegion: true,
            child: Text(
              title,
              style: tokens.typography.cardName.copyWith(
                color: c.text.primary,
              ),
            ),
          ),
          SizedBox(height: tokens.space.s2),
          Text(
            body,
            style: tokens.typography.body.copyWith(color: c.text.secondary),
          ),
          SizedBox(height: tokens.space.s4),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TaroButton.primary(
              label: dismissLabel,
              expand: false,
              onPressed: onDismiss,
            ),
          ),
        ],
      ),
    );
    if (arrow == TaroCoachmarkArrow.none) {
      return Semantics(container: true, child: bubble);
    }
    final tip = Padding(
      padding: EdgeInsetsDirectional.only(
        start: (arrowOffset ?? tokens.space.s9) - arrowSize / 2,
      ),
      child: CustomPaint(
        size: Size(arrowSize, arrowSize / 2),
        painter: _ArrowPainter(
          color: c.bg.surfaceRaised,
          border: c.border.strong,
          up: arrow == TaroCoachmarkArrow.up,
        ),
      ),
    );
    return Semantics(
      container: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (arrow == TaroCoachmarkArrow.up) tip,
          bubble,
          if (arrow == TaroCoachmarkArrow.down) tip,
        ],
      ),
    );
  }
}

class _ArrowPainter extends CustomPainter {
  const _ArrowPainter({
    required this.color,
    required this.border,
    required this.up,
  });

  final Color color;
  final Color border;
  final bool up;

  @override
  void paint(Canvas canvas, Size size) {
    final path = up
        ? (Path()
            ..moveTo(0, size.height)
            ..lineTo(size.width / 2, 0)
            ..lineTo(size.width, size.height))
        : (Path()
            ..moveTo(0, 0)
            ..lineTo(size.width / 2, size.height)
            ..lineTo(size.width, 0));
    canvas
      ..drawPath(path, Paint()..color = color)
      ..drawPath(
        path,
        Paint()
          ..color = border
          ..style = PaintingStyle.stroke
          ..strokeWidth = TaroStrokes.hairline,
      );
  }

  @override
  bool shouldRepaint(_ArrowPainter old) =>
      old.color != color || old.border != border || old.up != up;
}

/// Shows a [TaroCoachmark] over [child]: dims it with `color.bg.scrim`
/// except a hole around the widget of [targetKey], and places the bubble
/// above or below the target with its arrow pointing at it.
///
/// Wrap only the screen *body* (inside `TaroScaffold`), so the scrim never
/// covers the banner container or the tab bar (RC59). A tap on the scrim
/// dismisses too; the target inside the hole stays tappable. The bubble
/// fades in over `motion.duration.base` (reduced motion: the reduced
/// token). With `visible == false` it is just [child].
class TaroCoachmarkLayer extends StatefulWidget {
  /// Creates the layer.
  const TaroCoachmarkLayer({
    required this.child,
    required this.coachmark,
    required this.targetKey,
    this.visible = true,
    super.key,
  });

  /// The screen body.
  final Widget child;

  /// The bubble; its `onDismiss` also handles scrim taps.
  final TaroCoachmark coachmark;

  /// The key of the highlighted target.
  final GlobalKey targetKey;

  /// Whether the coachmark shows.
  final bool visible;

  @override
  State<TaroCoachmarkLayer> createState() => _TaroCoachmarkLayerState();
}

class _TaroCoachmarkLayerState extends State<TaroCoachmarkLayer> {
  final GlobalKey _layerKey = GlobalKey();
  Rect? _target;

  void _measure() {
    if (!mounted) return;
    final layer = _layerKey.currentContext?.findRenderObject() as RenderBox?;
    final target =
        widget.targetKey.currentContext?.findRenderObject() as RenderBox?;
    Rect? rect;
    if (layer != null && target != null && target.attached) {
      final origin = target.localToGlobal(Offset.zero, ancestor: layer);
      rect = origin & target.size;
    }
    if (rect != _target) setState(() => _target = rect);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.visible) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
    }
    final tokens = context.tokens;
    final motion = context.motion;
    return Stack(
      key: _layerKey,
      children: [
        widget.child,
        if (widget.visible && _target != null)
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final target = _target!;
                final layer = constraints.biggest;
                final gap = tokens.space.s3;
                final hole = target.inflate(tokens.space.s2);
                final below = target.center.dy < layer.height / 2;
                final rtl = Directionality.of(context) == TextDirection.rtl;
                // The bubble keeps the content column on wide screens.
                final width = math.min(
                  layer.width - 2 * tokens.layout.gutter,
                  tokens.layout.maxContentWidth,
                );
                final inset = (layer.width - width) / 2;
                final startX = rtl
                    ? layer.width - inset - target.center.dx
                    : target.center.dx - inset;
                final bubble = widget.coachmark.pointing(
                  below ? TaroCoachmarkArrow.up : TaroCoachmarkArrow.down,
                  startX.clamp(tokens.space.s7, width),
                );
                return TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: motion.duration.base,
                  curve: motion.easing.standard,
                  builder: (context, t, child) =>
                      Opacity(opacity: t, child: child),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: ExcludeSemantics(
                          // The scrim takes taps everywhere but the hole:
                          // the highlighted target stays usable.
                          child: GestureDetector(
                            behavior: HitTestBehavior.deferToChild,
                            onTap: widget.coachmark.onDismiss,
                            child: CustomPaint(
                              painter: _ScrimPainter(
                                color: tokens.color.bg.scrim,
                                hole: RRect.fromRectAndRadius(
                                  hole,
                                  Radius.circular(tokens.radius.lg),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      PositionedDirectional(
                        start: inset,
                        end: inset,
                        top: below ? hole.bottom + gap : null,
                        bottom: below ? null : layer.height - hole.top + gap,
                        child: bubble,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _ScrimPainter extends CustomPainter {
  const _ScrimPainter({required this.color, required this.hole});

  final Color color;
  final RRect hole;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size)
      ..addRRect(hole);
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool? hitTest(Offset position) => !hole.contains(position);

  @override
  bool shouldRepaint(_ScrimPainter old) =>
      old.color != color || old.hole != hole;
}
