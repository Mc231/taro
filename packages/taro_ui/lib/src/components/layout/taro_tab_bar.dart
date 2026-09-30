import 'dart:ui' show SemanticsRole;

import 'package:flutter/material.dart';
import 'package:taro_ui/src/components/common/taro_pressable.dart';
import 'package:taro_ui/src/theme/taro_tokens_extension.dart';

/// One destination of a [TaroTabBar].
@immutable
class TaroTabItem {
  /// Creates the destination.
  const TaroTabItem({
    required this.icon,
    required this.label,
    this.selectedIcon,
  });

  /// The glyph.
  final IconData icon;

  /// The glyph while selected (defaults to [icon]).
  final IconData? selectedIcon;

  /// Localised label ("Today", "Journal", "Learn", "Settings").
  final String label;
}

/// The bottom navigation (RC17: Today, Journal, Learn, Settings): icon +
/// label per tab on `color.bg.surface` with a `color.border.subtle`
/// hairline on top. The selected tab is `color.accent.primary`, the others
/// `color.text.secondary`. Screen readers get a `tabBar` of `tab`s with the
/// selected state; the order mirrors in RTL. At large text a label stays on
/// one line and scales down to fit its tab.
class TaroTabBar extends StatelessWidget {
  /// Creates the bar.
  const TaroTabBar({
    required this.items,
    required this.currentIndex,
    required this.onSelected,
    super.key,
  });

  /// The destinations.
  final List<TaroTabItem> items;

  /// The selected destination.
  final int currentIndex;

  /// Called with the tapped index (also for the selected tab: pop to root).
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    assert(items.length >= 2, 'at least two tabs');
    final tokens = context.tokens;
    final c = tokens.color;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.bg.surface,
        border: Border(
          top: BorderSide(color: c.border.subtle),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsetsDirectional.symmetric(vertical: tokens.space.s2),
          child: Semantics(
            container: true,
            role: SemanticsRole.tabBar,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < items.length; i++)
                  Expanded(
                    child: _Tab(
                      item: items[i],
                      selected: i == currentIndex,
                      onTap: () => onSelected(i),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({required this.item, required this.selected, required this.onTap});

  final TaroTabItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final c = tokens.color;
    final color = selected ? c.accent.primary : c.text.secondary;
    return Semantics(
      container: true,
      role: SemanticsRole.tab,
      selected: selected,
      child: TaroPressable(
        onTap: onTap,
        borderRadius: tokens.radius.md,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: tokens.size.touchTarget.min),
          child: Padding(
            padding: EdgeInsetsDirectional.symmetric(
              horizontal: tokens.space.s1,
              vertical: tokens.space.s2,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ExcludeSemantics(
                  child: Icon(
                    selected ? item.selectedIcon ?? item.icon : item.icon,
                    size: tokens.size.icon.md,
                    color: color,
                  ),
                ),
                SizedBox(height: tokens.space.s1),
                // One line, scaled down to fit rather than broken mid-word
                // at large text; the full label stays in the semantics.
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    item.label,
                    maxLines: 1,
                    textAlign: TextAlign.center,
                    style: tokens.typography.label.copyWith(color: color),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
