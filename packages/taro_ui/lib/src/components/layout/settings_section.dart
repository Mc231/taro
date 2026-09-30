import 'package:flutter/material.dart';
import 'package:taro_ui/src/theme/taro_tokens_extension.dart';
import 'package:taro_ui/src/tokens/taro_strokes.dart';

/// A titled group of `SettingsTile`s on one `color.bg.surface` block with
/// `radius.lg` corners and hairline dividers ("Readings", "Experience",
/// "Privacy & data"; S20, S23). The [title] is a screen-reader header; an
/// optional [footer] explains the group in `type.caption`.
class SettingsSection extends StatelessWidget {
  /// Creates the group.
  const SettingsSection({
    required this.children,
    this.title,
    this.footer,
    super.key,
  });

  /// Localised header.
  final String? title;

  /// The rows.
  final List<Widget> children;

  /// Localised explanation under the group.
  final String? footer;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final c = tokens.color;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (title != null)
          Padding(
            padding: EdgeInsetsDirectional.only(
              start: tokens.space.s2,
              bottom: tokens.space.s3,
            ),
            child: Semantics(
              header: true,
              child: Text(
                title!,
                style: tokens.typography.label.copyWith(
                  color: c.text.secondary,
                ),
              ),
            ),
          ),
        ClipRRect(
          borderRadius: BorderRadius.circular(tokens.radius.lg),
          child: ColoredBox(
            color: c.bg.surface,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < children.length; i++) ...[
                  if (i > 0)
                    Divider(
                      height: TaroStrokes.hairline,
                      thickness: TaroStrokes.hairline,
                      color: c.border.subtle,
                    ),
                  children[i],
                ],
              ],
            ),
          ),
        ),
        if (footer != null)
          Padding(
            padding: EdgeInsetsDirectional.only(
              start: tokens.space.s2,
              end: tokens.space.s2,
              top: tokens.space.s3,
            ),
            child: Text(
              footer!,
              style: tokens.typography.caption.copyWith(
                color: c.text.secondary,
              ),
            ),
          ),
      ],
    );
  }
}
