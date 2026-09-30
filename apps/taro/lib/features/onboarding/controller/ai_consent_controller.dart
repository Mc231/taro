import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show NotifierProviderFamily;
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taro/app_state/consent_controller.dart';
import 'package:taro/di/providers.dart';
import 'package:taro/features/onboarding/controller/onboarding_controller.dart';
import 'package:taro_core/taro_core.dart';

part 'ai_consent_controller.freezed.dart';

/// S04 AI consent (01 §7.12 step 3, §8.3; RC21): onboarding and the
/// reading-gate re-entry. **Allow AI readings** / **Not now** have equal
/// weight and nothing is pre-selected.
@freezed
sealed class AiConsentState with _$AiConsentState {
  /// Not decided at [version]. [previouslyDeclined] selects the F7
  /// re-entry copy ("AI readings need your permission").
  const factory AiConsentState.undecided({
    required AiConsentOrigin origin,
    required int version,
    @Default(false) bool previouslyDeclined,
  }) = AiConsentUndecided;

  /// Allowed: back to the origin (the reading gate re-runs, F7).
  const factory AiConsentState.granted({required AiConsentOrigin origin}) =
      AiConsentGranted;

  /// "Not now": back to the origin; from the reading flow it shows "AI
  /// readings need your permission" with **Allow** / **Back** and the
  /// Classic reading stays offered (F8).
  const factory AiConsentState.declined({required AiConsentOrigin origin}) =
      AiConsentDeclined;
}

/// S04. Versioned against `ai.consentVersion` (a higher version re-asks,
/// RC21). From onboarding, the decision continues with UMP → ATT (RC19)
/// through [OnboardingCompletion].
final class AiConsentController extends Notifier<AiConsentState> {
  /// A controller opened from [origin].
  AiConsentController(this.origin);

  /// Where S04 was opened from.
  final AiConsentOrigin origin;

  @override
  AiConsentState build() {
    final consent = ref.watch(consentStoreProvider).current;
    final version = ref
        .watch(remoteConfigRepositoryProvider)
        .current
        .aiConsentVersion;
    if (origin == AiConsentOrigin.onboarding) {
      unawaited(
        ref
            .watch(analyticsServiceProvider)
            .log(
              const OnboardingStepViewedEvent(
                step: AnalyticsOnboardingStep.aiConsent,
              ),
            ),
      );
    }
    return AiConsentState.undecided(
      origin: origin,
      version: version,
      previouslyDeclined: consent.ai.decision == AiConsentDecision.declined,
    );
  }

  /// **Allow AI readings** ([granted]) or **Not now**. From the reading
  /// flow's `declined` state, **Allow** may still be tapped.
  Future<Result<void>> decide({required bool granted}) async {
    final current = state;
    if (current is AiConsentGranted) return const Result.ok(null);
    if (current is AiConsentDeclined && !granted) return const Result.ok(null);
    final consent = ref.read(consentProvider.notifier);
    final analytics = ref.read(analyticsServiceProvider);
    final completion = origin == AiConsentOrigin.onboarding
        ? OnboardingCompletion(
            consent: consent,
            analytics: analytics,
            store: ref.read(consentStoreProvider),
            config: ref.read(remoteConfigRepositoryProvider),
            appInfo: ref.read(appInfoProvider),
            clock: ref.read(clockProvider),
            startedAt: ref.read(onboardingClockProvider).startedAt,
          )
        : null;
    final saved = granted ? await consent.grantAi() : await consent.declineAi();
    switch (saved) {
      case Err(:final failure):
        return Result.err(failure);
      case Ok(:final value):
        await analytics.log(
          AiConsentDecidedEvent(
            granted: granted,
            origin: origin,
            consentVersion: value.ai.version ?? 0,
          ),
        );
    }
    if (ref.mounted) {
      state = granted
          ? AiConsentState.granted(origin: origin)
          : AiConsentState.declined(origin: origin);
    }
    await completion?.run(aiConsent: granted);
    return const Result.ok(null);
  }
}

