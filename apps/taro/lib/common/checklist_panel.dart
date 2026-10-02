import 'package:flutter/material.dart';
import 'package:taro_ui/taro_ui.dart';

/// One line of a [ChecklistPanel]: a statement, an optional caption and
/// an optional value at the end ("128 readings").
@immutable
class ChecklistItem {
  /// Creates the line.
  const ChecklistItem(this.title, {this.caption, this.value});

  /// The localised statement.
  final String title;

  /// The localised caption under it.
  final String? caption;

  /// The localised value at the end.
  final String? value;
}

/// The include / exclude panel of S24 and S26 (`ChecklistPanel`,
/// `docs/design/screens/S24`): a [title] header, then check (included,
/// `color.status.success`) or minus (excluded, `color.text.tertiary`)
/// lines in `type.label`, and an optional [footer] caption. [accent] fills
/// it with `color.accent.subtle` ("What's kept" on S26), else
/// `color.bg.surface`. Each line is one screen-reader node.
class ChecklistPanel extends StatelessWidget {
  /// Creates the panel.
  const ChecklistPanel({
    required this.title,
    required this.items,
    required this.included,
    this.footer,
    this.accent = false,
    super.key,
  });

  /// The localised header ("Included", "What's erased").
  final String title;

  /// The lines.
  final List<ChecklistItem> items;

  /// Check icons (true) or minus icons (false).
  final bool included;

  /// The localised caption under the lines.
  final String? footer;

  /// The `color.accent.subtle` fill.
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final c = tokens.color;
    final footer = this.footer;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: accent ? c.accent.subtle : c.bg.surface,
        borderRadius: BorderRadius.circular(tokens.radius.lg),
      ),
      child: Padding(
        padding: EdgeInsetsDirectional.all(tokens.space.s5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: tokens.space.s4,
          children: [
            Semantics(
              header: true,
              child: Text(
                title,
                style: tokens.typography.titleSmall.copyWith(
                  color: c.text.primary,
                ),
              ),
            ),
            for (final item in items)
              MergeSemantics(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: tokens.space.s4,
                  children: [
                    ExcludeSemantics(
                      child: Icon(
                        included ? Icons.check_rounded : Icons.remove_rounded,
                        size: tokens.size.icon.md,
                        color: included ? c.status.success : c.text.tertiary,
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: tokens.space.s1,
                        children: [
                          Text(
                            item.title,
                            style: tokens.typography.label.copyWith(
                              color: c.text.primary,
                            ),
                          ),
                          if (item.caption case final caption?)
                            Text(
                              caption,
                              style: tokens.typography.caption.copyWith(
                                color: c.text.secondary,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (item.value case final value?)
                      Text(
                        value,
                        style: tokens.typography.label.copyWith(
                          color: c.text.secondary,
                        ),
                      ),
                  ],
                ),
              ),
            if (footer != null)
              Text(
                footer,
                style: tokens.typography.caption.copyWith(
                  color: c.text.secondary,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
