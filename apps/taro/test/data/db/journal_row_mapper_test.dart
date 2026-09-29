import 'package:drift/drift.dart' hide isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:taro/data/db/journal/journal_database.dart';
import 'package:taro/data/db/journal/journal_row_mapper.dart';
import 'package:taro_core/taro_core.dart';

import '../../../../../packages/taro_core/test/fakes/fakes.dart';
import 'db_fixtures.dart';

void main() {
  late JournalDatabase db;

  setUp(() => db = memoryJournal());
  tearDown(() => db.close());

  Future<Reading> roundTrip(Reading reading) async {
    await db.readingsDao.upsert(
      JournalRowMapper.readingRow(reading),
      JournalRowMapper.cardRows(reading),
    );
    return JournalRowMapper.reading(
      (await db.readingsDao.byId(
        reading.id.value,
      ))!,
    );
  }

  group('readings', () {
    final safety = SafetyInfo(
      category: RefusalCategory.gambling,
      messageKey: RefusalCategory.gambling.messageKey,
      canRephrase: true,
      crisisResources: [aCrisisResource()],
    );

    final cases = <String, Reading>{
      'complete with every field': aReading()
          .withNote('A note')
          .favourite()
          .withRating(Rating.down, RatingReason.tone)
          .withModelId('model-x')
          .withChargeSource(ChargeSource.paid)
          .reported()
          .updatedAt(DateTime.utc(2026, 9, 27, 1, 2, 3, 4, 5))
          .build(),
      'pending': aReading().pending().build(),
      'refused with safety': aReading().refused(safety: safety).build(),
      'refused without safety': aReading().refused().build(),
      'failed and refunded': aReading()
          .failed(const Failure.readingExpiredRefunded(), refunded: true)
          .build(),
      'failed with an unmapped code': aReading()
          .failed(const Failure.contract(wireCode: 'SOMETHING_NEW'))
          .build(),
      'classic without a question': aReading()
          .classic()
          .withQuestion(null)
          .withChargeSource(null)
          .build(),
    };

    for (final MapEntry(:key, :value) in cases.entries) {
      test('$key round-trips losslessly', () async {
        expect(await roundTrip(value), value);
      });
    }

    test(
      'stores cards in position order and JSON columns as specified',
      () async {
        final reading = aReading()
            .failed(const Failure.timeout(), refunded: true)
            .build();
        final row = JournalRowMapper.readingRow(reading);
        expect(row.failureJson.value, '{"code":"TIMEOUT","refunded":true}');
        expect(row.status.value, 'failed');
        final cards = JournalRowMapper.cardRows(reading);
        expect([for (final c in cards) c.positionOrder.value], [0, 1, 2]);
        expect(
          [for (final c in cards) c.positionId.value],
          [for (final c in reading.cards) c.positionId.value],
        );
      },
    );

    test('failureOfCode keeps every code', () {
      const failures = [
        Failure.network(),
        Failure.timeout(),
        Failure.sessionExpired(),
        Failure.holdConflict(),
        Failure.readingExpiredRefunded(),
        Failure.aiConsentRequired(),
        Failure.aiUnavailableRegion(),
        Failure.aiUnavailable(),
        Failure.requestInProgress(),
        Failure.storage(),
      ];
      for (final f in failures) {
        expect(JournalRowMapper.failureOfCode(f.code), f);
      }
      expect(
        JournalRowMapper.failureOfCode('INTERNAL'),
        const Failure.contract(wireCode: 'INTERNAL'),
      );
    });

    Future<void> expectBadRow(ReadingsCompanion changes) async {
      final reading = aReading().build();
      await db.readingsDao.upsert(
        JournalRowMapper.readingRow(reading),
        JournalRowMapper.cardRows(reading),
      );
      await db.readingsDao.patch(reading.id.value, changes);
      final row = (await db.readingsDao.byId(reading.id.value))!;
      expect(() => JournalRowMapper.reading(row), throwsFormatException);
    }

    test('rejects an unknown charge source', () async {
      await expectBadRow(const ReadingsCompanion(chargeSource: Value('gold')));
    });

    test('rejects an unknown rating reason', () async {
      await expectBadRow(const ReadingsCompanion(ratingReason: Value('meh')));
    });

    test('rejects content_json that is not an object', () async {
      await expectBadRow(const ReadingsCompanion(contentJson: Value('[]')));
    });

    test('rejects malformed failure_json', () async {
      await expectBadRow(
        const ReadingsCompanion(
          status: Value('failed'),
          failureJson: Value('{}'),
        ),
      );
      await expectBadRow(
        const ReadingsCompanion(
          status: Value('failed'),
          failureJson: Value('{"code":"TIMEOUT","refunded":"no"}'),
        ),
      );
    });

    test('a failed row without failure_json is rejected', () async {
      await expectBadRow(const ReadingsCompanion(status: Value('failed')));
    });

    test('rejects an invalid card ID', () async {
      final reading = aReading().build();
      await db.readingsDao.upsert(JournalRowMapper.readingRow(reading), [
        ReadingCardsCompanion.insert(
          readingId: reading.id.value,
          positionId: 'past',
          positionOrder: 0,
          cardId: 'joker',
          reversed: false,
        ),
      ]);
      final row = (await db.readingsDao.byId(reading.id.value))!;
      expect(() => JournalRowMapper.reading(row), throwsFormatException);
    });

    test('rejects an unknown status', () {
      final row = (
        reading: ReadingRow(
          id: 'x',
          spreadId: 'single',
          spreadVersion: 1,
          localDate: '2026-09-26',
          status: 'lost',
          contentLocale: 'en',
          favourite: false,
          deliveryAcked: false,
          reported: false,
          drawnAt: at(0),
          createdAt: at(0),
          updatedAt: at(0),
        ),
        cards: <ReadingCardRow>[],
      );
      expect(() => JournalRowMapper.reading(row), throwsFormatException);
    });
  });

  group('daily cards', () {
    test('round-trip losslessly', () async {
      final card = aDailyCard()
          .on('2026-09-24')
          .withCard('cups_14')
          .reversed()
          .withNote('Hope')
          .favourite()
          .updatedAt(DateTime.utc(2026, 9, 24, 12, 0, 0, 1))
          .build();
      await db.dailyCardsDao.upsert(JournalRowMapper.dailyCardRow(card));
      final row = (await db.dailyCardsDao.byDate('2026-09-24'))!;
      expect(JournalRowMapper.dailyCard(row), card);
    });
  });

  group('settings', () {
    test('no rows read as the defaults', () {
      expect(JournalRowMapper.settings(const {}), const UserSettings());
    });

    test('round-trip every field, including null locale and reduceMotion', () {
      const values = [
        UserSettings(
          themeMode: ThemeMode.dark,
          localeOverride: 'uk',
          reversalsEnabled: false,
          hapticsEnabled: false,
          reminder: ReminderSettings(enabled: true, time: '21:30'),
          reduceMotion: true,
        ),
        UserSettings(),
      ];
      for (final s in values) {
        expect(
          JournalRowMapper.settings(JournalRowMapper.settingsRows(s)),
          s,
        );
      }
    });

    test('stores one JSON value per key', () {
      expect(JournalRowMapper.settingsRows(const UserSettings()), {
        SettingsKeys.theme: '"system"',
        SettingsKeys.localeOverride: 'null',
        SettingsKeys.reversalsEnabled: 'true',
        SettingsKeys.hapticsEnabled: 'true',
        SettingsKeys.reminder: '{"enabled":false,"time":"09:00"}',
        SettingsKeys.reduceMotion: 'null',
      });
    });

    test('ignores unknown keys; a malformed value reads as its default', () {
      const stored = UserSettings(
        themeMode: ThemeMode.dark,
        localeOverride: 'uk',
        hapticsEnabled: false,
        reminder: ReminderSettings(enabled: true, time: '21:30'),
        reduceMotion: true,
      );
      final rows = JournalRowMapper.settingsRows(stored);
      expect(
        JournalRowMapper.settings({...rows, 'legacy': '1'}),
        stored,
      );
      final cases = <String, (String, String)>{
        'theme enum': (SettingsKeys.theme, '"sepia"'),
        'theme type': (SettingsKeys.theme, '3'),
        'locale': (SettingsKeys.localeOverride, '"xx"'),
        'reminder': (SettingsKeys.reminder, '{"enabled":true,"time":"25:00"}'),
        'haptics': (SettingsKeys.hapticsEnabled, 'not json'),
        'reduceMotion': (SettingsKeys.reduceMotion, '"yes"'),
      };
      final expected = {
        SettingsKeys.theme: stored.copyWith(themeMode: ThemeMode.system),
        SettingsKeys.localeOverride: stored.copyWith(localeOverride: null),
        SettingsKeys.reminder: stored.copyWith(
          reminder: const ReminderSettings(),
        ),
        SettingsKeys.hapticsEnabled: stored.copyWith(hapticsEnabled: true),
        SettingsKeys.reduceMotion: stored.copyWith(reduceMotion: null),
      };
      for (final MapEntry(key: name, value: (key, raw)) in cases.entries) {
        expect(
          JournalRowMapper.settings({...rows, key: raw}),
          expected[key],
          reason: name,
        );
      }
    });
  });
}
