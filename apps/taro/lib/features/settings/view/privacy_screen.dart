import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:taro/features/settings/controller/privacy_controller.dart';
import 'package:taro/l10n/generated/taro_localizations.dart';
import 'package:taro/routing/routes.dart';
import 'package:taro_core/taro_core.dart';
import 'package:taro_ui/taro_ui.dart';

/// S23 Privacy choices (01 §7.10): "Taro works fully whatever you choose
/// here."
class PrivacyScreen extends ConsumerWidget {
  /// Creates the screen.
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(privacyControllerProvider.notifier);
    return PrivacyLayout(
      state: ref.watch(privacyControllerProvider),
      onWithdrawAi: () async {
        final l10n = TaroLocalizations.of(context);
        // Equal-weight choices: neither button is the emphasised one.
        final confirmed = await TaroDialog.show<bool>(
          context,
          dismissible: true,
          builder: (dialog) => TaroDialog(
            title: l10n.privacyWithdrawTitle,
            body: l10n.privacyWithdrawBody,
            actions: [
              TaroButton.secondary(
                label: l10n.commonCancel,
                onPressed: () => Navigator.of(dialog).pop(false),
              ),
              TaroButton.secondary(
                label: l10n.privacyWithdrawConfirm,
                onPressed: () => Navigator.of(dialog).pop(true),
              ),
            ],
          ),
        );
        if (confirmed ?? false) await controller.withdrawAi();
      },
      onAllowAi: () => unawaited(context.push<void>(RoutePaths.consentAi)),
      onReviewAdChoices: () => unawaited(controller.reviewAdChoices()),
      onTracking: () => unawaited(controller.refreshTracking()),
      onAnalytics: (on) => unawaited(controller.setAnalytics(enabled: on)),
      onPolicy: () =>
          unawaited(context.push<void>(RoutePaths.legal('privacy'))),
      onBack: () => Navigator.of(context).maybePop(),
    );
  }
}

/// The S23 skeleton for one [state] (Phase 13.5; restyled in Phase 16).
class PrivacyLayout extends StatelessWidget {
  /// Creates the view.
  const PrivacyLayout({
    required this.state,
    required this.onWithdrawAi,
    required this.onAllowAi,
    required this.onReviewAdChoices,
    required this.onTracking,
    required this.onAnalytics,
    required this.onPolicy,
    required this.onBack,
    super.key,
  });

  /// The controller state.
  final PrivacyState state;

  /// "Withdraw" AI consent (asks first).
  final VoidCallback onWithdrawAi;

  /// "Allow" AI readings (→ S04).
  final VoidCallback onAllowAi;

  /// "Review ad choices" (the UMP privacy options form).
  final VoidCallback onReviewAdChoices;

  /// The Tracking row (re-reads the ATT status).
  final VoidCallback onTracking;

  /// The "Usage analytics" switch.
  final ValueChanged<bool> onAnalytics;

  /// "Read the privacy policy".
  final VoidCallback onPolicy;

  /// Back.
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final l10n = TaroLocalizations.of(context);
    final tokens = context.tokens;
    final PrivacyContent(:view) = state as PrivacyContent;
    final tracking = view.tracking;
    return TaroScaffold(
      appBar: TaroAppBar(
        leadingLabel: l10n.commonBack,
        onLeading: onBack,
        title: l10n.privacyTitle,
      ),
      body: ListView(
        children: [
          Text(l10n.privacyBody, style: tokens.typography.body),
          SettingsSection(
            title: l10n.privacyAiHeading,
            children: [
              SettingsTile(
                title: view.aiGranted
                    ? l10n.settingsAiAllowed
                    : l10n.settingsAiNotAllowed,
                subtitle: view.aiGranted
                    ? l10n.privacyAiAllowedSubtitle
                    : l10n.privacyAiNotAllowedSubtitle,
                value: view.aiGranted
                    ? l10n.privacyAiWithdraw
                    : l10n.privacyAiAllow,
                onTap: view.aiGranted ? onWithdrawAi : onAllowAi,
              ),
            ],
          ),
          if (view.adsPrivacyOptionsRequired || tracking != null)
            SettingsSection(
              title: l10n.privacyAdsHeading,
              children: [
                if (view.adsPrivacyOptionsRequired)
                  SettingsTile(
                    title: l10n.privacyAdPersonalisation,
                    subtitle: l10n.privacyAdPersonalisationSubtitle,
                    value: l10n.privacyReviewAdChoices,
                    onTap: onReviewAdChoices,
                  ),
                if (tracking != null)
                  SettingsTile(
                    title: l10n.privacyTracking,
                    value: switch (tracking) {
                      TrackingStatus.authorized => l10n.privacyTrackingAllowed,
                      TrackingStatus.notDetermined ||
                      TrackingStatus.notSupported =>
                        l10n.privacyTrackingNotAsked,
                      TrackingStatus.denied || TrackingStatus.restricted =>
                        l10n.privacyTrackingNotAllowed,
                    },
                    onTap: onTracking,
                  ),
              ],
            ),
          SettingsSection(
            title: l10n.privacyImprovingHeading,
            children: [
              SettingsTile.toggle(
                title: l10n.privacyAnalytics,
                subtitle: l10n.privacyAnalyticsSubtitle,
                switchValue: view.analyticsEnabled,
                onChanged: onAnalytics,
              ),
            ],
          ),
          TaroButton.tertiary(
            label: l10n.privacyReadPolicy,
            onPressed: onPolicy,
          ),
        ],
      ),
    );
  }
}
