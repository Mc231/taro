import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taro/data/db/database_location.dart';
import 'package:taro/data/db/device/device_database.dart';
import 'package:taro/data/db/instant_converter.dart';
import 'package:taro/data/db/journal/journal_database.dart';
import 'package:taro_core/taro_core.dart';

import '../../../../../packages/taro_core/test/fakes/fakes.dart';
import 'db_fixtures.dart';

DatabaseLocation locationIn(Directory dir) => DatabaseLocation(
  directory: () async => dir.path,
  tempDirectory: () async => dir.path,
);

Future<Directory> tempDir(String prefix) async {
  final dir = await Directory.systemTemp.createTemp(prefix);
  // The database isolate removes -wal/-shm shortly after close(), which can
  // race a recursive delete; retry until the tree is gone.
  addTearDown(() async {
    for (var attempt = 0; dir.existsSync(); attempt++) {
      try {
        await dir.delete(recursive: true);
      } on FileSystemException {
        if (attempt == 20) rethrow;
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
    }
  });
  return dir;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('InstantConverter', () {
    const converter = InstantConverter();

    test('round-trips an instant with microseconds, in UTC', () {
      final local = DateTime(2026, 9, 26, 12, 30, 1, 2, 3);
      final back = converter.fromSql(converter.toSql(local));
      expect(back, local.toUtc());
      expect(back.isUtc, isTrue);
      expect(converter.toSql(DateTime.utc(1970)), 0);
    });
  });

  group('DatabaseLocation', () {
    test('builds paths and SQLite siblings', () async {
      final location = DatabaseLocation(directory: () async => '/data');
      expect(await location.pathOf('taro_device.db'), '/data/taro_device.db');
      expect(DatabaseLocation.filesOf('/data/taro_device.db'), [
        '/data/taro_device.db',
        '/data/taro_device.db-wal',
        '/data/taro_device.db-shm',
        '/data/taro_device.db-journal',
      ]);
    });

    test('defaults to the path_provider documents and temp dirs', () async {
      const channel = MethodChannel('plugins.flutter.io/path_provider');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            channel,
            (call) async => switch (call.method) {
              'getApplicationDocumentsDirectory' => '/docs',
              'getTemporaryDirectory' => '/tmp-dir',
              _ => null,
            },
          );
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null),
      );
      const location = DatabaseLocation();
      expect(await location.directory(), '/docs');
      expect(await location.tempDirectory(), '/tmp-dir');
    });
  });

  group('file databases (driftDatabase, shareAcrossIsolates)', () {
    test('taro_journal.db persists across opens and uses WAL', () async {
      final dir = await tempDir('taro_journal_');
      final location = locationIn(dir);
      final first = JournalDatabase.open(location: location);
      await first.readingsDao.upsert(readingRow('r1'), threeCards('r1'));
      final mode = await first
          .customSelect('PRAGMA journal_mode')
          .map((r) => r.read<String>('journal_mode'))
          .getSingle();
      expect(mode, 'wal');
      await first.close();
      expect(File('${dir.path}/taro_journal.db').existsSync(), isTrue);

      final second = JournalDatabase.open(location: location);
      addTearDown(second.close);
      expect((await second.readingsDao.byId('r1'))!.cards, hasLength(3));
    });

    test('taro_device.db excludes its files from backup on open', () async {
      final dir = await tempDir('taro_device_');
      final exclusion = FakeBackupExclusion();
      final logger = CapturingLogger();
      final db = DeviceDatabase.open(
        backupExclusion: exclusion,
        logger: logger,
        location: locationIn(dir),
      );
      addTearDown(db.close);
      await db.pendingAcksDao.enqueue('r1', now: at(0));
      final path = '${dir.path}/taro_device.db';
      expect(exclusion.excluded, DatabaseLocation.filesOf(path));
      expect(File(path).existsSync(), isTrue);
      expect(File('$path-wal').existsSync(), isTrue);
      expect(logger.records, isEmpty);
    });

    test('a failed exclusion is logged and the database still works', () async {
      final dir = await tempDir('taro_device_');
      final exclusion = FakeBackupExclusion()
        ..failNext(const Failure.storage(), on: 'exclude');
      final logger = CapturingLogger();
      final db = DeviceDatabase.open(
        backupExclusion: exclusion,
        logger: logger,
        location: locationIn(dir),
      );
      addTearDown(db.close);
      await db.cacheDao.putSyncValue('k', 'v');
      expect(await db.cacheDao.syncValue('k'), 'v');
      expect(logger.records, hasLength(1));
      expect(logger.records.single.message, contains('STORAGE'));
      expect(logger.records.single.message, isNot(contains(dir.path)));
    });
  });

  test(
    'restore simulation: journal restored, device DB and secure storage '
    'empty (RC75)',
    () async {
      // Device A: everything populated.
      final deviceA = await tempDir('taro_device_a_');
      final secureA = InMemorySecureStore();
      await secureA.write('taro.install_id', 'install-a');
      final journalA = JournalDatabase.open(location: locationIn(deviceA));
      await journalA.readingsDao.upsert(
        readingRow('r1', question: 'Moon?'),
        threeCards('r1'),
      );
      await journalA.dailyCardsDao.upsert(dailyCardRow('2026-09-26'));
      await journalA.settingsDao.write('theme', '"dark"');
      await journalA.close();
      final exclusionA = FakeBackupExclusion();
      final deviceDbA = DeviceDatabase.open(
        backupExclusion: exclusionA,
        logger: CapturingLogger(),
        location: locationIn(deviceA),
      );
      await deviceDbA.cacheDao.replaceBalanceIf(
        BalanceCacheCompanion.insert(
          json: '{}',
          ledgerVersion: 7,
          serverTime: at(0),
          syncedAt: at(0),
        ),
        (_) => true,
      );
      await deviceDbA.outboxDao.insertIfAbsent(
        PurchaseOutboxTableCompanion.insert(
          txnKey: 't1',
          productId: 'com.vshyrochuk.taro.readings_3',
          platform: 'ios',
          idempotencyKey: 'k',
          status: 'awaitingVerification',
          createdAt: at(0),
          updatedAt: at(0),
        ),
      );
      await deviceDbA.cacheDao.putConsent(
        ConsentStatesCompanion.insert(
          json: '{"ai":"granted"}',
          updatedAt: at(0),
        ),
      );
      await deviceDbA.entitlementsDao.put(
        EntitlementsCompanion.insert(
          key: 'remove_ads',
          state: 'owned',
          source: 'store',
        ),
      );
      await deviceDbA.pendingAcksDao.enqueue('r1', now: at(0));
      await deviceDbA.close();

      // What an OS backup carries: every file that is not excluded. Only
      // taro_device.db and its siblings are excluded; secure storage is
      // excluded by the platform rules and never restored.
      final excluded = exclusionA.excluded.toSet();
      expect(excluded, contains('${deviceA.path}/taro_device.db'));
      expect(excluded.where((p) => p.contains('taro_journal')), isEmpty);

      // Device B: restore the backed-up files only.
      final deviceB = await tempDir('taro_device_b_');
      for (final file in deviceA.listSync().whereType<File>()) {
        if (!excluded.contains(file.path)) {
          file.copySync('${deviceB.path}/${file.uri.pathSegments.last}');
        }
      }
      expect(File('${deviceB.path}/taro_device.db').existsSync(), isFalse);
      final secureB = InMemorySecureStore();

      final journalB = JournalDatabase.open(location: locationIn(deviceB));
      addTearDown(journalB.close);
      final deviceDbB = DeviceDatabase.open(
        backupExclusion: FakeBackupExclusion(),
        logger: CapturingLogger(),
        location: locationIn(deviceB),
      );
      addTearDown(deviceDbB.close);

      // The journal came back, search index included.
      expect((await journalB.readingsDao.byId('r1'))!.cards, hasLength(3));
      expect(await journalB.dailyCardsDao.byDate('2026-09-26'), isNotNull);
      expect(await journalB.settingsDao.read('theme'), '"dark"');
      expect(await journalB.readingsDao.search('moon'), hasLength(1));

      // No cached balance, no purchase to re-verify, consent unknown.
      expect(await deviceDbB.cacheDao.balance(), isNull);
      expect(await deviceDbB.outboxDao.all(), isEmpty);
      expect(await deviceDbB.cacheDao.consent(), isNull);
      expect(const ConsentState().ai.decision, AiConsentDecision.unknown);
      expect(await deviceDbB.entitlementsDao.byKey('remove_ads'), isNull);
      expect(await deviceDbB.pendingAcksDao.all(), isEmpty);
      // A new install identity will be created (02 §6.2).
      expect((await secureB.read('taro.install_id')).valueOrNull, isNull);
      expect((await secureA.read('taro.install_id')).valueOrNull, 'install-a');
    },
  );
}
