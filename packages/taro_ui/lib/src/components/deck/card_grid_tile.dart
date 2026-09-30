import 'package:flutter/material.dart';
import 'package:taro_ui/src/components/state/skeleton_block.dart';
import 'package:taro_ui/src/theme/taro_tokens_extension.dart';
import 'package:taro_ui/src/tokens/taro_strokes.dart';

/// A tappable deck-browser cell (S16): numeral or rank, the card art and
/// the card name (`docs/design/components.md` § CardGridTile).
///
/// Fills the grid cell it is given (at least `size.touchTarget.min`). The
/// art is an [ImageProvider] fitted inside the tile, never mirrored; a
/// skeleton stands in while it decodes. Screen readers hear
/// [semanticsLabel] ("The Magician, Major Arcana, card 2 of 22").
class CardGridTile extends StatefulWidget {
  /// Creates the tile.
  const CardGridTile({
    required this.image,
    required this.name,
    required this.semanticsLabel,
    required this.onTap,
    this.numeral,
    super.key,
  });

  /// The card art or thumbnail.
  final ImageProvider image;

  /// Localised card name.
  final String name;

  /// Localised label for screen readers.
  final String semanticsLabel;

  /// Opens the card (S17).
  final VoidCallback? onTap;

  /// Roman numeral or rank ("II", "Page").
  final String? numeral;

  @override
  State<CardGridTile> createState() => _CardGridTileState();
}

class _CardGridTileState extends State<CardGridTile> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final c = tokens.color;
    final radius = BorderRadius.circular(tokens.radius.card);
    final content = Padding(
      padding: EdgeInsetsDirectional.all(tokens.space.s3),
      child: Column(
        children: [
          if (widget.numeral != null)
            Text(
              widget.numeral!,
              textAlign: TextAlign.center,
              style: tokens.typography.numeral.copyWith(color: c.text.primary),
            ),
          SizedBox(height: tokens.space.s2),
          Expanded(
            child: Image(
              image: widget.image,
              fit: BoxFit.contain,
              frameBuilder: (context, child, frame, sync) =>
                  frame == null && !sync
                  ? SkeletonBlock(
                      shape: SkeletonShape.rect,
                      width: tokens.size.card.thumb,
                    )
                  : child,
              errorBuilder: (context, error, stack) => const SizedBox.shrink(),
            ),
          ),
          SizedBox(height: tokens.space.s2),
          Text(
            widget.name,
            textAlign: TextAlign.center,
            style: tokens.typography.label.copyWith(color: c.text.primary),
          ),
        ],
      ),
    );
    return Semantics(
      container: true,
      button: true,
      enabled: widget.onTap != null,
      label: widget.semanticsLabel,
      onTap: widget.onTap,
      excludeSemantics: true,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: tokens.size.touchTarget.min,
          minHeight: tokens.size.touchTarget.min,
        ),
        child: Material(
          color: c.bg.surface,
          shape: RoundedRectangleBorder(
            borderRadius: radius,
            side: BorderSide(
              color: _focused ? c.border.focus : c.card.frame,
              width: _focused ? TaroStrokes.focusRing : TaroStrokes.control,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: widget.onTap,
            onFocusChange: (value) => setState(() => _focused = value),
            overlayColor: WidgetStatePropertyAll(
              c.text.primary.withValues(alpha: tokens.opacity.pressed),
            ),
            child: content,
          ),
        ),
      ),
    );
  }
}
