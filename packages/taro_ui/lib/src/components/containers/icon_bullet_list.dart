import 'package:flutter/material.dart';
import 'package:taro_ui/src/theme/taro_tokens_extension.dart';

/// The intent of an [IconBulletItem], which picks its icon colour.
enum IconBulletIntent {
  /// A brand statement: the given icon in `color.card.frame`.
  neutral,

  /// An accent statement: the given icon in `color.accent.primary`.
  accent,

  /// Included: a check in `color.status.success`.
  included,

  /// Excluded: a dash in `color.text.tertiary`.
  excluded,
}

/// One statement of an [IconBulletList].
@immutable
class IconBulletItem {
  /// Creates the statement.
  const IconBulletItem({
    required this.title,
    this.body,
    this.icon,
    this.intent = IconBulletIntent.neutral,
  });

  /// Localised statement.
  final String title;

  /// Localised explanation.
  final String? body;

  /// The glyph for [IconBulletIntent.neutral] and
  /// [IconBulletIntent.accent] (included/excluded use check/dash).
  final IconData? icon;

  /// The intent.
  final IconBulletIntent intent;
}

/// A short vertical list of icon + statement (S02 value list, S03
/// disclaimer points, S24 Included / Not included, S26 What's erased /
/// What's kept, S30). Icons are decorative; the text carries the meaning.
class IconBulletList extends StatelessWidget {
  /// Creates the list.
  const IconBulletList({required this.items, super.key});

  /// The statements.
  final List<IconBulletItem> items;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final c = tokens.color;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      spacing: tokens.space.s5,
      children: [
        for (final item in items)
          MergeSemantics(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ExcludeSemantics(
                  child: Icon(
                    switch (item.intent) {
                      IconBulletIntent.included => Icons.check_rounded,
                      IconBulletIntent.excluded => Icons.remove_rounded,
                      _ => item.icon ?? Icons.circle_outlined,
                    },
                    size: tokens.size.icon.md,
                    color: switch (item.intent) {
                      IconBulletIntent.neutral => c.card.frame,
                      IconBulletIntent.accent => c.accent.primary,
                      IconBulletIntent.included => c.status.success,
                      IconBulletIntent.excluded => c.text.tertiary,
                    },
                  ),
                ),
                SizedBox(width: tokens.space.s4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        item.title,
                        style: tokens.typography.titleSmall.copyWith(
                          color: c.text.primary,
                        ),
                      ),
                      if (item.body != null) ...[
                        SizedBox(height: tokens.space.s1),
                        Text(
                          item.body!,
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
          ),
      ],
    );
  }
}
