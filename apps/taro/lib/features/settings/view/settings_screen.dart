import 'dart:async';

import 'package:flutter/material.dart' hide ThemeMode;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:taro/common/bidi.dart';
import 'package:taro/di/providers.dart';
import 'package:taro/features/settings/controller/settings_controller.dart';
import 'package:taro/features/settings/view/language_names.dart';
import 'package:taro/l10n/generated/taro_localizations.dart';
import 'package:taro/routing/routes.dart';
import 'package:taro_core/taro_core.dart';
import 'package:taro_ui/taro_ui.dart';

/// S20 Settings, tab "Settings" (01 §7.10, `docs/design/screens/S20`).
class SettingsScreen extends ConsumerWidget {
  /// Creates the screen.
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(settingsScreenControllerProvider);
    final controller = ref.read(settingsScreenControllerProvider.notifier);
    final links = ref.read(urlLauncherProvider);
    final review = ref.watch(storeLinksProvider).review;
    // Restore results are a snackbar (S20 spec); failures stay inline.
    ref.listen(settingsScreenControllerProvider, (previous, next) {
      final SettingsContent(:restore) = next as SettingsContent;
      if (restore is! SettingsRestoreSuccess) return;
      if (previous case SettingsContent(restore: SettingsRestoreSuccess())) {
        return;
      }
      final l10n = TaroLocalizations.of(context);
      TaroToast.show(
        context,
        message: restore.finding == RestoreFinding.removeAdsRestored
            ? l10n.restoreRemoveAds
            : l10n.restoreNothingFound,
      );
    });
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
      onRate: review == null ? null : () => unawaited(links.open(review)),
      onEmailTransfer: (code) {
        final support = (state as SettingsContent).view.support;
        if (support == null) return;
        final l10n = TaroLocalizations.of(context);
        unawaited(
          links.open(
            support.mailto(
              subject: l10n.helpEmailSubject(support.supportId),
              body:
                  l10n.helpEmailBody(
                    '${support.appVersion} (${support.buildNumber})',
                    '${support.platform.name} ${support.osVersion}',
                    support.locale,
                    support.supportId,
                  ) +
                  l10n.settingsTransferEmailLine(code),
            ),
          ),
        );
      },
    );
  }
}

