import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taro/features/journal/controller/journal_list_controller.dart';
import 'package:taro_core/taro_core.dart';

import '../../helpers/pump_app.dart';

Reading _reading(
  String id, {
  String localDate = '2026-09-20',
  String spread = 'three_ppf',
  bool favourite = false,
  String? note,
}) => aReading()
    .withId(id)
    .createdAt(DateTime.parse('${localDate}T10:00:00Z'), localDate: localDate)
    .withSpread(spread)
    .favourite(favourite)
    .withNote(note)
    .build();

void main() {
  late TaroFakes fakes;

  setUp(() => fakes = TaroFakes());

  (ProviderContainer, JournalListController, JournalListState Function())
  open() {
    final container = fakes.container()
      ..listen(journalListControllerProvider, (_, _) {});
    return (
      container,
      container.read(journalListControllerProvider.notifier),
      () => container.read(journalListControllerProvider),
    );
  }

  void seed() {
    fakes.journal
      ..putReading(_reading('r-sep', note: 'about work'))
      ..putReading(
        _reading(
          'r-aug',
          localDate: '2026-08-02',
          spread: 'single',
          favourite: true,
        ),
      )
      ..putDailyCard(aDailyCard().on('2026-09-21').build());
  }

  test('loading, then empty', () async {
    final (_, _, read) = open();
    expect(read(), const JournalListState.loading());
    await pumpEventQueue();
    expect(read(), const JournalListState.empty());
  });

  test('content grouped by month, newest first; no patterns under 5 '
      'entries', () async {
    seed();
    final (_, _, read) = open();
    await pumpEventQueue();
    final content = read() as JournalListContent;
    expect(content.months.map((m) => m.yearMonth), ['2026-09', '2026-08']);
    expect(content.months.first.items, hasLength(2));
    expect(content.patterns, isNull);
    expect(content.filters, const JournalFilters());
    expect(fakes.analytics.eventNames, isEmpty);
  });

  test('the Patterns card appears at 5 entries and logs once', () async {
    for (var i = 1; i <= 5; i++) {
      fakes.journal.putReading(_reading('r$i', localDate: '2026-09-1$i'));
    }
    final (_, controller, read) = open();
    await pumpEventQueue();
    expect((read() as JournalListContent).patterns?.totalEntries, 5);
    fakes.journal.putReading(_reading('r6', localDate: '2026-09-19'));
    await pumpEventQueue();
    await controller.viewPatterns(PatternsRange.d90);
    expect(
      fakes.analytics.events.map((e) => e.parameters),
      [
        {'range': 'd30'},
        {'range': 'd90'},
      ],
    );
  });

  test('type, spread and card filters; filteredEmpty; clear', () async {
    seed();
    final (_, controller, read) = open();
    await pumpEventQueue();
    List<JournalItem> items() => [
      for (final m in (read() as JournalListContent).months) ...m.items,
    ];

    await controller.setType(JournalTypeFilter.readings);
    expect(items(), hasLength(2));
    await controller.setType(JournalTypeFilter.readings);
    await controller.setType(JournalTypeFilter.dailyCards);
    expect(items().single, isA<JournalDailyCardItem>());
    await controller.setType(JournalTypeFilter.favourites);
    expect(items().single, isA<JournalReadingItem>());
    await controller.setType(JournalTypeFilter.all);
    await controller.setSpread(const SpreadId('single'));
    expect(items().single, isA<JournalReadingItem>());
    await controller.setSpread(null);
    await controller.setCard(const CardId('major_17'));
    expect(items().single, isA<JournalDailyCardItem>());
    await controller.setCard(const CardId('major_00'));
    expect(items(), hasLength(2));
    await controller.setType(JournalTypeFilter.dailyCards);
    expect(
      read(),
      isA<JournalListFilteredEmpty>().having(
        (s) => s.filters.isActive,
        'active',
        isTrue,
      ),
    );
    controller.clearFilters();
    expect(items(), hasLength(3));
    expect(fakes.analytics.events.map((e) => e.parameters['filter']), [
      'type',
      'type',
      'favourites',
      'spread',
      'card',
      'card',
      'type',
    ]);
  });

  test('favourite daily cards pass the favourites filter', () {
    const filters = JournalFilters(type: JournalTypeFilter.favourites);
    expect(
      filters.accepts(
        JournalItem.dailyCard(aDailyCard().favourite().build()),
      ),
      isTrue,
    );
    expect(
      filters.accepts(JournalItem.dailyCard(aDailyCard().build())),
      isFalse,
    );
    expect(
      const JournalFilters(
        spreadId: SpreadId('single'),
      ).accepts(JournalItem.dailyCard(aDailyCard().build())),
      isFalse,
    );
  });

  test('search: hits, searchEmpty, cleared', () async {
    seed();
    final (_, controller, read) = open();
    await pumpEventQueue();
    await controller.search('work');
    expect(
      read(),
      isA<JournalListContent>().having((s) => s.query, 'query', 'work'),
    );
    fakes.journal.putReading(_reading('r-new', note: 'more work'));
    await pumpEventQueue();
    expect(
      (read() as JournalListContent).months.first.items,
      hasLength(2),
    );
    await controller.search('nothing here');
    expect(read(), const JournalListState.searchEmpty(query: 'nothing here'));
    await controller.search('  ');
    expect(read(), isA<JournalListContent>());
    expect(
      fakes.analytics.events.map((e) => e.parameters['filter']),
      ['search', 'search'],
    );
  });

  test('a failed search is a storage error', () async {
    seed();
    fakes.journalRepository.failNext(const Failure.storage(), on: 'search');
    final (_, controller, read) = open();
    await pumpEventQueue();
    await controller.search('work');
    expect(read(), const JournalListState.storageError());
  });

  test('delete shows Undo; undo restores and logs undone', () async {
    seed();
    final (_, controller, read) = open();
    await pumpEventQueue();
    await controller.delete(const ReadingId('r-sep'));
    await pumpEventQueue();
    expect((read() as JournalListContent).undoable, const ReadingId('r-sep'));
    await controller.undo();
    await pumpEventQueue();
    expect((read() as JournalListContent).undoable, isNull);
    expect(fakes.journal.readings, contains(const ReadingId('r-sep')));
    expect(fakes.analytics.events.single.parameters, {
      'entry_type': 'reading',
      'undone': true,
    });
    await controller.undo();
    expect(fakes.analytics.events, hasLength(1));
  });

  testWidgets('the Undo window lapses after 5 s', (tester) async {
    seed();
    final (_, controller, read) = open();
    await tester.pump();
    await controller.delete(const ReadingId('r-sep'));
    await tester.pump();
    expect((read() as JournalListContent).undoable, isNotNull);
    await tester.pump(ReadingRepository.undoWindow);
    expect((read() as JournalListContent).undoable, isNull);
    expect(fakes.analytics.events.single.parameters, {
      'entry_type': 'reading',
      'undone': false,
    });
  });

  test('closing the screen during the window logs not undone', () async {
    seed();
    final (container, controller, _) = open();
    await pumpEventQueue();
    await controller.delete(const ReadingId('r-sep'));
    container.dispose();
    expect(fakes.analytics.events.single.parameters['undone'], isFalse);
  });

  test('a failed delete is a storage error', () async {
    seed();
    fakes.readings.failNext(const Failure.storage(), on: 'delete');
    final (_, controller, read) = open();
    await pumpEventQueue();
    await controller.delete(const ReadingId('r-sep'));
    expect(read(), const JournalListState.storageError());
  });
}
