import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taro_core/src/logic/local_dates.dart';
import 'package:taro_core/src/model/daily_card.dart';
import 'package:taro_core/src/model/deck_card.dart';
import 'package:taro_core/src/model/reading.dart';
import 'package:taro_core/src/result/ids.dart';

part 'patterns.freezed.dart';

/// How often a card was drawn in a window.
@freezed
abstract class CardCount with _$CardCount {
  /// Creates a count.
  const factory CardCount({
    /// The card.
    required CardId cardId,

    /// Times drawn.
    required int count,
  }) = _CardCount;
}

/// The journal patterns over one window of local days (01 §7.8).
@freezed
abstract class PatternWindow with _$PatternWindow {
  /// Creates a window.
  const factory PatternWindow({
    /// Length of the window in local days, today included.
    required int days,

    /// Journal entries (readings + daily cards) in the window.
    required int entries,

    /// Cards drawn in the window.
    required int cards,

    /// The most-drawn cards, count descending, ties in canonical card
    /// order; only cards drawn at least twice, at most
    /// [JournalPatterns.topCards].
    required List<CardCount> mostDrawn,

    /// Cards per suit (every suit present, zero when none).
    required Map<Suit, int> suits,

    /// Major arcana cards.
    required int major,

    /// Reversed cards.
    required int reversed,
  }) = _PatternWindow;

  const PatternWindow._();

  /// Minor arcana cards.
  int get minor => cards - major;

  /// Share of major arcana cards, 0..1 (0 when no cards).
  double get majorRatio => cards == 0 ? 0 : major / cards;

  /// Share of reversed cards, 0..1 (0 when no cards).
  double get reversedRatio => cards == 0 ? 0 : reversed / cards;
}

/// The Patterns card at the top of the Journal (01 §7.8): computed locally,
/// patterns in *your draws*, not predictions.
@freezed
abstract class JournalPatterns with _$JournalPatterns {
  /// Creates patterns.
  const factory JournalPatterns({
    /// All journal entries (readings + daily cards).
    required int totalEntries,

    /// The last 30 local days.
    required PatternWindow last30,

    /// The last 90 local days.
    required PatternWindow last90,
  }) = _JournalPatterns;

  const JournalPatterns._();

  /// Computes the patterns of every reading and daily card as of the local
  /// date [today] (`YYYY-MM-DD`). Every drawn card counts, whatever the
  /// reading status (they are the user's draws).
  factory JournalPatterns.compute({
    required Iterable<Reading> readings,
    required Iterable<DailyCard> dailyCards,
    required String today,
  }) {
    final entries = <_Entry>[
      for (final r in readings)
        _Entry(
          LocalDates.toDay(r.localDate),
          [for (final c in r.cards) (c.cardId, c.reversed)],
        ),
      for (final d in dailyCards)
        _Entry(LocalDates.toDay(d.localDate), [(d.cardId, d.reversed)]),
    ];
    final day = LocalDates.toDay(today);
    return JournalPatterns(
      totalEntries: entries.length,
      last30: _window(entries, day, 30),
      last90: _window(entries, day, 90),
    );
  }

  /// Entries needed before the card is shown.
  static const int minEntries = 5;

  /// Size of [PatternWindow.mostDrawn].
  static const int topCards = 3;

  /// Whether the card is shown (hidden below [minEntries] entries).
  bool get visible => totalEntries >= minEntries;

  static PatternWindow _window(List<_Entry> all, int today, int days) {
    final inWindow = [
      for (final e in all)
        if (e.day <= today && e.day > today - days) e,
    ];
    final counts = <CardId, int>{};
    final suits = {for (final s in Suit.values) s: 0};
    var cards = 0;
    var major = 0;
    var reversed = 0;
    for (final e in inWindow) {
      for (final (id, isReversed) in e.cards) {
        cards++;
        counts[id] = (counts[id] ?? 0) + 1;
        if (isReversed) reversed++;
        final suit = suitOf(id);
        if (suit == null) {
          major++;
        } else {
          suits[suit] = suits[suit]! + 1;
        }
      }
    }
    final order = {for (var i = 0; i < kCardIds.length; i++) kCardIds[i]: i};
    final ranked =
        [
          for (final e in counts.entries)
            if (e.value >= 2) CardCount(cardId: e.key, count: e.value),
        ]..sort((a, b) {
          final byCount = b.count.compareTo(a.count);
          return byCount != 0
              ? byCount
              : order[a.cardId]!.compareTo(order[b.cardId]!);
        });
    return PatternWindow(
      days: days,
      entries: inWindow.length,
      cards: cards,
      mostDrawn: List.unmodifiable(ranked.take(topCards)),
      suits: Map.unmodifiable(suits),
      major: major,
      reversed: reversed,
    );
  }

  /// The suit of a card ID; `null` for major arcana.
  static Suit? suitOf(CardId id) {
    final prefix = id.value.substring(0, id.value.indexOf('_'));
    for (final s in Suit.values) {
      if (s.name == prefix) return s;
    }
    return null;
  }

  /// `streak_days` for `daily_card_revealed` (01 §15, Q10: analytics only,
  /// never shown): consecutive local days ending on [today] that have an
  /// entry in [localDates]; 0 when [today] has none.
  static int streakDays(Iterable<String> localDates, String today) {
    final days = {for (final d in localDates) LocalDates.toDay(d)};
    var day = LocalDates.toDay(today);
    var streak = 0;
    while (days.contains(day)) {
      streak++;
      day--;
    }
    return streak;
  }
}

final class _Entry {
  const _Entry(this.day, this.cards);

  final int day;
  final List<(CardId, bool)> cards;
}
