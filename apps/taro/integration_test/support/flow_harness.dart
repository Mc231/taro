import 'dart:async';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:patrol_finders/patrol_finders.dart';
import 'package:taro/bootstrap/bootstrap.dart';
import 'package:taro/bootstrap/build_defines.dart';
import 'package:taro/di/analytics_consent_tap.dart';
import 'package:taro/l10n/generated/taro_localizations.dart';
import 'package:taro/services/analytics/analytics_user_properties.dart';
import 'package:taro/services/analytics/consent_aware_analytics.dart';
import 'package:taro/services/consent/consent_orchestrator.dart';
import 'package:taro_core/taro_core.dart';
import 'package:taro_ui/taro_ui.dart';

import '../../test/helpers/pump_app.dart';
import '../../test/helpers/test_environment.dart';

export 'package:flutter_test/flutter_test.dart';
export 'package:patrol_finders/patrol_finders.dart';
export 'package:taro_core/taro_core.dart';

export '../../test/helpers/pump_app.dart';
export '../../test/helpers/test_environment.dart';

/// Patrol finder timeouts of the flows: a device frame can be slow on a
/// cold simulator, so waits are generous; settling is best-effort because
/// the loading kit animates forever.
const PatrolTesterConfig kFlowConfig = PatrolTesterConfig(
  existsTimeout: Duration(seconds: 20),
  visibleTimeout: Duration(seconds: 20),
  settleTimeout: Duration(seconds: 5),
);

/// Registers one fake-backed flow (06 §4, RC13): a patrol test over the
/// real app booted by `bootstrap(FakeTaroEnvironment)` (`TARO_ENV=test`).
///
/// The flows use patrol's finders and run with `flutter test
/// integration_test/flows` (no native automation is needed: UMP, ATT,
/// StoreKit and AdMob are the `taro_core` fakes). The native-dialog flows
/// move to `patrolTest` with the real SDKs in the pre-release smoke.
void taroFlow(String description, Future<void> Function(PatrolTester $) body) {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  // Every boot opens fresh in-memory databases the fakes never use.
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  patrolWidgetTest(description, config: kFlowConfig, ($) async {
    expect(
      BuildDefines.taroEnv,
      BuildDefines.testEnv,
      reason: 'run the flows with --dart-define=TARO_ENV=test (06 §4)',
    );
    await body($);
  });
}

/// An onboarded consent state with AI consent granted for version 1.
ConsentState onboardedConsent({bool aiGranted = true}) => ConsentState(
  onboardingStep: OnboardingStep.done,
  ai: aiGranted
      ? AiConsent(
          decision: AiConsentDecision.granted,
          version: 1,
          at: kTestNow.subtract(const Duration(days: 1)),
        )
      : AiConsent(
          decision: AiConsentDecision.declined,
          version: 1,
          at: kTestNow.subtract(const Duration(days: 1)),
        ),
);

/// Fresh fakes for a flow: a registered install with a session, and the
/// consent state [consent] (onboarded with AI consent by default). ATT was
/// answered before (authorized), so the neutral pre-prompt (RC19) stays
/// away unless a flow sets `tracking` to `notDetermined`
/// (`consent_denied_test` walks through it).
TaroFakes flowFakes({ConsentState? consent, FakeClock? clock}) {
  final fakes = TaroFakes(
    clock: clock,
    consent: consent ?? onboardedConsent(),
  )..tracking = FakeTrackingAuthorization(current: TrackingStatus.authorized);
  fakes.sessionTokens.token = SessionToken(
    token: 'flow-session-token',
    expiresAt: kTestNow.add(const Duration(days: 7)),
  );
  return fakes;
}

/// The analytics sink behind `ConsentAwareAnalytics` in the flows: what
/// reached "Firebase" (06 §4, RC68).
final class FlowAnalyticsSink implements TaroAnalyticsBackend {
  /// A sink over [fake].
  FlowAnalyticsSink(this.fake);

  /// The recording fake.
  final FakeAnalyticsService fake;

  /// User properties applied, oldest first.
  final List<AnalyticsUserProperties> properties = [];

  @override
  Future<void> log(TaroAnalyticsEvent event) => fake.log(event);

