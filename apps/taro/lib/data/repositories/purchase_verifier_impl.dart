import 'package:taro/data/api/dto/store_dtos.dart';
import 'package:taro/data/api/worker_client.dart';
import 'package:taro_core/taro_core.dart';

/// [PurchaseVerifier] over `POST /v1/purchases/verify` (03 §6.2, §6.3;
/// 04 §6.2).
///
/// Rejections are failures from the error mapper: `422 PURCHASE_INVALID` /
/// `PRODUCT_UNKNOWN` → [PurchaseFailure]; `409 PURCHASE_ALREADY_CLAIMED` →
/// [PurchaseAlreadyClaimedFailure] carrying `transferEligible` and the
/// single-use `transferToken` the "Move readings" support screen shows
/// (RC84). The caller applies the returned balance (`PurchaseCredits`).
final class PurchaseVerifierImpl implements PurchaseVerifier {
  /// Creates the verifier.
  PurchaseVerifierImpl(this._client);

  final WorkerClient _client;

  /// Verifies [purchase] with the outbox row's [idempotencyKey]. A replay
  /// (`already_granted`) grants nothing more, so its `creditsGranted` is 0.
  /// [transferToken] is sent only for a support transfer (RC84).
  @override
  Future<Result<GrantResult>> verify(
    StorePurchase purchase, {
    required String idempotencyKey,
    String? transferToken,
  }) async {
    final result = await _client.verifyPurchase(
      VerifyPurchaseRequestDto.fromDomain(
        purchase,
        transferToken: transferToken,
      ),
      idempotencyKey: idempotencyKey,
    );
    return result.map(
      (grant) => grant.status == GrantStatus.alreadyGranted
          ? grant.copyWith(creditsGranted: 0)
          : grant,
    );
  }
}
