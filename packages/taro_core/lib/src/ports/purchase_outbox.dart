import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taro_core/src/ports/store_purchase.dart';
import 'package:taro_core/src/result/result.dart';

part 'purchase_outbox.freezed.dart';

/// `purchase_outbox.status` (02 §6.1).
enum OutboxStatus {
  /// Written before verification; not yet granted.
  awaitingVerification,

  /// The Worker granted it; the store transaction is not finished yet.
  granted,

  /// Granted and finished.
  finished,

  /// The Worker rejected it; it will never be granted.
  rejected,
}

/// One `purchase_outbox` row (`taro_device.db`, never exported).
@freezed
abstract class OutboxEntry with _$OutboxEntry {
  /// Creates an outbox entry.
  const factory OutboxEntry({
    /// The store transaction.
    required StorePurchase purchase,

    /// The `Idempotency-Key`, reused on every retry.
    required String idempotencyKey,

    /// The row status.
    required OutboxStatus status,

    /// When the row was written (UTC).
    required DateTime createdAt,

    /// When it last changed (UTC).
    required DateTime updatedAt,

    /// Verification attempts so far.
    @Default(0) int attempts,

    /// The last failure code, if any.
    String? lastError,
  }) = _OutboxEntry;

  const OutboxEntry._();

  /// The primary key.
  String get txnKey => purchase.txnKey;

  /// Whether the row still needs work (verification or finishing).
  bool get isOpen =>
      status == OutboxStatus.awaitingVerification ||
      status == OutboxStatus.granted;
}

/// The purchase outbox (02 §5, 04 §6.2). The row is written **before**
/// verification so a kill mid-verify is recoverable (rule 8).
abstract interface class PurchaseOutbox {
  /// Inserts an `awaitingVerification` row for [purchase], or returns the
  /// existing row for its `txnKey` unchanged (keeping its idempotency key).
  Future<Result<OutboxEntry>> enqueue(
    StorePurchase purchase, {
    required String idempotencyKey,
    required DateTime now,
  });

  /// Every open row (`awaitingVerification` or `granted`), oldest first.
  Future<Result<List<OutboxEntry>>> pending();

  /// Marks [txnKey] granted.
  Future<Result<void>> markGranted(String txnKey, {required DateTime now});

  /// Marks [txnKey] finished.
  Future<Result<void>> markFinished(String txnKey, {required DateTime now});

  /// Marks [txnKey] rejected.
  Future<Result<void>> markRejected(String txnKey, {required DateTime now});

  /// Counts a verification attempt and records [error] (a failure code).
  Future<Result<void>> recordAttempt(
    String txnKey, {
    required DateTime now,
    String? error,
  });
}
