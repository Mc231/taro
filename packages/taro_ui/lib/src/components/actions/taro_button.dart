import 'package:flutter/material.dart';
import 'package:taro_ui/src/motion/taro_motion.dart';
import 'package:taro_ui/src/theme/taro_tokens_extension.dart';
import 'package:taro_ui/src/tokens/taro_strokes.dart';

/// The visual role of a [TaroButton] (`docs/design/components.md`).
enum TaroButtonVariant {
  /// Filled `color.accent.primary`: one per screen.
  primary,

  /// Outlined with `color.border.strong`.
  secondary,

  /// Text only in `color.accent.primary` (the design's "Text" button).
  tertiary,

  /// Filled `color.status.error`: destructive actions only.
  destructive,
}

/// Every action button (02 §14.3): primary, secondary, tertiary,
/// destructive, each with a loading state.
///
/// The label is a sentence-case verb, passed already localised. While
/// [loading], taps are ignored and a spinner replaces the label visually;
/// the label stays in the semantics tree. `onPressed == null` renders the
/// disabled state (`opacity.disabled`). Targets are ≥ 48 × 48 dp (primary,
/// secondary and destructive are 52 dp high); focus shows a 2 px
/// `color.border.focus` ring with a 2 px gap.
class TaroButton extends StatefulWidget {
  /// Creates a button of [variant].
  const TaroButton({
    required this.label,
    required this.onPressed,
    this.variant = TaroButtonVariant.primary,
    this.loading = false,
    this.icon,
    this.expand,
    this.semanticsLabel,
    this.loadingSemanticsHint,
    super.key,
  });

  /// A primary button.
  const TaroButton.primary({
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.icon,
    this.expand,
    this.semanticsLabel,
    this.loadingSemanticsHint,
    super.key,
  }) : variant = TaroButtonVariant.primary;

  /// A secondary (outlined) button.
  const TaroButton.secondary({
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.icon,
    this.expand,
    this.semanticsLabel,
    this.loadingSemanticsHint,
    super.key,
  }) : variant = TaroButtonVariant.secondary;

  /// A tertiary (text) button.
  const TaroButton.tertiary({
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.icon,
    this.expand,
    this.semanticsLabel,
    this.loadingSemanticsHint,
    super.key,
  }) : variant = TaroButtonVariant.tertiary;

  /// A destructive button.
  const TaroButton.destructive({
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.icon,
    this.expand,
    this.semanticsLabel,
    this.loadingSemanticsHint,
    super.key,
  }) : variant = TaroButtonVariant.destructive;

  /// The visible label.
  final String label;

  /// Called on tap; null disables the button.
  final VoidCallback? onPressed;

  /// The visual role.
  final TaroButtonVariant variant;

  /// Shows the spinner and ignores taps.
  final bool loading;

  /// Optional leading icon.
  final IconData? icon;

  /// Whether the button fills the available width. Defaults to true for
  /// every variant except [TaroButtonVariant.tertiary].
  final bool? expand;

  /// Overrides [label] for screen readers.
  final String? semanticsLabel;

  /// Screen-reader hint while [loading] (e.g. "Loading").
  final String? loadingSemanticsHint;

  @override
  State<TaroButton> createState() => _TaroButtonState();
}

class _TaroButtonState extends State<TaroButton> {
  bool _pressed = false;
  bool _focused = false;

