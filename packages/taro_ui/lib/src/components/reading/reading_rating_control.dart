import 'package:flutter/material.dart';
import 'package:taro_ui/src/components/common/taro_pressable.dart';
import 'package:taro_ui/src/theme/taro_tokens_extension.dart';
import 'package:taro_ui/src/tokens/taro_strokes.dart';

/// The two ratings of a reading (mirrors `Rating` `up | down` in
/// `taro_core`, which `taro_ui` cannot import; RC95).
enum ReadingRatingValue {
  /// Helpful.
  up,

  /// Not helpful.
  down,
}

/// "Was this reading helpful?" with Helpful / Not helpful toggle buttons
/// (S09, `ReadingRated.dc.html`).
///
/// The selected thumb is filled `color.accent.primary`; the other is
/// outlined. Each button has a localised label and a toggled state; tapping
/// the selected one again clears the rating (`onChanged(null)`). A light
/// outlined `radius.lg` container, `size.touchTarget.min` buttons.
class ReadingRatingControl extends StatelessWidget {
  /// Creates the control.
  const ReadingRatingControl({
    required this.prompt,
    required this.helpfulLabel,
    required this.notHelpfulLabel,
    required this.value,
    required this.onChanged,
    super.key,
  });

  /// Localised prompt ("Was this reading helpful?").
  final String prompt;

  /// Localised label of the thumbs-up button ("Helpful").
  final String helpfulLabel;

  /// Localised label of the thumbs-down button ("Not helpful").
  final String notHelpfulLabel;

  /// The current rating.
  final ReadingRatingValue? value;

  /// Called with the new rating (null clears); null disables the control.
  final ValueChanged<ReadingRatingValue?>? onChanged;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final c = tokens.color;
    Widget thumb(ReadingRatingValue rating) {
      final on = value == rating;
      final enabled = onChanged != null;
      final up = rating == ReadingRatingValue.up;
      Widget button = TaroPressable(
        onTap: enabled ? () => onChanged!(on ? null : rating) : null,
        borderRadius: tokens.radius.md,
        color: on ? c.accent.primary : Colors.transparent,
        side: on
            ? BorderSide.none
            : BorderSide(color: c.border.strong, width: TaroStrokes.control),
        child: SizedBox.square(
          dimension: tokens.size.touchTarget.min,
          child: Icon(
            up
                ? (on ? Icons.thumb_up_rounded : Icons.thumb_up_outlined)
                : (on ? Icons.thumb_down_rounded : Icons.thumb_down_outlined),
            size: tokens.size.icon.md,
            color: on ? c.text.onAccent : c.text.primary,
          ),
        ),
      );
      if (!enabled) {
        button = Opacity(opacity: tokens.opacity.disabled, child: button);
      }
      return Semantics(
        container: true,
        button: true,
        toggled: on,
        enabled: enabled,
        label: up ? helpfulLabel : notHelpfulLabel,
        child: button,
      );
    }

    return Container(
      padding: EdgeInsetsDirectional.fromSTEB(
        tokens.space.s5,
        tokens.space.s3,
        tokens.space.s3,
        tokens.space.s3,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(tokens.radius.lg),
        border: Border.all(color: c.border.subtle),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              prompt,
              style: tokens.typography.titleSmall.copyWith(
                color: c.text.primary,
              ),
            ),
          ),
          SizedBox(width: tokens.space.s3),
          thumb(ReadingRatingValue.up),
          SizedBox(width: tokens.space.s3),
          thumb(ReadingRatingValue.down),
        ],
      ),
    );
  }
}
