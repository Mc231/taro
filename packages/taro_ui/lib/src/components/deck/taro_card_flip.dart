import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:taro_ui/src/a11y/taro_haptics.dart';
import 'package:taro_ui/src/motion/taro_motion.dart';

/// Turns a card from its [back] to its [face] (02 §14.3).
///
/// Setting [revealed] to true starts the flip after [staggerIndex] ×
/// `motion.ritual.dealStagger` (cards of a spread reveal in order). The flip
/// is a Y-axis rotation over `motion.ritual.flip` with
/// `motion.easing.emphasized` and plays `haptic.flip`; under reduced motion
/// it is a cross-fade of the reduced `motion.ritual.flip` (≤ 200 ms, 01
/// §14.4). Only the visible side is in the semantics tree. Setting
/// [revealed] back to false shows the back again without animation.
class TaroCardFlip extends StatefulWidget {
  /// Creates the flip.
  const TaroCardFlip({
    required this.back,
    required this.face,
    required this.revealed,
    this.staggerIndex = 0,
    this.haptics = true,
    this.onFlipped,
    super.key,
  });

  /// The face-down side (usually a `TaroCardBack`).
  final Widget back;

  /// The revealed side (usually a `TaroCardFace`).
  final Widget face;

  /// Whether the face is shown.
  final bool revealed;

  /// Position in the reveal order; delays the start by
  /// `motion.ritual.dealStagger` per step.
  final int staggerIndex;

  /// Whether the flip plays `haptic.flip`.
  final bool haptics;

  /// Called once the face is fully shown.
  final VoidCallback? onFlipped;

  @override
  State<TaroCardFlip> createState() => _TaroCardFlipState();
}

class _TaroCardFlipState extends State<TaroCardFlip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    value: widget.revealed ? 1 : 0,
  )..addStatusListener(_onStatus);
  Timer? _delay;

  @override
  void didUpdateWidget(TaroCardFlip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.revealed == oldWidget.revealed) return;
    _delay?.cancel();
    if (widget.revealed) {
      final wait = context.motion.ritual.dealStagger * widget.staggerIndex;
      if (wait == Duration.zero) {
        _flip();
      } else {
        _delay = Timer(wait, _flip);
      }
    } else {
      _controller.value = 0;
    }
  }

  void _flip() {
    if (!mounted) return;
    final motion = context.motion;
    _controller.duration = motion.ritual.flip;
    if (widget.haptics) unawaited(TaroHaptics.flip(context));
    unawaited(_controller.forward(from: 0));
  }

  void _onStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) widget.onFlipped?.call();
  }

  @override
  void dispose() {
    _delay?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduced = context.reduceMotion;
    final easing = context.motion.easing.emphasized;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        if (reduced) {
          // Top-aligned: a face with its caption is taller than the back,
          // and the two card rectangles must cross-fade in place.
          return Stack(
            alignment: AlignmentDirectional.topCenter,
            children: [
              _side(widget.back, opacity: 1 - t, visible: t < 0.5),
              _side(widget.face, opacity: t, visible: t >= 0.5),
            ],
          );
        }
        final angle = easing.transform(t) * math.pi;
        final showFace = angle > math.pi / 2;
        final matrix = Matrix4.identity()
          ..setEntry(3, 2, _perspective)
          ..rotateY(showFace ? angle - math.pi : angle);
        return Transform(
          alignment: Alignment.center,
          transform: matrix,
          child: showFace ? widget.face : widget.back,
        );
      },
    );
  }

  static const double _perspective = 0.001;

  Widget _side(Widget child, {required double opacity, required bool visible}) {
    return ExcludeSemantics(
      excluding: !visible,
      child: IgnorePointer(
        ignoring: !visible,
        child: Opacity(opacity: opacity, child: child),
      ),
    );
  }
}
