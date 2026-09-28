import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taro_core/src/model/json.dart';
import 'package:taro_core/src/result/ids.dart';

part 'drawn_card.freezed.dart';

/// A card placed in a position; the wire `cards[]` shape (03 §9.1).
@Freezed(fromJson: false, toJson: false)
abstract class DrawnCard with _$DrawnCard {
  /// Creates a drawn card.
  const factory DrawnCard({
    /// The spread position.
    required PositionId positionId,

    /// The card.
    required CardId cardId,

    /// Whether the card is reversed.
    required bool reversed,
  }) = _DrawnCard;

  const DrawnCard._();

  /// Parses `{positionId, cardId, reversed}`; throws a [FormatException].
  factory DrawnCard.fromJson(Map<String, Object?> json) {
    final raw = req<String>(json, 'cardId');
    final cardId =
        CardId.tryParse(raw) ??
        (throw FormatException('"cardId" is not an RC1 card ID', raw));
    return DrawnCard(
      positionId: PositionId(req<String>(json, 'positionId')),
      cardId: cardId,
      reversed: req<bool>(json, 'reversed'),
    );
  }

  /// The wire / backup JSON.
  Map<String, Object?> toJson() => {
    'positionId': positionId.value,
    'cardId': cardId.value,
    'reversed': reversed,
  };
}
