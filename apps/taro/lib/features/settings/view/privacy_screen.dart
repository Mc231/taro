import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:taro/common/settings_page.dart';
import 'package:taro/di/providers.dart';
import 'package:taro/features/settings/controller/privacy_controller.dart';
import 'package:taro/l10n/generated/taro_localizations.dart';
import 'package:taro/routing/routes.dart';
import 'package:taro_core/taro_core.dart';
import 'package:taro_ui/taro_ui.dart';

/// S23 Privacy choices (01 §7.10): "Taro works fully whatever you choose
/// here." Back from iOS Settings the tracking status is read again.
class PrivacyScreen extends ConsumerStatefulWidget {
  /// Creates the screen.
  const PrivacyScreen({super.key});

  @override
  ConsumerState<PrivacyScreen> createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends ConsumerState<PrivacyScreen> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onResume: () => unawaited(
        ref.read(privacyControllerProvider.notifier).refreshTracking(),
      ),
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                label: l10n.privacyWithdrawConfirm,
                onPressed: () => Navigator.of(dialog).pop(true),
              ),
              TaroButton.secondary(
                label: l10n.commonCancel,
                onPressed: () => Navigator.of(dialog).pop(false),
              ),
            ],
          ),
        );
        if (confirmed ?? false) await controller.withdrawAi();
      },
      onAllowAi: () => unawaited(context.push<void>(RoutePaths.consentAi)),
      onReviewAdChoices: () => unawaited(controller.reviewAdChoices()),
      onTracking: () =>
          unawaited(ref.read(urlLauncherProvider).openAppSettings()),
      onAnalytics: (on) => unawaited(controller.setAnalytics(enabled: on)),
      onPolicy: () =>
          unawaited(context.push<void>(RoutePaths.legal('privacy'))),
      onBack: () => Navigator.of(context).maybePop(),
    );
  }
}

/// The S23 layout for one [state] (`docs/design/screens/S23`): the AI
/// readings status with Withdraw / Allow, the ads block (only when UMP
/// requires it) with the Tracking row (iOS only), the usage analytics
/// switch, and the privacy policy link.
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

  /// The Tracking row (opens iOS Settings).
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
    final c = tokens.color;
    final PrivacyContent(:view) = state as PrivacyContent;
    final tracking = view.tracking;
    final granted = view.aiGranted;
    return SettingsPage(
      title: l10n.privacyTitle,
      lead: l10n.privacyBody,
      onBack: onBack,
      gap: tokens.space.s6,
      children: [
        SettingsSection(
          title: l10n.privacyAiHeading,
          children: [
            Padding(
              padding: EdgeInsetsDirectional.symmetric(
                horizontal: tokens.space.s5,
                vertical: tokens.space.s4,
              ),
              child: Row(
                spacing: tokens.space.s4,
                children: [
                  Expanded(
                    child: MergeSemantics(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: tokens.space.s1,
                        children: [
                          Row(
                            spacing: tokens.space.s3,
                            children: [
                              ExcludeSemantics(
                                child: Container(
                                  width: tokens.space.s3,
                                  height: tokens.space.s3,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: granted
                                        ? c.status.success
                                        : c.text.tertiary,
                                  ),
                                ),
                              ),
                              Flexible(
                                child: Text(
                                  granted
                                      ? l10n.settingsAiAllowed
                                      : l10n.settingsAiNotAllowed,
                                  style: tokens.typography.body.copyWith(
                                    color: c.text.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Text(
                            granted
                                ? l10n.privacyAiAllowedSubtitle
                                : l10n.privacyAiNotAllowedSubtitle,
                            style: tokens.typography.caption.copyWith(
                              color: c.text.secondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  TaroButton.secondary(
                    label: granted
                        ? l10n.privacyAiWithdraw
                        : l10n.privacyAiAllow,
                    expand: false,
                    onPressed: granted ? onWithdrawAi : onAllowAi,
                  ),
                ],
              ),
            ),
          ],
        ),
        if (view.adsPrivacyOptionsRequired || tracking != null)
          SettingsSection(
            title: l10n.privacyAdsHeading,
            children: [
              if (view.adsPrivacyOptionsRequired)
                Padding(
                  padding: EdgeInsetsDirectional.all(tokens.space.s5),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: tokens.space.s4,
                    children: [
                      MergeSemantics(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          spacing: tokens.space.s1,
                          children: [
                            Text(
                              l10n.privacyAdPersonalisation,
                              style: tokens.typography.body.copyWith(
                                color: c.text.primary,
                              ),
                            ),
                            Text(
                              l10n.privacyAdPersonalisationSubtitle,
                              style: tokens.typography.caption.copyWith(
                                color: c.text.secondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      TaroButton.secondary(
                        label: l10n.privacyReviewAdChoices,
                        expand: true,
                        onPressed: onReviewAdChoices,
                      ),
                    ],
                  ),
                ),
              if (tracking != null)
                SettingsTile(
                  title: l10n.privacyTracking,
                  subtitle: switch (tracking) {
                    TrackingStatus.authorized => l10n.privacyTrackingAllowed,
                    TrackingStatus.notDetermined ||
                    TrackingStatus.notSupported => l10n.privacyTrackingNotAsked,
                    TrackingStatus.denied ||
                    TrackingStatus.restricted => l10n.privacyTrackingNotAllowed,
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
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TaroButton.tertiary(
            label: l10n.privacyReadPolicy,
            expand: false,
            onPressed: onPolicy,
          ),
        ),
      ],
    );
  }
}
