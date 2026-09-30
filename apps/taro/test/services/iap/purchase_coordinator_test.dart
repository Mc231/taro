import 'dart:async';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:taro/services/iap/pending_purchase_tracker.dart';
import 'package:taro/services/iap/purchase_coordinator.dart';
import 'package:taro/services/iap/remove_ads_entitlement.dart';
import 'package:taro/services/iap/store_iap_service.dart';
import 'package:taro_core/taro_core.dart';

import '../../../../../packages/taro_core/test/contracts/contract_support.dart';
import '../../../../../packages/taro_core/test/fakes/fakes.dart';
import 'support/fake_in_app_purchase_platform.dart';
import 'support/iap_test_support.dart';

final ProductId _pack = TaroProducts.readings3.id;
final ProductId _packM = TaroProducts.readings10.id;
final ProductId _removeAds = TaroProducts.removeAds.id;

/// Everything a coordinator needs, as fakes.
final class _Harness {
  _Harness({
    IapService? iap,
    this.connectivity,
    StoreProduct? Function(ProductId id)? priceOf,
  }) : iap = iap ?? FakeIapService() {
    tracker = PendingPurchaseTracker(
      clock: clock,
      holdMinutes: () => config.current.storePendingHoldMinutes,
    );
    removeAds = RemoveAdsEntitlement(
      cache: cache,
      ownership: FakeStoreOwnership(),
      clock: clock,
      analytics: analytics,
      logger: logger,
      delay: ManualDelay().call,
    );
    for (final fake in <FakeBehaviour?>[outbox, verifier, fakeIap]) {
      fake?.recorder = recorder;
    }
    coordinator = PurchaseCoordinator(
      iap: this.iap,
      verifier: verifier,
      outbox: outbox,
      balance: balance,
      install: install,
      config: config,
      removeAds: removeAds,
      tracker: tracker,
      analytics: analytics,
      ids: ids,
      clock: clock,
      logger: logger,
      connectivity: connectivity,
      priceOf: priceOf ?? (id) => aStoreProduct(TaroProducts.byId(id)!),
      delay: delay.call,
    );
    coordinator.updates.listen(updates.add);
  }

  final IapService iap;
  final ConnectivityMonitor? connectivity;
  final FakePurchaseVerifier verifier = FakePurchaseVerifier();
  final FakePurchaseOutbox outbox = FakePurchaseOutbox();
  final FakeBalanceRepository balance = FakeBalanceRepository();
  final FakeInstallRepository install = FakeInstallRepository();
  final FakeRemoteConfigRepository config = FakeRemoteConfigRepository();
  final FakeEntitlementCache cache = FakeEntitlementCache();
  final FakeAnalyticsService analytics = FakeAnalyticsService();
  final SequentialIdGenerator ids = SequentialIdGenerator('idem-');
  final FakeClock clock = FakeClock();
  final CapturingLogger logger = CapturingLogger();
  final ManualDelay delay = ManualDelay();
  final CallRecorder recorder = CallRecorder();
  final List<PurchaseUpdate> updates = [];
  late final PendingPurchaseTracker tracker;
  late final RemoveAdsEntitlement removeAds;
  late final PurchaseCoordinator coordinator;

  FakeIapService? get fakeIap =>
      iap is FakeIapService ? iap as FakeIapService : null;

  FakeIapService get store => fakeIap!;

  List<String> get eventNames => analytics.eventNames;

  T event<T extends TaroAnalyticsEvent>() =>
      analytics.events.whereType<T>().single;

  OutboxEntry row(String txnKey) => outbox.rows[txnKey]!;
}

OutboxEntry _entry(
  StorePurchase purchase, {
  OutboxStatus status = OutboxStatus.awaitingVerification,
  DateTime? createdAt,
  String key = 'idem-old',
}) => OutboxEntry(
  purchase: purchase,
  idempotencyKey: key,
  status: status,
  createdAt: createdAt ?? kTestNow,
  updatedAt: createdAt ?? kTestNow,
);

