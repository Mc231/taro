import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taro/common/banner_slot.dart';
import 'package:taro/features/paywall/controller/out_of_readings_controller.dart';
import 'package:taro/features/paywall/controller/paywall_catalog.dart';
import 'package:taro/features/paywall/controller/rewarded_controller.dart';
import 'package:taro/features/paywall/controller/store_controller.dart';
import 'package:taro/features/paywall/view/out_of_readings_screen.dart';
import 'package:taro/features/paywall/view/paywall_parts.dart';
import 'package:taro/features/paywall/view/rewarded_screen.dart';
import 'package:taro/features/paywall/view/store_screen.dart';
import 'package:taro/l10n/generated/taro_localizations.dart';
import 'package:taro/routing/routes.dart';
import 'package:taro_core/taro_core.dart';
import 'package:taro_ui/taro_ui.dart';

import '../flow_view_support.dart' show revealFound, tapFound;
import '../skeleton_support.dart';

final DateTime _now = DateTime.utc(2026, 9, 30, 12);

ProductOffer _offer(TaroProduct product, int credits, double price) =>
    ProductOffer(
      productId: product.id,
      price: '\$${price.toStringAsFixed(2)}',
      rawPrice: price,
      currencyCode: 'USD',
      credits: credits,
    );

final ProductOffer _pack3 = _offer(TaroProducts.readings3, 3, 1.99);
final ProductOffer _pack10 = _offer(TaroProducts.readings10, 10, 4.99);
final ProductOffer _removeAds = _offer(TaroProducts.removeAds, 0, 3.99);

final PaywallCatalog _catalog = PaywallCatalog(
  packs: [_pack3, _pack10],
  removeAds: _removeAds,
  bestValue: _pack10.productId,
);

StoreView _view({
  RewardedOption rewarded = const RewardedOption.hidden(),
  bool removeAdsOwned = false,
  bool offline = false,
  bool paidBlocked = false,
  PurchasesBlockedReason? purchasesBlocked,
  PaywallCatalog? catalog,
}) => StoreView(
  catalog: catalog ?? _catalog,
  rewarded: rewarded,
  removeAdsOwned: removeAdsOwned,
  offline: offline,
  paidBlocked: paidBlocked,
  purchasesBlocked: purchasesBlocked,
);

const ConsentState _adsAllowed = ConsentState(
  onboardingStep: OnboardingStep.done,
  ads: AdsConsent(status: AdsConsentStatus.notRequired, canRequestAds: true),
);

