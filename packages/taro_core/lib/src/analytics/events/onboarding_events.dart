part of '../taro_analytics_event.dart';

/// Onboarding events (01 §15 `OnboardingEvent`, §7.12).
sealed class OnboardingEvent extends TaroAnalyticsEvent {
  const OnboardingEvent._() : super._();
}

/// `onboarding_step_viewed`: an onboarding step was shown.
final class OnboardingStepViewedEvent extends OnboardingEvent {
  /// Creates the event.
  const OnboardingStepViewedEvent({required this.step}) : super._();

  /// The step shown.
  final AnalyticsOnboardingStep step;

  @override
  String get eventName => 'onboarding_step_viewed';

  @override
  Map<String, Object> get parameters => {'step': step.wire};
}

/// `onboarding_completed`: the last onboarding step finished.
final class OnboardingCompletedEvent extends OnboardingEvent {
  /// Creates the event.
  const OnboardingCompletedEvent({
    required this.durationS,
    required this.aiConsent,
  }) : super._();

  /// Seconds from the first step to completion.
  final int durationS;

  /// Whether AI consent was granted.
  final bool aiConsent;

  @override
  String get eventName => 'onboarding_completed';

  @override
  Map<String, Object> get parameters => {
    'duration_s': durationS,
    'ai_consent': aiConsent,
  };
}

/// `disclaimer_accepted`: the S03 disclaimer was accepted.
final class DisclaimerAcceptedEvent extends OnboardingEvent {
  /// Creates the event.
  const DisclaimerAcceptedEvent() : super._();

  @override
  String get eventName => 'disclaimer_accepted';

  @override
  Map<String, Object> get parameters => const {};
}
