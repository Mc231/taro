import 'dart:async';
import 'dart:ui' show SemanticsRole;

import 'package:flutter/material.dart';
import 'package:taro_ui/src/components/common/taro_pressable.dart';
import 'package:taro_ui/src/motion/taro_motion.dart';
import 'package:taro_ui/src/theme/taro_tokens_extension.dart';
import 'package:taro_ui/src/tokens/taro_strokes.dart';

/// A horizontally scrollable strip of document tabs (S29: Disclaimer, Terms
/// of use, Privacy policy, Open-source licences).
///
/// Unlike `SegmentedChoice` the labels are long and the strip scrolls; the
/// order mirrors in RTL. Screen readers get a `tabBar` of `tab` nodes with
/// the selected state. The selected tab has a `color.accent.primary`
/// underline and is scrolled into view when it changes.
class TaroTabStrip extends StatefulWidget {
  /// Creates the strip.
  const TaroTabStrip({
    required this.labels,
    required this.selectedIndex,
    required this.onSelected,
    super.key,
  });

  /// Localised tab labels.
  final List<String> labels;

  /// The selected tab.
  final int selectedIndex;

  /// Called with the tapped index.
  final ValueChanged<int> onSelected;

  @override
  State<TaroTabStrip> createState() => _TaroTabStripState();
}

class _TaroTabStripState extends State<TaroTabStrip> {
  final List<GlobalKey> _keys = [];

  @override
  void didUpdateWidget(TaroTabStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex != widget.selectedIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _reveal());
    }
  }

  void _reveal() {
    if (!mounted || widget.selectedIndex >= _keys.length) return;
    final target = _keys[widget.selectedIndex].currentContext;
    if (target == null) return;
    unawaited(
      Scrollable.ensureVisible(
        target,
        alignment: 0.5,
        duration: context.reduceMotion
            ? context.tokens.reducedMotion.duration.instant
            : context.motion.duration.base,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final c = tokens.color;
    while (_keys.length < widget.labels.length) {
      _keys.add(GlobalKey());
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: c.border.subtle,
          ),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsetsDirectional.symmetric(
          horizontal: tokens.space.s3,
        ),
        child: Semantics(
          container: true,
          role: SemanticsRole.tabBar,
          child: Row(
            children: [
              for (var i = 0; i < widget.labels.length; i++)
                _Tab(
                  key: _keys[i],
                  label: widget.labels[i],
                  selected: i == widget.selectedIndex,
                  onTap: () => widget.onSelected(i),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final c = tokens.color;
    return Semantics(
      container: true,
      role: SemanticsRole.tab,
      selected: selected,
      child: TaroPressable(
        onTap: onTap,
        borderRadius: tokens.radius.sm,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: tokens.size.touchTarget.min,
            minWidth: tokens.size.touchTarget.min,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: selected ? c.accent.primary : Colors.transparent,
                  width: TaroStrokes.focusRing,
                ),
              ),
            ),
            child: Padding(
              padding: EdgeInsetsDirectional.symmetric(
                horizontal: tokens.space.s4,
                vertical: tokens.space.s4,
              ),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: tokens.typography.label.copyWith(
                  color: selected ? c.text.primary : c.text.secondary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
