import 'package:flutter/material.dart';
import 'package:taro_ui/src/theme/taro_tokens_extension.dart';

/// A section heading inside a reading ("Present · The Star, reversed",
/// "Where you are now", "Upright meaning"): `type.title` (or
/// `type.titleSmall` when [small]) with the `color.accent.secondary`
/// section marker and an optional sub-line in `color.text.secondary`.
/// Announced as a header.
class ReadingSectionHeader extends StatelessWidget {
  /// Creates the heading.
  const ReadingSectionHeader({
    required this.title,
    this.subtitle,
    this.marker = true,
    this.small = false,
    super.key,
  });

  /// Localised heading.
  final String title;

  /// Localised sub-line.
  final String? subtitle;

  /// Whether the vermilion marker shows.
  final bool marker;

  /// The smaller `type.titleSmall` style.
  final bool small;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final c = tokens.color;
    final style =
        (small ? tokens.typography.titleSmall : tokens.typography.title)
            .copyWith(color: c.text.primary);
    final dot = tokens.space.s3;
    final lineHeight = (style.fontSize ?? 0) * (style.height ?? 1);
    return Semantics(
      header: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (marker) ...[
            ExcludeSemantics(
              child: Padding(
                padding: EdgeInsetsDirectional.only(
                  top:
                      MediaQuery.textScalerOf(context).scale(lineHeight) / 2 -
                      dot / 2,
                ),
                child: Container(
                  width: dot,
                  height: dot,
                  decoration: BoxDecoration(
                    color: c.accent.secondary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
            SizedBox(width: tokens.space.s4),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: style),
                if (subtitle != null) ...[
                  SizedBox(height: tokens.space.s1),
                  Text(
                    subtitle!,
                    style: tokens.typography.body.copyWith(
                      color: c.text.secondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
