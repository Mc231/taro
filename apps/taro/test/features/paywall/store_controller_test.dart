import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taro/features/paywall/controller/paywall_catalog.dart';
import 'package:taro/features/paywall/controller/store_controller.dart';
import 'package:taro_core/taro_core.dart';

import '../../helpers/pump_app.dart';

const ConsentState _adsAllowed = ConsentState(
  onboardingStep: OnboardingStep.done,
  ads: AdsConsent(status: AdsConsentStatus.notRequired, canRequestAds: true),
);

final ProductId _pack3 = TaroProducts.readings3.id;
final ProductId _removeAds = TaroProducts.removeAds.id;

/// `store.packs` as the Worker injects them: with `credits` (RC3).
List<StorePack> _workerPacks() => [
  StorePack(productId: _pack3, sortOrder: 0, credits: 3),
  StorePack(productId: TaroProducts.readings10.id, sortOrder: 1, credits: 10),
  StorePack(productId: TaroProducts.readings30.id, sortOrder: 2, credits: 30),
];

void main() {
  late TaroFakes fakes;

  setUp(() {
    fakes = TaroFakes(consent: _adsAllowed);
    fakes.balance.seed(
      aCreditBalance()
          .withFreeRemaining(0)
          .withRewarded(available: true)
          .build(),
    );
    fakes.config.current = aRemoteConfig().withPacks(_workerPacks()).build();
  });

  (ProviderContainer, StoreController, StoreState Function()) open([
    StoreSource source = StoreSource.outOfReadings,
  ]) {
    final container = fakes.container();
    final provider = storeControllerProvider(source);
    container.listen(provider, (_, _) {});
    return (
      container,
      container.read(provider.notifier),
      () => container.read(provider),
    );
  }

  Future<(StoreController, StoreState Function())> ready([
    StoreSource source = StoreSource.outOfReadings,
  ]) async {
    final (_, controller, read) = open(source);
    await pumpEventQueue();
    expect(read(), isA<StoreReady>());
    return (controller, read);
  }

  StorePurchasePhase phaseOf(StoreState state) => (state as StoreReady).phase;

  test('loading, then ready with packs, Remove Banner Ads and the rewarded '
      'offer; store_viewed fires', () async {
    final (_, _, read) = open(StoreSource.settings);
    expect(read(), const StoreState.loading());
    await pumpEventQueue();
    final view = (read() as StoreReady).view;
    expect(view.catalog.packs, hasLength(3));
    expect(view.catalog.removeAds?.productId, _removeAds);
    expect(view.rewarded, isA<RewardedOptionAvailable>());
    expect(view.removeAdsOwned, isFalse);
    expect(view.offline, isFalse);
    expect(view.paidBlocked, isFalse);
    expect(view.purchasesBlocked, isNull);
    expect(phaseOf(read()), const StorePurchasePhase.idle());
    expect(fakes.analytics.eventNames.take(2), [
      'store_viewed',
      'iap_products_loaded',
    ]);
    expect(fakes.analytics.events.first.parameters, {'source': 'settings'});
  });

  test('productsFailed, then Retry lists the products', () async {
    fakes.iap.failNext(const Failure.network(), on: 'products');
    final (_, controller, read) = open();
    await pumpEventQueue();
    expect(read(), const StoreState.productsFailed(ErrorKind.network));
    final retry = controller.retry();
    expect(read(), const StoreState.loading());
    await retry;
    expect(read(), isA<StoreReady>());
  });

  group('before the Worker config has loaded (BUG-02)', () {
    setUp(() => fakes.config.current = RemoteConfig.defaults);

    test('refreshes the config once, then lists packs with the Worker '
        'credits', () async {
      fakes.config.server = aRemoteConfig().withPacks(_workerPacks()).build();
      final (_, _, read) = open();
      await pumpEventQueue();
      final packs = (read() as StoreReady).view.catalog.packs;
      expect(packs.map((p) => p.credits), [3, 10, 30]);
      expect(fakes.config.calls, ['refresh']);
    });

    test('never lists a pack without credits ("0 readings")', () async {
      fakes.config.failNext(const Failure.network(), on: 'refresh');
      final (_, _, read) = open();
      await pumpEventQueue();
      final view = (read() as StoreReady).view;
      expect(view.catalog.packs, isEmpty);
      expect(view.catalog.removeAds?.productId, _removeAds);
    });

    test('storeUnavailable when no pack has credits and Remove Banner Ads '
        'is off', () async {
      fakes.config.current = aRemoteConfig()
          .withRemoveAdsEnabled(false)
          .build();
      final (_, _, read) = open();
      await pumpEventQueue();
      expect(read(), const StoreState.storeUnavailable());
    });
  });

  test('a loaded config is not refreshed again', () async {
    await ready();
    expect(fakes.config.calls, isEmpty);
  });

  test('storeUnavailable when nothing is listed', () async {
    fakes.iap.catalog.clear();
    final (_, _, read) = open();
    await pumpEventQueue();
    expect(read(), const StoreState.storeUnavailable());
  });

  test('buy: purchasing → granted; purchase_started carries the price; the '
      'transaction is finished only after the grant', () async {
    final (controller, read) = await ready();
    final buying = controller.buy(_pack3);
    expect(phaseOf(read()), StorePurchasePhase.purchasing(_pack3));
    await buying;
    expect(phaseOf(read()), StorePurchasePhase.granted(_pack3, credits: 3));
    expect(fakes.iap.finished, ['txn-1']);
    final started = fakes.analytics.events.firstWhere(
      (e) => e.eventName == 'purchase_started',
    );
    expect(started.parameters, {
      'product': 'pack_s',
      'price_micros': 2990000,
      'currency': 'USD',
    });
    controller.acknowledge();
    expect(phaseOf(read()), const StorePurchasePhase.idle());
  });

  test('a second buy while busy is refused (04 §12.4)', () async {
    final (controller, _) = await ready();
    final first = controller.buy(_pack3);
    await controller.buy(TaroProducts.readings10.id);
    await first;
    expect(fakes.iap.bindings, hasLength(1));
  });

  test('cancelled is a silent return', () async {
    fakes.iap.nextBuy(const StoreBuyResult.cancelled());
    final (controller, read) = await ready();
    await controller.buy(_pack3);
    expect(phaseOf(read()), StorePurchasePhase.cancelled(_pack3));
    controller.acknowledge();
    expect(phaseOf(read()), const StorePurchasePhase.idle());
  });

  test('pending, then the approval delivers: verifying → granted '
      '(Ask to Buy, 04 §12.7)', () async {
    fakes.iap.nextBuy(const StoreBuyResult.pending());
    final (controller, read) = await ready();
    await controller.buy(_pack3);
    expect(phaseOf(read()), StorePurchasePhase.pending(_pack3));
    controller.acknowledge();
    expect(phaseOf(read()), StorePurchasePhase.pending(_pack3));
    final phases = <StorePurchasePhase>[];
    fakes.verifier.onVerify = (_, _) => phases.add(phaseOf(read()));
    fakes.iap.approvePending(_pack3);
    await pumpEventQueue();
    expect(phases, [StorePurchasePhase.verifying(_pack3)]);
    expect(phaseOf(read()), StorePurchasePhase.granted(_pack3, credits: 3));
  });

  test(
    'verificationDeferred when the Worker is unreachable (04 §12.2)',
    () async {
      fakes.verifier.failNext(const Failure.network(), on: 'verify');
      final (controller, read) = await ready();
      await controller.buy(_pack3);
      expect(
        phaseOf(read()),
        StorePurchasePhase.verificationDeferred(_pack3),
      );
      expect(fakes.iap.finished, isEmpty);
    },
  );

  test('failed(reason) for a store error and a rejected verify', () async {
    fakes.iap.failNext(
      const Failure.purchase(wireCode: 'store_error'),
      on: 'buy',
    );
    final (controller, read) = await ready();
    await controller.buy(_pack3);
    expect(
      phaseOf(read()),
      StorePurchasePhase.failed(_pack3, reason: PurchaseErrorKind.storeError),
    );
    controller.acknowledge();
    fakes.verifier.failNext(
      const Failure.purchase(wireCode: 'PURCHASE_INVALID'),
      on: 'verify',
    );
    await controller.buy(_pack3);
    expect(
      phaseOf(read()),
      StorePurchasePhase.failed(
        _pack3,
        reason: PurchaseErrorKind.verifyRejected,
      ),
    );
  });

  test('PURCHASE_ALREADY_CLAIMED adds the transfer hint (RC84)', () async {
    fakes.verifier.failNext(
      const Failure.purchaseAlreadyClaimed(
        transferEligible: true,
        transferToken: 'tt1.a.b',
      ),
      on: 'verify',
    );
    final (controller, read) = await ready();
    await controller.buy(_pack3);
    expect(
      phaseOf(read()),
      StorePurchasePhase.failed(
        _pack3,
        reason: PurchaseErrorKind.alreadyClaimed,
        transferEligible: true,
      ),
    );
  });

  test('an install failure fails the buy before the store', () async {
    fakes.install.failNext(const Failure.storage(), on: 'getOrCreate');
    final (controller, read) = await ready();
    await controller.buy(_pack3);
    expect(
      phaseOf(read()),
      StorePurchasePhase.failed(_pack3, reason: PurchaseErrorKind.unknown),
    );
  });

  test('a cancelled store failure maps to cancelled', () async {
    fakes.iap.failNext(const Failure.purchaseCancelled(), on: 'buy');
    final (controller, read) = await ready();
    await controller.buy(_pack3);
    expect(phaseOf(read()), StorePurchasePhase.cancelled(_pack3));
  });

  test('Remove Banner Ads: granted, then removeAdsOwned hides the '
      'button', () async {
    final (controller, read) = await ready();
    await controller.buy(_removeAds);
    await pumpEventQueue();
    expect(phaseOf(read()), StorePurchasePhase.granted(_removeAds, credits: 0));
    expect((read() as StoreReady).view.removeAdsOwned, isTrue);
    controller.acknowledge();
    await controller.buy(_removeAds);
    expect(fakes.iap.bindings, hasLength(1));
  });

  test('already owned in the store counts as granted', () async {
    fakes.iap.own(_removeAds);
    final (controller, read) = await ready();
    await controller.buy(_removeAds);
    await pumpEventQueue();
    expect(phaseOf(read()), StorePurchasePhase.granted(_removeAds, credits: 0));
  });

  test('purchasesBlocked hides packs; Remove Banner Ads, rewarded and '
      'restore stay (RC66)', () async {
    fakes.balance.seed(
      aCreditBalance()
          .withFreeRemaining(0)
          .withPurchasesBlocked(PurchasesBlockedReason.refundDebt)
          .build()
          .copyWith(paidBlocked: true),
    );
    final (controller, read) = await ready();
    final view = (read() as StoreReady).view;
    expect(view.purchasesBlocked, PurchasesBlockedReason.refundDebt);
    expect(view.paidBlocked, isTrue);
    await controller.buy(_pack3);
    expect(fakes.iap.bindings, isEmpty);
    await controller.restore();
    expect(fakes.iap.calls, contains('restore'));
  });

  test('the store.enabled kill switch is storeDisabled', () async {
    fakes.config.current = aRemoteConfig().withStoreEnabled(false).build();
    final (_, read) = await ready();
    expect(
      (read() as StoreReady).view.purchasesBlocked,
      PurchasesBlockedReason.storeDisabled,
    );
  });

  test('offline shows the warning', () async {
    final (_, read) = await ready();
    fakes.connectivity.setOnline(online: false);
    await pumpEventQueue();
    expect((read() as StoreReady).view.offline, isTrue);
  });

  test('buy before ready or of an unknown product is ignored', () async {
    final (_, controller, _) = open();
    await controller.buy(_pack3);
    await pumpEventQueue();
    await controller.buy(const ProductId('com.vshyrochuk.taro.nope'));
    expect(fakes.iap.bindings, isEmpty);
  });

  test('updates of other products are ignored', () async {
    fakes.iap.nextBuy(const StoreBuyResult.pending());
    final (controller, read) = await ready();
    await controller.buy(_pack3);
    fakes.iap.redeliver(
      aStorePurchase(txnKey: 'other', productId: TaroProducts.readings10.id),
    );
    fakes.iap.redeliver(
      aStorePurchase(
        txnKey: 'r',
        productId: TaroProducts.readings30.id,
        isRestored: true,
      ),
    );
    await pumpEventQueue();
    expect(phaseOf(read()), StorePurchasePhase.pending(_pack3));
  });

  test('rewarded tap and dismiss log once', () async {
    final (controller, _) = await ready(StoreSource.deepLink);
    expect(await controller.tapRewarded(), isTrue);
    fakes.clock.advance(const Duration(seconds: 3));
    await controller.dismiss();
    await controller.dismiss();
    expect(
      fakes.analytics.eventNames.where((n) => n == 'paywall_dismissed'),
      hasLength(1),
    );
    expect(fakes.analytics.events.last.parameters, {
      'surface': 'store',
      'seconds_visible': 3,
      'action_taken': 'reward',
    });
    expect(
      fakes.analytics.events
          .firstWhere((e) => e.eventName == 'rewarded_offer_tapped')
          .parameters,
      {'source': 'store'},
    );
  });

  test('rewarded tap is refused when not available', () async {
    fakes.balance.seed(aCreditBalance().build());
    final (controller, _) = await ready();
    expect(await controller.tapRewarded(), isFalse);
  });

  test('phase helpers', () {
    expect(const StorePurchasePhase.idle().productId, isNull);
    expect(StorePurchasePhase.verifying(_pack3).isBusy, isTrue);
    expect(StorePurchasePhase.pending(_pack3).isBusy, isFalse);
  });

  test('closing the screen mid-buy drops the result', () async {
    final (container, controller, _) = open();
    await pumpEventQueue();
    final buying = controller.buy(_pack3);
    container.dispose();
    await buying;
  });
}