  @override
  Future<void> screen(String screenId) => fake.screen(screenId);

  @override
  Future<void> setCollectionEnabled({required bool enabled}) =>
      fake.setCollectionEnabled(enabled: enabled);

  @override
  Future<void> setConsent(AnalyticsConsent consent) => fake.setConsent(consent);

  @override
  Future<void> setUserProperties(AnalyticsUserProperties properties) async =>
      this.properties.add(properties);
}

/// The running app of one flow: the environment, its container and the
/// patrol tester.
final class FlowApp {
  FlowApp._(this.$, this.env, this.container, this.orchestrator);

  /// Boots the real composition root over [env]'s fakes (a fresh onboarded
  /// install by default) and pumps the first frame.
  ///
  /// The analytics path is the production one (RC68): the fakes'
  /// `FakeAnalyticsService` is the sink behind an `AnalyticsConsentTap` and
  /// `ConsentAwareAnalytics`, released by the orchestrator's
  /// `whenResolved`.
  static Future<FlowApp> launch(
    PatrolTester $, {
    FakeTaroEnvironment? env,
    TaroFakes? fakes,
  }) async {
    final environment = env ?? FakeTaroEnvironment(fakes: fakes ?? flowFakes());
    final f = environment.fakes;
    final tap = AnalyticsConsentTap(FlowAnalyticsSink(f.analytics));
    final analytics = ConsentAwareAnalytics(
      inner: tap,
      whenResolved: tap.resolved,
      logger: f.logger,
    );
    final orchestrator = ConsentOrchestrator(
      consent: f.consentService,
      tracking: f.tracking,
      ads: f.ads,
      analytics: tap,
      store: f.consentStore,
      config: f.config,
      policy: () => AdRequestPolicy(
        bannersEnabled:
            f.config.current.adsEnabled &&
            f.config.current.adsBannerEnabled &&
            !f.entitlements.read().removesAds,
        rewardedEnabled:
            f.config.current.adsEnabled && f.config.current.rewardedEnabled,
      ),
      logger: f.logger,
    );
    unawaited(orchestrator.whenResolved.then((_) => tap.resolve()));
    f
      ..analyticsPort = analytics
      ..orchestratorPort = orchestrator;
    final container = await bootstrap(environment);
    expect(container, isNotNull, reason: 'bootstrap failed');
    await $.tester.pumpWidget(environment.app);
    await $.pump();
    final app = FlowApp._($, environment, container!, orchestrator);
    addTearDown(app.shutdown);
    return app;
  }

  /// The patrol tester.
  final PatrolTester $;

  /// The fake environment.
  final FakeTaroEnvironment env;

  /// The bootstrap container.
  final ProviderContainer container;

  /// The consent orchestrator of this run.
  final ConsentOrchestrator orchestrator;

  bool _down = false;

  /// Flow progress in the device log (`FLOW:` lines).
  static void _log(String message) => debugPrint('FLOW: $message');

  /// The fakes behind every port.
  TaroFakes get fakes => env.fakes;

  /// The test control port (clock, time zone, Worker scripting).
  TestControlPort get control => env.control;

  /// The strings of the app locale [locale] (`en` by default).
  TaroLocalizations l10n([String locale = 'en']) =>
      lookupTaroLocalizations(Locale(locale));

  /// The screen keyed [id] (`buildScreen` keys every screen by S-ID).
  Finder screen(ScreenId id) => find.byKey(ValueKey(id));

  /// Waits until the screen [id] is in the tree.
  Future<void> waitForScreen(ScreenId id) async {
    _log('wait $id');
    try {
      await $(screen(id)).waitUntilExists();
    } on Object {
      fail('$id not shown; on screen: ${visibleTexts().join(' | ')}');
    }
    await settle();
  }

  /// The texts in the tree (a failure message aid).
  List<String> visibleTexts() => [
    for (final e in find.byType(Text).evaluate()) ?(e.widget as Text).data,
  ];

  /// Waits until [finder] is in the tree and visible.
  Future<void> waitFor(Finder finder) async {
    _log('wait ${finder.toString(describeSelf: true)}');
    await $(finder).waitUntilVisible();
    await settle();
  }

