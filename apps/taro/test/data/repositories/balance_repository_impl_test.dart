import 'dart:async';

import 'package:drift/drift.dart' hide isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:taro/data/db/device/device_database.dart';
import 'package:taro/data/repositories/balance_repository_impl.dart';
import 'package:taro_core/taro_core.dart';

import '../../../../../packages/taro_core/test/contracts/contracts.dart';
import '../../../../../packages/taro_core/test/fakes/fakes.dart';
import '../api/support/worker_client_harness.dart';
import '../db/db_fixtures.dart';

/// A scripted `GET /v1/balance` over an in-memory `taro_device.db`.
final class _Harness implements BalanceRepositoryHarness {
  _Harness._(this.db, this.logger);

  static Future<_Harness> open() async {
    final harness = _Harness._(memoryDevice(), CapturingLogger());
    harness.repo = await BalanceRepositoryImpl.open(
      cache: harness.db.cacheDao,
      fetch: harness.fetch,
      logger: harness.logger,
    );
    addTearDown(() async {
      await harness.repo.close();
      await harness.db.close();
    });
    return harness;
  }

  final DeviceDatabase db;
  final CapturingLogger logger;
  late BalanceRepositoryImpl repo;
  CreditBalance? server;
  Failure? _failNext;
  Completer<void>? _gate;
  int _requests = 0;

  Future<Result<CreditBalance>> fetch() async {
    _requests++;
    await _gate?.future;
    final failure = _failNext;
    _failNext = null;
    return failure == null ? Result.ok(server!) : Result.err(failure);
  }

  @override
  BalanceRepository get subject => repo;

  @override
  void serverReturns(CreditBalance balance) => server = balance;

  @override
  void serverFailsNext(Failure failure) => _failNext = failure;

  @override
  int get requests => _requests;

  @override
  void holdRequests() => _gate = Completer<void>();

  @override
  void release() {
    _gate?.complete();
    _gate = null;
  }
}

