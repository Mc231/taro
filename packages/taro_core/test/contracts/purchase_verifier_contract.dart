import 'package:taro_core/taro_core.dart';
import 'package:test/test.dart';

import 'contract_support.dart';

/// What the `PurchaseVerifier` contract needs besides the port.
abstract interface class PurchaseVerifierHarness {
  /// The verifier under test, talking to a Worker that grants valid
  /// consumable transactions.
  PurchaseVerifier get subject;

  /// A valid, never verified consumable transaction (a new one per call).
  StorePurchase validPurchase();

  /// A transaction the Worker rejects as `PURCHASE_INVALID`.
  StorePurchase invalidPurchase();
}

/// The `PurchaseVerifier` contract (`POST /v1/purchases/verify`, 03 §6.2,
/// 04 §6.2).
void runPurchaseVerifierContract(PurchaseVerifierHarness Function() create) {
  group('PurchaseVerifier contract', () {
    late PurchaseVerifierHarness harness;
    late PurchaseVerifier verifier;

    setUp(() {
      harness = create();
      verifier = harness.subject;
    });

    test('grants a valid purchase with the new balance', () async {
      final purchase = harness.validPurchase();
      final grant = expectOk(
        await verifier.verify(purchase, idempotencyKey: 'key-1'),
      );
      expect(grant.status, GrantStatus.granted);
      expect(grant.creditsGranted, greaterThan(0));
      expect(grant.productId, purchase.productId);
      expect(grant.balance, isNotNull);
    });

    test('a replay is alreadyGranted and grants nothing more', () async {
      final purchase = harness.validPurchase();
      final first = expectOk(
        await verifier.verify(purchase, idempotencyKey: 'key-1'),
      );
      final replay = expectOk(
        await verifier.verify(purchase, idempotencyKey: 'key-1'),
      );
      expect(replay.status, GrantStatus.alreadyGranted);
      expect(replay.creditsGranted, 0);
      expect(replay.balance?.paid, first.balance?.paid);
    });

    test('only the first purchase is the first purchase', () async {
      final a = expectOk(
        await verifier.verify(harness.validPurchase(), idempotencyKey: 'a'),
      );
      final b = expectOk(
        await verifier.verify(harness.validPurchase(), idempotencyKey: 'b'),
      );
      expect(a.isFirstPurchase, isTrue);
      expect(b.isFirstPurchase, isFalse);
    });

    test('an invalid purchase is a PurchaseFailure', () async {
      final failure = expectErr(
        await verifier.verify(harness.invalidPurchase(), idempotencyKey: 'x'),
      );
      expect(failure, isA<PurchaseFailure>());
      expect(failure.code, 'PURCHASE_INVALID');
    });
  });
}
