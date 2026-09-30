import 'package:flutter/widgets.dart';
import 'package:taro/common/balance_chip.dart';
import 'package:taro/common/banner_slot.dart';
import 'package:taro_ui/taro_ui.dart';

import '../support/flow_harness.dart';

/// F4 (01 §9.4, 04 §6.3): buy Remove Banner Ads (a non-consumable: no
/// Worker grant, finished at once) → the Home banner slot is gone → a
/// fresh app (new install state, the same store account, a silent
/// ownership query) shows the banner again → Settings → Restore
/// purchases → the banner is gone.
void main() {
  taroFlow('Remove Ads: purchase, fresh install, restore', ($) async {
    final fakes = flowFakes();
    final app = await FlowApp.launch($, fakes: fakes);
    final l = app.l10n();
    await app.waitForScreen(ScreenId.s05);
    await app.$(BannerSlot).waitUntilExists();

    await app.tapFinder(find.byType(BalanceChip));
    await app.waitForScreen(ScreenId.s11);
    await app.tapFinder(
      find.descendant(
        of: find.byKey(ValueKey(TaroProducts.removeAds.id)),
        matching: find.byType(TaroButton),
      ),
    );
    await app.waitFor(find.text(l.storeRemoveAdsOwned));
    expect(fakes.iap.owned, contains(TaroProducts.removeAds.id));
    expect(fakes.iap.finished, hasLength(1));
    expect(fakes.verifier.verifications, isEmpty, reason: 'no Worker grant');
    await app.tapFinder(find.bySemanticsLabel(l.commonClose));
    await app.waitForScreen(ScreenId.s05);
    await app.waitUntil(() => !$.tester.any(find.byType(BannerSlot)));

    // A fresh app state on the same store account; the silent ownership
    // query gets no answer, so only Restore brings the entitlement back.
    await app.shutdown();
    final fresh = flowFakes()..iap = fakes.iap;
    fresh.storeOwnership = FakeStoreOwnership(fresh.iap)
      ..next = const Result.err(Failure.network());
    final again = await FlowApp.launch($, fakes: fresh);
    await again.waitForScreen(ScreenId.s05);
    await again.$(BannerSlot).waitUntilExists();

    await again.tapText(l.tabSettings);
    await again.waitForScreen(ScreenId.s20);
    await again.tapText(l.storeRestore);
    await again.waitFor(find.text(l.restoreRemoveAds));
    expect(fresh.iap.calls, contains('restore'));
    expect(fresh.entitlements.entitlement.removesAds, isTrue);

    await again.tapText(l.tabToday);
    await again.waitForScreen(ScreenId.s05);
    await again.waitUntil(() => !$.tester.any(find.byType(BannerSlot)));
  });
}
