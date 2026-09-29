import 'package:drift/drift.dart';
import 'package:taro/data/db/journal/journal_database.dart';

part 'daily_cards_dao.g.dart';

/// Daily cards (`taro_journal.db`, 01 §7.6): one per local date.
@DriftAccessor(include: {'journal.drift'})
class DailyCardsDao extends DatabaseAccessor<JournalDatabase>
    with _$DailyCardsDaoMixin {
  /// Creates the DAO.
  DailyCardsDao(super.attachedDatabase);

  /// Stores [card] unless its date already has a card, and returns the
  /// card of that date: drawing twice on one day is idempotent.
  Future<DailyCardRow> insertIfAbsent(DailyCardsCompanion card) =>
      transaction(() async {
        await into(dailyCards).insert(card, onConflict: DoNothing());
        return (await byDate(card.localDate.value))!;
      });

  /// Inserts [card] or replaces every column of the card of its date
  /// (backup import and merge).
  Future<void> upsert(DailyCardsCompanion card) =>
      into(dailyCards).insertOnConflictUpdate(card);

  /// Applies [changes] to the card of [localDate]; returns whether it
  /// exists.
  Future<bool> patch(String localDate, DailyCardsCompanion changes) async =>
      await (update(
        dailyCards,
      )..where((c) => c.localDate.equals(localDate))).write(changes) ==
      1;

  /// The card of [localDate], or `null`.
  Future<DailyCardRow?> byDate(String localDate) => (select(
    dailyCards,
  )..where((c) => c.localDate.equals(localDate))).getSingleOrNull();

  /// Emits the card of [localDate] (or `null`) and every change.
  Stream<DailyCardRow?> watchByDate(String localDate) => (select(
    dailyCards,
  )..where((c) => c.localDate.equals(localDate))).watchSingleOrNull();

  /// Every daily card, newest date first.
  Future<List<DailyCardRow>> all() => _newestFirst().get();

  /// Daily cards newest date first; only favourites when [favouritesOnly].
  Stream<List<DailyCardRow>> watchAll({bool favouritesOnly = false}) {
    final query = _newestFirst();
    if (favouritesOnly) query.where((c) => c.favourite.equals(true));
    return query.watch();
  }

  /// Deletes the card of [localDate]; returns whether it existed.
  Future<bool> deleteByDate(String localDate) async =>
      await (delete(
        dailyCards,
      )..where((c) => c.localDate.equals(localDate))).go() ==
      1;

  /// Deletes every daily card.
  Future<void> deleteAll() => delete(dailyCards).go();

  SimpleSelectStatement<DailyCards, DailyCardRow> _newestFirst() =>
      select(dailyCards)..orderBy([(c) => OrderingTerm.desc(c.localDate)]);
}
