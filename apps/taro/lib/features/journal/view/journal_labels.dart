import 'package:intl/intl.dart';
import 'package:taro/common/spread_text.dart';
import 'package:taro/features/journal/controller/journal_entry_controller.dart';
import 'package:taro/l10n/generated/taro_localizations.dart';
import 'package:taro/routing/routes.dart';
import 'package:taro_core/taro_core.dart';
import 'package:taro_ui/taro_ui.dart';

/// Labels of journal entries shared by S14 and S15.
abstract final class JournalLabels {
  /// The route `:id` of [item]: the reading ID, or the daily card's local
  /// date (`YYYY-MM-DD`).
  static String routeId(JournalItem item) => switch (item) {
    JournalReadingItem(:final reading) => reading.id.value,
    JournalDailyCardItem(:final card) => card.localDate,
  };

  /// The S15 entry of a route [id]: a local date names a daily card, any
  /// other value a reading.
  static JournalEntryKey keyOf(String id) => _localDate.hasMatch(id)
      ? JournalEntryKey.dailyCard(id)
      : JournalEntryKey.reading(ReadingId(id));

  /// The entry title: the question, else the spread name; "Daily card".
  static String title(TaroLocalizations l10n, JournalItem item) =>
      switch (item) {
        JournalReadingItem(:final reading) =>
          (reading.question?.trim().isNotEmpty ?? false)
              ? reading.question!.trim()
              : SpreadText.name(l10n, reading.spreadId),
        JournalDailyCardItem() => l10n.commonDailyCard,
      };

  /// "12 Sep 2026 · Three cards" (the date alone for a daily card).
  static String meta(TaroLocalizations l10n, JournalItem item) =>
      switch (item) {
        JournalReadingItem(:final reading) => l10n.commonItemSeparator(
          date(l10n, reading.localDate),
          SpreadText.name(l10n, reading.spreadId),
        ),
        JournalDailyCardItem(:final card) => date(l10n, card.localDate),
      };

  /// The tile status of [item].
  static JournalEntryTileStatus status(JournalItem item) => switch (item) {
    JournalDailyCardItem() => JournalEntryTileStatus.dailyCard,
    JournalReadingItem(:final reading) => switch (reading.status) {
      ReadingStatusPending() => JournalEntryTileStatus.pending,
      ReadingStatusFailed() => JournalEntryTileStatus.failed,
      ReadingStatusClassic() => JournalEntryTileStatus.classic,
      ReadingStatusComplete() ||
      ReadingStatusRefused() => JournalEntryTileStatus.ai,
    },
  };

  /// The visible status label of [status].
  static String statusLabel(
    TaroLocalizations l10n,
    JournalEntryTileStatus status,
  ) => switch (status) {
    JournalEntryTileStatus.ai => l10n.aiLabel,
    JournalEntryTileStatus.classic => l10n.classicLabel,
    JournalEntryTileStatus.dailyCard => l10n.commonDailyCard,
    JournalEntryTileStatus.pending => l10n.journalPending,
    JournalEntryTileStatus.failed => l10n.journalFailedLabel,
  };

  /// A local date (`YYYY-MM-DD`) in the app locale ("12 Sep 2026").
  static String date(TaroLocalizations l10n, String localDate) =>
      DateFormat.yMMMd(l10n.localeName).format(DateTime.parse(localDate));

  /// A month group header (`YYYY-MM` → "September 2026").
  static String month(TaroLocalizations l10n, String yearMonth) =>
      l10n.journalMonthHeader(
        DateFormat.yMMMM(l10n.localeName).format(
          DateTime.parse('$yearMonth-01'),
        ),
      );

  /// The S15 location of [item].
  static String location(JournalItem item) =>
      RoutePaths.journalEntry(routeId(item));

  /// Where "Finish reading" / "Try again" goes: S08 resuming the stored
  /// reading [id] with the same cards (RC49; `?resume=` is read by S08).
  static String finishLocation(ReadingId id) => Uri(
    path: RoutePaths.readingDraw,
    queryParameters: {'resume': id.value},
  ).toString();

  static final RegExp _localDate = RegExp(r'^\d{4}-\d{2}-\d{2}$');
}
