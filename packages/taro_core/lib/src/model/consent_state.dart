import 'package:freezed_annotation/freezed_annotation.dart';

part 'consent_state.freezed.dart';

/// UMP consent status (02 §4, 04 §10).
enum AdsConsentStatus {
  /// Not requested yet.
  unknown,

  /// Consent is required and not yet given.
  required,

  /// Consent was obtained.
  obtained,

  /// Consent is not required in this region.
  notRequired,
}

/// App Tracking Transparency status (iOS; `notSupported` elsewhere).
enum TrackingStatus {
  /// The system prompt was not shown yet.
  notDetermined,

  /// Tracking is restricted by the device.
  restricted,

  /// The user denied tracking.
  denied,

  /// The user authorized tracking.
  authorized,

  /// The platform has no ATT.
  notSupported,
}

/// The user's AI data-sharing decision.
enum AiConsentDecision {
  /// Not asked yet.
  unknown,

  /// "Allow AI readings".
  granted,

  /// "Not now".
  declined,
}

/// Onboarding progress, persisted per step (01 §7.12).
enum OnboardingStep {
  /// Step 1: welcome pages.
  welcome,

  /// Step 2: disclaimer.
  disclaimer,

  /// Step 3: AI data-sharing consent.
  aiConsent,

  /// Step 4: UMP form.
  ump,

  /// Step 5: ATT pre-prompt and system prompt (iOS).
  att,

  /// Onboarding finished.
  done,
}

/// UMP state (02 §4 `AdsConsent`).
@freezed
abstract class AdsConsent with _$AdsConsent {
  /// Creates the UMP state.
  const factory AdsConsent({
    /// UMP status.
    @Default(AdsConsentStatus.unknown) AdsConsentStatus status,

    /// `ConsentInformation.canRequestAds`.
    @Default(false) bool canRequestAds,

    /// Whether Settings must show "Privacy options".
    @Default(false) bool privacyOptionsRequired,
  }) = _AdsConsent;
}

/// AI data-sharing consent (02 §4, RC21).
@freezed
abstract class AiConsent with _$AiConsent {
  /// Creates the AI consent.
  const factory AiConsent({
    /// The decision.
    @Default(AiConsentDecision.unknown) AiConsentDecision decision,

    /// The disclosure version the decision applies to.
    int? version,

    /// When the decision was made.
    DateTime? at,
  }) = _AiConsent;

  const AiConsent._();

  /// Whether consent covers [requiredVersion] (`ai.consentVersion`):
  /// granted for that version or a newer one (RC21).
  bool isValidFor(int requiredVersion) =>
      decision == AiConsentDecision.granted &&
      version != null &&
      version! >= requiredVersion;
}

/// Device-local consent state; never backed up (02 §4, 01 §7.11).
@freezed
abstract class ConsentState with _$ConsentState {
  /// Creates the consent state; the defaults are the first-launch state.
  const factory ConsentState({
    /// UMP state.
    @Default(AdsConsent()) AdsConsent ads,

    /// ATT status.
    @Default(TrackingStatus.notDetermined) TrackingStatus tracking,

    /// AI consent.
    @Default(AiConsent()) AiConsent ai,

    /// Whether analytics collection is on.
    @Default(false) bool analyticsEnabled,

    /// The onboarding step to resume at.
    @Default(OnboardingStep.welcome) OnboardingStep onboardingStep,
  }) = _ConsentState;

  const ConsentState._();

  /// Whether onboarding is finished.
  bool get onboardingDone => onboardingStep == OnboardingStep.done;
}
