import 'package:taro_core/taro_core.dart';

import 'builders/builders.dart';
import 'fake_behaviour.dart';
import 'fake_clock.dart';
import 'random_sources.dart';

/// The in-memory `taro_journal.db`: readings, daily cards and settings,
/// shared by [FakeJournalRepository], `FakeReadingRepository`,
/// [FakeDailyCardRepository] and [FakeSettingsRepository] so that, as in
/// the app, one sees what another wrote.
final class InMemoryJournal {
  /// Readings by ID, in insertion order.
  final Map<ReadingId, Reading> readings = {};

  /// Daily cards by local date, in insertion order.
  final Map<String, DailyCard> dailyCards = {};

  /// The user settings.
  UserSettings settings = const UserSettings();

  final ChangeSignal _changes = ChangeSignal();

  /// Fires after every change.
  Stream<void> get changes => _changes.stream;

  /// Stores [reading] (no call recorded).
  void putReading(Reading reading) {
    readings[reading.id] = reading;
    _changes.notify();
  }

  /// Stores [card] (no call recorded).
  void putDailyCard(DailyCard card) {
    dailyCards[card.localDate] = card;
    _changes.notify();
  }

  /// Replaces the settings (no call recorded).
  void putSettings(UserSettings settings) {
    this.settings = settings;
    _changes.notify();
  }

  /// Signals a change made through the maps directly.
  void notify() => _changes.notify();
}

/// A [JournalRepository] over an [InMemoryJournal]. Search matches the
/// question, the note and the card IDs (the fake has no card names).
final class FakeJournalRepository
    with FakeBehaviour
    implements JournalRepository {
  /// A repository over [journal] (a fresh one by default).
  FakeJournalRepository([InMemoryJournal? journal])
    : journal = journal ?? InMemoryJournal();

  @override
  String get fakeName => 'JournalRepository';

  /// The backing store.
  final InMemoryJournal journal;

  /// The data of every [replaceAll] call.
  final List<BackupData> replaced = [];

  List<JournalItem> _items(JournalQuery query) {
    final items = <JournalItem>[
      for (final r in journal.readings.values)
        if ((query.spreadId == null || r.spreadId == query.spreadId) &&
            (!query.favouritesOnly || r.favourite))
          JournalItem.reading(r),
      if (query.includeDailyCards && query.spreadId == null)
        for (final d in journal.dailyCards.values)
          if (!query.favouritesOnly || d.favourite) JournalItem.dailyCard(d),
    ];
    return _newestFirst(items);
  }

  static List<JournalItem> _newestFirst(List<JournalItem> items) {
    final indexed = [for (var i = 0; i < items.length; i++) (i, items[i])]
      ..sort((a, b) {
        final byTime = b.$2.createdAt.compareTo(a.$2.createdAt);
        return byTime != 0 ? byTime : a.$1.compareTo(b.$1);
      });
    return [for (final (_, item) in indexed) item];
  }

  @override
  Stream<List<JournalItem>> watchAll({
    JournalQuery query = const JournalQuery(),
  }) {
    record('watchAll');
    return watchValue(() => _items(query), journal.changes);
  }

  @override
  Future<Result<List<JournalItem>>> search(String text) async {
    record('search');
    final failure = takeFailure('search');
    if (failure != null) return Result.err(failure);
    final needle = text.trim().toLowerCase();
    if (needle.isEmpty) return const Result.ok([]);
    bool hit(String? s) => s != null && s.toLowerCase().contains(needle);
    return Result.ok(
      _newestFirst([
        for (final r in journal.readings.values)
          if (hit(r.question) ||
              hit(r.note) ||
              r.cards.any((c) => hit(c.cardId.value)))
            JournalItem.reading(r),
        for (final d in journal.dailyCards.values)
          if (hit(d.note) || hit(d.cardId.value)) JournalItem.dailyCard(d),
      ]),
    );
  }

  @override
  Future<Result<JournalSnapshot>> snapshot() async {
    record('snapshot');
    final failure = takeFailure('snapshot');
    if (failure != null) return Result.err(failure);
    return Result.ok(
      JournalSnapshot(
        readings: journal.readings.values.toList(),
        dailyCards: journal.dailyCards.values.toList(),
      ),
    );
  }

  @override
  Future<Result<void>> replaceAll(BackupData data) async {
    record('replaceAll');
    final failure = takeFailure('replaceAll');
    if (failure != null) return Result.err(failure);
    replaced.add(data);
    journal
      ..readings.clear()
      ..dailyCards.clear();
    for (final r in data.readings) {
      journal.readings[r.id] = r;
    }
    for (final d in data.dailyCards) {
      journal.dailyCards[d.localDate] = d;
    }
    journal
      ..settings = data.settings
      ..notify();
    return const Result.ok(null);
  }

  @override
  Future<Result<void>> deleteAll() async {
    record('deleteAll');
    final failure = takeFailure('deleteAll');
    if (failure != null) return Result.err(failure);
    journal
      ..readings.clear()
      ..dailyCards.clear()
      ..settings = const UserSettings()
      ..notify();
    return const Result.ok(null);
  }
}

