import 'dart:async';

import 'package:flutter/material.dart' hide ThemeMode;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:taro/features/settings/controller/settings_controller.dart';
import 'package:taro/features/settings/view/language_names.dart';
import 'package:taro/l10n/generated/taro_localizations.dart';
import 'package:taro/routing/routes.dart';
import 'package:taro_core/taro_core.dart';
import 'package:taro_ui/taro_ui.dart';

/// S20 Settings, tab "Settings" (01 §7.10).
class SettingsScreen extends ConsumerWidget {
  /// Creates the screen.
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(settingsScreenControllerProvider);
    final controller = ref.read(settingsScreenControllerProvider.notifier);
    void push(String location) => unawaited(context.push<void>(location));
    return SettingsLayout(
      state: state,
      onNavigate: push,
      onStore: () => push(
        Uri(
          path: RoutePaths.store,
          queryParameters: {'source': StoreSource.settings.name},
        ).toString(),
      ),
      onReversals: (on) => unawaited(controller.setReversals(enabled: on)),
      onHaptics: (on) => unawaited(controller.setHaptics(enabled: on)),
      onTheme: (mode) => unawaited(controller.setTheme(mode)),
      onRestore: () => unawaited(controller.restore()),
      onMoveReadings: () => unawaited(controller.moveReadings()),
      onAcknowledge: controller.acknowledge,
      onCopy: (text) async {
        await Clipboard.setData(ClipboardData(text: text));
        if (context.mounted) {
          TaroToast.show(
            context,
            message: TaroLocalizations.of(context).commonCopied,
          );
        }
      },
    );
  }
}

/// The S20 skeleton for one [state] (Phase 13.5; restyled in Phase 16).
class SettingsLayout extends StatelessWidget {
  /// Creates the view.
  const SettingsLayout({
    required this.state,
    required this.onNavigate,
    required this.onStore,
    required this.onReversals,
    required this.onHaptics,
    required this.onTheme,
    required this.onRestore,
    required this.onMoveReadings,
    required this.onAcknowledge,
    required this.onCopy,
    super.key,
  });

  /// The controller state.
  final SettingsScreenState state;

  /// Opens a settings sub-screen or another route.
  final ValueChanged<String> onNavigate;

  /// Opens the store (S11, source `settings`).
  final VoidCallback onStore;

  /// "Reversed cards".
  final ValueChanged<bool> onReversals;

  /// "Haptics".
  final ValueChanged<bool> onHaptics;

  /// Theme.
  final ValueChanged<ThemeMode> onTheme;

  /// Restore purchases.
  final VoidCallback onRestore;

  /// "Move readings from another device" (RC84).
  final VoidCallback onMoveReadings;

  /// Clears a shown restore or transfer result.
  final VoidCallback onAcknowledge;

  /// Copies a Support ID or transfer code.
  final ValueChanged<String> onCopy;

