import 'package:taro_core/taro_core.dart';
import 'package:test/test.dart';

import 'contract_support.dart';

/// The `ConsentStore` contract (02 §5, §9.7). [create] returns a store in
/// the first-launch state.
void runConsentStoreContract(ConsentStore Function() create) {
  group('ConsentStore contract', () {
    late ConsentStore store;

    setUp(() => store = create());

    test('starts in the first-launch state', () {
      expect(store.current, const ConsentState());
      expect(store.current.onboardingDone, isFalse);
      expect(store.current.ai.decision, AiConsentDecision.unknown);
    });

    test('update applies the change and returns the new state', () async {
      final at = DateTime.utc(2026, 9, 26, 9);
      final next = expectOk(
        await store.update(
          (s) => s.copyWith(
            ai: AiConsent(
              decision: AiConsentDecision.granted,
              version: 1,
              at: at,
            ),
          ),
        ),
      );
      expect(next.ai.isValidFor(1), isTrue);
      expect(store.current, next);
    });

    test('watch emits the current state, then every change', () async {
      final seen = <ConsentState>[];
      final sub = store.watch().listen(seen.add);
      await settle();
      await store.update(
        (s) => s.copyWith(onboardingStep: OnboardingStep.disclaimer),
      );
      await store.update((s) => s.copyWith(analyticsEnabled: true));
      await settle();
      await sub.cancel();
      expect(seen.first, const ConsentState());
      expect(seen.last.onboardingStep, OnboardingStep.disclaimer);
      expect(seen.last.analyticsEnabled, isTrue);
    });

    test('concurrent updates are applied one after another', () async {
      await Future.wait([
        store.update((s) => s.copyWith(analyticsEnabled: true)),
        store.update(
          (s) => s.copyWith(tracking: TrackingStatus.denied),
        ),
      ]);
      expect(store.current.analyticsEnabled, isTrue);
      expect(store.current.tracking, TrackingStatus.denied);
    });
  });
}
