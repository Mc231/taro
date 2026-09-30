import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show NotifierProviderFamily;
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taro/di/providers.dart';
import 'package:taro_core/taro_core.dart';

part 'journal_entry_controller.freezed.dart';

/// The longest note (01 §7.8: plain text, up to 5,000 chars).
const int kJournalNoteMaxChars = 5000;

/// The pause after the last keystroke before a note is autosaved.
const Duration kJournalNoteAutosaveDelay = Duration(milliseconds: 800);

/// Which journal entry S15 shows.
@freezed
sealed class JournalEntryKey with _$JournalEntryKey {
  /// A reading (AI or classic) by ID.
  const factory JournalEntryKey.reading(ReadingId id) = JournalReadingKey;

  /// A daily card by its local date.
  const factory JournalEntryKey.dailyCard(String localDate) =
      JournalDailyCardKey;
}

/// The note editor's autosave status ("Saved on this device").
enum NoteStatus {
  /// Matches the stored note.
  saved,

  /// Edited, waiting for the autosave.
  editing,

  /// The last save failed; the draft is kept and retried on the next edit.
  failed,
}

/// The entry and its note draft.
@freezed
abstract class JournalEntryView with _$JournalEntryView {
  /// Creates a view.
  const factory JournalEntryView({
    required JournalItem item,

    /// The note text in the editor (≤ [kJournalNoteMaxChars]).
    required String note,
    required NoteStatus noteStatus,
  }) = _JournalEntryView;

  const JournalEntryView._();

  /// Whether the entry can be deleted (readings; daily cards stay).
  bool get canDelete => item is JournalReadingItem;

  /// Whether the entry is a favourite.
  bool get favourite => switch (item) {
    JournalReadingItem(:final reading) => reading.favourite,
    JournalDailyCardItem(:final card) => card.favourite,
  };
}

/// S15 Journal entry detail + note editor (01 §7.8, §8.3).
@freezed
sealed class JournalEntryState with _$JournalEntryState {
  /// Loading the entry.
  const factory JournalEntryState.loading() = JournalEntryLoading;

  /// A complete, refused, classic reading or a daily card.
  const factory JournalEntryState.content(JournalEntryView view) =
      JournalEntryContent;

  /// A pending reading: cards face-down + "Finish reading" (→ S08
  /// `awaitingReading`, PR6).
  const factory JournalEntryState.pending(JournalEntryView view) =
      JournalEntryPending;

  /// A failed reading: "We couldn't create this reading. You weren't
  /// charged." + Try again with the same cards.
  const factory JournalEntryState.failed(
    JournalEntryView view, {
    required bool refunded,
  }) = JournalEntryFailed;

  /// Deleted: pop to S14 with a 5 s Undo until [undoUntil].
  const factory JournalEntryState.deleted({required DateTime undoUntil}) =
      JournalEntryDeleted;

  /// The entry does not exist (deleted elsewhere, a stale link).
  const factory JournalEntryState.notFound() = JournalEntryNotFound;

  /// The journal database could not be read or written.
  const factory JournalEntryState.storageError() = JournalEntryStorageError;
}

/// Drives S15 for one [entry]: follows the stored entry, autosaves the note,
/// toggles favourite, deletes with a 5 s undo (01 §7.8).
final class JournalEntryController extends Notifier<JournalEntryState> {
  /// A controller for [entry].
  JournalEntryController(this.entry);

  /// The entry shown.
  final JournalEntryKey entry;

  JournalItem? _item;
  String? _draft;
  NoteStatus _noteStatus = NoteStatus.saved;
  Timer? _autosave;
  Timer? _undoTimer;
  DateTime? _undoUntil;
  bool _storageError = false;
  bool _missing = false;
  late AnalyticsService _analytics;
  late ReadingRepository _readings;
  late DailyCardRepository _dailyCards;
  late Clock _clock;

  JournalEntryType get _type => switch (entry) {
    JournalReadingKey() => JournalEntryType.reading,
    JournalDailyCardKey() => JournalEntryType.daily,
  };

  @override
  JournalEntryState build() {
    _analytics = ref.watch(analyticsServiceProvider);
    _readings = ref.watch(readingRepositoryProvider);
    _dailyCards = ref.watch(dailyCardRepositoryProvider);
    _clock = ref.watch(clockProvider);
    final source = switch (entry) {
      JournalReadingKey(:final id) =>
        _readings
            .watch(id)
            .map((r) => r == null ? null : JournalItem.reading(r)),
      JournalDailyCardKey(:final localDate) =>
        ref
            .watch(journalRepositoryProvider)
            .watchAll()
            .map(
              (items) => items
                  .whereType<JournalDailyCardItem>()
                  .where((i) => i.card.localDate == localDate)
                  .firstOrNull,
            ),
    };
    final subscription = source.listen(
      _onItem,
      onError: (Object _) {
        _storageError = true;
        _update();
      },
    );
    ref.onDispose(() {
      unawaited(subscription.cancel());
      _autosave?.cancel();
      _undoTimer?.cancel();
      // Leaving the screen saves a pending edit (autosave, never lost).
      if (_noteStatus == NoteStatus.editing) unawaited(_saveNote());
      if (_undoUntil != null) unawaited(_logDeleted(undone: false));
    });
    return const JournalEntryState.loading();
  }

