import 'package:flutter/material.dart';
import 'package:taro_ui/src/components/common/taro_pressable.dart';
import 'package:taro_ui/src/components/common/taro_reflow.dart';
import 'package:taro_ui/src/theme/taro_tokens_extension.dart';
import 'package:taro_ui/src/tokens/taro_strokes.dart';

/// A row on a surface (`docs/design/components.md`): leading visual (icon,
/// `SpreadDiagram`, card thumb), title, subtitle and trailing (chevron,
/// value, or an action button such as S27 "Call").
///
/// * [selected]: `color.accent.subtle` fill with a `color.accent.primary`
///   ring, announced as selected (S06 spread options).
/// * Disabled with a reason (04 §9.1): pass `onTap: null` and
///   [disabledReason]; the reason replaces the subtitle and is never hidden
///   (S10 "Available again in 4 min").
///
/// A tappable row is one screen-reader node (its texts merged). A
/// [trailing] action stays a separate node, so the row itself should then
/// have no [onTap].
class TaroListTile extends StatelessWidget {
  /// Creates the row.
  const TaroListTile({
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.selected = false,
    this.disabledReason,
    this.showChevron = false,
    super.key,
  });

  /// Localised title.
  final String title;

  /// Localised subtitle.
  final String? subtitle;

  /// Leading visual (decorative unless it has its own semantics).
  final Widget? leading;

  /// Trailing widget (value text or an action button).
  final Widget? trailing;

  /// Called on tap; null renders a static row, or a disabled one when
  /// [disabledReason] is set.
  final VoidCallback? onTap;

  /// The selected state.
  final bool selected;

  /// Why the row is disabled, shown in place of the subtitle.
  final String? disabledReason;

  /// Shows a trailing chevron (navigation rows).
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final c = tokens.color;
    final disabled = onTap == null && disabledReason != null;
    final sub = disabled ? disabledReason : subtitle;
    final faded = disabled ? tokens.opacity.disabled : 1.0;
    // At large text a trailing action moves under the text (01 §12).
    final stacked = taroShouldReflow(context);
    final row = Padding(
      padding: EdgeInsetsDirectional.symmetric(
        horizontal: tokens.space.s5,
        vertical: tokens.space.s4,
      ),
      child: Row(
        children: [
          if (leading != null) ...[
            Opacity(opacity: faded, child: leading),
            SizedBox(width: tokens.space.s4),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Opacity(
                  opacity: faded,
                  child: Text(
                    title,
                    style: tokens.typography.titleSmall.copyWith(
                      color: c.text.primary,
                    ),
                  ),
                ),
                if (sub != null) ...[
                  SizedBox(height: tokens.space.s1),
                  // The reason keeps full contrast: it is the explanation.
                  Text(
                    sub,
                    style: tokens.typography.caption.copyWith(
                      color: disabled ? c.text.secondary : c.text.tertiary,
                    ),
                  ),
                ],
                if (trailing != null && stacked) ...[
                  SizedBox(height: tokens.space.s3),
                  Semantics(container: true, child: trailing),
                ],
              ],
            ),
          ),
          if (trailing != null && !stacked) ...[
            SizedBox(width: tokens.space.s4),
            // Its own node: an action button never merges into the row.
            Semantics(container: true, child: trailing),
          ],
          if (showChevron) ...[
            SizedBox(width: tokens.space.s3),
            ExcludeSemantics(
              child: Icon(
                Icons.chevron_right_rounded,
                size: tokens.size.icon.md,
                color: c.text.secondary,
              ),
            ),
          ],
        ],
      ),
    );
    final tile = TaroPressable(
      onTap: onTap,
      borderRadius: tokens.radius.lg,
      color: selected ? c.accent.subtle : c.bg.surface,
      side: selected
          ? BorderSide(color: c.accent.primary, width: TaroStrokes.focusRing)
          : BorderSide.none,
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: tokens.size.touchTarget.min),
        child: row,
      ),
    );
    if (onTap == null && !disabled && !selected) return tile;
    return MergeSemantics(
      child: Semantics(
        button: onTap != null || disabled,
        enabled: onTap != null || !disabled,
        selected: selected,
        child: tile,
      ),
    );
  }
}
