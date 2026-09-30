import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taro/di/providers.dart';
import 'package:taro_core/taro_core.dart';

part 'journal_list_controller.freezed.dart';

/// The type chips of S14 (01 §7.8: All / Readings / Daily cards /
/// Favourites).
enum JournalTypeFilter {
  /// Every entry.
  all,

  /// AI and classic readings only.
  readings,

  /// Daily cards only.
  dailyCards,

  /// Favourite entries of both kinds.
  favourites,
}

/// The active S14 filters (01 §7.8).
@freezed
abstract class JournalFilters with _$JournalFilters {
  /// Creates filters (none by default).
  const factory JournalFilters({
    @Default(JournalTypeFilter.all) JournalTypeFilter type,

    /// Only readings of this spread.
    SpreadId? spreadId,

    /// Only entries containing this card (the S17 "drawn N times" link).
    CardId? cardId,
  }) = _JournalFilters;

  const JournalFilters._();

  /// Whether any filter is set.
  bool get isActive =>
      type != JournalTypeFilter.all || spreadId != null || cardId != null;

  /// Whether [item] passes the filters.
  bool accepts(JournalItem item) {
    switch (item) {
      case JournalReadingItem(:final reading):
        if (type == JournalTypeFilter.dailyCards) return false;
        if (type == JournalTypeFilter.favourites && !reading.favourite) {
          return false;
        }
        if (spreadId != null && reading.spreadId != spreadId) return false;
        return cardId == null || reading.cards.any((c) => c.cardId == cardId);
      case JournalDailyCardItem(:final card):
        if (type == JournalTypeFilter.readings || spreadId != null) {
          return false;
        }
        if (type == JournalTypeFilter.favourites && !card.favourite) {
          return false;
        }
        return cardId == null || card.cardId == cardId;
    }
  }
}

/// One month group of S14, newest first (`yearMonth` = `YYYY-MM`).
@freezed
abstract class JournalMonth with _$JournalMonth {
  /// Creates a group.
  const factory JournalMonth({
    required String yearMonth,
    required List<JournalItem> items,
  }) = _JournalMonth;
}

/// S14 Journal list (01 §7.8, §8.3).
@freezed
sealed class JournalListState with _$JournalListState {
  /// Loading the journal.
  const factory JournalListState.loading() = JournalListLoading;

  /// No entries at all: "Your readings will live here" + Start a reading.
  const factory JournalListState.empty() = JournalListEmpty;

  /// Entries grouped by month, newest first.
  const factory JournalListState.content({
    required List<JournalMonth> months,
    required JournalFilters filters,

    /// The search text (empty when not searching).
    @Default('') String query,

    /// The Patterns card, when there are ≥ 5 entries (01 §7.8).
    JournalPatterns? patterns,

    /// The reading just deleted from the list (the 5 s Undo snackbar).
    ReadingId? undoable,
  }) = JournalListContent;

  /// Filters match nothing: "Nothing matches this filter" + Clear filter.
  const factory JournalListState.filteredEmpty({
    required JournalFilters filters,
  }) = JournalListFilteredEmpty;

  /// The search matches nothing ("No entries match “…”").
  const factory JournalListState.searchEmpty({required String query}) =
      JournalListSearchEmpty;

  /// The journal database could not be read (`TaroErrorView(storage)`).
  const factory JournalListState.storageError() = JournalListStorageError;
}

/// Drives S14: the journal stream, local filters, local full-text search
/// (FTS5 or LIKE behind `JournalRepository.search`, RC91) and the Patterns
/// card (computed locally, not a prediction).
final class JournalListController extends Notifier<JournalListState> {
  List<JournalItem>? _all;
  List<JournalItem>? _hits;
  JournalFilters _filters = const JournalFilters();
  String _query = '';
  ReadingId? _undoable;
  Timer? _undoTimer;
  bool _storageError = false;
  bool _patternsLogged = false;
  int _searchRun = 0;
  late AnalyticsService _analytics;

  @override
  JournalListState build() {
    final journal = ref.watch(journalRepositoryProvider);
    _analytics = ref.watch(analyticsServiceProvider);
    final subscription = journal.watchAll().listen(
      (items) {
        _storageError = false;
        _all = items;
        if (_query.isNotEmpty) unawaited(_runSearch());
        _update();
      },
      onError: (Object _) {
        _storageError = true;
        _update();
      },
    );
    ref.onDispose(() {
      unawaited(subscription.cancel());
      _finishUndo(undone: false);
    });
    return const JournalListState.loading();
  }

  /// Sets the type chip.
  Future<void> setType(JournalTypeFilter type) async {
    if (_filters.type == type) return;
    _filters = _filters.copyWith(type: type);
    _update();
    if (type == JournalTypeFilter.all) return;
    await _logFilter(
      type == JournalTypeFilter.favourites
          ? JournalFilter.favourites
          : JournalFilter.type,
    );
  }

