import 'package:flutter/material.dart';
import 'package:taro_ui/src/components/common/taro_pressable.dart';
import 'package:taro_ui/src/components/common/taro_reflow.dart';
import 'package:taro_ui/src/motion/taro_motion.dart';
import 'package:taro_ui/src/theme/taro_tokens_extension.dart';
import 'package:taro_ui/src/tokens/taro_strokes.dart';

/// One settings row (02 §14.3): title, optional subtitle and leading
/// visual, and a trailing value + chevron (navigation), a switch (toggle)
/// or nothing (text action such as "Copy ID"; [destructive] for "Delete all
/// data").
///
/// The whole row is one target and one screen-reader node (a toggle
/// announces its on/off state). Rows sit in a `SettingsSection`, which draws
/// the surface and dividers. `onTap == null` (or `onChanged == null` for a
/// toggle) renders the disabled state.
class SettingsTile extends StatelessWidget {
  /// A navigation, value or action row.
  const SettingsTile({
    required this.title,
    required this.onTap,
    this.subtitle,
    this.leading,
    this.value,
    this.showChevron,
    this.destructive = false,
    super.key,
  }) : switchValue = null,
       onChanged = null;

  /// A switch row.
  const SettingsTile.toggle({
    required this.title,
    required bool this.switchValue,
    required this.onChanged,
    this.subtitle,
    this.leading,
    super.key,
  }) : onTap = null,
       value = null,
       showChevron = false,
       destructive = false;

  /// Localised title.
  final String title;

  /// Localised subtitle (`type.caption`).
  final String? subtitle;

  /// A leading visual (e.g. the balance dot); decorative.
  final Widget? leading;

  /// Localised trailing value ("English", "8:00 PM", "$3.99").
  final String? value;

  /// Whether to show the chevron (defaults to true for tappable
  /// navigation rows with a [value] or without [destructive]).
  final bool? showChevron;

  /// Title in `color.status.error`.
  final bool destructive;

  /// Called on tap (navigation, value and action rows).
  final VoidCallback? onTap;

  /// The switch state of a toggle row.
  final bool? switchValue;

  /// Called with the new switch state; null disables the toggle.
  final ValueChanged<bool>? onChanged;

  bool get _isToggle => switchValue != null;

  VoidCallback? get _tap => _isToggle
      ? (onChanged == null ? null : () => onChanged!(!switchValue!))
      : onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final c = tokens.color;
    final enabled = _tap != null;
    final chevron =
        showChevron ?? (!_isToggle && !destructive && onTap != null);
    // At large text the value moves under the title instead of squeezing it.
    final stacked = taroShouldReflow(context);
    final valueText = value == null
        ? null
        : Text(
            value!,
            textAlign: stacked ? TextAlign.start : TextAlign.end,
            style: tokens.typography.body.copyWith(color: c.text.secondary),
          );
    Widget row = TaroPressable(
      onTap: _tap,
      borderRadius: tokens.radius.none,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: tokens.size.touchTarget.min + tokens.space.s3,
        ),
        child: Padding(
          padding: EdgeInsetsDirectional.symmetric(
            horizontal: tokens.space.s5,
            vertical: tokens.space.s4,
          ),
          child: Row(
            children: [
              if (leading != null) ...[
                ExcludeSemantics(child: leading),
                SizedBox(width: tokens.space.s4),
              ],
              Expanded(
                // The title keeps two thirds of the row next to a value; the
                // value sits at the end of its third, next to the chevron.
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: tokens.typography.body.copyWith(
                        color: destructive ? c.status.error : c.text.primary,
                      ),
                    ),
                    if (subtitle != null) ...[
                      SizedBox(height: tokens.space.s1),
                      Text(
                        subtitle!,
                        style: tokens.typography.caption.copyWith(
                          color: c.text.secondary,
                        ),
                      ),
                    ],
                    if (valueText != null && stacked) ...[
                      SizedBox(height: tokens.space.s1),
                      valueText,
                    ],
                  ],
                ),
              ),
              if (valueText != null && !stacked) ...[
                SizedBox(width: tokens.space.s4),
                Flexible(
                  child: Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: valueText,
                  ),
                ),
              ],
              if (chevron) ...[
                SizedBox(width: tokens.space.s3),
                ExcludeSemantics(
                  child: Icon(
                    Icons.chevron_right_rounded,
                    size: tokens.size.icon.md,
                    color: c.text.secondary,
                  ),
                ),
              ],
              if (_isToggle) ...[
                SizedBox(width: tokens.space.s4),
                ExcludeSemantics(
                  child: _TaroSwitch(value: switchValue!, enabled: enabled),
                ),
              ],
            ],
          ),
        ),
      ),
    );
    if (!enabled) {
      row = Opacity(opacity: tokens.opacity.disabled, child: row);
    }
    return Semantics(
      container: true,
      button: !_isToggle,
      toggled: switchValue,
      enabled: enabled,
      child: row,
    );
  }
}

/// The visual switch of a toggle row (the row is the target and the
/// semantics node, so this is a picture of the state).
class _TaroSwitch extends StatelessWidget {
  const _TaroSwitch({required this.value, required this.enabled});

  final bool value;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final c = tokens.color;
    final height = tokens.space.s8;
    final thumb = height - 2 * tokens.space.s2;
    return AnimatedContainer(
      duration: context.reduceMotion
          ? context.motion.duration.instant
          : context.motion.duration.fast,
      width: height + thumb,
      height: height,
      padding: EdgeInsetsDirectional.all(tokens.space.s2),
      alignment: value
          ? AlignmentDirectional.centerEnd
          : AlignmentDirectional.centerStart,
      decoration: BoxDecoration(
        color: value ? c.accent.primary : c.bg.sunken,
        borderRadius: BorderRadius.circular(tokens.radius.full),
        border: Border.all(
          color: value ? c.accent.primary : c.border.strong,
          width: TaroStrokes.control,
        ),
      ),
      child: Container(
        width: thumb,
        height: thumb,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: value ? c.text.onAccent : c.border.strong,
        ),
      ),
    );
  }
}
