import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:taro_ui/src/components/deck/spread_layout.dart';
import 'package:taro_ui/src/theme/taro_tokens_extension.dart';
import 'package:taro_ui/src/tokens/taro_strokes.dart';

/// The two sizes of a [SpreadDiagram].
enum SpreadDiagramSize {
  /// The spread picker tile (S06): at most `size.card.md` wide.
  small,

  /// The spread guide (S18): full width, `size.card.thumb` cards and the
  /// position legend.
  large,
}

/// One row of the [SpreadDiagram] legend (large size).
@immutable
class SpreadDiagramLegendEntry {
  /// Creates an entry.
  const SpreadDiagramLegendEntry({required this.title, this.description});

  /// Localised position name ("Present").
  final String title;

  /// Localised one-line meaning ("where you stand right now").
  final String? description;
}

/// A static, non-interactive diagram of a spread's layout: numbered card
/// outlines drawn from the same [SpreadSlotLayout]s as `SpreadCanvas`
/// (`docs/design/components.md`, S06 and S18).
///
/// RTL mirrors x. The diagram is one semantics node with [semanticsLabel]
/// ("Celtic Cross layout: cards 1 to 6 form a cross…"); the [legend] rows
/// (large only) are read in order.
class SpreadDiagram extends StatelessWidget {
  /// Creates a diagram; [layout] is in position order (number = index + 1).
  const SpreadDiagram({
    required this.layout,
    required this.semanticsLabel,
    this.size = SpreadDiagramSize.small,
    this.selected = false,
    this.legend = const [],
    super.key,
  });

  /// The slot layouts in position order.
  final List<SpreadSlotLayout> layout;

  /// Localised description of the layout.
  final String semanticsLabel;

  /// Small or large.
  final SpreadDiagramSize size;

  /// Outlines in `color.accent.primary` (inside a selected tile).
  final bool selected;

  /// The legend rows, by position number (large size only).
  final List<SpreadDiagramLegendEntry> legend;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final large = size == SpreadDiagramSize.large;
    final diagram = LayoutBuilder(
      builder: (context, constraints) {
        final width = large
            ? math.min(constraints.maxWidth, tokens.layout.readingMaxWidth)
            : math.min(constraints.maxWidth, tokens.size.card.md);
        return _Diagram(
          layout: layout,
          width: width,
          cardWidth: large ? tokens.size.card.thumb : tokens.size.icon.md,
          gap: large ? tokens.space.s3 : tokens.space.s2,
          large: large,
          selected: selected,
        );
      },
    );
    final labelled = Semantics(
      container: true,
      image: true,
      label: semanticsLabel,
      excludeSemantics: true,
      child: Center(child: diagram),
    );
    if (!large || legend.isEmpty) return labelled;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        labelled,
        SizedBox(height: tokens.space.s6),
        for (var i = 0; i < legend.length; i++) ...[
          if (i > 0)
            Divider(height: tokens.space.s5, color: tokens.color.border.subtle),
          _LegendRow(number: i + 1, entry: legend[i]),
        ],
      ],
    );
  }
}

class _Diagram extends StatelessWidget {
  const _Diagram({
    required this.layout,
    required this.width,
    required this.cardWidth,
    required this.gap,
    required this.large,
    required this.selected,
  });

  final List<SpreadSlotLayout> layout;
  final double width;
  final double cardWidth;
  final double gap;
  final bool large;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final c = tokens.color;
    final direction = Directionality.of(context);
    final geometry = SpreadGeometry.compute(
      slots: [for (final l in layout) l.resolve(direction)],
      width: width,
      cardWidth: cardWidth,
      aspectRatio: tokens.size.card.aspectRatio,
      gap: gap,
    );
    final card = geometry.cardSize;
    final outline = selected ? c.accent.primary : c.card.frame;
    final numberStyle =
        (large ? tokens.typography.label : tokens.typography.caption).copyWith(
          color: selected ? c.accent.primary : c.text.tertiary,
        );
    return SizedBox.fromSize(
      size: geometry.size,
      child: CustomMultiChildLayout(
        delegate: _DiagramDelegate(geometry.centers, card),
        children: [
          for (var i = 0; i < layout.length; i++)
            LayoutId(
              id: i,
              child: Transform.rotate(
                angle: layout[i].rotationDeg * math.pi / 180,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: layout[i].isCrossing ? c.card.back : c.bg.surface,
                    borderRadius: BorderRadius.circular(tokens.radius.xs),
                    border: Border.all(
                      color: outline,
                      width: large ? TaroStrokes.control : TaroStrokes.hairline,
                    ),
                  ),
                  child: Center(
                    child: Transform.rotate(
                      angle: -layout[i].rotationDeg * math.pi / 180,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          '${i + 1}',
                          maxLines: 1,
                          style: layout[i].isCrossing
                              ? numberStyle.copyWith(color: c.card.glow)
                              : numberStyle,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DiagramDelegate extends MultiChildLayoutDelegate {
  _DiagramDelegate(this.centers, this.card);

  final List<Offset> centers;
  final Size card;

  @override
  void performLayout(Size size) {
    for (var i = 0; i < centers.length; i++) {
      layoutChild(i, BoxConstraints.tight(card));
      positionChild(
        i,
        centers[i] - Offset(card.width / 2, card.height / 2),
      );
    }
  }

  @override
  bool shouldRelayout(_DiagramDelegate oldDelegate) =>
      oldDelegate.card != card || !listEquals(oldDelegate.centers, centers);
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({required this.number, required this.entry});

  final int number;
  final SpreadDiagramLegendEntry entry;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final c = tokens.color;
    final badge = tokens.size.icon.lg;
    return MergeSemantics(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: badge,
            height: badge,
            alignment: AlignmentDirectional.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: c.card.frame,
                width: TaroStrokes.control,
              ),
            ),
            child: Text(
              '$number',
              style: tokens.typography.caption.copyWith(color: c.text.primary),
            ),
          ),
          SizedBox(width: tokens.space.s4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.title,
                  style: tokens.typography.titleSmall.copyWith(
                    color: c.text.primary,
                  ),
                ),
                if (entry.description != null)
                  Text(
                    entry.description!,
                    style: tokens.typography.body.copyWith(
                      color: c.text.secondary,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