void main() {
  group('04 §15 Unit — PurchaseCoordinator', () {
    test('happy path: outbox → verify → balance → finish → finished', () async {
      final h = _Harness();
      final purchase = aStorePurchase();
      final outcome = await h.coordinator.process(purchase);

      expect(
        outcome,
        const PurchaseOutcome.granted(credits: 3, isFirstPurchase: true),
      );
      expect(h.recorder.calls, [
        'PurchaseOutbox.enqueue',
        'PurchaseVerifier.verify',
        'PurchaseOutbox.markGranted',
        'IapService.finish',
        'PurchaseOutbox.markFinished',
      ]);
      expect(h.row('txn-1').status, OutboxStatus.finished);
      expect(h.verifier.verifications.single.$2, 'idem-1');
      expect(h.balance.applied.single.paid, 3);
      expect(h.store.finished, ['txn-1']);
      await settle();
      expect(h.updates, [
        PurchaseUpdate(
          _pack,
          const PurchaseOutcome.granted(credits: 3, isFirstPurchase: true),
        ),
      ]);
      expect(h.eventNames, ['iap_verify_result', 'purchase_completed']);
      expect(h.event<PurchaseCompletedEvent>().parameters, {
        'product': 'pack_s',
        'value': 2990000,
        'currency': 'USD',
        'credits': 3,
        'is_first_purchase': true,
      });
      expect(h.event<IapVerifyResultEvent>().parameters, {
        'product': 'pack_s',
        'status': 'granted',
        'ms': 0,
        'attempt': 1,
      });
    });

    test(
      'store deliveries are handled from construction, before any UI',
      () async {
        final h = _Harness();
        final approved = h.store.approvePending(_pack);
        await settle();
        await settle();
        expect(h.store.finished, [approved.txnKey]);
        await settle();
        expect(h.updates.single.outcome, isA<PurchaseGranted>());
      },
    );

    test(
      'pending → purchased: tracker, no Worker call, then granted',
      () async {
        final h = _Harness();
        h.store.emitPending(_pack);
        await settle();
        expect(h.coordinator.isPending(_pack), isTrue);
        expect(h.coordinator.isPending(_packM), isFalse);
        expect(h.verifier.calls, isEmpty);
        expect(h.eventNames, ['purchase_pending']);
        // A repeated pending event is not logged twice.
        h.store.emitPending(_pack);
        await settle();
        expect(h.eventNames, ['purchase_pending']);

        h.store.approvePending(_pack);
        await settle();
        await settle();
        expect(h.coordinator.isPending(_pack), isFalse);
        await settle();
        expect(h.updates.single.outcome, isA<PurchaseGranted>());
      },
    );

    test('pending → silent: lapses after store.pendingHoldMinutes', () async {
      final h = _Harness();
      h.store.emitPending(_pack);
      await settle();
      expect(
        expectOk(await h.coordinator.buy(_pack)),
        const PurchaseOutcome.pending(),
      );
      expect(h.store.callCount('buy'), 0, reason: 'button disabled');
      h.clock.advance(const Duration(minutes: 30));
      expect(h.coordinator.isPending(_pack), isFalse);
      h.store.pending.clear();
      final outcome = expectOk(await h.coordinator.buy(_pack));
      expect(outcome, isA<PurchaseGranted>());
    });

    test('duplicate delivery in flight: one verify, one finish', () async {
      final h = _Harness();
      final purchase = aStorePurchase();
      final results = await Future.wait([
        h.coordinator.process(purchase),
        h.coordinator.process(purchase),
      ]);
      expect(results[0], results[1]);
      expect(h.verifier.callCount('verify'), 1);
      expect(h.store.finished, ['txn-1']);
      await settle();
      expect(h.updates, hasLength(1));
    });

    test(
      'redelivery after a crash reuses the outbox idempotency key',
      () async {
        final h = _Harness();
        final purchase = aStorePurchase();
        h.outbox.seed(_entry(purchase));
        h.store.redeliver(purchase);
        await settle();
        await settle();
        expect(h.verifier.verifications.single.$2, 'idem-old');
        expect(h.row('txn-1').status, OutboxStatus.finished);
      },
    );

    test(
      'crash between grant and finish: finished without a Worker call',
      () async {
        final h = _Harness();
        final purchase = aStorePurchase();
        h.outbox.seed(_entry(purchase, status: OutboxStatus.granted));
        final outcome = await h.coordinator.process(purchase);
        expect(outcome, const PurchaseOutcome.alreadyGranted());
        expect(h.verifier.calls, isEmpty);
        expect(h.row('txn-1').status, OutboxStatus.finished);
        expect(h.eventNames, isNot(contains('purchase_completed')));
      },
    );

    test(
      'a finished row redelivered is finished again, no Worker call',
      () async {
        final h = _Harness();
        final purchase = aStorePurchase();
        h.outbox.seed(_entry(purchase, status: OutboxStatus.finished));
        expect(
          await h.coordinator.process(purchase),
          const PurchaseOutcome.alreadyGranted(),
        );
        expect(h.store.finished, ['txn-1']);
        expect(h.verifier.calls, isEmpty);
      },
    );

    test('verify 5xx → delayed → backoff retry → granted', () async {
      final h = _Harness();
      h.verifier
        ..failNext(const Failure.server(status: 500), on: 'verify')
        ..failNext(const Failure.network(), on: 'verify');
      final outcome = await h.coordinator.process(aStorePurchase());

      expect(outcome, const PurchaseOutcome.verificationDelayed());
      await settle();
      expect(h.updates.single.verificationDeferred, isTrue);
      expect(h.store.finished, isEmpty);
      expect(h.row('txn-1').status, OutboxStatus.awaitingVerification);
      expect(h.row('txn-1').attempts, 1);
      expect(h.row('txn-1').lastError, 'INTERNAL');
      expect(h.delay.waiting, [const Duration(seconds: 2)]);

      h.delay.fire();
      await settle();
      await settle();
      expect(h.verifier.callCount('verify'), 2);
      expect(h.delay.waiting, [const Duration(seconds: 10)]);
      expect(h.store.finished, isEmpty);

      h.delay.fire();
      await settle();
      await settle();
      expect(h.store.finished, ['txn-1']);
      expect(h.updates.last.outcome, isA<PurchaseGranted>());
      expect(h.delay.waiting, isEmpty);
      expect(
        h.eventNames.where((e) => e == 'purchase_verification_delayed'),
        hasLength(1),
      );
      expect(h.event<PurchaseCompletedEvent>().parameters['credits'], 3);
      final attempts = [
        for (final e in h.analytics.events.whereType<IapVerifyResultEvent>())
          e.parameters['attempt'],
      ];
      expect(attempts, [1, 2, 3]);
    });

    test('backoff is 2 s, 10 s, 60 s, then only drains', () async {
      final h = _Harness();
      for (var i = 0; i < 4; i++) {
        h.verifier.failNext(const Failure.timeout(), on: 'verify');
      }
      await h.coordinator.process(aStorePurchase());
      for (var i = 0; i < 3; i++) {
        h.delay.fire();
        await settle();
        await settle();
      }
      expect(h.delay.requested, kVerifyRetryBackoff);
      expect(h.delay.waiting, isEmpty);
      expect(h.verifier.callCount('verify'), 4);
      expect(h.store.finished, isEmpty);
      // Resume drain picks it up.
      final drained = expectOk(
        await h.coordinator.drainOutbox(reason: SyncReason.resume),
      );
      expect(drained['txn-1'], isA<PurchaseGranted>());
      expect(h.store.finished, ['txn-1']);
    });

    for (final failure in [
      const Failure.sessionExpired(),
      const Failure.attestation(kind: AttestationFailureKind.rejected),
      const Failure.network(),
      const Failure.timeout(),
      const Failure.server(status: 503),
    ]) {
      test('${failure.code} never finishes', () async {
        final h = _Harness();
        h.verifier.failNext(failure, on: 'verify');
        expect(
          await h.coordinator.process(aStorePurchase()),
          const PurchaseOutcome.verificationDelayed(),
        );
        expect(h.store.callCount('finish'), 0);
        expect(h.row('txn-1').isOpen, isTrue);
      });
    }

    test('422 PURCHASE_INVALID finishes and rejects', () async {
      final h = _Harness();
      h.verifier.rejected.add('txn-1');
      final outcome = await h.coordinator.process(aStorePurchase());
      expect(
        outcome,
        const PurchaseOutcome.failed(
          Failure.purchase(wireCode: 'PURCHASE_INVALID'),
        ),
      );
      await settle();
      expect(h.updates.single.isSandboxCap, isFalse);
      expect(h.store.finished, ['txn-1']);
      expect(h.row('txn-1').status, OutboxStatus.rejected);
      expect(h.event<PurchaseFailedEvent>().parameters, {
        'product': 'pack_s',
        'error': 'verify_rejected',
      });
      expect(
        h.logger.logged('purchase rejected', level: LogLevel.warning),
        isTrue,
      );
    });

    test('422 sandbox_cap finishes with a neutral message (RC63)', () async {
      final h = _Harness();
      h.verifier.failNext(
        const Failure.purchase(
          wireCode: 'PURCHASE_INVALID',
          reason: kSandboxCapReason,
        ),
        on: 'verify',
      );
      await h.coordinator.process(aStorePurchase());
      await settle();
      expect(h.updates.single.isSandboxCap, isTrue);
      expect(h.store.finished, ['txn-1']);
      expect(h.row('txn-1').status, OutboxStatus.rejected);
      expect(h.logger.logged('sandbox cap', level: LogLevel.info), isTrue);
      expect(h.logger.logged('purchase rejected'), isFalse);
    });

    test('409 PURCHASE_ALREADY_CLAIMED does not finish (RC84)', () async {
      final h = _Harness();
      const claimed = Failure.purchaseAlreadyClaimed(
        transferEligible: true,
        transferToken: 'tt',
      );
      h.verifier.failNext(claimed, on: 'verify');
      final outcome = await h.coordinator.process(aStorePurchase());
      expect(outcome, const PurchaseOutcome.failed(claimed));
      expect(h.store.callCount('finish'), 0);
      expect(h.row('txn-1').status, OutboxStatus.rejected);
      expect(
        h.event<IapVerifyResultEvent>().parameters['status'],
        'already_claimed',
      );
    });

    test('a rejected row redelivered is verified again', () async {
      final h = _Harness();
      final purchase = aStorePurchase();
      h.outbox.seed(_entry(purchase, status: OutboxStatus.rejected));
      h.verifier.rejected.add('txn-1');
      await h.coordinator.process(purchase);
      expect(h.verifier.verifications.single.$2, 'idem-old');
      expect(h.store.finished, ['txn-1']);
    });

    test('already_granted does not re-log revenue', () async {
      final h = _Harness();
      h.verifier.granted.add('txn-1');
      final outcome = await h.coordinator.process(aStorePurchase());
      expect(outcome, const PurchaseOutcome.alreadyGranted());
      expect(h.store.finished, ['txn-1']);
      expect(h.eventNames, ['iap_verify_result']);
      expect(
        h.event<IapVerifyResultEvent>().parameters['status'],
        'already_granted',
      );
      expect(h.balance.applied, hasLength(1));
    });

    test('202 pending keeps the transaction open and tracked', () async {
      final h = _Harness();
      h.verifier.scripted.add(const GrantResult(status: GrantStatus.pending));
      final outcome = await h.coordinator.process(
        aStorePurchase(platform: StorePlatform.android),
      );
      expect(outcome, const PurchaseOutcome.pending());
      expect(h.store.callCount('finish'), 0);
      expect(h.row('txn-1').isOpen, isTrue);
      expect(h.coordinator.isPending(_pack), isTrue);
      expect(h.delay.waiting, isEmpty);
    });

    test('a grant without a balance still finishes', () async {
      final h = _Harness();
      h.verifier.scripted.add(
        const GrantResult(status: GrantStatus.granted, creditsGranted: 3),
      );
      await h.coordinator.process(aStorePurchase());
      expect(h.balance.applied, isEmpty);
      expect(h.store.finished, ['txn-1']);
    });

    test(
      'a failed finish after the grant is retried by the next drain',
      () async {
        final h = _Harness();
        h.store.failNext(const Failure.purchase(wireCode: 'X'), on: 'finish');
        await h.coordinator.process(aStorePurchase());
        expect(h.row('txn-1').status, OutboxStatus.granted);
        expect(h.logger.logged('finish deferred'), isTrue);
        final drained = expectOk(
          await h.coordinator.drainOutbox(reason: SyncReason.resume),
        );
        expect(drained['txn-1'], const PurchaseOutcome.alreadyGranted());
        expect(h.row('txn-1').status, OutboxStatus.finished);
        expect(h.verifier.callCount('verify'), 1);
      },
    );

    test('an outbox write failure never verifies', () async {
      final h = _Harness();
      h.outbox.failNext(const Failure.storage(), on: 'enqueue');
      expect(
        await h.coordinator.process(aStorePurchase()),
        const PurchaseOutcome.verificationDelayed(),
      );
      expect(h.verifier.calls, isEmpty);
      expect(h.store.calls, isNot(contains('finish')));
      expect(h.logger.logged('outbox write failed'), isTrue);
    });

    test('Android consumes only after the grant (real adapter)', () async {
      final platform = FakePlayPlatform();
      final addition = FakePlayAddition(platform);
      final iap = StoreIapService(
        platform: platform,
        store: StorePlatform.android,
        logger: CapturingLogger(),
        androidAddition: addition,
      );
      final h = _Harness(iap: iap, priceOf: iap.cachedProduct);
      h.verifier.failNext(const Failure.network(), on: 'verify');
      final first = expectOk(await h.coordinator.buy(_pack));
      expect(first, const PurchaseOutcome.verificationDelayed());
      expect(addition.consumed, isEmpty);
      expect(platform.completed, isEmpty);
      expect(platform.params.single.applicationUserName, isNull);

      h.delay.fire();
      await settle();
      await settle();
      await settle();
      expect(addition.consumed, ['token-1']);
      expect(platform.unfinished, isEmpty);
      expect(h.outbox.rows.values.single.status, OutboxStatus.finished);
      expect(h.event<PurchaseCompletedEvent>().parameters['value'], 2990000);
    });

    test(
      'non-consumable: entitlement cached, finished, no Worker call',
      () async {
        final h = _Harness();
        final bought = expectOk(await h.coordinator.buy(_removeAds));
        expect(
          bought,
          const PurchaseOutcome.granted(credits: 0, isFirstPurchase: false),
        );
        expect(h.verifier.calls, isEmpty);
        expect(h.outbox.rows, isEmpty);
        expect(h.removeAds.removesAds, isTrue);
        expect(h.cache.entitlement.removeAds, EntitlementState.owned);
        expect(h.store.finished, hasLength(1));
        expect(h.eventNames, ['remove_ads_changed', 'purchase_completed']);
        expect(h.store.bindings.single, h.install.identity!.purchaseBinding);
      },
    );

    test('restored Remove Ads is alreadyOwned, no revenue event', () async {
      final h = _Harness()..store.own(_removeAds);
      expectOk(await h.coordinator.restore());
      await settle();
      await settle();
      expect(h.updates.single.outcome, const PurchaseOutcome.alreadyOwned());
      expect(h.removeAds.removesAds, isTrue);
      expect(h.eventNames, containsAllInOrder(['remove_ads_changed']));
      expect(h.eventNames, isNot(contains('purchase_completed')));
      expect(
        h.event<RestoreCompletedEvent>().parameters,
        {'result': 'remove_ads'},
      );
    });

    test('a restore batch without Remove Ads reports nothing', () async {
      final h = _Harness();
      expectOk(await h.coordinator.restore());
      await settle();
      expect(h.event<RestoreCompletedEvent>().parameters, {
        'result': 'nothing',
      });
    });

    test(
      'a restore batch without Remove Ads revokes a cached owner (MO7)',
      () async {
        final platform = FakeInAppPurchasePlatform();
        final iap = StoreIapService(
          platform: platform,
          store: StorePlatform.ios,
          logger: CapturingLogger(),
          delay: (_) => Future<void>.delayed(Duration.zero),
        );
        final h = _Harness(iap: iap);
        await h.removeAds.markOwned(source: RemoveAdsSource.purchase);
        final entitlement = RemoveAdsEntitlement(
          cache: h.cache,
          ownership: iap,
          clock: h.clock,
          analytics: h.analytics,
          logger: h.logger,
        );
        expect(entitlement.removesAds, isTrue);
        await entitlement.refresh();
        expect(entitlement.removesAds, isFalse);
        expect(h.cache.entitlement.removeAds, EntitlementState.notOwned);
      },
    );

    test('a silent store keeps the cached owner (MO7)', () async {
      final h = _Harness(iap: FakeIapService());
      await h.removeAds.markOwned(source: RemoveAdsSource.purchase);
      final silent = FakeStoreOwnership()
        ..answer = const Result.err(Failure.network());
      final entitlement = RemoveAdsEntitlement(
        cache: h.cache,
        ownership: silent,
        clock: h.clock,
        analytics: h.analytics,
        logger: h.logger,
      );
      await entitlement.refresh();
      expect(entitlement.removesAds, isTrue);
    });
  });

  group('buy', () {
    test('binds the purchase to the install (RC9)', () async {
      final h = _Harness();
      await h.coordinator.buy(_pack);
      expect(
        h.store.bindings.single.appleAccountToken,
        '5b0d6c1e-3333-5444-8555-666677778888',
      );
    });

    test('an unregistered install buys with an empty binding', () async {
      final h = _Harness();
      h.install.identity = anInstallIdentity(registered: false);
      await h.coordinator.buy(_pack);
      expect(h.store.bindings.single, const PurchaseBinding());
    });

    test('an install failure is returned', () async {
      final h = _Harness();
      h.install.failNext(const Failure.storage(), on: 'getOrCreate');
      expect(
        expectErr(await h.coordinator.buy(_pack)),
        const Failure.storage(),
      );
      expect(h.store.callCount('buy'), 0);
    });

    test('cancelled (result or failure) settles and logs', () async {
      final h = _Harness();
      h.store
        ..nextBuy(const StoreBuyResult.cancelled())
        ..failNext(const Failure.purchaseCancelled(), on: 'buy');
      expect(
        expectOk(await h.coordinator.buy(_pack)),
        const PurchaseOutcome.cancelled(),
      );
      expect(
        expectOk(await h.coordinator.buy(_pack)),
        const PurchaseOutcome.cancelled(),
      );
      expect(h.eventNames, ['purchase_cancelled', 'purchase_cancelled']);
    });

    test('store errors and RC66 blocks are returned and logged', () async {
      final h = _Harness();
      const blocked = Failure.purchasesBlocked(
        reason: PurchasesBlockedReason.refundDebt,
      );
      h.store.failNext(blocked, on: 'buy');
      expect(expectErr(await h.coordinator.buy(_pack)), blocked);
      expect(
        h.event<PurchaseFailedEvent>().parameters['error'],
        'purchases_blocked',
      );
    });

    test('store pending marks the tracker', () async {
      final h = _Harness();
      h.store.nextBuy(const StoreBuyResult.pending());
      expect(
        expectOk(await h.coordinator.buy(_pack)),
        const PurchaseOutcome.pending(),
      );
      expect(h.coordinator.isPending(_pack), isTrue);
      expect(h.eventNames, ['purchase_pending']);
    });

    test('alreadyOwned Remove Ads is cached', () async {
      final h = _Harness()..store.own(_removeAds);
      expect(
        expectOk(await h.coordinator.buy(_removeAds)),
        const PurchaseOutcome.alreadyOwned(),
      );
      expect(h.removeAds.removesAds, isTrue);
      h.store.nextBuy(const StoreBuyResult.alreadyOwned());
      final before = h.cache.callCount('write');
      expectOk(await h.coordinator.buy(_pack));
      expect(h.cache.callCount('write'), before);
    });

    test('a product outside the catalogue goes to the Worker', () async {
      final h = _Harness();
      final unknown = aStorePurchase(
        txnKey: 'odd',
      ).copyWith(productId: const ProductId('com.example.odd'));
      final outcome = await h.coordinator.process(unknown);
      expect(
        outcome,
        const PurchaseOutcome.failed(
          Failure.purchase(wireCode: 'PRODUCT_UNKNOWN'),
        ),
      );
      expect(h.store.finished, ['odd']);
      expect(h.event<PurchaseFailedEvent>().parameters['product'], 'pack_s');
    });

    test('without a listing the revenue value is 0 / other', () async {
      final h = _Harness(priceOf: (_) => null);
      await h.coordinator.process(aStorePurchase());
      expect(
        h.event<PurchaseCompletedEvent>().parameters,
        containsPair('value', 0),
      );
      expect(
        h.event<PurchaseCompletedEvent>().parameters,
        containsPair('currency', 'other'),
      );
    });
  });

  group('drainOutbox', () {
    test('verifies every open row, oldest first', () async {
      final h = _Harness();
      h.outbox
        ..seed(_entry(aStorePurchase(txnKey: 'a')))
        ..seed(_entry(aStorePurchase(txnKey: 'b'), key: 'idem-b'));
      final drained = expectOk(
        await h.coordinator.drainOutbox(reason: SyncReason.launch),
      );
      expect(drained.keys, ['a', 'b']);
      expect(h.store.finished, ['a', 'b']);
      expect(h.delay.waiting, isEmpty, reason: 'drains do not start backoff');
    });

    test('past store.verifyRetryWindowHours: launch only, iap_verify_stuck '
        'once', () async {
      final h = _Harness();
      final old = aStorePurchase(txnKey: 'old');
      h.outbox.seed(
        _entry(old, createdAt: kTestNow.subtract(const Duration(hours: 73))),
      );
      h.verifier.failNext(const Failure.network(), on: 'verify');

      final resumed = expectOk(
        await h.coordinator.drainOutbox(reason: SyncReason.resume),
      );
      expect(resumed, isEmpty);
      expect(h.verifier.calls, isEmpty);
      expect(h.event<IapVerifyStuckEvent>().parameters, {
        'product': 'pack_s',
        'hours': 73,
      });
      expect(h.logger.logged('iap_verify_stuck'), isTrue);

      final launched = expectOk(
        await h.coordinator.drainOutbox(reason: SyncReason.launch),
      );
      expect(launched['old'], const PurchaseOutcome.verificationDelayed());
      expect(h.eventNames.where((e) => e == 'iap_verify_stuck'), hasLength(1));
      expectOk(await h.coordinator.drainOutbox(reason: SyncReason.launch));
      expect(h.store.finished, ['old']);
    });

    test('the retry window follows remote config', () async {
      final h = _Harness();
      h.config.current = RemoteConfig.defaults.copyWith(
        storeVerifyRetryWindowHours: 24,
      );
      h.outbox.seed(
        _entry(
          aStorePurchase(),
          createdAt: kTestNow.subtract(const Duration(hours: 25)),
        ),
      );
      expectOk(await h.coordinator.drainOutbox(reason: SyncReason.resume));
      expect(h.verifier.calls, isEmpty);
    });

    test('backoff stops once the row is past the window', () async {
      final h = _Harness();
      h.verifier.failNext(const Failure.network(), on: 'verify');
      await h.coordinator.process(aStorePurchase());
      h.clock.advance(const Duration(hours: 80));
      h.delay.fire();
      await settle();
      await settle();
      expect(h.verifier.callCount('verify'), 1);
      expect(h.delay.waiting, isEmpty);
    });

    test('backoff stops when the row was settled elsewhere', () async {
      final h = _Harness();
      h.verifier.failNext(const Failure.network(), on: 'verify');
      await h.coordinator.process(aStorePurchase());
      expectOk(await h.coordinator.drainOutbox(reason: SyncReason.resume));
      h.delay.fire();
      await settle();
      expect(h.verifier.callCount('verify'), 2);
    });

    test('backoff stops when the outbox cannot be read', () async {
      final h = _Harness();
      h.verifier.failNext(const Failure.network(), on: 'verify');
      await h.coordinator.process(aStorePurchase());
      h.outbox.failNext(const Failure.storage(), on: 'pending');
      h.delay.fire();
      await settle();
      await settle();
      expect(h.verifier.callCount('verify'), 1);
      expect(h.delay.waiting, isEmpty);
    });

    test('an outbox read failure is returned', () async {
      final h = _Harness();
      h.outbox.failNext(const Failure.storage(), on: 'pending');
      expect(
        expectErr(await h.coordinator.drainOutbox(reason: SyncReason.resume)),
        const Failure.storage(),
      );
    });

    test('connectivity regained drains the outbox', () async {
      final connectivity = FakeConnectivityMonitor(online: false);
      final h = _Harness(connectivity: connectivity);
      h.outbox.seed(_entry(aStorePurchase()));
      connectivity.setOnline(online: true);
      await settle();
      await settle();
      expect(h.store.finished, ['txn-1']);
      connectivity.setOnline(online: false);
      await settle();
      expect(h.verifier.callCount('verify'), 1);
    });
  });

  test('dispose stops deliveries and pending retries', () async {
    final h = _Harness();
    h.verifier.failNext(const Failure.network(), on: 'verify');
    await h.coordinator.process(aStorePurchase());
    await h.coordinator.dispose();
    h.delay.fire();
    await settle();
    h.store.redeliver(aStorePurchase(txnKey: 'late'));
    await settle();
    expect(h.verifier.callCount('verify'), 1);
  });

  test('PurchaseUpdate value semantics', () {
    final a = PurchaseUpdate(_pack, const PurchaseOutcome.pending());
    final b = PurchaseUpdate(_pack, const PurchaseOutcome.pending());
    expect(a, b);
    expect(a.hashCode, b.hashCode);
    expect(a, isNot(PurchaseUpdate(_packM, const PurchaseOutcome.pending())));
    expect(a.toString(), contains('readings_3'));
    expect(a.verificationDeferred, isFalse);
    expect(a.isSandboxCap, isFalse);
  });

  test('the default retry timer is a real delay', () async {
    final h = _Harness();
    final coordinator = PurchaseCoordinator(
      iap: FakeIapService(),
      verifier: h.verifier,
      outbox: h.outbox,
      balance: h.balance,
      install: h.install,
      config: h.config,
      removeAds: h.removeAds,
      tracker: h.tracker,
      analytics: h.analytics,
      ids: h.ids,
      clock: h.clock,
      logger: h.logger,
      retryBackoff: const [Duration.zero],
    );
    h.verifier.failNext(const Failure.network(), on: 'verify');
    await coordinator.process(aStorePurchase(txnKey: 'real'));
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(h.outbox.rows['real']!.status, OutboxStatus.finished);
    await coordinator.dispose();
  });

  test('other store events are ignored', () async {
    final h = _Harness();
    h.store
      ..emit(IapEvent.purchased(_pack))
      ..emit(const IapEvent.cancelled())
      ..emit(const IapEvent.failed(Failure.network()))
      ..emit(const IapEvent.entitlementChanged(Entitlement.unknown));
    await settle();
    expect(h.analytics.events, isEmpty);
  });

  group('property: finish() only after granted / already_granted / 422', () {
    for (var seed = 1; seed <= 40; seed++) {
      test('seed $seed', () => _runRandomizedOrder(seed));
    }
  });
}

