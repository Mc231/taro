import 'package:flutter/material.dart';
import 'package:taro_ui/src/components/deck/taro_card_back_art.dart';
import 'package:taro_ui/src/components/deck/taro_card_ornament.dart';
import 'package:taro_ui/src/components/deck/taro_card_size.dart';
import 'package:taro_ui/src/motion/taro_motion.dart';
import 'package:taro_ui/src/theme/taro_tokens_extension.dart';
import 'package:taro_ui/src/tokens/generated/taro_tokens.g.dart';
import 'package:taro_ui/src/tokens/taro_strokes.dart';

/// A face-down card (02 §14.3, design system **TarotCard** face-down).
///
/// Identical in both themes: the field is `color.card.back` and the
/// ornament keeps the dark-mode `color.card.frame` the art was signed off
/// with (`docs/design/assets/README.md`). Raster art ([art], else the
/// ambient [TaroCardBackArt]) replaces the painted ornament; it is decoded
/// at the card's physical width (`ResizeImage`) and the ornament stands in
/// while it decodes or when it fails to load.
///
/// States: idle; [picked] (`color.card.glow` ring and `elevation.3`);
/// disabled (`onTap == null` while [enabled] is false, `opacity.disabled`).
/// The semantics label is passed localised, e.g. "Card back, position 2 of
/// 3, double-tap to pick". A tappable back is at least
/// `size.touchTarget.min` in both directions.
class TaroCardBack extends StatelessWidget {
  /// Creates a card back.
  const TaroCardBack({
    this.size = TaroCardSize.sm,
    this.semanticsLabel,
    this.picked = false,
    this.enabled = true,
    this.onTap,
    this.art,
    super.key,
  });

  /// The card size.
  final TaroCardSize size;

  /// Localised label; null makes the back decorative.
  final String? semanticsLabel;

  /// The picked state (glow and lift).
  final bool picked;

  /// False renders the disabled state.
  final bool enabled;

  /// Called on tap (the pick gesture).
  final VoidCallback? onTap;

  /// Raster art instead of the painted ornament; null uses the ambient
  /// [TaroCardBackArt] (and the ornament without one).
  final ImageProvider? art;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final card = size.sizeOf(tokens);
    final radius = BorderRadius.circular(tokens.radius.card);
    final glow = tokens.color.card.glow;
    final ornament = CustomPaint(
      painter: TaroCardOrnamentPainter(
        field: tokens.color.card.back,
        frame: TaroColorTokens.dark.card.frame,
      ),
    );
    final image = art ?? TaroCardBackArt.maybeOf(context);
    Widget face = ClipRRect(
      borderRadius: radius,
      child: SizedBox.fromSize(
        size: card,
        child: image == null
            ? ornament
            : Image(
                image: image is ResizeImage
                    ? image
                    : ResizeImage(
                        image,
                        width:
                            (card.width *
                                    MediaQuery.devicePixelRatioOf(
                                      context,
                                    ))
                                .ceil(),
                      ),
                fit: BoxFit.cover,
                gaplessPlayback: true,
                frameBuilder: (context, child, frame, sync) =>
                    frame == null && !sync ? ornament : child,
                errorBuilder: (context, error, stack) => ornament,
              ),
      ),
    );
    face = AnimatedContainer(
      duration: context.motion.duration.fast,
      curve: context.motion.easing.standard,
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: picked
            ? tokens.elevation.e3.shadow
            : tokens.elevation.e2.shadow,
      ),
      foregroundDecoration: picked
          ? BoxDecoration(
              borderRadius: radius,
              border: Border.all(
                color: glow,
                width: TaroStrokes.focusRing,
                strokeAlign: BorderSide.strokeAlignOutside,
              ),
            )
          : null,
      child: face,
    );
    final active = enabled && onTap != null;
    if (!enabled) {
      face = Opacity(opacity: tokens.opacity.disabled, child: face);
    }
    if (onTap != null) {
      final min = tokens.size.touchTarget.min;
      face = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: active ? onTap : null,
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: min, minHeight: min),
          child: Center(widthFactor: 1, heightFactor: 1, child: face),
        ),
      );
    }
    if (semanticsLabel == null) return ExcludeSemantics(child: face);
    return Semantics(
      container: true,
      button: onTap != null,
      enabled: onTap != null ? active : null,
      selected: picked,
      label: semanticsLabel,
      onTap: active ? onTap : null,
      excludeSemantics: true,
      child: face,
    );
  }
}
