import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taro_core/src/model/drawn_card.dart';
import 'package:taro_core/src/result/ids.dart';

part 'draw.freezed.dart';

/// The cards drawn for one reading; produced by `CardDrawer` and immutable
/// once created (02 §4).
@freezed
abstract class Draw with _$Draw {
  /// Creates a draw.
  const factory Draw({
    /// The spread.
    required SpreadId spreadId,

    /// The spread content version.
    required int spreadVersion,

    /// One card per position, in position order.
    required List<DrawnCard> cards,

    /// When the cards were drawn (UTC).
    required DateTime drawnAt,
  }) = _Draw;

  const Draw._();

  /// The card IDs in position order.
  List<CardId> get cardIds => [for (final c in cards) c.cardId];

  /// The card in [positionId], or `null`.
  DrawnCard? at(PositionId positionId) {
    for (final c in cards) {
      if (c.positionId == positionId) return c;
    }
    return null;
  }

  /// Whether no card appears twice.
  bool get hasUniqueCards => cardIds.toSet().length == cards.length;
}
