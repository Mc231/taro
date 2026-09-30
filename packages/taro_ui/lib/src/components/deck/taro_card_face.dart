import 'package:flutter/material.dart';
import 'package:taro_ui/src/components/deck/taro_card_size.dart';
import 'package:taro_ui/src/components/state/skeleton_block.dart';
import 'package:taro_ui/src/motion/taro_motion.dart';
import 'package:taro_ui/src/theme/taro_tokens_extension.dart';
import 'package:taro_ui/src/tokens/taro_strokes.dart';

/// A revealed card (02 §14.3, design system **TarotCard** revealed).
///
/// The art comes from an [ImageProvider] (`taro_ui` never reads the app's
/// assets). Reversed cards rotate the art 180° and show the [reversedLabel]
/// badge; the badge, [numeral] and [name] are never rotated, and the art is
/// never mirrored in RTL (02 §11). While the art decodes a skeleton stands
/// in. [highlighted] adds the `color.card.glow` halo of a just-revealed card.
///
/// Screen readers hear only [semanticsLabel], passed localised, e.g. "Three
/// of Cups, reversed, position: Past".
class TaroCardFace extends StatelessWidget {
  /// Creates a revealed card.
  const TaroCardFace({
    required this.image,
    required this.semanticsLabel,
    this.size = TaroCardSize.md,
    this.reversed = false,
    this.reversedLabel,
    this.numeral,
    this.name,
    this.highlighted = false,
    this.onTap,
    super.key,
  });

  /// The card art.
  final ImageProvider image;

  /// Localised label for screen readers.
  final String semanticsLabel;

  /// The card size.
  final TaroCardSize size;

  /// Whether the card is reversed (art rotated 180°).
  final bool reversed;

  /// Localised badge text of a reversed card ("Reversed").
  final String? reversedLabel;

  /// Roman numeral or rank below the card (`type.numeral`).
  final String? numeral;

  /// Card name below the card (`type.cardName`).
  final String? name;

  /// The just-revealed glow.
  final bool highlighted;

  /// Called on tap (for example to zoom, S17).
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final c = tokens.color;
    final card = size.sizeOf(tokens);
    final radius = BorderRadius.circular(tokens.radius.card);
    Widget art = Image(
      image: image,
      width: card.width,
      height: card.height,
      fit: BoxFit.cover,
      frameBuilder: (context, child, frame, sync) => frame == null && !sync
          ? SkeletonBlock(
              shape: SkeletonShape.rect,
              width: card.width,
              height: card.height,
            )
          : child,
      errorBuilder: (context, error, stack) => ColoredBox(
        color: c.bg.sunken,
        child: SizedBox.fromSize(size: card),
      ),
    );
    if (reversed) art = RotatedBox(quarterTurns: 2, child: art);
    Widget face = AnimatedContainer(
      duration: context.motion.duration.base,
      curve: context.motion.easing.standard,
      width: card.width,
      height: card.height,
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          ...tokens.elevation.e2.shadow,
          if (highlighted)
            BoxShadow(
              color: c.card.glow,
              blurRadius: tokens.space.s5,
              spreadRadius: tokens.space.s1,
            ),
        ],
      ),
      foregroundDecoration: BoxDecoration(
        borderRadius: radius,
        border: Border.all(
          color: highlighted ? c.card.glow : c.card.frame,
          width: highlighted ? TaroStrokes.focusRing : TaroStrokes.hairline,
        ),
      ),
      child: ClipRRect(borderRadius: radius, child: art),
    );
    final badgeText = reversed ? reversedLabel : null;
    if (badgeText != null) {
      face = Stack(
        children: [
          face,
          PositionedDirectional(
            top: tokens.space.s3,
            start: 0,
            end: 0,
            child: Center(child: _ReversedBadge(label: badgeText)),
          ),
        ],
      );
    }
    final captions = <Widget>[
      if (numeral != null)
        Text(
          numeral!,
          textAlign: TextAlign.center,
          style: tokens.typography.numeral.copyWith(color: c.text.secondary),
        ),
      if (name != null)
        Text(
          name!,
          textAlign: TextAlign.center,
          style: tokens.typography.cardName.copyWith(color: c.text.primary),
        ),
    ];
    var content = captions.isEmpty
        ? face
        : Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              face,
              SizedBox(height: tokens.space.s3),
              ...captions,
            ],
          );
    if (onTap != null) {
      content = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: tokens.size.touchTarget.min,
            minHeight: tokens.size.touchTarget.min,
          ),
          child: Center(widthFactor: 1, heightFactor: 1, child: content),
        ),
      );
    }
    return Semantics(
      container: true,
      image: onTap == null,
      button: onTap != null,
      label: semanticsLabel,
      onTap: onTap,
      excludeSemantics: true,
      child: content,
    );
  }
}

class _ReversedBadge extends StatelessWidget {
  const _ReversedBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: tokens.color.card.reversedBadge,
        borderRadius: BorderRadius.circular(tokens.radius.xs),
      ),
      child: Padding(
        padding: EdgeInsetsDirectional.symmetric(
          horizontal: tokens.space.s3,
          vertical: tokens.space.s1,
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: tokens.typography.caption.copyWith(
            color: tokens.color.text.onAccent,
          ),
        ),
      ),
    );
  }
}
