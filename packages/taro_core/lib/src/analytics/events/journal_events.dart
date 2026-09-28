part of '../taro_analytics_event.dart';

/// Journal events (01 §15 `JournalEvent`). Never the note text.
sealed class JournalEvent extends TaroAnalyticsEvent {
  const JournalEvent._() : super._();
}

/// `journal_note_saved`: a note was autosaved.
final class JournalNoteSavedEvent extends JournalEvent {
  /// Creates the event.
  const JournalNoteSavedEvent({
    required this.entryType,
    required this.noteLenBucket,
  }) : super._();

  /// The entry type.
  final JournalEntryType entryType;

  /// The note length bucket.
  final NoteLengthBucket noteLenBucket;

  @override
  String get eventName => 'journal_note_saved';

  @override
  Map<String, Object> get parameters => {
    'entry_type': entryType.wire,
    'note_len_bucket': noteLenBucket.wire,
  };
}

/// `journal_entry_deleted`: an entry was deleted (or the delete undone).
final class JournalEntryDeletedEvent extends JournalEvent {
  /// Creates the event.
  const JournalEntryDeletedEvent({
    required this.entryType,
    required this.undone,
  }) : super._();

  /// The entry type.
  final JournalEntryType entryType;

  /// Whether Undo was tapped.
  final bool undone;

  @override
  String get eventName => 'journal_entry_deleted';

  @override
  Map<String, Object> get parameters => {
    'entry_type': entryType.wire,
    'undone': undone,
  };
}

/// `journal_favourite_toggled`: the favourite star changed.
final class JournalFavouriteToggledEvent extends JournalEvent {
  /// Creates the event.
  const JournalFavouriteToggledEvent({
    required this.entryType,
    required this.on,
  }) : super._();

  /// The entry type.
  final JournalEntryType entryType;

  /// The new state.
  final bool on;

  @override
  String get eventName => 'journal_favourite_toggled';

  @override
  Map<String, Object> get parameters => {
    'entry_type': entryType.wire,
    'on': on,
  };
}

/// `journal_filter_used`: a journal filter was applied.
final class JournalFilterUsedEvent extends JournalEvent {
  /// Creates the event.
  const JournalFilterUsedEvent({required this.filter}) : super._();

  /// The filter kind (never the search text).
  final JournalFilter filter;

  @override
  String get eventName => 'journal_filter_used';

  @override
  Map<String, Object> get parameters => {'filter': filter.wire};
}

/// `patterns_viewed`: journal insights were opened (01 §7.8).
final class PatternsViewedEvent extends JournalEvent {
  /// Creates the event.
  const PatternsViewedEvent({required this.range}) : super._();

  /// The range shown.
  final PatternsRange range;

  @override
  String get eventName => 'patterns_viewed';

  @override
  Map<String, Object> get parameters => {'range': range.wire};
}
