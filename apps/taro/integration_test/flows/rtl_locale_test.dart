import 'package:flutter/widgets.dart';
import 'package:taro/common/balance_chip.dart';

import '../support/flow_harness.dart';

/// RTL (01 §12, rule 14; 06 §4): Settings → Language → العربية applies at
/// once → the layout is mirrored → a reading completes in Arabic.
void main() {
  taroFlow('Arabic: mirrored layout, the reading flow completes', ($) async {
    final fakes = flowFakes();
    final app = await FlowApp.launch($, fakes: fakes);
    final en = app.l10n();
    await app.waitForScreen(ScreenId.s05);
    final width =
        $.tester.view.physicalSize.width / $.tester.view.devicePixelRatio;
    expect(
      $.tester.getCenter(find.byType(BalanceChip)).dx,
      greaterThan(width / 2),
    );

    await app.tapText(en.tabSettings);
    await app.waitForScreen(ScreenId.s20);
    await app.tapText(en.settingsLanguage);
    await app.waitForScreen(ScreenId.s21);
    await app.tapFinder(find.byKey(const ValueKey('ar')));
    // The content locale follows the app locale (resolveAppLocale in prod).
    fakes.locale = 'ar';
    await app.settle();
    expect(
      Directionality.of($.tester.element(app.screen(ScreenId.s21))),
      TextDirection.rtl,
    );
    expect(fakes.settings.current.localeOverride, 'ar');

    final ar = app.l10n('ar');
    await app.tapFinder(find.bySemanticsLabel(ar.commonBack));
    await app.waitForScreen(ScreenId.s20);
    await app.tapText(ar.tabToday);
    await app.waitForScreen(ScreenId.s05);
    // Mirrored: the balance chip sits at the start (the left in RTL).
    expect(
      $.tester.getCenter(find.byType(BalanceChip)).dx,
      lessThan(width / 2),
    );

    await app.tapButton(ar.homeStartReading);
    await app.waitForScreen(ScreenId.s06);
    await app.tapText(ar.spread_three_ppf_name);
    await app.waitForScreen(ScreenId.s07);
    await app.enterQuestion('ما الذي يجب أن أركز عليه؟');
    await app.tapButton(ar.questionBegin);
    await app.waitForScreen(ScreenId.s08);
    await app.tapButton(ar.drawShuffleButton);
    await app.tapButton(ar.drawForMe);
    await app.tapButton(ar.drawRevealAll);
    await app.waitForScreen(ScreenId.s09);
    expect(
      Directionality.of($.tester.element(app.screen(ScreenId.s09))),
      TextDirection.rtl,
    );
    expect(fakes.readings.holds.single.$3, 'ar');
    await app.waitUntil(() => fakes.readings.acked.isNotEmpty);
  });
}
