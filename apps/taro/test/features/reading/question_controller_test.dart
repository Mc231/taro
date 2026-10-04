import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taro/app_state/sync_coordinator.dart';
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
            version: 2,
          ),
        ),
      );
      await pumpEventQueue();
      expect(log.last, isA<QuestionReady>());
    });

    test('deviceUnverified', () async {
      fakes.install = FakeInstallRepository(
        identity: anInstallIdentity(registered: false),
      )..failNext(const Failure.network(), on: 'ensureRegistered');
      final (_, log, controller) = await open();
      await controller.begin();
      expect(log.last, isA<QuestionDeviceUnverified>());
      expect(
        eventsOf<DeviceUnverifiedShownEvent>(fakes).single.origin,
        AppNoticeOrigin.readingGate,
      );
    });

    test('deviceUnverified heals: Retry registers and the reading '
        'starts', () async {
      fakes.install = FakeInstallRepository(
        identity: anInstallIdentity(registered: false),
      )..failNext(const Failure.network(), on: 'ensureRegistered');
      final (_, log, controller) = await open();
      await controller.begin();
      expect(log.last, isA<QuestionDeviceUnverified>());
      controller.dismissNotice();
      await controller.begin();
      expect(log.last, isA<QuestionReady>());
      expect(fakes.readings.holds, hasLength(1));
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

    test('attestation that a repair cannot fix → deviceUnverified', () async {
      const refused = Failure.attestation(
        kind: AttestationFailureKind.rejected,
      );
      fakes.readings.failNextWorkerCall(refused);
      final state = await holdFails(refused);
      expect(state, isA<QuestionDeviceUnverified>());
      expect(fakes.install.calls, contains('repairRegistration'));
    });

    test('an install upgraded to App Attest whose key cannot sign '
        '(keyInvalidated before any request) repairs and starts the '
        'reading', () async {
      final state = await holdFails(
        const Failure.attestation(kind: AttestationFailureKind.keyInvalidated),
      );
      expect(state, isA<QuestionReady>());
      expect(fakes.install.calls, contains('repairRegistration'));
      expect(fakes.readings.holds, hasLength(2));
    });

    test('a session revoked by the upgrade re-registration repairs and '
        'starts the reading', () async {
      final state = await holdFails(const Failure.sessionExpired());
      expect(state, isA<QuestionReady>());
    });

    test('deviceUnverified returns to editing after a successful sync '
        '(launch or resume)', () async {
      const refused = Failure.attestation(
        kind: AttestationFailureKind.rejected,
      );
      fakes.readings
        ..failNextWorkerCall(refused)
        ..failNextWorkerCall(refused);
      final (container, log, controller) = await open();
      await controller.begin();
      expect(log.last, isA<QuestionDeviceUnverified>());
      await container.read(syncCoordinatorProvider).run(SyncReason.resume);
      await pumpEventQueue();
      expect(log.last, isA<QuestionEditing>());
      expect(log.last.draft.canBegin, isTrue);
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
      final (container, log, controller) = await open();
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
      final refused = log.last as QuestionRefused;
      expect(refused.category, RefusalCategory.sexualMinors);
      expect(refused.draw, draw);
      // Moderation-blocked: the neutral message only, no reflect path.
      await controller.reflectWithoutQuestion();
      expect(log.last, isA<QuestionRefused>());
    });

    test(
      'refused(advice category): reflect reuses the declined cards',
      () async {
        final (container, log, controller) = await open();
        controller.updateText('Is this mole serious?');
        container
            .read(readingHandoffProvider.notifier)
            .post(
              ReadingHandoff.declined(
                safety: const SafetyInfo(
                  category: RefusalCategory.health,
                  messageKey: 'safetyDeclinedHealth',
                  canRephrase: false,
                ),
                draw: draw,
              ),
            );
        await pumpEventQueue();
        expect(log.last, isA<QuestionRefused>());
        await controller.reflectWithoutQuestion();
        expect(log.last, isA<QuestionReady>());
        final session = container.read(readingSessionProvider)!;
        expect(session.question, isNull);
        expect(session.presetCards.map((c) => c.cardId), draw.cardIds);
      },
    );

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

    void decline(
      ProviderContainer container, {
      RefusalCategory category = RefusalCategory.health,
      bool canRephrase = true,
      bool notCharged = true,
    }) => container
        .read(readingHandoffProvider.notifier)
        .post(
          ReadingHandoff.declined(
            safety: SafetyInfo(
              category: category,
              messageKey: category.messageKey,
              canRephrase: canRephrase,
            ),
            draw: draw,
            notCharged: notCharged,
          ),
        );

    test('the not-charged flag comes from the Worker response', () async {
      final (container, log, _) = await open();
      decline(container);
      await pumpEventQueue();
      expect((log.last as QuestionRephrase).notCharged, isTrue);
      decline(container, canRephrase: false, notCharged: false);
      await pumpEventQueue();
      expect((log.last as QuestionRefused).notCharged, isFalse);
    });

    test('rephrase: back to editing with the declined question kept, '
        'no hold and no draw until Begin', () async {
      final (container, log, controller) = await open();
      controller.updateText('Will the kids get sick?');
      decline(container);
      await pumpEventQueue();
      expect(log.last.isRefusal, isTrue);
      controller.rephrase();
      final editing = log.last as QuestionEditing;
      expect(editing.draft.text, 'Will the kids get sick?');
      expect(editing.isRefusal, isFalse);
      expect(fakes.readings.holds, isEmpty);
      expect(container.read(readingSessionProvider), isNull);
    });

    test(
      'rephrase(clear): "Ask a different question" empties the field',
      () async {
        final (container, log, controller) = await open();
        controller.updateText('Something blocked');
        decline(
          container,
          category: RefusalCategory.sexualMinors,
          canRephrase: false,
        );
        await pumpEventQueue();
        controller.rephrase(clear: true);
        final editing = log.last as QuestionEditing;
        expect(editing.draft.text, isEmpty);
        expect(editing.draft.canBegin, isTrue);
      },
    );

    test('a rewording chip fills the editor and returns to editing', () async {
      final (container, log, controller) = await open();
      controller.updateText('Will the kids get sick?');
      decline(container);
      await pumpEventQueue();
      controller.useSuggestion('How can I support the people I love?');
      final editing = log.last as QuestionEditing;
      expect(editing.draft.text, 'How can I support the people I love?');
      expect(editing.draft.usedSuggestion, isTrue);
    });

    test('rephrase is ignored outside the refusal state', () async {
      final (_, log, controller) = await open();
      controller.updateText('Q');
      final before = log.states.length;
      controller.rephrase();
      expect(log.states.length, before);
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