  bool get _enabled => widget.onPressed != null && !widget.loading;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final c = tokens.color;
    final variant = widget.variant;
    final (Color background, Color foreground) = switch (variant) {
      TaroButtonVariant.primary => (
        _pressed ? c.accent.primaryPressed : c.accent.primary,
        c.text.onAccent,
      ),
      TaroButtonVariant.secondary => (Colors.transparent, c.text.primary),
      TaroButtonVariant.tertiary => (Colors.transparent, c.accent.primary),
      TaroButtonVariant.destructive => (c.status.error, c.status.onError),
    };
    final radius = BorderRadius.circular(tokens.radius.md);
    final minHeight = variant == TaroButtonVariant.tertiary
        ? tokens.size.touchTarget.min
        : tokens.size.touchTarget.min + tokens.space.s2;
    final labelStyle = tokens.typography.label.copyWith(color: foreground);
    final label = Text(
      widget.label,
      textAlign: TextAlign.center,
      style: labelStyle,
    );
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.icon != null) ...[
          Icon(widget.icon, size: tokens.size.icon.sm, color: foreground),
          SizedBox(width: tokens.space.s3),
        ],
        Flexible(child: label),
      ],
    );
    final body = widget.loading
        ? Stack(
            alignment: AlignmentDirectional.center,
            children: [
              Opacity(opacity: 0, alwaysIncludeSemantics: true, child: content),
              _Spinner(color: foreground),
            ],
          )
        : content;
    final overlay = foreground.withValues(alpha: tokens.opacity.pressed);
    Widget button = Material(
      color: background,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: variant == TaroButtonVariant.secondary
            ? BorderSide(color: c.border.strong, width: TaroStrokes.control)
            : BorderSide.none,
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: _enabled ? widget.onPressed : null,
        onHighlightChanged: (value) => setState(() => _pressed = value),
        onFocusChange: (value) => setState(() => _focused = value),
        customBorder: RoundedRectangleBorder(borderRadius: radius),
        splashFactory: NoSplash.splashFactory,
        overlayColor: WidgetStateProperty.resolveWith(
          (states) => variant == TaroButtonVariant.primary
              ? Colors.transparent
              : states.contains(WidgetState.pressed)
              ? overlay
              : null,
        ),
        focusColor: Colors.transparent,
        hoverColor: overlay,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: minHeight,
            minWidth: tokens.size.touchTarget.min,
          ),
          child: Padding(
            padding: EdgeInsetsDirectional.symmetric(
              horizontal: tokens.space.s5,
              vertical: tokens.space.s3,
            ),
            child: Center(widthFactor: 1, heightFactor: 1, child: body),
          ),
        ),
      ),
    );
    if (widget.onPressed == null) {
      button = Opacity(opacity: tokens.opacity.disabled, child: button);
    }
    if (_focused) {
      const inset = -(TaroStrokes.focusGap + TaroStrokes.focusRing);
      button = Stack(
        clipBehavior: Clip.none,
        children: [
          button,
          PositionedDirectional(
            start: inset,
            end: inset,
            top: inset,
            bottom: inset,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(
                    tokens.radius.md + TaroStrokes.focusGap,
                  ),
                  border: Border.all(
                    color: c.border.focus,
                    width: TaroStrokes.focusRing,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }
    final expand = widget.expand ?? variant != TaroButtonVariant.tertiary;
    // Its own node: inside a toast, coachmark or list row the button is
    // announced separately, not merged into the surrounding text.
    return Semantics(
      container: true,
      button: true,
      enabled: _enabled,
      label: widget.semanticsLabel,
      hint: widget.loading ? widget.loadingSemanticsHint : null,
      excludeSemantics: widget.semanticsLabel != null,
      onTap: widget.semanticsLabel != null && _enabled
          ? widget.onPressed
          : null,
      child: expand
          ? LayoutBuilder(
              builder: (context, constraints) => constraints.hasBoundedWidth
                  ? SizedBox(width: constraints.maxWidth, child: button)
                  : button,
            )
          : button,
    );
  }
}

class _Spinner extends StatelessWidget {
  const _Spinner({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final size = tokens.size.icon.md;
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: size,
        child: CircularProgressIndicator(
          // Reduced motion: a still arc instead of the spinning one.
          value: context.reduceMotion ? 0.75 : null,
          strokeWidth: TaroStrokes.focusRing,
          color: color,
        ),
      ),
    );
  }
}
