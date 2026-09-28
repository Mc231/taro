import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taro_core/src/model/install_identity.dart';
import 'package:taro_core/src/ports/iap_event.dart';
import 'package:taro_core/src/ports/store_product.dart';
import 'package:taro_core/src/ports/store_purchase.dart';
import 'package:taro_core/src/result/ids.dart';
import 'package:taro_core/src/result/result.dart';

part 'iap_service.freezed.dart';

/// How the store sheet ended (`IapService.buy`).
@freezed
sealed class StoreBuyResult with _$StoreBuyResult {
  /// The store delivered a transaction; it still needs verification.
  const factory StoreBuyResult.purchased(StorePurchase purchase) =
      StoreBuyPurchased;

  /// Awaiting approval (Ask to Buy, deferred payment).
  const factory StoreBuyResult.pending() = StoreBuyPending;

  /// The user cancelled the sheet.
  const factory StoreBuyResult.cancelled() = StoreBuyCancelled;

  /// The non-consumable is already owned.
  const factory StoreBuyResult.alreadyOwned() = StoreBuyAlreadyOwned;
}

/// The store (StoreKit 2 / Play Billing, 02 §5, 04 §6.1).
///
/// Verification is not the adapter's job: consumable transactions reach the
/// `PurchaseCredits` use case (from [buy] or [deliveries]), which verifies
/// with the Worker and calls [finish] only after the grant (rule 8).
abstract interface class IapService {
  /// Localized products for [ids].
  Future<Result<List<StoreProduct>>> products(Set<ProductId> ids);

  /// Opens the store sheet for [id]; [binding] becomes `appAccountToken`
  /// (iOS) or `obfuscatedAccountId` (Android) (MO15).
  Future<Result<StoreBuyResult>> buy(
    ProductId id, {
    required PurchaseBinding binding,
  });

  /// User-initiated "Restore purchases".
  Future<Result<void>> restore();

  /// Finishes (iOS) or acknowledges/consumes (Android) [purchase].
  Future<Result<void>> finish(StorePurchase purchase);

  /// Transactions the store delivered outside [buy] (redelivery on launch,
  /// approved Ask to Buy, restore).
  Stream<StorePurchase> get deliveries;

  /// Store events for the UI.
  Stream<IapEvent> get events;

  /// Products whose purchase is pending approval.
  Set<ProductId> get pending;
}
