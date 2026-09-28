import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taro_core/src/result/failure.dart';

part 'purchase_outcome.freezed.dart';

/// The user-facing result of a purchase (04 §6.2).
@freezed
sealed class PurchaseOutcome with _$PurchaseOutcome {
  /// The Worker granted [credits] (0 for Remove Banner Ads).
  const factory PurchaseOutcome.granted({
    required int credits,
    required bool isFirstPurchase,
  }) = PurchaseGranted;

  /// An idempotent replay: the grant already happened.
  const factory PurchaseOutcome.alreadyGranted() = PurchaseAlreadyGranted;

  /// Awaiting store approval or `202 pending`; nothing is granted yet.
  const factory PurchaseOutcome.pending() = PurchaseOutcomePending;

  /// The user cancelled.
  const factory PurchaseOutcome.cancelled() = PurchaseOutcomeCancelled;

  /// The purchase failed or was rejected (`PurchaseFailure`,
  /// `PurchaseAlreadyClaimedFailure`, ...).
  const factory PurchaseOutcome.failed(Failure failure) = PurchaseOutcomeFailed;

  /// Paid, but the Worker could not be reached yet: "Your purchase is
  /// safe" (never "failed", 02 §9.5 step 6).
  const factory PurchaseOutcome.verificationDelayed() =
      PurchaseVerificationDelayed;

  /// The store or product is unavailable.
  const factory PurchaseOutcome.notAvailable() = PurchaseNotAvailable;

  /// The non-consumable is already owned.
  const factory PurchaseOutcome.alreadyOwned() = PurchaseAlreadyOwned;
}
