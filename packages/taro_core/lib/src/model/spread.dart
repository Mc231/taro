import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taro_core/src/result/ids.dart';

part 'spread.freezed.dart';

/// The six v1 spread IDs in 01 §10.3 order (RC2).
const List<SpreadId> kSpreadIds = [
  SpreadId('single'),
  SpreadId('three_ppf'),
  SpreadId('three_sao'),
  SpreadId('relationship'),
  SpreadId('two_paths'),
  SpreadId('celtic_cross'),
];

/// One position of a spread (01 §10.2). Name and description come from ARB
/// (`spread_{spreadId}_pos_{positionId}_name` / `_desc`).
@freezed
abstract class SpreadPosition with _$SpreadPosition {
  /// Creates a position.
  const factory SpreadPosition({
    /// `past`, `challenge`, …
    required PositionId id,

    /// Draw and reveal order, 1-based.
    required int order,

    /// Normalized 0..1 horizontal layout coordinate (LTR; mirrored in RTL).
    required double x,

    /// Normalized 0..1 vertical layout coordinate.
    required double y,

    /// Card rotation in degrees, e.g. 90 for Celtic Cross `challenge`.
    @Default(0) double rotationDeg,
  }) = _SpreadPosition;
}

/// A spread (01 §10.2, 02 §4 `Spread`). There is no per-spread cost: every
/// reading costs exactly one credit (RC62).
@freezed
abstract class SpreadDefinition with _$SpreadDefinition {
  /// Creates a spread. Use [problems] to check its invariants.
  const factory SpreadDefinition({
    /// One of [kSpreadIds].
    required SpreadId id,

    /// Content version (sent as `spread.version`, 03 §9.1).
    required int version,

    /// Positions in draw order.
    required List<SpreadPosition> positions,

    /// ARB keys of the question suggestions.
    @Default(<String>[]) List<String> questionSuggestionKeys,

    /// Whether cards of this spread may be reversed.
    @Default(true) bool allowsReversals,

    /// Whether the spread is offered (`spreads.enabled`).
    @Default(true) bool enabled,
  }) = _SpreadDefinition;

  const SpreadDefinition._();

  /// The number of cards drawn.
  int get cardCount => positions.length;

  /// The positions sorted by [SpreadPosition.order].
  List<SpreadPosition> get positionsInOrder =>
      [...positions]..sort((a, b) => a.order.compareTo(b.order));

  /// Every invariant this spread breaks; empty when it is consistent.
  List<String> get problems {
    final ids = positions.map((p) => p.id).toSet();
    final orders = positions.map((p) => p.order).toSet();
    return [
      if (positions.isEmpty) '${id.value}: no positions',
      if (ids.length != positions.length) '${id.value}: duplicate position IDs',
      if (!orders.containsAll([for (var i = 1; i <= cardCount; i++) i]))
        '${id.value}: orders must be 1..$cardCount',
      for (final p in positions)
        if (p.x < 0 || p.x > 1 || p.y < 0 || p.y > 1)
          '${id.value}/${p.id.value}: layout outside 0..1',
    ];
  }

  /// The position with [id], or `null`.
  SpreadPosition? position(PositionId id) {
    for (final p in positions) {
      if (p.id == id) return p;
    }
    return null;
  }
}
