import 'package:flutter/material.dart';
import 'package:taro_ui/src/theme/taro_tokens_extension.dart';
import 'package:taro_ui/src/tokens/taro_strokes.dart';

/// The shared tap surface of the `taro_ui` controls (internal, not exported):
/// a `Material` fill with an optional outline, a pressed overlay of
/// `opacity.pressed`, no ripple, and the 2 px `color.border.focus` ring with
/// a 2 px gap while focused (`docs/design/components.md`).
///
/// It adds no semantics; the caller wraps it in a `Semantics` node that
/// names the control. `onTap == null` makes it inert (no ink, no focus).
class TaroPressable extends StatefulWidget {
  /// Creates the surface.
  const TaroPressable({
    required this.child,
    required this.onTap,
    required this.borderRadius,
    this.color = Colors.transparent,
    this.side = BorderSide.none,
    this.overlayColor,
    this.onLongPress,
    this.focusNode,
    this.autofocus = false,
    super.key,
  });

  /// The content.
  final Widget child;

  /// Called on tap; null disables the surface.
  final VoidCallback? onTap;

  /// Called on long press.
  final VoidCallback? onLongPress;

  /// Corner radius of the fill, the ink and the focus ring.
  final double borderRadius;

  /// The fill.
  final Color color;

  /// The outline.
  final BorderSide side;

  /// The pressed overlay colour (defaults to `color.text.primary`).
  final Color? overlayColor;

  /// An external focus node.
  final FocusNode? focusNode;

  /// Whether to take focus on first build.
  final bool autofocus;

  @override
  State<TaroPressable> createState() => _TaroPressableState();
}

class _TaroPressableState extends State<TaroPressable> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final radius = BorderRadius.circular(widget.borderRadius);
    final overlay = (widget.overlayColor ?? tokens.color.text.primary)
        .withValues(alpha: tokens.opacity.pressed);
    final surface = Material(
      color: widget.color,
      shape: RoundedRectangleBorder(borderRadius: radius, side: widget.side),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: widget.onTap,
        onLongPress: widget.onTap == null ? null : widget.onLongPress,
        focusNode: widget.focusNode,
        autofocus: widget.autofocus,
        onFocusChange: (value) => setState(() => _focused = value),
        customBorder: RoundedRectangleBorder(borderRadius: radius),
        splashFactory: NoSplash.splashFactory,
        overlayColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.pressed) ||
                  states.contains(WidgetState.hovered)
              ? overlay
              : Colors.transparent,
        ),
        child: widget.child,
      ),
    );
    return TaroFocusRing(
      visible: _focused,
      borderRadius: widget.borderRadius,
      child: surface,
    );
  }
}

/// Draws the focus ring (2 px `color.border.focus`, 2 px gap) around
/// [child] while [visible]. Internal to `taro_ui`.
class TaroFocusRing extends StatelessWidget {
  /// Wraps [child].
  const TaroFocusRing({
    required this.visible,
    required this.borderRadius,
    required this.child,
    super.key,
  });

  /// Whether the ring shows.
  final bool visible;

  /// The corner radius of [child].
  final double borderRadius;

  /// The focused control.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!visible) return child;
    const inset = -(TaroStrokes.focusGap + TaroStrokes.focusRing);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        PositionedDirectional(
          start: inset,
          end: inset,
          top: inset,
          bottom: inset,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(
                  borderRadius + TaroStrokes.focusGap,
                ),
                border: Border.all(
                  color: context.tokens.color.border.focus,
                  width: TaroStrokes.focusRing,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
