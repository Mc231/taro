import 'package:flutter/material.dart';
import 'package:taro_ui/src/components/common/taro_pressable.dart';
import 'package:taro_ui/src/theme/taro_tokens_extension.dart';
import 'package:taro_ui/src/tokens/taro_strokes.dart';

/// A generic content container (`docs/design/components.md`): S05 daily
/// card tile and "Ask the cards a question" card, S13 meaning block, S24
/// file card, S27 hotline group, S31 paused card.
///
/// `color.bg.surface` with `radius.lg` (or `color.bg.surfaceRaised` +
/// `elevation.1` when [raised]); [highlighted] adds the `color.accent.subtle`
/// fill with a `color.accent.primary` ring (the coachmark target). With
/// [onTap] the whole card is one button node whose label is merged from
/// its text (or [semanticsLabel]).
class TaroSurfaceCard extends StatelessWidget {
  /// Creates the card.
  const TaroSurfaceCard({
    required this.child,
    this.onTap,
    this.raised = false,
    this.highlighted = false,
    this.padding,
    this.semanticsLabel,
    super.key,
  });

  /// The content.
  final Widget child;

  /// Makes the card one tappable unit.
  final VoidCallback? onTap;

  /// `color.bg.surfaceRaised` + `elevation.1` (the primary CTA card).
  final bool raised;

  /// The highlighted state.
  final bool highlighted;

  /// Overrides the `space.5` padding.
  final EdgeInsetsGeometry? padding;

  /// Overrides the merged screen-reader label of a tappable card.
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final c = tokens.color;
    final fill = highlighted
        ? c.accent.subtle
        : raised
        ? c.bg.surfaceRaised
        : c.bg.surface;
    final radius = tokens.radius.lg;
    final body = Padding(
      padding: padding ?? EdgeInsetsDirectional.all(tokens.space.s5),
      child: child,
    );
    Widget card = TaroPressable(
      onTap: onTap,
      borderRadius: radius,
      color: fill,
      side: highlighted
          ? BorderSide(color: c.accent.primary, width: TaroStrokes.focusRing)
          : BorderSide.none,
      child: body,
    );
    if (raised && tokens.brightness == Brightness.light) {
      card = DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          boxShadow: tokens.elevation.e1.shadow,
        ),
        child: card,
      );
    }
    if (onTap == null) return card;
    return MergeSemantics(
      child: Semantics(
        button: true,
        label: semanticsLabel,
        excludeSemantics: semanticsLabel != null,
        onTap: semanticsLabel != null ? onTap : null,
        child: card,
      ),
    );
  }
}
