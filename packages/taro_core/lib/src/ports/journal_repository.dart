import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taro_core/src/model/backup.dart';
import 'package:taro_core/src/model/daily_card.dart';
import 'package:taro_core/src/model/reading.dart';
import 'package:taro_core/src/result/ids.dart';
import 'package:taro_core/src/result/result.dart';

part 'journal_repository.freezed.dart';

/// One Journal row: a reading or a daily card (01 §7.8).
@freezed
sealed class JournalItem with _$JournalItem {
  /// A reading row.
  const factory JournalItem.reading(Reading reading) = JournalReadingItem;

  /// A daily-card row.
  const factory JournalItem.dailyCard(DailyCard card) = JournalDailyCardItem;

  const JournalItem._();

  /// The sort key (newest first).
  DateTime get createdAt => switch (this) {
    JournalReadingItem(:final reading) => reading.createdAt,
    JournalDailyCardItem(:final card) => card.createdAt,
  };
}

/// Journal filters (01 §7.8).
@freezed
abstract class JournalQuery with _$JournalQuery {
  /// Creates a query; the defaults list everything.
  const factory JournalQuery({
    /// Only favourites.
    @Default(false) bool favouritesOnly,

    /// Only readings of this spread (daily cards are excluded when set).
    SpreadId? spreadId,

    /// Include daily cards.
    @Default(true) bool includeDailyCards,

    /// Only readings containing this card, and the daily cards that drew
    /// it.
    CardId? cardId,
  }) = _JournalQuery;
}

/// Every local journal row at one instant (for export, import and merge).
@freezed
abstract class JournalSnapshot with _$JournalSnapshot {
  /// Creates a snapshot.
  const factory JournalSnapshot({
    /// Every reading, whatever its status.
    required List<Reading> readings,

    /// Every daily card.
    required List<DailyCard> dailyCards,
  }) = _JournalSnapshot;
}

/// The journal database as a whole (`taro_journal.db`, 02 §5, §6.1).
abstract interface class JournalRepository {
  /// Readings and daily cards, newest first.
  Stream<List<JournalItem>> watchAll({
    JournalQuery query = const JournalQuery(),
  });

  /// Full-text search over questions, notes and card names (RC91).
  Future<Result<List<JournalItem>>> search(String text);

  /// Every reading and daily card.
  Future<Result<JournalSnapshot>> snapshot();

  /// Replaces all readings, daily cards and the settings with [data] in one
  /// transaction (backup import, 02 §12).
  Future<Result<void>> replaceAll(BackupData data);

  /// Deletes every reading, daily card and the user settings (Delete all
  /// data, RC37). Device state (`taro_device.db`) is untouched.
  Future<Result<void>> deleteAll();
}
