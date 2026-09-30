import 'package:flutter/material.dart';
import 'package:taro_ui/src/components/inputs/taro_icon_button.dart';
import 'package:taro_ui/src/theme/taro_tokens_extension.dart';
import 'package:taro_ui/src/tokens/taro_strokes.dart';

/// The number of graphemes from which a [TaroTextField] shows its counter
/// (02 §14.3: "a grapheme counter from 250").
const int kTaroCounterVisibleFrom = 250;

/// The layouts of a [TaroTextField].
enum TaroTextFieldStyle {
  /// One line (type-to-confirm, short answers).
  singleLine,

  /// Several lines that grow with the text (question, note, report details).
  multiLine,

  /// A search box: leading search glyph and a clear button.
  search,
}

/// Formats the counter, e.g. `(44, 300) → "44 / 300"`. Pass a localised
/// formatter (numerals per locale).
typedef TaroCounterFormatter = String Function(int count, int max);

/// Text input (02 §14.3): single-line, multi-line with a grapheme counter,
/// and search.
///
/// Counting uses user-perceived characters (grapheme clusters), so an emoji
/// or an Arabic ligature counts once. The counter appears once the text
/// reaches [counterVisibleFrom] graphemes (default 250) and turns
/// `color.status.error` above [maxGraphemes]; the text is never truncated
/// (the caller blocks submit, and [isOverLimit] tells it). [errorText] wins
/// over [helperText]; [statusText] is the saved-status caption ("Saved on
/// this device"). All strings arrive localised.
class TaroTextField extends StatefulWidget {
  /// Creates the field.
  const TaroTextField({
    this.controller,
    this.style = TaroTextFieldStyle.singleLine,
    this.label,
    this.hintText,
    this.helperText,
    this.errorText,
    this.statusText,
    this.maxGraphemes,
    this.counterVisibleFrom = kTaroCounterVisibleFrom,
    this.counterFormatter,
    this.clearLabel,
    this.onChanged,
    this.onSubmitted,
    this.enabled = true,
    this.readOnly = false,
    this.autofocus = false,
    this.focusNode,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.sentences,
    this.minLines,
    this.maxLines,
    super.key,
  });

  /// The text; one is created when null.
  final TextEditingController? controller;

  /// The layout.
  final TaroTextFieldStyle style;

  /// The visible label above the field (also its screen-reader name).
  final String? label;

  /// Placeholder in `color.text.tertiary`.
  final String? hintText;

  /// Help under the field.
  final String? helperText;

  /// An error under the field (outline and text in `color.status.error`).
  final String? errorText;

  /// Saved-status caption under the field.
  final String? statusText;

  /// The grapheme limit; enables the counter.
  final int? maxGraphemes;

  /// Grapheme count from which the counter shows.
  final int counterVisibleFrom;

  /// Formats the counter (default `"count / max"`).
  final TaroCounterFormatter? counterFormatter;

  /// Screen-reader label of the search clear button ("Clear search").
  final String? clearLabel;

  /// Called with the new text.
  final ValueChanged<String>? onChanged;

  /// Called on the keyboard action.
  final ValueChanged<String>? onSubmitted;

  /// Whether the field accepts input.
  final bool enabled;

  /// Shows the text without editing (S31 question kept).
  final bool readOnly;

  /// Whether to focus on first build.
  final bool autofocus;

  /// An external focus node.
  final FocusNode? focusNode;

  /// The keyboard type.
  final TextInputType? keyboardType;

  /// The keyboard action.
  final TextInputAction? textInputAction;

  /// Capitalisation.
  final TextCapitalization textCapitalization;

  /// Minimum lines of a [TaroTextFieldStyle.multiLine] field (default 3).
  final int? minLines;

  /// Maximum lines of a [TaroTextFieldStyle.multiLine] field (null grows).
  final int? maxLines;

  /// The number of graphemes in [text].
  static int graphemeCount(String text) => text.characters.length;

  /// Whether [text] exceeds [maxGraphemes] (false without a limit).
  static bool isOverLimit(String text, int? maxGraphemes) =>
      maxGraphemes != null && graphemeCount(text) > maxGraphemes;

  @override
  State<TaroTextField> createState() => _TaroTextFieldState();
}

class _TaroTextFieldState extends State<TaroTextField> {
  TextEditingController? _own;

