import 'package:flutter_test/flutter_test.dart';
import 'package:taro/services/consent/consent_orchestrator.dart';
import 'package:taro_core/taro_core.dart';

import '../../../../../packages/taro_core/test/fakes/fakes.dart';

const _both = AdRequestPolicy(bannersEnabled: true, rewardedEnabled: true);
const _none = AdRequestPolicy(bannersEnabled: false, rewardedEnabled: false);

/// A UMP scenario: the status before `gather` and the answer after the
/// form (when one is shown).
typedef _Ump = ({
  String name,
  AdsConsentStatus before,
  AdsConsent afterForm,
  bool canRequestAds,
  AnalyticsConsent analytics,
});

final _obtained = AnalyticsConsent.allDenied(); // no TCF purposes readable

final List<_Ump> _umpScenarios = [
  (
    name: 'unknown → form → obtained',
    before: AdsConsentStatus.unknown,
    afterForm: const AdsConsent(
      status: AdsConsentStatus.obtained,
      canRequestAds: true,
    ),
    canRequestAds: true,
    analytics: _obtained,
  ),
  (
    name: 'required → form → obtained',
    before: AdsConsentStatus.required,
    afterForm: const AdsConsent(
      status: AdsConsentStatus.obtained,
      canRequestAds: true,
      privacyOptionsRequired: true,
    ),
    canRequestAds: true,
    analytics: _obtained,
  ),
  (
    name: 'required → form dismissed → still required',
    before: AdsConsentStatus.required,
    afterForm: const AdsConsent(status: AdsConsentStatus.required),
    canRequestAds: false,
    analytics: AnalyticsConsent.allDenied(),
  ),
  (
    name: 'obtained earlier',
    before: AdsConsentStatus.obtained,
    afterForm: const AdsConsent(),
    canRequestAds: true,
    analytics: _obtained,
  ),
  (
    name: 'not required',
    before: AdsConsentStatus.notRequired,
    afterForm: const AdsConsent(),
    canRequestAds: true,
    analytics: AnalyticsConsent.allGranted(),
  ),
];

