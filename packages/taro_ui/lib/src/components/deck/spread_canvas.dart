import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:taro_ui/src/components/common/taro_word_fit.dart';
import 'package:taro_ui/src/components/deck/spread_layout.dart';
import 'package:taro_ui/src/components/deck/taro_card_size.dart';
import 'package:taro_ui/src/components/layout/taro_badge.dart';
import 'package:taro_ui/src/theme/taro_tokens_extension.dart';
import 'package:taro_ui/src/tokens/taro_strokes.dart';

/// Above this text scale [SpreadCanvas] reflows to a vertical list (01 §12).
const double kSpreadReflowTextScale = 1.5;

/// One slot of a [SpreadCanvas]: a position with its card, or empty.
@immutable
class SpreadCanvasSlot {
  /// Creates a slot.
  const SpreadCanvasSlot({
    required this.layout,
    required this.label,
    required this.number,
    this.card,
    this.emptySemanticsLabel,
    this.hint,
  });

  /// Where the slot sits (LTR; the canvas mirrors it in RTL).
  final SpreadSlotLayout layout;

  /// Localised position name shown under the card ("Past").
  final String label;

  /// The position number shown in an empty slot (the draw order).
  final int number;

  /// The card (`TaroCardBack`, `TaroCardFace`, `TaroCardFlip`); null is an
  /// empty slot. The canvas scales it to the slot's card size; the card
  /// carries its own semantics label (which names the position).
  final Widget? card;

  /// Localised label of the empty slot ("Position 3, Future, empty");
  /// defaults to [label].
  final String? emptySemanticsLabel;

  /// A short localised hint over the card ("Tap to reveal"). It is drawn at
  /// no less than `type.caption` and stays inside the card; a hint that
  /// cannot fit at that size is left out (V2-12). Not read by screen
  /// readers (the card's own label says what to do).
  final String? hint;
}

/// How a [SpreadCanvas] arranges its slots.
enum SpreadCanvasMode {
  /// The spread's own layout, with position labels (S08, S13, S32).
  layout,

  /// A single compact row of small cards without labels (S09/S15 header).
  compactRow,
}

/// Lays out a spread from its normalized slot layouts (02 §14.3, 01 §12).
///
/// In RTL the x of every slot is mirrored (`x → 1 - x`); the cards
/// themselves are not. Above [kSpreadReflowTextScale] the slots reflow to a
/// vertical list (card, then label) in slot order. A crossing card
/// (`rotationDeg` 90) is rotated over the card it crosses and keeps its
/// position name in semantics only. Empty slots are a dashed
/// `color.border.strong` outline with the position number.
class SpreadCanvas extends StatelessWidget {
  /// Creates the canvas. [slots] are in draw order.
  const SpreadCanvas({
    required this.slots,
    this.cardSize = TaroCardSize.sm,
    this.mode = SpreadCanvasMode.layout,
    this.semanticsLabel,
    super.key,
  });

  /// The slots in draw order.
  final List<SpreadCanvasSlot> slots;

  /// The largest card size; cards shrink to fit the width.
  final TaroCardSize cardSize;

  /// Layout or compact row.
  final SpreadCanvasMode mode;

  /// Localised label of the whole spread ("Past, Present, Future spread").
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final reflow =
        MediaQuery.textScalerOf(context).scale(1) > kSpreadReflowTextScale;
    final Widget body;
    if (mode == SpreadCanvasMode.compactRow) {
      body = _CompactRow(slots: slots);
    } else if (reflow) {
      body = _SlotList(slots: slots);
    } else {
      body = LayoutBuilder(
        builder: (context, constraints) => _SlotCanvas(
          slots: slots,
          cardSize: cardSize,
          width: constraints.maxWidth,
        ),
      );
    }
    return RepaintBoundary(
      child: Semantics(
        container: true,
        explicitChildNodes: true,
        label: semanticsLabel,
        child: body,
      ),
    );
  }
}

class _SlotCanvas extends StatelessWidget {
  const _SlotCanvas({
    required this.slots,
    required this.cardSize,
    required this.width,
  });

