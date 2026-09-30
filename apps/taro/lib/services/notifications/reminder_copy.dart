import 'package:flutter/foundation.dart';

/// The number of localized reminder texts the scheduler rotates through
/// (01 §7.7).
const int kReminderVariantCount = 6;

/// One localized reminder text. It never reveals a card and never uses
/// urgency (01 §7.7).
@immutable
final class ReminderMessage {
  /// A reminder text.
  const ReminderMessage({required this.title, required this.body});

  /// The notification title.
  final String title;

  /// The notification body.
  final String body;

  @override
  bool operator ==(Object other) =>
      other is ReminderMessage && other.title == title && other.body == body;

  @override
  int get hashCode => Object.hash(title, body);
}

/// The localized copy of the daily reminder for one locale, taken from the
/// ARB files by the composition root (`TaroLocalizations`).
final class ReminderCopy {
  /// The copy: the Android channel name and description (shown in the
  /// system settings) and the [kReminderVariantCount] rotating texts.
  const ReminderCopy({
    required this.channelName,
    required this.channelDescription,
    required this.variants,
  });

  /// The Android notification channel name.
  final String channelName;

  /// The Android notification channel description.
  final String channelDescription;

  /// The rotating reminder texts, normally [kReminderVariantCount].
  final List<ReminderMessage> variants;
}

/// Resolves the reminder copy for an app locale (`en`, `uk`, …).
typedef ReminderCopyResolver = ReminderCopy Function(String locale);
