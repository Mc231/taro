import 'dart:async';

import 'package:drift/drift.dart';
import 'package:taro/data/db/device/device_database.dart';
import 'package:taro/data/db/device/outbox_dao.dart';
import 'package:taro_core/taro_core.dart';

/// [PurchaseOutbox] over the drift `purchase_outbox` table of
/// `taro_device.db` (02 §6.1, 04 §6.2, MO8, AR10).
///
/// The purchase flow calls [enqueue] **before** `POST /v1/purchases/verify`
/// (rule 8), so a kill mid-verify leaves an `awaitingVerification` row that
/// the next launch retries with the same `Idempotency-Key`. The row is
/// device-bound: never exported, kept by "Delete all data". `finished`
/// rows are pruned [kOutboxRetention] (30 days) after they finish, by
/// [markFinished] and [pruneFinished].
///
/// `verification_data` holds the iOS JWS or the Play purchase token. It is
/// never logged; failures are logged by kind only.
final class PurchaseOutboxImpl implements PurchaseOutbox {
  /// Creates the outbox over [dao].
  PurchaseOutboxImpl({required OutboxDao dao, required Logger logger})
    : _dao = dao,
      _logger = logger;

  final OutboxDao _dao;
  final Logger _logger;

  @override
  Future<Result<OutboxEntry>> enqueue(
    StorePurchase purchase, {
    required String idempotencyKey,
    required DateTime now,
  }) => _guard('enqueue', () async {
    final row = await _dao.insertIfAbsent(
      PurchaseOutboxTableCompanion.insert(
        txnKey: purchase.txnKey,
        productId: purchase.productId.value,
        platform: purchase.platform.name,
        transactionId: Value(purchase.transactionId),
        verificationData: Value(switch (purchase.platform) {
          StorePlatform.ios => purchase.signedTransaction,
          StorePlatform.android => purchase.purchaseToken,
        }),
        orderId: Value(purchase.orderId),
        idempotencyKey: idempotencyKey,
        status: OutboxStatus.awaitingVerification.name,
        createdAt: now,
        updatedAt: now,
      ),
    );
    return Result.ok(entryOf(row));
  });

  @override
  Future<Result<List<OutboxEntry>>> pending() => _guard(
    'pending',
    () async => Result.ok([for (final row in await _dao.open()) entryOf(row)]),
  );

  @override
  Future<Result<void>> markGranted(String txnKey, {required DateTime now}) =>
      _status('markGranted', txnKey, OutboxStatus.granted, now);

  @override
  Future<Result<void>> markFinished(String txnKey, {required DateTime now}) =>
      _status('markFinished', txnKey, OutboxStatus.finished, now).then(
        (result) async {
          if (result.isOk) await pruneFinished(now: now);
          return result;
        },
      );

  @override
  Future<Result<void>> markRejected(String txnKey, {required DateTime now}) =>
      _status('markRejected', txnKey, OutboxStatus.rejected, now);

  @override
  Future<Result<void>> recordAttempt(
    String txnKey, {
    required DateTime now,
    String? error,
  }) => _guard(
    'recordAttempt',
    () async => _found(
      await _dao.recordAttempt(txnKey, now: now, error: error),
      'recordAttempt',
    ),
  );

  /// Deletes `finished` rows that finished more than 30 days before [now];
  /// returns how many.
  Future<Result<int>> pruneFinished({required DateTime now}) => _guard(
    'pruneFinished',
    () async => Result.ok(await _dao.pruneFinished(now: now)),
  );

  Future<Result<void>> _status(
    String method,
    String txnKey,
    OutboxStatus status,
    DateTime now,
  ) => _guard(
    method,
    () async =>
        _found(await _dao.setStatus(txnKey, status.name, now: now), method),
  );

  Result<void> _found(bool exists, String method) {
    if (exists) return const Result.ok(null);
    _logger.warning('outbox $method: no such row');
    return const Result.err(Failure.storage());
  }

  Future<Result<T>> _guard<T>(
    String method,
    Future<Result<T>> Function() body,
  ) async {
    try {
      return await body();
    } on Object catch (error) {
      _logger.severe('outbox $method failed: ${error.runtimeType}');
      return const Result.err(Failure.storage());
    }
  }

  /// The entry of [row]. `isRestored` is not stored and reads `false`.
  static OutboxEntry entryOf(PurchaseOutboxRow row) {
    final platform = StorePlatform.values.byName(row.platform);
    return OutboxEntry(
      purchase: StorePurchase(
        txnKey: row.txnKey,
        productId: ProductId(row.productId),
        platform: platform,
        transactionId: row.transactionId,
        signedTransaction: platform == StorePlatform.ios
            ? row.verificationData
            : null,
        purchaseToken: platform == StorePlatform.android
            ? row.verificationData
            : null,
        orderId: row.orderId,
      ),
      idempotencyKey: row.idempotencyKey,
      status: OutboxStatus.values.byName(row.status),
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      attempts: row.attempts,
      lastError: row.lastError,
    );
  }
}
