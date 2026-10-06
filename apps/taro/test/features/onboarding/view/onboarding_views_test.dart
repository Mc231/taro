import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taro/features/onboarding/controller/ai_consent_controller.dart';
import 'package:taro/features/onboarding/view/ai_consent_screen.dart';
import 'package:taro/features/onboarding/view/disclaimer_screen.dart';
import 'package:taro/features/onboarding/view/launch_screen.dart';
import 'package:taro/features/onboarding/view/welcome_screen.dart';
import 'package:taro/l10n/generated/taro_localizations.dart';
import 'package:taro/routing/routes.dart';
import 'package:taro_core/taro_core.dart';
import 'package:taro_ui/taro_ui.dart';

import '../../flow_view_support.dart';

TaroFakes _at(OnboardingStep step, {AiConsent ai = const AiConsent()}) =>
    TaroFakes(
      consent: ConsentState(onboardingStep: step, ai: ai),
    );

void main() {
  late TaroLocalizations l10n;

  setUpAll(() async => l10n = await enL10n());

  group('S01 Launch', () {
    testWidgets('bootstrapping shows the brand mark', (tester) async {
      await pumpTaroWidget(tester, const LaunchScreen());
      expect(find.byType(TaroBrandMark), findsOneWidget);
      expect(find.bySemanticsLabel(l10n.launchSemantics), findsWidgets);
    });
  });

  group('S02 Welcome', () {
    testWidgets('content: headline, features, Get started, step 1 of 3', (
      tester,
    ) async {
      await pumpTaroWidget(tester, const WelcomeLayout(onGetStarted: noop));
      expect(find.text(l10n.welcomeTitle), findsOneWidget);
      expect(find.text(l10n.welcomeFeatureFreeReading), findsOneWidget);
      expect(find.text(l10n.welcomeFeatureDailyCard), findsOneWidget);
      expect(find.text(l10n.welcomeFeatureJournal), findsOneWidget);
      expect(find.bySemanticsLabel(l10n.commonStepOf(1, 3)), findsOneWidget);
    });

    testWidgets('Get started persists the step and opens S03', (
      tester,
    ) async {
      final fakes = _at(OnboardingStep.welcome);
      await pumpFlow(
        tester,
        path: RoutePaths.onboardingWelcome,
        builder: (_) => const WelcomeScreen(),
        fakes: fakes,
      );
      await tapText(tester, l10n.welcomeGetStarted);
      expect(
        fakes.consentStore.current.onboardingStep,
        OnboardingStep.disclaimer,
      );
      expectRoute(RoutePaths.onboardingDisclaimer);
    });
  });

  group('S03 Disclaimer', () {
    testWidgets('content: the disclaimer and I understand enabled', (
      tester,
    ) async {
      await pumpTaroWidget(
        tester,
        const DisclaimerLayout(
          acknowledged: false,
          onAcknowledge: noop,
          onReadFull: noop,
        ),
      );
      expect(find.text(l10n.disclaimerOnboardingTitle), findsOneWidget);
      expect(find.text(l10n.disclaimerOnboardingBody), findsOneWidget);
      expect(find.text(l10n.disclaimerNoticeAi), findsOneWidget);
      final button = tester.widget<TaroButton>(
        find.widgetWithText(TaroButton, l10n.disclaimerAcknowledge),
      );
      expect(button.onPressed, isNotNull);
      expect(button.loading, isFalse);
      expect(find.bySemanticsLabel(l10n.commonStepOf(2, 3)), findsOneWidget);
    });

    testWidgets('acknowledged: the button is busy', (tester) async {
      await pumpTaroWidget(
        tester,
        const DisclaimerLayout(
          acknowledged: true,
          onAcknowledge: noop,
          onReadFull: noop,
        ),
      );
      final button = tester.widget<TaroButton>(
        find.byWidgetPredicate(
          (w) => w is TaroButton && w.label == l10n.disclaimerAcknowledge,
        ),
      );
      expect(button.loading, isTrue);
      expect(button.onPressed, isNull);
    });

    testWidgets('I understand persists and opens S04; full disclaimer', (
      tester,
    ) async {
      final fakes = _at(OnboardingStep.disclaimer);
      await pumpFlow(
        tester,
        path: RoutePaths.onboardingDisclaimer,
        builder: (_) => const DisclaimerScreen(),
        fakes: fakes,
      );
      final link = tester.widget<TaroButton>(
        find.widgetWithText(TaroButton, l10n.disclaimerReadFull),
      );
      expect(link.variant, TaroButtonVariant.link);
      await tapText(tester, l10n.disclaimerReadFull);
      expectRoute(RoutePaths.legal('disclaimer'));
    });

    testWidgets('I understand persists the step and opens S04', (
      tester,
    ) async {
      final fakes = _at(OnboardingStep.disclaimer);
      await pumpFlow(
        tester,
        path: RoutePaths.onboardingDisclaimer,
        builder: (_) => const DisclaimerScreen(),
        fakes: fakes,
      );
      await tapText(tester, l10n.disclaimerAcknowledge);
      expect(
        fakes.consentStore.current.onboardingStep,
        OnboardingStep.aiConsent,
      );
      expectRoute(RoutePaths.consentAi);
    });
  });

  group('S04 AI consent', () {
    Future<void> pumpLayout(WidgetTester tester, AiConsentState state) =>
        pumpTaroWidget(
          tester,
          AiConsentLayout(
            state: state,
            onAllow: noop,
            onNotNow: noop,
            onBack: noop,
            onPrivacy: noop,
          ),
        );

    testWidgets('undecided: equal-weight buttons, nothing pre-selected', (
      tester,
    ) async {
      await pumpLayout(
        tester,
        const AiConsentState.undecided(
          origin: AiConsentOrigin.onboarding,
          version: 1,
        ),
      );
      expect(find.text(l10n.aiConsentTitle), findsOneWidget);
      expect(find.text(l10n.aiConsentBody), findsOneWidget);
      final allow = find.widgetWithText(TaroButton, l10n.aiConsentAccept);
      final decline = find.widgetWithText(TaroButton, l10n.aiConsentDecline);
      final a = tester.widget<TaroButton>(allow);
      final d = tester.widget<TaroButton>(decline);
      expect(a.variant, d.variant);
      expect(a.expand, d.expand);
      expect(tester.getSize(allow), tester.getSize(decline));
      expect(a.onPressed, isNotNull);
      expect(d.onPressed, isNotNull);
      expect(find.bySemanticsLabel(l10n.commonStepOf(3, 3)), findsOneWidget);
      expect(find.byType(TaroAppBar), findsNothing);
      expect(find.byType(Checkbox), findsNothing);
    });

    testWidgets('granted: both buttons are disabled while leaving', (
      tester,
    ) async {
      await pumpLayout(
        tester,
        const AiConsentState.granted(origin: AiConsentOrigin.onboarding),
      );
      for (final b in tester.widgetList<TaroButton>(find.byType(TaroButton))) {
        if (b.label == l10n.commonPrivacyPolicy) continue;
        expect(b.onPressed, isNull);
      }
    });

    testWidgets('granted from the reading flow: the standard copy, busy', (
      tester,
    ) async {
      await pumpLayout(
        tester,
        const AiConsentState.granted(origin: AiConsentOrigin.readingGate),
      );
      expect(find.text(l10n.aiConsentTitle), findsOneWidget);
    });

    testWidgets(
      'declined from the reading flow: "AI readings need your permission" '
      'with equal-weight Allow / Back',
      (tester) async {
        await pumpLayout(
          tester,
          const AiConsentState.declined(origin: AiConsentOrigin.readingGate),
        );
        expect(find.text(l10n.aiConsentReentryTitle), findsOneWidget);
        final allow = find.widgetWithText(
          TaroButton,
          l10n.aiConsentReentryAllow,
        );
        final back = find.widgetWithText(TaroButton, l10n.aiConsentReentryBack);
        expect(
          tester.widget<TaroButton>(allow).variant,
          tester.widget<TaroButton>(back).variant,
        );
        expect(tester.getSize(allow), tester.getSize(back));
        expect(find.byType(TaroAppBar), findsOneWidget);
      },
    );

    testWidgets('undecided after an earlier decline shows the re-entry copy', (
      tester,
    ) async {
      await pumpLayout(
        tester,
        const AiConsentState.undecided(
          origin: AiConsentOrigin.readingGate,
          version: 2,
          previouslyDeclined: true,
        ),
      );
      expect(find.text(l10n.aiConsentReentryTitle), findsOneWidget);
    });

    test('fromQuery / location round-trip the origin', () {
      for (final origin in AiConsentOrigin.values) {
        final uri = Uri.parse(AiConsentScreen.location(origin));
        expect(uri.path, RoutePaths.consentAi);
        expect(
          AiConsentScreen.fromQuery(uri.queryParameters).origin,
          origin,
        );
      }
      expect(
        AiConsentScreen.fromQuery(const {'origin': 'bogus'}).origin,
        AiConsentOrigin.onboarding,
      );
    });

    testWidgets('onboarding: Allow grants and continues Home', (tester) async {
      final fakes = _at(OnboardingStep.aiConsent);
      await pumpFlow(
        tester,
        path: RoutePaths.consentAi,
        builder: (state) =>
            AiConsentScreen.fromQuery(state.uri.queryParameters),
        fakes: fakes,
      );
      await tapText(tester, l10n.aiConsentAccept);
      expect(fakes.consentStore.current.ai.decision, AiConsentDecision.granted);
      expectRoute(RoutePaths.home);
    });

    testWidgets('onboarding: Not now declines and continues Home', (
      tester,
    ) async {
      final fakes = _at(OnboardingStep.aiConsent);
      await pumpFlow(
        tester,
        path: RoutePaths.consentAi,
        builder: (state) =>
            AiConsentScreen.fromQuery(state.uri.queryParameters),
        fakes: fakes,
      );
      await tapText(tester, l10n.aiConsentDecline);
      expect(
        fakes.consentStore.current.ai.decision,
        AiConsentDecision.declined,
      );
      expectRoute(RoutePaths.home);
    });

    testWidgets('reading gate: Allow grants and returns to S07', (
      tester,
    ) async {
      final fakes = _at(OnboardingStep.done);
      await pumpFlow(
        tester,
        path: RoutePaths.consentAi,
        location: AiConsentScreen.location(AiConsentOrigin.readingGate),
        pushed: true,
        builder: (state) =>
            AiConsentScreen.fromQuery(state.uri.queryParameters),
        fakes: fakes,
      );
      await tapText(tester, l10n.aiConsentAccept);
      expect(fakes.consentStore.current.ai.decision, AiConsentDecision.granted);
      expectRoute('/');
    });

    testWidgets('reading gate: Not now shows Allow / Back; Back returns', (
      tester,
    ) async {
      final fakes = _at(OnboardingStep.done);
      await pumpFlow(
        tester,
        path: RoutePaths.consentAi,
        location: AiConsentScreen.location(AiConsentOrigin.readingGate),
        pushed: true,
        builder: (state) =>
            AiConsentScreen.fromQuery(state.uri.queryParameters),
        fakes: fakes,
      );
      await tapText(tester, l10n.aiConsentDecline);
      expect(find.text(l10n.aiConsentReentryTitle), findsOneWidget);
      await tapText(tester, l10n.aiConsentReentryBack);
      expectRoute('/');
    });

    for (final origin in AiConsentOrigin.values) {
      testWidgets('$origin: the privacy link opens the hosted policy', (
        tester,
      ) async {
        final fakes = _at(
          origin == AiConsentOrigin.onboarding
              ? OnboardingStep.aiConsent
              : OnboardingStep.done,
        );
        await pumpFlow(
          tester,
          path: RoutePaths.consentAi,
          location: AiConsentScreen.location(origin),
          pushed: origin != AiConsentOrigin.onboarding,
          builder: (state) =>
              AiConsentScreen.fromQuery(state.uri.queryParameters),
          fakes: fakes,
        );
        final link = tester.widget<TaroButton>(
          find.widgetWithText(TaroButton, l10n.commonPrivacyPolicy),
        );
        expect(link.variant, TaroButtonVariant.link);
        await tapText(tester, l10n.commonPrivacyPolicy);
        expect(fakes.links.openedInApp, [
          Uri.parse('https://taro.vshyrochuk.com/privacy?hl=en'),
        ]);
        // No in-app browser: the system browser.
        fakes.links.failNext(const Failure.storage(), on: 'openInApp');
        await tapText(tester, l10n.commonPrivacyPolicy);
        expect(fakes.links.opened, [
          Uri.parse('https://taro.vshyrochuk.com/privacy?hl=en'),
        ]);
      });
    }

    testWidgets('settings: Not now declines and returns', (tester) async {
      final fakes = _at(OnboardingStep.done);
      await pumpFlow(
        tester,
        path: RoutePaths.consentAi,
        location: AiConsentScreen.location(AiConsentOrigin.settings),
        pushed: true,
        builder: (state) =>
            AiConsentScreen.fromQuery(state.uri.queryParameters),
        fakes: fakes,
      );
      await tapText(tester, l10n.aiConsentDecline);
      expectRoute('/');
    });

    testWidgets('the app-bar Back goes Home when nothing is below', (
      tester,
    ) async {
      final fakes = _at(OnboardingStep.done);
      await pumpFlow(
        tester,
        path: RoutePaths.consentAi,
        location: AiConsentScreen.location(AiConsentOrigin.settings),
        builder: (state) =>
            AiConsentScreen.fromQuery(state.uri.queryParameters),
        fakes: fakes,
      );
      await tester.tap(find.bySemanticsLabel(l10n.commonBack).first);
      await tester.pumpAndSettle();
      expectRoute(RoutePaths.home);
    });
  });
}
