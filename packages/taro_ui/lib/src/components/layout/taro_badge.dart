import 'package:flutter/material.dart';
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
    super.key,
  });

  /// Localised text.
  final String label;

  /// The variant.
  final TaroBadgeVariant variant;

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
    return Container(
      padding: EdgeInsetsDirectional.symmetric(
        horizontal: variant == TaroBadgeVariant.keyword
            ? tokens.space.s4
            : tokens.space.s3,
        vertical: tokens.space.s1,
      ),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Text(label, style: style.copyWith(color: text)),
    );
  }
}
