import 'package:taro/l10n/generated/taro_localizations.dart';

/// Compact countdown text over ARB strings ("5 h 12 min", "4 min", "less
/// than a minute"; 02 §11: no `timeago` dependency). The caller computes
/// [remaining] from server time (`free.resetsAt`, `cooldownEndsAt`), never
/// from a fake timer (04 §11). Negative durations read as "less than a
/// minute".
String formatCountdown(TaroLocalizations l10n, Duration remaining) {
  final minutes = remaining.inMinutes;
  if (minutes < 1) return l10n.durationLessThanMinute;
  final hours = remaining.inHours;
  if (hours < 1) return l10n.durationMinutes(minutes);
  return l10n.durationHoursMinutes(hours, minutes - hours * 60);
}
