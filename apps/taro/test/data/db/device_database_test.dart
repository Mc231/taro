import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taro/data/db/device/device_database.dart';
import 'package:taro/data/db/device/outbox_dao.dart';

import 'db_fixtures.dart';

BalanceCacheCompanion balanceRow(int version, int minute) =>
    BalanceCacheCompanion.insert(
      json: '{"ledgerVersion":$version}',
      ledgerVersion: version,
      serverTime: at(minute),
      syncedAt: at(minute),
    );

/// RC67 as the repository passes it: newer version, or equal with a newer
/// server time.
bool Function(BalanceCacheRow?) newerThanCached(int version, int minute) =>
    (cached) =>
        cached == null ||
        version > cached.ledgerVersion ||
        (version == cached.ledgerVersion &&
            at(minute).isAfter(cached.serverTime));

PurchaseOutboxTableCompanion outboxRow(
  String txnKey, {
  String key = 'idem-1',
  int minute = 0,
  String platform = 'ios',
}) => PurchaseOutboxTableCompanion.insert(
  txnKey: txnKey,
  productId: 'com.vshyrochuk.taro.readings_3',
  platform: platform,
  transactionId: Value(platform == 'ios' ? txnKey : null),
  verificationData: const Value('jws'),
  orderId: Value(platform == 'android' ? 'GPA.1' : null),
  idempotencyKey: key,
  status: 'awaitingVerification',
  createdAt: at(minute),
  updatedAt: at(minute),
);

