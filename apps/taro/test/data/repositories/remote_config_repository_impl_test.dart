import 'dart:async';

import 'package:drift/drift.dart' hide isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:taro/data/api/worker_models.dart';
import 'package:taro/data/db/device/device_database.dart';
import 'package:taro/data/repositories/remote_config_repository_impl.dart';
import 'package:taro_core/taro_core.dart';

import '../../../../../packages/taro_core/test/contracts/contracts.dart';
import '../../../../../packages/taro_core/test/fakes/fakes.dart';
import '../api/support/worker_client_harness.dart';
import '../db/db_fixtures.dart';

/// A scripted `GET /v1/config` over an in-memory `taro_device.db`.
final class _Harness implements RemoteConfigRepositoryHarness {
  _Harness(this.db);

  final DeviceDatabase db;
  final FakeClock clock = FakeClock.utc(DateTime.utc(2026, 9, 26, 10));
  final CapturingLogger logger = CapturingLogger();
  final List<String?> sentEtags = [];
  late RemoteConfigRepositoryImpl repo;
  ConfigFetch _next = const ConfigFetch.notModified();
  Failure? _failNext;
  Completer<void>? gate;

  static Future<_Harness> open([DeviceDatabase? db]) async {
    final harness = _Harness(db ?? memoryDevice());
    harness.repo = await harness.reopen();
    addTearDown(() async {
      await harness.repo.close();
      await harness.db.close();
    });
    return harness;
  }

  Future<RemoteConfigRepositoryImpl> reopen() =>
      RemoteConfigRepositoryImpl.open(
        cache: db.cacheDao,
        fetch: fetch,
        clock: clock,
        logger: logger,
      );

  Future<Result<ConfigFetch>> fetch({String? etag}) async {
    sentEtags.add(etag);
    await gate?.future;
    final failure = _failNext;
    _failNext = null;
    return failure == null ? Result.ok(_next) : Result.err(failure);
  }

  void serverJson(Map<String, Object?> json, {String? etag}) =>
      _next = ConfigFetch.fetched(
        config: RemoteConfig.fromJson(json),
        json: json,
        etag: etag,
      );

  @override
  RemoteConfigRepository get subject => repo;

  @override
  void serverReturns(RemoteConfig config) => serverJson({
    'version': config.version,
    'rewarded.enabled': config.rewardedEnabled,
  }, etag: '"v${config.version}"');

  @override
  void serverUnchanged() => _next = const ConfigFetch.notModified();

  @override
  void serverFailsNext(Failure failure) => _failNext = failure;
}

void main() {
  late _Harness h;
  setUp(() async => h = await _Harness.open());

  runRemoteConfigRepositoryContract(() => h);

  test('the ETag of the fetched document goes out as If-None-Match', () async {
    h.serverJson({'version': 3}, etag: '"v3"');
    await h.repo.refresh();
    h.serverUnchanged();
    await h.repo.refresh();
    expect(h.sentEtags, [null, '"v3"']);
  });

  test(
    'the cache survives a restart: offline uses the last cached config',
    () async {
      h.serverJson({'version': 4, 'readings.enabled': false}, etag: '"v4"');
      await h.repo.refresh();
      final reopened = await h.reopen();
      addTearDown(reopened.close);
      expect(reopened.current.version, 4);
      expect(reopened.current.readingsEnabled, isFalse);
      expect(reopened.current.fetchedAt, h.clock.now());
      h.serverFailsNext(const Failure.network());
      expect(expectErr(await reopened.refresh()), isA<NetworkFailure>());
      expect(reopened.current.version, 4);
      expect(h.sentEtags.last, '"v4"');
    },
  );

  test('offline without a cache keeps the compiled defaults', () async {
    h.serverFailsNext(const Failure.network());
    await h.repo.refresh();
    expect(h.repo.current, RemoteConfig.defaults);
    expect(h.logger.logged('config refresh failed: NETWORK'), isTrue);
  });

  test('an unreadable cache starts from the defaults without ETag', () async {
    await h.db.cacheDao.putRemoteConfig(
      RemoteConfigCacheCompanion.insert(
        json: 'not json',
        etag: const Value('"v9"'),
        fetchedAt: at(0),
      ),
    );
    final reopened = await h.reopen();
    addTearDown(reopened.close);
    expect(reopened.current, RemoteConfig.defaults);
    expect(h.logger.logged('config cache unreadable'), isTrue);
    h.serverUnchanged();
    await reopened.refresh();
    expect(h.sentEtags.last, isNull);
  });

  test('clamped cached values are logged by key', () async {
    await h.db.cacheDao.putRemoteConfig(
      RemoteConfigCacheCompanion.insert(
        json: '{"version": 2, "readings.freeDaily": 99}',
        fetchedAt: at(0),
      ),
    );
    final reopened = await h.reopen();
    addTearDown(reopened.close);
    expect(reopened.current.readingsFreeDaily, 5);
    expect(h.logger.logged('config_value_clamped'), isTrue);
  });

  test('a fetched config applies even when the cache write fails', () async {
    h.serverJson({'version': 6});
    await h.db.customStatement('DROP TABLE remote_config_cache');
    expect(expectOk(await h.repo.refresh()).version, 6);
    expect(h.repo.current.version, 6);
    expect(h.logger.logged('config cache write failed'), isTrue);
  });

  test('concurrent refreshes share one request', () async {
    h
      ..serverJson({'version': 8})
      ..gate = Completer<void>();
    final a = h.repo.refresh();
    final b = h.repo.refresh();
    h.gate!.complete();
    final results = await Future.wait([a, b]);
    expect(h.sentEtags, hasLength(1));
    expect(expectOk(results[0]).version, 8);
    expect(expectOk(results[1]).version, 8);
  });

  test('refreshes through WorkerClient.fetchConfig with the ETag', () async {
    final worker = WorkerClientHarness();
    final repo = await RemoteConfigRepositoryImpl.open(
      cache: h.db.cacheDao,
      fetch: worker.client.fetchConfig,
      clock: worker.clock,
      logger: h.logger,
    );
    addTearDown(repo.close);
    worker.adapter
      ..reply(200, json: {'version': 11}, headers: {'etag': '"c11"'})
      ..reply(304);
    expect(expectOk(await repo.refresh()).version, 11);
    expect(expectOk(await repo.refresh()).version, 11);
    expect(worker.requests.last.header('if-none-match'), '"c11"');
    expect((await h.db.cacheDao.remoteConfig())!.etag, '"c11"');
  });
}
