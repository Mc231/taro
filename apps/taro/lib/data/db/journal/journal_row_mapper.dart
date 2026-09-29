import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:taro/data/db/journal/journal_database.dart';
import 'package:taro/data/db/journal/readings_dao.dart';
import 'package:taro_core/taro_core.dart';

/// Maps `taro_journal.db` rows to domain types and back (02 AR6, §6.1).
///
/// The mapping is lossless: `mapper.reading(row)` written back with
/// [readingRow] and [cardRows] gives the same row. JSON columns hold
/// `ReadingContent.toJson()` (`content_json`), `SafetyInfo.toJson()`
/// (`safety_json`) and `{code, refunded}` (`failure_json`). A malformed row
/// throws a [FormatException].
///
/// `settings` stores one row per [UserSettings] field ([SettingsKeys]); a
/// missing key reads as the default.
abstract final class JournalRowMapper {
  /// The domain reading of [row].
  static Reading reading(ReadingWithCards row) {
    final r = row.reading;
    return Reading(
      id: ReadingId(r.id),
      createdAt: r.createdAt,
      updatedAt: r.updatedAt,
      localDate: r.localDate,
      draw: Draw(
        spreadId: SpreadId(r.spreadId),
        spreadVersion: r.spreadVersion,
        cards: [
          for (final c in row.cards)
            DrawnCard(
              positionId: PositionId(c.positionId),
              cardId: CardId.parse(c.cardId),
              reversed: c.reversed,
            ),
        ],
        drawnAt: r.drawnAt,
      ),
      status: _status(r),
      contentLocale: r.contentLocale,
      question: r.question,
      content: r.contentJson == null
          ? null
          : ReadingContent.fromJson(_object(r.contentJson!)),
      promptVersion: r.promptVersion,
      modelId: r.modelId,
      chargeSource: r.chargeSource == null
          ? null
          : _byName(ChargeSource.values, r.chargeSource!, 'charge_source'),
      note: r.note,
      favourite: r.favourite,
      rating: r.rating == null
          ? null
          : _byName(Rating.values, r.rating!, 'rating'),
      ratingReason: r.ratingReason == null
          ? null
          : RatingReason.fromWire(r.ratingReason!) ??
                (throw FormatException(
                  'unknown rating_reason',
                  r.ratingReason,
                )),
      deliveryAcked: r.deliveryAcked,
      reported: r.reported,
    );
  }

  /// The `readings` row of [reading] (every column set).
  static ReadingsCompanion readingRow(Reading reading) =>
      ReadingsCompanion.insert(
        id: reading.id.value,
        spreadId: reading.spreadId.value,
        spreadVersion: reading.draw.spreadVersion,
        localDate: reading.localDate,
        question: Value(reading.question),
        status: reading.status.wire,
        contentJson: Value(
          reading.content == null
              ? null
              : jsonEncode(reading.content!.toJson()),
        ),
        safetyJson: Value(switch (reading.status) {
          ReadingStatusRefused(:final safety?) => jsonEncode(safety.toJson()),
          _ => null,
        }),
        failureJson: Value(switch (reading.status) {
          ReadingStatusFailed(:final failure, :final refunded) => jsonEncode({
            'code': failure.code,
            'refunded': refunded,
          }),
          _ => null,
        }),
        contentLocale: reading.contentLocale,
        promptVersion: Value(reading.promptVersion),
        modelId: Value(reading.modelId),
        chargeSource: Value(reading.chargeSource?.name),
        note: Value(reading.note),
        favourite: Value(reading.favourite),
        rating: Value(reading.rating?.name),
        ratingReason: Value(reading.ratingReason?.wire),
        deliveryAcked: Value(reading.deliveryAcked),
        reported: Value(reading.reported),
        drawnAt: reading.draw.drawnAt,
        createdAt: reading.createdAt,
        updatedAt: reading.updatedAt,
      );

  /// The `reading_cards` rows of [reading], in position order.
  static List<ReadingCardsCompanion> cardRows(Reading reading) => [
    for (var i = 0; i < reading.cards.length; i++)
      ReadingCardsCompanion.insert(
        readingId: reading.id.value,
        positionId: reading.cards[i].positionId.value,
        positionOrder: i,
        cardId: reading.cards[i].cardId.value,
        reversed: reading.cards[i].reversed,
      ),
  ];

  /// The domain daily card of [row].
  static DailyCard dailyCard(DailyCardRow row) => DailyCard(
    localDate: row.localDate,
    cardId: CardId.parse(row.cardId),
    reversed: row.reversed,
    drawnAt: row.drawnAt,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
    note: row.note,
    favourite: row.favourite,
  );

