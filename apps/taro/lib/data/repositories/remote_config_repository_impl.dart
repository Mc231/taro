import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:taro/data/api/worker_models.dart';
import 'package:taro/data/db/device/cache_dao.dart';
import 'package:taro/data/db/device/device_database.dart';
import 'package:taro/data/repositories/serial_value.dart';
import 'package:taro_core/taro_core.dart';

/// `GET /v1/config` with `If-None-Match` (`WorkerClient.fetchConfig`).
typedef ConfigFetcher = Future<Result<ConfigFetch>> Function({String? etag});

/// [RemoteConfigRepository] over the Worker and the drift
/// `remote_config_cache` (02 §5, §9.4, §10; RC8).
///
/// [current] is the last fetched config, else the cached one, else
/// `RemoteConfig.defaults`; offline it never changes (02 §10). The cached
/// document's ETag goes out as `If-None-Match`, and `304` keeps [current].
final class RemoteConfigRepositoryImpl implements RemoteConfigRepository {
  RemoteConfigRepositoryImpl._(
    this._dao,
    this._fetch,
    this._clock,
    this._logger,
  );

  /// Opens the repository with the cached config (if any) loaded.
  static Future<RemoteConfigRepositoryImpl> open({
    required CacheDao cache,
    required ConfigFetcher fetch,
    required Clock clock,
    required Logger logger,
  }) async {
    final repo = RemoteConfigRepositoryImpl._(cache, fetch, clock, logger);
    await repo._loadCache();
    return repo;
  }

  final CacheDao _dao;
  final ConfigFetcher _fetch;
  final Clock _clock;
  final Logger _logger;
  final SerialValue<RemoteConfig> _value = SerialValue(RemoteConfig.defaults);
  String? _etag;
  Future<Result<RemoteConfig>>? _inflight;

  @override
  RemoteConfig get current => _value.value;

  @override
  Stream<RemoteConfig> watch() => _value.watch();

  /// Fetches the config; concurrent calls share one request.
  @override
  Future<Result<RemoteConfig>> refresh() =>
      _inflight ??= _refresh().whenComplete(() => _inflight = null);

  Future<Result<RemoteConfig>> _refresh() async {
    switch (await _fetch(etag: _etag)) {
      case Err(:final failure):
        _logger.fine('config refresh failed: ${failure.code}');
        return Result.err(failure);
      case Ok(value: ConfigNotModified()):
        return Result.ok(current);
      case Ok(value: final ConfigFetched fetched):
        final fetchedAt = fetched.config.fetchedAt ?? _clock.now();
        try {
          await _dao.putRemoteConfig(
            RemoteConfigCacheCompanion.insert(
              json: jsonEncode(fetched.json),
              etag: Value(fetched.etag),
              fetchedAt: fetchedAt,
            ),
          );
        } on Object catch (error) {
          // The fetched config still applies for this run.
          _logger.warning('config cache write failed', error: error);
        }
        _etag = fetched.etag;
        _value.set(fetched.config.copyWith(fetchedAt: fetchedAt));
        return Result.ok(current);
    }
  }

  Future<void> _loadCache() async {
    try {
      final row = await _dao.remoteConfig();
      if (row == null) return;
      final json = jsonDecode(row.json) as Map<String, Object?>;
      _value.set(
        RemoteConfig.fromJson(
          json,
          fetchedAt: row.fetchedAt,
          onClamped: (key) => _logger.info('config_value_clamped $key'),
        ),
      );
      _etag = row.etag;
    } on Object catch (error) {
      // Unreadable cache: start from the defaults and fetch without ETag.
      _logger.warning('config cache unreadable', error: error);
    }
  }

  /// Completes [watch] streams.
  Future<void> close() => _value.close();
}