void main() {
  late TaroLocalizations l10n;

  setUpAll(() async => l10n = await enL10n());

  group('S10 out-of-readings view', () {
    Future<void> pump(
      WidgetTester tester,
      OutOfReadingsState state, {
      void Function()? onClose,
      void Function()? onRewarded,
      void Function()? onGetMore,
      void Function()? onRetry,
      void Function()? onSupport,
      void Function()? onDailyCard,
      void Function()? onLearn,
      double textScale = 1,
    }) => pumpTaroWidget(
      tester,
      OutOfReadingsLayout(
        state: state,
        now: () => _now,
        onClose: onClose ?? noop,
        onRewarded: onRewarded ?? noop,
        onGetMore: onGetMore ?? noop,
        onRetryPacks: onRetry ?? noop,
        onContactSupport: onSupport ?? noop,
        onDailyCard: onDailyCard ?? noop,
        onLearn: onLearn ?? noop,
        onTerms: noop,
        onPrivacy: noop,
      ),
      textScale: textScale,
    );

    OutOfReadingsState content({
      RewardedOption rewarded = const RewardedOption.hidden(),
      PaywallPacks packs = const PaywallPacks.loading(),
      bool lowTrust = false,
      Duration? nextFreeIn,
      DateTime? nextFreeAt,
    }) => OutOfReadingsState.content(
      rewarded: rewarded,
      packs: packs,
      lowTrustLimited: lowTrust,
      nextFreeIn: nextFreeIn,
      nextFreeAt: nextFreeAt,
    );

    testWidgets('content: free path, close, Not now, legal footer; packs '
        'loading', (tester) async {
      var closed = 0;
      await pump(
        tester,
        content(
          nextFreeIn: const Duration(hours: 5, minutes: 12),
          nextFreeAt: DateTime(2026, 10),
        ),
        onClose: () => closed++,
      );
      expect(find.text(l10n.outOfReadingsTitle), findsOneWidget);
      expect(find.text(l10n.outOfReadingsBody), findsOneWidget);
      expect(find.textContaining('5 h 12 min'), findsOneWidget);
      expect(find.text(l10n.outOfReadingsGetMore), findsOneWidget);
      expect(find.text(l10n.commonLoading), findsOneWidget);
      expect(find.byType(BannerSlot), findsNothing);
      expect(find.text(l10n.storeConsumableDisclosure), findsOneWidget);
      expect(find.text(l10n.commonTerms), findsOneWidget);
      expect(find.text(l10n.commonPrivacy), findsOneWidget);
      expect(find.text(l10n.disclaimerShort), findsOneWidget);
      await tester.tap(find.bySemanticsLabel(l10n.commonClose));
      await tapText(tester, l10n.commonNotNow);
      expect(closed, 2);
    });

    testWidgets('until then: daily card and Learn links', (tester) async {
      final calls = <String>[];
      await pump(
        tester,
        content(),
        onDailyCard: () => calls.add('daily'),
        onLearn: () => calls.add('learn'),
      );
      expect(find.text(l10n.outOfReadingsUntilThen), findsOneWidget);
      await tapText(tester, l10n.commonDailyCard);
      await tapText(tester, l10n.commonLearn);
      expect(calls, ['daily', 'learn']);
    });

    testWidgets('the countdown is the only timer and comes from server time', (
      tester,
    ) async {
      await pump(
        tester,
        content(
          nextFreeIn: const Duration(hours: 5, minutes: 12),
          nextFreeAt: DateTime(2026, 10),
        ),
      );
      // One countdown, and it is the real free reset (04 §11).
      expect(find.byType(CountdownText), findsOneWidget);
      final countdown = tester.widget<CountdownText>(
        find.byType(CountdownText),
      );
      expect(
        countdown.target,
        _now.add(const Duration(hours: 5, minutes: 12)),
      );
    });

    testWidgets('200% text: the sheet scrolls without overflow', (
      tester,
    ) async {
      await pump(
        tester,
        content(
          rewarded: const RewardedOption.available(amount: 1, leftToday: 3),
          packs: PaywallPacks.loaded(_catalog),
          nextFreeIn: const Duration(hours: 5, minutes: 12),
        ),
        textScale: 2,
      );
      expect(tester.takeException(), isNull);
      await revealFound(tester, find.text(l10n.disclaimerShort));
      expect(find.text(l10n.disclaimerShort), findsOneWidget);
    });

    testWidgets('free path copy without a reset instant or a balance', (
      tester,
    ) async {
      await pump(tester, content(nextFreeIn: const Duration(minutes: 4)));
      expect(find.text(l10n.balanceNextFreeIn('4 min')), findsOneWidget);
      await pump(tester, content());
      expect(find.text(l10n.balanceNextFreeTomorrow), findsOneWidget);
    });

    testWidgets('every combination keeps the free path, close, Not now, '
        'Terms, Privacy, the disclosure and the disclaimer (04 §11)', (
      tester,
    ) async {
      for (final rewarded in [
        const RewardedOption.available(amount: 1, leftToday: 3),
        RewardedOption.coolingDown(until: _now.add(const Duration(minutes: 4))),
        const RewardedOption.capped(),
        RewardedOption.noFill(until: _now),
        const RewardedOption.hidden(),
      ]) {
        for (final packs in [
          const PaywallPacks.loading(),
          PaywallPacks.loaded(_catalog),
          const PaywallPacks.unavailable(),
          const PaywallPacks.purchasesBlocked(PurchasesBlockedReason.blocked),
        ]) {
          await pump(
            tester,
            content(
              rewarded: rewarded,
              packs: packs,
              nextFreeIn: const Duration(hours: 3, minutes: 12),
            ),
          );
          expect(find.textContaining('3 h 12 min'), findsOneWidget);
          expect(find.bySemanticsLabel(l10n.commonClose), findsOneWidget);
          expect(find.text(l10n.commonNotNow), findsOneWidget);
          expect(find.text(l10n.commonTerms), findsOneWidget);
          expect(find.text(l10n.commonPrivacy), findsOneWidget);
          expect(find.text(l10n.storeConsumableDisclosure), findsOneWidget);
          expect(find.text(l10n.disclaimerShort), findsOneWidget);
          expect(find.byType(CountdownText), findsOneWidget);
        }
      }
    });

    testWidgets('a disabled rewarded row is announced with its reason', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pump(tester, content(rewarded: const RewardedOption.capped()));
      final node = tester.getSemantics(
        find
            .ancestor(
              of: find.text(l10n.rewardedCapped),
              matching: find.byType(MergeSemantics),
            )
            .first,
      );
      expect(node.label, contains(l10n.rewardedOfferTitle(1)));
      expect(node.label, contains(l10n.rewardedCapped));
      handle.dispose();
    });

    testWidgets('lowTrustLimited copy variant', (tester) async {
      await pump(tester, content(lowTrust: true));
      expect(find.text(l10n.outOfReadingsLowTrustTitle), findsOneWidget);
    });

    testWidgets('rewarded available / coolingDown / capped / noFill', (
      tester,
    ) async {
      var taps = 0;
      await pump(
        tester,
        content(
          rewarded: const RewardedOption.available(amount: 1, leftToday: 2),
        ),
        onRewarded: () => taps++,
      );
      await tapText(tester, l10n.rewardedOfferTitle(1));
      expect(taps, 1);
      expect(find.text(l10n.rewardedOfferLeft(2)), findsOneWidget);

      await pump(
        tester,
        content(
          rewarded: RewardedOption.coolingDown(
            until: _now.add(const Duration(minutes: 30)),
          ),
        ),
      );
      expect(find.text(l10n.rewardedCoolingDown('30 min')), findsOneWidget);
      await pump(tester, content(rewarded: const RewardedOption.capped()));
      expect(find.text(l10n.rewardedCapped), findsOneWidget);
      await pump(
        tester,
        content(rewarded: RewardedOption.noFill(until: _now)),
      );
      expect(find.text(l10n.rewardedNoFill), findsOneWidget);
    });

    testWidgets('packs loaded / unavailable / purchasesBlocked', (
      tester,
    ) async {
      var more = 0;
      var retry = 0;
      var support = 0;
      await pump(
        tester,
        content(packs: PaywallPacks.loaded(_catalog)),
        onGetMore: () => more++,
      );
      expect(find.text(l10n.outOfReadingsFromPrice(r'$1.99', 3)), findsOne);
      await tapText(tester, l10n.outOfReadingsGetMore);
      expect(more, 1);

      await pump(
        tester,
        content(packs: const PaywallPacks.unavailable()),
        onRetry: () => retry++,
      );
      expect(find.text(l10n.storePricesUnavailable), findsOneWidget);
      await tapText(tester, l10n.commonRetry);
      expect(retry, 1);

      for (final (reason, text) in [
        (PurchasesBlockedReason.blocked, l10n.storePurchasesBlocked),
        (PurchasesBlockedReason.refundDebt, l10n.storeRefundDebt),
        (PurchasesBlockedReason.storeDisabled, l10n.storeDisabled),
      ]) {
        await pump(
          tester,
          content(packs: PaywallPacks.purchasesBlocked(reason)),
          onSupport: () => support++,
        );
        expect(find.text(text), findsOneWidget);
        expect(find.text(l10n.outOfReadingsGetMore), findsNothing);
      }
      await tapText(tester, l10n.storeContactSupport);
      expect(support, 1);
    });

    testWidgets('resolved renders nothing', (tester) async {
      await pump(tester, const OutOfReadingsState.resolved());
      expect(find.text(l10n.outOfReadingsTitle), findsNothing);
    });
  });

  group('S11 store view', () {
    Future<void> pump(
      WidgetTester tester,
      StoreState state, {
      void Function()? onClose,
      void Function(ProductId)? onBuy,
      void Function()? onRestore,
      void Function()? onRetry,
      void Function()? onAcknowledge,
      void Function()? onTerms,
      void Function()? onPrivacy,
      void Function()? onSupport,
    }) => pumpTaroWidget(
      tester,
      StoreLayout(
        state: state,
        now: _now,
        onClose: onClose ?? noop,
        onBuy: onBuy ?? noop1,
        onRestore: onRestore ?? noop,
        onRetry: onRetry ?? noop,
        onAcknowledge: onAcknowledge ?? noop,
        onRewarded: noop,
        onContactSupport: onSupport ?? noop,
        onTerms: onTerms ?? noop,
        onPrivacy: onPrivacy ?? noop,
      ),
    );

    StoreState ready({
      StoreView? view,
      StorePurchasePhase phase = const StorePurchasePhase.idle(),
    }) => StoreState.ready(view: view ?? _view(), phase: phase);

    Future<void> expectCompliance(WidgetTester tester) async {
      // The footer follows the content; scroll to it when a state is long.
      await revealFound(tester, find.text(l10n.disclaimerShort));
      expect(find.bySemanticsLabel(l10n.commonClose), findsOneWidget);
      expect(find.text(l10n.storeRestore), findsOneWidget);
      expect(find.text(l10n.commonTerms), findsOneWidget);
      expect(find.text(l10n.commonPrivacy), findsOneWidget);
      expect(find.text(l10n.storeConsumableDisclosure), findsOneWidget);
      expect(find.text(l10n.disclaimerShort), findsOneWidget);
      // No fake urgency: S11 has no timer at all (04 §11, 05 §9.5).
      expect(find.byType(CountdownText), findsNothing);
      expect(find.byType(BannerSlot), findsNothing);
    }

    testWidgets('every state keeps close, restore, terms, privacy, the '
        'non-restorable line and the disclaimer (04 §15, 05 3.1.1)', (
      tester,
    ) async {
      final id = _pack3.productId;
      for (final state in [
        const StoreState.loading(),
        const StoreState.storeUnavailable(),
        const StoreState.productsFailed(ErrorKind.network),
        ready(),
        ready(phase: StorePurchasePhase.purchasing(id)),
        ready(phase: StorePurchasePhase.pending(id)),
        ready(phase: StorePurchasePhase.verifying(id)),
        ready(phase: StorePurchasePhase.verificationDeferred(id)),
        ready(
          phase: StorePurchasePhase.failed(
            id,
            reason: PurchaseErrorKind.network,
          ),
        ),
        ready(view: _view(offline: true, paidBlocked: true)),
        ready(view: _view(removeAdsOwned: true)),
        ready(view: _view(purchasesBlocked: PurchasesBlockedReason.blocked)),
        ready(
          view: _view(purchasesBlocked: PurchasesBlockedReason.refundDebt),
        ),
        ready(
          view: _view(purchasesBlocked: PurchasesBlockedReason.storeDisabled),
        ),
      ]) {
        await pump(tester, state);
        await expectCompliance(tester);
      }
    });

    testWidgets('200% text on the smallest phone: close stays visible, the '
        'footer is reachable, nothing overflows', (tester) async {
      await pumpTaroWidget(
        tester,
        StoreLayout(
          state: ready(
            view: _view(
              rewarded: const RewardedOption.available(
                amount: 1,
                leftToday: 3,
              ),
            ),
          ),
          now: _now,
          onClose: noop,
          onBuy: noop1,
          onRestore: noop,
          onRetry: noop,
          onAcknowledge: noop,
          onRewarded: noop,
          onContactSupport: noop,
          onTerms: noop,
          onPrivacy: noop,
        ),
        textScale: 2,
      );
      expect(tester.takeException(), isNull);
      await revealFound(tester, find.text(l10n.disclaimerShort));
      // The close is outside the scroll view (rule 11).
      final close = tester.getRect(find.bySemanticsLabel(l10n.commonClose));
      expect(close.top, greaterThanOrEqualTo(0));
      expect(close.width, greaterThanOrEqualTo(48));
      expect(close.height, greaterThanOrEqualTo(48));
    });

    testWidgets('ready: each pack is its own buy button, none pre-selected', (
      tester,
    ) async {
      final bought = <ProductId>[];
      var closed = 0;
      var restored = 0;
      var terms = 0;
      var privacy = 0;
      await pump(
        tester,
        ready(),
        onBuy: bought.add,
        onClose: () => closed++,
        onRestore: () => restored++,
        onTerms: () => terms++,
        onPrivacy: () => privacy++,
      );
      final tiles = tester
          .widgetList<ProductOfferTile>(find.byType(ProductOfferTile))
          .toList();
      expect(tiles, hasLength(3));
      expect(
        tiles.every((t) => t.state == ProductOfferState.content),
        isTrue,
        reason: 'no pack is pre-selected or busy',
      );
      expect(find.text(l10n.commonContinue), findsNothing);
      expect(find.text(l10n.storePackTitle(3)), findsOneWidget);
      expect(find.text(l10n.storePerReading(r'$0.66')), findsOneWidget);
      expect(find.text(l10n.storeBestValue), findsOneWidget);
      expect(
        find.bySemanticsLabel(
          l10n.storePackSemanticsBestValue(
            l10n.storePackSemantics(10, r'$4.99', r'$0.50'),
          ),
        ),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(l10n.storePackSemantics(3, r'$1.99', r'$0.66')),
        findsOneWidget,
      );
      expect(find.text(l10n.storeRemoveAdsTitle), findsOneWidget);
      await tapText(tester, r'$4.99');
      await tapText(tester, r'$3.99');
      expect(bought, [_pack10.productId, _removeAds.productId]);
      await tester.tap(find.bySemanticsLabel(l10n.commonClose));
      await tapText(tester, l10n.storeRestore);
      await tapText(tester, l10n.commonTerms);
      await tapText(tester, l10n.commonPrivacy);
      expect((closed, restored, terms, privacy), (1, 1, 1, 1));
    });

    testWidgets('loading, storeUnavailable and productsFailed retry', (
      tester,
    ) async {
      var retry = 0;
      await pump(tester, const StoreState.loading());
      expect(find.byType(ProductOfferTile), findsNWidgets(4));
      await pump(
        tester,
        const StoreState.storeUnavailable(),
        onRetry: () => retry++,
      );
      expect(find.text(l10n.storeUnavailable), findsOneWidget);
      await tapText(tester, l10n.commonRetry);
      await pump(
        tester,
        const StoreState.productsFailed(ErrorKind.server),
        onRetry: () => retry++,
      );
      expect(find.text(l10n.storePricesUnavailable), findsOneWidget);
      await tapText(tester, l10n.commonRetry);
      expect(retry, 2);
    });

    testWidgets('purchase phases', (tester) async {
      final id = _pack3.productId;
      await pump(tester, ready(phase: StorePurchasePhase.purchasing(id)));
      expect(
        tester.widget<ProductOfferTile>(find.byKey(ValueKey(id))).state,
        ProductOfferState.purchasing,
      );
      await pump(tester, ready(phase: StorePurchasePhase.pending(id)));
      expect(
        tester.widget<ProductOfferTile>(find.byKey(ValueKey(id))).state,
        ProductOfferState.pending,
      );
      await pump(tester, ready(phase: StorePurchasePhase.verifying(id)));
      expect(find.text(l10n.storeVerifying), findsOneWidget);
      await pump(
        tester,
        ready(phase: StorePurchasePhase.verificationDeferred(id)),
      );
      expect(find.text(l10n.storeVerificationDelayed), findsOneWidget);
      await pump(tester, ready(phase: StorePurchasePhase.cancelled(id)));
      expect(find.byType(TaroInlineNotice), findsNothing);

      // A grant is announced by the toast (StoreScreen), not inline.
      await pump(
        tester,
        ready(phase: StorePurchasePhase.granted(id, credits: 3)),
      );
      expect(find.byType(TaroInlineNotice), findsNothing);

      var acknowledged = 0;
      await pump(
        tester,
        ready(
          phase: StorePurchasePhase.failed(
            id,
            reason: PurchaseErrorKind.alreadyClaimed,
            transferEligible: true,
          ),
        ),
        onAcknowledge: () => acknowledged++,
      );
      expect(find.text(l10n.failurePurchaseAlreadyClaimed), findsOneWidget);
      expect(find.text(l10n.storeTransferHint), findsOneWidget);
      tester
          .widget<TaroInlineNotice>(find.byType(TaroInlineNotice))
          .onDismiss!();
      expect(acknowledged, 1);
    });

    testWidgets('offline, paidBlocked, purchasesBlocked, removeAdsOwned', (
      tester,
    ) async {
      await pump(tester, ready(view: _view(offline: true)));
      expect(find.text(l10n.storeOfflineNotice), findsOneWidget);
      await pump(tester, ready(view: _view(paidBlocked: true)));
      expect(find.text(l10n.storeRefundDebt), findsOneWidget);
      var support = 0;
      await pump(
        tester,
        ready(
          view: _view(purchasesBlocked: PurchasesBlockedReason.storeDisabled),
        ),
        onSupport: () => support++,
      );
      expect(find.text(l10n.storeDisabled), findsOneWidget);
      expect(find.text(l10n.storePackTitle(3)), findsNothing);
      await tapText(tester, l10n.storeContactSupport);
      expect(support, 1);
      await pump(tester, ready(view: _view(removeAdsOwned: true)));
      expect(find.text(l10n.storeRemoveAdsOwned), findsOneWidget);
      expect(find.text(l10n.storeRemoveAdsBody), findsNothing);
      expect(find.text(r'$3.99'), findsNothing);
      await pump(
        tester,
        ready(
          view: _view(
            catalog: PaywallCatalog(
              packs: [_pack3.copyWith(credits: 0)],
            ),
            rewarded: const RewardedOption.available(amount: 1, leftToday: 1),
          ),
        ),
      );
      expect(find.text(l10n.rewardedOfferTitle(1)), findsOneWidget);
    });

    test('PaywallText.failed covers every kind', () {
      for (final kind in PurchaseErrorKind.values) {
        expect(PaywallText.failed(l10n, kind), isNotEmpty);
      }
      expect(
        PaywallText.failed(l10n, PurchaseErrorKind.network),
        l10n.failureNetwork,
      );
    });

    test('source parsing', () {
      expect(storeSourceOf('settings'), StoreSource.settings);
      expect(storeSourceOf(null), StoreSource.balanceChip);
      expect(outOfReadingsSourceOf('hold_402'), OutOfReadingsSource.hold402);
      expect(outOfReadingsSourceOf('x'), OutOfReadingsSource.questionGate);
    });
  });

  group('S12 rewarded view', () {
    testWidgets('every state', (tester) async {
      var closed = 0;
      Future<void> pump(RewardedState state) => pumpTaroWidget(
        tester,
        RewardedLayout(state: state, onClose: () => closed++),
      );
      await pump(const RewardedState.loadingAd());
      expect(find.bySemanticsLabel(l10n.rewardedLoadingAd), findsWidgets);
      await tapText(tester, l10n.commonCancel);
      expect(closed, 1);
      await pump(const RewardedState.showing());
      expect(find.bySemanticsLabel(l10n.rewardedLoadingAd), findsWidgets);
      await pump(const RewardedState.granting());
      expect(find.text(l10n.rewardedGrantingTitle), findsOneWidget);
      expect(find.textContaining(l10n.rewardedCloseNote), findsOneWidget);
      await pump(const RewardedState.granted(amount: 1));
      expect(find.text(l10n.rewardedGrantedTitle), findsOneWidget);
      expect(find.text(l10n.rewardedGrantedBody(1)), findsOneWidget);
      expect(find.text(l10n.commonDone), findsOneWidget);
      await tapText(tester, l10n.commonContinue);
      await pump(const RewardedState.grantDelayed());
      expect(find.text(l10n.rewardedGrantDelayed), findsOneWidget);
      await pump(const RewardedState.dismissedEarly());
      expect(find.text(l10n.rewardedDismissedEarly), findsOneWidget);
      await pump(const RewardedState.noFill());
      expect(find.text(l10n.rewardedNoFill), findsOneWidget);
      await pump(
        const RewardedState.unavailable(RewardUnavailableReason.cap),
      );
      expect(find.text(l10n.rewardedCapped), findsOneWidget);
      await pump(
        const RewardedState.unavailable(RewardUnavailableReason.cooldown),
      );
      expect(find.text(l10n.failureRewardUnavailable), findsOneWidget);
      await pump(const RewardedState.failed(ErrorKind.network));
      expect(find.text(l10n.errorNetworkTitle), findsOneWidget);
      await tapText(tester, l10n.commonClose);
      expect(closed, 3);
      await pump(const RewardedState.failed(ErrorKind.server));
      expect(find.byType(BannerSlot), findsNothing);
    });
  });

  group('paywall screens with fakes', () {
    late TaroFakes fakes;

    setUp(() {
      fakes = TaroFakes(consent: _adsAllowed);
      fakes.balance.seed(
        aCreditBalance()
            .withFreeRemaining(0)
            .withRewarded(available: true)
            .build(),
      );
    });

    Widget host(Future<Object?> Function(BuildContext) open) => Builder(
      builder: (context) => Scaffold(
        body: TextButton(
          onPressed: () => unawaited(open(context)),
          child: const Text('open'),
        ),
      ),
    );

    testWidgets('the rewarded ad is never auto-shown: opening S10 shows no '
        'ad and no banner (05 3.2.2, rule 12)', (tester) async {
      await pumpRouted(
        tester,
        host((context) => TaroModals.outOfReadings<bool>(context)),
        fakes: fakes,
      );
      await tapText(tester, 'open');
      expect(find.text(l10n.rewardedOfferTitle(1)), findsOneWidget);
      expect(fakes.ads.shown, isEmpty);
      expect(fakes.ads.isShowing, isFalse);
      expect(find.byType(BannerSlot), findsNothing);
      expect(find.byType(RewardedScreen), findsNothing);
    });

    Future<void> openRewarded(WidgetTester tester) async {
      await pumpRouted(
        tester,
        host((context) => TaroModals.rewarded<void>(context)),
        fakes: fakes,
        overrides: [
          rewardedPollDelayProvider.overrideWithValue(
            (d) async => fakes.clock.advance(d),
          ),
        ],
      );
      await tapText(tester, 'open');
      await tester.pumpAndSettle();
    }

    testWidgets('S12 dismissedEarly: closes with a neutral snackbar', (
      tester,
    ) async {
      fakes.ads.autoResult = RewardedShowResult.dismissedEarly;
      await openRewarded(tester);
      expect(find.byType(RewardedScreen), findsNothing);
      expect(find.text(l10n.rewardedDismissedEarly), findsOneWidget);
    });

    testWidgets('S12 grantDelayed: closes; "Your reading will appear '
        'shortly"', (tester) async {
      fakes.ads.autoResult = RewardedShowResult.earned;
      await openRewarded(tester);
      expect(find.byType(RewardedScreen), findsNothing);
      expect(find.text(l10n.rewardedGrantDelayed), findsOneWidget);
    });

    testWidgets('S12 noFill: closes silently', (tester) async {
      fakes.ads.autoResult = RewardedShowResult.noFill;
      await openRewarded(tester);
      expect(find.byType(RewardedScreen), findsNothing);
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('S10: Get more opens the store; Not now logs the dismissal', (
      tester,
    ) async {
      Object? result = 'unset';
      final router = await pumpRouted(
        tester,
        host(
          (context) async => result = await TaroModals.outOfReadings<bool>(
            context,
            source: OutOfReadingsSource.hold402.wire,
          ),
        ),
        fakes: fakes,
      );
      await tapText(tester, 'open');
      expect(find.byType(OutOfReadingsScreen), findsOneWidget);
      await tapText(tester, l10n.commonNotNow);
      expect(result, isFalse);
      expect(
        fakes.analytics.events.whereType<PaywallDismissedEvent>(),
        hasLength(1),
      );

      await tapText(tester, 'open');
      await tapText(tester, l10n.outOfReadingsGetMore);
      expect(router.state.uri.toString(), '/store?source=outOfReadings');
    });

    for (final (label, location) in [
      ('terms', '/legal/terms'),
      ('privacy', '/legal/privacy'),
    ]) {
      testWidgets('S10: the $label link', (tester) async {
        await pumpRouted(
          tester,
          host((context) => TaroModals.outOfReadings<bool>(context)),
          fakes: fakes,
        );
        await tapText(tester, 'open');
        await tapText(
          tester,
          label == 'terms' ? l10n.commonTerms : l10n.commonPrivacy,
        );
        expectRoute(location);
      });
    }

    testWidgets('S10: rewarded opens S12; a grant resolves the sheet', (
      tester,
    ) async {
      fakes.ads.autoResult = RewardedShowResult.earned;
      fakes.rewards.autoGrant = true;
      Object? result = 'unset';
      await pumpRouted(
        tester,
        host(
          (context) async =>
              result = await TaroModals.outOfReadings<bool>(context),
        ),
        fakes: fakes,
        overrides: [
          rewardedPollDelayProvider.overrideWithValue((_) async {}),
        ],
      );
      await tapText(tester, 'open');
      await tapText(tester, l10n.rewardedOfferTitle(1));
      expect(find.byType(RewardedScreen), findsOneWidget);
      await tester.pumpAndSettle();
      if (find.text(l10n.commonContinue).evaluate().isNotEmpty) {
        await tapText(tester, l10n.commonContinue);
      } else {
        await tapText(tester, l10n.commonClose);
      }
      expect(find.byType(RewardedScreen), findsNothing);
      fakes.balance.seed(aCreditBalance().withBonus(1).build());
      await tester.pumpAndSettle();
      expect(result, isTrue);
    });

    for (final (label, location) in [
      ('daily card', '/daily'),
      ('learn', '/learn'),
    ]) {
      testWidgets('S10: the $label link closes the sheet', (tester) async {
        Object? result = 'unset';
        await pumpRouted(
          tester,
          host(
            (context) async =>
                result = await TaroModals.outOfReadings<bool>(context),
          ),
          fakes: fakes,
        );
        await tapText(tester, 'open');
        await tapText(
          tester,
          label == 'learn' ? l10n.commonLearn : l10n.commonDailyCard,
        );
        expect(result, isFalse);
        expectRoute(location);
      });
    }

    testWidgets('S10: a passed free reset re-syncs the balance', (
      tester,
    ) async {
      fakes.balance.seed(
        aCreditBalance()
            .withFreeRemaining(0)
            .withResetsAt(fakes.clock.now().add(const Duration(minutes: 1)))
            .build(),
      );
      await pumpRouted(
        tester,
        host((context) => TaroModals.outOfReadings<bool>(context)),
        fakes: fakes,
      );
      await tapText(tester, 'open');
      final before = fakes.balance.requests;
      fakes.clock.advance(const Duration(minutes: 2));
      await tester.pump(const Duration(minutes: 1));
      await tester.pumpAndSettle();
      expect(fakes.balance.requests, greaterThan(before));
      await tapText(tester, l10n.commonNotNow);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(minutes: 5));
    });

    testWidgets('S10: purchases blocked → contact support', (tester) async {
      fakes.balance.seed(
        aCreditBalance().withFreeRemaining(0).withPurchasesBlocked().build(),
      );
      await pumpRouted(
        tester,
        host((context) => TaroModals.outOfReadings<bool>(context)),
        fakes: fakes,
      );
      await tapText(tester, 'open');
      await tapText(tester, l10n.storeContactSupport);
      expectRoute('/help');
    });

    testWidgets('S10: store listing failure → retry', (tester) async {
      fakes.iap.failNext(const Failure.network(), on: 'products');
      await pumpRouted(
        tester,
        host((context) => TaroModals.outOfReadings<bool>(context)),
        fakes: fakes,
      );
      await tapText(tester, 'open');
      expect(find.text(l10n.storePricesUnavailable), findsOneWidget);
      await tapText(tester, l10n.commonRetry);
      expect(find.text(l10n.outOfReadingsGetMore), findsOneWidget);
    });

    testWidgets('S11: buy, continue, restore, legal links and close', (
      tester,
    ) async {
      final router = await pumpRouted(
        tester,
        const StoreScreen(source: StoreSource.settings),
        fakes: fakes,
        pushed: true,
      );
      expect(find.byType(ProductOfferTile), findsWidgets);
      final pack = find.byType(ProductOfferTile).first;
      final price = find
          .descendant(of: pack, matching: find.byType(TaroButton))
          .first;
      await tester.tap(price);
      await tester.pumpAndSettle();
      expect(
        fakes.analytics.events.whereType<PurchaseStartedEvent>(),
        isNotEmpty,
      );
      if (find.text(l10n.commonContinue).evaluate().isNotEmpty) {
        await tapText(tester, l10n.commonContinue);
        expectRoute('/');
        router.push<void>('/under-test').ignore();
        await tester.pumpAndSettle();
      }
      await tapText(tester, l10n.storeRestore);
      await tapText(tester, l10n.commonTerms);
      expectRoute('/legal/terms');
      router.pop();
      await tester.pumpAndSettle();
      await tapText(tester, l10n.commonPrivacy);
      expectRoute('/legal/privacy');
      router.pop();
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel(l10n.commonClose));
      await tester.pumpAndSettle();
      expectRoute('/');
      expect(
        fakes.analytics.events.whereType<PaywallDismissedEvent>(),
        isNotEmpty,
      );
    });

    testWidgets('S11 from S10: a grant shows the toast and returns to S07 '
        '(nothing auto-starts, RC58)', (tester) async {
      await pumpRouted(
        tester,
        const StoreScreen(source: StoreSource.outOfReadings),
        fakes: fakes,
        pushed: true,
      );
      await tester.tap(
        find
            .descendant(
              of: find.byType(ProductOfferTile).first,
              matching: find.byType(TaroButton),
            )
            .first,
      );
      await tester.pump();
      await tester.pump();
      expect(find.text(l10n.storeGranted(3)), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.byType(StoreScreen), findsNothing);
      expectRoute('/');
    });

    testWidgets('S11: buying Remove Banner Ads shows the owned toast', (
      tester,
    ) async {
      await pumpRouted(
        tester,
        const StoreScreen(source: StoreSource.settings),
        fakes: fakes,
      );
      await tapFound(tester, find.text(_removeAds.price));
      expect(find.text(l10n.storeRemoveAdsOwned), findsWidgets);
      expect(find.byType(StoreScreen), findsOneWidget);
    });

    testWidgets('S11: a cancelled purchase returns silently; rewarded opens '
        'S12; blocked packs link to support', (tester) async {
      fakes.iap.nextBuy(const StoreBuyResult.cancelled());
      await pumpRouted(
        tester,
        const StoreScreen(source: StoreSource.balanceChip),
        fakes: fakes,
      );
      await tester.tap(
        find
            .descendant(
              of: find.byType(ProductOfferTile).first,
              matching: find.byType(TaroButton),
            )
            .first,
      );
      await tester.pumpAndSettle();
      expect(find.byType(TaroInlineNotice), findsNothing);
      await tapText(tester, l10n.rewardedOfferTitle(1));
      expect(find.byType(RewardedScreen), findsOneWidget);
      await tester.pumpAndSettle();
      await tester.tap(
        find
            .descendant(
              of: find.byType(RewardedScreen),
              matching: find.byType(TaroButton),
            )
            .last,
      );
      await tester.pumpAndSettle();
      expect(find.byType(RewardedScreen), findsNothing);
    });

    testWidgets('S11: purchases blocked → contact support', (tester) async {
      fakes.balance.seed(
        aCreditBalance().withPurchasesBlocked().build(),
      );
      await pumpRouted(
        tester,
        const StoreScreen(source: StoreSource.balanceChip),
        fakes: fakes,
      );
      await tapText(tester, l10n.storeContactSupport);
      expectRoute('/help');
    });

    testWidgets('S11: products failed → retry', (tester) async {
      fakes.iap.failNext(const Failure.network(), on: 'products');
      await pumpRouted(
        tester,
        const StoreScreen(source: StoreSource.deepLink),
        fakes: fakes,
      );
      await tapText(tester, l10n.commonRetry);
      expect(find.byType(ProductOfferTile), findsWidgets);
    });
  });
}
