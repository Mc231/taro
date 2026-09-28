import 'package:taro_core/src/result/result.dart';

/// Server-side erasure (`DELETE /v1/installs/me`, CS15, RC37) and its
/// retry queue (`sync_state`, 02 §6.1).
abstract interface class DataDeletionGateway {
  /// Calls `DELETE /v1/installs/me` with [idempotencyKey].
  Future<Result<void>> eraseServerData({required String idempotencyKey});

  /// Queues an erasure with [idempotencyKey] for retry (S26 `partial`).
  Future<Result<void>> queue({required String idempotencyKey});

  /// The queued erasure's idempotency key, if any.
  Future<Result<String?>> queued();

  /// Clears the queue after a successful erasure.
  Future<Result<void>> clearQueue();
}
