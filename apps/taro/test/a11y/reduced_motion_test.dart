import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taro/features/daily_card/controller/daily_card_controller.dart';
import 'package:taro/features/daily_card/view/daily_card_screen.dart';
import 'package:taro/features/paywall/controller/rewarded_controller.dart';
import 'package:taro/features/paywall/view/rewarded_screen.dart';
import 'package:taro/features/reading/controller/draw_state.dart';
import 'package:taro/features/reading/controller/reading_result_controller.dart';
import 'package:taro/features/reading/view/draw_screen.dart';
import 'package:taro/features/reading/view/reading_result_screen.dart';
import 'package:taro/l10n/generated/taro_localizations.dart';
import 'package:taro_core/taro_core.dart';
import 'package:taro_ui/taro_ui.dart';

import '../features/flow_view_support.dart';
import 'a11y_support.dart';

/// Sprint 19.4 (01 §12, §14.4): with reduce motion on, every ritual
/// animation (shuffle, deal, flip, the daily reveal, the reading reveal
/// and the rewarded wait) is at most a 200 ms cross-fade: every ticker
/// settles within [kReducedRitualBudget], and nothing moves, rotates or
/// sways on the way. The test harness reduces motion (the system setting,
/// `MediaQuery.disableAnimations`); [_Motion] turns it back on for the
/// controls that prove the measurement.

DrawView _view({int placed = 0, int revealed = 0, bool autoDraw = false}) =>
    DrawView(
      spread: aSpread().build(),
      draw: aDraw(),
      classic: false,
      placed: placed,
      revealed: revealed,
      autoDraw: autoDraw,
      readingId: const ReadingId('r-1'),
    );