void main() {
  late DeviceDatabase db;

  setUp(() => db = memoryDevice());
  tearDown(() => db.close());

  group('CacheDao balance', () {
    test('is empty on a fresh database', () async {
      expect(await db.cacheDao.balance(), isNull);
    });

    test('replaceBalanceIf applies the caller rule atomically', () async {
      expect(
        await db.cacheDao.replaceBalanceIf(
          balanceRow(5, 10),
          newerThanCached(5, 10),
        ),
        isTrue,
      );
      // A late GET /v1/balance with an older version is ignored.
      expect(
        await db.cacheDao.replaceBalanceIf(
          balanceRow(4, 20),
          newerThanCached(4, 20),
        ),
        isFalse,
      );
      // Same version, older server time: ignored.
      expect(
        await db.cacheDao.replaceBalanceIf(
          balanceRow(5, 9),
          newerThanCached(5, 9),
        ),
        isFalse,
      );
      // Same version, newer server time: applied.
      expect(
        await db.cacheDao.replaceBalanceIf(
          balanceRow(5, 11),
          newerThanCached(5, 11),
        ),
        isTrue,
      );
      final row = (await db.cacheDao.balance())!;
      expect(row.id, 1);
      expect(row.ledgerVersion, 5);
      expect(row.serverTime, at(11));
      expect(row.syncedAt, at(11));
      expect(row.json, '{"ledgerVersion":5}');
      expect(await db.select(db.balanceCache).get(), hasLength(1));
    });

    test('watchBalance emits changes and clearBalance empties it', () async {
      final seen = <int?>[];
      final sub = db.cacheDao.watchBalance().listen(
        (r) => seen.add(r?.ledgerVersion),
      );
      await pumpEventQueue();
      await db.cacheDao.replaceBalanceIf(balanceRow(1, 0), (_) => true);
      await pumpEventQueue();
      await db.cacheDao.clearBalance();
      await pumpEventQueue();
      await sub.cancel();
      expect(seen, [null, 1, null]);
    });

    test('a second row is impossible (CHECK id = 1)', () async {
      await expectLater(
        db
            .into(db.balanceCache)
            .insert(
              balanceRow(1, 0).copyWith(id: const Value(2)),
            ),
        throwsA(isA<SqliteException>()),
      );
    });
  });

  group('CacheDao remote config, consent and sync state', () {
    test('remote config round-trips and clears', () async {
      expect(await db.cacheDao.remoteConfig(), isNull);
      await db.cacheDao.putRemoteConfig(
        RemoteConfigCacheCompanion.insert(
          json: '{}',
          etag: const Value('"v1"'),
          fetchedAt: at(1),
        ),
      );
      await db.cacheDao.putRemoteConfig(
        RemoteConfigCacheCompanion.insert(
          json: '{"a":1}',
          etag: const Value('"v2"'),
          fetchedAt: at(2),
        ),
      );
      final row = (await db.cacheDao.remoteConfig())!;
      expect(row.json, '{"a":1}');
      expect(row.etag, '"v2"');
      expect(row.fetchedAt, at(2));
      await db.cacheDao.clearRemoteConfig();
      expect(await db.cacheDao.remoteConfig(), isNull);
    });

    test('consent round-trips, watches and clears', () async {
      final seen = <String?>[];
      final sub = db.cacheDao.watchConsent().listen((r) => seen.add(r?.json));
      await pumpEventQueue();
      await db.cacheDao.putConsent(
        ConsentStatesCompanion.insert(
          json: '{"ai":"granted"}',
          updatedAt: at(1),
        ),
      );
      await pumpEventQueue();
      expect((await db.cacheDao.consent())!.updatedAt, at(1));
      await db.cacheDao.clearConsent();
      await pumpEventQueue();
      await sub.cancel();
      expect(seen, [null, '{"ai":"granted"}', null]);
    });

    test('sync_state markers', () async {
      expect(await db.cacheDao.syncValue('last_timezone'), isNull);
      await db.cacheDao.putSyncValue('last_timezone', 'Europe/Kyiv');
      await db.cacheDao.putSyncValue('last_timezone', 'Europe/Berlin');
      expect(await db.cacheDao.syncValue('last_timezone'), 'Europe/Berlin');
      expect(await db.cacheDao.removeSyncValue('last_timezone'), isTrue);
      expect(await db.cacheDao.removeSyncValue('last_timezone'), isFalse);
    });
  });

  group('EntitlementsDao', () {
    test('put, byKey, watch and remove', () async {
      final seen = <String?>[];
      final sub = db.entitlementsDao
          .watchByKey('remove_ads')
          .listen((r) => seen.add(r?.state));
      await pumpEventQueue();
      await db.entitlementsDao.put(
        EntitlementsCompanion.insert(
          key: 'remove_ads',
          state: 'owned',
          source: 'store',
          verifiedAt: Value(at(3)),
        ),
      );
      await pumpEventQueue();
      final row = (await db.entitlementsDao.byKey('remove_ads'))!;
      expect(row.source, 'store');
      expect(row.verifiedAt, at(3));
      expect(await db.entitlementsDao.remove('remove_ads'), isTrue);
      expect(await db.entitlementsDao.remove('remove_ads'), isFalse);
      await pumpEventQueue();
      await sub.cancel();
      expect(seen, [null, 'owned', null]);
    });

    test('verifiedAt is optional', () async {
      await db.entitlementsDao.put(
        EntitlementsCompanion.insert(
          key: 'remove_ads',
          state: 'unknown',
          source: 'cache',
        ),
      );
      expect(
        (await db.entitlementsDao.byKey('remove_ads'))!.verifiedAt,
        isNull,
      );
    });
  });

  group('OutboxDao', () {
    test(
      'insertIfAbsent keeps the first row and its idempotency key',
      () async {
        final first = await db.outboxDao.insertIfAbsent(outboxRow('t1'));
        final again = await db.outboxDao.insertIfAbsent(
          outboxRow('t1', key: 'idem-2', minute: 5),
        );
        expect(again, first);
        expect(again.idempotencyKey, 'idem-1');
        expect(again.attempts, 0);
        expect(again.lastError, isNull);
        expect(again.transactionId, 't1');
        expect(again.verificationData, 'jws');
        expect(again.orderId, isNull);
      },
    );

    test('open() lists awaiting and granted rows oldest first', () async {
      await db.outboxDao.insertIfAbsent(outboxRow('t3', minute: 3));
      await db.outboxDao.insertIfAbsent(
        outboxRow('t1', minute: 1, platform: 'android'),
      );
      await db.outboxDao.insertIfAbsent(outboxRow('t2', minute: 2));
      await db.outboxDao.insertIfAbsent(outboxRow('t4', minute: 4));
      expect(
        await db.outboxDao.setStatus('t2', 'granted', now: at(10)),
        isTrue,
      );
      await db.outboxDao.setStatus('t3', 'finished', now: at(10));
      await db.outboxDao.setStatus('t4', 'rejected', now: at(10));
      expect(
        await db.outboxDao.setStatus('nope', 'granted', now: at(10)),
        isFalse,
      );
      expect(
        [for (final r in await db.outboxDao.open()) r.txnKey],
        [
          't1',
          't2',
        ],
      );
      expect(
        [for (final r in await db.outboxDao.all()) r.txnKey],
        [
          't1',
          't2',
          't3',
          't4',
        ],
      );
      final t1 = (await db.outboxDao.byTxnKey('t1'))!;
      expect(t1.platform, 'android');
      expect(t1.orderId, 'GPA.1');
      expect((await db.outboxDao.byTxnKey('t2'))!.updatedAt, at(10));
    });

    test('recordAttempt counts and keeps the last error', () async {
      await db.outboxDao.insertIfAbsent(outboxRow('t1'));
      await db.outboxDao.recordAttempt('t1', now: at(1), error: 'NETWORK');
      await db.outboxDao.recordAttempt('t1', now: at(2));
      final row = (await db.outboxDao.byTxnKey('t1'))!;
      expect(row.attempts, 2);
      expect(row.lastError, isNull);
      expect(row.updatedAt, at(2));
      expect(await db.outboxDao.recordAttempt('nope', now: at(3)), isFalse);
    });

    test('the status and platform CHECKs reject unknown values', () async {
      await db.outboxDao.insertIfAbsent(outboxRow('t1'));
      await expectLater(
        db.outboxDao.setStatus('t1', 'done', now: at(1)),
        throwsA(isA<SqliteException>()),
      );
      await expectLater(
        db.outboxDao.insertIfAbsent(outboxRow('t2', platform: 'web')),
        throwsA(isA<SqliteException>()),
      );
    });

    test('prunes finished rows 30 days after they finished', () async {
      await db.outboxDao.insertIfAbsent(outboxRow('old'));
      await db.outboxDao.insertIfAbsent(outboxRow('recent'));
      await db.outboxDao.insertIfAbsent(outboxRow('granted'));
      await db.outboxDao.insertIfAbsent(outboxRow('rejected'));
      await db.outboxDao.setStatus('old', 'finished', now: at(0));
      await db.outboxDao.setStatus('recent', 'finished', now: at(60));
      await db.outboxDao.setStatus('granted', 'granted', now: at(0));
      await db.outboxDao.setStatus('rejected', 'rejected', now: at(0));
      final now = at(0).add(kOutboxRetention).add(const Duration(minutes: 1));

      expect(await db.outboxDao.pruneFinished(now: now), 1);
      expect([for (final r in await db.outboxDao.all()) r.txnKey]..sort(), [
        'granted',
        'recent',
        'rejected',
      ]);
      // Exactly 30 days is kept.
      expect(
        await db.outboxDao.pruneFinished(
          now: at(60).add(kOutboxRetention),
        ),
        0,
      );
    });
  });

  group('PendingAcksDao', () {
    test('enqueue is idempotent, attempts count, remove dequeues', () async {
      await db.pendingAcksDao.enqueue('r2', now: at(2));
      await db.pendingAcksDao.enqueue('r1', now: at(1));
      await db.pendingAcksDao.enqueue('r1', now: at(5));
      expect(await db.pendingAcksDao.recordAttempt('r1'), isTrue);
      expect(await db.pendingAcksDao.recordAttempt('r1'), isTrue);
      expect(await db.pendingAcksDao.recordAttempt('nope'), isFalse);
      final all = await db.pendingAcksDao.all();
      expect([for (final a in all) a.readingId], ['r1', 'r2']);
      expect(all.first.attempts, 2);
      expect(all.first.createdAt, at(1));
      expect(await db.pendingAcksDao.remove('r1'), isTrue);
      expect(await db.pendingAcksDao.remove('r1'), isFalse);
      expect(await db.pendingAcksDao.all(), hasLength(1));
    });
  });

  test('schemaVersion is 1 and the file name is taro_device', () {
    expect(db.schemaVersion, 1);
    expect(DeviceDatabase.name, 'taro_device');
  });
}
