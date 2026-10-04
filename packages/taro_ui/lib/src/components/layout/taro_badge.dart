import 'package:flutter/material.dart';
import 'package:taro_ui/src/components/common/taro_word_fit.dart';
import 'package:taro_ui/src/theme/taro_tokens_extension.dart';

/// The variants of a [TaroBadge] (design system **Badge**).
enum TaroBadgeVariant {
  /// "Reversed" on a card face: `color.card.reversedBadge`, `radius.xs`.
  reversed,

  /// "Best value" on a pack (S11): `color.accent.subtle`.
  bestValue,

  /// Entry status (Pending, Classic, Reported): `color.bg.sunken`.
  status,

  /// Card keyword pill ("Hope", "Renewal"): `color.accent.subtle`, round.
  keyword,

  /// The "Ad" label inside `BannerContainer`.
  ad,
}

/// A small non-interactive label (02 §14.3 `Badge`, written `TaroBadge`).
/// The text carries the meaning; colour is never the only signal. It is
/// read as plain text, in reading order.
class TaroBadge extends StatelessWidget {
  /// Creates the badge.
  const TaroBadge({
    required this.label,
    this.variant = TaroBadgeVariant.status,
    this.maxWidth,
    this.textAlign,
    super.key,
  });

  /// Localised text.
  final String label;

  /// The variant.
  final TaroBadgeVariant variant;

  /// The widest the badge may be (a hint inside a card, BUG-06). The label
  /// then wraps between words, and a word wider than the badge shrinks;
  /// null keeps one unconstrained line.
  final double? maxWidth;

  /// The label alignment when it wraps (directional).
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final c = tokens.color;
    final (Color fill, Color text, double radius) = switch (variant) {
      TaroBadgeVariant.reversed => (
        c.card.reversedBadge,
        c.text.onAccent,
        tokens.radius.xs,
      ),
      TaroBadgeVariant.bestValue => (
        c.accent.subtle,
        c.text.primary,
        tokens.radius.full,
      ),
      TaroBadgeVariant.status => (
        c.bg.sunken,
        c.text.secondary,
        tokens.radius.sm,
      ),
      TaroBadgeVariant.keyword => (
        c.accent.subtle,
        c.text.primary,
        tokens.radius.full,
      ),
      TaroBadgeVariant.ad => (
        c.bg.sunken,
        c.text.secondary,
        tokens.radius.xs,
      ),
    };
    final style = switch (variant) {
      TaroBadgeVariant.keyword ||
      TaroBadgeVariant.bestValue => tokens.typography.label,
      _ => tokens.typography.caption,
    };
    final horizontal = variant == TaroBadgeVariant.keyword
        ? tokens.space.s4
        : tokens.space.s3;
    final textStyle = style.copyWith(color: text);
    final maxWidth = this.maxWidth;
    return Container(
      constraints: maxWidth == null ? null : BoxConstraints(maxWidth: maxWidth),
      padding: EdgeInsetsDirectional.symmetric(
        horizontal: horizontal,
        vertical: tokens.space.s1,
      ),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Text(
        label,
        style: textStyle,
        textAlign: textAlign,
        textScaler: maxWidth == null
            ? null
            : taroWordFitScaler(
                text: label,
                style: textStyle,
                scaler: MediaQuery.textScalerOf(context),
                maxWidth: maxWidth - 2 * horizontal,
                direction: Directionality.of(context),
              ),
      ),
    );
  }
}