  /// The `daily_cards` row of [card] (every column set).
  static DailyCardsCompanion dailyCardRow(DailyCard card) =>
      DailyCardsCompanion.insert(
        localDate: card.localDate,
        cardId: card.cardId.value,
        reversed: card.reversed,
        drawnAt: card.drawnAt,
        note: Value(card.note),
        favourite: Value(card.favourite),
        createdAt: card.createdAt,
        updatedAt: card.updatedAt,
      );

  /// The settings stored as [rows] (key → JSON). A missing or invalid key
  /// reads as its default and unknown keys are ignored, as in
  /// `SettingsRepositoryImpl`, so an export carries what the app shows.
  static UserSettings settings(Map<String, String> rows) {
    var json = const UserSettings().toBackupJson();
    bool? reduceMotion;
    for (final MapEntry(:key, :value) in rows.entries) {
      try {
        final decoded = jsonDecode(value);
        if (key == SettingsKeys.reduceMotion) {
          if (decoded is bool?) reduceMotion = decoded;
          continue;
        }
        if (!json.containsKey(key)) continue;
        final candidate = {...json, key: decoded};
        UserSettings.fromBackupJson(candidate);
        json = candidate;
      } on FormatException {
        continue;
      }
    }
    return UserSettings.fromBackupJson(json, reduceMotion: reduceMotion);
  }

  /// The `settings` rows (key → JSON) of [settings]; every key is written.
  static Map<String, String> settingsRows(UserSettings settings) => {
    SettingsKeys.theme: jsonEncode(settings.themeMode.name),
    SettingsKeys.localeOverride: jsonEncode(settings.localeOverride),
    SettingsKeys.reversalsEnabled: jsonEncode(settings.reversalsEnabled),
    SettingsKeys.hapticsEnabled: jsonEncode(settings.hapticsEnabled),
    SettingsKeys.reminder: jsonEncode(settings.reminder.toJson()),
    SettingsKeys.reduceMotion: jsonEncode(settings.reduceMotion),
  };

  static ReadingStatus _status(ReadingRow r) => switch (r.status) {
    'pending' => const ReadingStatus.pending(),
    'complete' => const ReadingStatus.complete(),
    'classic' => const ReadingStatus.classic(),
    'refused' => ReadingStatus.refused(
      safety: r.safetyJson == null
          ? null
          : SafetyInfo.fromJson(_object(r.safetyJson!)),
    ),
    'failed' => _failed(r.failureJson),
    _ => throw FormatException('unknown reading status', r.status),
  };

  static ReadingStatus _failed(String? json) {
    final failure = json == null ? const <String, Object?>{} : _object(json);
    final code = failure['code'];
    final refunded = failure['refunded'] ?? false;
    if (code is! String || refunded is! bool) {
      throw FormatException('malformed failure_json', json);
    }
    return ReadingStatus.failed(failureOfCode(code), refunded: refunded);
  }

  /// The [Failure] stored as [code] in `failure_json`, such that
  /// `failureOfCode(f.code).code == f.code` for every failure.
  ///
  /// Codes of failures without parameters map to their own type; any other
  /// code keeps its value as a `ContractFailure`.
  static Failure failureOfCode(String code) => switch (code) {
    'NETWORK' => const Failure.network(),
    'TIMEOUT' => const Failure.timeout(),
    'UNAUTHENTICATED' => const Failure.sessionExpired(),
    'HOLD_CONFLICT' => const Failure.holdConflict(),
    'READING_EXPIRED_REFUNDED' => const Failure.readingExpiredRefunded(),
    'AI_CONSENT_REQUIRED' => const Failure.aiConsentRequired(),
    'AI_UNAVAILABLE_REGION' => const Failure.aiUnavailableRegion(),
    'AI_UNAVAILABLE' => const Failure.aiUnavailable(),
    'REQUEST_IN_PROGRESS' => const Failure.requestInProgress(),
    'STORAGE' => const Failure.storage(),
    _ => Failure.contract(wireCode: code),
  };

  static Map<String, Object?> _object(String json) {
    final value = jsonDecode(json);
    if (value is Map<String, Object?>) return value;
    throw FormatException('expected a JSON object', json);
  }

  static T _byName<T extends Enum>(List<T> values, String name, String what) =>
      values.asNameMap()[name] ??
      (throw FormatException('unknown $what', name));
}

/// Keys of the `settings` table (one [UserSettings] field each; values are
/// JSON). `reduceMotion` is device-only and never exported.
abstract final class SettingsKeys {
  /// `ThemeMode` name.
  static const theme = 'theme';

  /// Locale code or `null`.
  static const localeOverride = 'localeOverride';

  /// `bool`.
  static const reversalsEnabled = 'reversalsEnabled';

  /// `bool`.
  static const hapticsEnabled = 'hapticsEnabled';

  /// `{enabled, time}`.
  static const reminder = 'reminder';

  /// `bool` or `null` (follow the OS).
  static const reduceMotion = 'reduceMotion';
}