  @override
  Widget build(BuildContext context) {
    final l10n = TaroLocalizations.of(context);
    final SettingsContent(:view, :restore, :transfer) =
        state as SettingsContent;
    final settings = view.settings;
    final balance = view.balance;
    final reminder = settings.reminder;
    final support = view.support;
    final dismiss = TaroButton.tertiary(
      label: l10n.commonDismiss,
      onPressed: onAcknowledge,
    );
    return TaroScaffold(
      appBar: TaroAppBar(
        leading: TaroAppBarLeading.none,
        title: l10n.settingsTitle,
      ),
      body: ListView(
        children: [
          SettingsSection(
            title: l10n.settingsSectionReadings,
            children: [
              SettingsTile(
                title: l10n.balanceUnknown,
                value: balance == null
                    ? null
                    : l10n.commonItemSeparator(
                        l10n.balanceReadings(
                          balance.bonus + balance.displayPaid,
                        ),
                        l10n.balanceFreeToday(balance.free.remaining),
                      ),
                onTap: onStore,
              ),
              SettingsTile(title: l10n.settingsGetMore, onTap: onStore),
              if (view.adsRemoved)
                SettingsTile(
                  title: l10n.storeRemoveAdsTitle,
                  value: l10n.storeRemoveAdsOwned,
                  onTap: null,
                )
              else if (view.removeAdsOffered)
                SettingsTile(title: l10n.storeRemoveAdsTitle, onTap: onStore),
              SettingsTile(
                title: l10n.storeRestore,
                subtitle: restore is SettingsRestoreInProgress
                    ? l10n.settingsRestoreInProgress
                    : null,
                onTap: restore is SettingsRestoreInProgress ? null : onRestore,
              ),
              SettingsTile(
                title: l10n.settingsMoveReadings,
                subtitle: transfer is SettingsTransferChecking
                    ? l10n.settingsTransferChecking
                    : l10n.settingsMoveReadingsSubtitle,
                onTap: transfer is SettingsTransferChecking
                    ? null
                    : onMoveReadings,
              ),
            ],
          ),
          ...switch (restore) {
            SettingsRestoreIdle() || SettingsRestoreInProgress() => const [],
            SettingsRestoreSuccess(:final finding) => [
              TaroInlineNotice(
                kind: TaroNoticeKind.success,
                title: finding == RestoreFinding.removeAdsRestored
                    ? l10n.restoreRemoveAds
                    : l10n.restoreNothingFound,
                liveRegion: true,
                actions: [dismiss],
              ),
            ],
            SettingsRestoreFailed() => [
              TaroInlineNotice(
                kind: TaroNoticeKind.warning,
                title: l10n.restoreFailed,
                liveRegion: true,
                actions: [
                  TaroButton.tertiary(
                    label: l10n.commonRetry,
                    onPressed: onRestore,
                  ),
                  dismiss,
                ],
              ),
            ],
          },
          ...switch (transfer) {
            SettingsTransferIdle() || SettingsTransferChecking() => const [],
            SettingsTransferCode(:final transferCode) => [
              TaroInlineNotice(
                kind: TaroNoticeKind.info,
                title: l10n.settingsTransferCodeTitle,
                body: '$transferCode\n${l10n.settingsTransferCodeBody}',
                liveRegion: true,
                actions: [
                  TaroButton.tertiary(
                    label: l10n.commonCopy,
                    onPressed: () => onCopy(transferCode),
                  ),
                  dismiss,
                ],
              ),
            ],
            SettingsTransferNothing() => [
              TaroInlineNotice(
                kind: TaroNoticeKind.info,
                title: l10n.settingsTransferNothing,
                liveRegion: true,
                actions: [dismiss],
              ),
            ],
            SettingsTransferNotEligible() => [
              TaroInlineNotice(
                kind: TaroNoticeKind.info,
                title: l10n.settingsTransferNotEligible,
                liveRegion: true,
                actions: [dismiss],
              ),
            ],
            SettingsTransferFailed() => [
              TaroInlineNotice(
                kind: TaroNoticeKind.warning,
                title: l10n.settingsTransferFailed,
                liveRegion: true,
                actions: [
                  TaroButton.tertiary(
                    label: l10n.commonRetry,
                    onPressed: onMoveReadings,
                  ),
                  dismiss,
                ],
              ),
            ],
          },
          SettingsSection(
            title: l10n.settingsSectionExperience,
            children: [
              SettingsTile(
                title: l10n.settingsLanguage,
                value: switch (settings.localeOverride) {
                  final locale? => languageEndonym(locale),
                  null => l10n.settingsLanguageSystem,
                },
                onTap: () => onNavigate(RoutePaths.settingsLanguage),
              ),
              SettingsTile(
                title: l10n.settingsReminder,
                value: reminder.enabled
                    ? MaterialLocalizations.of(context).formatTimeOfDay(
                        TimeOfDay(hour: reminder.hour, minute: reminder.minute),
                        alwaysUse24HourFormat:
                            MediaQuery.alwaysUse24HourFormatOf(
                              context,
                            ),
                      )
                    : l10n.settingsReminderOff,
                onTap: () => onNavigate(RoutePaths.settingsReminder),
              ),
              SettingsTile.toggle(
                title: l10n.settingsReversals,
                subtitle: l10n.settingsReversalsSubtitle,
                switchValue: settings.reversalsEnabled,
                onChanged: onReversals,
              ),
              SettingsTile.toggle(
                title: l10n.settingsHaptics,
                switchValue: settings.hapticsEnabled,
                onChanged: onHaptics,
              ),
              Semantics(
                label: l10n.settingsTheme,
                child: SegmentedChoice<ThemeMode>(
                  segments: [
                    TaroSegment(
                      value: ThemeMode.system,
                      label: l10n.settingsThemeSystem,
                    ),
                    TaroSegment(
                      value: ThemeMode.light,
                      label: l10n.settingsThemeLight,
                    ),
                    TaroSegment(
                      value: ThemeMode.dark,
                      label: l10n.settingsThemeDark,
                    ),
                  ],
                  selected: settings.themeMode,
                  onChanged: onTheme,
                ),
              ),
            ],
          ),
          SettingsSection(
            title: l10n.settingsSectionPrivacyData,
            children: [
              SettingsTile(
                title: l10n.settingsAiReadings,
                value: view.aiConsentGranted
                    ? l10n.settingsAiAllowed
                    : l10n.settingsAiNotAllowed,
                onTap: () => onNavigate(RoutePaths.settingsPrivacy),
              ),
              SettingsTile(
                title: l10n.settingsPrivacyChoices,
                onTap: () => onNavigate(RoutePaths.settingsPrivacy),
              ),
              SettingsTile(
                title: l10n.settingsExport,
                onTap: () => onNavigate(RoutePaths.settingsExport),
              ),
              SettingsTile(
                title: l10n.settingsImport,
                onTap: () => onNavigate(RoutePaths.settingsImport),
              ),
              SettingsTile(
                title: l10n.settingsDeleteAll,
                destructive: true,
                onTap: () => onNavigate(RoutePaths.settingsDelete),
              ),
            ],
          ),
          SettingsSection(
            title: l10n.settingsSectionHelp,
            children: [
              SettingsTile(
                title: l10n.settingsHelpFaq,
                onTap: () => onNavigate(RoutePaths.help),
              ),
              SettingsTile(
                title: l10n.settingsSupportLines,
                subtitle: l10n.settingsSupportLinesSubtitle,
                onTap: () => onNavigate(RoutePaths.helpCrisis),
              ),
            ],
          ),
          SettingsSection(
            title: l10n.settingsSectionAbout,
            footer: l10n.settingsSupportIdCaption,
            children: [
              SettingsTile(
                title: l10n.settingsLegal,
                subtitle: l10n.settingsLegalSubtitle,
                onTap: () => onNavigate(RoutePaths.legal('disclaimer')),
              ),
              if (support != null) ...[
                SettingsTile(
                  title: l10n.settingsVersion(
                    support.appVersion,
                    support.buildNumber,
                  ),
                  onTap: null,
                ),
                SettingsTile(
                  title: l10n.settingsSupportId(support.supportId),
                  value: l10n.settingsCopyId,
                  onTap: () => onCopy(support.supportId),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