  TextEditingController get _controller =>
      widget.controller ?? (_own ??= TextEditingController());

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onText);
  }

  @override
  void didUpdateWidget(TaroTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      (oldWidget.controller ?? _own)?.removeListener(_onText);
      _controller.addListener(_onText);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onText);
    _own?.dispose();
    super.dispose();
  }

  void _onText() => setState(() {});

  void _clear() {
    _controller.clear();
    widget.onChanged?.call('');
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final c = tokens.color;
    final text = _controller.text;
    final count = TaroTextField.graphemeCount(text);
    final max = widget.maxGraphemes;
    final over = TaroTextField.isOverLimit(text, max);
    final showCounter = max != null && count >= widget.counterVisibleFrom;
    final hasError = widget.errorText != null || over;
    final caption = tokens.typography.caption;
    OutlineInputBorder outline(Color color, double width) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(tokens.radius.md),
      borderSide: BorderSide(color: color, width: width),
    );
    final search = widget.style == TaroTextFieldStyle.search;
    final multi = widget.style == TaroTextFieldStyle.multiLine;
    final field = TextField(
      controller: _controller,
      focusNode: widget.focusNode,
      enabled: widget.enabled,
      readOnly: widget.readOnly,
      autofocus: widget.autofocus,
      keyboardType:
          widget.keyboardType ??
          (multi ? TextInputType.multiline : TextInputType.text),
      textInputAction:
          widget.textInputAction ?? (search ? TextInputAction.search : null),
      textCapitalization: widget.textCapitalization,
      minLines: multi ? widget.minLines ?? 3 : 1,
      maxLines: multi ? widget.maxLines : 1,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      style: tokens.typography.body.copyWith(
        color: widget.enabled ? c.text.primary : c.text.disabled,
      ),
      cursorColor: c.accent.primary,
      decoration: InputDecoration(
        hintText: widget.hintText,
        hintStyle: tokens.typography.body.copyWith(color: c.text.tertiary),
        filled: true,
        fillColor: c.bg.sunken,
        isDense: true,
        constraints: BoxConstraints(minHeight: tokens.size.touchTarget.min),
        contentPadding: EdgeInsetsDirectional.symmetric(
          horizontal: tokens.space.s5,
          vertical: tokens.space.s4,
        ),
        prefixIcon: search
            ? ExcludeSemantics(
                child: Icon(
                  Icons.search_rounded,
                  size: tokens.size.icon.md,
                  color: c.text.secondary,
                ),
              )
            : null,
        suffixIcon: search && text.isNotEmpty && widget.enabled
            ? TaroIconButton(
                icon: Icons.close_rounded,
                semanticsLabel: widget.clearLabel ?? '',
                color: c.text.secondary,
                onPressed: _clear,
              )
            : null,
        border: outline(c.border.strong, TaroStrokes.control),
        enabledBorder: outline(
          hasError ? c.status.error : c.border.strong,
          TaroStrokes.control,
        ),
        focusedBorder: outline(
          hasError ? c.status.error : c.border.focus,
          TaroStrokes.focusRing,
        ),
        disabledBorder: outline(c.border.subtle, TaroStrokes.control),
      ),
    );
    final below = widget.errorText ?? widget.helperText ?? widget.statusText;
    final belowColor = widget.errorText != null
        ? c.status.error
        : c.text.secondary;
    return Opacity(
      opacity: widget.enabled ? 1 : tokens.opacity.disabled,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          MergeSemantics(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.label != null) ...[
                  Text(
                    widget.label!,
                    style: tokens.typography.label.copyWith(
                      color: c.text.secondary,
                    ),
                  ),
                  SizedBox(height: tokens.space.s3),
                ],
                field,
              ],
            ),
          ),
          if (below != null || showCounter) ...[
            SizedBox(height: tokens.space.s2),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: below == null
                      ? const SizedBox.shrink()
                      : Semantics(
                          liveRegion: widget.errorText != null,
                          child: Text(
                            below,
                            style: caption.copyWith(color: belowColor),
                          ),
                        ),
                ),
                if (showCounter) ...[
                  SizedBox(width: tokens.space.s3),
                  Semantics(
                    liveRegion: over,
                    child: Text(
                      (widget.counterFormatter ?? _defaultCounter)(count, max),
                      textAlign: TextAlign.end,
                      style: caption.copyWith(
                        color: over ? c.status.error : c.text.secondary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  static String _defaultCounter(int count, int max) => '$count / $max';
}
