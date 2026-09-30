import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taro/features/settings/controller/reminder_settings_controller.dart';
import 'package:taro/l10n/generated/taro_localizations.dart';
import 'package:taro_core/taro_core.dart';
import 'package:taro_ui/taro_ui.dart';

/// S22 Reminder (01 §7.7): the toggle and the time; a denied permission
/// shows the system-settings note.
class ReminderSettingsScreen extends ConsumerWidget {
  /// Creates the screen.
  const ReminderSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(reminderSettingsControllerProvider.notifier);
    return ReminderSettingsLayout(
      state: ref.watch(reminderSettingsControllerProvider),
      onEnabled: (on) => unawaited(controller.setEnabled(enabled: on)),
      onChangeTime: (current) async {
        final picked = await showTimePicker(
          context: context,
          initialTime: current,
        );
        if (picked != null) {
          await controller.setTime(hour: picked.hour, minute: picked.minute);
        }
      },
      onOpenSettings: () => unawaited(controller.recheckPermission()),
      onBack: () => Navigator.of(context).maybePop(),
    );
  }
}

/// The S22 skeleton for one [state] (Phase 13.5; restyled in Phase 16).
class ReminderSettingsLayout extends StatelessWidget {
  /// Creates the view.
  const ReminderSettingsLayout({
    required this.state,
    required this.onEnabled,
    required this.onChangeTime,
    required this.onOpenSettings,
    required this.onBack,
    super.key,
  });

  /// The controller state.
  final ReminderSettingsState state;

  /// The switch.
  final ValueChanged<bool> onEnabled;

  /// "Change" the time (starting from the current one).
  final ValueChanged<TimeOfDay> onChangeTime;

  /// "Open settings" after a denied permission.
  final VoidCallback onOpenSettings;

  /// Back.
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final l10n = TaroLocalizations.of(context);
    final tokens = context.tokens;
    final (ReminderSettings reminder, bool denied) = switch (state) {
      ReminderSettingsContent(:final reminder) => (reminder, false),
      ReminderSettingsPermissionDenied(:final reminder) => (reminder, true),
    };
    final time = TimeOfDay(hour: reminder.hour, minute: reminder.minute);
    final timeText = MaterialLocalizations.of(context).formatTimeOfDay(
      time,
      alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
    );
    return TaroScaffold(
      appBar: TaroAppBar(
        leadingLabel: l10n.commonBack,
        onLeading: onBack,
        title: l10n.reminderTitle,
      ),
      body: ListView(
        children: [
          Text(l10n.reminderBody, style: tokens.typography.body),
          SizedBox(height: tokens.space.s5),
          SettingsTile.toggle(
            title: l10n.reminderToggle,
            subtitle: l10n.reminderPermissionNote,
            switchValue: reminder.enabled,
            onChanged: onEnabled,
          ),
          if (denied)
            TaroInlineNotice(
              kind: TaroNoticeKind.warning,
              title: l10n.reminderPermissionDenied,
              liveRegion: true,
              actions: [
                TaroButton.tertiary(
                  label: l10n.commonOpenSettings,
                  onPressed: onOpenSettings,
                ),
              ],
            ),
          SettingsTile(
            title: l10n.reminderAt,
            value: timeText,
            onTap: reminder.enabled ? () => onChangeTime(time) : null,
          ),
          SizedBox(height: tokens.space.s5),
          Text(l10n.reminderPreviewCaption, style: tokens.typography.label),
          NotificationPreview(
            appName: l10n.appTitle,
            time: timeText,
            title: l10n.appTitle,
            body: l10n.reminderBody1,
          ),
          Text(l10n.reminderPreviewNote, style: tokens.typography.caption),
        ],
      ),
    );
  }
}
