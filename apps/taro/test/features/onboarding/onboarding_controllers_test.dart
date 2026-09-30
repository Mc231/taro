import 'package:flutter_test/flutter_test.dart';
import 'package:taro/features/onboarding/controller/ai_consent_controller.dart';
import 'package:taro/features/onboarding/controller/onboarding_controller.dart';
import 'package:taro_core/taro_core.dart';

import '../feature_test_support.dart';

void main() {
  late TaroFakes fakes;

  TaroFakes at(OnboardingStep step, {AiConsent ai = const AiConsent()}) =>
      TaroFakes(
        consent: ConsentState(onboardingStep: step, ai: ai),
      );

  List<AnalyticsOnboardingStep> viewed() => [
    for (final e in eventsOf<OnboardingStepViewedEvent>(fakes)) e.step,
  ];

  group('OnboardingController (S02–S03)', () {
    test('welcome pages, then the disclaimer, then S04', () async {
      fakes = at(OnboardingStep.welcome);
      final container = fakes.container();
      final log = StateLog(container, onboardingControllerProvider);
      final controller = container.read(onboardingControllerProvider.notifier);
      expect(log.last, const OnboardingState.welcome(page: 0));
      await controller.nextPage();
      await controller.nextPage();
      expect((log.last as OnboardingWelcome).page, 2);
      await controller.nextPage();
      await pumpEventQueue();
      expect(log.last, isA<OnboardingDisclaimer>());
      expect(
        fakes.consentStore.current.onboardingStep,
        OnboardingStep.disclaimer,
      );

      await container
          .read(onboardingControllerProvider.notifier)
          .acknowledgeDisclaimer();
      await pumpEventQueue();
      expect(log.last, isA<OnboardingAcknowledged>());
      expect(
        fakes.consentStore.current.onboardingStep,
        OnboardingStep.aiConsent,
      );
      expect(eventsOf<DisclaimerAcceptedEvent>(fakes), hasLength(1));
      expect(viewed(), [
        AnalyticsOnboardingStep.welcome,
        AnalyticsOnboardingStep.disclaimer,
      ]);
      expect(container.read(onboardingClockProvider).startedAt, kTestNow);
    });

    test(
      'skip goes straight to the disclaimer; out-of-step calls are ignored',
      () async {
        fakes = at(OnboardingStep.welcome);
        final container = fakes.container();
        final log = StateLog(container, onboardingControllerProvider);
        final controller = container.read(
          onboardingControllerProvider.notifier,
        );
        await controller.acknowledgeDisclaimer();
        expect(
          fakes.consentStore.current.onboardingStep,
          OnboardingStep.welcome,
        );
        await controller.skipWelcome();
        await pumpEventQueue();
        expect(log.last, isA<OnboardingDisclaimer>());
        final disclaimer = container.read(
          onboardingControllerProvider.notifier,
        );
        await disclaimer.skipWelcome();
        await disclaimer.nextPage();
        expect(log.last, isA<OnboardingDisclaimer>());
      },
    );

    test('a kill resumes at the persisted step', () {
      fakes = at(OnboardingStep.disclaimer);
      expect(
        fakes.container().read(onboardingControllerProvider),
        isA<OnboardingDisclaimer>(),
      );
      fakes = at(OnboardingStep.ump);
      expect(
        fakes.container().read(onboardingControllerProvider),
        isA<OnboardingAcknowledged>(),
      );
    });

    test('a failed step write logs no disclaimer_accepted', () async {
      fakes = at(OnboardingStep.disclaimer);
      final container = fakes.container();
      StateLog(container, onboardingControllerProvider);
      fakes.consentStore.failNext(const Failure.storage());
      await container
          .read(onboardingControllerProvider.notifier)
          .acknowledgeDisclaimer();
      expect(eventsOf<DisclaimerAcceptedEvent>(fakes), isEmpty);
    });
  });

  group('AiConsentController (S04)', () {
    test('onboarding Allow: granted, then UMP → ATT → done', () async {
      fakes = at(OnboardingStep.aiConsent);
      final container = fakes.container();
      container
          .read(onboardingClockProvider)
          .markStart(
            kTestNow.subtract(const Duration(seconds: 42)),
          );
      final log = StateLog(
        container,
        aiConsentControllerProvider(AiConsentOrigin.onboarding),
      );
      expect(
        log.last,
        const AiConsentState.undecided(
          origin: AiConsentOrigin.onboarding,
          version: 1,
        ),
      );
      await container
          .read(
            aiConsentControllerProvider(AiConsentOrigin.onboarding).notifier,
          )
          .decide(granted: true);
      expect(fakes.consentStore.current.ai.isValidFor(1), isTrue);
      expect(fakes.consentStore.current.onboardingStep, OnboardingStep.done);
      final decided = eventsOf<AiConsentDecidedEvent>(fakes).single;
      expect(decided.granted, isTrue);
      expect(decided.origin, AiConsentOrigin.onboarding);
      expect(decided.consentVersion, 1);
      expect(viewed(), [
        AnalyticsOnboardingStep.aiConsent,
        AnalyticsOnboardingStep.ump,
        AnalyticsOnboardingStep.att,
      ]);
      final ump = eventsOf<ConsentUmpResultEvent>(fakes).single;
      expect(ump.status, UmpResultStatus.notRequired);
      expect(ump.formShown, isFalse);
      expect(ump.canRequestAds, isTrue);
      final att = eventsOf<ConsentAttResultEvent>(fakes).single;
      expect(att.status, AttResultStatus.authorized);
      expect(att.prepromptShown, isTrue);
      final completed = eventsOf<OnboardingCompletedEvent>(fakes).single;
      expect(completed.aiConsent, isTrue);
      expect(completed.durationS, 42);
    });

    test(
      'onboarding Not now in the EEA: declined; ATT skipped on denial',
      () async {
        fakes = at(OnboardingStep.aiConsent)
          ..consentService = FakeConsentService(
            status: AdsConsentStatus.required,
            afterForm: const AdsConsent(status: AdsConsentStatus.required),
          );
        final container = fakes.container();
        final provider = aiConsentControllerProvider(
          AiConsentOrigin.onboarding,
        );
        final log = StateLog(container, provider);
        await container.read(provider.notifier).decide(granted: false);
        expect(
          fakes.consentStore.current.ai.decision,
          AiConsentDecision.declined,
        );
        expect(log.states, contains(isA<AiConsentDeclined>()));
        final ump = eventsOf<ConsentUmpResultEvent>(fakes).single;
        expect(ump.status, UmpResultStatus.requiredDeclined);
        expect(ump.formShown, isTrue);
        expect(eventsOf<ConsentAttResultEvent>(fakes), isEmpty);
        expect(
          eventsOf<OnboardingCompletedEvent>(fakes).single.aiConsent,
          isFalse,
        );
      },
    );

    test(
      'UMP obtained / unknown statuses and Android skip ATT events',
      () async {
        fakes = at(OnboardingStep.aiConsent)
          ..appInfo = const FakeAppInfo(platform: AppPlatform.android)
          ..consentService = FakeConsentService(
            status: AdsConsentStatus.unknown,
          );
        final container = fakes.container();
        final provider = aiConsentControllerProvider(
          AiConsentOrigin.onboarding,
        );
        StateLog(container, provider);
        await container.read(provider.notifier).decide(granted: true);
        final ump = eventsOf<ConsentUmpResultEvent>(fakes).single;
        expect(ump.status, UmpResultStatus.obtained);
        expect(ump.formShown, isTrue);
        expect(eventsOf<ConsentAttResultEvent>(fakes), isEmpty);
      },
    );

    test(
      'ATT already answered: no pre-prompt; notSupported logs nothing',
      () async {
        for (final (status, logged) in [
          (TrackingStatus.denied, AttResultStatus.denied),
          (TrackingStatus.restricted, AttResultStatus.restricted),
          (TrackingStatus.notSupported, null),
        ]) {
          fakes = TaroFakes(
            consent: ConsentState(
              onboardingStep: OnboardingStep.aiConsent,
              tracking: status,
            ),
          )..tracking = FakeTrackingAuthorization(current: status);
          final container = fakes.container();
          final provider = aiConsentControllerProvider(
            AiConsentOrigin.onboarding,
          );
          StateLog(container, provider);
          await container.read(provider.notifier).decide(granted: true);
          final att = eventsOf<ConsentAttResultEvent>(fakes);
          if (logged == null) {
            expect(att, isEmpty);
          } else {
            expect(att.single.status, logged);
            expect(att.single.prepromptShown, isFalse);
          }
        }
      },
    );

    test('ATT not determined after the prompt is logged as such', () async {
      fakes = at(OnboardingStep.aiConsent)
        ..tracking = FakeTrackingAuthorization(
          answer: TrackingStatus.notDetermined,
        );
      final container = fakes.container();
      final provider = aiConsentControllerProvider(AiConsentOrigin.onboarding);
      StateLog(container, provider);
      await container.read(provider.notifier).decide(granted: true);
      expect(
        eventsOf<ConsentAttResultEvent>(fakes).single.status,
        AttResultStatus.notDetermined,
      );
    });

    test('reading-gate re-entry: previously declined, then Allow', () async {
      fakes = at(
        OnboardingStep.done,
        ai: const AiConsent(decision: AiConsentDecision.declined, version: 1),
      );
      final container = fakes.container();
      final provider = aiConsentControllerProvider(
        AiConsentOrigin.readingGate,
      );
      final log = StateLog(container, provider);
      expect((log.last as AiConsentUndecided).previouslyDeclined, isTrue);
      final controller = container.read(provider.notifier);
      await controller.decide(granted: false);
      expect(log.last, isA<AiConsentDeclined>());
      await controller.decide(granted: false);
      await controller.decide(granted: true);
      expect(log.last, isA<AiConsentGranted>());
      await controller.decide(granted: false);
      expect(log.last, isA<AiConsentGranted>());
      expect(eventsOf<AiConsentDecidedEvent>(fakes), hasLength(2));
      expect(eventsOf<OnboardingCompletedEvent>(fakes), isEmpty);
      expect(viewed(), isEmpty);
    });

    test('a failed write keeps S04 undecided', () async {
      fakes = at(OnboardingStep.done);
      final container = fakes.container();
      final provider = aiConsentControllerProvider(AiConsentOrigin.settings);
      final log = StateLog(container, provider);
      fakes.consentStore.failNext(const Failure.storage());
      final result = await container
          .read(provider.notifier)
          .decide(granted: true);
      expect(result.isOk, isFalse);
      expect(log.last, isA<AiConsentUndecided>());
      expect(eventsOf<AiConsentDecidedEvent>(fakes), isEmpty);
    });
  });
}
