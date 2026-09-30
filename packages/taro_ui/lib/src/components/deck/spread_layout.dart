import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// One position of a spread layout: the `taro_ui` mirror of the core
/// `PositionLayout` (02 §5, 01 §10.2). `x` and `y` are normalized 0..1 in
/// LTR; [rotationDeg] turns the card (90 for the Celtic Cross challenge).
@immutable
class SpreadSlotLayout {
  /// Creates a slot layout.
  const SpreadSlotLayout({
    required this.x,
    required this.y,
    this.rotationDeg = 0,
  }) : assert(x >= 0 && x <= 1, 'x is normalized'),
       assert(y >= 0 && y <= 1, 'y is normalized');

  /// Horizontal position, 0 = start edge in LTR.
  final double x;

  /// Vertical position, 0 = top.
  final double y;

  /// Clockwise card rotation in degrees.
  final double rotationDeg;

  /// Whether the card lies across (a quarter turn).
  bool get isCrossing => (rotationDeg.abs() % 180 - 90).abs() < 1;

  /// This layout with `x` mirrored for [direction] (`x → 1 - x` in RTL,
  /// 02 §11). The card art itself is never mirrored.
  SpreadSlotLayout resolve(TextDirection direction) =>
      direction == TextDirection.rtl
      ? SpreadSlotLayout(x: 1 - x, y: y, rotationDeg: rotationDeg)
      : this;

  @override
  bool operator ==(Object other) =>
      other is SpreadSlotLayout &&
      other.x == x &&
      other.y == y &&
      other.rotationDeg == rotationDeg;

  @override
  int get hashCode => Object.hash(x, y, rotationDeg);

  @override
  String toString() => 'SpreadSlotLayout($x, $y, $rotationDeg°)';
}

/// The laid-out geometry of a spread: where each slot's box goes.
@immutable
class SpreadGeometry {
  /// Creates a geometry.
  const SpreadGeometry({
    required this.size,
    required this.cardSize,
    required this.centers,
  });

  /// Computes the geometry of [slots] in [width].
  ///
  /// Each slot is a box of the card plus [labelExtent] below it. The card
  /// starts at [cardWidth] (height from [aspectRatio], width ÷ height) and
  /// shrinks until cards on the same row fit side by side with [gap]. The
  /// height grows until cards that share a column no longer overlap; cards
  /// on the same point (a crossing card) overlap on purpose. [slots] must
  /// already be resolved for the text direction.
  factory SpreadGeometry.compute({
    required List<SpreadSlotLayout> slots,
    required double width,
    required double cardWidth,
    required double aspectRatio,
    double labelExtent = 0,
    double gap = 0,
  }) {
    const epsilon = 0.01;
    var w = math.min(cardWidth, width);
    for (var i = 0; i < slots.length; i++) {
      for (var j = i + 1; j < slots.length; j++) {
        final dx = (slots[i].x - slots[j].x).abs();
        final dy = (slots[i].y - slots[j].y).abs();
        if (dx > epsilon && dy < epsilon) {
          // centres dx·(width − w) apart must be ≥ w + gap.
          w = math.min(w, (dx * width - gap) / (1 + dx));
        }
      }
    }
    final card = Size(w, w / aspectRatio);
    final slotHeight = card.height + labelExtent;
    var range = 0.0;
    final usable = width - w;
    for (var i = 0; i < slots.length; i++) {
      for (var j = i + 1; j < slots.length; j++) {
        final dx = (slots[i].x - slots[j].x).abs() * usable;
        final dy = (slots[i].y - slots[j].y).abs();
        if (dy > epsilon && dx < w + gap) {
          range = math.max(range, (slotHeight + gap) / dy);
        }
      }
    }
    final ys = slots.map((s) => s.y);
    final minY = ys.isEmpty ? 0.0 : ys.reduce(math.min);
    final maxY = ys.isEmpty ? 0.0 : ys.reduce(math.max);
    final centers = [
      for (final slot in slots)
        Offset(
          w / 2 + slot.x * usable,
          slotHeight / 2 + (slot.y - minY) * range,
        ),
    ];
    return SpreadGeometry(
      size: Size(width, slotHeight + (maxY - minY) * range),
      cardSize: card,
      centers: centers,
    );
  }

  /// The canvas size.
  final Size size;

  /// The card size of every slot.
  final Size cardSize;

  /// The centre of each slot box (card + label), in slot order.
  final List<Offset> centers;
}
