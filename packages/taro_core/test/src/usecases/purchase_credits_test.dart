import 'package:taro_core/taro_core.dart';
import 'package:test/test.dart';

import '../../contracts/contract_support.dart';
import '../../fakes/fakes.dart';

void main() {
  late FakeIapService iap;
  late FakePurchaseVerifier verifier;
  late FakePurchaseOutbox outbox;
  late FakeEntitlementCache entitlements;
  late FakeBalanceRepository balance;
  late FakeInstallRepository install;
  late FakeRemoteConfigRepository config;
  late SequentialIdGenerator ids;
  late FakeClock clock;
  late CapturingLogger logger;
  late CallRecorder recorder;
  late PurchaseCredits purchases;

  final pack = TaroProducts.readings3.id;
  final removeAds = TaroProducts.removeAds.id;

  setUp(() {
    recorder = CallRecorder();
    iap = FakeIapService()..recorder = recorder;
    verifier = FakePurchaseVerifier(
      balance: aCreditBalance().withLedgerVersion(5).build(),
    )..recorder = recorder;
    outbox = FakePurchaseOutbox()..recorder = recorder;
    entitlements = FakeEntitlementCache();
    balance = FakeBalanceRepository(
      cached: aCreditBalance().withLedgerVersion(5).build(),
    );
    install = FakeInstallRepository();
    config = FakeRemoteConfigRepository();
    ids = SequentialIdGenerator('idem-');
    clock = FakeClock();
    logger = CapturingLogger();
    purchases = PurchaseCredits(
      iap: iap,
      verifier: verifier,
      outbox: outbox,
      entitlements: entitlements,
      balance: balance,
      install: install,
      config: config,
      ids: ids,
      clock: clock,
      logger: logger,
    );
  });

  group('buy: availability', () {
    test('an unknown product is not available', () async {
      expect(
        expectOk(await purchases.buy(const ProductId('com.example.x'))),
        const PurchaseOutcome.notAvailable(),
      );
      expect(iap.calls, isEmpty);
    });

    test('nothing is available while the store is off', () async {
      config.current = aRemoteConfig().withStoreEnabled(false).build();
      for (final id in [pack, removeAds]) {
        expect(
          expectOk(await purchases.buy(id)),
          const PurchaseOutcome.notAvailable(),
        );
      }
    });

    test('a pack missing from store.packs is not available', () async {
      config.current = aRemoteConfig().withPacks([
        StorePack(productId: TaroProducts.readings10.id, sortOrder: 0),
        StorePack(productId: pack, sortOrder: 1, enabled: false),
      ]).build();
      expect(
        expectOk(await purchases.buy(pack)),
        const PurchaseOutcome.notAvailable(),
      );
    });

    test('packs are refused while purchases are blocked (RC66)', () async {
      balance.seed(
        aCreditBalance()
            .withPurchasesBlocked(PurchasesBlockedReason.refundDebt)
            .build(),
      );
      expect(
        expectErr(await purchases.buy(pack)),
        const Failure.purchasesBlocked(
          reason: PurchasesBlockedReason.refundDebt,
        ),
      );
      balance.seed(
        aCreditBalance().build().copyWith(purchasesAllowed: false),
      );
      expect(
        expectErr(await purchases.buy(pack)),
        const Failure.purchasesBlocked(reason: PurchasesBlockedReason.blocked),
      );
      expect(iap.calls, isEmpty);
    });

    test('a pack can be bought before the first balance sync', () async {
      balance.seed(null);
      expect(
        expectOk(await purchases.buy(pack)),
        const PurchaseOutcome.granted(credits: 3, isFirstPurchase: true),
      );
    });

    test('Remove Banner Ads off or already owned', () async {
      config.current = aRemoteConfig().withRemoveAdsEnabled(false).build();
      expect(
        expectOk(await purchases.buy(removeAds)),
        const PurchaseOutcome.notAvailable(),
      );
      config.current = RemoteConfig.defaults;
      entitlements.entitlement = const Entitlement(
        removeAds: EntitlementState.owned,
        source: EntitlementSource.cache,
      );
      expect(
        expectOk(await purchases.buy(removeAds)),
        const PurchaseOutcome.alreadyOwned(),
      );
      expect(iap.calls, isEmpty);
    });

    test('a purchase awaiting approval is pending', () async {
      iap.emitPending(pack);
      expect(
        expectOk(await purchases.buy(pack)),
        const PurchaseOutcome.pending(),
      );
      expect(iap.callCount('buy'), 0);
    });

    test('an unreadable install identity fails', () async {
      install.failNext(const Failure.storage(), on: 'getOrCreate');
      expect(expectErr(await purchases.buy(pack)), const Failure.storage());
      expect(iap.callCount('buy'), 0);
    });
  });

  group('buy: consumable', () {
    test('outbox first, verify, grant, then finish (rule 8)', () async {
      final outcome = expectOk(await purchases.buy(pack));
      expect(
        outcome,
        const PurchaseOutcome.granted(credits: 3, isFirstPurchase: true),
      );
      expect(recorder.calls, [
        'IapService.buy',
        'PurchaseOutbox.enqueue',
        'PurchaseVerifier.verify',
        'PurchaseOutbox.markGranted',
        'IapService.finish',
        'PurchaseOutbox.markFinished',
      ]);
      expect(iap.finished, ['txn-1']);
      expect(outbox.rows['txn-1']!.status, OutboxStatus.finished);
      expect(verifier.verifications.single.$2, 'idem-1');
      // The balance comes from the grant, never from the client (rule 7).
      expect(balance.cached?.paid, 3);
      expect(balance.cached?.ledgerVersion, 6);
    });

    test('binds the purchase to the install (MO15)', () async {
      await purchases.buy(pack);
      expect(iap.bindings.single, anInstallIdentity().purchaseBinding);
    });

    test('an install without a binding buys with an empty one', () async {
      install.identity = anInstallIdentity(binding: null);
      await purchases.buy(pack);
      expect(iap.bindings.single, const PurchaseBinding());
    });

    test('a cancelled sheet is cancelled, either way', () async {
      iap.failNext(const Failure.purchaseCancelled(), on: 'buy');
      expect(
        expectOk(await purchases.buy(pack)),
        const PurchaseOutcome.cancelled(),
      );
      iap.nextBuy(const StoreBuyResult.cancelled());
      expect(
        expectOk(await purchases.buy(pack)),
        const PurchaseOutcome.cancelled(),
      );
      expect(outbox.rows, isEmpty);
    });

    test('a store error is returned', () async {
      iap.failNext(const Failure.purchase(wireCode: 'STORE_ERROR'), on: 'buy');
      expect(
        expectErr(await purchases.buy(pack)),
        const Failure.purchase(wireCode: 'STORE_ERROR'),
      );
    });

    test('Ask to Buy returns pending', () async {
      iap.nextBuy(const StoreBuyResult.pending());
      expect(
        expectOk(await purchases.buy(pack)),
        const PurchaseOutcome.pending(),
      );
    });
  });

  group('buy: Remove Banner Ads', () {
    test('caches the entitlement and finishes without the Worker', () async {
      expect(
        expectOk(await purchases.buy(removeAds)),
        const PurchaseOutcome.granted(credits: 0, isFirstPurchase: false),
      );
      expect(entitlements.entitlement.removesAds, isTrue);
      expect(entitlements.entitlement.verifiedAt, kTestNow);
      expect(iap.finished, hasLength(1));
      expect(verifier.verifications, isEmpty);
      expect(outbox.rows, isEmpty);
    });

    test('a store "already owned" caches the entitlement', () async {
      iap.nextBuy(const StoreBuyResult.alreadyOwned());
      expect(
        expectOk(await purchases.buy(removeAds)),
        const PurchaseOutcome.alreadyOwned(),
      );
      expect(entitlements.entitlement.removesAds, isTrue);
    });

    test('a failed cache write is logged', () async {
      entitlements.failNext(const Failure.storage());
      await purchases.buy(removeAds);
      expect(logger.logged('entitlement cache write failed'), isTrue);
    });
  });

  group('process', () {
    test('a restored Remove Banner Ads is already owned', () async {
      final restored = aStorePurchase(productId: removeAds, isRestored: true);
      expect(
        await purchases.process(restored),
        const PurchaseOutcome.alreadyOwned(),
      );
      expect(entitlements.entitlement.removesAds, isTrue);
      expect(iap.finished, [restored.txnKey]);
    });

    test('a redelivered transaction is verified once', () async {
      final txn = aStorePurchase(txnKey: 'redelivered');
      final first = purchases.process(txn);
      final second = purchases.process(txn);
      expect(await second, const PurchaseOutcome.verificationDelayed());
      expect(
        await first,
        const PurchaseOutcome.granted(credits: 3, isFirstPurchase: true),
      );
      expect(verifier.verifications, hasLength(1));
      // Once done, the same transaction may be processed again (replay).
      expect(
        await purchases.process(txn),
        const PurchaseOutcome.alreadyGranted(),
      );
    });

    test('no outbox row, no verification', () async {
      outbox.failNext(const Failure.storage(), on: 'enqueue');
      expect(
        await purchases.process(aStorePurchase()),
        const PurchaseOutcome.verificationDelayed(),
      );
      expect(verifier.verifications, isEmpty);
      expect(iap.finished, isEmpty);
    });

    test('Worker pending keeps the transaction open', () async {
      verifier.scripted.add(const GrantResult(status: GrantStatus.pending));
      final txn = aStorePurchase();
      expect(await purchases.process(txn), const PurchaseOutcome.pending());
      expect(outbox.rows[txn.txnKey]!.attempts, 1);
      expect(outbox.rows[txn.txnKey]!.isOpen, isTrue);
      expect(iap.finished, isEmpty);
    });

    test('an idempotent replay is alreadyGranted and finished', () async {
      verifier.granted.add('txn-1');
      expect(
        await purchases.process(aStorePurchase()),
        const PurchaseOutcome.alreadyGranted(),
      );
      expect(iap.finished, ['txn-1']);
    });

    test('a grant without a balance applies nothing', () async {
      verifier.scripted.add(
        const GrantResult(status: GrantStatus.granted, creditsGranted: 10),
      );
      expect(
        await purchases.process(aStorePurchase()),
        const PurchaseOutcome.granted(credits: 10, isFirstPurchase: false),
      );
      expect(balance.applied, isEmpty);
    });

    test('a rejected purchase is finished and closed', () async {
      verifier.rejected.add('txn-1');
      final outcome = await purchases.process(aStorePurchase());
      expect(
        outcome,
        const PurchaseOutcome.failed(
          Failure.purchase(wireCode: 'PURCHASE_INVALID'),
        ),
      );
      expect(iap.finished, ['txn-1']);
      expect(outbox.rows['txn-1']!.status, OutboxStatus.rejected);
      expect(
        logger.logged('PURCHASE_INVALID', level: LogLevel.warning),
        isTrue,
      );
    });

    test('a purchase claimed by another install stays unfinished', () async {
      const claimed = Failure.purchaseAlreadyClaimed(
        transferEligible: true,
        transferToken: 'transfer',
      );
      verifier.failNext(claimed);
      expect(
        await purchases.process(aStorePurchase()),
        const PurchaseOutcome.failed(claimed),
      );
      expect(iap.finished, isEmpty);
      expect(outbox.rows['txn-1']!.status, OutboxStatus.rejected);
    });

    test('a transport failure is "safe", never finished', () async {
      verifier.failNext(const Failure.network());
      expect(
        await purchases.process(aStorePurchase()),
        const PurchaseOutcome.verificationDelayed(),
      );
      final row = outbox.rows['txn-1']!;
      expect(row.status, OutboxStatus.awaitingVerification);
      expect(row.lastError, 'NETWORK');
      expect(iap.finished, isEmpty);
    });

    test('a failed finish leaves the row granted for a retry', () async {
      iap.failNext(const Failure.network(), on: 'finish');
      expect(
        await purchases.process(aStorePurchase()),
        const PurchaseOutcome.granted(credits: 3, isFirstPurchase: true),
      );
      expect(outbox.rows['txn-1']!.status, OutboxStatus.granted);
      expect(logger.logged('finish deferred'), isTrue);
    });
  });

  group('flushOutbox', () {
    OutboxEntry row(
      String txnKey,
      OutboxStatus status, {
      Duration age = Duration.zero,
    }) => OutboxEntry(
      purchase: aStorePurchase(txnKey: txnKey),
      idempotencyKey: 'key-$txnKey',
      status: status,
      createdAt: kTestNow.subtract(age),
      updatedAt: kTestNow.subtract(age),
    );

    test('retries every open row with its own key', () async {
      outbox
        ..seed(row('a', OutboxStatus.awaitingVerification))
        ..seed(row('b', OutboxStatus.granted));
      final outcomes = expectOk(
        await purchases.flushOutbox(reason: SyncReason.resume),
      );
      expect(outcomes, {
        'a': const PurchaseOutcome.granted(credits: 3, isFirstPurchase: true),
        'b': const PurchaseOutcome.alreadyGranted(),
      });
      expect(verifier.verifications.single.$2, 'key-a');
      expect(iap.finished, unorderedEquals(['a', 'b']));
      expect(outbox.rows.values.every((r) => !r.isOpen), isTrue);
    });

    test('a closed row is answered without the Worker', () async {
      // A redelivery of a transaction whose row is already closed.
      outbox.seed(row('done', OutboxStatus.finished));
      expect(
        await purchases.process(aStorePurchase(txnKey: 'done')),
        const PurchaseOutcome.alreadyGranted(),
      );
      outbox.seed(row('bad', OutboxStatus.rejected));
      expect(
        await purchases.process(aStorePurchase(txnKey: 'bad')),
        const PurchaseOutcome.failed(
          Failure.purchase(wireCode: 'PURCHASE_INVALID'),
        ),
      );
      expect(verifier.verifications, isEmpty);
    });

    test('old rows are retried on launch only', () async {
      outbox.seed(
        row(
          'old',
          OutboxStatus.awaitingVerification,
          age: const Duration(days: 4),
        ),
      );
      final onResume = expectOk(
        await purchases.flushOutbox(reason: SyncReason.resume),
      );
      expect(onResume, isEmpty);
      expect(verifier.verifications, isEmpty);

      final onLaunch = expectOk(
        await purchases.flushOutbox(reason: SyncReason.launch),
      );
      expect(onLaunch.keys, ['old']);
      expect(
        logger.logged('iap_verify_stuck', level: LogLevel.warning),
        isTrue,
      );
    });

    test('a row being processed is skipped', () async {
      Future<Result<Map<String, PurchaseOutcome>>>? flush;
      verifier.onVerify = (_, _) =>
          flush ??= purchases.flushOutbox(reason: SyncReason.resume);
      await purchases.process(aStorePurchase());
      expect(expectOk(await flush!), isEmpty);
      expect(verifier.verifications, hasLength(1));
    });

    test('an unreadable outbox is a failure', () async {
      outbox.failNext(const Failure.storage(), on: 'pending');
      expect(
        expectErr(await purchases.flushOutbox(reason: SyncReason.launch)),
        const Failure.storage(),
      );
    });
  });

  test('restore asks the store', () async {
    iap.own(removeAds);
    final delivered = <StorePurchase>[];
    final sub = iap.deliveries.listen(delivered.add);
    expectOk(await purchases.restore());
    await settle();
    await sub.cancel();
    expect(delivered.single.isRestored, isTrue);
  });
}
