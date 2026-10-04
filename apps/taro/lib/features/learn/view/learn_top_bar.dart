import 'package:flutter/material.dart';
import 'package:taro/l10n/generated/taro_localizations.dart';
import 'package:taro_ui/taro_ui.dart';

/// The Learn detail top bar (S17, S18, S19): Back at the start, a centred
/// `type.caption` [caption] ("Cups · 3 of 14", "Spreads guide · 6 of 6",
/// "Learn") and the [actions] (previous / next) at the end. Without actions
/// a touch-target spacer keeps the caption centred.
class LearnTopBar extends StatelessWidget implements PreferredSizeWidget {
  /// Creates the bar.
  const LearnTopBar({
    required this.onBack,
    this.caption,
    this.actions = const [],
    super.key,
  });

  /// Back.
  final VoidCallback onBack;

  /// The centred caption.
  final String? caption;

  /// Trailing buttons.
  final List<Widget> actions;

  @override
  Size get preferredSize => Size.fromHeight(TaroAppBar.height);

  @override
  Widget build(BuildContext context) {
    final l10n = TaroLocalizations.of(context);
    final tokens = context.tokens;
    final c = tokens.color;
    final caption = this.caption;
    final spacer = SizedBox(width: tokens.size.touchTarget.min);
    return Material(
      color: c.bg.canvas,
      child: SafeArea(
        bottom: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: TaroAppBar.height),
          child: Padding(
            padding: EdgeInsetsDirectional.symmetric(
              horizontal: tokens.space.s2,
              vertical: tokens.space.s3,
            ),
            child: Row(
              children: [
                TaroIconButton(
                  icon: Icons.arrow_back_ios_new_rounded,
                  semanticsLabel: l10n.commonBack,
                  onPressed: onBack,
                ),
                // Mirrors the actions so the caption stays centred.
                if (actions.length > 1) spacer,
                Expanded(
                  child: caption == null
                      ? const SizedBox.shrink()
                      // Up to two lines at the bar's width; when large
                      // text makes them taller than the bar they shrink
                      // to fit instead of running out of it (BUG-12).
                      : LayoutBuilder(
                          builder: (context, box) => FittedBox(
                            fit: BoxFit.scaleDown,
                            child: SizedBox(
                              width: box.maxWidth,
                              child: Text(
                                caption,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: tokens.typography.caption.copyWith(
                                  color: c.text.secondary,
                                ),
                              ),
                            ),
                          ),
                        ),
                ),
                if (actions.isEmpty) spacer else ...actions,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