  /// Waits until [condition] holds, pumping frames ([timeout] at most).
  Future<void> waitUntil(
    bool Function() condition, {
    Duration timeout = const Duration(seconds: 20),
    String? reason,
  }) async {
    final end = DateTime.timestamp().add(timeout);
    while (!condition()) {
      if (DateTime.timestamp().isAfter(end)) {
        fail('timed out waiting: ${reason ?? 'condition'}');
      }
      await $.tester.pump(const Duration(milliseconds: 100));
    }
  }

  /// Pumps frames for a moment; never fails on endless animations.
  Future<void> settle([Duration max = const Duration(seconds: 2)]) async {
    await $.tester
        .pumpAndSettle(
          const Duration(milliseconds: 100),
          EnginePhase.sendSemanticsUpdate,
          max,
        )
        .catchError((Object _) => 0);
  }

  /// Taps the first widget showing [text] (see [tapFinder]).
  Future<void> tapText(String text) {
    _log('tap "$text"');
    return _tap(find.text(text));
  }

  /// Taps the `TaroButton` labelled [label] (a coachmark or a notice may
  /// show the same words as plain text).
  Future<void> tapButton(String label) {
    _log('tap button "$label"');
    return _tap(find.widgetWithText(TaroButton, label));
  }

  /// Taps [finder]; it is scrolled into view first only when it is not
  /// hit-testable (scrolling drags the first scrollable, which under a
  /// sheet would hit the barrier and dismiss it).
  Future<void> tapFinder(Finder finder) {
    _log('tap ${finder.toString(describeSelf: true)}');
    return _tap(finder);
  }

  Future<void> _tap(Finder finder) async {
    // Give a screen that is still loading a moment before scrolling.
    for (var i = 0; i < 20 && !$.tester.any(finder); i++) {
      await $.tester.pump(const Duration(milliseconds: 100));
    }
    if (!$.tester.any(finder.hitTestable())) await $(finder).scrollTo();
    await $(finder).tap();
    await settle();
  }

  /// Types [text] in the only text field on screen.
  Future<void> enterQuestion(String text) async {
    await $(TextField).enterText(text);
    await settle();
  }

  /// Sends the app to the background and back (02 §9.2 resume path);
  /// [whileAway] runs while paused (e.g. the clock moves on).
  Future<void> backgroundAndResume({
    FutureOr<void> Function()? whileAway,
  }) async {
    final binding = $.tester.binding;
    [
      AppLifecycleState.inactive,
      AppLifecycleState.hidden,
      AppLifecycleState.paused,
    ].forEach(binding.handleAppLifecycleStateChanged);
    // No frames while paused: nothing may pump until `resumed`.
    await Future<void>.delayed(Duration.zero);
    await whileAway?.call();
    [
      AppLifecycleState.hidden,
      AppLifecycleState.inactive,
      AppLifecycleState.resumed,
    ].forEach(binding.handleAppLifecycleStateChanged);
    await settle();
  }

  /// Unmounts the app and disposes its container (a process death).
  Future<void> shutdown() async {
    if (_down) return;
    _down = true;
    await $.tester.pumpWidget(const SizedBox.shrink());
    container.dispose();
    await $.pump();
  }

  // ---------------------------------------------------------------------
  // Reading-flow steps shared by the flows (F1–F3, F6, F8).

  /// Home → "Start a reading" → S06 → [spreadName] → S07.
  Future<void> openQuestion({String? spreadName}) async {
    final l = l10n();
    await waitForScreen(ScreenId.s05);
    await tapButton(l.homeStartReading);
    await waitForScreen(ScreenId.s06);
    await tapText(spreadName ?? l.spread_three_ppf_name);
    await waitForScreen(ScreenId.s07);
  }

  /// Types the question and taps **Begin**.
  Future<void> begin({String question = kTestQuestion}) async {
    await enterQuestion(question);
    await tapButton(l10n().questionBegin);
  }

  /// S08: shuffle, "Draw for me", "Reveal all".
  Future<void> drawAndRevealAll() async {
    final l = l10n();
    await waitForScreen(ScreenId.s08);
    await tapButton(l.drawShuffleButton);
    await tapButton(l.drawForMe);
    await tapButton(l.drawRevealAll);
  }
}
