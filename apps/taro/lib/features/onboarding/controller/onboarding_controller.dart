import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taro/app_state/consent_controller.dart';
import 'package:taro/di/providers.dart';
import 'package:taro_core/taro_core.dart';

part 'onboarding_controller.freezed.dart';

/// When onboarding started in this process (for
/// `onboarding_completed.duration_s`); kept alive across S02 → S04.
final class OnboardingClock {
  /// The first onboarding screen shown, or `null`.
  DateTime? startedAt;

  /// Records [now] as the start unless one is recorded.
  void markStart(DateTime now) => startedAt ??= now;
}

/// The onboarding start (`onboardingClockProvider`).
final onboardingClockProvider = Provider<OnboardingClock>(
  (ref) => OnboardingClock(),
);

/// S02 Welcome and S03 Disclaimer (01 §7.12, §8.3), derived from the
/// persisted `ConsentState.onboardingStep` so a kill resumes at the same
/// step.
@freezed
sealed class OnboardingState with _$OnboardingState {
  /// S02: up to 3 swipeable pages (Reflect, Learn, Journal); skippable.
  const factory OnboardingState.welcome({
    required int page,
    @Default(OnboardingController.welcomePages) int pageCount,
  }) = OnboardingWelcome;

  /// S03 `content`: "I understand" is required to continue.
  const factory OnboardingState.disclaimer() = OnboardingDisclaimer;

  /// S03 `acknowledged`: onboarding continues on S04 (`/consent/ai`).
  const factory OnboardingState.acknowledged() = OnboardingAcknowledged;
}

/// S02–S03. Every step is persisted before it is shown next (01 §7.12).
final class OnboardingController extends Notifier<OnboardingState> {
  /// The Welcome page count.
  static const int welcomePages = 3;

  @override
  OnboardingState build() {
    final step = ref.watch(consentProvider.select((s) => s.onboardingStep));
    final analytics = ref.watch(analyticsServiceProvider);
    ref
        .watch(onboardingClockProvider)
        .markStart(ref.watch(clockProvider).now());
    final (state, viewed) = switch (step) {
      OnboardingStep.welcome => (
        const OnboardingState.welcome(page: 0),
        AnalyticsOnboardingStep.welcome,
      ),
      OnboardingStep.disclaimer => (
        const OnboardingState.disclaimer(),
        AnalyticsOnboardingStep.disclaimer,
      ),
      OnboardingStep.aiConsent ||
      OnboardingStep.ump ||
      OnboardingStep.att ||
      OnboardingStep.done => (const OnboardingState.acknowledged(), null),
    };
    if (viewed != null) {
      unawaited(analytics.log(OnboardingStepViewedEvent(step: viewed)));
    }
    return state;
  }

  /// The next Welcome page; past the last one, the disclaimer.
  Future<void> nextPage() async {
    final current = state;
    if (current is! OnboardingWelcome) return;
    if (current.page + 1 < current.pageCount) {
      state = current.copyWith(page: current.page + 1);
      return;
    }
    await skipWelcome();
  }

  /// "Skip": straight to the disclaimer (step 1 → 2).
  Future<void> skipWelcome() async {
    if (state is! OnboardingWelcome) return;
    await ref
        .read(consentProvider.notifier)
        .setOnboardingStep(OnboardingStep.disclaimer);
  }

  /// "I understand" (S03): persisted, then S04.
  Future<void> acknowledgeDisclaimer() async {
    if (state is! OnboardingDisclaimer) return;
    final analytics = ref.read(analyticsServiceProvider);
    final saved = await ref
        .read(consentProvider.notifier)
        .setOnboardingStep(OnboardingStep.aiConsent);
    if (saved.isOk) await analytics.log(const DisclaimerAcceptedEvent());
  }
}

/// S02–S03 (`onboardingControllerProvider`).
final NotifierProvider<OnboardingController, OnboardingState>
onboardingControllerProvider = NotifierProvider.autoDispose(
  OnboardingController.new,
);
