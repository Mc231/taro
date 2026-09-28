import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taro_core/src/model/json.dart';
import 'package:taro_core/src/result/ids.dart';

part 'daily_card.freezed.dart';

/// The card of the day (01 §7.6, §10.4); local only, keyed by [localDate].
@freezed
abstract class DailyCard with _$DailyCard {
  /// Creates a daily card.
  const factory DailyCard({
    /// Local calendar date `YYYY-MM-DD` (primary key).
    required String localDate,

    /// The card.
    required CardId cardId,

    /// Whether the card is reversed.
    required bool reversed,

    /// When the card was drawn (UTC).
    required DateTime drawnAt,

    /// Row creation time (UTC; backup `createdAt`, RC70).
    required DateTime createdAt,

    /// Last change (UTC); the newer one wins a backup merge.
    required DateTime updatedAt,

    /// The user's note.
    String? note,

    /// Favourite flag.
    @Default(false) bool favourite,
  }) = _DailyCard;

  const DailyCard._();

  /// Parses a backup `dailyCard`; throws a [FormatException].
  factory DailyCard.fromBackupJson(Map<String, Object?> json) {
    final raw = req<String>(json, 'cardId');
    return DailyCard(
      localDate: reqLocalDate(json, 'localDate'),
      cardId:
          CardId.tryParse(raw) ??
          (throw FormatException('"cardId" is not an RC1 card ID', raw)),
      reversed: req<bool>(json, 'reversed'),
      drawnAt: reqInstant(json, 'drawnAt'),
      createdAt: reqInstant(json, 'createdAt'),
      updatedAt: reqInstant(json, 'updatedAt'),
      note: opt<String>(json, 'note'),
      favourite: req<bool>(json, 'favourite'),
    );
  }

  /// The backup JSON (`backup_schema_v1.json` `dailyCard`).
  Map<String, Object?> toBackupJson() => {
    'localDate': localDate,
    'cardId': cardId.value,
    'reversed': reversed,
    'drawnAt': formatInstant(drawnAt),
    'createdAt': formatInstant(createdAt),
    'updatedAt': formatInstant(updatedAt),
    'note': note,
    'favourite': favourite,
  };
}