/// S04 (`aiConsentControllerProvider(origin)`).
final NotifierProviderFamily<
  AiConsentController,
  AiConsentState,
  AiConsentOrigin
>
aiConsentControllerProvider = NotifierProvider.autoDispose.family(
  AiConsentController.new,
);

/// The end of onboarding after S04 (01 §7.12 steps 4–6, RC19): the step
/// moves to `ump` (the router leaves onboarding for Home), UMP → ATT → Mobile
/// Ads run through `ConsentOrchestrator`, then the step is `done`.
///
/// Holds its dependencies directly: S04 is gone (and its controller
/// disposed) once the step leaves `aiConsent`.
final class OnboardingCompletion {
  /// Creates the sequence.
  OnboardingCompletion({
    required ConsentController consent,
    required AnalyticsService analytics,
    required ConsentStore store,
    required RemoteConfigRepository config,
    required AppInfo appInfo,
    required Clock clock,
    required DateTime? startedAt,
  }) : _consent = consent,
       _analytics = analytics,
       _store = store,
       _config = config,
       _appInfo = appInfo,
       _clock = clock,
       _startedAt = startedAt;

  final ConsentController _consent;
  final AnalyticsService _analytics;
  final ConsentStore _store;
  final RemoteConfigRepository _config;
  final AppInfo _appInfo;
  final Clock _clock;
  final DateTime? _startedAt;

  /// Runs the rest of onboarding; [aiConsent] is the S04 decision.
  Future<void> run({required bool aiConsent}) async {
    await _analytics.log(
      const OnboardingStepViewedEvent(step: AnalyticsOnboardingStep.ump),
    );
    await _consent.setOnboardingStep(OnboardingStep.ump);
    final trackingBefore = _store.current.tracking;
    final outcome = await _consent.runAdsConsent();
    if (outcome != null) await _logConsent(outcome, trackingBefore);
    await _consent.setOnboardingStep(OnboardingStep.done);
    final now = _clock.now();
    await _analytics.log(
      OnboardingCompletedEvent(
        durationS: now.difference(_startedAt ?? now).inSeconds,
        aiConsent: aiConsent,
      ),
    );
  }

  Future<void> _logConsent(
    ConsentOutcome outcome,
    TrackingStatus trackingBefore,
  ) async {
    final ads = outcome.ads;
    await _analytics.log(
      ConsentUmpResultEvent(
        status: switch (ads.status) {
          AdsConsentStatus.obtained => UmpResultStatus.obtained,
          AdsConsentStatus.notRequired => UmpResultStatus.notRequired,
          AdsConsentStatus.required => UmpResultStatus.requiredDeclined,
          AdsConsentStatus.unknown => UmpResultStatus.error,
        },
        // UMP shows its form only where consent is required.
        formShown:
            ads.status == AdsConsentStatus.obtained ||
            ads.status == AdsConsentStatus.required,
        canRequestAds: ads.canRequestAds,
      ),
    );
    final att = switch (outcome.tracking) {
      TrackingStatus.authorized => AttResultStatus.authorized,
      TrackingStatus.denied => AttResultStatus.denied,
      TrackingStatus.restricted => AttResultStatus.restricted,
      TrackingStatus.notDetermined => AttResultStatus.notDetermined,
      TrackingStatus.notSupported => null,
    };
    // ATT runs on iOS only, after UMP, and only when ads may be requested.
    if (att == null ||
        !ads.canRequestAds ||
        _appInfo.platform != AppPlatform.ios) {
      return;
    }
    await _analytics.log(
      const OnboardingStepViewedEvent(step: AnalyticsOnboardingStep.att),
    );
    await _analytics.log(
      ConsentAttResultEvent(
        status: att,
        prepromptShown:
            trackingBefore == TrackingStatus.notDetermined &&
            _config.current.adsAttPrepromptEnabled,
      ),
    );
  }
}
