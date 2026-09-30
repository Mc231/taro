import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taro/features/reading/controller/question_controller.dart';
import 'package:taro/features/reading/controller/question_state.dart';
import 'package:taro/features/reading/controller/reading_session.dart';
import 'package:taro_core/taro_core.dart';

import '../feature_test_support.dart';

const _spread = SpreadId('three_ppf');
const _args = QuestionArgs(spreadId: _spread);

void main() {
  late TaroFakes fakes;

  Future<(ProviderContainer, StateLog<QuestionState>, QuestionController)>
  open([QuestionArgs args = _args]) async {
    final container = fakes.container();
    final log = StateLog(container, questionControllerProvider(args));
    await pumpEventQueue();
    return (
      container,
      log,
      container.read(questionControllerProvider(args).notifier),
    );
  }

  List<GateBlockReason> blocked() => [
    for (final e in eventsOf<ReadingGateBlockedEvent>(fakes)) e.reason,
  ];

  setUp(() => fakes = aiReadyFakes());

  group('editing', () {
    test(
      'opens with the spread loaded and logs reading_flow_started',
      () async {
        final (_, log, _) = await open(
          const QuestionArgs(
            spreadId: _spread,
            source: ReadingFlowSource.deepLink,
          ),
        );
        final state = log.last as QuestionEditing;
        expect(state.draft.spread?.id, _spread);
        expect(state.draft.canBegin, isTrue);
        final started = eventsOf<ReadingFlowStartedEvent>(fakes).single;
        expect(started.source, ReadingFlowSource.deepLink);
        expect(started.spread, AnalyticsSpread.threePpf);
      },
    );

    test('text is pre-checked; too long disables Begin', () async {
      final (_, log, controller) = await open();
      controller.updateText('x' * 301);
      expect(log.last.draft.canBegin, isFalse);
      expect(log.last.draft.showsCounter, isTrue);
      await controller.begin();
      expect(log.last, isA<QuestionEditing>());
      expect(fakes.readings.holds, isEmpty);
    });

    test('a suggestion fills the field and is reported', () async {
      final (_, log, controller) = await open();
      controller.useSuggestion('What should I focus on?');
      expect(log.last.draft.text, 'What should I focus on?');
      expect(log.last.draft.usedSuggestion, isTrue);
      await controller.begin();
      final submitted = eventsOf<QuestionSubmittedEvent>(fakes).single;
      expect(submitted.usedSuggestion, isTrue);
      expect(submitted.hasQuestion, isTrue);
      expect(submitted.questionLenBucket, QuestionLengthBucket.short);
    });

    test('an unknown spread is spreadDisabled', () async {
      final (_, log, _) = await open(
        const QuestionArgs(spreadId: SpreadId('nope')),
      );
      expect(log.last, isA<QuestionSpreadDisabled>());
    });

    test('unreadable content is failed', () async {
      fakes.content.failNext(const Failure.storage(), on: 'spreads');
      final (_, log, controller) = await open();
      expect(log.last, isA<QuestionFailed>());
      await controller.begin();
      expect(fakes.readings.holds, isEmpty);
    });
  });

  group('Begin allowed', () {
    test('checking → hold → ready with the session started', () async {
      final (container, log, controller) = await open();
      controller.updateText('  What now?  ');
      await controller.begin();
      expect(log.states.whereType<QuestionChecking>(), hasLength(1));
      expect(log.last, isA<QuestionReady>());
      final session = container.read(readingSessionProvider)!;
      expect(session.hold, isNotNull);
      expect(session.question, 'What now?');
      expect(session.isClassic, isFalse);
      expect(fakes.readings.holds.single.$2, _spread);
      expect(
        eventsOf<ReadingGateEvaluatedEvent>(fakes).single.decision,
        GateDecisionKind.allowed,
      );
      expect(
        eventsOf<ReadingHoldResultEvent>(fakes).single.result,
        HoldResult.held,
      );
    });

    test('a second Begin while checking is ignored', () async {
      final (_, _, controller) = await open();
      final first = controller.begin();
      await controller.begin();
      await first;
      expect(fakes.readings.holds, hasLength(1));
    });

    test('text edits are ignored once ready', () async {
      final (_, log, controller) = await open();
      await controller.begin();
      controller.updateText('late');
      expect(log.last, isA<QuestionReady>());
    });
  });

  group('gate decisions', () {
    test('offline, then editing again when the connection returns', () async {
      fakes.connectivity.setOnline(online: false);
      final (_, log, controller) = await open();
      await controller.begin();
      expect(log.last, isA<QuestionOffline>());
      expect(blocked(), [GateBlockReason.offline]);
      fakes.connectivity.setOnline(online: true);
      await pumpEventQueue();
      expect(log.last, isA<QuestionEditing>());
    });

    test('a balance that cannot be confirmed is offline (needsSync)', () async {
      fakes.balance = FakeBalanceRepository()
        ..failNext(const Failure.server(status: 500), on: 'sync');
      final (_, log, controller) = await open();
      await controller.begin();
      expect(log.last, isA<QuestionOffline>());
    });

    test('consentRequired, then the gate re-runs after Allow (F7)', () async {
      fakes = TaroFakes();
      final (_, log, controller) = await open();
      await controller.begin();
      expect(log.last, isA<QuestionConsentRequired>());
      expect(log.last.offersClassic, isTrue);
      expect(blocked(), [GateBlockReason.noConsent]);
      await fakes.consentStore.update(
        (s) => s.copyWith(
          ai: const AiConsent(
            decision: AiConsentDecision.granted,
            version: 1,
          ),
        ),
      );
      await pumpEventQueue();
      expect(log.last, isA<QuestionReady>());
    });

    test('deviceUnverified', () async {
      fakes.install = FakeInstallRepository(
        identity: anInstallIdentity(registered: false),
      );
      final (_, log, controller) = await open();
      await controller.begin();
      expect(log.last, isA<QuestionDeviceUnverified>());
      expect(
        eventsOf<DeviceUnverifiedShownEvent>(fakes).single.origin,
        AppNoticeOrigin.readingGate,
      );
    });

    test('readingsPaused (kill switch) is never a paywall', () async {
      fakes.config.current = aRemoteConfig().withReadingsEnabled(false).build();
      final (_, log, controller) = await open();
      await controller.begin();
      final state = log.last as QuestionReadingsPaused;
      expect(state.freePaused, isFalse);
      expect(state.offersClassic, isTrue);
      expect(blocked(), [GateBlockReason.readingsPaused]);
      expect(eventsOf<ReadingsPausedShownEvent>(fakes), hasLength(1));
    });

    test('spreadDisabled by config', () async {
      fakes.config.current = aRemoteConfig().withSpreadsEnabled([
        'single',
      ]).build();
      final (_, log, controller) = await open();
      await controller.begin();
      expect(log.last, isA<QuestionSpreadDisabled>());
      expect(blocked(), [GateBlockReason.spreadDisabled]);
    });

    test('outOfReadings (S10 from the gate)', () async {
      fakes.balance = FakeBalanceRepository(
        cached: aCreditBalance().withFreeRemaining(0).build(),
      );
      final (_, log, controller) = await open();
      await controller.begin();
      final state = log.last as QuestionOutOfReadings;
      expect(state.source, OutOfReadingsSource.questionGate);
      expect(state.options.reason, PaywallReason.noCredits);
      expect(fakes.readings.holds, isEmpty);
      expect(blocked(), [GateBlockReason.insufficientCredits]);
    });

    test('lowTrustLimited from the gate', () async {
      fakes.balance = FakeBalanceRepository(
        cached: aCreditBalance().withLowTrustCap().build(),
      );
      final (_, log, controller) = await open();
      await controller.begin();
      expect(log.last, isA<QuestionLowTrustLimited>());
      expect(blocked(), [GateBlockReason.lowTrust]);
    });

    test('dailyLimitReached from the gate', () async {
      fakes.balance = FakeBalanceRepository(
        cached: aCreditBalance().withDailyLimitReached().build(),
      );
      final (_, log, controller) = await open();
      await controller.begin();
      expect(log.last, isA<QuestionDailyLimitReached>());
      expect(blocked(), [GateBlockReason.dailyLimit]);
    });

    test('an unreadable install is failed', () async {
      fakes.install.failNext(const Failure.storage(), on: 'getOrCreate');
      final (_, log, controller) = await open();
      await controller.begin();
      expect(log.last, isA<QuestionFailed>());
    });
  });

  group('hold outcomes', () {
    Future<QuestionState> holdFails(Failure failure) async {
      fakes.readings.failNextWorkerCall(failure);
      final (_, log, controller) = await open();
      await controller.begin();
      return log.last;
    }

    test('402 noCredits → outOfReadings (hold_402), nothing drawn', () async {
      final state = await holdFails(
        const Failure.insufficientCredits(reason: InsufficientReason.noCredits),
      );
      expect(
        (state as QuestionOutOfReadings).source,
        OutOfReadingsSource.hold402,
      );
      expect(
        eventsOf<ReadingHoldResultEvent>(fakes).single.result,
        HoldResult.insufficientCredits,
      );
    });

    test('402 lowTrustCap → lowTrustLimited', () async {
      final state = await holdFails(
        const Failure.insufficientCredits(
          reason: InsufficientReason.lowTrustCap,
        ),
      );
      expect(state, isA<QuestionLowTrustLimited>());
    });

    test('402 freePaused → readingsPaused(freePaused)', () async {
      final state = await holdFails(
        const Failure.insufficientCredits(
          reason: InsufficientReason.freePaused,
        ),
      );
      expect((state as QuestionReadingsPaused).freePaused, isTrue);
      expect(blocked(), [GateBlockReason.freePaused]);
    });

    test('429 dailyLimit → dailyLimitReached', () async {
      final state = await holdFails(
        const Failure.rateLimited(reason: RateLimitReason.dailyLimit),
      );
      expect(state, isA<QuestionDailyLimitReached>());
    });

    test('429 lowTrustCap → lowTrustLimited', () async {
      final state = await holdFails(
        const Failure.rateLimited(reason: RateLimitReason.lowTrustCap),
      );
      expect(state, isA<QuestionLowTrustLimited>());
    });

    test('429 burst → rateLimited', () async {
      final state = await holdFails(
        const Failure.rateLimited(
          reason: RateLimitReason.burst,
          retryAfter: Duration(seconds: 30),
        ),
      );
      expect(
        (state as QuestionRateLimited).retryAfter,
        const Duration(seconds: 30),
      );
      expect(blocked(), [GateBlockReason.rateLimited]);
    });

    test('412 → consentRequired', () async {
      final state = await holdFails(const Failure.aiConsentRequired());
      expect(state, isA<QuestionConsentRequired>());
    });

    test('403 region → aiUnavailableRegion, remembered for Begin', () async {
      fakes.readings.failNextWorkerCall(const Failure.aiUnavailableRegion());
      final (_, log, controller) = await open();
      await controller.begin();
      expect(log.last, isA<QuestionAiUnavailableRegion>());
      controller.dismissNotice();
      await controller.begin();
      expect(log.last, isA<QuestionAiUnavailableRegion>());
      expect(fakes.readings.holds, hasLength(1));
      expect(blocked(), [GateBlockReason.region, GateBlockReason.region]);
    });

    test('503 paused → readingsPaused', () async {
      final state = await holdFails(
        const Failure.readingsPaused(reason: PausedReason.budgetHard),
      );
      expect((state as QuestionReadingsPaused).freePaused, isFalse);
      expect(
        eventsOf<ReadingHoldResultEvent>(fakes).single.result,
        HoldResult.paused,
      );
    });

    test('503 freeStop → readingsPaused(freePaused)', () async {
      final state = await holdFails(
        const Failure.readingsPaused(reason: PausedReason.freeStop),
      );
      expect((state as QuestionReadingsPaused).freePaused, isTrue);
    });

    test('network → offline', () async {
      expect(await holdFails(const Failure.network()), isA<QuestionOffline>());
    });

    test('attestation → deviceUnverified', () async {
      final state = await holdFails(
        const Failure.attestation(kind: AttestationFailureKind.rejected),
      );
      expect(state, isA<QuestionDeviceUnverified>());
    });

    test('a server error → failed', () async {
      final state = await holdFails(const Failure.server(status: 500));
      expect((state as QuestionFailed).failure, isA<ServerFailure>());
      expect(
        eventsOf<ReadingHoldResultEvent>(fakes).single.result,
        HoldResult.error,
      );
    });
  });

  group('Classic reading (F8)', () {
    test('from consentRequired starts a Classic session', () async {
      fakes = TaroFakes();
      final (container, log, controller) = await open();
      await controller.begin();
      await controller.startClassic();
      expect(log.last, isA<QuestionReady>());
      final session = container.read(readingSessionProvider)!;
      expect(session.classicReason, ClassicReadingReason.noConsent);
      expect(session.hold, isNull);
      expect(
        eventsOf<ClassicReadingStartedEvent>(fakes).single.reason,
        ClassicReadingReason.noConsent,
      );
    });

    test('from readingsPaused and aiUnavailableRegion', () async {
      fakes.config.current = aRemoteConfig().withReadingsEnabled(false).build();
      final (container, _, controller) = await open();
      await controller.begin();
      await controller.startClassic();
      expect(
        container.read(readingSessionProvider)!.classicReason,
        ClassicReadingReason.paused,
      );
      fakes.readings.failNextWorkerCall(const Failure.aiUnavailableRegion());
      fakes.config.current = RemoteConfig.defaults;
      controller.dismissNotice();
      await controller.begin();
      await controller.startClassic();
      expect(
        container.read(readingSessionProvider)!.classicReason,
        ClassicReadingReason.region,
      );
    });

    test('is not offered while editing', () async {
      final (container, log, controller) = await open();
      await controller.startClassic();
      expect(log.last, isA<QuestionEditing>());
      expect(container.read(readingSessionProvider), isNull);
    });
  });

  group('handoff from S08', () {
    final draw = aDraw();

    test('declined with canRephrase → rephrase, question kept', () async {
      final (container, log, controller) = await open();
      controller.updateText('Will I win?');
      await controller.begin();
      container
          .read(readingHandoffProvider.notifier)
          .post(
            ReadingHandoff.declined(
              safety: const SafetyInfo(
                category: RefusalCategory.gambling,
                messageKey: 'safetyDeclinedGambling',
                canRephrase: true,
              ),
              draw: draw,
            ),
          );
      await pumpEventQueue();
      final state = log.last as QuestionRephrase;
      expect(state.draft.text, 'Will I win?');
      expect(container.read(readingHandoffProvider), isNull);

      await controller.reflectWithoutQuestion();
      expect(log.last, isA<QuestionReady>());
      final session = container.read(readingSessionProvider)!;
      expect(session.question, isNull);
      expect(session.presetCards.map((c) => c.cardId), draw.cardIds);
    });

    test('declined without rephrase → refused(category)', () async {
      final (container, log, _) = await open();
      container
          .read(readingHandoffProvider.notifier)
          .post(
            ReadingHandoff.declined(
              safety: const SafetyInfo(
                category: RefusalCategory.sexualMinors,
                messageKey: 'safetyDeclinedSexualMinors',
                canRephrase: false,
              ),
              draw: draw,
            ),
          );
      await pumpEventQueue();
      expect(
        (log.last as QuestionRefused).category,
        RefusalCategory.sexualMinors,
      );
    });

    test('paused, consent and region handoffs', () async {
      final (container, log, controller) = await open();
      final handoffs = container.read(readingHandoffProvider.notifier)
        ..post(const ReadingHandoff.paused(freePaused: true));
      await pumpEventQueue();
      expect((log.last as QuestionReadingsPaused).freePaused, isTrue);
      handoffs.post(const ReadingHandoff.consentRequired());
      await pumpEventQueue();
      expect(log.last, isA<QuestionConsentRequired>());
      handoffs.post(const ReadingHandoff.aiUnavailableRegion());
      await pumpEventQueue();
      expect(log.last, isA<QuestionAiUnavailableRegion>());
      controller.dismissNotice();
      await controller.begin();
      expect(fakes.readings.holds, isEmpty);
    });

    test('a pending handoff is taken when S07 opens', () async {
      final container = fakes.container();
      container
          .read(readingHandoffProvider.notifier)
          .post(const ReadingHandoff.consentRequired());
      final log = StateLog(container, questionControllerProvider(_args));
      await pumpEventQueue();
      expect(log.last, isA<QuestionConsentRequired>());
    });

    test('reflectWithoutQuestion only from rephrase', () async {
      final (_, log, controller) = await open();
      await controller.reflectWithoutQuestion();
      expect(log.last, isA<QuestionEditing>());
    });
  });

  test(
    'dismissNotice returns to editing (nothing auto-starts, RC58)',
    () async {
      fakes.balance = FakeBalanceRepository(
        cached: aCreditBalance().withFreeRemaining(0).build(),
      );
      final (_, log, controller) = await open();
      await controller.begin();
      expect(log.last, isA<QuestionOutOfReadings>());
      fakes.balance.seed(
        aCreditBalance().withBonus(1).withLedgerVersion(2).build(),
      );
      controller.dismissNotice();
      expect(log.last, isA<QuestionEditing>());
      expect(fakes.readings.holds, isEmpty);
    },
  );

  test('the preset cards travel into the session (Reflect deeper)', () async {
    const preset = [PresetCard(cardId: CardId('major_17'), reversed: true)];
    final (container, _, controller) = await open(
      const QuestionArgs(
        spreadId: SpreadId('single'),
        source: ReadingFlowSource.dailyCard,
        presetCards: preset,
      ),
    );
    await controller.begin();
    expect(container.read(readingSessionProvider)!.presetCards, preset);
  });
}
