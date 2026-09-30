import 'package:flutter/material.dart';
import 'package:taro_ui/src/components/common/taro_pressable.dart';
import 'package:taro_ui/src/theme/taro_tokens_extension.dart';
import 'package:taro_ui/src/tokens/taro_strokes.dart';

/// The layouts of a [TaroRadioTile].
enum TaroRadioTileStyle {
  /// A list row: radio, title, optional subtitle (S21, S33, theme sheet).
  row,

  /// A "radio card" on `color.bg.surface` with an explanatory body (S25).
  card,
}

/// A single-choice option with a visible radio (`docs/design/components.md`).
///
/// Selected when [value] equals [groupValue]. The whole tile is the target
/// and one screen-reader node (`inMutuallyExclusiveGroup`, checked state).
/// A selected card gets the `color.accent.subtle` fill and a
/// `color.accent.primary` ring. `onChanged == null` disables it.
class TaroRadioTile<T> extends StatelessWidget {
  /// Creates the tile.
  const TaroRadioTile({
    required this.value,
    required this.groupValue,
    required this.onChanged,
    required this.title,
    this.subtitle,
    this.style = TaroRadioTileStyle.row,
    super.key,
  });

  /// This option.
  final T value;

  /// The selected option of the group (null: none).
  final T? groupValue;

  /// Called with [value] on tap; null disables the tile.
  final ValueChanged<T>? onChanged;

  /// Localised title.
  final String title;

  /// Localised subtitle (row) or body (card).
  final String? subtitle;

  /// Row or card.
  final TaroRadioTileStyle style;

  bool get _selected => value == groupValue;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final c = tokens.color;
    final card = style == TaroRadioTileStyle.card;
    final selected = _selected;
    final enabled = onChanged != null;
    final content = Padding(
      padding: EdgeInsetsDirectional.symmetric(
        horizontal: card ? tokens.space.s5 : tokens.space.s4,
        vertical: card ? tokens.space.s5 : tokens.space.s3,
      ),
      child: Row(
        crossAxisAlignment: card
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          _RadioDot(selected: selected),
          SizedBox(width: tokens.space.s4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style:
                      (card
                              ? tokens.typography.titleSmall
                              : tokens.typography.body)
                          .copyWith(color: c.text.primary),
                ),
                if (subtitle != null) ...[
                  SizedBox(height: tokens.space.s1),
                  Text(
                    subtitle!,
                    style:
                        (card
                                ? tokens.typography.body
                                : tokens.typography.caption)
                            .copyWith(color: c.text.secondary),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
    Widget tile = TaroPressable(
      onTap: enabled ? () => onChanged!(value) : null,
      borderRadius: card ? tokens.radius.lg : tokens.radius.md,
      color: card
          ? (selected ? c.accent.subtle : c.bg.surface)
          : Colors.transparent,
      side: card
          ? BorderSide(
              color: selected ? c.accent.primary : c.border.subtle,
              width: selected ? TaroStrokes.control : TaroStrokes.hairline,
            )
          : BorderSide.none,
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: tokens.size.touchTarget.min),
        child: content,
      ),
    );
    if (!enabled) {
      tile = Opacity(opacity: tokens.opacity.disabled, child: tile);
    }
    return Semantics(
      container: true,
      inMutuallyExclusiveGroup: true,
      checked: selected,
      enabled: enabled,
      child: tile,
    );
  }
}

class _RadioDot extends StatelessWidget {
  const _RadioDot({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final c = tokens.color;
    final size = tokens.size.icon.md;
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        padding: EdgeInsetsDirectional.all(tokens.space.s2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? c.accent.primary : c.border.strong,
            width: TaroStrokes.focusRing,
          ),
        ),
        child: selected
            ? DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: c.accent.primary,
                ),
              )
            : null,
      ),
    );
  }
}