  /// The note editor changed: clamps to [kJournalNoteMaxChars] and
  /// schedules the autosave.
  void editNote(String text) {
    final clamped = text.length > kJournalNoteMaxChars
        ? text.substring(0, kJournalNoteMaxChars)
        : text;
    if (clamped == _draft) return;
    _draft = clamped;
    _noteStatus = NoteStatus.editing;
    _autosave?.cancel();
    _autosave = Timer(kJournalNoteAutosaveDelay, () => unawaited(_saveNote()));
    _update();
  }

  /// Saves a pending note edit now (the editor lost focus).
  Future<void> flushNote() async {
    _autosave?.cancel();
    if (_noteStatus != NoteStatus.saved) await _saveNote();
  }

  /// Toggles the favourite flag.
  Future<void> toggleFavourite() async {
    final item = _item;
    if (item == null) return;
    final on = !switch (item) {
      JournalReadingItem(:final reading) => reading.favourite,
      JournalDailyCardItem(:final card) => card.favourite,
    };
    final saved = switch (entry) {
      JournalReadingKey(:final id) => await _readings.setFavourite(
        id,
        favourite: on,
      ),
      JournalDailyCardKey(:final localDate) => await _dailyCards.setFavourite(
        localDate,
        favourite: on,
      ),
    };
    if (saved case Err()) {
      _storageError = true;
      _update();
      return;
    }
    await _analytics.log(
      JournalFavouriteToggledEvent(entryType: _type, on: on),
    );
  }

  /// Deletes a reading ("Delete this entry?" confirmed); Undo for 5 s.
  Future<void> delete() async {
    final key = entry;
    if (key is! JournalReadingKey) return;
    await flushNote();
    final deleted = await _readings.delete(key.id);
    if (deleted case Err()) {
      _storageError = true;
      _update();
      return;
    }
    final until = _clock.now().add(ReadingRepository.undoWindow);
    _undoUntil = until;
    _undoTimer = Timer(ReadingRepository.undoWindow, () {
      if (_undoUntil == null) return;
      _undoUntil = null;
      unawaited(_logDeleted(undone: false));
      _update();
    });
    _update();
  }

  /// Undo within the window: the reading comes back.
  Future<void> undo() async {
    final key = entry;
    if (key is! JournalReadingKey || _undoUntil == null) return;
    _undoTimer?.cancel();
    _undoUntil = null;
    final restored = await _readings.undoDelete(key.id);
    final undone = restored.valueOrNull ?? false;
    await _logDeleted(undone: undone);
    if (!undone) _missing = true;
    _update();
  }

  Future<void> _logDeleted({required bool undone}) => _analytics.log(
    JournalEntryDeletedEvent(entryType: _type, undone: undone),
  );

  void _onItem(JournalItem? item) {
    _storageError = false;
    _item = item;
    _missing = item == null;
    if (item != null && _noteStatus == NoteStatus.saved) {
      _draft = _storedNote(item);
    }
    _update();
  }

  static String _storedNote(JournalItem item) => switch (item) {
    JournalReadingItem(:final reading) => reading.note ?? '',
    JournalDailyCardItem(:final card) => card.note ?? '',
  };

  Future<void> _saveNote() async {
    final text = _draft ?? '';
    final note = text.trim().isEmpty ? null : text;
    final saved = switch (entry) {
      JournalReadingKey(:final id) => await _readings.setNote(id, note),
      JournalDailyCardKey(:final localDate) => await _dailyCards.setNote(
        localDate,
        note,
      ),
    };
    switch (saved) {
      case Ok():
        if (_draft == text) _noteStatus = NoteStatus.saved;
        await _analytics.log(
          JournalNoteSavedEvent(
            entryType: _type,
            noteLenBucket: NoteLengthBucket.fromLength(note?.length ?? 0),
          ),
        );
      case Err():
        _noteStatus = NoteStatus.failed;
    }
    _update();
  }

  void _update() {
    if (!ref.mounted) return;
    state = _compute();
  }

  JournalEntryState _compute() {
    final undoUntil = _undoUntil;
    if (undoUntil != null) {
      return JournalEntryState.deleted(undoUntil: undoUntil);
    }
    if (_storageError) return const JournalEntryState.storageError();
    final item = _item;
    if (item == null) {
      return _missing
          ? const JournalEntryState.notFound()
          : const JournalEntryState.loading();
    }
    final view = JournalEntryView(
      item: item,
      note: _draft ?? _storedNote(item),
      noteStatus: _noteStatus,
    );
    return switch (item) {
      JournalReadingItem(:final reading) => switch (reading.status) {
        ReadingStatusPending() => JournalEntryState.pending(view),
        ReadingStatusFailed(:final refunded) => JournalEntryState.failed(
          view,
          refunded: refunded,
        ),
        ReadingStatusComplete() ||
        ReadingStatusRefused() ||
        ReadingStatusClassic() => JournalEntryState.content(view),
      },
      JournalDailyCardItem() => JournalEntryState.content(view),
    };
  }
}

/// S15 controllers by entry (auto-disposed with the screen).
final NotifierProviderFamily<
  JournalEntryController,
  JournalEntryState,
  JournalEntryKey
>
journalEntryControllerProvider = NotifierProvider.autoDispose.family(
  JournalEntryController.new,
);
