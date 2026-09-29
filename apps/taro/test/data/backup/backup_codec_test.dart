import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' hide isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:taro/data/backup/backup_codec.dart';
import 'package:taro/data/backup/journal_backup_store.dart';
import 'package:taro/data/db/journal/journal_database.dart';
import 'package:taro_core/taro_core.dart';

import '../../../../../packages/taro_core/test/contracts/contract_support.dart';
import '../../../../../packages/taro_core/test/fakes/fakes.dart';
import '../db/db_fixtures.dart';
import 'support/json_schema.dart';

Future<R> _inline<R>(FutureOr<R> Function() task) async => task();

final _codec = BackupCodec(runner: _inline);

Failure _invalid(BackupInvalidReason reason) =>
    Failure.backupInvalid(reason: reason);

Uint8List _bytes(Object? json) =>
    Uint8List.fromList(utf8.encode(jsonEncode(json)));

Map<String, Object?> _json(Uint8List bytes) =>
    jsonDecode(utf8.decode(bytes)) as Map<String, Object?>;

/// Every object key anywhere in [json].
Set<String> _keys(Object? json) => switch (json) {
  Map<String, Object?>() => {
    ...json.keys,
    for (final v in json.values) ..._keys(v),
  },
  List<Object?>() => {for (final v in json) ..._keys(v)},
  _ => const {},
};