class _Motion extends StatelessWidget {
  const _Motion({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => MediaQuery(
    data: MediaQuery.of(context).copyWith(disableAnimations: false),
    child: child,
  );
}

/// Every `Transform` under [of] is a pure translation of zero and no
/// rotation (cards cross-fade in place).
void _expectNoMovement(WidgetTester tester, Finder of) {
  final transforms = tester.widgetList<Transform>(
    find.descendant(of: of, matching: find.byType(Transform)),
  );
  for (final t in transforms) {
    expect(t.transform.isIdentity(), isTrue, reason: '${t.transform}');
  }
}

/// Some `Opacity` under [of] is part-way (a cross-fade in progress).
void _expectCrossFading(WidgetTester tester, Finder of) {
  final opacities = tester.widgetList<Opacity>(
    find.descendant(of: of, matching: find.byType(Opacity)),
  );
  expect(
    opacities.any((o) => o.opacity > 0 && o.opacity < 1),
    isTrue,
    reason: 'a cross-fade is in progress',
  );
}

void main() {
  late TaroLocalizations l10n;

  setUpAll(() async => l10n = await enL10n());

  setUp(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          SystemChannels.platform,
          (call) async => null,
        ),
  );

  tearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null),
  );

  /// Pumps S08 once over [state]; the returned notifier moves it to the
  /// next state inside the same app (so only the ritual animates, not a
  /// rebuilt theme).
  Future<ValueNotifier<DrawState>> pumpDraw(
    WidgetTester tester,
    DrawState state, {
    bool motion = false,
  }) async {
    final notifier = ValueNotifier(state);
    addTearDown(notifier.dispose);
    final layout = ValueListenableBuilder<DrawState>(
      valueListenable: notifier,
      builder: (context, value, _) => DrawLayout(
        state: value,
        onClose: noop,
        onShuffled: noop,
        onPick: noop,
        onDrawForMe: noop,
        onReveal: noop,
        onRevealAll: noop,
        onRetry: noop,
        onFinishLater: noop,
        onOpenOptions: noop,
      ),
    );
    await pumpTaro(
      tester,
      motion ? _Motion(child: layout) : layout,
      fakes: aiReadyFakes(),
    );
    await tester.pumpAndSettle();
    return notifier;
  }

  group('S08 draw', () {
    testWidgets('shuffle: a 200 ms cross-fade dip, the deck never sways', (
      tester,
    ) async {
      await pumpDraw(tester, DrawState.shuffling(_view()));
      await tester.tap(find.text(l10n.drawShuffleButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      final deck = find.byWidgetPredicate(
        (w) => w is GestureDetector && w.onLongPressStart != null,
      );
      _expectCrossFading(tester, deck);
      final translations = tester.widgetList<Transform>(
        find.descendant(of: deck, matching: find.byType(Transform)),
      );
      // Only the static fan tilt; no sway offset.
      for (final t in translations) {
        expect(t.transform.getTranslation().x, 0);
      }
      expect(await settleTime(tester), lessThanOrEqualTo(kReducedRitualBudget));
      final ready = tester.widget<TaroButton>(
        find.widgetWithText(TaroButton, l10n.drawShuffleReady),
      );
      expect(ready.onPressed, isNotNull);
    });

    testWidgets('deal (Draw for me): the cards fade in place, no stagger', (
      tester,
    ) async {
      final draw = await pumpDraw(tester, DrawState.picking(_view()));
      draw.value = DrawState.picking(_view(placed: 3, autoDraw: true));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      final canvas = find.byType(SpreadCanvas);
      _expectCrossFading(tester, canvas);
      _expectNoMovement(tester, canvas);
      expect(await settleTime(tester), lessThanOrEqualTo(kReducedRitualBudget));
    });

    testWidgets('flip (Reveal all): a 200 ms cross-fade, never a rotation', (
      tester,
    ) async {
      final draw = await pumpDraw(
        tester,
        DrawState.revealing(_view(placed: 3)),
      );
      draw.value = DrawState.revealing(_view(placed: 3, revealed: 3));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      final flips = find.byType(TaroCardFlip);
      expect(flips, findsNWidgets(3));
      _expectCrossFading(tester, flips);
      _expectNoMovement(tester, flips);
      expect(await settleTime(tester), lessThanOrEqualTo(kReducedRitualBudget));
      expect(find.byType(TaroCardFace), findsNWidgets(3));
    });

    testWidgets('control: with motion on the flip rotates and takes longer', (
      tester,
    ) async {
      final draw = await pumpDraw(
        tester,
        DrawState.revealing(_view(placed: 3)),
        motion: true,
      );
      draw.value = DrawState.revealing(_view(placed: 3, revealed: 3));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      final rotating = tester.widgetList<Transform>(
        find.descendant(
          of: find.byType(TaroCardFlip),
          matching: find.byType(Transform),
        ),
      );
      expect(rotating.any((t) => !t.transform.isIdentity()), isTrue);
      expect(await settleTime(tester), greaterThan(kReducedRitualBudget));
    });
  });

  testWidgets('S13 daily reveal: the flip and the texts within 200 ms', (
    tester,
  ) async {
    final card = aDailyCard().withCard('major_17').build();
    final view = DailyCardView(
      card: card,
      text: aCardText(card.cardId),
      deckCard: deckCardFor(card.cardId),
    );
    final daily = ValueNotifier<DailyCardState>(
      const DailyCardState.notDrawn(),
    );
    addTearDown(daily.dispose);
    await pumpTaroWidget(
      tester,
      ValueListenableBuilder<DailyCardState>(
        valueListenable: daily,
        builder: (context, state, _) => DailyCardLayout(
          state: state,
          today: DateTime(2026, 9, 27, 9),
          onClose: noop,
          onReveal: noop,
          onRetry: noop,
          onReflectDeeper: noop,
          onEditNote: noop,
          onCancelNote: noop,
          onSaveNote: noop1,
          onToggleFavourite: noop,
          onAnswerReminder: ({required accepted}) {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    daily.value = const DailyCardState.revealing();
    await tester.pump();
    daily.value = DailyCardState.drawn(view);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    final flip = find.byType(TaroCardFlip);
    _expectCrossFading(tester, flip);
    _expectNoMovement(tester, flip);
    expect(await settleTime(tester), lessThanOrEqualTo(kReducedRitualBudget));
    expect(find.text(view.shortMeaning), findsOneWidget);
  });

  testWidgets('S09 reading reveal: every section at once', (tester) async {
    final reading = aReading().build();
    await pumpTaroWidget(
      tester,
      ReadingResultLayout(
        state: ReadingResultState.content(
          ReadingResultView(
            reading: reading,
            cardTexts: {
              for (final c in reading.cards) c.cardId: aCardText(c.cardId),
            },
          ),
        ),
        reveal: true,
        onDone: noop,
        onOpenDisclaimer: noop,
        onRate: (_, _) {},
        onToggleFavourite: noop,
        onReport: noop,
        onAddNote: noop,
        onWriteAbout: noop1,
        onShare: (_, {required includeQuestion}) {},
      ),
    );
    await tester.pump();
    // No section is faded out or still rising on the first frame.
    final opacities = tester.widgetList<Opacity>(
      find.descendant(
        of: find.byType(ReadingTextView),
        matching: find.byType(Opacity),
      ),
    );
    expect(opacities.every((o) => o.opacity == 1), isTrue);
    expect(await settleTime(tester), lessThanOrEqualTo(kReducedRitualBudget));
  });

  for (final state in const [
    RewardedState.loadingAd(),
    RewardedState.granting(),
  ]) {
    testWidgets('S12 ${state.runtimeType}: a still ring, no endless spin', (
      tester,
    ) async {
      await pumpTaroWidget(
        tester,
        RewardedLayout(state: state, onClose: noop),
      );
      await tester.pump();
      final ring = tester.widget<CircularProgressIndicator>(
        find.byType(CircularProgressIndicator),
      );
      expect(ring.value, isNotNull);
      expect(tester.binding.hasScheduledFrame, isFalse);
    });
  }

  testWidgets('control: S12 spins with motion on', (tester) async {
    await pumpTaroWidget(
      tester,
      const _Motion(
        child: RewardedLayout(state: RewardedState.loadingAd(), onClose: noop),
      ),
    );
    await tester.pump();
    final ring = tester.widget<CircularProgressIndicator>(
      find.byType(CircularProgressIndicator),
    );
    expect(ring.value, isNull);
    expect(tester.binding.hasScheduledFrame, isTrue);
  });
}
