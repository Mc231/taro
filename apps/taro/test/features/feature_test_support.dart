import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderListenable;
import 'package:taro_core/taro_core.dart';

import '../helpers/pump_app.dart';

export '../helpers/pump_app.dart';

/// Consent with AI data sharing granted at version 1 and onboarding done.
const ConsentState kAiGranted = ConsentState(
  onboardingStep: OnboardingStep.done,
  ai: AiConsent(decision: AiConsentDecision.granted, version: 2),
);

/// Fakes where an AI reading is allowed (registered, consent, a free
/// reading, online).
TaroFakes aiReadyFakes() => TaroFakes(consent: kAiGranted);

/// Every state `provider` went through while listened, starting with the
/// current one.
final class StateLog<T> {
  StateLog(ProviderContainer container, ProviderListenable<T> provider) {
    subscription = container.listen<T>(
      provider,
      (previous, next) => states.add(next),
      fireImmediately: true,
    );
  }

  /// The listen subscription (keeps an auto-dispose provider alive).
  late final ProviderSubscription<T> subscription;

  /// Every state, oldest first.
  final List<T> states = [];

  /// The current state.
  T get last => subscription.read();
}

/// The analytics events of type [E].
List<E> eventsOf<E extends TaroAnalyticsEvent>(TaroFakes fakes) =>
    fakes.analytics.events.whereType<E>().toList();
