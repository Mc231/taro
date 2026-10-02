import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taro/common/settings_page.dart';
import 'package:taro/di/providers.dart';
import 'package:taro/features/settings/controller/reminder_settings_controller.dart';
import 'package:taro/l10n/generated/taro_localizations.dart';
import 'package:taro_core/taro_core.dart';
import 'package:taro_ui/taro_ui.dart';

/// S22 Reminder (01 §7.7): the toggle and the time; a denied permission
/// shows the system-settings note. Back from the system settings the
/// permission is asked again.
class ReminderSettingsScreen extends ConsumerStatefulWidget {
  /// Creates the screen.
  const ReminderSettingsScreen({super.key});

  @override
  ConsumerState<ReminderSettingsScreen> createState() =>
      _ReminderSettingsScreenState();
}

class _ReminderSettingsScreenState
    extends ConsumerState<ReminderSettingsScreen> {
  late final AppLifecycleListener _lifecycle;
  bool _inSettings = false;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onResume: _onResume);
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  void _onResume() {
    if (!_inSettings) return;
    _inSettings = false;
    unawaited(
      ref.read(reminderSettingsControllerProvider.notifier).recheckPermission(),
    );
  }

  @override
  Widget build(BuildContext context) {
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
      onOpenSettings: () async {
        _inSettings = true;
        final opened = await ref.read(urlLauncherProvider).openAppSettings();
        // No settings page to open: ask again right away.
        if (opened case Err()) {
          _inSettings = false;
          await controller.recheckPermission();
        }
      },
      onBack: () => Navigator.of(context).maybePop(),
    );
  }
}

/// The S22 layout for one [state] (`docs/design/screens/S22`): the switch
/// and the time button in one group, the notification preview, and the
/// permission note. Off: the time block and the preview are dimmed and
/// inactive. `permissionDenied`: a warning with "Open settings".
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
    final on = reminder.enabled;
    final time = TimeOfDay(hour: reminder.hour, minute: reminder.minute);
    final timeText = MaterialLocalizations.of(context).formatTimeOfDay(
      time,
      alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
    );
    final duration = context.reduceMotion
        ? context.motion.duration.instant
        : context.motion.duration.base;
    Widget dimmed(Widget child) => AnimatedOpacity(
      opacity: on ? 1 : tokens.opacity.disabled,
      duration: duration,
      child: child,
    );
    return SettingsPage(
      title: l10n.reminderTitle,
      lead: l10n.reminderBody,
      onBack: onBack,
      gap: tokens.space.s6,
      children: [
        SettingsSection(
          children: [
            SettingsTile.toggle(
              title: l10n.reminderToggle,
              switchValue: on,
              onChanged: onEnabled,
            ),
            dimmed(
              Padding(
                padding: EdgeInsetsDirectional.all(tokens.space.s5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: tokens.space.s3,
                  children: [
                    ExcludeSemantics(
                      child: Text(
                        l10n.reminderAt,
                        style: tokens.typography.label.copyWith(
                          color: tokens.color.text.secondary,
                        ),
                      ),
                    ),
                    _TimeButton(
                      time: timeText,
                      changeLabel: l10n.reminderChange,
                      semanticsLabel: l10n.reminderTimeSemantics(timeText),
                      onTap: on ? () => onChangeTime(time) : null,
                    ),
                  ],
                ),
              ),
            ),
          ],
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
        dimmed(
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: tokens.space.s3,
            children: [
              SettingsPageCaption(l10n.reminderPreviewCaption),
              NotificationPreview(
                appName: l10n.appTitle,
                time: timeText,
                title: l10n.appTitle,
                body: l10n.reminderBody2,
              ),
              Text(
                l10n.reminderPreviewNote,
                style: tokens.typography.caption.copyWith(
                  color: tokens.color.text.secondary,
                ),
              ),
            ],
          ),
        ),
        TaroInlineNotice(
          kind: TaroNoticeKind.info,
          title: l10n.reminderPermissionNote,
        ),
      ],
    );
  }
}

/// The big time button of S22 (`TimeField`): the time in `type.headline`
/// on `color.bg.sunken` with "Change" at the end; one button node.
class _TimeButton extends StatelessWidget {
  const _TimeButton({
    required this.time,
    required this.changeLabel,
    required this.semanticsLabel,
    required this.onTap,
  });

  final String time;
  final String changeLabel;
  final String semanticsLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final c = tokens.color;
    final radius = BorderRadius.circular(tokens.radius.md);
    return Semantics(
      button: true,
      enabled: onTap != null,
      label: semanticsLabel,
      excludeSemantics: true,
      onTap: onTap,
      child: Material(
        color: c.bg.sunken,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(color: c.border.strong),
        ),
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: tokens.size.touchTarget.min + tokens.space.s4,
            ),
            child: Padding(
              padding: EdgeInsetsDirectional.symmetric(
                horizontal: tokens.space.s5,
                vertical: tokens.space.s3,
              ),
              child: Row(
                spacing: tokens.space.s4,
                children: [
                  Expanded(
                    child: Text(
                      time,
                      style: tokens.typography.headline.copyWith(
                        color: c.text.primary,
                      ),
                    ),
                  ),
                  Text(
                    changeLabel,
                    style: tokens.typography.label.copyWith(
                      color: c.accent.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
