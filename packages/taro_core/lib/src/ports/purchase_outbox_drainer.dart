import 'package:taro_core/src/ports/purchase_outcome.dart';
import 'package:taro_core/src/ports/sync_reason.dart';
import 'package:taro_core/src/result/result.dart';

/// Retries the open `purchase_outbox` rows: verify → finish (02 §9.2, 04
/// §6.2, rule 8).
///
/// Implemented by the app's `PurchaseCoordinator` (the single purchase
/// path: buy, deliveries, retries and outbox drain); `SyncAccount` calls it
/// on launch, resume and connectivity regained. Rows older than
/// `store.verifyRetryWindowHours` are retried on [SyncReason.launch] only.
// A port is an interface with swappable adapters, even with one member.
// ignore: one_member_abstracts
abstract interface class PurchaseOutboxDrainer {
  /// Verifies every open row once; the outcome per `txnKey`.
  Future<Result<Map<String, PurchaseOutcome>>> drainOutbox({
    required SyncReason reason,
  });
}
