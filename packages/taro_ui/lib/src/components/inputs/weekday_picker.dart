import 'package:flutter/material.dart';
import 'package:taro_ui/src/components/common/taro_pressable.dart';
import 'package:taro_ui/src/theme/taro_tokens_extension.dart';

/// A multi-select row of the seven weekdays (`docs/design/components.md`;
/// dropped from S22 for v1, kept for a later spec that adds reminder days).
///
/// Days use `DateTime.weekday` numbering (1 = Monday … 7 = Sunday) and are
/// ordered from the locale's [firstWeekday]; the row mirrors in RTL. Each
/// toggle shows a short label and announces the full day name with its
/// selected state ("Wednesday, selected"). `onChanged == null` disables the
/// row (reminder off).
class WeekdayPicker extends StatelessWidget {
  /// Creates the picker.
  const WeekdayPicker({
    required this.selected,
    required this.onChanged,
    required this.shortLabels,
    required this.fullLabels,
    this.firstWeekday = DateTime.monday,
    super.key,
  }) : assert(firstWeekday >= 1 && firstWeekday <= 7, 'a DateTime weekday');

  /// The selected weekdays (1–7).
  final Set<int> selected;

  /// Called with the new selection; null disables the picker.
  final ValueChanged<Set<int>>? onChanged;

  /// Localised short labels, Monday first ("M", "T", …).
  final List<String> shortLabels;

  /// Localised full names, Monday first ("Monday", …).
  final List<String> fullLabels;

  /// The locale's first day of the week (`DateTime.monday` …).
  final int firstWeekday;

  /// The seven weekdays in display order, starting at [firstWeekday].
  List<int> get orderedDays => [
    for (var i = 0; i < 7; i++) (firstWeekday - 1 + i) % 7 + 1,
  ];

  void _toggle(int day) {
    final next = {...selected};
    if (!next.remove(day)) next.add(day);
    onChanged!(next);
  }

  @override
  Widget build(BuildContext context) {
    assert(shortLabels.length == 7 && fullLabels.length == 7, '7 days');
    final tokens = context.tokens;
    final c = tokens.color;
    final enabled = onChanged != null;
    final target = tokens.size.touchTarget.min;
    Widget row = Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (final day in orderedDays)
          Semantics(
            container: true,
            button: true,
            enabled: enabled,
            selected: selected.contains(day),
            label: fullLabels[day - 1],
            excludeSemantics: true,
            onTap: enabled ? () => _toggle(day) : null,
            child: TaroPressable(
              onTap: enabled ? () => _toggle(day) : null,
              borderRadius: tokens.radius.full,
              color: selected.contains(day) ? c.accent.primary : c.bg.sunken,
              child: SizedBox.square(
                dimension: target,
                child: Center(
                  child: Text(
                    shortLabels[day - 1],
                    maxLines: 1,
                    style: tokens.typography.label.copyWith(
                      color: selected.contains(day)
                          ? c.text.onAccent
                          : c.text.secondary,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
    if (!enabled) {
      row = Opacity(opacity: tokens.opacity.disabled, child: row);
    }
    return row;
  }
}