void main() {
  late _Harness h;
  setUp(() async => h = await _Harness.open());

  runBalanceRepositoryContract(() => h);

  final t0 = DateTime.utc(2026, 9, 26, 10);
  CreditBalance balance(int version, {int second = 0, int? remaining}) =>
      aCreditBalance()
          .withLedgerVersion(version)
          .withPaid(version)
          .build()
          .copyWith(
            serverTime: t0.add(Duration(seconds: second)),
            free: aCreditBalance().build().free.copyWith(
              remaining: remaining ?? 1,
            ),
          );

  group('RC67 race (Sprint 11.4)', () {
    test('a GET /v1/balance sent before a reading and answered after it '
        '(lower version) never overwrites the post-reading cache', () async {
      final before = balance(4);
      await h.repo.apply(before);
      h
        ..serverReturns(balance(4, remaining: 1))
        ..holdRequests();
      final seen = <CreditBalance?>[];
      final sub = h.repo.watch().listen(seen.add);
      final sync = h.repo.sync(reason: SyncReason.resume);
      await settle();
      final afterReading = balance(5, second: 3, remaining: 0);
      await h.repo.apply(afterReading);
      h.release();
      final synced = expectOk(await sync);
      await settle();
      await sub.cancel();
      expect(synced.ledgerVersion, 5);
      expect(synced.free.remaining, 0);
      expect(h.repo.cached!.free.remaining, 0);
      expect(seen.last!.free.remaining, 0);
      expect(
        seen
            .skipWhile((b) => b?.ledgerVersion != 5)
            .map((b) => b!.free.remaining),
        everyElement(0),
      );
      final row = await h.db.cacheDao.balance();
      expect(row!.ledgerVersion, 5);
    });

    test(
      'the same version with an older or equal serverTime is ignored',
      () async {
        await h.repo.apply(balance(5, second: 3, remaining: 0));
        h.serverReturns(balance(5, second: 1, remaining: 1));
        expect(
          expectOk(await h.repo.sync(reason: SyncReason.manual)).free.remaining,
          0,
        );
        expect(
          (await h.repo.apply(
            balance(5, second: 3, remaining: 1),
          )).free.remaining,
          0,
        );
        expect(h.repo.cached!.free.remaining, 0);
      },
    );
  });

  test('open loads the cached row; a reopen sees the same balance', () async {
    await h.repo.apply(balance(3, second: 2));
    final reopened = await BalanceRepositoryImpl.open(
      cache: h.db.cacheDao,
      fetch: h.fetch,
      logger: h.logger,
    );
    addTearDown(reopened.close);
    expect(reopened.cached, h.repo.cached);
    expect(reopened.cached!.serverTime, t0.add(const Duration(seconds: 2)));
    expect(reopened.cached!.syncedAt, h.repo.cached!.syncedAt);
  });

  test('an unreadable cache row reads as nothing and is replaced', () async {
    await h.db.cacheDao.replaceBalanceIf(
      BalanceCacheCompanion.insert(
        json: '{"ledgerVersion": 9}',
        ledgerVersion: 9,
        serverTime: at(0),
        syncedAt: at(0),
      ),
      (_) => true,
    );
    final reopened = await BalanceRepositoryImpl.open(
      cache: h.db.cacheDao,
      fetch: h.fetch,
      logger: h.logger,
    );
    addTearDown(reopened.close);
    expect(reopened.cached, isNull);
    expect(h.logger.logged('balance cache row unreadable'), isTrue);
    expect((await reopened.apply(balance(1))).ledgerVersion, 1);
    expect((await h.db.cacheDao.balance())!.ledgerVersion, 1);
  });

  test('a cache cleared outside the repository is seen', () async {
    await h.repo.apply(balance(2));
    final seen = <CreditBalance?>[];
    final sub = h.repo.watch().listen(seen.add);
    await settle();
    await h.db.cacheDao.clearBalance();
    await pumpEventQueue();
    await sub.cancel();
    expect(h.repo.cached, isNull);
    expect(seen.last, isNull);
  });

  test('a failed cache write keeps the RC67 order in memory', () async {
    await h.repo.apply(balance(2));
    await h.repo.close();
    await h.db.close();
    expect((await h.repo.apply(balance(3))).ledgerVersion, 3);
    expect((await h.repo.apply(balance(1))).ledgerVersion, 3);
    expect(h.logger.logged('balance cache write failed'), isTrue);
  });

  test('a follow reload failure is logged', () async {
    await h.db.customStatement('DROP TABLE balance_cache');
    await h.db.customStatement(
      'CREATE TABLE balance_cache (id INTEGER PRIMARY KEY, x TEXT)',
    );
    await h.db.customStatement("INSERT INTO balance_cache VALUES (1, 'x')");
    h.db.notifyUpdates({const TableUpdate('balance_cache')});
    await pumpEventQueue();
    expect(h.logger.logged('balance cache reload failed'), isTrue);
  });

  test('a failed sync is logged by code only', () async {
    h.serverFailsNext(const Failure.timeout());
    expect(
      expectErr(await h.repo.sync(reason: SyncReason.preReading)),
      isA<TimeoutFailure>(),
    );
    expect(
      h.logger.logged('balance sync (preReading) failed: TIMEOUT'),
      isTrue,
    );
  });

  test('syncs through WorkerClient.fetchBalance', () async {
    final worker = WorkerClientHarness();
    worker.adapter.reply(200, json: balanceJson(ledgerVersion: 12, paid: 4));
    final repo = await BalanceRepositoryImpl.open(
      cache: h.db.cacheDao,
      fetch: worker.client.fetchBalance,
      logger: h.logger,
    );
    addTearDown(repo.close);
    final synced = expectOk(await repo.sync(reason: SyncReason.launch));
    expect(synced.ledgerVersion, 12);
    expect(synced.paid, 4);
    expect(worker.last.route, 'GET /v1/balance');
    expect((await h.db.cacheDao.balance())!.ledgerVersion, 12);
  });
}