  /// Filters by spread (`null` clears it).
  Future<void> setSpread(SpreadId? spreadId) async {
    _filters = _filters.copyWith(spreadId: spreadId);
    _update();
    if (spreadId != null) await _logFilter(JournalFilter.spread);
  }

  /// Filters by card (`null` clears it).
  Future<void> setCard(CardId? cardId) async {
    _filters = _filters.copyWith(cardId: cardId);
    _update();
    if (cardId != null) await _logFilter(JournalFilter.card);
  }

  /// "Clear filter".
  void clearFilters() {
    _filters = const JournalFilters();
    _update();
  }

  /// Searches questions and notes; an empty [text] ends the search.
  Future<void> search(String text) async {
    _query = text.trim();
    if (_query.isEmpty) {
      _hits = null;
      _update();
      return;
    }
    await _runSearch();
    await _logFilter(JournalFilter.search);
  }

  /// The Patterns range toggle (`patterns_viewed`).
  Future<void> viewPatterns(PatternsRange range) =>
      _analytics.log(PatternsViewedEvent(range: range));

  /// Deletes a reading from the list; [undo] restores it for 5 s (01 §7.8).
  Future<void> delete(ReadingId id) async {
    final deleted = await ref.read(readingRepositoryProvider).delete(id);
    if (deleted case Err()) {
      _storageError = true;
      _update();
      return;
    }
    _finishUndo(undone: false);
    _undoable = id;
    _undoTimer = Timer(ReadingRepository.undoWindow, () {
      _finishUndo(undone: false);
      _update();
    });
    _update();
  }

  /// Undo of the last [delete] within the window.
  Future<void> undo() async {
    final id = _undoable;
    if (id == null) return;
    final restored = await ref.read(readingRepositoryProvider).undoDelete(id);
    _finishUndo(undone: restored.valueOrNull ?? false);
    _update();
  }

  void _finishUndo({required bool undone}) {
    _undoTimer?.cancel();
    _undoTimer = null;
    if (_undoable == null) return;
    _undoable = null;
    unawaited(
      _analytics.log(
        JournalEntryDeletedEvent(
          entryType: JournalEntryType.reading,
          undone: undone,
        ),
      ),
    );
  }

  Future<void> _runSearch() async {
    final run = ++_searchRun;
    final found = await ref.read(journalRepositoryProvider).search(_query);
    if (!ref.mounted || run != _searchRun) return;
    switch (found) {
      case Ok(:final value):
        _hits = value;
      case Err():
        _storageError = true;
    }
    _update();
  }

  Future<void> _logFilter(JournalFilter filter) =>
      _analytics.log(JournalFilterUsedEvent(filter: filter));

  void _update() {
    if (!ref.mounted) return;
    state = _compute();
  }

  JournalListState _compute() {
    if (_storageError) return const JournalListState.storageError();
    final all = _all;
    if (all == null) return const JournalListState.loading();
    if (all.isEmpty) return const JournalListState.empty();
    final searching = _query.isNotEmpty;
    final source = searching ? (_hits ?? const <JournalItem>[]) : all;
    final visible = [
      for (final item in source)
        if (_filters.accepts(item)) item,
    ];
    if (visible.isEmpty) {
      return searching
          ? JournalListState.searchEmpty(query: _query)
          : JournalListState.filteredEmpty(filters: _filters);
    }
    return JournalListState.content(
      months: _byMonth(visible),
      filters: _filters,
      query: _query,
      patterns: _patterns(all),
      undoable: _undoable,
    );
  }

  JournalPatterns? _patterns(List<JournalItem> all) {
    final patterns = JournalPatterns.compute(
      readings: [
        for (final item in all)
          if (item case JournalReadingItem(:final reading)) reading,
      ],
      dailyCards: [
        for (final item in all)
          if (item case JournalDailyCardItem(:final card)) card,
      ],
      today: LocalDates.format(ref.read(clockProvider).nowLocal()),
    );
    if (!patterns.visible) return null;
    if (!_patternsLogged) {
      _patternsLogged = true;
      unawaited(viewPatterns(PatternsRange.d30));
    }
    return patterns;
  }

  static List<JournalMonth> _byMonth(List<JournalItem> items) {
    final months = <String, List<JournalItem>>{};
    for (final item in items) {
      final localDate = switch (item) {
        JournalReadingItem(:final reading) => reading.localDate,
        JournalDailyCardItem(:final card) => card.localDate,
      };
      months.putIfAbsent(localDate.substring(0, 7), () => []).add(item);
    }
    final keys = months.keys.toList()..sort((a, b) => b.compareTo(a));
    return [
      for (final key in keys)
        JournalMonth(yearMonth: key, items: List.unmodifiable(months[key]!)),
    ];
  }
}

/// S14 controller (auto-disposed with the tab's screen).
final NotifierProvider<JournalListController, JournalListState>
journalListControllerProvider = NotifierProvider.autoDispose(
  JournalListController.new,
);
