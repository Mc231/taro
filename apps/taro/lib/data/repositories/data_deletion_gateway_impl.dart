import 'package:taro/data/api/worker_client.dart';
import 'package:taro/data/db/device/cache_dao.dart';
import 'package:taro_core/taro_core.dart';

/// [DataDeletionGateway] over `DELETE /v1/installs/me` (03 §3.6, CS15,
/// RC37) with its retry queue in `sync_state` (`taro_device.db`, 02 §6.1):
/// the queued key survives a kill and is retried by `SyncAccount` (S26
/// `partial`). The idempotency key is not a secret, but it is logged only
/// by its presence.
final class DataDeletionGatewayImpl implements DataDeletionGateway {
  /// Creates the gateway.
  DataDeletionGatewayImpl({
    required WorkerClient client,
    required CacheDao cache,
    required Logger logger,
  }) : _client = client,
       _cache = cache,
       _logger = logger.child('erasure');

  /// The `sync_state` key of the queued erasure's idempotency key
  /// (GLOSSARY §7).
  static const queueKey = 'pending_erasure';

  final WorkerClient _client;
  final CacheDao _cache;
  final Logger _logger;

  @override
  Future<Result<void>> eraseServerData({required String idempotencyKey}) =>
      _client.deleteInstall(idempotencyKey: idempotencyKey);

  @override
  Future<Result<void>> queue({required String idempotencyKey}) =>
      _local(() => _cache.putSyncValue(queueKey, idempotencyKey));

  @override
  Future<Result<String?>> queued() => _local(() => _cache.syncValue(queueKey));

  @override
  Future<Result<void>> clearQueue() =>
      _local(() => _cache.removeSyncValue(queueKey));

  Future<Result<T>> _local<T>(Future<T> Function() body) async {
    try {
      return Result.ok(await body());
    } on Object catch (error) {
      _logger.warning('erasure queue storage failed', error: error.runtimeType);
      return const Result.err(Failure.storage());
    }
  }
}
