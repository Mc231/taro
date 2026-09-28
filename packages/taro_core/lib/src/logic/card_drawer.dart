import 'package:taro_core/src/model/deck.dart';
import 'package:taro_core/src/model/draw.dart';
import 'package:taro_core/src/model/drawn_card.dart';
import 'package:taro_core/src/model/spread.dart';
import 'package:taro_core/src/ports/random_source.dart';
import 'package:taro_core/src/result/ids.dart';

/// Draws the cards of a reading (02 §4.1, 01 §7.3).
///
/// A full Fisher–Yates shuffle of the deck's 78 IDs driven by
/// [RandomSource.nextInt] (whose adapters sample without modulo bias,
/// `uniformIntBelow`); picking position *i* (in `order`) takes
/// `shuffled[i]`. Each orientation is an independent coin flip (P = 0.5)
/// when the spread allows reversals and the user enabled them (PR7);
/// otherwise no coin is flipped.
///
/// The random calls happen in a fixed order, so a scripted source yields an
/// exact, reproducible draw: 77 `nextInt` calls (`nextInt(78)` down to
/// `nextInt(2)`), then one `nextBool` per position in `order`.
final class CardDrawer {
  /// Creates a drawer over the random source `rng`.
  const CardDrawer(this._rng);

  final RandomSource _rng;

  /// Draws [spread] from [deck] at [now] (stored as UTC).
  ///
  /// Throws an [ArgumentError] if the spread has more positions than the
  /// deck has cards.
  Draw draw(
    Deck deck,
    SpreadDefinition spread, {
    required bool reversalsEnabled,
    required DateTime now,
  }) {
    final positions = spread.positionsInOrder;
    if (positions.length > deck.cards.length) {
      throw ArgumentError.value(
        positions.length,
        'spread',
        'more positions than cards in the deck',
      );
    }
    final shuffled = shuffle([for (final c in deck.cards) c.id]);
    final flip = spread.allowsReversals && reversalsEnabled;
    return Draw(
      spreadId: spread.id,
      spreadVersion: spread.version,
      cards: List.unmodifiable([
        for (var i = 0; i < positions.length; i++)
          DrawnCard(
            positionId: positions[i].id,
            cardId: shuffled[i],
            reversed: flip && _rng.nextBool(),
          ),
      ]),
      drawnAt: now.toUtc(),
    );
  }

  /// A Fisher–Yates shuffle of [ids] (a new list; [ids] is not changed).
  ///
  /// For `i` from `length - 1` down to 1 it swaps `i` with
  /// `j = rng.nextInt(i + 1)`.
  List<CardId> shuffle(List<CardId> ids) {
    final out = [...ids];
    for (var i = out.length - 1; i > 0; i--) {
      final j = _rng.nextInt(i + 1);
      if (j < 0 || j > i) {
        throw RangeError.range(j, 0, i, 'RandomSource.nextInt(${i + 1})');
      }
      final tmp = out[i];
      out[i] = out[j];
      out[j] = tmp;
    }
    return out;
  }
}
