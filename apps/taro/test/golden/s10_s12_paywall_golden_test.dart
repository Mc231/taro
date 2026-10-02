@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taro/common/balance_chip.dart';
import 'package:taro/features/paywall/controller/out_of_readings_controller.dart';
import 'package:taro/features/paywall/controller/paywall_catalog.dart';
import 'package:taro/features/paywall/controller/rewarded_controller.dart';
import 'package:taro/features/paywall/controller/store_controller.dart';
import 'package:taro/features/paywall/view/out_of_readings_screen.dart';
import 'package:taro/features/paywall/view/rewarded_screen.dart';
import 'package:taro/features/paywall/view/store_screen.dart';
import 'package:taro_core/taro_core.dart';
import 'package:taro_ui/taro_ui.dart';

import 'golden_app_support.dart';

/// The monetization golden matrix of 04 §15 (Phase 17.1): S10, S11, S12.
final DateTime _now = DateTime(2026, 9, 27, 20, 48);

ProductOffer _offer(TaroProduct product, int credits, double price) =>
    ProductOffer(
      productId: product.id,
      price: '\$${price.toStringAsFixed(2)}',
      rawPrice: price,
      currencyCode: 'USD',
      credits: credits,
    );

final ProductOffer _pack30 = _offer(TaroProducts.readings30, 30, 9.99);

final PaywallCatalog _catalog = PaywallCatalog(
  packs: [
    _offer(TaroProducts.readings3, 3, 1.99),
    _offer(TaroProducts.readings10, 10, 4.99),
    _pack30,
  ],
  removeAds: _offer(TaroProducts.removeAds, 0, 3.99),
  bestValue: _pack30.productId,
);

final CreditBalance _zero = aCreditBalance().withFreeRemaining(0).build();

/// The pump with a synced "0 readings" chip.
final GoldenPump _pump = pumpAppGolden(
  () => goldenFakes(clock: FakeClock(_now)),
  overrides: [
    balanceChipProvider.overrideWithValue(
      BalanceChipView(balance: _zero, sync: BalanceChipSync.synced),
    ),
  ],
);

/// S10 as `TaroSheet.show` presents it: the scrim and the raised sheet at
/// the bottom, capped at `layout.maxContentWidth`.
class _SheetFrame extends StatelessWidget {
  const _SheetFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return ColoredBox(
      color: tokens.color.bg.canvas,
      child: ColoredBox(
        color: tokens.color.bg.scrim,
        child: Align(
          alignment: AlignmentDirectional.bottomCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: tokens.layout.maxContentWidth,
            ),
            child: Material(
              color: tokens.color.bg.surfaceRaised,
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(tokens.radius.sheet),
                ),
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

Widget _sheet({
  required RewardedOption rewarded,
  bool lowTrust = false,
}) => _SheetFrame(
  child: OutOfReadingsLayout(
    state: OutOfReadingsState.content(
      rewarded: rewarded,
      packs: PaywallPacks.loaded(_catalog),
      lowTrustLimited: lowTrust,
      nextFreeIn: const Duration(hours: 3, minutes: 12),
      nextFreeAt: DateTime(2026, 9, 28),
    ),
    now: () => _now,
    onClose: () {},
    onRewarded: () {},
    onGetMore: () {},
    onRetryPacks: () {},
    onContactSupport: () {},
    onDailyCard: () {},
    onLearn: () {},
    onTerms: () {},
    onPrivacy: () {},
  ),
);

Widget _store(StoreState state) => StoreLayout(
  state: state,
  balance: const BalanceChip(),
  now: _now,
  onClose: () {},
  onBuy: (_) {},
  onRestore: () {},
  onRetry: () {},
  onAcknowledge: () {},
  onRewarded: () {},
  onContactSupport: () {},
  onTerms: () {},
  onPrivacy: () {},
);

StoreState _ready({
  StorePurchasePhase phase = const StorePurchasePhase.idle(),
  bool removeAdsOwned = false,
  PurchasesBlockedReason? purchasesBlocked,
  RewardedOption rewarded = const RewardedOption.available(
    amount: 1,
    leftToday: 3,
  ),
}) => StoreState.ready(
  view: StoreView(
    catalog: _catalog,
    rewarded: rewarded,
    removeAdsOwned: removeAdsOwned,
    offline: false,
    paidBlocked: false,
    purchasesBlocked: purchasesBlocked,
  ),
  phase: phase,
);

void main() {
  const de = [Locale('de')];
  final id = TaroProducts.readings10.id;

  // S10 (★ content: rewarded eligible).
  goldenMatrix(
    's10_out_of_readings_rewarded_eligible',
    (_) => _sheet(
      rewarded: const RewardedOption.available(amount: 1, leftToday: 3),
    ),
    keyScreen: true,
    accessibility: true,
    largeText: true,
    extraLocales: de,
    pump: _pump,
  );
  goldenMatrix(
    's10_out_of_readings_rewarded_cooldown',
    (_) => _sheet(
      rewarded: RewardedOption.coolingDown(
        until: _now.add(const Duration(minutes: 4)),
      ),
    ),
    extraLocales: de,
    pump: _pump,
  );
  goldenMatrix(
    's10_out_of_readings_rewarded_capped',
    (_) => _sheet(rewarded: const RewardedOption.capped()),
    extraLocales: de,
    pump: _pump,
  );
  goldenMatrix(
    's10_out_of_readings_low_trust',
    (_) => _sheet(rewarded: const RewardedOption.hidden(), lowTrust: true),
    extraLocales: de,
    pump: _pump,
  );

  // S11 (★ loading and content).
  goldenMatrix(
    's11_store_loading',
    (_) => _store(const StoreState.loading()),
    keyScreen: true,
    accessibility: true,
    extraLocales: de,
    pump: _pump,
  );
  goldenMatrix(
    's11_store_content',
    (_) => _store(_ready()),
    keyScreen: true,
    accessibility: true,
    largeText: true,
    extraLocales: de,
    pump: _pump,
  );
  goldenMatrix(
    's11_store_pending',
    (_) => _store(_ready(phase: StorePurchasePhase.pending(id))),
    extraLocales: de,
    pump: _pump,
  );
  goldenMatrix(
    's11_store_verification_deferred',
    (_) => _store(_ready(phase: StorePurchasePhase.verificationDeferred(id))),
    extraLocales: de,
    pump: _pump,
  );
  goldenMatrix(
    's11_store_unavailable',
    (_) => _store(const StoreState.storeUnavailable()),
    extraLocales: de,
    pump: _pump,
  );
  goldenMatrix(
    's11_store_purchases_blocked',
    (_) => _store(_ready(purchasesBlocked: PurchasesBlockedReason.refundDebt)),
    extraLocales: de,
    pump: _pump,
  );
  goldenMatrix(
    's11_store_remove_ads_owned',
    (_) => _store(
      _ready(removeAdsOwned: true, rewarded: const RewardedOption.hidden()),
    ),
    extraLocales: de,
    pump: _pump,
  );

  // S12 (★ granted), over the dimmed screen.
  goldenMatrix(
    's12_rewarded_granted',
    (_) => Builder(
      builder: (context) => ColoredBox(
        color: context.tokens.color.bg.scrim,
        child: RewardedLayout(
          state: const RewardedState.granted(amount: 1),
          onClose: () {},
        ),
      ),
    ),
    keyScreen: true,
    accessibility: true,
    pump: _pump,
  );
}
