import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taro_core/src/model/credit_balance.dart';
import 'package:taro_core/src/model/entitlement.dart';
import 'package:taro_core/src/result/failure.dart';
import 'package:taro_core/src/result/ids.dart';

part 'iap_event.freezed.dart';

/// What a Worker grant gave (`POST /v1/purchases/verify` 200, 03 §6.2).
@freezed
abstract class CreditGrant with _$CreditGrant {
  /// Creates a grant.
  const factory CreditGrant({
    /// `creditsGranted` (the amount lives only in the Worker, RC3).
    required int credits,

    /// Whether this was the install's first purchase.
    required bool isFirstPurchase,

    /// The balance after the grant.
    CreditBalance? balance,
  }) = _CreditGrant;
}

/// Store events for the UI (02 §5).
@freezed
sealed class IapEvent with _$IapEvent {
  /// A purchase completed; [grant] is set for a verified consumable.
  const factory IapEvent.purchased(ProductId productId, {CreditGrant? grant}) =
      IapPurchased;

  /// A purchase awaits approval (Ask to Buy, deferred payment).
  const factory IapEvent.pending(ProductId productId) = IapPending;

  /// The user cancelled the store sheet.
  const factory IapEvent.cancelled() = IapCancelled;

  /// A purchase failed.
  const factory IapEvent.failed(Failure failure) = IapFailed;

  /// A restore finished with these non-consumables owned.
  const factory IapEvent.restored(Set<ProductId> productIds) = IapRestored;

  /// The Remove Banner Ads entitlement changed.
  const factory IapEvent.entitlementChanged(Entitlement entitlement) =
      IapEntitlementChanged;
}