void main() {
  final exportedAt = DateTime.utc(2026, 9, 29, 10, 30);
  const appVersion = '1.2.3+45';

  final fixtureBytes = File(kAppFixturePath).readAsBytesSync();
  late BackupData fixtureData;

  setUpAll(() async {
    // The round trip opens a second journal (another device).
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    fixtureData = expectOk(await _codec.decode(fixtureBytes)).data;
  });

  late JournalDatabase db;
  late JournalBackupStore store;
  late CapturingLogger logger;

  setUp(() {
    db = memoryJournal();
    logger = CapturingLogger();
    store = JournalBackupStore(db, logger: logger);
  });
  tearDown(() => db.close());

  /// Device-only readings and fields the export must never carry.
  final pending = aReading()
      .withId('aaaaaaaa-0000-4000-8000-000000000001')
      .pending()
      .withQuestion('PENDING-QUESTION')
      .build();
  final failed = aReading()
      .withId('aaaaaaaa-0000-4000-8000-000000000002')
      .failed(const Failure.readingExpiredRefunded(), refunded: true)
      .build();
  final charged = aReading()
      .withId('aaaaaaaa-0000-4000-8000-000000000003')
      .withModelId('MODEL-SECRET-ID')
      .withChargeSource(ChargeSource.paid)
      .reported()
      .refused(
        safety: SafetyInfo(
          category: RefusalCategory.selfHarm,
          messageKey: RefusalCategory.selfHarm.messageKey,
          canRephrase: false,
          crisisResources: [aCrisisResource()],
        ),
      )
      .build();

  Future<void> seed() async {
    expectOk(
      await store.replaceAll(
        fixtureData.copyWith(
          settings: fixtureData.settings.copyWith(reduceMotion: true),
          readings: [...fixtureData.readings, pending, failed, charged],
        ),
      ),
    );
  }

  group('encode', () {
    test('writes the data wrapper with the JCS checksum (RC70)', () async {
      final encoded = await _codec.encode(
        fixtureData,
        exportedAt: exportedAt,
        appVersion: appVersion,
      );
      final json = _json(encoded.bytes);
      expect(json.keys, [
        'format',
        'schemaVersion',
        'exportedAt',
        'appVersion',
        'data',
        'checksum',
      ]);
      expect(json['format'], 'taro.backup');
      expect(json['schemaVersion'], 1);
      expect(json['exportedAt'], '2026-09-29T10:30:00Z');
      expect(json['appVersion'], appVersion);
      expect(json['checksum'], kFixtureChecksum);
      expect(encoded.backup.checksum, kFixtureChecksum);
      expect(BackupJsonSchema.load().validate(json), isEmpty);
    });

    test('drops pending and failed readings and stores UTC', () async {
      final encoded = await _codec.encode(
        fixtureData.copyWith(readings: [pending, failed]),
        exportedAt: DateTime.utc(2026, 9, 29, 12).toLocal(),
        appVersion: appVersion,
      );
      expect(encoded.backup.data.readings, isEmpty);
      expect(encoded.backup.exportedAt.isUtc, isTrue);
      expect(_json(encoded.bytes)['exportedAt'], '2026-09-29T12:00:00Z');
    });

    test('runs in a real isolate by default', () async {
      final codec = BackupCodec();
      final encoded = await codec.encode(
        fixtureData,
        exportedAt: exportedAt,
        appVersion: appVersion,
      );
      expect(encoded.backup.checksum, kFixtureChecksum);
      final decoded = expectOk(await codec.decode(encoded.bytes));
      expect(decoded, encoded.backup);
    });
  });

  group('encodeJournal from taro_journal.db', () {
    test('a key scan proves forbidden keys are absent (06 §2.5)', () async {
      await seed();
      final encoded = expectOk(
        await _codec.encodeJournal(
          store,
          exportedAt: exportedAt,
          appVersion: appVersion,
        ),
      );
      final json = _json(encoded.bytes);
      final keys = _keys(json);
      final allowed = {
        for (final names in BackupSchemaV1.objectKeys.values) ...names,
      };
      expect(keys.difference(allowed), isEmpty);
      const forbidden = {
        ...kForbiddenBackupKeys,
        'chargeSource',
        'charge_source',
        'modelId',
        'deliveryAcked',
        'reported',
        'safety',
        'failure',
        'reduceMotion',
        'spreadVersion',
        'installSecret',
        'sessionToken',
        'purchaseBinding',
        'attestKeyId',
        'token',
        'outbox',
        'purchaseOutbox',
        'consentState',
        'aiConsent',
        'remoteConfig',
        'syncState',
        'pendingAcks',
        'ledgerVersion',
      };
      expect(keys.intersection(forbidden), isEmpty);
      final text = utf8.decode(encoded.bytes);
      expect(text, isNot(contains('MODEL-SECRET-ID')));
      expect(text, isNot(contains('PENDING-QUESTION')));
      expect(text, isNot(contains(pending.id.value)));
      expect(text, isNot(contains(failed.id.value)));
      expect(text, isNot(contains('READING_EXPIRED_REFUNDED')));
      expect(text, isNot(contains(aCrisisResource().name)));
      expect(BackupJsonSchema.load().validate(json), isEmpty);
    });

    test('a round trip through two journals preserves every field', () async {
      await seed();
      final first = expectOk(
        await _codec.encodeJournal(
          store,
          exportedAt: exportedAt,
          appVersion: appVersion,
        ),
      );
      final fixture = _json(fixtureBytes);
      final fixtureDataJson = fixture['data']! as Map<String, Object?>;
      final firstData = _json(first.bytes)['data']! as Map<String, Object?>;
      expect(firstData['settings'], fixtureDataJson['settings']);
      expect(
        firstData['readings'],
        unorderedEquals([
          ...fixtureDataJson['readings']! as List<Object?>,
          charged.toBackupJson(),
        ]),
      );
      expect(
        firstData['dailyCards'],
        unorderedEquals(fixtureDataJson['dailyCards']! as List<Object?>),
      );

      // Import into an empty journal on another device, export again.
      final other = memoryJournal();
      addTearDown(other.close);
      final otherStore = JournalBackupStore(other, logger: logger);
      final decoded = expectOk(await _codec.decode(first.bytes));
      expectOk(
        await otherStore.importBackup(decoded.data, mode: MergeMode.replace),
      );
      final second = expectOk(
        await _codec.encodeJournal(
          otherStore,
          exportedAt: exportedAt,
          appVersion: appVersion,
        ),
      );
      expect(second.bytes, first.bytes);
      expect(second.backup.checksum, first.backup.checksum);
    });

    test('a storage failure is returned, not thrown', () async {
      await db.readingsDao.upsert(readingRow('broken'), threeCards('broken'));
      await db.readingsDao.patch(
        'broken',
        const ReadingsCompanion(chargeSource: Value('gold')),
      );
      final result = await _codec.encodeJournal(
        store,
        exportedAt: exportedAt,
        appVersion: appVersion,
      );
      expect(expectErr(result), const Failure.storage());
    });
  });

  group('decode (import pipeline up to the preview)', () {
    test('accepts a valid file against the bundled deck', () async {
      final backup = expectOk(
        await _codec.decode(fixtureBytes, deck: aDeck().build()),
      );
      expect(backup.data.readings, hasLength(3));
      expect(backup.data.dailyCards, hasLength(2));
    });

    test('keeps the device reduceMotion on the imported settings', () async {
      final backup = expectOk(
        await _codec.decode(fixtureBytes, reduceMotion: true),
      );
      expect(backup.data.settings.reduceMotion, isTrue);
    });

    test(
      'a tampered file with credits is rejected and has no effect',
      () async {
        await seed();
        final before = expectOk(await store.snapshot());
        final encoded = expectOk(
          await _codec.encodeJournal(
            store,
            exportedAt: exportedAt,
            appVersion: appVersion,
          ),
        );
        final json = _json(encoded.bytes);
        final data = json['data']! as Map<String, Object?>;
        final withCredits = {...data, 'credits': 999};
        final tampered = [
          // Hand-added at the root, the checksum still matches.
          {...json, 'credits': 999},
          // Inside data, resealed so only the schema can catch it.
          {
            ...json,
            'data': withCredits,
            'checksum': BackupChecksum.ofJson(withCredits),
          },
          // Nested in a reading.
          {
            ...json,
            'data': {
              ...data,
              'readings': [
                {
                  ...(data['readings']! as List<Object?>).first!
                      as Map<String, Object?>,
                  'credits': 999,
                },
              ],
            },
          },
        ];
        for (final file in tampered) {
          expect(
            expectErr(await _codec.decode(_bytes(file))),
            _invalid(BackupInvalidReason.schema),
          );
        }
        expect(expectOk(await store.snapshot()), before);
      },
    );

    test('a newer schemaVersion is unsupportedVersion', () async {
      final file = aBackup().withVersion(2).bytes();
      expect(
        expectErr(await _codec.decode(file)),
        _invalid(BackupInvalidReason.unsupportedVersion),
      );
    });

    test('a checksum mismatch is rejected', () async {
      final json = _json(fixtureBytes);
      final data = json['data']! as Map<String, Object?>;
      final edited = {
        ...json,
        'data': {
          ...data,
          'settings': {
            ...data['settings']! as Map<String, Object?>,
            'theme': 'light',
          },
        },
      };
      expect(
        expectErr(await _codec.decode(_bytes(edited))),
        _invalid(BackupInvalidReason.checksum),
      );
      expect(
        expectErr(
          await _codec.decode(aBackup().withChecksum('0' * 64).bytes()),
        ),
        _invalid(BackupInvalidReason.checksum),
      );
    });

    test('a file over 20 MB is tooLarge before parsing', () async {
      final big = Uint8List(BackupSchemaV1.maxFileBytes + 1);
      expect(
        expectErr(await _codec.decode(big)),
        _invalid(BackupInvalidReason.tooLarge),
      );
      expect(
        expectErr(BackupCodec.decodeSync(big)),
        _invalid(BackupInvalidReason.tooLarge),
      );
    });

    test('more than 50,000 entries is tooLarge', () async {
      final json = _json(fixtureBytes);
      final data = json['data']! as Map<String, Object?>;
      for (final key in ['readings', 'dailyCards']) {
        final over = {
          ...data,
          key: List.filled(
            BackupSchemaV1.maxEntries + 1,
            (data[key]! as List<Object?>).first,
          ),
        };
        final file = {
          ...json,
          'data': over,
          'checksum': BackupChecksum.ofJson(over),
        };
        expect(
          expectErr(await _codec.decode(_bytes(file))),
          _invalid(BackupInvalidReason.tooLarge),
          reason: key,
        );
      }
    });

    test('not JSON, bad UTF-8 and a wrong format are rejected', () async {
      expect(
        expectErr(await _codec.decode(utf8.encode('{"format":'))),
        _invalid(BackupInvalidReason.notJson),
      );
      expect(
        expectErr(await _codec.decode([0xff, 0xfe, 0x00])),
        _invalid(BackupInvalidReason.notJson),
      );
      expect(
        expectErr(await _codec.decode(_bytes([1, 2]))),
        _invalid(BackupInvalidReason.wrongFormat),
      );
      expect(
        expectErr(await _codec.decode(aBackup().withFormat('x').bytes())),
        _invalid(BackupInvalidReason.wrongFormat),
      );
    });

    test('a UTF-8 byte-order mark is accepted', () async {
      final withBom = [0xEF, 0xBB, 0xBF, ...fixtureBytes];
      expect(expectOk(await _codec.decode(withBom)).checksum, kFixtureChecksum);
    });

    test('a card missing from the deck is a schema failure', () async {
      const empty = Deck(
        id: 'rws_original',
        version: 1,
        cards: [],
        artSet: 'x',
      );
      expect(
        expectErr(await _codec.decode(fixtureBytes, deck: empty)),
        _invalid(BackupInvalidReason.schema),
      );
    });

    test('an older version without a migration is a schema failure', () async {
      expect(
        expectErr(await _codec.decode(aBackup().withVersion(0).bytes())),
        _invalid(BackupInvalidReason.schema),
      );
    });
  });
}
