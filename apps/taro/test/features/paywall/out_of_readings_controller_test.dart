import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taro/features/paywall/controller/out_of_readings_controller.dart';
import 'package:taro/features/paywall/controller/paywall_catalog.dart';
import 'package:taro_core/taro_core.dart';

import '../../helpers/pump_app.dart';

CreditBalance _outOfReadings({
  bool rewardedAvailable = true,
  DateTime? cooldownEndsAt,
  int grantedToday = 0,
}) => aCreditBalance()
    .withFreeRemaining(0)
    .withRewarded(
      available: rewardedAvailable,
      grantedToday: grantedToday,
      cooldownEndsAt: cooldownEndsAt,
    )
    .build()
    .copyWith(canRead: false, canReadReason: CanReadReason.noCredits);

List<StorePack> _packsWithCredits() => [
  StorePack(
    productId: TaroProducts.readings3.id,
    sortOrder: 0,
    credits: 3,
  ),
  StorePack(
    productId: TaroProducts.readings10.id,
    sortOrder: 1,
    credits: 10,
  ),
  StorePack(
    productId: TaroProducts.readings30.id,
    sortOrder: 2,
    credits: 30,
  ),
];

const ConsentState kAdsAllowed = ConsentState(
  onboardingStep: OnboardingStep.done,
  ads: AdsConsent(
    status: AdsConsentStatus.notRequired,
    canRequestAds: true,
  ),
);

