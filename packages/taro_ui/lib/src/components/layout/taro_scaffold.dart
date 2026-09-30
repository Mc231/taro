import 'package:flutter/material.dart';
import 'package:taro_ui/src/theme/taro_tokens_extension.dart';

/// The page frame (02 §14.3): safe areas, `color.bg.canvas`, `layout.gutter`
/// side padding, content centred and capped at `layout.maxContentWidth` on
/// wide screens (RC24). Optional slots: an app bar, a top banner
/// (`TaroOfflineBanner`), a [bottom] slot for a sticky CTA outside the
/// scroll view, a full-width [banner] slot separated by `space.adGap`
/// (RC59), and a bottom navigation bar.
class TaroScaffold extends StatelessWidget {
  /// Creates the frame.
  const TaroScaffold({
    required this.body,
    this.appBar,
    this.topBanner,
    this.bottom,
    this.banner,
    this.bottomNavigationBar,
    this.padded = true,
    this.backgroundColor,
    this.resizeToAvoidBottomInset = true,
    super.key,
  });

  /// The screen content (it scrolls itself where needed).
  final Widget body;

  /// An app bar (`TaroAppBar`).
  final PreferredSizeWidget? appBar;

  /// A banner above the content, e.g. `TaroOfflineBanner`.
  final Widget? topBanner;

  /// A sticky slot under the content (primary CTA), padded like the body.
  final Widget? bottom;

  /// A full-width slot at the very bottom (the ad banner container), at
  /// least `space.adGap` from the content (RC59).
  final Widget? banner;

  /// The tab bar.
  final Widget? bottomNavigationBar;

  /// Whether [body] gets the `layout.gutter` side padding.
  final bool padded;

  /// Overrides `color.bg.canvas`.
  final Color? backgroundColor;

  /// See [Scaffold.resizeToAvoidBottomInset].
  final bool resizeToAvoidBottomInset;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    Widget constrained(Widget child, {required bool pad, bool fill = false}) =>
        Padding(
          padding: EdgeInsetsDirectional.symmetric(
            horizontal: pad ? tokens.layout.gutter : 0,
          ),
          child: Align(
            alignment: AlignmentDirectional.topCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: tokens.layout.maxContentWidth,
              ),
              child: fill ? SizedBox.expand(child: child) : child,
            ),
          ),
        );
    return Scaffold(
      backgroundColor: backgroundColor ?? tokens.color.bg.canvas,
      appBar: appBar,
      bottomNavigationBar: bottomNavigationBar,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      body: SafeArea(
        top: appBar == null,
        bottom: bottomNavigationBar == null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ?topBanner,
            Expanded(child: constrained(body, pad: padded, fill: true)),
            if (bottom != null)
              Padding(
                padding: EdgeInsetsDirectional.only(
                  top: tokens.space.s5,
                  bottom: tokens.space.s5,
                ),
                child: constrained(bottom!, pad: true),
              ),
            if (banner != null)
              Padding(
                padding: EdgeInsetsDirectional.only(top: tokens.space.adGap),
                child: banner,
              ),
          ],
        ),
      ),
    );
  }
}
