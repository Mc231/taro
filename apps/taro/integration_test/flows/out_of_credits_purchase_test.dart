import 'package:flutter/widgets.dart';
import 'package:taro_ui/taro_ui.dart';

import '../support/flow_harness.dart';

/// F3 (01 §9.3, 04 §6.2, 06 §4): the free reading is used → Begin → the
/// hold returns `402` → S10 before any draw → S11 → buy
/// `com.vshyrochuk.taro.readings_3` (fake store) → outbox row → Worker
/// grant → finish only after the grant (rule 8) → back on S07 with Begin
/// enabled and nothing auto-started (RC3, RC58) → Begin → hold → reading.
void main() {
  taroFlow('out of readings: purchase, then Begin again', ($) async {
    final exhausted = aCreditBalance().withFreeRemaining(0).build();
    final fakes = flowFakes()
      ..verifier = FakePurchaseVerifier(balance: exhausted);
    final order = CallRecorder();
    fakes
      ..iap.recorder = order
      ..outbox.recorder = order
      ..verifier.recorder = order;
    // The cache still says the free reading is there (used on another
    // path); the Worker knows better: the hold is refused, so the paywall
    // comes before any draw.
    fakes.readings.failNext(
      Failure.insufficientCredits(
        reason: InsufficientReason.noCredits,
        balance: exhausted,
      ),
      on: 'hold',
    );

    final app = await FlowApp.launch($, fakes: fakes);
    final l = app.l10n();
    await app.openQuestion();
    await app.begin();
    await app.waitForScreen(ScreenId.s10);
    expect(app.screen(ScreenId.s08), findsNothing);
    expect(fakes.readings.holds, hasLength(1));
    expect(fakes.readings.submitted, isEmpty);

    await app.tapText(l.outOfReadingsGetMore);
    await app.waitForScreen(ScreenId.s11);
    await app.tapFinder(
      find.descendant(
        of: find.byKey(ValueKey(TaroProducts.readings3.id)),
        matching: find.byType(TaroButton),
      ),
    );
    await app.waitFor(find.text(l.storeGranted(3)));

    final txn = fakes.iap.finished.single;
    expect(fakes.verifier.verifications.single.$1.txnKey, txn);
    expect(
      order.isBefore('PurchaseOutbox.enqueue', 'PurchaseVerifier.verify'),
      isTrue,
    );
    expect(
      order.isBefore('PurchaseVerifier.verify', 'IapService.finish'),
      isTrue,
    );
    expect(fakes.balance.cached?.paid, 3);

    // Opened from S10, the store closes after the grant toast (RC58).
    await app.waitForScreen(ScreenId.s07);
    // Nothing auto-starts (RC58): still one hold, no draw screen.
    await app.settle();
    expect(app.screen(ScreenId.s08), findsNothing);
    expect(fakes.readings.holds, hasLength(1));

    await app.tapButton(l.questionBegin);
    await app.drawAndRevealAll();
    await app.waitForScreen(ScreenId.s09);
    expect(fakes.readings.holds, hasLength(2));
    await app.waitUntil(() => fakes.readings.acked.isNotEmpty);
    expect(
      fakes.journal.readings.values.single.status,
      isA<ReadingStatusComplete>(),
    );
  });
}