/// A [SettingsRepository] over an [InMemoryJournal].
final class FakeSettingsRepository
    with FakeBehaviour
    implements SettingsRepository {
  /// A repository over [journal]; [initial] replaces its settings.
  FakeSettingsRepository({InMemoryJournal? journal, UserSettings? initial})
    : journal = journal ?? InMemoryJournal() {
    if (initial != null) this.journal.settings = initial;
  }

  @override
  String get fakeName => 'SettingsRepository';

  /// The backing store.
  final InMemoryJournal journal;

  @override
  UserSettings get current => journal.settings;

  @override
  Stream<UserSettings> watch() =>
      watchValue(() => journal.settings, journal.changes);

  @override
  Future<Result<UserSettings>> update(
    UserSettings Function(UserSettings current) change,
  ) async {
    record('update');
    final failure = takeFailure('update');
    if (failure != null) return Result.err(failure);
    journal.putSettings(change(journal.settings));
    return Result.ok(journal.settings);
  }
}

/// A [DailyCardRepository] over an [InMemoryJournal], drawing with the real
/// `DailyCardRules` on a [FakeClock] and a seeded source.
final class FakeDailyCardRepository
    with FakeBehaviour
    implements DailyCardRepository {
  /// A repository over [journal].
  FakeDailyCardRepository({
    InMemoryJournal? journal,
    FakeClock? clock,
    RandomSource? random,
    Deck? deck,
  }) : journal = journal ?? InMemoryJournal(),
       clock = clock ?? FakeClock(),
       _rules = DailyCardRules(random ?? SeededRandomSource()),
       _deck = deck ?? aDeck().build();

  @override
  String get fakeName => 'DailyCardRepository';

  /// The backing store.
  final InMemoryJournal journal;

  /// The device clock.
  final FakeClock clock;

  final DailyCardRules _rules;
  final Deck _deck;

  @override
  Stream<DailyCard?> watchToday() =>
      watchValue(() => journal.dailyCards[clock.localDate], journal.changes);

  @override
  Future<Result<DailyCard>> drawToday() async {
    record('drawToday');
    final failure = takeFailure('drawToday');
    if (failure != null) return Result.err(failure);
    final today = clock.localDate;
    final pick = _rules.today(
      today: today,
      stored: journal.dailyCards[today],
      deck: _deck,
      reversalsEnabled: journal.settings.reversalsEnabled,
      now: clock.now(),
    );
    if (pick.isNew) journal.putDailyCard(pick.card);
    return Result.ok(pick.card);
  }

  Future<Result<void>> _change(
    String method,
    String localDate,
    DailyCard Function(DailyCard card) change,
  ) async {
    record(method);
    final failure = takeFailure(method);
    if (failure != null) return Result.err(failure);
    final card = journal.dailyCards[localDate];
    if (card != null) {
      journal.putDailyCard(change(card).copyWith(updatedAt: clock.now()));
    }
    return const Result.ok(null);
  }

  @override
  Future<Result<void>> setNote(String localDate, String? note) =>
      _change('setNote', localDate, (c) => c.copyWith(note: note));

  @override
  Future<Result<void>> setFavourite(
    String localDate, {
    required bool favourite,
  }) => _change(
    'setFavourite',
    localDate,
    (c) => c.copyWith(favourite: favourite),
  );
}
