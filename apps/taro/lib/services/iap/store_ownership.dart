import 'package:taro_core/taro_core.dart';

/// The silent store ownership query of the IAP adapter (04 §6.1: internal
/// to `StoreIapService`, not part of the `IapService` port).
///
/// Reads StoreKit 2 current entitlements (iOS) or Play `queryPurchases`
/// (Android) without any UI, unlike the user-initiated
/// `IapService.restore`.
// A seam with swappable implementations, even with one member.
// ignore: one_member_abstracts
abstract interface class StoreOwnership {
  /// The non-consumables the store says this account owns now. An `Err`
  /// means the store did not answer, which never revokes anything (MO7).
  Future<Result<Set<ProductId>>> queryOwnership();
}
