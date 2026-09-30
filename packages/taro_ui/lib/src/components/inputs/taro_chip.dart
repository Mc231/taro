import 'package:flutter/material.dart';
import 'package:taro_ui/src/components/common/taro_pressable.dart';
import 'package:taro_ui/src/theme/taro_tokens_extension.dart';
import 'package:taro_ui/src/tokens/taro_strokes.dart';

/// The roles of a [TaroChip].
enum TaroChipVariant {
  /// Tap inserts text (S07 "Ideas").
  suggestion,

  /// A toggle with a selected state (S14 filters, S16 suit filter).
  filter,
}

/// A compact pill (`docs/design/components.md`): a *suggestion* (tap
/// inserts text) or a *filter* (selected state, `color.accent.subtle` fill
/// with a `color.accent.primary` outline). `radius.full`, `type.label`,
/// ≥ `size.touchTarget.min` high. An optional [leading] glyph (`SuitGlyph`)
/// is decorative; the label carries the meaning.
class TaroChip extends StatelessWidget {
  /// A suggestion chip.
  const TaroChip.suggestion({
    required this.label,
    required VoidCallback? onPressed,
    this.leading,
    super.key,
  }) : variant = TaroChipVariant.suggestion,
       selected = false,
       _onPressed = onPressed,
       onSelected = null;

  /// A filter chip.
  const TaroChip.filter({
    required this.label,
    required this.selected,
    required this.onSelected,
    this.leading,
    super.key,
  }) : variant = TaroChipVariant.filter,
       _onPressed = null;

  /// The localised label.
  final String label;

  /// The role.
  final TaroChipVariant variant;

  /// Whether a filter chip is on.
  final bool selected;

  /// Called with the new selection of a filter chip; null disables it.
  final ValueChanged<bool>? onSelected;

  final VoidCallback? _onPressed;

  /// A decorative leading glyph.
  final Widget? leading;

  VoidCallback? get _onTap => switch (variant) {
    TaroChipVariant.suggestion => _onPressed,
    TaroChipVariant.filter =>
      onSelected == null ? null : () => onSelected!(!selected),
  };

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final c = tokens.color;
    final on = variant == TaroChipVariant.filter && selected;
    final enabled = _onTap != null;
    Widget chip = TaroPressable(
      onTap: _onTap,
      borderRadius: tokens.radius.full,
      color: on ? c.accent.subtle : c.bg.surface,
      side: BorderSide(
        color: on ? c.accent.primary : c.border.subtle,
        width: on ? TaroStrokes.control : TaroStrokes.hairline,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: tokens.size.touchTarget.min,
          minWidth: tokens.size.touchTarget.min,
        ),
        child: Padding(
          padding: EdgeInsetsDirectional.symmetric(
            horizontal: tokens.space.s5,
            vertical: tokens.space.s3,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (leading != null) ...[
                ExcludeSemantics(
                  child: IconTheme.merge(
                    data: IconThemeData(size: tokens.size.icon.sm),
                    child: leading!,
                  ),
                ),
                SizedBox(width: tokens.space.s3),
              ],
              Flexible(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: tokens.typography.label.copyWith(
                    color: c.text.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (!enabled) {
      chip = Opacity(opacity: tokens.opacity.disabled, child: chip);
    }
    return Semantics(
      container: true,
      button: true,
      enabled: enabled,
      selected: variant == TaroChipVariant.filter ? selected : null,
      child: chip,
    );
  }
}