  final List<SpreadCanvasSlot> slots;
  final TaroCardSize cardSize;
  final double width;

  /// The most lines a position label may take under its card.
  static const int _maxLabelLines = 2;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final direction = Directionality.of(context);
    final layouts = [for (final s in slots) s.layout.resolve(direction)];
    final gap = tokens.space.s4;
    final aspect = tokens.size.card.aspectRatio;
    final nominal = cardSize.widthOf(tokens);
    final first = SpreadGeometry.compute(
      slots: layouts,
      width: width,
      cardWidth: nominal,
      aspectRatio: aspect,
      gap: gap,
    );
    final labelStyle = _labelStyle(context);
    final scaler = MediaQuery.textScalerOf(context);
    // Neighbouring labels keep at least `space.3` between them (V2-11).
    final labelWidth = first.cardSize.width + gap - tokens.space.s3;
    // A label wraps only between words: a word wider than its slot shrinks
    // (BUG-05, BUG-08), but never below `type.caption` (V2-01).
    final labelScalers = [
      for (final slot in slots)
        taroWordFitScaler(
          text: slot.label,
          style: labelStyle,
          scaler: scaler,
          maxWidth: labelWidth,
          direction: direction,
        ),
    ];
    final minSize = scaler.scale(tokens.typography.caption.fontSize!);
    final fontSize = labelStyle.fontSize!;
    // A crossing card has no label of its own, and a label that would
    // shrink below the minimum or wrap past two lines is unreadable under
    // a small card: then every slot shows its number and the names move to
    // a legend under the spread (V2-01).
    var numbered = layouts.any((l) => l.isCrossing);
    for (var i = 0; i < slots.length && !numbered; i++) {
      final fit = labelScalers[i];
      if (fit != null && fit.scale(fontSize) < minSize - 0.01) {
        numbered = true;
        break;
      }
      final painter = TextPainter(
        text: TextSpan(text: slots[i].label, style: labelStyle),
        textDirection: direction,
        textScaler: fit ?? scaler,
        textAlign: TextAlign.center,
      )..layout(maxWidth: labelWidth);
      numbered = painter.computeLineMetrics().length > _maxLabelLines;
      painter.dispose();
    }
    final labels = [
      for (var i = 0; i < slots.length; i++)
        numbered ? _numbersAt(i, layouts) : slots[i].label,
    ];
    var labelHeight = 0.0;
    for (var i = 0; i < slots.length; i++) {
      if (layouts[i].isCrossing) continue;
      final painter = TextPainter(
        text: TextSpan(text: labels[i], style: labelStyle),
        textDirection: direction,
        textScaler: numbered ? scaler : labelScalers[i] ?? scaler,
        textAlign: TextAlign.center,
      )..layout(maxWidth: labelWidth);
      labelHeight = math.max(labelHeight, painter.height);
      painter.dispose();
    }
    final labelExtent = labelHeight == 0 ? 0.0 : labelHeight + tokens.space.s3;
    final geometry = SpreadGeometry.compute(
      slots: layouts,
      width: width,
      cardWidth: nominal,
      aspectRatio: aspect,
      labelExtent: labelExtent,
      gap: gap,
    );
    final card = geometry.cardSize;
    final box = Size(card.width + gap, card.height + labelExtent);
    final canvas = SizedBox.fromSize(
      size: geometry.size,
      child: CustomMultiChildLayout(
        delegate: _SlotDelegate(geometry.centers, box),
        children: [
          for (var i = 0; i < slots.length; i++)
            LayoutId(
              id: i,
              child: Semantics(
                sortKey: OrdinalSortKey(i.toDouble()),
                child: SizedBox.fromSize(
                  size: box,
                  child: Column(
                    children: [
                      Transform.rotate(
                        angle: layouts[i].rotationDeg * math.pi / 180,
                        child: _SlotCard(
                          slot: slots[i],
                          size: card,
                          showHint: !layouts[i].isCrossing,
                        ),
                      ),
                      if (!layouts[i].isCrossing && labelExtent > 0) ...[
                        SizedBox(height: tokens.space.s3),
                        ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: labelWidth),
                          child: _SlotLabel(
                            label: labels[i],
                            style: labelStyle,
                            textScaler: numbered ? null : labelScalers[i],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
    if (!numbered) return canvas;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        canvas,
        SizedBox(height: tokens.space.s5),
        _Legend(slots: slots),
      ],
    );
  }

  /// The numbers under slot [i]: its own, then those of the crossing cards
  /// lying on it ("1 · 2").
  String _numbersAt(int i, List<SpreadSlotLayout> layouts) {
    final here = layouts[i];
    return [
      slots[i].number,
      for (var j = 0; j < slots.length; j++)
        if (j != i &&
            layouts[j].isCrossing &&
            !here.isCrossing &&
            layouts[j].x == here.x &&
            layouts[j].y == here.y)
          slots[j].number,
    ].join(' · ');
  }
}

/// The position names of a numbered [SpreadCanvas], each after its number
/// badge (V2-01). Read in the cards' own labels, so not read again here.
class _Legend extends StatelessWidget {
  const _Legend({required this.slots});

  final List<SpreadCanvasSlot> slots;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final c = tokens.color;
    final badge = tokens.size.icon.lg;
    final ordered = [...slots]..sort((a, b) => a.number.compareTo(b.number));
    return ExcludeSemantics(
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: tokens.space.s5,
        runSpacing: tokens.space.s3,
        children: [
          for (final slot in ordered)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  constraints: BoxConstraints(
                    minWidth: badge,
                    minHeight: badge,
                  ),
                  alignment: AlignmentDirectional.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: c.card.frame,
                      width: TaroStrokes.control,
                    ),
                  ),
                  child: Text(
                    '${slot.number}',
                    style: tokens.typography.caption.copyWith(
                      color: c.text.primary,
                    ),
                  ),
                ),
                SizedBox(width: tokens.space.s3),
                Flexible(
                  child: Text(slot.label, style: _labelStyle(context)),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

TextStyle _labelStyle(BuildContext context) {
  final tokens = context.tokens;
  return tokens.typography.label.copyWith(color: tokens.color.text.primary);
}

class _SlotDelegate extends MultiChildLayoutDelegate {
  _SlotDelegate(this.centers, this.box);

  final List<Offset> centers;
  final Size box;

  @override
  void performLayout(Size size) {
    for (var i = 0; i < centers.length; i++) {
      layoutChild(i, BoxConstraints.tight(box));
      final center = centers[i];
      positionChild(
        i,
        Offset(center.dx - box.width / 2, center.dy - box.height / 2),
      );
    }
  }

  @override
  bool shouldRelayout(_SlotDelegate oldDelegate) =>
      oldDelegate.box != box || !listEquals(oldDelegate.centers, centers);
}

class _SlotCard extends StatelessWidget {
  const _SlotCard({
    required this.slot,
    required this.size,
    this.showHint = false,
  });

  final SpreadCanvasSlot slot;
  final Size size;

  /// Whether [SpreadCanvasSlot.hint] is drawn over the card.
  final bool showHint;

  @override
  Widget build(BuildContext context) {
    final card = slot.card;
    if (card != null) {
      final sized = SizedBox.fromSize(
        size: size,
        child: FittedBox(child: card),
      );
      final hint = showHint ? slot.hint : null;
      final tokens = context.tokens;
      final maxWidth = size.width - tokens.space.s2;
      // Drawn over the scaled card, not inside it, so it keeps its size
      // (V2-12); it wraps between words and stays inside the card (BUG-06).
      // The Stack stays when the hint goes, so the card keeps its state (a
      // flip in progress).
      return Stack(
        alignment: AlignmentDirectional.bottomCenter,
        children: [
          sized,
          if (hint != null && _hintFits(context, hint, maxWidth))
            PositionedDirectional(
              bottom: tokens.space.s4,
              child: IgnorePointer(
                child: ExcludeSemantics(
                  child: TaroBadge(
                    label: hint,
                    maxWidth: maxWidth,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
        ],
      );
    }
    final tokens = context.tokens;
    return Semantics(
      label: slot.emptySemanticsLabel ?? slot.label,
      excludeSemantics: true,
      child: CustomPaint(
        painter: _DashedSlotPainter(
          color: tokens.color.border.strong,
          radius: tokens.radius.card,
          dash: tokens.space.s2,
        ),
        child: SizedBox.fromSize(
          size: size,
          child: Center(
            child: Text(
              '${slot.number}',
              style: tokens.typography.numeral.copyWith(
                color: tokens.color.text.tertiary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Whether [hint] fits a `TaroBadge` of [maxWidth] (the badge wraps between
/// words) at no less than `type.caption` (V2-12), and in at most three
/// lines inside the card.
bool _hintFits(BuildContext context, String hint, double maxWidth) {
  final tokens = context.tokens;
  final style = tokens.typography.caption;
  final inner = maxWidth - 2 * tokens.space.s3;
  if (inner <= 0) return false;
  final scaler = MediaQuery.textScalerOf(context);
  final direction = Directionality.of(context);
  final fit = taroWordFitScaler(
    text: hint,
    style: style,
    scaler: scaler,
    maxWidth: inner,
    direction: direction,
  );
  final size = style.fontSize!;
  if (fit != null && fit.scale(size) < size - 0.01) return false;
  final painter = TextPainter(
    text: TextSpan(text: hint, style: style),
    textDirection: direction,
    textScaler: fit ?? scaler,
  )..layout(maxWidth: inner);
  final lines = painter.computeLineMetrics().length;
  painter.dispose();
  return lines <= 3;
}

class _SlotLabel extends StatelessWidget {
  const _SlotLabel({required this.label, required this.style, this.textScaler});

  final String label;
  final TextStyle style;

  /// The shrunk scaler of a label with a word wider than its slot.
  final TextScaler? textScaler;

  @override
  Widget build(BuildContext context) {
    // A filled card names its position itself; an empty slot's label is
    // already in its outline's semantics.
    return ExcludeSemantics(
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: style,
        textScaler: textScaler,
      ),
    );
  }
}

class _SlotList extends StatelessWidget {
  const _SlotList({required this.slots});

  final List<SpreadCanvasSlot> slots;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final card = TaroCardSize.sm.sizeOf(tokens);
    final style = _labelStyle(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < slots.length; i++) ...[
          if (i > 0) SizedBox(height: tokens.space.s4),
          Row(
            children: [
              _SlotCard(slot: slots[i], size: card),
              SizedBox(width: tokens.space.s4),
              Expanded(
                child: ExcludeSemantics(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(slots[i].label, style: style),
                      // Beside the card at large text, where it has room.
                      if (slots[i].card != null && slots[i].hint != null) ...[
                        SizedBox(height: tokens.space.s2),
                        TaroBadge(label: slots[i].hint!),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _CompactRow extends StatelessWidget {
  const _CompactRow({required this.slots});

  final List<SpreadCanvasSlot> slots;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final card = TaroCardSize.thumb.sizeOf(tokens);
    return Wrap(
      spacing: tokens.space.s3,
      runSpacing: tokens.space.s3,
      children: [
        for (final slot in slots) _SlotCard(slot: slot, size: card),
      ],
    );
  }
}

class _DashedSlotPainter extends CustomPainter {
  _DashedSlotPainter({
    required this.color,
    required this.radius,
    required this.dash,
  });

  final Color color;
  final double radius;
  final double dash;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = TaroStrokes.control;
    final outline = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          (Offset.zero & size).deflate(TaroStrokes.control / 2),
          Radius.circular(radius),
        ),
      );
    for (final metric in outline.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(metric.extractPath(distance, distance + dash), paint);
        distance += dash * 2;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedSlotPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.radius != radius ||
      oldDelegate.dash != dash;
}
