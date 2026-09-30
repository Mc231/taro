import 'package:flutter/widgets.dart';
import 'package:taro_ui/src/components/state/taro_shimmer.dart';
import 'package:taro_ui/src/theme/taro_tokens_extension.dart';

/// The shape of a [SkeletonBlock].
enum SkeletonShape {
  /// A text line (`radius.sm`).
  line,

  /// A rectangle such as a row or tile (`radius.sm`).
  rect,

  /// A tarot card (`radius.card`, `size.card.aspectRatio`).
  card,

  /// A circle (avatar, icon).
  circle,
}

/// One placeholder shape (text line, card, row) in `color.skeleton.base`,
/// shimmering towards `color.skeleton.highlight` inside a [TaroShimmer]
/// (02 §14.3). Invisible to screen readers: the enclosing
/// `TaroLoadingView` carries the label.
class SkeletonBlock extends StatelessWidget {
  /// Creates a block. A [SkeletonShape.line] defaults to the full width and
  /// the height of `space.5`; a [SkeletonShape.card] to `size.card.md`.
  const SkeletonBlock({
    this.shape = SkeletonShape.line,
    this.width,
    this.height,
    super.key,
  });

  /// The shape.
  final SkeletonShape shape;

  /// Width in logical pixels (use token values).
  final double? width;

  /// Height in logical pixels (use token values).
  final double? height;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final color = Color.lerp(
      tokens.color.skeleton.base,
      tokens.color.skeleton.highlight,
      TaroShimmer.phaseOf(context),
    )!;
    final (double w, double h, BorderRadius radius) = switch (shape) {
      SkeletonShape.line => (
        width ?? double.infinity,
        height ?? tokens.space.s5,
        BorderRadius.circular(tokens.radius.sm),
      ),
      SkeletonShape.rect => (
        width ?? double.infinity,
        height ?? tokens.size.touchTarget.min,
        BorderRadius.circular(tokens.radius.sm),
      ),
      SkeletonShape.card => (
        width ?? tokens.size.card.md,
        height ?? (width ?? tokens.size.card.md) / tokens.size.card.aspectRatio,
        BorderRadius.circular(tokens.radius.card),
      ),
      SkeletonShape.circle => (
        width ?? tokens.size.card.thumb,
        height ?? width ?? tokens.size.card.thumb,
        BorderRadius.circular(tokens.radius.full),
      ),
    };
    return ExcludeSemantics(
      child: SizedBox(
        width: w,
        height: h,
        child: DecoratedBox(
          decoration: BoxDecoration(color: color, borderRadius: radius),
        ),
      ),
    );
  }
}
