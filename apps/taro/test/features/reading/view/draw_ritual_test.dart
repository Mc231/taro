import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taro/common/disclaimer_footer.dart';
import 'package:taro/features/reading/controller/draw_state.dart';
import 'package:taro/features/reading/controller/reading_session.dart';
import 'package:taro/features/reading/view/draw_screen.dart';
import 'package:taro/features/reading/view/question_screen.dart';
import 'package:taro/l10n/generated/taro_localizations.dart';
import 'package:taro/routing/routes.dart';
import 'package:taro_core/taro_core.dart';
import 'package:taro_ui/taro_ui.dart';

import '../../flow_view_support.dart';

/// S08 ritual details (Sprint 16.3): motion, reduced motion, haptics, the
/// screen-reader path, the leave dialog, the footer and large text.
DrawView _view({
  int placed = 0,
  int revealed = 0,
  bool autoDraw = false,
  bool reducedMotion = false,
  String? question,
}) => DrawView(
  spread: aSpread().build(),
  draw: aDraw(),
  classic: false,
  placed: placed,
  revealed: revealed,
  autoDraw: autoDraw,
  reducedMotion: reducedMotion,
  readingId: const ReadingId('r-1'),
  question: question,
);

/// Turns animations back on under the test harness (which reduces motion).
class _Motion extends StatelessWidget {
  const _Motion({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => MediaQuery(
    data: MediaQuery.of(context).copyWith(disableAnimations: false),
    child: child,
  );
}

Finder _deck() => find.byWidgetPredicate(
  (w) => w is GestureDetector && w.onLongPressStart != null,
);

void main() {
  late TaroLocalizations l10n;
  final haptics = <String>[];

  setUpAll(() async => l10n = await enL10n());

  setUp(() {
    haptics.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'HapticFeedback.vibrate') {
            haptics.add('${call.arguments}');
          }
          return null;
        });
  });

  tearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null),
  );

  Future<List<String>> pumpLayout(
    WidgetTester tester,
    DrawState state, {
    bool motion = false,
    double textScale = 1,
    Locale locale = const Locale('en'),
  }) async {
    final calls = <String>[];
    final layout = DrawLayout(
      state: state,
      onClose: () => calls.add('close'),
      onShuffled: () => calls.add('shuffled'),
      onPick: () => calls.add('pick'),
      onDrawForMe: () => calls.add('drawForMe'),
      onReveal: () => calls.add('reveal'),
      onRevealAll: () => calls.add('revealAll'),
      onRetry: () => calls.add('retry'),
      onFinishLater: () => calls.add('later'),
      onOpenOptions: () => calls.add('options'),
    );
    await pumpTaro(
      tester,
      motion ? _Motion(child: layout) : layout,
      fakes: aiReadyFakes(),
      textScale: textScale,
      locale: locale,
    );
    await tester.pumpAndSettle();
    return calls;
  }

  TaroButton button(WidgetTester tester, String label) =>
      tester.widget<TaroButton>(find.widgetWithText(TaroButton, label));

  group('shuffling', () {
    testWidgets('the shuffle runs motion.ritual.shuffle before Ready', (
      tester,
    ) async {
      await pumpLayout(
        tester,
        DrawState.shuffling(_view()),
        motion: true,
      );
      await tester.tap(find.text(l10n.drawShuffleButton));
      await tester.pump(const Duration(milliseconds: 600));
      expect(button(tester, l10n.drawShuffleReady).onPressed, isNull);
      await tester.pumpAndSettle();
      expect(button(tester, l10n.drawShuffleReady).onPressed, isNotNull);
    });

    testWidgets('holding the deck shuffles until released', (tester) async {
      await pumpLayout(
        tester,
        DrawState.shuffling(_view()),
        motion: true,
      );
      final deck = _deck();
      final gesture = await tester.startGesture(tester.getCenter(deck));
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump(const Duration(milliseconds: 2400));
      expect(button(tester, l10n.drawShuffleReady).onPressed, isNull);
      await gesture.up();
      await tester.pumpAndSettle();
      expect(button(tester, l10n.drawShuffleReady).onPressed, isNotNull);
    });

    testWidgets('a tap on the deck shuffles too; the reduced-motion '
        'setting applies', (tester) async {
      await pumpLayout(
        tester,
        DrawState.shuffling(_view(reducedMotion: true)),
        motion: true,
      );
      final layout = find.byType(TaroScaffold);
      expect(
        MediaQuery.disableAnimationsOf(tester.element(layout)),
        isTrue,
      );
      await tester.tap(_deck());
      await tester.pump();
      // The reduced shuffle is a 200 ms cross-fade.
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pump();
      expect(button(tester, l10n.drawShuffleReady).onPressed, isNotNull);
    });
  });

  group('picking', () {
    testWidgets('Pick this card picks the centre card with haptic.pick', (
      tester,
    ) async {
      final calls = await pumpLayout(
        tester,
        DrawState.picking(_view(placed: 1)),
      );
      await tapFound(tester, find.text(l10n.drawPickThis));
      await tapFound(tester, find.text(l10n.drawForMe));
      expect(calls, ['pick', 'drawForMe']);
      expect(haptics, everyElement('HapticFeedbackType.selectionClick'));
      expect(haptics, hasLength(2));
    });

    testWidgets('screen-reader labels: deck, slots, fan cards', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpLayout(tester, DrawState.picking(_view(placed: 1)));
      expect(
        find.bySemanticsLabel(l10n.drawDeckSemantics(Deck.size - 1)),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(
          l10n.drawSlotBackSemantics(1, 3, l10n.spread_three_ppf_pos_past_name),
        ),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(
          l10n.drawEmptySlotSemantics(3, l10n.spread_three_ppf_pos_future_name),
        ),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(l10n.drawCardBackSemantics(2, 3)),
        findsWidgets,
      );
      expect(find.text(l10n.drawPickedProgress(1, 3)), findsOneWidget);
      handle.dispose();
    });

    testWidgets('Draw for me deals the cards in with the stagger', (
      tester,
    ) async {
      await pumpLayout(tester, DrawState.picking(_view()), motion: true);
      await pumpLayout(
        tester,
        DrawState.picking(_view(placed: 3, autoDraw: true)),
        motion: true,
      );
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();
      expect(find.text(l10n.drawRevealTitle), findsOneWidget);
      // Every card is placed: the fan's actions are off.
      expect(button(tester, l10n.drawForMe).onPressed, isNull);
    });
  });

  group('revealing', () {
    testWidgets('the next card is labelled for the screen reader; the '
        'flip plays haptic.flip', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpLayout(
        tester,
        DrawState.revealing(_view(placed: 3, question: 'How do I grow?')),
      );
      final past = l10n.spread_three_ppf_pos_past_name;
      expect(
        find.bySemanticsLabel(l10n.drawSlotRevealSemantics(1, 3, past)),
        findsOneWidget,
      );
      expect(find.text(l10n.drawTapToReveal), findsOneWidget);
      expect(find.text(l10n.drawRevealedProgress(0, 3)), findsOneWidget);
      // BUG-11: the question keeps its own direction in an RTL UI.
      expect(find.text(firstStrongIsolate('How do I grow?')), findsOneWidget);
      // The parent flips the first card.
      await pumpLayout(
        tester,
        DrawState.revealing(_view(placed: 3, revealed: 1)),
      );
      expect(haptics, contains('HapticFeedbackType.lightImpact'));
      expect(find.byType(TaroCardFace), findsOneWidget);
      handle.dispose();
    });

    testWidgets('revealed cards read name, orientation and position', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpLayout(
        tester,
        DrawState.revealing(_view(placed: 3, revealed: 2)),
      );
      final face = tester.widgetList<TaroCardFace>(find.byType(TaroCardFace));
      expect(face, hasLength(2));
      expect(face.last.reversed, isTrue);
      expect(
        face.last.semanticsLabel,
        contains(l10n.spread_three_ppf_pos_present_name),
      );
      expect(face.last.semanticsLabel, contains(l10n.commonReversed));
      handle.dispose();
    });
  });

  testWidgets('every state after the pick carries the disclaimer footer', (
    tester,
  ) async {
    final done = _view(placed: 3, revealed: 3);
    for (final state in [
      DrawState.revealing(_view(placed: 3)),
      DrawState.awaitingReading(done),
      DrawState.slowReading(done),
      DrawState.timeoutPolling(done),
      DrawState.generationFailed(done, failure: const Failure.aiUnavailable()),
      DrawState.deliveryExpired(done),
      DrawState.holdLost(done),
    ]) {
      await pumpLayout(tester, state);
      expect(find.byType(DisclaimerFooter), findsOneWidget, reason: '$state');
    }
  });

  testWidgets('slowReading: Finish later; no percentage anywhere', (
    tester,
  ) async {
    final calls = await pumpLayout(
      tester,
      DrawState.slowReading(_view(placed: 3, revealed: 3)),
    );
    expect(find.text(l10n.drawSlowReading), findsOneWidget);
    expect(find.textContaining('%'), findsNothing);
    await tapFound(tester, find.text(l10n.drawFinishLater));
    expect(calls, ['later']);
  });

  testWidgets('awaitingReading: keywords per position', (tester) async {
    await pumpLayout(
      tester,
      DrawState.awaitingReading(_view(placed: 3, revealed: 3)),
    );
    expect(find.text(l10n.drawAwaitingTitle), findsOneWidget);
    expect(find.text(l10n.spread_three_ppf_pos_future_name), findsWidgets);
    expect(find.textContaining(' · '), findsWidgets);
  });

  for (final (name, state) in [
    ('shuffling', DrawState.shuffling(_view())),
    ('picking', DrawState.picking(_view(placed: 1))),
    ('revealing', DrawState.revealing(_view(placed: 3, revealed: 1))),
    ('awaitingReading', DrawState.awaitingReading(_view(placed: 3))),
  ]) {
    testWidgets('$name at 200 % text and in RTL: no overflow', (
      tester,
    ) async {
      await pumpLayout(tester, state, textScale: 2);
      expect(tester.takeException(), isNull);
      await pumpLayout(tester, state, locale: const Locale('ar'));
      expect(tester.takeException(), isNull);
    });
  }

  group('screen', () {
    Future<ProviderContainer> open(
      WidgetTester tester,
      TaroFakes fakes,
      ReadingSession session,
    ) async {
      final router = await pumpFlow(
        tester,
        path: RoutePaths.readingDraw,
        location: '/',
        builder: (_) => const DrawScreen(),
        fakes: fakes,
      );
      final container = ProviderScope.containerOf(
        tester.element(find.text('route:/')),
      );
      container.read(readingSessionProvider.notifier).start(session);
      router.push(RoutePaths.readingDraw).ignore();
      await tester.pumpAndSettle();
      return container;
    }

    ReadingSession ai() => ReadingSession(
      spread: aSpread().build(),
      source: ReadingFlowSource.home,
      locale: 'en',
      hold: aReadingHold(),
    );

    Future<void> startPicking(WidgetTester tester) async {
      await tapFound(tester, find.text(l10n.drawShuffleButton));
      await tapFound(tester, find.text(l10n.drawShuffleReady));
    }

    testWidgets('the whole ritual by buttons alone (screen-reader path); '
        'haptic.ready when the reading arrives', (tester) async {
      final fakes = aiReadyFakes();
      await open(tester, fakes, ai());
      await startPicking(tester);
      await tapFound(tester, find.text(l10n.drawForMe));
      await tapFound(tester, find.text(l10n.drawRevealAll));
      final reading = fakes.journal.readings.values.single;
      expectRoute(RoutePaths.reading(reading.id.value));
      expect(haptics, contains('HapticFeedbackType.mediumImpact'));
    });

    testWidgets('Close after a pick asks first; Stay keeps the draw', (
      tester,
    ) async {
      await open(tester, aiReadyFakes(), ai());
      await startPicking(tester);
      await tapFound(tester, find.text(l10n.drawPickThis));
      await tester.tap(find.byTooltip(l10n.commonClose));
      await tester.pumpAndSettle();
      expect(find.text(l10n.drawLeaveTitle), findsOneWidget);
      expect(find.text(l10n.drawLeaveBody), findsOneWidget);
      await tester.tap(find.text(l10n.drawLeaveStay));
      await tester.pumpAndSettle();
      expect(find.text(l10n.drawLeaveTitle), findsNothing);
      expect(find.text(l10n.drawPickTitle(2)), findsOneWidget);
    });

    testWidgets('Close once every card is placed: saved copy; Leave goes '
        'Home', (tester) async {
      final fakes = aiReadyFakes();
      await open(tester, fakes, ai());
      await startPicking(tester);
      await tapFound(tester, find.text(l10n.drawForMe));
      await tester.tap(find.byTooltip(l10n.commonClose));
      await tester.pumpAndSettle();
      expect(find.text(l10n.drawLeaveBodySaved), findsOneWidget);
      await tester.tap(find.text(l10n.drawLeaveConfirm));
      await tester.pumpAndSettle();
      expectRoute(RoutePaths.home);
    });
  });

  testWidgets('S07 precaches a preset card (Reflect deeper)', (tester) async {
    await pumpFlow(
      tester,
      path: RoutePaths.readingQuestionPath,
      location: RoutePaths.readingQuestion(
        'single',
        source: 'daily_card',
        cardId: 'major_17',
      ),
      builder: (state) => QuestionScreen.fromQuery(state.uri.queryParameters),
      fakes: aiReadyFakes(),
    );
    expect(find.text(l10n.questionTitle), findsOneWidget);
    expect(find.byType(TaroCardFace), findsNothing);
  });
}
