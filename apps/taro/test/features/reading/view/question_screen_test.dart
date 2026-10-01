import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taro/common/balance_chip.dart';
import 'package:taro/common/banner_slot.dart';
import 'package:taro/features/reading/controller/question_state.dart';
import 'package:taro/features/reading/controller/reading_session.dart';
import 'package:taro/features/reading/view/question_screen.dart';
import 'package:taro/l10n/generated/taro_localizations.dart';
import 'package:taro/routing/routes.dart';
import 'package:taro_core/taro_core.dart';
import 'package:taro_ui/taro_ui.dart';

import '../../flow_view_support.dart';

QuestionDraft _draft([String text = '']) => QuestionDraft(
  spreadId: const SpreadId('three_ppf'),
  check: QuestionPrecheck.check(text, maxChars: 300),
  maxChars: 300,
  spread: aSpread().build(),
  text: text,
);

const _options = PaywallOptions(
  reason: PaywallReason.noCredits,
  packs: [],
  rewardedAvailable: false,
  nextFreeAt: null,
);

const _safety = SafetyInfo(
  category: RefusalCategory.health,
  messageKey: 'safetyDeclinedHealth',
  canRephrase: true,
);

void main() {
  late TaroLocalizations l10n;

  setUpAll(() async => l10n = await enL10n());

  Future<List<String>> pumpLayout(
    WidgetTester tester,
    QuestionState state, {
    TaroFakes? fakes,
  }) async {
    final calls = <String>[];
    final text = TextEditingController(text: state.draft.text);
    addTearDown(text.dispose);
    await pumpTaro(
      tester,
      QuestionLayout(
        state: state,
        text: text,
        onChanged: (t) => calls.add('changed:$t'),
        onSuggestion: (t) => calls.add('suggestion'),
        onBegin: () => calls.add('begin'),
        onRetry: () => calls.add('retry'),
        onDismiss: () => calls.add('dismiss'),
        onClassic: () => calls.add('classic'),
        onReflectWithoutQuestion: () => calls.add('reflect'),
        onOpenConsent: () => calls.add('consent'),
        onOpenOptions: () => calls.add('options'),
        onBack: () => calls.add('back'),
        onDailyCard: () => calls.add('daily'),
        onLearn: () => calls.add('learn'),
        onChooseSpread: () => calls.add('spreads'),
      ),
      fakes: fakes ?? aiReadyFakes(),
    );
    await tester.pumpAndSettle();
    // No card face exists before the gate allows (06 §2.5); never a banner
    // on the reading flow (RC18).
    expect(find.byType(TaroCardFace), findsNothing);
    expect(find.byType(BannerSlot), findsNothing);
    return calls;
  }

  TaroButton begin(WidgetTester tester) => tester.widget<TaroButton>(
    find.byWidgetPredicate(
      (w) => w is TaroButton && w.label == l10n.questionBegin,
    ),
  );

  testWidgets('editing: title, field, suggestions, Begin enabled', (
    tester,
  ) async {
    final calls = await pumpLayout(tester, QuestionState.editing(_draft()));
    expect(find.text(l10n.questionTitle), findsOneWidget);
    expect(find.text(l10n.questionIdeas), findsOneWidget);
    expect(find.text(l10n.questionChargeFree), findsOneWidget);
    expect(begin(tester).onPressed, isNotNull);
    await tapFound(tester, find.text(l10n.spread_three_ppf_suggestion_1));
    await tester.enterText(find.byType(TextField), 'Hi');
    await tapFound(tester, find.text(l10n.questionBegin));
    expect(calls, ['suggestion', 'changed:Hi', 'begin']);
  });

  testWidgets('editing: only symbols shows the pre-check error', (
    tester,
  ) async {
    await pumpLayout(tester, QuestionState.editing(_draft('!!!')));
    expect(find.text(l10n.questionOnlySymbols), findsOneWidget);
    expect(begin(tester).onPressed, isNull);
  });

  testWidgets('editing: credits wording when the free reading is used', (
    tester,
  ) async {
    final balance = aCreditBalance().withFreeRemaining(0).withPaid(3).build();
    await pumpLayout(
      tester,
      QuestionState.editing(_draft()),
      fakes: aiReadyFakes()..balance = FakeBalanceRepository(cached: balance),
    );
    expect(find.text(l10n.questionChargeCredits(3)), findsOneWidget);
  });

  testWidgets('checking: Begin is busy', (tester) async {
    await pumpLayout(tester, QuestionState.checking(_draft()));
    expect(begin(tester).loading, isTrue);
    expect(begin(tester).onPressed, isNull);
  });

  testWidgets('ready: Begin stays busy while S08 opens', (tester) async {
    await pumpLayout(tester, QuestionState.ready(_draft()));
    expect(begin(tester).loading, isTrue);
  });

  testWidgets('offline: notice, Begin disabled', (tester) async {
    await pumpLayout(tester, QuestionState.offline(_draft()));
    expect(find.text(l10n.questionOfflineNotice), findsOneWidget);
    expect(begin(tester).onPressed, isNull);
  });

  testWidgets('consentRequired: Allow AI readings / classic offer', (
    tester,
  ) async {
    final calls = await pumpLayout(
      tester,
      QuestionState.consentRequired(_draft()),
    );
    expect(find.text(l10n.questionConsentDeclinedNotice), findsOneWidget);
    await tapFound(tester, find.text(l10n.aiConsentAccept));
    await tapFound(tester, find.text(l10n.questionTryClassic));
    expect(calls, ['consent', 'classic']);
  });

  testWidgets('deviceUnverified: notice with Retry', (tester) async {
    final calls = await pumpLayout(
      tester,
      QuestionState.deviceUnverified(_draft()),
    );
    expect(find.text(l10n.questionDeviceUnverified), findsWidgets);
    await tapFound(tester, find.text(l10n.commonRetry).last);
    expect(calls, ['retry']);
  });

  testWidgets('readingsPaused (S31): resting copy, links, never a paywall', (
    tester,
  ) async {
    final calls = await pumpLayout(
      tester,
      QuestionState.readingsPaused(_draft()),
    );
    expect(find.text(l10n.pausedTitle), findsOneWidget);
    expect(find.text(l10n.outOfReadingsGetMore), findsNothing);
    // S31: the Classic reading replaces Begin; Back to Today below it.
    expect(find.text(l10n.questionBegin), findsNothing);
    expect(find.text(l10n.questionClassicCaption), findsOneWidget);
    await tapFound(tester, find.text(l10n.commonDailyCard));
    await tapFound(tester, find.text(l10n.commonLearn));
    await tapFound(tester, find.text(l10n.questionTryClassic));
    await tapFound(tester, find.text(l10n.commonBackToToday));
    expect(calls, ['daily', 'learn', 'classic', 'back']);
  });

  testWidgets('readingsPaused freePaused: the free copy variant', (
    tester,
  ) async {
    await pumpLayout(
      tester,
      QuestionState.readingsPaused(_draft(), freePaused: true),
    );
    expect(find.text(l10n.pausedFreeTitle), findsOneWidget);
  });

  testWidgets('aiUnavailableRegion: Classic offer', (tester) async {
    final calls = await pumpLayout(
      tester,
      QuestionState.aiUnavailableRegion(_draft()),
    );
    expect(find.text(l10n.pausedRegionTitle), findsOneWidget);
    await tapFound(tester, find.text(l10n.questionTryClassic));
    expect(calls, ['classic']);
  });

  testWidgets('outOfReadings: reading options', (tester) async {
    final calls = await pumpLayout(
      tester,
      QuestionState.outOfReadings(
        _draft(),
        options: _options,
        source: OutOfReadingsSource.questionGate,
      ),
    );
    expect(find.text(l10n.outOfReadingsTitle), findsOneWidget);
    await tapFound(tester, find.text(l10n.outOfReadingsGetMore));
    expect(calls, ['options']);
  });

  testWidgets('lowTrustLimited: the low-trust copy', (tester) async {
    await pumpLayout(
      tester,
      QuestionState.lowTrustLimited(
        _draft(),
        options: _options.copyWith(reason: PaywallReason.lowTrustCap),
      ),
    );
    expect(find.text(l10n.outOfReadingsLowTrustTitle), findsOneWidget);
  });

  testWidgets('dailyLimitReached: no paywall', (tester) async {
    await pumpLayout(tester, QuestionState.dailyLimitReached(_draft()));
    expect(find.text(l10n.questionDailyLimitTitle), findsOneWidget);
    expect(find.text(l10n.outOfReadingsGetMore), findsNothing);
    expect(find.text(l10n.questionBegin), findsNothing);
    expect(find.text(l10n.commonBackToToday), findsOneWidget);
  });

  testWidgets('rephrase: hint, examples, reflect without a question', (
    tester,
  ) async {
    final calls = await pumpLayout(
      tester,
      QuestionState.rephrase(
        _draft('Am I ill?'),
        safety: _safety,
        draw: aDraw(),
      ),
    );
    expect(find.text(l10n.questionRephraseTitle), findsOneWidget);
    expect(find.textContaining(l10n.questionRephraseExample1), findsOneWidget);
    await tapFound(tester, find.text(l10n.questionReflectWithoutQuestion));
    expect(calls, ['reflect']);
  });

  testWidgets('refused(category): the refusal card, rewordings, reflect', (
    tester,
  ) async {
    final calls = await pumpLayout(
      tester,
      QuestionState.refused(
        _draft('Q'),
        category: RefusalCategory.legal,
        safety: _safety.copyWith(category: RefusalCategory.legal),
        draw: aDraw(),
      ),
    );
    expect(find.text(l10n.questionRefusedHeadline), findsOneWidget);
    expect(find.text(l10n.questionRefusedTitle), findsOneWidget);
    expect(find.textContaining(l10n.safetyDeclinedLegal), findsOneWidget);
    expect(
      find.textContaining(l10n.questionRefusedProfessional),
      findsOneWidget,
    );
    expect(find.text(l10n.questionNoReadingUsed), findsOneWidget);
    expect(find.text(l10n.questionRephraseTry), findsOneWidget);
    expect(begin(tester).onPressed, isNotNull);
    await tapFound(tester, find.text(l10n.questionRephraseExample2));
    await tapFound(tester, find.text(l10n.questionReflectWithoutQuestion));
    expect(calls, ['suggestion', 'reflect']);
  });

  testWidgets('refused(sexual_minors): the neutral message only', (
    tester,
  ) async {
    await pumpLayout(
      tester,
      QuestionState.refused(
        _draft('Q'),
        category: RefusalCategory.sexualMinors,
        safety: _safety.copyWith(category: RefusalCategory.sexualMinors),
        draw: aDraw(),
      ),
    );
    expect(find.text(l10n.safetyDeclinedSexualMinors), findsOneWidget);
    expect(find.textContaining(l10n.questionRefusedProfessional), findsNothing);
    expect(find.text(l10n.questionRephraseTry), findsNothing);
    expect(find.text(l10n.questionReflectWithoutQuestion), findsNothing);
  });

  testWidgets('refused without a draw: no reflect link', (tester) async {
    await pumpLayout(
      tester,
      QuestionState.refused(
        _draft('Q'),
        category: RefusalCategory.other,
        safety: _safety.copyWith(category: RefusalCategory.other),
      ),
    );
    expect(find.text(l10n.refusalGeneric), findsOneWidget);
    expect(find.text(l10n.questionReflectWithoutQuestion), findsNothing);
    expect(find.text(l10n.questionChargeFree), findsOneWidget);
  });

  testWidgets('rateLimited: notice', (tester) async {
    await pumpLayout(tester, QuestionState.rateLimited(_draft()));
    expect(find.text(l10n.questionRateLimited), findsOneWidget);
  });

  testWidgets('spreadDisabled: choose another spread', (tester) async {
    final calls = await pumpLayout(
      tester,
      QuestionState.spreadDisabled(_draft()),
    );
    expect(find.text(l10n.questionSpreadDisabled), findsOneWidget);
    await tapFound(tester, find.text(l10n.spreadsTitle));
    expect(calls, ['spreads']);
  });

  testWidgets('failed: the failure message with Retry', (tester) async {
    final calls = await pumpLayout(
      tester,
      QuestionState.failed(
        _draft(),
        failure: const Failure.server(status: 500),
      ),
    );
    expect(find.text(l10n.failureServer), findsOneWidget);
    await tapFound(tester, find.text(l10n.commonRetry));
    expect(calls, ['retry']);
  });

  test('fromQuery parses spread, source and the preset card', () {
    final screen = QuestionScreen.fromQuery(
      Uri.parse(
        RoutePaths.readingQuestion(
          'single',
          source: 'daily_card',
          cardId: 'major_17',
          reversed: true,
        ),
      ).queryParameters,
    );
    expect(screen.args.spreadId, const SpreadId('single'));
    expect(screen.args.source, ReadingFlowSource.dailyCard);
    expect(screen.args.presetCards, const [
      PresetCard(cardId: CardId('major_17'), reversed: true),
    ]);
    final plain = QuestionScreen.fromQuery(const {'spread': 'three_ppf'});
    expect(plain.args.source, ReadingFlowSource.home);
    expect(plain.args.presetCards, isEmpty);
  });

  group('screen', () {
    Future<void> pumpQuestion(
      WidgetTester tester,
      TaroFakes fakes, {
      bool pushed = false,
    }) => pumpFlow(
      tester,
      path: RoutePaths.readingQuestionPath,
      location: RoutePaths.readingQuestion('three_ppf'),
      pushed: pushed,
      builder: (state) => QuestionScreen.fromQuery(state.uri.queryParameters),
      fakes: fakes,
    );

    testWidgets('Begin takes the hold, then S08 opens', (tester) async {
      final fakes = aiReadyFakes();
      await pumpQuestion(tester, fakes);
      await tester.enterText(find.byType(TextField), 'What helps me now?');
      await tester.pump();
      await tapFound(tester, find.text(l10n.questionBegin));
      expect(fakes.readings.holds, hasLength(1));
      expectRoute(RoutePaths.readingDraw);
    });

    testWidgets('a suggestion fills the field', (tester) async {
      await pumpQuestion(tester, aiReadyFakes());
      await tapFound(tester, find.text(l10n.spread_three_ppf_suggestion_1));
      expect(
        find.widgetWithText(TextField, l10n.spread_three_ppf_suggestion_1),
        findsOneWidget,
      );
    });

    testWidgets('consent missing: S04 opens for the reading gate', (
      tester,
    ) async {
      await pumpQuestion(tester, TaroFakes());
      await tapFound(tester, find.text(l10n.questionBegin));
      expectRoute(RoutePaths.consentAiFrom('reading_gate'));
    });

    testWidgets('no readings: S10 opens; closing it returns to editing', (
      tester,
    ) async {
      final fakes = aiReadyFakes();
      final empty = aCreditBalance().withFreeRemaining(0).build();
      fakes.balance = FakeBalanceRepository(cached: empty, server: empty);
      await pumpQuestion(tester, fakes);
      await tapFound(tester, find.text(l10n.questionBegin));
      expect(find.byType(BottomSheet), findsOneWidget);
      expect(fakes.readings.holds, isEmpty);
      Navigator.of(tester.element(find.byType(BottomSheet))).pop();
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsNothing);
      expect(find.text(l10n.outOfReadingsTitle), findsNothing);
    });

    testWidgets('readings paused: S31, then a Classic reading opens S08', (
      tester,
    ) async {
      final fakes = aiReadyFakes();
      final paused = aCreditBalance().withReadingsPaused().build();
      fakes.balance = FakeBalanceRepository(cached: paused, server: paused);
      await pumpQuestion(tester, fakes);
      await tapFound(tester, find.text(l10n.questionBegin));
      expect(find.text(l10n.pausedTitle), findsOneWidget);
      await tapFound(tester, find.text(l10n.questionTryClassic));
      expectRoute(RoutePaths.readingDraw);
    });

    testWidgets('S31 links go to the daily card and Learn', (tester) async {
      final fakes = aiReadyFakes();
      final paused = aCreditBalance().withReadingsPaused().build();
      fakes.balance = FakeBalanceRepository(cached: paused, server: paused);
      await pumpQuestion(tester, fakes);
      await tapFound(tester, find.text(l10n.questionBegin));
      await tapFound(tester, find.text(l10n.commonLearn));
      expectRoute(RoutePaths.learn);
    });

    Future<ProviderContainer> containerOf(WidgetTester tester) async =>
        ProviderScope.containerOf(tester.element(find.byType(QuestionScreen)));

    testWidgets('back from S08 without an outcome: editable again', (
      tester,
    ) async {
      final fakes = aiReadyFakes();
      final router = await pumpFlow(
        tester,
        path: RoutePaths.readingQuestionPath,
        location: RoutePaths.readingQuestion('three_ppf'),
        builder: (state) => QuestionScreen.fromQuery(state.uri.queryParameters),
        fakes: fakes,
      );
      await tapFound(tester, find.text(l10n.questionBegin));
      expectRoute(RoutePaths.readingDraw);
      router.pop();
      await tester.pumpAndSettle();
      expect(begin(tester).loading, isFalse);
      expect(begin(tester).onPressed, isNotNull);
    });

    testWidgets('a failure retries Begin', (tester) async {
      final fakes = aiReadyFakes();
      fakes.readings.failNextWorkerCall(const Failure.server(status: 500));
      await pumpQuestion(tester, fakes);
      await tapFound(tester, find.text(l10n.questionBegin));
      expect(find.text(l10n.failureServer), findsOneWidget);
      await tapFound(tester, find.text(l10n.commonRetry));
      expectRoute(RoutePaths.readingDraw);
    });

    testWidgets('declined with a rewording hint: reflect without the question '
        'reuses the cards', (tester) async {
      final fakes = aiReadyFakes();
      await pumpQuestion(tester, fakes);
      final container = await containerOf(tester);
      container
          .read(readingHandoffProvider.notifier)
          .post(ReadingHandoff.declined(safety: _safety, draw: aDraw()));
      await tester.pumpAndSettle();
      expect(find.text(l10n.questionRephraseTitle), findsOneWidget);
      await tapFound(tester, find.text(l10n.questionReflectWithoutQuestion));
      expectRoute(RoutePaths.readingDraw);
    });

    testWidgets('refused: a rewording returns to editing', (tester) async {
      await pumpQuestion(tester, aiReadyFakes());
      final container = await containerOf(tester);
      container
          .read(readingHandoffProvider.notifier)
          .post(
            ReadingHandoff.declined(
              safety: _safety.copyWith(canRephrase: false),
              draw: aDraw(),
            ),
          );
      await tester.pumpAndSettle();
      expect(find.text(l10n.questionRefusedTitle), findsOneWidget);
      await tapFound(tester, find.text(l10n.questionRephraseExample1));
      expect(find.text(l10n.questionRefusedTitle), findsNothing);
      expect(
        find.widgetWithText(TextField, l10n.questionRephraseExample1),
        findsOneWidget,
      );
    });

    testWidgets('consent handoff: the notice reopens S04', (tester) async {
      await pumpQuestion(tester, aiReadyFakes());
      final container = await containerOf(tester);
      container
          .read(readingHandoffProvider.notifier)
          .post(const ReadingHandoff.consentRequired());
      await tester.pumpAndSettle();
      expect(find.text(l10n.questionConsentDeclinedNotice), findsOneWidget);
      await tapFound(tester, find.text(l10n.aiConsentAccept));
      expectRoute(RoutePaths.consentAiFrom('reading_gate'));
    });

    testWidgets('low trust: S10 opens with the low-trust source', (
      tester,
    ) async {
      final fakes = aiReadyFakes();
      final capped = aCreditBalance().withFreeRemaining(0).withLowTrustCap();
      fakes.balance = FakeBalanceRepository(
        cached: capped.build(),
        server: capped.build(),
      );
      await pumpQuestion(tester, fakes);
      await tapFound(tester, find.text(l10n.questionBegin));
      expect(find.byType(BottomSheet), findsOneWidget);
      Navigator.of(tester.element(find.byType(BottomSheet))).pop();
      await tester.pumpAndSettle();
      expect(find.text(l10n.outOfReadingsLowTrustTitle), findsNothing);
    });

    testWidgets('the balance chip opens the reading options', (tester) async {
      await pumpQuestion(tester, aiReadyFakes());
      await tester.tap(find.byType(BalanceChip));
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsOneWidget);
    });

    testWidgets('S31 links go to the daily card', (tester) async {
      final fakes = aiReadyFakes();
      final paused = aCreditBalance().withReadingsPaused().build();
      fakes.balance = FakeBalanceRepository(cached: paused, server: paused);
      await pumpQuestion(tester, fakes);
      await tapFound(tester, find.text(l10n.questionBegin));
      await tapFound(tester, find.text(l10n.commonDailyCard));
      expectRoute(RoutePaths.daily);
    });

    testWidgets('a disabled spread goes back to the picker', (tester) async {
      await pumpFlow(
        tester,
        path: RoutePaths.readingQuestionPath,
        location: RoutePaths.readingQuestion('nope'),
        builder: (state) => QuestionScreen.fromQuery(state.uri.queryParameters),
        fakes: aiReadyFakes(),
      );
      await tapFound(tester, find.text(l10n.spreadsTitle));
      expectRoute(RoutePaths.readingSpreads);
    });

    testWidgets('the personal-details helper shows', (tester) async {
      await pumpQuestion(tester, aiReadyFakes());
      await tester.enterText(find.byType(TextField), 'mail me at a@b.co');
      await tester.pumpAndSettle();
      expect(find.text(l10n.questionPersonalDetails), findsOneWidget);
    });

    testWidgets('back from a pushed S07 returns', (tester) async {
      await pumpQuestion(tester, aiReadyFakes(), pushed: true);
      await tester.tap(find.byTooltip(l10n.commonBack));
      await tester.pumpAndSettle();
      expectRoute('/');
    });
  });
}