void main() {
  late TaroFakes fakes;

  setUp(() {
    fakes = TaroFakes(consent: kAdsAllowed);
    fakes.balance.seed(_outOfReadings());
    fakes.config.current = aRemoteConfig()
        .withPacks(_packsWithCredits())
        .build();
  });

  (ProviderContainer, OutOfReadingsState Function()) open([
    OutOfReadingsSource source = OutOfReadingsSource.questionGate,
  ]) {
    final container = fakes.container();
    final provider = outOfReadingsControllerProvider(source);
    container.listen(provider, (_, _) {});
    return (container, () => container.read(provider));
  }

  test('content: rewarded available, packs load, the free path shows, '
      'events and preload fire', () async {
    final (_, read) = open();
    expect(
      read(),
      isA<OutOfReadingsContent>()
          .having((s) => s.packs, 'packs', const PaywallPacks.loading())
          .having(
            (s) => s.rewarded,
            'rewarded',
            const RewardedOption.available(amount: 1, leftToday: 3),
          )
          .having((s) => s.nextFreeIn, 'nextFreeIn', const Duration(hours: 12))
          .having((s) => s.lowTrustLimited, 'lowTrust', isFalse),
    );
    await pumpEventQueue();
    final content = read() as OutOfReadingsContent;
    final catalog = (content.packs as PaywallPacksLoaded).catalog;
    expect(catalog.packs.map((p) => p.credits), [3, 10, 30]);
    expect(catalog.bestValue, TaroProducts.readings30.id);
    expect(catalog.removeAds?.productId, TaroProducts.removeAds.id);
    expect(fakes.ads.preloads, 1);
    expect(fakes.analytics.eventNames, [
      'out_of_readings_viewed',
      'rewarded_offer_shown',
      'iap_products_loaded',
    ]);
    expect(fakes.analytics.events.first.parameters, {
      'source': 'question_gate',
      'rewarded_available': true,
      'free_reset_in_min': 720,
    });
    expect(fakes.analytics.events[1].parameters, {'eligible': true});
  });

  test(
    'rewarded cooling down, capped, disabled and no-fill variants',
    () async {
      final cooling = fakes.clock.now().add(const Duration(minutes: 4));
      fakes.balance.seed(
        _outOfReadings(rewardedAvailable: false, cooldownEndsAt: cooling),
      );
      var (container, read) = open();
      expect(
        (read() as OutOfReadingsContent).rewarded,
        RewardedOption.coolingDown(until: cooling),
      );
      await pumpEventQueue();
      expect(fakes.analytics.events[1].parameters, {
        'eligible': false,
        'ineligible_reason': 'cooldown',
      });
      expect(fakes.ads.preloads, 0);
      container.dispose();

      fakes.balance.seed(
        _outOfReadings(rewardedAvailable: false, grantedToday: 3),
      );
      (container, read) = open();
      expect(
        (read() as OutOfReadingsContent).rewarded,
        const RewardedOption.capped(),
      );
      container.dispose();

      fakes
        ..balance.seed(_outOfReadings())
        ..config.current = aRemoteConfig().withRewardedEnabled(false).build();
      (container, read) = open();
      expect(
        (read() as OutOfReadingsContent).rewarded,
        const RewardedOption.hidden(),
      );
      fakes.config.current = aRemoteConfig().build();
      await pumpEventQueue();
      expect(
        (read() as OutOfReadingsContent).rewarded,
        isA<RewardedOptionAvailable>(),
      );
      container
          .read(rewardedNoFillProvider.notifier)
          .recordNoFill(
            fakes.clock.now(),
          );
      await pumpEventQueue();
      expect(
        (read() as OutOfReadingsContent).rewarded,
        RewardedOption.noFill(
          until: fakes.clock.now().add(kRewardedNoFillCooldown),
        ),
      );
    },
  );

  test('no balance yet hides rewarded and leaves the countdown empty', () {
    fakes.balance.seed(null);
    final (_, read) = open(OutOfReadingsSource.balanceChip);
    expect(
      read(),
      isA<OutOfReadingsContent>()
          .having((s) => s.rewarded, 'rewarded', const RewardedOption.hidden())
          .having((s) => s.nextFreeIn, 'nextFreeIn', isNull)
          .having((s) => s.nextFreeAt, 'nextFreeAt', isNull),
    );
  });

  test('lowTrustLimited from the source or the balance (RC74)', () {
    var (container, read) = open(OutOfReadingsSource.lowTrust);
    expect((read() as OutOfReadingsContent).lowTrustLimited, isTrue);
    container.dispose();
    fakes.balance.seed(
      _outOfReadings().copyWith(canReadReason: CanReadReason.lowTrustCap),
    );
    (container, read) = open();
    expect((read() as OutOfReadingsContent).lowTrustLimited, isTrue);
  });

  test('purchasesBlocked from the Worker and the store kill switch '
      '(RC66)', () async {
    fakes.balance.seed(
      _outOfReadings().copyWith(
        purchasesAllowed: false,
        purchasesBlockedReason: PurchasesBlockedReason.refundDebt,
      ),
    );
    var (container, read) = open();
    await pumpEventQueue();
    expect(
      (read() as OutOfReadingsContent).packs,
      const PaywallPacks.purchasesBlocked(PurchasesBlockedReason.refundDebt),
    );
    final controller = container.read(
      outOfReadingsControllerProvider(
        OutOfReadingsSource.questionGate,
      ).notifier,
    );
    expect(controller.tapGetMore(), isFalse);
    container.dispose();

    fakes.balance.seed(
      _outOfReadings().copyWith(purchasesAllowed: false),
    );
    (container, read) = open();
    expect(
      (read() as OutOfReadingsContent).packs,
      const PaywallPacks.purchasesBlocked(PurchasesBlockedReason.blocked),
    );
    container.dispose();

    fakes
      ..balance.seed(_outOfReadings())
      ..config.current = aRemoteConfig().withStoreEnabled(false).build();
    (container, read) = open();
    expect(
      (read() as OutOfReadingsContent).packs,
      const PaywallPacks.purchasesBlocked(PurchasesBlockedReason.storeDisabled),
    );
  });

  test('store unavailable, then a retry lists the packs', () async {
    fakes.iap.failNext(const Failure.network(), on: 'products');
    final (container, read) = open();
    await pumpEventQueue();
    expect(
      (read() as OutOfReadingsContent).packs,
      const PaywallPacks.unavailable(),
    );
    expect(
      fakes.analytics.events.last.parameters,
      containsPair('result', 'error'),
    );
    final controller = container.read(
      outOfReadingsControllerProvider(
        OutOfReadingsSource.questionGate,
      ).notifier,
    );
    final retry = controller.retryPacks();
    expect(
      (read() as OutOfReadingsContent).packs,
      const PaywallPacks.loading(),
    );
    await retry;
    expect((read() as OutOfReadingsContent).packs, isA<PaywallPacksLoaded>());
  });

  test('before the Worker config has loaded, packs are unavailable (never '
      '"for 0"); Retry refreshes the config and lists them (BUG-02)', () async {
    fakes.config
      ..current = RemoteConfig.defaults
      ..failNext(const Failure.network(), on: 'refresh');
    final (container, read) = open();
    await pumpEventQueue();
    expect(
      (read() as OutOfReadingsContent).packs,
      const PaywallPacks.unavailable(),
    );
    fakes.config.server = aRemoteConfig()
        .withPacks(_packsWithCredits())
        .build();
    await container
        .read(
          outOfReadingsControllerProvider(
            OutOfReadingsSource.questionGate,
          ).notifier,
        )
        .retryPacks();
    final packs = (read() as OutOfReadingsContent).packs;
    expect(
      (packs as PaywallPacksLoaded).catalog.packs.map((p) => p.credits),
      [3, 10, 30],
    );
  });

  test('an empty listing is unavailable', () async {
    fakes.iap.catalog.clear();
    final (_, read) = open();
    await pumpEventQueue();
    expect(
      (read() as OutOfReadingsContent).packs,
      const PaywallPacks.unavailable(),
    );
    expect(
      fakes.analytics.events.last.parameters,
      containsPair('result', 'empty'),
    );
  });

  test('a partial listing still loads', () async {
    fakes.iap.catalog.remove(TaroProducts.readings30.id);
    fakes.config.current = aRemoteConfig()
        .withPacks(_packsWithCredits())
        .withRemoveAdsEnabled(false)
        .build();
    final (_, read) = open();
    await pumpEventQueue();
    final catalog =
        ((read() as OutOfReadingsContent).packs as PaywallPacksLoaded).catalog;
    expect(catalog.packs, hasLength(2));
    expect(catalog.removeAds, isNull);
    expect(
      fakes.analytics.events.last.parameters,
      containsPair('result', 'partial'),
    );
  });

  test('a grant resolves the sheet: back to S07, nothing auto-starts '
      '(RC58)', () async {
    final (_, read) = open();
    await pumpEventQueue();
    fakes.balance.seed(
      aCreditBalance()
          .withFreeRemaining(0)
          .withBonus(1)
          .withLedgerVersion(2)
          .build(),
    );
    await pumpEventQueue();
    expect(read(), const OutOfReadingsState.resolved());
  });

  test(
    'opened with readings available (the balance chip) stays open',
    () async {
      fakes.balance.seed(aCreditBalance().withPaid(3).build());
      final (_, read) = open(OutOfReadingsSource.balanceChip);
      await pumpEventQueue();
      expect(read(), isA<OutOfReadingsContent>());
    },
  );

  test('taps and dismiss log the paywall events once', () async {
    final (container, read) = open();
    await pumpEventQueue();
    final controller = container.read(
      outOfReadingsControllerProvider(
        OutOfReadingsSource.questionGate,
      ).notifier,
    );
    expect(controller.tapGetMore(), isTrue);
    expect(await controller.tapRewarded(), isTrue);
    fakes.clock.advance(const Duration(seconds: 7));
    await controller.dismiss();
    await controller.dismiss();
    expect(
      fakes.analytics.eventNames.where((n) => n == 'paywall_dismissed'),
      hasLength(1),
    );
    expect(fakes.analytics.events.last.parameters, {
      'surface': 'out_of_readings',
      'seconds_visible': 7,
      'action_taken': 'reward',
    });
    expect(
      fakes.analytics.events.any(
        (e) =>
            e.eventName == 'rewarded_offer_tapped' &&
            e.parameters['source'] == 'out_of_readings',
      ),
      isTrue,
    );
    controller.refresh();
    expect(read(), isA<OutOfReadingsContent>());
  });

  test('tapRewarded is refused while the row is not available', () async {
    fakes.balance.seed(
      _outOfReadings(rewardedAvailable: false, grantedToday: 3),
    );
    final (container, _) = open();
    final controller = container.read(
      outOfReadingsControllerProvider(
        OutOfReadingsSource.questionGate,
      ).notifier,
    );
    expect(await controller.tapRewarded(), isFalse);
  });

  test('the cooldown end syncs the balance and re-enables the row', () async {
    final until = fakes.clock.now().add(const Duration(milliseconds: 5));
    fakes.balance
      ..seed(_outOfReadings(rewardedAvailable: false, cooldownEndsAt: until))
      ..server = _outOfReadings().copyWith(ledgerVersion: 5);
    final (_, read) = open();
    expect(
      (read() as OutOfReadingsContent).rewarded,
      isA<RewardedOptionCoolingDown>(),
    );
    fakes.clock.advance(const Duration(milliseconds: 5));
    await Future<void>.delayed(const Duration(milliseconds: 20));
    await pumpEventQueue();
    expect(fakes.balance.syncReasons, contains(SyncReason.manual));
    expect(
      (read() as OutOfReadingsContent).rewarded,
      isA<RewardedOptionAvailable>(),
    );
  });

  test('the no-fill pause ends on its own', () async {
    final (container, read) = open();
    container
        .read(rewardedNoFillProvider.notifier)
        .recordNoFill(
          fakes.clock.now().subtract(
            kRewardedNoFillCooldown - const Duration(milliseconds: 5),
          ),
        );
    expect(
      (read() as OutOfReadingsContent).rewarded,
      isA<RewardedOptionNoFill>(),
    );
    fakes.clock.advance(const Duration(milliseconds: 5));
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(
      (read() as OutOfReadingsContent).rewarded,
      isA<RewardedOptionAvailable>(),
    );
  });

  test('no ads consent hides the rewarded row', () async {
    fakes.consentStore.seed(const ConsentState());
    final (_, read) = open();
    expect(
      (read() as OutOfReadingsContent).rewarded,
      const RewardedOption.hidden(),
    );
    await pumpEventQueue();
    expect(fakes.analytics.events[1].parameters, {
      'eligible': false,
      'ineligible_reason': 'consent',
    });
  });
}
