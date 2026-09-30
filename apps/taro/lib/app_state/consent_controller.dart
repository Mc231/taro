import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taro/app_state/remote_config_controller.dart';
import 'package:taro/di/providers.dart';
import 'package:taro_core/taro_core.dart';

/// Consent state (02 §9.7): AI data sharing (versioned against
/// `ai.consentVersion`, RC21), UMP / ATT (through `ConsentOrchestrator`,
/// RC19), the analytics toggle and the persisted onboarding step.
final class ConsentController extends Notifier<ConsentState> {
  @override
  ConsentState build() {
    final store = ref.watch(consentStoreProvider);
    final subscription = store.watch().listen((consent) {
      state = consent;
    });
    ref.onDispose(subscription.cancel);
    return store.current;
  }

  /// Grants AI data sharing at the current `ai.consentVersion` (S04 Allow).
  Future<Result<ConsentState>> grantAi() => _setAi(AiConsentDecision.granted);

  /// Declines or revokes AI data sharing (S04 Not now, S23 revoke).
  Future<Result<ConsentState>> declineAi() =>
      _setAi(AiConsentDecision.declined);

  /// Persists the onboarding [step] (resumed there after a kill, 01 §7.12).
  Future<Result<ConsentState>> setOnboardingStep(OnboardingStep step) => ref
      .read(consentStoreProvider)
      .update((s) => s.copyWith(onboardingStep: step));

  /// The analytics toggle (S23): stored, and applied to analytics and crash
  /// collection at once.
  Future<Result<ConsentState>> setAnalyticsEnabled({
    required bool enabled,
  }) async {
    final saved = await ref
        .read(consentStoreProvider)
        .update((s) => s.copyWith(analyticsEnabled: enabled));
    await ref
        .read(analyticsServiceProvider)
        .setCollectionEnabled(enabled: enabled);
    await ref
        .read(crashReporterProvider)
        .setCollectionEnabled(enabled: enabled);
    return saved;
  }

  /// Runs UMP → ATT → Mobile Ads once onboarding reached the UMP step
  /// (`null` before that).
  Future<ConsentOutcome?> runAdsConsent() =>
      ref.read(consentOrchestratorProvider).run();

  /// Shows the UMP privacy options form (S23).
  Future<ConsentOutcome> showPrivacyOptions() =>
      ref.read(consentOrchestratorProvider).showPrivacyOptions();

  Future<Result<ConsentState>> _setAi(AiConsentDecision decision) {
    final version = ref.read(remoteConfigRepositoryProvider).current;
    final now = ref.read(clockProvider).now();
    return ref
        .read(consentStoreProvider)
        .update(
          (s) => s.copyWith(
            ai: AiConsent(
              decision: decision,
              version: version.aiConsentVersion,
              at: now,
            ),
          ),
        );
  }
}

/// The app-wide consent state (`consentProvider`, 02 §7).
final consentProvider = NotifierProvider<ConsentController, ConsentState>(
  ConsentController.new,
);

/// Whether AI consent is granted at the current `ai.consentVersion`; a
/// higher version re-asks (RC21).
final aiConsentValidProvider = Provider<bool>((ref) {
  final consent = ref.watch(consentProvider);
  final config = ref.watch(remoteConfigProvider);
  return consent.ai.isValidFor(config.aiConsentVersion);
});
