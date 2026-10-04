import 'package:flutter/material.dart';
import 'package:taro_ui/taro_ui.dart';

/// The page template of the onboarding screens S02–S04 and the ATT
/// pre-prompt (docs/design/screens/S02–S04): `space.12` top, `space.7`
/// sides and `space.9` bottom padding, the [content] in one column with
/// [gap] between them, then the [footer] (buttons, step indicator,
/// footnote) pinned at the bottom.
///
/// When the content is taller than the space above the footer (small
/// phones) it scrolls, so nothing clips and the actions stay reachable.
/// Above 1.5× text the footer scrolls after the content instead. On
/// tablets the column is `layout.maxContentWidth` wide and centred
/// (`TaroScaffold`).
class OnboardingPage extends StatelessWidget {
  /// Creates the page.
  const OnboardingPage({
    required this.content,
    required this.footer,
    this.gap,
    this.appBar,
    super.key,
  });

  /// The content, top to bottom.
  final List<Widget> content;

  /// The bottom block, pinned under the scrolling content.
  final Widget footer;

  /// The gap between [content] (default `space.8`).
  final double? gap;

  /// An app bar (S04 re-entry Back); the top padding shrinks with it.
  final PreferredSizeWidget? appBar;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final space = tokens.space;
    final gutter = space.s7;
    final top = Padding(
      padding: EdgeInsetsDirectional.fromSTEB(
        gutter,
        appBar == null ? space.s12 : space.s5,
        gutter,
        space.s7,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: gap ?? space.s8,
        children: content,
      ),
    );
    final bottom = Padding(
      padding: EdgeInsetsDirectional.fromSTEB(gutter, 0, gutter, space.s9),
      child: footer,
    );
    // Above 1.5× text the footer scrolls after the content: pinned, it
    // would cover most of the screen (S02 at 200 %, BUG-04).
    final flow =
        MediaQuery.textScalerOf(context).scale(1) > kSpreadReflowTextScale;
    return TaroScaffold(
      appBar: appBar,
      padded: false,
      body: flow
          ? SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [top, bottom],
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: SingleChildScrollView(child: top)),
                bottom,
              ],
            ),
    );
  }
}

/// The 56 dp icon tile at the top of S04 and the ATT pre-prompt:
/// `radius.lg`, `color.accent.subtle`, the icon in `color.accent.primary`.
/// Decorative (excluded from semantics).
class OnboardingIconTile extends StatelessWidget {
  /// Creates the tile.
  const OnboardingIconTile({required this.icon, super.key});

  /// The icon.
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final side = tokens.space.s11;
    return ExcludeSemantics(
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: Container(
          width: side,
          height: side,
          decoration: BoxDecoration(
            color: tokens.color.accent.subtle,
            borderRadius: BorderRadius.circular(tokens.radius.lg),
          ),
          child: Icon(
            icon,
            size: tokens.size.icon.md,
            color: tokens.color.accent.primary,
          ),
        ),
      ),
    );
  }
}
