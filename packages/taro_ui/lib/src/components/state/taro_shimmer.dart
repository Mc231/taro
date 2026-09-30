import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:taro_ui/src/motion/taro_motion.dart';

/// Drives the loading shimmer of every `SkeletonBlock` below it
/// (`motion.duration.slow`; still under reduced motion, 01 §12).
class TaroShimmer extends StatefulWidget {
  /// Animates the skeletons in [child].
  const TaroShimmer({required this.child, super.key});

  /// The skeleton layout.
  final Widget child;

  /// The shimmer phase (0 = `color.skeleton.base`, 1 = `highlight`) for
  /// [context], or 0 without a [TaroShimmer] ancestor.
  static double phaseOf(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<_ShimmerScope>()
          ?.notifier
          ?.value ??
      0;

  @override
  State<TaroShimmer> createState() => _TaroShimmerState();
}

class _TaroShimmerState extends State<TaroShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (context.reduceMotion) {
      _controller
        ..stop()
        ..value = 0;
    } else {
      _controller.duration = context.motion.duration.slow;
      unawaited(_controller.repeat(reverse: true));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      _ShimmerScope(notifier: _controller, child: widget.child);
}

class _ShimmerScope extends InheritedNotifier<Animation<double>> {
  const _ShimmerScope({required super.notifier, required super.child});
}
