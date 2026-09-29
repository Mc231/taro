import 'dart:async';

import 'package:taro/data/backup/journal_backup_store.dart';
import 'package:taro/data/db/journal/journal_database.dart';
import 'package:taro/data/db/journal/journal_row_mapper.dart';
import 'package:taro/data/db/journal/readings_dao.dart';
import 'package:taro_core/taro_core.dart';

/// Resolves search [text] to the IDs of cards whose localized name contains
/// it (card names are content, not journal rows; 02 §6.1, RC91).
typedef CardNameResolver = Future<Set<CardId>> Function(String text);

/// [JournalRepository] over `taro_journal.db` (01 §7.8, 02 §5, §6.1, §12).
///
/// [watchAll] merges readings and daily cards newest first; [search] uses
/// the FTS5 trigram index over questions and notes (`ReadingsDao.search`)
/// plus card names through the optional [CardNameResolver]. [snapshot] and
/// [replaceAll] run in one transaction through [JournalBackupStore], which
/// the backup import shares.
final class JournalRepositoryImpl implements JournalRepository {
  /// Creates the repository. Without [cardNames], search covers questions
  /// and notes only.
  JournalRepositoryImpl({
    required JournalDatabase journal,
    required Logger logger,
    CardNameResolver? cardNames,
  }) : _db = journal,
       _backup = JournalBackupStore(journal, logger: logger),
       _cardNames = cardNames,
       _logger = logger.child('journal');

  final JournalDatabase _db;
  final JournalBackupStore _backup;
  final CardNameResolver? _cardNames;
  final Logger _logger;

  /// A [CardNameResolver] over [content] in the app locale [locale] (read
  /// per search): a case-insensitive substring match on each card name.
  static CardNameResolver contentNames(
    ContentRepository content,
    String Function() locale,
  ) => (text) async {
    final needle = text.trim().toLowerCase();
    final deck = await content.deck();
    if (needle.isEmpty || deck is! Ok<Deck>) return const {};
    final ids = <CardId>{};
    for (final card in deck.value.cards) {
      final name = await content.cardText(card.id, locale());
      if (name case Ok(
        :final value,
      ) when value.name.toLowerCase().contains(needle)) {
        ids.add(card.id);
      }
    }
    return ids;
  };

  /// Readings and daily cards newest first, filtered by [query] and, when
  /// [cardId] is set, only readings containing that card (and the daily
  /// cards that drew it).
  @override
  Stream<List<JournalItem>> watchAll({
    JournalQuery query = const JournalQuery(),
    CardId? cardId,
  }) {
    final readings = _db.readingsDao.watchAll(
      favouritesOnly: query.favouritesOnly,
      spreadId: query.spreadId?.value,
      cardId: cardId?.value,
    );
    final withDaily = query.includeDailyCards && query.spreadId == null;
    final daily = withDaily
        ? _db.dailyCardsDao.watchAll(favouritesOnly: query.favouritesOnly)
        : Stream.value(const <DailyCardRow>[]);
    return _combine(readings, daily, (r, d) {
      final items = <JournalItem>[
        for (final row in r) JournalItem.reading(JournalRowMapper.reading(row)),
        for (final row in d)
          if (cardId == null || row.cardId == cardId.value)
            JournalItem.dailyCard(JournalRowMapper.dailyCard(row)),
      ];
      return _newestFirst(items);
    });
  }

  @override
  Future<Result<List<JournalItem>>> search(String text) => _local(() async {
    if (text.trim().isEmpty) return const <JournalItem>[];
    final hits = await _db.readingsDao.search(text);
    final readingIds = {
      for (final h in hits)
        if (h.kind == JournalSearchKind.reading) h.ref,
    };
    final dates = {
      for (final h in hits)
        if (h.kind == JournalSearchKind.daily) h.ref,
    };
    final cards = await _cardNames?.call(text) ?? const <CardId>{};
    if (cards.isNotEmpty) {
      final byCard = await _readingIdsWithCards(cards);
      readingIds.addAll(byCard);
      for (final row in await _db.dailyCardsDao.all()) {
        if (cards.contains(CardId(row.cardId))) dates.add(row.localDate);
      }
    }
    final items = <JournalItem>[
      for (final id in readingIds)
        if (await _db.readingsDao.byId(id) case final row?)
          JournalItem.reading(JournalRowMapper.reading(row)),
      for (final date in dates)
        if (await _db.dailyCardsDao.byDate(date) case final row?)
          JournalItem.dailyCard(JournalRowMapper.dailyCard(row)),
    ];
    return _newestFirst(items);
  });

  Future<Set<String>> _readingIdsWithCards(Set<CardId> cards) async {
    final c = _db.readingCards;
    final rows =
        await (_db.selectOnly(c, distinct: true)
              ..addColumns([c.readingId])
              ..where(c.cardId.isIn([for (final id in cards) id.value])))
            .get();
    return {for (final row in rows) row.read(c.readingId)!};
  }

  @override
  Future<Result<JournalSnapshot>> snapshot() => _backup.snapshot();

  @override
  Future<Result<void>> replaceAll(BackupData data) => _backup.replaceAll(data);

  @override
  Future<Result<void>> deleteAll() => _local(_db.wipe);

  static List<JournalItem> _newestFirst(List<JournalItem> items) {
    final indexed = [for (var i = 0; i < items.length; i++) (i, items[i])]
      ..sort((a, b) {
        final byTime = b.$2.createdAt.compareTo(a.$2.createdAt);
        return byTime != 0 ? byTime : a.$1.compareTo(b.$1);
      });
    return [for (final (_, item) in indexed) item];
  }

  /// Emits [combine] of the latest values of [a] and [b] once both have
  /// emitted, and on every later event of either.
  static Stream<R> _combine<A, B, R>(
    Stream<A> a,
    Stream<B> b,
    R Function(A a, B b) combine,
  ) {
    late final StreamController<R> out;
    StreamSubscription<A>? subA;
    StreamSubscription<B>? subB;
    (A,)? lastA;
    (B,)? lastB;
    var done = 0;
    void emit() {
      if (lastA case (final va,)) {
        if (lastB case (final vb,)) out.add(combine(va, vb));
      }
    }

    void close() {
      if (++done == 2) unawaited(out.close());
    }

    out = StreamController<R>(
      onListen: () {
        subA = a.listen(
          (v) {
            lastA = (v,);
            emit();
          },
          onError: out.addError,
          onDone: close,
        );
        subB = b.listen(
          (v) {
            lastB = (v,);
            emit();
          },
          onError: out.addError,
          onDone: close,
        );
      },
      onCancel: () async {
        await subA?.cancel();
        await subB?.cancel();
      },
    );
    return out.stream;
  }

  Future<Result<T>> _local<T>(Future<T> Function() body) async {
    try {
      return Result.ok(await body());
    } on Object catch (error) {
      _logger.warning('journal storage failed', error: error.runtimeType);
      return const Result.err(Failure.storage());
    }
  }
}
