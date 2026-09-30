import 'package:flutter/widgets.dart';
import 'package:taro/l10n/generated/taro_localizations.dart';
import 'package:taro/services/notifications/reminder_copy.dart';

/// The reminder copy for [locale] from the ARB files (01 §7.7), resolved
/// lazily per schedule; an unknown locale falls back to English.
ReminderCopy reminderCopyFor(String locale) {
  final supported = TaroLocalizations.supportedLocales.any(
    (l) => l.languageCode == locale,
  );
  final l10n = lookupTaroLocalizations(Locale(supported ? locale : 'en'));
  return ReminderCopy(
    channelName: l10n.reminderChannelName,
    channelDescription: l10n.reminderChannelDescription,
    variants: [
      for (final body in [
        l10n.reminderBody1,
        l10n.reminderBody2,
        l10n.reminderBody3,
        l10n.reminderBody4,
        l10n.reminderBody5,
        l10n.reminderBody6,
      ])
        ReminderMessage(title: l10n.appTitle, body: body),
    ],
  );
}