/// A verifier answering at random, logging every answer before the
/// coordinator sees it.
final class _RandomVerifier implements PurchaseVerifier {
  _RandomVerifier(this._random, this._log);

  final Random _random;
  final List<String> _log;
  final Set<String> _granted = {};

  static const _answers = [
    'granted',
    'pending',
    'network',
    'server',
    'unauthorized',
    'forbidden',
    'rejected',
    'sandbox_cap',
    'claimed',
  ];

  @override
  Future<Result<GrantResult>> verify(
    StorePurchase purchase, {
    required String idempotencyKey,
    String? transferToken,
  }) async {
    await Future<void>.delayed(Duration.zero);
    final key = purchase.txnKey;
    var answer = _answers[_random.nextInt(_answers.length)];
    if (answer == 'granted' && _granted.contains(key)) {
      answer = 'already_granted';
    }
    _log.add('answer:$key:$answer');
    return switch (answer) {
      'granted' || 'already_granted' => () {
        _granted.add(key);
        return Result.ok(
          GrantResult(
            status: answer == 'granted'
                ? GrantStatus.granted
                : GrantStatus.alreadyGranted,
            creditsGranted: 3,
            balance: aCreditBalance().withPaid(3).build(),
          ),
        );
      }(),
      'pending' => const Result.ok(GrantResult(status: GrantStatus.pending)),
      'network' => const Result.err(Failure.network()),
      'server' => const Result.err(Failure.server(status: 502)),
      'unauthorized' => const Result.err(Failure.sessionExpired()),
      'forbidden' => const Result.err(
        Failure.attestation(kind: AttestationFailureKind.rejected),
      ),
      'rejected' => const Result.err(
        Failure.purchase(wireCode: 'PURCHASE_INVALID'),
      ),
      'sandbox_cap' => const Result.err(
        Failure.purchase(
          wireCode: 'PURCHASE_INVALID',
          reason: kSandboxCapReason,
        ),
      ),
      _ => const Result.err(
        Failure.purchaseAlreadyClaimed(transferEligible: false),
      ),
    };
  }
}

