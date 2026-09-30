import 'package:flutter/material.dart';
import 'package:taro_ui/src/components/common/taro_pressable.dart';
import 'package:taro_ui/src/components/common/taro_reflow.dart';
import 'package:taro_ui/src/components/inputs/taro_chip.dart';
import 'package:taro_ui/src/theme/taro_tokens_extension.dart';

/// Text scale above which [SegmentedChoice] falls back to wrapping filter
/// chips (01 §12 reflow threshold).
const double kSegmentedChoiceReflowScale = kTaroRowReflowTextScale;

/// One option of a [SegmentedChoice].
@immutable
class TaroSegment<T> {
  /// Creates the option.
  const TaroSegment({required this.value, required this.label});

  /// The value selected by this option.
  final T value;

  /// Localised short label.
  final String label;
}

/// A single choice among 2–4 short options (02 §14.3): S20 theme (System /
/// Light / Dark), S14 filter row.
///
/// A `color.bg.sunken` track with `radius.full`; the selected segment is
/// `color.accent.subtle`. Each segment is ≥ `size.touchTarget.min` high and
/// announced as a selected/unselected button in a mutually exclusive group.
/// Above [kSegmentedChoiceReflowScale]× text it falls back to wrapping
/// `TaroChip.filter`s so labels never clip. `onChanged == null` disables it.
class SegmentedChoice<T> extends StatelessWidget {
  /// Creates the control.
  const SegmentedChoice({
    required this.segments,
    required this.selected,
    required this.onChanged,
    super.key,
  });

  /// The options, in reading order.
  final List<TaroSegment<T>> segments;

  /// The selected value.
  final T selected;

  /// Called with the tapped value; null disables the control.
  final ValueChanged<T>? onChanged;

  @override
  Widget build(BuildContext context) {
    assert(segments.length >= 2 && segments.length <= 4, '2–4 options');
    final tokens = context.tokens;
    final c = tokens.color;
    final enabled = onChanged != null;
    if (taroShouldReflow(context)) {
      return Wrap(
        spacing: tokens.space.s3,
        runSpacing: tokens.space.s3,
        children: [
          for (final s in segments)
            TaroChip.filter(
              label: s.label,
              selected: s.value == selected,
              onSelected: enabled ? (_) => onChanged!(s.value) : null,
            ),
        ],
      );
    }
    Widget track = Container(
      padding: EdgeInsetsDirectional.all(tokens.space.s1),
      decoration: BoxDecoration(
        color: c.bg.sunken,
        borderRadius: BorderRadius.circular(tokens.radius.full),
      ),
      child: Row(
        children: [
          for (final s in segments)
            Expanded(
              child: Semantics(
                container: true,
                button: true,
                inMutuallyExclusiveGroup: true,
                selected: s.value == selected,
                enabled: enabled,
                child: TaroPressable(
                  onTap: enabled ? () => onChanged!(s.value) : null,
                  borderRadius: tokens.radius.full,
                  color: s.value == selected
                      ? c.accent.subtle
                      : Colors.transparent,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: tokens.size.touchTarget.min,
                    ),
                    child: Padding(
                      padding: EdgeInsetsDirectional.symmetric(
                        horizontal: tokens.space.s3,
                        vertical: tokens.space.s3,
                      ),
                      child: Center(
                        child: Text(
                          s.label,
                          textAlign: TextAlign.center,
                          style: tokens.typography.label.copyWith(
                            color: c.text.primary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
    if (!enabled) {
      track = Opacity(opacity: tokens.opacity.disabled, child: track);
    }
    return track;
  }
}
