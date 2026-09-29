import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:taro/data/repositories/purchase_verifier_impl.dart';
import 'package:taro_core/taro_core.dart';

import '../../../../../packages/taro_core/test/contracts/contracts.dart';
import '../api/support/scripted_http_adapter.dart';
import '../api/support/worker_client_harness.dart';
import 'support/fake_worker_server.dart';

final class _Harness implements PurchaseVerifierHarness {
  _Harness() : h = RepositoryHarness() {
    subject = PurchaseVerifierImpl(h.client);
  }

  final RepositoryHarness h;
  var _next = 0;

  @override
  late final PurchaseVerifierImpl subject;

  @override
  StorePurchase validPurchase() {
    final id = '200000010000${_next++}';
    return StorePurchase(
      txnKey: id,
      productId: const ProductId('com.vshyrochuk.taro.readings_3'),
      platform: StorePlatform.ios,
      transactionId: id,
    );
  }

  @override
  StorePurchase invalidPurchase() {
    final purchase = validPurchase();
    h.server.invalid.add(purchase.transactionId!);
    return purchase;
  }
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  runPurchaseVerifierContract(_Harness.new);

  group('PurchaseVerifierImpl', () {
    late _Harness harness;
    late FakeWorkerServer server;

    setUp(() {
      harness = _Harness();
      server = harness.h.server;
    });
    tearDown(() => harness.h.close());

    test(
      'sends the platform fields, the outbox key and a transfer token',
      () async {
        const android = StorePurchase(
          txnKey: 'hash',
          productId: ProductId('com.vshyrochuk.taro.readings_10'),
          platform: StorePlatform.android,
          purchaseToken: 'play-token',
          orderId: 'GPA.1',
        );
        expectOk(
          await harness.subject.verify(
            android,
            idempotencyKey: 'outbox-key',
            transferToken: 'tt1.abc',
          ),
        );
        final sent = server.sent('POST /v1/purchases/verify').single;
        expect(sent.header('Idempotency-Key'), 'outbox-key');
        expect(sent.json, {
          'platform': 'android',
          'productId': 'com.vshyrochuk.taro.readings_10',
          'purchaseToken': 'play-token',
          'orderId': 'GPA.1',
          'transferToken': 'tt1.abc',
        });
      },
    );

    test(
      '409 PURCHASE_ALREADY_CLAIMED carries the transfer token (RC84)',
      () async {
        server.onNext(
          'POST /v1/purchases/verify',
          (_) => ScriptedHttpAdapter.response(
            409,
            json: fixture('errors.purchase_already_claimed'),
          ),
        );
        final failure = expectErr(
          await harness.subject.verify(
            harness.validPurchase(),
            idempotencyKey: 'k',
          ),
        );
        expect(failure, isA<PurchaseAlreadyClaimedFailure>());
        final claimed = failure as PurchaseAlreadyClaimedFailure;
        expect(claimed.transferEligible, isTrue);
        expect(claimed.transferToken, startsWith('tt1.'));
      },
    );

    test('202 pending grants nothing and has no balance', () async {
      server.onNext(
        'POST /v1/purchases/verify',
        (_) => ScriptedHttpAdapter.response(
          202,
          json: fixture('purchases.verify.pending.response'),
        ),
      );
      final grant = expectOk(
        await harness.subject.verify(
          harness.validPurchase(),
          idempotencyKey: 'k',
        ),
      );
      expect(grant.status, GrantStatus.pending);
      expect(grant.creditsGranted, 0);
      expect(grant.balance, isNull);
    });
  });
}
