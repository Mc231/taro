import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taro/data/db/journal/journal_database.dart';
import 'package:taro/data/db/journal/readings_dao.dart';

import 'db_fixtures.dart';

void main() {
  late JournalDatabase db;

  setUp(() => db = memoryJournal());
  tearDown(() => db.close());

  group('ReadingsDao', () {
    test('upsert + byId round-trips every column and orders cards', () async {
      final row = readingRow('r1', question: 'Will it rain?', note: 'n')
          .copyWith(
            contentJson: const Value('{"title":"T"}'),
            safetyJson: const Value('{"category":"other"}'),
            failureJson: const Value('{"code":"TIMEOUT","refunded":true}'),
            promptVersion: const Value('p1'),
            modelId: const Value('m1'),
            chargeSource: const Value('free'),
            rating: const Value('down'),
            ratingReason: const Value('too_generic'),
            deliveryAcked: const Value(true),
            reported: const Value(true),
          );
      await db.readingsDao.upsert(row, threeCards('r1'));

      final stored = (await db.readingsDao.byId('r1'))!;
      final r = stored.reading;
      expect(r.id, 'r1');
      expect(r.spreadId, 'three_ppf');
      expect(r.spreadVersion, 1);
      expect(r.localDate, '2026-09-26');
      expect(r.question, 'Will it rain?');
      expect(r.status, 'complete');
      expect(r.contentJson, '{"title":"T"}');
      expect(r.safetyJson, '{"category":"other"}');
      expect(r.failureJson, '{"code":"TIMEOUT","refunded":true}');
      expect(r.contentLocale, 'en');
      expect(r.promptVersion, 'p1');
      expect(r.modelId, 'm1');
      expect(r.chargeSource, 'free');
      expect(r.note, 'n');
      expect(r.favourite, isFalse);
      expect(r.rating, 'down');
      expect(r.ratingReason, 'too_generic');
      expect(r.deliveryAcked, isTrue);
      expect(r.reported, isTrue);
      expect(r.drawnAt, at(0));
      expect(r.createdAt, at(0));
      expect(r.updatedAt, at(0));
      expect(r.createdAt.isUtc, isTrue);
      expect(
        [for (final c in stored.cards) c.positionId],
        [
          'past',
          'present',
          'future',
        ],
      );
      expect(stored.cards[1].reversed, isTrue);
      expect(stored.cards[1].cardId, 'cups_03');
    });

    test('byId is null for an unknown reading', () async {
      expect(await db.readingsDao.byId('nope'), isNull);
    });

    test('a second upsert updates the row and replaces the cards', () async {
      await db.readingsDao.upsert(
        readingRow('r1', status: 'pending'),
        threeCards('r1'),
      );
      await db.readingsDao.upsert(
        readingRow('r1', minute: 5, note: 'later'),
        threeCards('r1', first: 'major_21'),
      );
      final stored = (await db.readingsDao.byId('r1'))!;
      expect(stored.reading.status, 'complete');
      expect(stored.reading.note, 'later');
      expect(stored.cards, hasLength(3));
      expect(stored.cards.first.cardId, 'major_21');
    });

    test('a reading without cards reads back with an empty list', () async {
      await db.readingsDao.upsert(readingRow('r1'), const []);
      expect((await db.readingsDao.byId('r1'))!.cards, isEmpty);
    });

    test('patch changes only the given columns', () async {
      await db.readingsDao.upsert(readingRow('r1'), threeCards('r1'));
      final patched = await db.readingsDao.patch(
        'r1',
        ReadingsCompanion(
          favourite: const Value(true),
          note: const Value('mine'),
          updatedAt: Value(at(9)),
        ),
      );
      expect(patched, isTrue);
      final r = (await db.readingsDao.byId('r1'))!.reading;
      expect(r.favourite, isTrue);
      expect(r.note, 'mine');
      expect(r.updatedAt, at(9));
      expect(r.createdAt, at(0));
      expect(
        await db.readingsDao.patch(
          'nope',
          const ReadingsCompanion(favourite: Value(true)),
        ),
        isFalse,
      );
    });

    test('all() is newest first; byStatus() oldest first', () async {
      await db.readingsDao.upsert(readingRow('a', minute: 1), threeCards('a'));
      await db.readingsDao.upsert(
        readingRow('b', minute: 3, status: 'pending'),
        threeCards('b'),
      );
      await db.readingsDao.upsert(
        readingRow('c', minute: 2, status: 'pending'),
        threeCards('c'),
      );
      expect(
        [for (final r in await db.readingsDao.all()) r.reading.id],
        [
          'b',
          'c',
          'a',
        ],
      );
      expect(
        [
          for (final r in await db.readingsDao.byStatus('pending'))
            r.reading.id,
        ],
        ['c', 'b'],
      );
    });

    test('watchAll filters by favourite, spread and card', () async {
      await db.readingsDao.upsert(
        readingRow('a', minute: 1, favourite: true),
        threeCards('a'),
      );
      await db.readingsDao.upsert(
        readingRow('b', minute: 2, spreadId: 'single'),
        [
          ReadingCardsCompanion.insert(
            readingId: 'b',
            positionId: 'focus',
            positionOrder: 0,
            cardId: 'major_21',
            reversed: false,
          ),
        ],
      );
      Future<List<String>> ids(Stream<List<ReadingWithCards>> s) async => [
        for (final r in await s.first) r.reading.id,
      ];
      expect(await ids(db.readingsDao.watchAll()), ['b', 'a']);
      expect(await ids(db.readingsDao.watchAll(favouritesOnly: true)), ['a']);
      expect(await ids(db.readingsDao.watchAll(spreadId: 'single')), ['b']);
      expect(await ids(db.readingsDao.watchAll(cardId: 'cups_03')), ['a']);
      expect(
        await ids(
          db.readingsDao.watchAll(favouritesOnly: true, cardId: 'major_21'),
        ),
        isEmpty,
      );
    });

    test('watchById emits null, the row, and each change', () async {
      final seen = <String?>[];
      final sub = db.readingsDao
          .watchById('r1')
          .listen((r) => seen.add(r?.reading.note));
      await pumpEventQueue();
      await db.readingsDao.upsert(
        readingRow('r1', note: 'one'),
        threeCards('r1'),
      );
      await pumpEventQueue();
      await db.readingsDao.patch(
        'r1',
        const ReadingsCompanion(note: Value('two')),
      );
      await pumpEventQueue();
      await sub.cancel();
      expect(seen, [null, 'one', 'two']);
    });

    test('deleting a reading cascades to its cards', () async {
      await db.readingsDao.upsert(readingRow('r1'), threeCards('r1'));
      await db.readingsDao.upsert(readingRow('r2'), threeCards('r2'));
      expect(await db.readingsDao.deleteById('r1'), isTrue);
      expect(await db.readingsDao.deleteById('r1'), isFalse);
      final cards = await db.select(db.readingCards).get();
      expect({for (final c in cards) c.readingId}, {'r2'});
    });

    test('cards cannot reference a missing reading (foreign keys on)', () {
      expect(
        db.into(db.readingCards).insert(threeCards('ghost').first),
        throwsA(isA<SqliteException>()),
      );
    });

    test('the status and rating CHECKs reject unknown values', () async {
      await expectLater(
        db.readingsDao.upsert(readingRow('r1', status: 'done'), const []),
        throwsA(isA<SqliteException>()),
      );
      await expectLater(
        db.readingsDao.upsert(
          readingRow('r2').copyWith(rating: const Value('meh')),
          const [],
        ),
        throwsA(isA<SqliteException>()),
      );
    });

    test('deleteAll removes readings and cards', () async {
      await db.readingsDao.upsert(readingRow('r1'), threeCards('r1'));
      await db.readingsDao.deleteAll();
      expect(await db.readingsDao.all(), isEmpty);
      expect(await db.select(db.readingCards).get(), isEmpty);
    });
  });

  group('journal search (FTS5 trigram, RC91)', () {
    Future<List<String>> refs(String text) async => [
      for (final hit in await db.readingsDao.search(text))
        '${hit.kind.name}:${hit.ref}',
    ];

    setUp(() async {
      await db.readingsDao.upsert(
        readingRow(
          'r1',
          minute: 1,
          question: 'Will the new Moon bring clarity?',
        ),
        threeCards('r1'),
      );
      await db.readingsDao.upsert(
        readingRow('r2', minute: 3, question: 'Career path', note: 'Café talk'),
        threeCards('r2'),
      );
      await db.readingsDao.upsert(
        readingRow('r3', minute: 4, question: 'Чи буде дощ?', note: '月の光'),
        threeCards('r3'),
      );
      await db.dailyCardsDao.upsert(
        dailyCardRow('2026-09-25', minute: 2, note: 'moonlit walk'),
      );
    });

    test('matches substrings case-insensitively, newest first', () async {
      expect(await refs('MOON'), ['daily:2026-09-25', 'reading:r1']);
    });

    test('ignores diacritics', () async {
      expect(await refs('cafe'), ['reading:r2']);
    });

    test('works for Cyrillic and Japanese', () async {
      expect(await refs('ДОЩ'), ['reading:r3']);
      expect(await refs('月の光'), ['reading:r3']);
    });

    test('every token must match', () async {
      expect(await refs('moon clarity'), ['reading:r1']);
      expect(await refs('moon career'), isEmpty);
    });

    test('short tokens use LIKE and combine with long ones', () async {
      expect(await refs('CA'), ['reading:r2']);
      expect(await refs('mo'), ['daily:2026-09-25', 'reading:r1']);
      expect(await refs('月'), ['reading:r3']);
      expect(await refs('path ca'), ['reading:r2']);
    });

    test('LIKE wildcards and FTS syntax are taken literally', () async {
      expect(await refs('%'), isEmpty);
      expect(await refs('_'), isEmpty);
      expect(await refs(r'\'), isEmpty);
      expect(await refs('"moon'), isEmpty);
      expect(await refs('moon OR x'), isEmpty);
    });

    test('blank text finds nothing', () async {
      expect(await refs('  '), isEmpty);
    });

    test('the index follows updates and deletes', () async {
      await db.readingsDao.patch(
        'r2',
        const ReadingsCompanion(note: Value('sunrise')),
      );
      expect(await refs('cafe'), isEmpty);
      expect(await refs('sunrise'), ['reading:r2']);

      await db.dailyCardsDao.patch(
        '2026-09-25',
        const DailyCardsCompanion(note: Value('stars')),
      );
      expect(await refs('moonlit'), isEmpty);
      expect(await refs('stars'), ['daily:2026-09-25']);

      await db.readingsDao.deleteById('r1');
      await db.dailyCardsDao.deleteByDate('2026-09-25');
      expect(await refs('moon'), isEmpty);
      expect(await refs('stars'), isEmpty);
      final leftovers = await db
          .customSelect(
            'SELECT COUNT(*) AS n FROM journal_search_refs',
          )
          .getSingle();
      expect(leftovers.read<int>('n'), 2);
    });

    test('an upsert of an existing reading updates the index', () async {
      await db.readingsDao.upsert(
        readingRow('r1', minute: 1, question: 'Sun'),
        threeCards('r1'),
      );
      expect(await refs('moon'), ['daily:2026-09-25']);
    });

    test('wipe() empties the journal and the index', () async {
      await db.settingsDao.write('theme', '"dark"');
      await db.wipe();
      expect(await db.readingsDao.all(), isEmpty);
      expect(await db.dailyCardsDao.all(), isEmpty);
      expect(await db.settingsDao.readAll(), isEmpty);
      expect(await refs('moon'), isEmpty);
      final n = await db
          .customSelect(
            'SELECT (SELECT COUNT(*) FROM journal_fts) + '
            '(SELECT COUNT(*) FROM journal_search_refs) AS n',
          )
          .getSingle();
      expect(n.read<int>('n'), 0);
    });
  });

  group('DailyCardsDao', () {
    test('insertIfAbsent keeps the first card of a day', () async {
      final first = await db.dailyCardsDao.insertIfAbsent(
        dailyCardRow('2026-09-26'),
      );
      final second = await db.dailyCardsDao.insertIfAbsent(
        dailyCardRow('2026-09-26', cardId: 'major_00', minute: 5),
      );
      expect(first.cardId, 'major_17');
      expect(second, first);
      expect(await db.dailyCardsDao.all(), hasLength(1));
    });

    test('upsert, patch, byDate and delete', () async {
      await db.dailyCardsDao.upsert(dailyCardRow('2026-09-26'));
      await db.dailyCardsDao.upsert(
        dailyCardRow('2026-09-26', note: 'replaced'),
      );
      expect((await db.dailyCardsDao.byDate('2026-09-26'))!.note, 'replaced');
      expect(
        await db.dailyCardsDao.patch(
          '2026-09-26',
          const DailyCardsCompanion(favourite: Value(true)),
        ),
        isTrue,
      );
      expect(
        await db.dailyCardsDao.patch(
          '2000-01-01',
          const DailyCardsCompanion(favourite: Value(true)),
        ),
        isFalse,
      );
      final row = (await db.dailyCardsDao.byDate('2026-09-26'))!;
      expect(row.favourite, isTrue);
      expect(row.drawnAt, at(0));
      expect(row.createdAt, at(0));
      expect(row.updatedAt, at(0));
      expect(row.reversed, isFalse);
      expect(await db.dailyCardsDao.deleteByDate('2026-09-26'), isTrue);
      expect(await db.dailyCardsDao.deleteByDate('2026-09-26'), isFalse);
      expect(await db.dailyCardsDao.byDate('2026-09-26'), isNull);
    });

    test('lists newest date first, with a favourites filter', () async {
      await db.dailyCardsDao.upsert(
        dailyCardRow('2026-09-24', favourite: true),
      );
      await db.dailyCardsDao.upsert(dailyCardRow('2026-09-26'));
      await db.dailyCardsDao.upsert(dailyCardRow('2026-09-25'));
      expect(
        [for (final c in await db.dailyCardsDao.all()) c.localDate],
        [
          '2026-09-26',
          '2026-09-25',
          '2026-09-24',
        ],
      );
      expect([
        for (final c in await db.dailyCardsDao.watchAll().first) c.localDate,
      ], hasLength(3));
      expect(
        [
          for (final c
              in await db.dailyCardsDao.watchAll(favouritesOnly: true).first)
            c.localDate,
        ],
        ['2026-09-24'],
      );
      await db.dailyCardsDao.deleteAll();
      expect(await db.dailyCardsDao.all(), isEmpty);
    });

    test('watchByDate emits null then the drawn card', () async {
      final seen = <String?>[];
      final sub = db.dailyCardsDao
          .watchByDate('2026-09-26')
          .listen((c) => seen.add(c?.cardId));
      await pumpEventQueue();
      await db.dailyCardsDao.insertIfAbsent(dailyCardRow('2026-09-26'));
      await pumpEventQueue();
      await sub.cancel();
      expect(seen, [null, 'major_17']);
    });
  });

  group('SettingsDao', () {
    test('write, read, overwrite and remove', () async {
      expect(await db.settingsDao.read('theme'), isNull);
      await db.settingsDao.write('theme', '"dark"');
      await db.settingsDao.write('theme', '"light"');
      expect(await db.settingsDao.read('theme'), '"light"');
      expect(await db.settingsDao.remove('theme'), isTrue);
      expect(await db.settingsDao.remove('theme'), isFalse);
      expect(await db.settingsDao.read('theme'), isNull);
    });

    test('replaceAll swaps every key in one go', () async {
      await db.settingsDao.write('old', '1');
      await db.settingsDao.replaceAll({'a': '1', 'b': '{"x":2}'});
      expect(await db.settingsDao.readAll(), {'a': '1', 'b': '{"x":2}'});
      expect(await db.settingsDao.watchAll().first, {
        'a': '1',
        'b': '{"x":2}',
      });
    });

    test('watch emits the value and each change', () async {
      final seen = <String?>[];
      final sub = db.settingsDao.watch('locale').listen(seen.add);
      await pumpEventQueue();
      await db.settingsDao.write('locale', '"uk"');
      await pumpEventQueue();
      await sub.cancel();
      expect(seen, [null, '"uk"']);
    });
  });

  test('schemaVersion is 1 and the file name is taro_journal', () {
    expect(db.schemaVersion, 1);
    expect(JournalDatabase.name, 'taro_journal');
  });
}
