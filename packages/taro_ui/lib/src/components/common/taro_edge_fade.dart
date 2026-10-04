import 'package:flutter/material.dart';
import 'package:taro_ui/src/theme/taro_tokens_extension.dart';

/// Fades the [start] and/or [end] edge of a horizontal scroller to show
/// that more content sits past it (S29 tab strip, BUG-10). The edges are
/// directional: in RTL `start` is the right edge.
///
/// The fade is an alpha mask over [child] (`space.7` wide), so it works on
/// any background; with neither edge set the child is returned untouched.
class TaroEdgeFade extends StatelessWidget {
  /// Creates the fade.
  const TaroEdgeFade({
    required this.start,
    required this.end,
    required this.child,
    super.key,
  });

  /// Whether the leading edge fades (content is scrolled past it).
  final bool start;

  /// Whether the trailing edge fades (more content follows).
  final bool end;

  /// The scroller.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!start && !end) return child;
    final width = context.tokens.space.s7;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return ShaderMask(
      blendMode: BlendMode.dstIn,
      shaderCallback: (bounds) {
        // A zero-width box gives infinity, clamped to the middle.
        final edge = (width / bounds.width).clamp(0.0, 0.5);
        // Stops run left → right; the leading edge is on the right in RTL.
        final left = rtl ? end : start;
        final right = rtl ? start : end;
        return LinearGradient(
          colors: [
            if (left) Colors.transparent else Colors.white,
            Colors.white,
            Colors.white,
            if (right) Colors.transparent else Colors.white,
          ],
          stops: [0, edge, 1 - edge, 1],
        ).createShader(bounds);
      },
      child: child,
    );
  }
}
