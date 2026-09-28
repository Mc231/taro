import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taro_core/src/model/credit_balance.dart';
import 'package:taro_core/src/ports/store_purchase.dart';
import 'package:taro_core/src/result/ids.dart';
import 'package:taro_core/src/result/result.dart';

part 'purchase_verifier.freezed.dart';

/// The `status` of a verify response (GLOSSARY §5.1).
enum GrantStatus {
  /// Credits were granted now.
  granted('granted'),

  /// An idempotent replay for the same install.
  alreadyGranted('already_granted'),

  /// `202 pending` (Android): keep the transaction open.
  pending('pending');

  const GrantStatus(this.wire);

  /// The wire value.
  final String wire;
}

/// A `POST /v1/purchases/verify` response (03 §6.2, §6.3).
@freezed
abstract class GrantResult with _$GrantResult {
  /// Creates a grant result.
  const factory GrantResult({
    /// The response status.
    required GrantStatus status,

    /// `creditsGranted` (0 when pending).
    @Default(0) int creditsGranted,

    /// `isFirstPurchase`.
    @Default(false) bool isFirstPurchase,

    /// The Worker purchase ID.
    String? purchaseId,

    /// The product the store says was bought.
    ProductId? productId,

    /// The balance after the grant (absent when pending).
    CreditBalance? balance,
  }) = _GrantResult;
}

/// Worker purchase verification (`POST /v1/purchases/verify`, 02 §5).
///
/// Rejections are failures: `PurchaseFailure` (422) and
/// `PurchaseAlreadyClaimedFailure` (409).
// A port is an interface with swappable adapters, even with one member.
// ignore: one_member_abstracts
abstract interface class PurchaseVerifier {
  /// Verifies [purchase] with the outbox row's [idempotencyKey].
  Future<Result<GrantResult>> verify(
    StorePurchase purchase, {
    required String idempotencyKey,
  });
}
