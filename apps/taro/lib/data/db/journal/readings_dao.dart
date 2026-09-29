import 'package:drift/drift.dart';
import 'package:taro/data/db/journal/journal_database.dart';

part 'readings_dao.g.dart';

/// A `readings` row with its `reading_cards` in position order.
typedef ReadingWithCards = ({ReadingRow reading, List<ReadingCardRow> cards});

/// What a journal search hit points at.
enum JournalSearchKind {
  /// A reading (`ref` = `readings.id`).
  reading,

  /// A daily card (`ref` = `daily_cards.local_date`).
  daily,
}

/// One journal search hit.
typedef JournalSearchHit = ({JournalSearchKind kind, String ref});

/// Readings, their cards and the journal search (`taro_journal.db`).
///
/// Row-level: mapping to the domain `Reading` is the repository's job
/// (Sprint 11.4). Callers set `updated_at` on every change.
@DriftAccessor(include: {'journal.drift'})
class ReadingsDao extends DatabaseAccessor<JournalDatabase>
    with _$ReadingsDaoMixin {
  /// Creates the DAO.
  ReadingsDao(super.attachedDatabase);

  /// Inserts [reading], or updates the columns [reading] sets on the
  /// existing row with the same `id`, and replaces its cards with [cards],
  /// in one transaction.
  Future<void> upsert(
    ReadingsCompanion reading,
    List<ReadingCardsCompanion> cards,
  ) => transaction(() async {
    await into(readings).insertOnConflictUpdate(reading);
    await (delete(
      readingCards,
    )..where((c) => c.readingId.equals(reading.id.value))).go();
    await batch((b) => b.insertAll(readingCards, cards));
  });

  /// Applies [changes] to the reading [id]; returns whether it exists.
  Future<bool> patch(String id, ReadingsCompanion changes) async =>
      await (update(
        readings,
      )..where((r) => r.id.equals(id))).write(changes) ==
      1;

  /// The reading [id] with its cards, or `null`.
  Future<ReadingWithCards?> byId(String id) async {
    final rows = await _joined(where: readings.id.equals(id)).get();
    final grouped = _group(rows);
    return grouped.isEmpty ? null : grouped.single;
  }

  /// Emits the reading [id] (or `null`) and every change.
  Stream<ReadingWithCards?> watchById(String id) => _joined(
    where: readings.id.equals(id),
  ).watch().map(_group).map((list) => list.isEmpty ? null : list.single);

  /// Every reading with status [status], oldest first (e.g. `pending` for
  /// resume on launch).
  Future<List<ReadingWithCards>> byStatus(String status) async => _group(
    await _joined(
      where: readings.status.equals(status),
      newestFirst: false,
    ).get(),
  );

  /// Every reading, newest first.
  Future<List<ReadingWithCards>> all() async => _group(await _joined().get());

  /// Readings newest first, filtered (01 §7.8): favourites only, one
  /// spread, or readings containing [cardId].
  Stream<List<ReadingWithCards>> watchAll({
    bool favouritesOnly = false,
    String? spreadId,
    String? cardId,
  }) {
    final filters = <Expression<bool>>[
      if (favouritesOnly) readings.favourite.equals(true),
      if (spreadId != null) readings.spreadId.equals(spreadId),
      if (cardId != null)
        readings.id.isInQuery(
          selectOnly(readingCards)
            ..addColumns([readingCards.readingId])
            ..where(readingCards.cardId.equals(cardId)),
        ),
    ];
    return _joined(
      where: filters.isEmpty ? null : Expression.and(filters),
    ).watch().map(_group);
  }

  /// Deletes the reading [id] (its cards cascade); returns whether it
  /// existed.
  Future<bool> deleteById(String id) async =>
      await (delete(readings)..where((r) => r.id.equals(id))).go() == 1;

  /// Deletes every reading and card.
  Future<void> deleteAll() => delete(readings).go();

  /// Searches questions and notes of readings and daily cards (RC91),
  /// newest first.
  ///
  /// Every whitespace-separated token must match (AND) as a case- and
  /// diacritic-insensitive substring. Tokens of three or more characters go
  /// through the FTS5 trigram index; shorter ones use `LIKE` over the same
  /// table (the trigram index cannot match them).
  Future<List<JournalSearchHit>> search(String text) async {
    final tokens = text
        .trim()
        .split(RegExp(r'\s+'))
        .where((t) => t.isNotEmpty)
        .toList();
    if (tokens.isEmpty) return const [];
    final conditions = <String>[];
    final variables = <Variable<Object>>[];
    final long = [
      for (final t in tokens)
        if (t.runes.length >= 3) '"${t.replaceAll('"', '""')}"',
    ];
    if (long.isNotEmpty) {
      conditions.add('journal_fts MATCH ?');
      variables.add(Variable.withString(long.join(' ')));
    }
    for (final t in tokens.where((t) => t.runes.length < 3)) {
      conditions.add(
        r"(journal_fts.question LIKE ? ESCAPE '\' "
        r"OR journal_fts.note LIKE ? ESCAPE '\')",
      );
      final pattern =
          '%${t.replaceAllMapped(RegExp(r'[\\%_]'), (m) => '\\${m[0]}')}%';
      variables.addAll([
        Variable.withString(pattern),
        Variable.withString(pattern),
      ]);
    }
    final rows = await customSelect(
      'SELECT r.kind AS kind, r.ref AS ref FROM journal_fts '
      'JOIN journal_search_refs r ON r.fts_rowid = journal_fts.rowid '
      "LEFT JOIN readings rd ON r.kind = 'reading' AND rd.id = r.ref "
      "LEFT JOIN daily_cards dc ON r.kind = 'daily' AND dc.local_date = r.ref "
      'WHERE ${conditions.join(' AND ')} '
      'ORDER BY COALESCE(rd.created_at, dc.created_at) DESC, r.ref DESC',
      variables: variables,
      readsFrom: {readings, dailyCards},
    ).get();
    return [
      for (final row in rows)
        (
          kind: JournalSearchKind.values.byName(row.read<String>('kind')),
          ref: row.read<String>('ref'),
        ),
    ];
  }

  JoinedSelectStatement<HasResultSet, dynamic> _joined({
    Expression<bool>? where,
    bool newestFirst = true,
  }) {
    final query = select(readings).join([
      leftOuterJoin(
        readingCards,
        readingCards.readingId.equalsExp(readings.id),
      ),
    ]);
    if (where != null) query.where(where);
    final mode = newestFirst ? OrderingMode.desc : OrderingMode.asc;
    return query..orderBy([
      OrderingTerm(expression: readings.createdAt, mode: mode),
      OrderingTerm(expression: readings.id, mode: mode),
      OrderingTerm.asc(readingCards.positionOrder),
    ]);
  }

  List<ReadingWithCards> _group(List<TypedResult> rows) {
    final result = <ReadingWithCards>[];
    for (final row in rows) {
      final reading = row.readTable(readings);
      final card = row.readTableOrNull(readingCards);
      if (result.isEmpty || result.last.reading.id != reading.id) {
        result.add((reading: reading, cards: [?card]));
      } else if (card != null) {
        result.last.cards.add(card);
      }
    }
    return result;
  }
}