/// An [IapService] that logs `finish` before delegating.
final class _LoggingIap implements IapService {
  _LoggingIap(this._inner, this._log);

  final FakeIapService _inner;
  final List<String> _log;

  @override
  Future<Result<void>> finish(StorePurchase purchase) {
    _log.add('finish:${purchase.txnKey}');
    return _inner.finish(purchase);
  }

  @override
  Future<Result<StoreBuyResult>> buy(
    ProductId id, {
    required PurchaseBinding binding,
  }) => _inner.buy(id, binding: binding);

  @override
  Future<Result<List<StoreProduct>>> products(Set<ProductId> ids) =>
      _inner.products(ids);

  @override
  Future<Result<void>> restore() => _inner.restore();

  @override
  Stream<StorePurchase> get deliveries => _inner.deliveries;

  @override
  Stream<IapEvent> get events => _inner.events;

  @override
  Set<ProductId> get pending => _inner.pending;
}

const _finishingAnswers = {
  'granted',
  'already_granted',
  'rejected',
  'sandbox_cap',
};

Future<void> _runRandomizedOrder(int seed) async {
  final random = Random(seed);
  final log = <String>[];
  final store = FakeIapService();
  final connectivity = FakeConnectivityMonitor();
  final clock = FakeClock();
  final delay = ManualDelay();
  final analytics = FakeAnalyticsService();
  final logger = CapturingLogger();
  final config = FakeRemoteConfigRepository();
  final coordinator = PurchaseCoordinator(
    iap: _LoggingIap(store, log),
    verifier: _RandomVerifier(random, log),
    outbox: FakePurchaseOutbox(),
    balance: FakeBalanceRepository(),
    install: FakeInstallRepository(),
    config: config,
    removeAds: RemoveAdsEntitlement(
      cache: FakeEntitlementCache(),
      ownership: FakeStoreOwnership(),
      clock: clock,
      analytics: analytics,
      logger: logger,
      delay: ManualDelay().call,
    ),
    tracker: PendingPurchaseTracker(clock: clock, holdMinutes: () => 30),
    analytics: analytics,
    ids: SequentialIdGenerator('idem-'),
    clock: clock,
    logger: logger,
    connectivity: connectivity,
    delay: delay.call,
  );
  final packs = [
    TaroProducts.readings3.id,
    TaroProducts.readings10.id,
    TaroProducts.readings30.id,
  ];
  final delivered = <StorePurchase>[];
  final running = <Future<Object?>>[];

  for (var step = 0; step < 60; step++) {
    switch (random.nextInt(9)) {
      case 0:
      case 1:
        final purchase = store.newTransaction(packs[random.nextInt(3)]);
        delivered.add(purchase);
        store.redeliver(purchase);
      case 2:
        if (delivered.isNotEmpty) {
          store.redeliver(delivered[random.nextInt(delivered.length)]);
        }
      case 3:
        if (delivered.isNotEmpty) {
          running.add(
            coordinator.process(delivered[random.nextInt(delivered.length)]),
          );
        }
      case 4:
        running.add(
          coordinator.drainOutbox(
            reason: SyncReason.values[random.nextInt(SyncReason.values.length)],
          ),
        );
      case 5:
        delay.fire();
      case 6:
        connectivity.setOnline(online: random.nextBool());
      case 7:
        store.emitPending(packs[random.nextInt(3)]);
      case 8:
        clock.advance(Duration(minutes: random.nextInt(24 * 60)));
    }
    for (var i = random.nextInt(3); i > 0; i--) {
      await settle();
    }
  }
  // Let everything settle, firing every remaining backoff.
  for (var i = 0; i < 20; i++) {
    while (delay.fire()) {}
    await settle();
  }
  await Future.wait(running);
  await coordinator.dispose();

  for (var i = 0; i < log.length; i++) {
    final entry = log[i];
    if (!entry.startsWith('finish:')) continue;
    final key = entry.substring('finish:'.length);
    final answered = log
        .take(i)
        .where((e) => e.startsWith('answer:$key:'))
        .map((e) => e.substring('answer:$key:'.length));
    expect(
      answered.any(_finishingAnswers.contains),
      isTrue,
      reason: 'seed $seed: $key finished after only $answered',
    );
  }
  expect(log.where((e) => e.startsWith('answer:')), isNotEmpty);
}
