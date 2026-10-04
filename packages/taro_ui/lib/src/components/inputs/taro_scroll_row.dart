import 'package:flutter/material.dart';
import 'package:taro_ui/src/components/common/taro_edge_fade.dart';

/// A horizontally scrolling row (filter chips, S14 and S16) whose edges
/// fade while content sits past them, like the S29 tab strip (BUG-10,
/// V2-05). The fades follow the scroll position and the text direction.
class TaroScrollRow extends StatefulWidget {
  /// Creates the row.
  const TaroScrollRow({
    required this.children,
    this.spacing = 0,
    this.padding,
    super.key,
  });

  /// The row items.
  final List<Widget> children;

  /// The gap between items.
  final double spacing;

  /// Padding inside the scroll view.
  final EdgeInsetsGeometry? padding;

  @override
  State<TaroScrollRow> createState() => _TaroScrollRowState();
}

class _TaroScrollRowState extends State<TaroScrollRow> {
  bool _start = false;
  bool _end = false;

  /// Fades the side(s) with content past them; scroll offsets run from the
  /// leading edge in both directions.
  bool _fade(ScrollMetrics m) {
    final start = m.pixels > m.minScrollExtent;
    final end = m.pixels < m.maxScrollExtent;
    if (start != _start || end != _end) {
      setState(() {
        _start = start;
        _end = end;
      });
    }
    return false;
  }

  @override
  Widget build(BuildContext context) =>
      NotificationListener<ScrollMetricsNotification>(
        onNotification: (n) => _fade(n.metrics),
        child: NotificationListener<ScrollNotification>(
          onNotification: (n) => _fade(n.metrics),
          child: TaroEdgeFade(
            start: _start,
            end: _end,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: widget.padding,
              child: Row(spacing: widget.spacing, children: widget.children),
            ),
          ),
        ),
      );
}
