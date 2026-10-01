import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:taro/common/banner_slot.dart';
import 'package:taro/features/reading/controller/draw_controller.dart';
import 'package:taro/features/reading/controller/draw_state.dart';
import 'package:taro/features/reading/controller/reading_session.dart';
import 'package:taro/features/reading/view/draw_screen.dart';
import 'package:taro/l10n/generated/taro_localizations.dart';
import 'package:taro/routing/routes.dart';
import 'package:taro_core/taro_core.dart';
import 'package:taro_ui/taro_ui.dart';

import '../../flow_view_support.dart';

DrawView _view({int placed = 0, int revealed = 0, bool classic = false}) =>
    DrawView(
      spread: aSpread().build(),
      draw: aDraw(),
      classic: classic,
      placed: placed,
      revealed: revealed,
      readingId: const ReadingId('r-1'),
    );

void main() {
  late TaroLocalizations l10n;

  setUpAll(() async => l10n = await enL10n());

  Future<List<String>> pumpLayout(
    WidgetTester tester,
    DrawState state,
  ) async {
    final calls = <String>[];
    await pumpTaro(
      tester,
      DrawLayout(
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
      ),
      fakes: aiReadyFakes(),
    );
    await tester.pumpAndSettle();
    expect(find.byType(BannerSlot), findsNothing);
    return calls;
  }

  Finder faces() => find.byType(TaroCardFace, skipOffstage: false);

  /// Shuffle once, then "I'm ready — draw".
  Future<void> startPicking(WidgetTester tester) async {
    await tapFound(tester, find.text(l10n.drawShuffleButton));
    await tapFound(tester, find.text(l10n.drawShuffleReady));
  }

  /// "Draw for me" (after the shuffle, when still shuffling).
  Future<void> drawForMe(WidgetTester tester) async {
    if (find.text(l10n.drawShuffleReady).evaluate().isNotEmpty) {
      await startPicking(tester);
    }
    await tapFound(tester, find.text(l10n.drawForMe));
  }

  testWidgets('unavailable / preparing: loading, no faces', (tester) async {
    await pumpLayout(tester, const DrawState.unavailable());
    expect(find.byType(TaroLoadingView), findsOneWidget);
    await pumpLayout(tester, const DrawState.preparing());
    expect(find.byType(TaroLoadingView), findsOneWidget);
    expect(faces(), findsNothing);
  });

  testWidgets('shuffling: ready only after one shuffle; every card '
      'face-down', (tester) async {
    final calls = await pumpLayout(tester, DrawState.shuffling(_view()));
    expect(find.text(l10n.drawShuffleTitle), findsOneWidget);
    expect(find.text(l10n.drawShuffleNote), findsOneWidget);
    expect(faces(), findsNothing);
    TaroButton ready() => tester.widget<TaroButton>(
      find.widgetWithText(TaroButton, l10n.drawShuffleReady),
    );
    expect(ready().onPressed, isNull);
    await tapFound(tester, find.text(l10n.drawShuffleButton));
    expect(ready().onPressed, isNotNull);
    await tapFound(tester, find.text(l10n.drawShuffleReady));
    expect(calls, ['shuffled']);
  });

  testWidgets('picking: the fan picks; progress in the bar; no faces', (
    tester,
  ) async {
    final calls = await pumpLayout(
      tester,
      DrawState.picking(_view(placed: 1)),
    );
    expect(find.text(l10n.drawPickTitle(2)), findsOneWidget);
    expect(find.text(l10n.drawPickedProgress(1, 3)), findsOneWidget);
    expect(faces(), findsNothing);
    await tester.tap(find.byType(TaroCardBack).last);
    expect(calls, ['pick']);
  });

  testWidgets('revealing: only revealed cards show a face', (tester) async {
    final calls = await pumpLayout(
      tester,
      DrawState.revealing(_view(placed: 3, revealed: 1)),
    );
    expect(find.text(l10n.drawRevealTitle), findsOneWidget);
    expect(faces(), findsOneWidget);
    await tester.tap(
      find.byWidgetPredicate((w) => w is TaroCardBack && w.onTap != null),
    );
    await tapFound(tester, find.text(l10n.drawRevealAll));
    expect(calls, ['reveal', 'revealAll']);
  });

  for (final (name, state, status) in [
    ('awaitingReading', DrawState.awaitingReading, null),
    ('slowReading', DrawState.slowReading, 'slow'),
    ('timeoutPolling', DrawState.timeoutPolling, 'polling'),
  ]) {
    testWidgets('$name: every face with keywords', (tester) async {
      await pumpLayout(tester, state(_view(placed: 3, revealed: 3)));
      expect(find.text(l10n.drawAwaitingTitle), findsOneWidget);
      expect(faces(), findsNWidgets(3));
      if (status == 'slow') {
        expect(find.text(l10n.drawSlowReading), findsOneWidget);
      }
      if (status == 'polling') {
        expect(find.text(l10n.drawTimeoutPolling), findsOneWidget);
      }
    });
  }

  testWidgets('reducedMotion variant renders the same state', (tester) async {
    await pumpLayout(
      tester,
      DrawState.shuffling(_view().copyWith(reducedMotion: true)),
    );
    expect(find.text(l10n.drawShuffleTitle), findsOneWidget);
  });

  testWidgets('generationFailed: cards kept, Try again, finish later', (
    tester,
  ) async {
    final calls = await pumpLayout(
      tester,
      DrawState.generationFailed(
        _view(placed: 3, revealed: 3),
        failure: const Failure.aiUnavailable(),
      ),
    );
    expect(find.text(l10n.drawGenerationFailedTitle), findsOneWidget);
    expect(faces(), findsNWidgets(3));
    await tapFound(tester, find.text(l10n.commonRetry));
    await tapFound(tester, find.text(l10n.drawFinishLater));
    expect(calls, ['retry', 'later']);
  });

  testWidgets('holdLost: every card face-down; reading options', (
    tester,
  ) async {
    final calls = await pumpLayout(
      tester,
      DrawState.holdLost(_view(placed: 3, revealed: 2)),
    );
    expect(find.text(l10n.drawHoldLost), findsOneWidget);
    expect(faces(), findsNothing);
    await tapFound(tester, find.text(l10n.outOfReadingsGetMore));
    expect(calls, ['options']);
  });

  testWidgets('deliveryExpired: not charged + Try again', (tester) async {
    final calls = await pumpLayout(
      tester,
      DrawState.deliveryExpired(_view(placed: 3, revealed: 3)),
    );
    expect(find.text(l10n.drawDeliveryExpired), findsOneWidget);
    await tapFound(tester, find.text(l10n.commonRetry));
    expect(calls, ['retry']);
  });

  testWidgets('crisis / returnedToQuestion / completed: leaving', (
    tester,
  ) async {
    final reading = aReading().build();
    for (final state in [
      DrawState.crisis(
        _view(placed: 3, revealed: 3),
        safety: const SafetyInfo(
          category: RefusalCategory.selfHarm,
          messageKey: 'safetyDeclinedSelfHarm',
          canRephrase: false,
        ),
      ),
      DrawState.returnedToQuestion(_view()),
      DrawState.completed(_view(), reading: reading),
    ]) {
      await pumpLayout(tester, state);
      expect(find.byType(TaroLoadingView), findsOneWidget);
    }
  });

  testWidgets('failed: error view and Back to Today', (tester) async {
    final calls = await pumpLayout(
      tester,
      const DrawState.failed(failure: Failure.storage()),
    );
    expect(find.text(l10n.errorStorageTitle), findsOneWidget);
    await tapFound(tester, find.text(l10n.commonBackToToday));
    expect(calls, ['close']);
  });

  group('screen', () {
    Future<(GoRouter, ProviderContainer)> open(
      WidgetTester tester,
      TaroFakes fakes,
      ReadingSession? session,
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
      if (session != null) {
        container.read(readingSessionProvider.notifier).start(session);
      }
      router.push(RoutePaths.readingDraw).ignore();
      await tester.pumpAndSettle();
      return (router, container);
    }

    ReadingSession classic() => ReadingSession(
      spread: aSpread().build(),
      source: ReadingFlowSource.home,
      locale: 'en',
      classicReason: ClassicReadingReason.noConsent,
    );

    group('DrawEntry (?resume=, Journal "Finish reading")', () {
      Future<GoRouter> openEntry(WidgetTester tester, TaroFakes fakes) =>
          pumpFlow(
            tester,
            path: RoutePaths.readingDraw,
            location:
                '${RoutePaths.readingDraw}?resume=${kTestReadingId.value}',
            builder: (state) =>
                DrawEntry(resumeId: state.uri.queryParameters['resume']),
            fakes: fakes,
          );

      testWidgets('a pending reading resumes and opens S09', (tester) async {
        final fakes = aiReadyFakes();
        fakes.journal.putReading(
          aReading().withStatus(const ReadingStatus.pending()).build(),
        );
        await openEntry(tester, fakes);
        await tester.pumpAndSettle();
        expect(fakes.readings.calls, contains('resume'));
        expectRoute(RoutePaths.reading(kTestReadingId.value));
      });

      testWidgets('a reading that cannot resume goes Home', (tester) async {
        await openEntry(tester, aiReadyFakes());
        expectRoute(RoutePaths.home);
      });

      testWidgets('loading while the stored reading is read', (tester) async {
        final slow = _SlowReadings();
        await openEntry(tester, aiReadyFakes()..readingsPort = slow);
        expect(find.byType(TaroLoadingView), findsOneWidget);
        slow.done.complete(const Ok(null));
        await tester.pumpAndSettle();
        expectRoute(RoutePaths.home);
      });

      testWidgets('without resume it is the plain draw screen', (
        tester,
      ) async {
        await pumpFlow(
          tester,
          path: RoutePaths.readingDraw,
          builder: (_) => const DrawEntry(),
          fakes: TaroFakes(),
        );
        await tester.pumpAndSettle();
        expectRoute(RoutePaths.home);
      });

      testWidgets('an already-resumed session is kept', (tester) async {
        final fakes = aiReadyFakes();
        fakes.journal.putReading(
          aReading().withStatus(const ReadingStatus.pending()).build(),
        );
        await pumpFlow(
          tester,
          path: RoutePaths.readingDraw,
          location: '/',
          builder: (state) =>
              DrawEntry(resumeId: state.uri.queryParameters['resume']),
          fakes: fakes,
        );
        final container = ProviderScope.containerOf(
          tester.element(find.text('route:/')),
        );
        await container
            .read(readingSessionProvider.notifier)
            .resume(kTestReadingId);
        final router = GoRouter.of(tester.element(find.text('route:/')));
        router
            .push('${RoutePaths.readingDraw}?resume=${kTestReadingId.value}')
            .ignore();
        await tester.pumpAndSettle();
        expect(eventsOf<ReadingFlowStartedEvent>(fakes), hasLength(1));
        expectRoute(RoutePaths.reading(kTestReadingId.value));
      });
    });

    testWidgets('no session: back Home', (tester) async {
      await open(tester, TaroFakes(), null);
      expectRoute(RoutePaths.home);
    });

    testWidgets('Classic: shuffle, draw for me, reveal all → S32', (
      tester,
    ) async {
      final fakes = TaroFakes();
      await open(tester, fakes, classic());
      expect(faces(), findsNothing);
      await startPicking(tester);
      expect(find.text(l10n.drawPickTitle(3)), findsOneWidget);
      await drawForMe(tester);
      expect(find.text(l10n.drawRevealTitle), findsOneWidget);
      await tester.tap(
        find.byWidgetPredicate((w) => w is TaroCardBack && w.onTap != null),
      );
      await tester.pumpAndSettle();
      expect(faces(), findsOneWidget);
      await tapFound(tester, find.text(l10n.drawRevealAll));
      final saved = fakes.journal.readings.values.single;
      expectRoute(RoutePaths.reading(saved.id.value, classic: true));
    });

    testWidgets('AI: pick each card, reveal, the reading opens S09', (
      tester,
    ) async {
      final fakes = aiReadyFakes();
      await open(
        tester,
        fakes,
        ReadingSession(
          spread: aSpread('single').build(),
          source: ReadingFlowSource.home,
          locale: 'en',
          hold: aReadingHold(),
        ),
      );
      await startPicking(tester);
      await tester.tap(find.byType(TaroCardBack).last);
      await tester.pumpAndSettle();
      await tapFound(tester, find.text(l10n.drawRevealAll));
      final reading = fakes.journal.readings.values.single;
      expectRoute(RoutePaths.reading(reading.id.value));
    });

    testWidgets('AI crisis refusal goes to S27 (reading origin)', (
      tester,
    ) async {
      final fakes = aiReadyFakes();
      fakes.readings.refuseNext(
        safety: const SafetyInfo(
          category: RefusalCategory.selfHarm,
          messageKey: 'safetyDeclinedSelfHarm',
          canRephrase: false,
        ),
      );
      await open(
        tester,
        fakes,
        ReadingSession(
          spread: aSpread('single').build(),
          source: ReadingFlowSource.home,
          locale: 'en',
          hold: aReadingHold(),
        ),
      );
      await drawForMe(tester);
      await tester.pumpAndSettle();
      expectRoute(RoutePaths.helpCrisisFrom('reading'));
    });

    ReadingSession ai() => ReadingSession(
      spread: aSpread('single').build(),
      source: ReadingFlowSource.home,
      locale: 'en',
      hold: aReadingHold(),
    );

    testWidgets('hold lost without readings: stays face-down; the options '
        'reopen', (tester) async {
      final fakes = aiReadyFakes();
      final (_, container) = await open(
        tester,
        fakes,
        ReadingSession(
          spread: aSpread('single').build(),
          source: ReadingFlowSource.home,
          locale: 'en',
          hold: aReadingHold(validFor: const Duration(seconds: 30)),
        ),
      );
      fakes.readings.failNextWorkerCall(
        const Failure.insufficientCredits(reason: InsufficientReason.noCredits),
      );
      final empty = aCreditBalance().withFreeRemaining(0).build();
      await drawForMe(tester);
      fakes.balance.seed(empty.copyWith(ledgerVersion: 99));
      await tester.pumpAndSettle();
      Navigator.of(tester.element(find.byType(BottomSheet))).pop();
      await tester.pumpAndSettle();
      expect(container.read(drawControllerProvider), isA<DrawHoldLost>());
      await tapFound(tester, find.text(l10n.outOfReadingsGetMore));
      expect(find.byType(BottomSheet), findsOneWidget);
    });

    testWidgets('a failed generation keeps the cards; finish later', (
      tester,
    ) async {
      final fakes = aiReadyFakes();
      fakes.readings.failNextWorkerCall(const Failure.server(status: 500));
      await open(tester, fakes, ai());
      await drawForMe(tester);
      await tapFound(tester, find.text(l10n.drawRevealAll));
      expect(find.text(l10n.drawGenerationFailedTitle), findsOneWidget);
      expect(faces(), findsOneWidget);
      await tapFound(tester, find.text(l10n.drawFinishLater));
      expectRoute(RoutePaths.journal);
    });

    testWidgets('a failed generation retries with the same cards', (
      tester,
    ) async {
      final fakes = aiReadyFakes();
      fakes.readings.failNextWorkerCall(const Failure.server(status: 500));
      await open(tester, fakes, ai());
      await drawForMe(tester);
      await tapFound(tester, find.text(l10n.drawRevealAll));
      await tapFound(tester, find.text(l10n.commonRetry));
      final reading = fakes.journal.readings.values.single;
      expectRoute(RoutePaths.reading(reading.id.value));
    });

    testWidgets('an outcome for S07 (paused) closes back to the question', (
      tester,
    ) async {
      final fakes = aiReadyFakes();
      fakes.readings.failNextWorkerCall(
        const Failure.readingsPaused(reason: PausedReason.disabled),
      );
      await open(tester, fakes, ai());
      await drawForMe(tester);
      await tapFound(tester, find.text(l10n.drawRevealAll));
      expectRoute('/');
    });

    testWidgets('picked cards: back asks before leaving', (tester) async {
      await open(tester, TaroFakes(), classic());
      await drawForMe(tester);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text(l10n.drawLeaveTitle), findsOneWidget);
    });

    testWidgets('close goes Home', (tester) async {
      await open(tester, TaroFakes(), classic());
      await tester.tap(find.byTooltip(l10n.commonClose));
      await tester.pumpAndSettle();
      expectRoute(RoutePaths.home);
    });

    testWidgets('hold lost: S10 opens with the cards face-down; after a '
        'grant the same draw resumes', (tester) async {
      final fakes = aiReadyFakes();
      final (_, container) = await open(
        tester,
        fakes,
        ReadingSession(
          spread: aSpread('single').build(),
          source: ReadingFlowSource.home,
          locale: 'en',
          hold: aReadingHold(validFor: const Duration(seconds: 30)),
        ),
      );
      fakes.readings.failNextWorkerCall(
        const Failure.insufficientCredits(reason: InsufficientReason.noCredits),
      );
      await drawForMe(tester);
      expect(container.read(drawControllerProvider), isA<DrawHoldLost>());
      expect(find.byType(BottomSheet), findsOneWidget);
      expect(faces(), findsNothing);
      Navigator.of(tester.element(find.byType(BottomSheet))).pop();
      await tester.pumpAndSettle();
      expect(container.read(drawControllerProvider), isA<DrawRevealing>());
      await tapFound(tester, find.text(l10n.drawRevealAll));
      final reading = fakes.journal.readings.values.single;
      expectRoute(RoutePaths.reading(reading.id.value));
    });
  });
}

/// A reading repository whose `get` waits for [done].
final class _SlowReadings implements ReadingRepository {
  final Completer<Result<Reading?>> done = Completer<Result<Reading?>>();

  @override
  Future<Result<Reading?>> get(ReadingId id) => done.future;

  @override
  Object? noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