void main() {
  late CallRecorder recorder;
  late FakeConsentService ump;
  late FakeTrackingAuthorization att;
  late FakeAdsService ads;
  late FakeAnalyticsService analytics;
  late FakeConsentStore store;
  late FakeRemoteConfigRepository config;
  late CapturingLogger logger;
  late AdRequestPolicy policy;
  late int prePrompts;
  late ConsentOrchestrator orchestrator;

  ConsentOrchestrator build({
    AdsConsentStatus umpStatus = AdsConsentStatus.notRequired,
    AdsConsent? afterForm,
    TrackingStatus attStatus = TrackingStatus.notDetermined,
    TrackingStatus attAnswer = TrackingStatus.authorized,
    OnboardingStep step = OnboardingStep.done,
    TcfPurposeSource? tcf,
  }) {
    recorder = CallRecorder();
    ump = FakeConsentService(
      status: umpStatus,
      afterForm:
          afterForm ??
          const AdsConsent(
            status: AdsConsentStatus.obtained,
            canRequestAds: true,
          ),
    )..recorder = recorder;
    att = FakeTrackingAuthorization(current: attStatus, answer: attAnswer)
      ..recorder = recorder;
    ads = FakeAdsService()..recorder = recorder;
    analytics = FakeAnalyticsService()..recorder = recorder;
    store = FakeConsentStore(ConsentState(onboardingStep: step));
    config = FakeRemoteConfigRepository();
    logger = CapturingLogger();
    policy = _both;
    prePrompts = 0;
    return orchestrator = ConsentOrchestrator(
      consent: ump,
      tracking: att,
      ads: ads,
      analytics: analytics,
      store: store,
      config: config,
      policy: () => policy,
      logger: logger,
      tcfPurposes: tcf,
      prePrompt: () async {
        prePrompts++;
        recorder.add('prePrompt');
      },
    );
  }

  group('every UMP status × ATT status', () {
    for (final u in _umpScenarios) {
      for (final a in TrackingStatus.values) {
        test('${u.name} × ATT ${a.name}', () async {
          build(
            umpStatus: u.before,
            afterForm: u.afterForm,
            attStatus: a,
            attAnswer: TrackingStatus.denied,
          );
          expect(orchestrator.isResolved, isFalse);
          final outcome = (await orchestrator.run())!;

          expect(orchestrator.isResolved, isTrue);
          expect(outcome.ads.canRequestAds, u.canRequestAds);
          expect(store.current.ads, outcome.ads);
          expect(analytics.consents, [
            AnalyticsConsent.allDenied(),
            u.analytics,
          ]);
          expect(outcome.analytics, u.analytics);
          if (!u.canRequestAds) {
            // No ATT, no pre-prompt and no SDK init this launch (RC19).
            expect(att.calls, isEmpty);
            expect(prePrompts, 0);
            expect(ads.calls, isEmpty);
            expect(outcome.adsInitialized, isFalse);
            expect(outcome.tracking, TrackingStatus.notDetermined);
            return;
          }
          final prompted = a == TrackingStatus.notDetermined;
          expect(att.prompts, prompted ? 1 : 0);
          expect(prePrompts, prompted ? 1 : 0);
          final tracking = prompted ? TrackingStatus.denied : a;
          expect(outcome.tracking, tracking);
          expect(store.current.tracking, tracking);
          expect(ads.policy, _both);
          expect(outcome.adsInitialized, isTrue);
          // Order: UMP → consent mode → (pre-prompt → ATT) → SDK init.
          expect(
            recorder.isBefore('ConsentService.gather', 'AdsService.initialize'),
            isTrue,
          );
          expect(
            recorder.isBefore(
              'TrackingAuthorization.status',
              'AdsService.initialize',
            ),
            isTrue,
          );
          if (prompted) {
            expect(
              recorder.isBefore(
                'ConsentService.gather',
                'TrackingAuthorization.request',
              ),
              isTrue,
            );
            expect(
              recorder.isBefore('prePrompt', 'TrackingAuthorization.request'),
              isTrue,
            );
            expect(
              recorder.isBefore(
                'TrackingAuthorization.request',
                'AdsService.initialize',
              ),
              isTrue,
            );
          }
        });
      }
    }
  });

  test('no initialize before canRequestAds', () async {
    build(
      umpStatus: AdsConsentStatus.required,
      afterForm: const AdsConsent(status: AdsConsentStatus.required),
    );
    await orchestrator.run();
    expect(ads.calls, isEmpty);
    expect(ads.isInitialized, isFalse);
    expect(store.current.ads.canRequestAds, isFalse);

    // Privacy choices later give consent: ATT and the SDK follow.
    ump.consent = const AdsConsent(
      status: AdsConsentStatus.obtained,
      canRequestAds: true,
    );
    final later = await orchestrator.showPrivacyOptions();
    expect(ump.privacyOptionsShown, 1);
    expect(later.adsInitialized, isTrue);
    expect(att.prompts, 1);
    expect(
      recorder.isBefore(
        'ConsentService.showPrivacyOptions',
        'AdsService.initialize',
      ),
      isTrue,
    );
    expect(orchestrator.outcome, later);
  });

  group('onboarding first', () {
    for (final step in [
      OnboardingStep.welcome,
      OnboardingStep.disclaimer,
      OnboardingStep.aiConsent,
    ]) {
      test('${step.name}: nothing runs, consent unresolved', () async {
        build(step: step);
        expect(await orchestrator.run(), isNull);
        expect(recorder.calls, isEmpty);
        expect(orchestrator.isResolved, isFalse);
        expect(orchestrator.outcome, isNull);
      });
    }

    test('the UMP step runs it', () async {
      build(step: OnboardingStep.ump);
      expect(await orchestrator.run(), isNotNull);
      expect(ads.isInitialized, isTrue);
    });
  });

  test('runs once per launch', () async {
    build();
    final first = orchestrator.run();
    expect(orchestrator.run(), same(first));
    await first;
    await orchestrator.run();
    expect(ump.callCount('gather'), 1);
  });

  test('whenResolved completes before the ATT prompt', () async {
    build();
    var resolvedAtPrompt = false;
    orchestrator.prePrompt = () async =>
        resolvedAtPrompt = orchestrator.isResolved;
    final resolved = orchestrator.whenResolved;
    await orchestrator.run();
    await resolved;
    expect(resolvedAtPrompt, isTrue);
  });

  test('ads.attPrepromptEnabled false → system prompt only', () async {
    build();
    config.current = RemoteConfig.defaults.copyWith(
      adsAttPrepromptEnabled: false,
    );
    await orchestrator.run();
    expect(prePrompts, 0);
    expect(att.prompts, 1);
  });

  test('no pre-prompt attached → system prompt only', () async {
    build();
    orchestrator.prePrompt = null;
    await orchestrator.run();
    expect(att.prompts, 1);
  });

  test('a policy without ads skips the SDK', () async {
    build();
    policy = _none;
    final outcome = (await orchestrator.run())!;
    expect(outcome.adsInitialized, isFalse);
    expect(ads.calls, isEmpty);
  });

  test('an initialised SDK is not initialised again', () async {
    build();
    await ads.initialize(_both);
    ads.calls.clear();
    final outcome = (await orchestrator.run())!;
    expect(outcome.adsInitialized, isTrue);
    expect(ads.calls, isEmpty);
  });

  test('the debug geography is passed to UMP', () async {
    build();
    orchestrator = ConsentOrchestrator(
      consent: ump,
      tracking: att,
      ads: ads,
      analytics: analytics,
      store: store,
      config: config,
      policy: () => policy,
      logger: logger,
      debugEea: () => true,
    );
    await orchestrator.run();
    expect(ump.debugEeaRequests, [true]);
  });

  test('TCF purposes set consent mode after consent is obtained', () async {
    build(
      umpStatus: AdsConsentStatus.required,
      tcf: () async => '1111111111',
    );
    final outcome = (await orchestrator.run())!;
    expect(outcome.analytics, AnalyticsConsent.allGranted());
  });

  test('a store failure is logged; the run goes on', () async {
    build();
    store.failNext(const Failure.storage(), on: 'update');
    final outcome = (await orchestrator.run())!;
    expect(outcome.adsInitialized, isTrue);
    expect(logger.logged('consent not saved: STORAGE'), isTrue);
  });

  group('failures are logged and treated as denied', () {
    test('UMP throws → no ads, resolved', () async {
      build();
      orchestrator = ConsentOrchestrator(
        consent: _ThrowingConsent(),
        tracking: att,
        ads: ads,
        analytics: analytics,
        store: store,
        config: config,
        policy: () => policy,
        logger: logger,
      );
      final outcome = (await orchestrator.run())!;
      expect(outcome.ads, const AdsConsent());
      expect(ads.calls, isEmpty);
      expect(orchestrator.isResolved, isTrue);
      expect(logger.logged('ump gather failed'), isTrue);
      final later = await orchestrator.showPrivacyOptions();
      expect(later.ads, const AdsConsent());
      expect(logger.logged('privacy options failed'), isTrue);
      expect(logger.logged('ump current failed'), isTrue);
    });

    test('ATT throws → denied, ads still initialised', () async {
      build();
      orchestrator = ConsentOrchestrator(
        consent: ump,
        tracking: _ThrowingTracking(),
        ads: ads,
        analytics: analytics,
        store: store,
        config: config,
        policy: () => policy,
        logger: logger,
      );
      final outcome = (await orchestrator.run())!;
      expect(outcome.tracking, TrackingStatus.denied);
      expect(outcome.adsInitialized, isTrue);
      expect(logger.logged('att failed'), isTrue);
    });

    test('SDK init throws → not initialised', () async {
      build();
      orchestrator = ConsentOrchestrator(
        consent: ump,
        tracking: att,
        ads: _ThrowingAds(),
        analytics: analytics,
        store: store,
        config: config,
        policy: () => policy,
        logger: logger,
      );
      final outcome = (await orchestrator.run())!;
      expect(outcome.adsInitialized, isFalse);
      expect(logger.logged('ads init failed'), isTrue);
    });

    test('consent mode throws → still resolved', () async {
      build();
      var calls = 0;
      orchestrator = ConsentOrchestrator(
        consent: ump,
        tracking: att,
        ads: ads,
        analytics: analytics,
        store: store,
        config: config,
        policy: () => policy,
        logger: logger,
        tcfPurposes: () async {
          calls++;
          throw StateError('prefs');
        },
      );
      final outcome = (await orchestrator.run())!;
      expect(calls, 1);
      expect(orchestrator.isResolved, isTrue);
      expect(outcome.analytics, AnalyticsConsent.allDenied());
      expect(logger.logged('consent mode failed'), isTrue);
    });
  });

  group('analyticsConsentFor', () {
    const obtained = AdsConsent(
      status: AdsConsentStatus.obtained,
      canRequestAds: true,
    );

    test('no ads consent → all denied', () {
      expect(
        analyticsConsentFor(
          const AdsConsent(status: AdsConsentStatus.notRequired),
          '1111111111',
        ),
        AnalyticsConsent.allDenied(),
      );
      expect(
        analyticsConsentFor(
          const AdsConsent(
            status: AdsConsentStatus.required,
            canRequestAds: true,
          ),
          '1111111111',
        ),
        AnalyticsConsent.allDenied(),
      );
    });

    test('not required → all granted', () {
      expect(
        analyticsConsentFor(
          const AdsConsent(
            status: AdsConsentStatus.notRequired,
            canRequestAds: true,
          ),
          null,
        ),
        AnalyticsConsent.allGranted(),
      );
    });

    test('obtained without readable purposes → all denied', () {
      expect(analyticsConsentFor(obtained, null), AnalyticsConsent.allDenied());
    });

    test('obtained maps the TCF purposes', () {
      // P1 storage, P3/P4 personalisation, P7 ad measurement, P8 content.
      expect(
        analyticsConsentFor(obtained, '1011001'),
        const AnalyticsConsent(
          analyticsStorage: false,
          adStorage: true,
          adUserData: true,
          adPersonalization: true,
        ),
      );
      expect(
        analyticsConsentFor(obtained, '0111111'),
        const AnalyticsConsent(
          analyticsStorage: false,
          adStorage: false,
          adUserData: false,
          adPersonalization: true,
        ),
      );
      expect(
        analyticsConsentFor(obtained, '10000001'),
        const AnalyticsConsent(
          analyticsStorage: true,
          adStorage: true,
          adUserData: false,
          adPersonalization: false,
        ),
      );
    });
  });
}

final class _ThrowingConsent implements ConsentService {
  @override
  Future<AdsConsent> gather({bool debugEea = false}) => throw StateError('ump');

  @override
  Future<AdsConsent> current() => throw StateError('ump');

  @override
  Future<void> showPrivacyOptions() => throw StateError('ump');
}

final class _ThrowingTracking implements TrackingAuthorization {
  @override
  Future<TrackingStatus> status() => throw StateError('att');

  @override
  Future<TrackingStatus> request() => throw StateError('att');
}

final class _ThrowingAds implements AdsService {
  @override
  bool get isInitialized => false;

  @override
  Future<void> initialize(AdRequestPolicy policy) => throw StateError('sdk');

  @override
  Future<void> preloadRewarded() async {}

  @override
  Future<Result<RewardedShowResult>> showRewarded(RewardIntent intent) =>
      throw StateError('sdk');
}
