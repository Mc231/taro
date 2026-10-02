import 'package:flutter/material.dart';
import 'package:taro/l10n/generated/taro_localizations.dart';
import 'package:taro_ui/taro_ui.dart';

/// The page template of the Settings sub-screens S21–S26, S28 and S29
/// (`docs/design/screens/S21`–`S29`): Back, the serif [title], an optional
/// secondary [lead] paragraph, then [children] separated by [gap]
/// (`space.5` by default) in one scrolling list, and an optional [footer]
/// pinned at the bottom (primary action + caption).
///
/// While [busy] (an import or a wipe is running) Back is hidden and the
/// system back gesture does nothing. On tablets the column is
/// `layout.maxContentWidth` wide and centred (`TaroScaffold`).
class SettingsPage extends StatelessWidget {
  /// Creates the page.
  const SettingsPage({
    required this.title,
    required this.children,
    required this.onBack,
    this.lead,
    this.footer,
    this.gap,
    this.busy = false,
    super.key,
  });

  /// The localised title (`type.headline`, a header).
  final String title;

  /// The localised paragraph under the title.
  final String? lead;

  /// The content, top to bottom.
  final List<Widget> children;

  /// The pinned bottom block.
  final Widget? footer;

  /// The gap between [children] (default `space.5`).
  final double? gap;

  /// Back.
  final VoidCallback onBack;

  /// Whether leaving is blocked (no Back, no system back).
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final l10n = TaroLocalizations.of(context);
    final tokens = context.tokens;
    final space = gap ?? tokens.space.s5;
    final lead = this.lead;
    final header = <Widget>[
      TaroLargeTitle(title),
      if (lead != null) ...[
        SizedBox(height: tokens.space.s2),
        Text(
          lead,
          style: tokens.typography.body.copyWith(
            color: tokens.color.text.secondary,
          ),
        ),
      ],
    ];
    return PopScope(
      canPop: !busy,
      child: TaroScaffold(
        appBar: TaroAppBar(
          leading: busy ? TaroAppBarLeading.none : TaroAppBarLeading.back,
          leadingLabel: l10n.commonBack,
          onLeading: onBack,
        ),
        bottom: footer,
        body: ListView(
          padding: EdgeInsetsDirectional.only(
            top: tokens.space.s3,
            bottom: tokens.space.s7,
          ),
          children: [
            ...header,
            for (final child in children) ...[
              SizedBox(height: space),
              child,
            ],
          ],
        ),
      ),
    );
  }
}

/// A caption-style group header inside a [SettingsPage] ("What you'll
/// see", "How to bring it in"): `type.label`, `color.text.secondary`, a
/// screen-reader header.
class SettingsPageCaption extends StatelessWidget {
  /// Creates the caption.
  const SettingsPageCaption(this.text, {super.key});

  /// The localised caption.
  final String text;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Padding(
      padding: EdgeInsetsDirectional.only(start: tokens.space.s2),
      child: Semantics(
        header: true,
        child: Text(
          text,
          style: tokens.typography.label.copyWith(
            color: tokens.color.text.secondary,
          ),
        ),
      ),
    );
  }
}
