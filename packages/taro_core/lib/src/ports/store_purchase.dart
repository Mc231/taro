import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taro_core/src/result/ids.dart';

part 'store_purchase.freezed.dart';

/// The store platform (`platform` on the verify request, 03 §6.2).
enum StorePlatform {
  /// App Store.
  ios,

  /// Google Play.
  android,
}

/// A delivered store transaction to verify and finish (04 §6.1).
///
/// Adapter-neutral: everything `POST /v1/purchases/verify` needs, plus the
/// outbox key.
@freezed
abstract class StorePurchase with _$StorePurchase {
  /// Creates a store purchase.
  const factory StorePurchase({
    /// The outbox primary key: `transactionId ?? sha256(purchaseToken)`.
    required String txnKey,

    /// The fully qualified product ID.
    required ProductId productId,

    /// Which store delivered it.
    required StorePlatform platform,

    /// StoreKit transaction ID (iOS).
    String? transactionId,

    /// StoreKit JWS `signedTransaction` (iOS, optional on the wire).
    String? signedTransaction,

    /// Play purchase token (Android). Never logged.
    String? purchaseToken,

    /// Play order ID (Android).
    String? orderId,

    /// Whether the store redelivered it from a restore.
    @Default(false) bool isRestored,
  }) = _StorePurchase;
}
