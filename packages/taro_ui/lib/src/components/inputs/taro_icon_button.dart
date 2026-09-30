import 'package:flutter/material.dart';
import 'package:taro_ui/src/components/common/taro_pressable.dart';
import 'package:taro_ui/src/theme/taro_tokens_extension.dart';

/// An icon-only action with a required, localised [semanticsLabel]
/// (02 §14.3): Back, Close, Favourite, More, Export, search clear.
///
/// The target is `size.touchTarget.min` square with a `size.icon.md` glyph
/// in `color.text.primary`. A toggle ([toggled] non-null, e.g. Favourite)
/// shows [selectedIcon] in `color.accent.primary` when on and exposes the
/// toggled state to screen readers. `onPressed == null` renders the
/// disabled state (`opacity.disabled`). Directional glyphs (Back) mirror in
/// RTL through `IconData.matchTextDirection`.
class TaroIconButton extends StatelessWidget {
  /// Creates the button.
  const TaroIconButton({
    required this.icon,
    required this.semanticsLabel,
    required this.onPressed,
    this.toggled,
    this.selectedIcon,
    this.color,
    this.tooltip = true,
    super.key,
  });

  /// The glyph.
  final IconData icon;

  /// The glyph while [toggled] is true (defaults to [icon]).
  final IconData? selectedIcon;

  /// What the button does, read by screen readers ("Close", "Favourite").
  final String semanticsLabel;

  /// Called on tap; null disables the button.
  final VoidCallback? onPressed;

  /// Null for a plain action; true/false for a toggle.
  final bool? toggled;

  /// Overrides the glyph colour (e.g. `color.text.secondary`).
  final Color? color;

  /// Whether a long press shows [semanticsLabel] as a tooltip.
  final bool tooltip;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final on = toggled ?? false;
    final glyphColor = on
        ? tokens.color.accent.primary
        : color ?? tokens.color.text.primary;
    final target = tokens.size.touchTarget.min;
    Widget button = TaroPressable(
      onTap: onPressed,
      borderRadius: tokens.radius.full,
      child: SizedBox.square(
        dimension: target,
        child: Icon(
          on ? selectedIcon ?? icon : icon,
          size: tokens.size.icon.md,
          color: glyphColor,
        ),
      ),
    );
    if (onPressed == null) {
      button = Opacity(opacity: tokens.opacity.disabled, child: button);
    }
    if (tooltip && onPressed != null) {
      button = Tooltip(
        message: semanticsLabel,
        excludeFromSemantics: true,
        child: button,
      );
    }
    return Semantics(
      container: true,
      button: true,
      enabled: onPressed != null,
      toggled: toggled,
      label: semanticsLabel,
      child: button,
    );
  }
}
