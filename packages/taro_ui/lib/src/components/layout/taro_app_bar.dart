import 'package:flutter/material.dart';
import 'package:taro_ui/src/components/inputs/taro_icon_button.dart';
import 'package:taro_ui/src/theme/taro_tokens_extension.dart';
import 'package:taro_ui/src/tokens/generated/taro_tokens.g.dart';

/// The leading control of a [TaroAppBar].
enum TaroAppBarLeading {
  /// No leading control (tab roots).
  none,

  /// A Back chevron that mirrors in RTL (pushed screens).
  back,

  /// A Close X (modal flows: S08, S09, S11).
  close,
}

/// The top bar (02 §14.3): a leading Back or Close, an optional in-bar
/// [title] (`type.title`, pushed detail screens), an optional live [status]
/// ("2 of 3 picked", announced politely) and trailing [actions]
/// (`TaroIconButton`s or tertiary `TaroButton`s).
///
/// Tab roots and most screens put a large serif title below the bar with
/// [TaroLargeTitle]. [scrolled] tints the bar `color.bg.surface` with a
/// hairline once content scrolls under it. The bar is
/// `size.touchTarget.min + 2 × space.3` high and sits under the status bar.
class TaroAppBar extends StatelessWidget implements PreferredSizeWidget {
  /// Creates the bar.
  const TaroAppBar({
    this.leading = TaroAppBarLeading.back,
    this.onLeading,
    this.leadingLabel,
    this.title,
    this.status,
    this.actions = const [],
    this.scrolled = false,
    super.key,
  }) : assert(
         leading == TaroAppBarLeading.none || leadingLabel != null,
         'Back and Close need a localised label',
       );

  /// The leading control.
  final TaroAppBarLeading leading;

  /// Called by the leading control (defaults to `Navigator.maybePop`).
  final VoidCallback? onLeading;

  /// Localised label of the leading control ("Back", "Close").
  final String? leadingLabel;

  /// Localised in-bar title.
  final String? title;

  /// Localised live status text.
  final String? status;

  /// Trailing actions, in reading order.
  final List<Widget> actions;

  /// Whether content has scrolled under the bar.
  final bool scrolled;

  /// The bar height (tokens are mode-independent for sizes).
  static final double height =
      TaroSizeTokens.light.touchTarget.min + 2 * TaroSpaceTokens.light.s3;

  @override
  Size get preferredSize => Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final c = tokens.color;
    final leadingButton = switch (leading) {
      TaroAppBarLeading.none => null,
      TaroAppBarLeading.back => TaroIconButton(
        icon: Icons.arrow_back_ios_new_rounded,
        semanticsLabel: leadingLabel!,
        onPressed: onLeading ?? () => Navigator.maybePop(context),
      ),
      TaroAppBarLeading.close => TaroIconButton(
        icon: Icons.close_rounded,
        semanticsLabel: leadingLabel!,
        onPressed: onLeading ?? () => Navigator.maybePop(context),
      ),
    };
    return Material(
      color: scrolled ? c.bg.surface : c.bg.canvas,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: scrolled ? c.border.subtle : Colors.transparent,
            ),
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: height),
            child: Padding(
              padding: EdgeInsetsDirectional.symmetric(
                horizontal: tokens.space.s2,
                vertical: tokens.space.s3,
              ),
              child: Row(
                children: [
                  ?leadingButton,
                  SizedBox(width: tokens.space.s2),
                  Expanded(
                    child: title == null
                        ? const SizedBox.shrink()
                        : Semantics(
                            header: true,
                            child: Text(
                              title!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: tokens.typography.title.copyWith(
                                color: c.text.primary,
                              ),
                            ),
                          ),
                  ),
                  if (status != null) ...[
                    Semantics(
                      liveRegion: true,
                      child: Text(
                        status!,
                        style: tokens.typography.label.copyWith(
                          color: c.text.secondary,
                        ),
                      ),
                    ),
                    SizedBox(width: tokens.space.s3),
                  ],
                  ...actions,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The large serif screen title under a [TaroAppBar] or at the top of a tab
/// root (`type.headline`, `Semantics(header: true)`). Wraps, never
/// truncates (01 §12).
class TaroLargeTitle extends StatelessWidget {
  /// Creates the title.
  const TaroLargeTitle(this.text, {super.key});

  /// Localised title.
  final String text;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Semantics(
      header: true,
      child: Text(
        text,
        style: tokens.typography.headline.copyWith(
          color: tokens.color.text.primary,
        ),
      ),
    );
  }
}
