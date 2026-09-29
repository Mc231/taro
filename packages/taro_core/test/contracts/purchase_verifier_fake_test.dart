import 'package:taro_core/taro_core.dart';
import 'package:test/test.dart';

import '../fakes/fakes.dart';
import 'contracts.dart';

final class _Harness implements PurchaseVerifierHarness {
  final FakePurchaseVerifier verifier = FakePurchaseVerifier();
  int _n = 0;

  @override
  PurchaseVerifier get subject => verifier;

  @override
  StorePurchase validPurchase() => aStorePurchase(txnKey: 'valid-${++_n}');

  @override
  StorePurchase invalidPurchase() {
    final p = aStorePurchase(txnKey: 'invalid-${++_n}');
    verifier.rejected.add(p.txnKey);
    return p;
  }
}

void main() {
  runPurchaseVerifierContract(_Harness.new);

  group('FakePurchaseVerifier hooks', () {
    test('Remove Banner Ads is unknown to the Worker', () async {
      final verifier = FakePurchaseVerifier();
      final failure = expectErr(
        await verifier.verify(
          aStorePurchase(productId: TaroProducts.removeAds.id),
          idempotencyKey: 'k',
        ),
      );
      expect(failure.code, 'PRODUCT_UNKNOWN');
    });

    test('scripted results, onVerify and failNext', () async {
      final seen = <String>[];
      final verifier = FakePurchaseVerifier()
        ..scripted.add(const GrantResult(status: GrantStatus.pending))
        ..onVerify = ((_, key) => seen.add(key));
      final pending = expectOk(
        await verifier.verify(aStorePurchase(), idempotencyKey: 'a'),
      );
      expect(pending.status, GrantStatus.pending);
      verifier.failNext(const Failure.network());
      expect(
        (await verifier.verify(
          aStorePurchase(),
          idempotencyKey: 'b',
          transferToken: 'tt1.x',
        )).isErr,
        isTrue,
      );
      expect(seen, ['a', 'b']);
      expect(verifier.verifications, hasLength(2));
      expect(verifier.transferTokens, [null, 'tt1.x']);
    });

    test('grants bump paid credits and the ledger version', () async {
      final verifier = FakePurchaseVerifier(
        balance: aCreditBalance().withPaid(1).withLedgerVersion(10).build(),
      );
      final grant = expectOk(
        await verifier.verify(
          aStorePurchase(productId: TaroProducts.readings10.id),
          idempotencyKey: 'k',
        ),
      );
      expect(grant.creditsGranted, 10);
      expect(grant.balance?.paid, 11);
      expect(grant.balance?.ledgerVersion, 11);
    });
  });
}
