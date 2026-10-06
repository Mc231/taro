import 'package:flutter_test/flutter_test.dart';
import 'package:taro/routing/deep_link_policy.dart';
import 'package:taro/routing/guards.dart';
import 'package:taro_core/taro_core.dart';

void main() {
  const policy = DeepLinkPolicy(universalLinkHost: 'taro.vshyrochuk.com');
  const done = GuardState(
    updateRequired: false,
    onboardingStep: OnboardingStep.done,
  );

  group('updateGuard', () {
    test('outdated → /update, and it stays there', () {
      const outdated = GuardState(
        updateRequired: true,
        onboardingStep: OnboardingStep.done,
      );
      expect(updateGuard(outdated, '/home'), '/update');
      expect(updateGuard(outdated, '/update'), isNull);
    });

    test('up to date: /update leads Home', () {
      expect(updateGuard(done, '/update'), '/home');
      expect(updateGuard(done, '/journal'), isNull);
    });

    test('redirectFor: /update when up to date leads Home', () {
      expect(
        redirectFor(
          state: done,
          uri: Uri.parse('/update'),
          policy: policy,
          pending: PendingDeepLink(),
        ),
        '/home',
      );
    });
  });

  group('onboardingGuard (resume at the persisted step, 01 §7.12)', () {
    final table = <OnboardingStep, String>{
      OnboardingStep.welcome: '/onboarding/welcome',
      OnboardingStep.disclaimer: '/onboarding/disclaimer',
      OnboardingStep.aiConsent: '/consent/ai',
    };
    for (final MapEntry(key: step, value: location) in table.entries) {
      test('$step → $location', () {
        final state = GuardState(updateRequired: false, onboardingStep: step);
        expect(onboardingGuard(state, '/home'), location);
        expect(onboardingGuard(state, '/'), location);
        expect(onboardingGuard(state, '/onboarding/welcome'), isNull);
        expect(onboardingLocationFor(step), location);
      });
    }

    // Release 1.0.0: the S03 "Read the full disclaimer" link was sent back
    // to S03 by this guard, so it did nothing on a device.
    test('S29 legal and S27 support lines open over onboarding', () {
      for (final step in table.keys) {
        final state = GuardState(updateRequired: false, onboardingStep: step);
        for (final doc in ['disclaimer', 'terms', 'privacy', 'licenses']) {
          expect(onboardingGuard(state, '/legal/$doc'), isNull);
        }
        expect(onboardingGuard(state, '/help/crisis'), isNull);
        expect(onboardingGuard(state, '/help'), table[step]);
        expect(onboardingGuard(state, '/legalese'), table[step]);
      }
    });

    test('from the UMP step on the app is usable', () {
      for (final step in [
        OnboardingStep.ump,
        OnboardingStep.att,
        OnboardingStep.done,
      ]) {
        final state = GuardState(updateRequired: false, onboardingStep: step);
        expect(state.onboarded, isTrue);
        expect(onboardingGuard(state, '/journal'), isNull);
        expect(onboardingLocationFor(step), '/home');
      }
    });

    test('after onboarding, the first screens and / lead Home', () {
      expect(onboardingGuard(done, '/'), '/home');
      expect(onboardingGuard(done, '/onboarding/welcome'), '/home');
      expect(onboardingGuard(done, '/onboarding/disclaimer'), '/home');
      expect(onboardingGuard(done, '/consent/ai'), isNull);
    });
  });

  group('redirectFor', () {
    String? redirect(GuardState state, String link, PendingDeepLink pending) =>
        redirectFor(
          state: state,
          uri: Uri.parse(link),
          policy: policy,
          pending: pending,
        );

    test('a deep link is sanitized', () {
      final pending = PendingDeepLink();
      expect(redirect(done, 'taro://daily', pending), '/daily');
      expect(redirect(done, 'taro://evil', pending), '/home');
      expect(redirect(done, '/daily', pending), isNull);
      expect(redirect(done, '/', pending), '/home');
    });

    test('the update guard wins over everything', () {
      const outdated = GuardState(
        updateRequired: true,
        onboardingStep: OnboardingStep.welcome,
      );
      final pending = PendingDeepLink();
      expect(redirect(outdated, 'taro://daily', pending), '/update');
      expect(redirect(outdated, '/update', pending), isNull);
      expect(pending.location, isNull);
    });

    test('a link during onboarding is queued until Home', () {
      const onboarding = GuardState(
        updateRequired: false,
        onboardingStep: OnboardingStep.disclaimer,
      );
      final pending = PendingDeepLink();
      expect(
        redirect(onboarding, 'taro://learn/card/major_00', pending),
        '/onboarding/disclaimer',
      );
      expect(pending.location, '/learn/card/major_00');
      expect(redirect(onboarding, '/onboarding/welcome', pending), isNull);
      // In-app legal opens over onboarding; a link to it still does not.
      expect(redirect(onboarding, '/legal/privacy', pending), isNull);
      expect(
        redirect(onboarding, 'taro://legal/privacy', PendingDeepLink()),
        '/onboarding/disclaimer',
      );
      expect(
        redirect(onboarding, '/journal', pending),
        '/onboarding/disclaimer',
      );

      expect(redirect(done, '/home', pending), '/learn/card/major_00');
      expect(pending.location, isNull);
      expect(redirect(done, '/home', pending), isNull);
    });

    test('an onboarding link to an onboarding screen is not queued', () {
      const onboarding = GuardState(
        updateRequired: false,
        onboardingStep: OnboardingStep.welcome,
      );
      final pending = PendingDeepLink();
      expect(
        redirect(onboarding, 'https://evil.example.com/x', pending),
        '/onboarding/welcome',
      );
      expect(pending.take(), '/home');
    });

    test('finishing onboarding on / also releases the queued link', () {
      final pending = PendingDeepLink()..queue('/daily');
      expect(redirect(done, '/', pending), '/daily');
    });
  });
}
