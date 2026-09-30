import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taro/app_state/consent_controller.dart';
import 'package:taro/app_state/remote_config_controller.dart';
import 'package:taro/di/providers.dart';
import 'package:taro_core/taro_core.dart';

part 'privacy_controller.freezed.dart';

/// What S23 shows.
@freezed
abstract class PrivacyView with _$PrivacyView {
  /// Creates a view.
  const factory PrivacyView({
    /// AI readings: "Allowed" (Withdraw) or "Not allowed" (Allow → S04).
    required bool aiGranted,

    /// "Ad personalisation" + "Review ad choices" is shown only when UMP
    /// reports `privacyOptionsRequirementStatus == required`.
    required bool adsPrivacyOptionsRequired,

    /// The ATT status (iOS only; `null` on Android: no Tracking row).
    required TrackingStatus? tracking,

    /// "Usage analytics" (also binds crash reports, 02 §13).
    required bool analyticsEnabled,
  }) = _PrivacyView;
}

/// S23 Privacy choices (01 §7.10 Privacy). The variants (UMP required or
/// not, iOS or Android, AI allowed or not) are fields of [PrivacyView].
@freezed
sealed class PrivacyState with _$PrivacyState {
  /// The privacy choices.
  const factory PrivacyState.content(PrivacyView view) = PrivacyContent;
}

/// Drives S23. "Taro works fully whatever you choose here."
final class PrivacyController extends Notifier<PrivacyState> {
  late ProviderSubscription<ConsentState> _consent;
  late ProviderSubscription<bool> _aiValid;
  TrackingStatus? _tracking;

  bool get _isIos => ref.read(appInfoProvider).platform == AppPlatform.ios;

  @override
  PrivacyState build() {
    _consent = ref.listen(consentProvider, (_, _) => _update());
    _aiValid = ref.listen(aiConsentValidProvider, (_, _) => _update());
    _tracking = _isIos ? _consent.read().tracking : null;
    unawaited(refreshTracking());
    return _compute();
  }

  /// Re-reads the ATT status (on open and back from iOS Settings).
  Future<void> refreshTracking() async {
    if (!_isIos) return;
    final status = await ref.read(trackingAuthorizationProvider).status();
    _tracking = status;
    _update();
  }

  /// "Stop AI readings" confirmed (the dialog is equal-weight; classic
  /// readings, the daily card, Learn and the journal keep working).
  Future<void> withdrawAi() async {
    final analytics = ref.read(analyticsServiceProvider);
    final version = ref.read(remoteConfigProvider).aiConsentVersion;
    final saved = await ref.read(consentProvider.notifier).declineAi();
    if (saved case Err()) return;
    await analytics.log(
      AiConsentDecidedEvent(
        granted: false,
        origin: AiConsentOrigin.settings,
        consentVersion: version,
      ),
    );
  }

  /// "Review ad choices": the UMP privacy options form.
  Future<void> reviewAdChoices() async {
    if (!_consent.read().ads.privacyOptionsRequired) return;
    await ref.read(consentProvider.notifier).showPrivacyOptions();
  }

  /// The "Usage analytics" switch. The event is logged while collection is
  /// on (after enabling, before disabling), so it is never dropped.
  Future<void> setAnalytics({required bool enabled}) async {
    final analytics = ref.read(analyticsServiceProvider);
    final consent = ref.read(consentProvider.notifier);
    if (!enabled) {
      await analytics.log(const AnalyticsToggledEvent(enabled: false));
    }
    await consent.setAnalyticsEnabled(enabled: enabled);
    if (enabled) {
      await analytics.log(const AnalyticsToggledEvent(enabled: true));
    }
  }

  void _update() {
    if (ref.mounted) state = _compute();
  }

  PrivacyState _compute() {
    final consent = _consent.read();
    return PrivacyState.content(
      PrivacyView(
        aiGranted: _aiValid.read(),
        adsPrivacyOptionsRequired: consent.ads.privacyOptionsRequired,
        tracking: _tracking,
        analyticsEnabled: consent.analyticsEnabled,
      ),
    );
  }
}

/// S23 controller.
final NotifierProvider<PrivacyController, PrivacyState>
privacyControllerProvider = NotifierProvider.autoDispose(
  PrivacyController.new,
);