/// The S20 layout for one [state]: the Readings, Experience, Privacy &
/// data, Help and About groups (S20 spec; every 01 §7.10 item, the usage
/// analytics toggle and ad choices living on S23).
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
    this.onRate,
    this.onEmailTransfer,
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

  /// Clears a shown transfer or restore result.
  final VoidCallback onAcknowledge;

  /// Copies a Support ID or transfer code.
  final ValueChanged<String> onCopy;

  /// "Rate Taro" (the store's review page); `null` disables the row.
  final VoidCallback? onRate;

  /// Emails the transfer code with the Support ID to support.
  final ValueChanged<String>? onEmailTransfer;

  @override
  Widget build(BuildContext context) {
    final l10n = TaroLocalizations.of(context);
    final tokens = context.tokens;
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
    final restoring = restore is SettingsRestoreInProgress;
    final checking = transfer is SettingsTransferChecking;
    final startSections = <Widget>[
      SettingsSection(
        title: l10n.settingsSectionReadings,
        children: [
          SettingsTile(
            leading: _Dot(color: tokens.color.card.frame),
            title: balance == null
                ? l10n.balanceUnknown
                : l10n.commonItemSeparator(
                    l10n.balanceReadings(balance.bonus + balance.displayPaid),
                    l10n.balanceFreeToday(balance.free.remaining),
                  ),
            subtitle: l10n.settingsGetMore,
            onTap: onStore,
          ),
          SettingsTile(
            title: l10n.storeRestore,
            subtitle: restoring ? l10n.settingsRestoreInProgress : null,
            showChevron: false,
            onTap: restoring ? null : onRestore,
          ),
          if (view.adsRemoved)
            SettingsTile(title: l10n.storeRemoveAdsOwned, onTap: null)
          else if (view.removeAdsOffered)
            SettingsTile(title: l10n.storeRemoveAdsTitle, onTap: onStore),
        ],
      ),
      if (restore is SettingsRestoreFailed)
        TaroInlineNotice(
          kind: TaroNoticeKind.error,
          title: l10n.restoreFailed,
          liveRegion: true,
          actions: [
            TaroButton.tertiary(label: l10n.commonRetry, onPressed: onRestore),
            dismiss,
          ],
        ),
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
                    alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(
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
          SettingsTile(
            title: l10n.settingsTheme,
            value: _themeLabel(l10n, settings.themeMode),
            onTap: () => unawaited(_pickTheme(context, settings.themeMode)),
          ),
        ],
      ),
    ];
    final endSections = <Widget>[
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
          SettingsTile(
            title: l10n.settingsMoveReadings,
            subtitle: checking
                ? l10n.settingsTransferChecking
                : l10n.settingsMoveReadingsSubtitle,
            onTap: checking ? null : onMoveReadings,
          ),
          SettingsTile(
            title: l10n.settingsLegal,
            subtitle: l10n.settingsLegalSubtitle,
            onTap: () => onNavigate(RoutePaths.legal('disclaimer')),
          ),
          SettingsTile(
            title: l10n.settingsRate,
            subtitle: l10n.commonExternalLink,
            showChevron: false,
            onTap: onRate,
          ),
        ],
      ),
      ..._transferNotice(l10n, transfer, dismiss),
      SettingsSection(
        title: l10n.settingsSectionAbout,
        footer: l10n.settingsSupportIdCaption,
        children: [
          if (support != null) ...[
            SettingsTile(
              title: l10n.settingsVersion(
                support.appVersion,
                support.buildNumber,
              ),
              onTap: null,
            ),
            _SupportIdRow(
              supportId: support.supportId,
              onCopy: () => onCopy(support.supportId),
            ),
          ] else
            SettingsTile(title: l10n.appTitle, onTap: null),
        ],
      ),
    ];
    Widget column(List<Widget> sections) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: tokens.space.s7,
      children: sections,
    );
    // Tablets show the groups in two columns (RC99); phones stack them in
    // the same order.
    return TaroScaffold(
      wide: true,
      body: ListView(
        padding: EdgeInsetsDirectional.only(
          top: tokens.space.s7,
          bottom: tokens.space.s7,
        ),
        children: [
          TaroLargeTitle(l10n.settingsTitle),
          SizedBox(height: tokens.space.s7),
          TaroColumns(
            spacing: tokens.space.s7,
            start: column(startSections),
            end: column(endSections),
          ),
        ],
      ),
    );
  }

  List<Widget> _transferNotice(
    TaroLocalizations l10n,
    SettingsTransfer transfer,
    Widget dismiss,
  ) => switch (transfer) {
    SettingsTransferIdle() || SettingsTransferChecking() => const [],
    SettingsTransferCode(:final transferCode) => [
      TaroInlineNotice(
        kind: TaroNoticeKind.info,
        title: l10n.settingsTransferCodeTitle,
        body: '${ltrIsolate(transferCode)}\n${l10n.settingsTransferCodeBody}',
        liveRegion: true,
        actions: [
          TaroButton.tertiary(
            label: l10n.commonCopy,
            onPressed: () => onCopy(transferCode),
          ),
          if (onEmailTransfer case final email?)
            TaroButton.tertiary(
              label: l10n.settingsTransferEmail,
              onPressed: () => email(transferCode),
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
        kind: TaroNoticeKind.error,
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
  };

  static String _themeLabel(TaroLocalizations l10n, ThemeMode mode) =>
      switch (mode) {
        ThemeMode.system => l10n.settingsThemeSystem,
        ThemeMode.light => l10n.settingsThemeLight,
        ThemeMode.dark => l10n.settingsThemeDark,
      };

  Future<void> _pickTheme(BuildContext context, ThemeMode current) async {
    final l10n = TaroLocalizations.of(context);
    final picked = await TaroSheet.show<ThemeMode>(
      context,
      builder: (sheet) => TaroSheet(
        title: l10n.settingsTheme,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final mode in ThemeMode.values)
              TaroRadioTile<ThemeMode>(
                value: mode,
                groupValue: current,
                title: _themeLabel(l10n, mode),
                onChanged: (value) => Navigator.of(sheet).pop(value),
              ),
          ],
        ),
      ),
    );
    if (picked != null && picked != current) onTheme(picked);
  }
}

/// The balance row's dot (`color.card.frame`; decorative).
class _Dot extends StatelessWidget {
  const _Dot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    final side = context.tokens.space.s3;
    return Container(
      width: side,
      height: side,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

/// "Support ID 3f9a1c07" with the "Copy ID" pill (RC43); the pill reads
/// "Copy Support ID 3f9a1c07". The ID stays LTR in RTL text.
class _SupportIdRow extends StatelessWidget {
  const _SupportIdRow({required this.supportId, required this.onCopy});

  final String supportId;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final l10n = TaroLocalizations.of(context);
    final tokens = context.tokens;
    return Padding(
      padding: EdgeInsetsDirectional.symmetric(
        horizontal: tokens.space.s5,
        vertical: tokens.space.s3,
      ),
      child: Row(
        spacing: tokens.space.s4,
        children: [
          Expanded(
            child: Text(
              l10n.settingsSupportId(ltrIsolate(supportId)),
              style: tokens.typography.body.copyWith(
                color: tokens.color.text.primary,
              ),
            ),
          ),
          TaroButton.secondary(
            label: l10n.settingsCopyId,
            semanticsLabel: l10n.settingsCopyIdSemantics(supportId),
            expand: false,
            onPressed: onCopy,
          ),
        ],
      ),
    );
  }
}
