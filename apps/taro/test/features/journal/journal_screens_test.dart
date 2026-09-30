import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:taro/features/journal/controller/journal_entry_controller.dart';
import 'package:taro/features/journal/controller/journal_list_controller.dart';
import 'package:taro/features/journal/view/journal_entry_screen.dart';
import 'package:taro/features/journal/view/journal_labels.dart';
import 'package:taro/features/journal/view/journal_list_screen.dart';
import 'package:taro/l10n/generated/taro_localizations.dart';
import 'package:taro_core/taro_core.dart';
import 'package:taro_ui/taro_ui.dart';

import '../skeleton_support.dart';

final Reading _complete = aReading().withId('r-complete').favourite().build();
final Reading _pending = aReading().withId('r-pending').pending().build();
final Reading _failed = aReading()
    .withId('r-failed')
    .failed(const Failure.server(status: 500), refunded: true)
    .withQuestion(null)
    .build();
final Reading _classic = aReading()
    .withId('r-classic')
    .classic()
    .withNote('A note')
    .build();
final DailyCard _daily = aDailyCard()
    .on('2026-09-25')
    .withNote('n')
    .favourite()
    .build();

JournalEntryView _view(JournalItem item, {NoteStatus? status}) =>
    JournalEntryView(
      item: item,
      note: 'note text',
      noteStatus: status ?? NoteStatus.saved,
    );

void main() {
  late TaroLocalizations l10n;

  setUpAll(() async {
    await initializeDateFormatting('en');
    l10n = await enL10n();
  });

  group('JournalLabels', () {
    test('keys, titles, statuses and locations', () {
      expect(
        JournalLabels.keyOf('2026-09-25'),
        const JournalEntryKey.dailyCard('2026-09-25'),
      );
      expect(
        JournalLabels.keyOf('r1'),
        const JournalEntryKey.reading(ReadingId('r1')),
      );
      expect(
        JournalLabels.title(l10n, JournalItem.reading(_failed)),
        l10n.spread_three_ppf_name,
      );
      expect(
        JournalLabels.title(l10n, JournalItem.dailyCard(_daily)),
        l10n.commonDailyCard,
      );
      expect(
        JournalLabels.location(JournalItem.dailyCard(_daily)),
        '/journal/2026-09-25',
      );
      expect(
        JournalLabels.finishLocation(const ReadingId('r1')),
        '/reading/draw?resume=r1',
      );
      for (final status in JournalEntryTileStatus.values) {
        expect(JournalLabels.statusLabel(l10n, status), isNotEmpty);
      }
      expect(
        JournalLabels.status(
          JournalItem.reading(aReading().refused().build()),
        ),
        JournalEntryTileStatus.ai,
      );
      expect(JournalLabels.month(l10n, '2026-09'), 'September 2026');
    });
  });

  group('S14 journal list view', () {
    Future<void> pump(
      WidgetTester tester,
      JournalListState state, {
      JournalTypeFilter type = JournalTypeFilter.all,
      void Function(JournalTypeFilter)? onType,
      void Function(String)? onSearch,
      void Function()? onClear,
      void Function(JournalItem)? onOpen,
      void Function(ReadingId)? onFinish,
      void Function()? onUndo,
      void Function()? onStart,
      void Function()? onRetry,
    }) => pumpTaroWidget(
      tester,
      JournalListLayout(
        state: state,
        type: type,
        onType: onType ?? noop1,
        onSearch: onSearch ?? noop1,
        onClearFilters: onClear ?? noop,
        onOpen: onOpen ?? noop1,
        onFinish: onFinish ?? noop1,
        onUndo: onUndo ?? noop,
        onStartReading: onStart ?? noop,
        onRetry: onRetry ?? noop,
      ),
    );

    testWidgets('loading, empty, filteredEmpty, searchEmpty, storageError', (
      tester,
    ) async {
      var start = 0;
      var clear = 0;
      var retry = 0;
      await pump(tester, const JournalListState.loading());
      expect(find.byType(TaroLoadingView), findsOneWidget);
      await pump(
        tester,
        const JournalListState.empty(),
        onStart: () => start++,
      );
      expect(find.text(l10n.journalEmptyTitle), findsOneWidget);
      await tapText(tester, l10n.homeStartReading);
      await pump(
        tester,
        const JournalListState.filteredEmpty(
          filters: JournalFilters(type: JournalTypeFilter.favourites),
        ),
        type: JournalTypeFilter.favourites,
        onClear: () => clear++,
      );
      await tapText(tester, l10n.journalClearFilter);
      await pump(tester, const JournalListState.searchEmpty(query: 'moon'));
      expect(find.text(l10n.journalSearchEmpty('moon')), findsOneWidget);
      await pump(
        tester,
        const JournalListState.storageError(),
        onRetry: () => retry++,
      );
      await tapText(tester, l10n.commonRetry);
      expect((start, clear, retry), (1, 1, 1));
    });

    testWidgets('content: months, tiles, patterns, filters, search, undo', (
      tester,
    ) async {
      final opened = <JournalItem>[];
      final finished = <ReadingId>[];
      final types = <JournalTypeFilter>[];
      final searches = <String>[];
      var undo = 0;
      final patterns = JournalPatterns.compute(
        readings: [_complete, _pending, _failed, _classic],
        dailyCards: [_daily],
        today: '2026-09-30',
      );
      await pump(
        tester,
        JournalListState.content(
          months: [
            JournalMonth(
              yearMonth: '2026-09',
              items: [
                JournalItem.reading(_complete),
                JournalItem.reading(_pending),
                JournalItem.reading(_failed),
                JournalItem.reading(_classic),
                JournalItem.dailyCard(_daily),
              ],
            ),
          ],
          filters: const JournalFilters(),
          patterns: patterns,
          undoable: const ReadingId('gone'),
        ),
        onOpen: opened.add,
        onFinish: finished.add,
        onType: types.add,
        onSearch: searches.add,
        onUndo: () => undo++,
      );
      expect(find.text(l10n.journalPatternsTitle(30)), findsOneWidget);
      expect(find.text('September 2026'), findsOneWidget);
      expect(find.byType(JournalEntryTile), findsWidgets);
      await tapText(tester, l10n.journalFilterFavourites);
      await tester.enterText(find.byType(TextField).first, 'moon');
      await tapText(tester, l10n.journalFinishReading);
      await tapText(tester, l10n.spread_three_ppf_name);
      await tapText(tester, l10n.commonUndo);
      expect(types, [JournalTypeFilter.favourites]);
      expect(searches, ['moon']);
      expect(finished, [_pending.id]);
      expect(opened, [JournalItem.reading(_failed)]);
      expect(undo, 1);
    });
  });

  group('S15 journal entry view', () {
    Future<void> pump(
      WidgetTester tester,
      JournalEntryState state, {
      void Function(String)? onNote,
      void Function()? onFavourite,
      void Function()? onDelete,
      void Function()? onUndo,
      void Function(ReadingId)? onFinish,
      void Function(Reading)? onFull,
      void Function()? onBack,
      void Function()? onRetry,
    }) => pumpTaroWidget(
      tester,
      JournalEntryLayout(
        state: state,
        onNoteChanged: onNote ?? noop1,
        onToggleFavourite: onFavourite ?? noop,
        onDelete: onDelete ?? noop,
        onUndo: onUndo ?? noop,
        onFinish: onFinish ?? noop1,
        onFullReading: onFull ?? noop1,
        onBack: onBack ?? noop,
        onRetry: onRetry ?? noop,
      ),
    );

    testWidgets('every state ends with the disclaimer', (tester) async {
      for (final state in [
        const JournalEntryState.loading(),
        JournalEntryState.content(_view(JournalItem.reading(_complete))),
        JournalEntryState.content(_view(JournalItem.dailyCard(_daily))),
        JournalEntryState.pending(_view(JournalItem.reading(_pending))),
        JournalEntryState.failed(
          _view(JournalItem.reading(_failed)),
          refunded: true,
        ),
        JournalEntryState.deleted(undoUntil: DateTime.utc(2026)),
        const JournalEntryState.notFound(),
        const JournalEntryState.storageError(),
      ]) {
        await pump(tester, state);
        await tester.scrollUntilVisible(
          find.text(l10n.disclaimerShort),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.text(l10n.disclaimerShort), findsOneWidget);
      }
    });

    testWidgets('content: note, favourite, delete, full reading', (
      tester,
    ) async {
      final notes = <String>[];
      final full = <Reading>[];
      var favourite = 0;
      var delete = 0;
      await pump(
        tester,
        JournalEntryState.content(
          _view(JournalItem.reading(_complete), status: NoteStatus.editing),
        ),
        onNote: notes.add,
        onFavourite: () => favourite++,
        onDelete: () => delete++,
        onFull: full.add,
      );
      expect(find.text(kTestQuestion), findsOneWidget);
      expect(find.text(l10n.commonSaving), findsOneWidget);
      expect(find.text('note text'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'new');
      await tapText(tester, l10n.entryFullReading);
      await tapText(tester, l10n.commonUnfavourite);
      await tapText(tester, l10n.entryDelete);
      expect(notes, ['new']);
      expect(full, [_complete]);
      expect((favourite, delete), (1, 1));

      await pump(
        tester,
        JournalEntryState.content(
          _view(JournalItem.dailyCard(_daily), status: NoteStatus.failed),
        ),
      );
      expect(find.text(l10n.failureStorage), findsOneWidget);
      expect(find.text(l10n.entryDelete), findsNothing);
    });

    testWidgets('pending / failed offer finishing with the same cards', (
      tester,
    ) async {
      final finished = <ReadingId>[];
      await pump(
        tester,
        JournalEntryState.pending(_view(JournalItem.reading(_pending))),
        onFinish: finished.add,
      );
      expect(find.text(l10n.entryPendingNotice), findsOneWidget);
      await tapText(tester, l10n.journalFinishReading);
      await pump(
        tester,
        JournalEntryState.failed(
          _view(JournalItem.reading(_failed)),
          refunded: true,
        ),
        onFinish: finished.add,
      );
      expect(find.text(l10n.entryFailedNotice), findsOneWidget);
      await tapText(tester, l10n.commonRetry);
      expect(finished, [_pending.id, _failed.id]);
    });

    testWidgets('deleted undo, notFound back, storage retry', (tester) async {
      var undo = 0;
      var back = 0;
      var retry = 0;
      await pump(
        tester,
        JournalEntryState.deleted(undoUntil: DateTime.utc(2026)),
        onUndo: () => undo++,
        onBack: () => back++,
      );
      await tapText(tester, l10n.commonUndo);
      await tapText(tester, l10n.commonBack);
      await pump(
        tester,
        const JournalEntryState.notFound(),
        onBack: () => back++,
      );
      expect(find.text(l10n.readingNotFound), findsOneWidget);
      await tapText(tester, l10n.commonBack);
      await pump(
        tester,
        const JournalEntryState.storageError(),
        onRetry: () => retry++,
      );
      await tapText(tester, l10n.commonRetry);
      expect((undo, back, retry), (1, 2, 1));
    });
  });

  group('journal screens with fakes', () {
    late TaroFakes fakes;

    setUp(() {
      fakes = TaroFakes();
      fakes.journal
        ..putReading(_complete)
        ..putReading(_pending)
        ..putDailyCard(_daily);
    });

    testWidgets('S14: filter, search, open, finish, start', (tester) async {
      final router = await pumpRouted(
        tester,
        const JournalListScreen(),
        fakes: fakes,
      );
      expect(find.byType(JournalEntryTile), findsNWidgets(3));
      await tapText(tester, l10n.journalFilterDailyCards);
      expect(find.byType(JournalEntryTile), findsOneWidget);
      await tapText(tester, l10n.journalFilterFavourites);
      expect(find.byType(JournalEntryTile), findsNWidgets(2));
      await tester.enterText(find.byType(TextField), 'zzz');
      await tester.pumpAndSettle();
      expect(find.text(l10n.journalSearchEmpty('zzz')), findsOneWidget);
      await tester.enterText(find.byType(TextField), '');
      await tester.pumpAndSettle();
      await tapText(tester, l10n.journalFilterReadings);
      await tapText(tester, l10n.journalFinishReading);
      expectRoute('/reading/draw?resume=${_pending.id.value}');
      router.pop();
      await tester.pumpAndSettle();
      await tester.tap(find.byType(JournalEntryTile).first);
      await tester.pumpAndSettle();
      expect(find.textContaining('route:/journal/'), findsOneWidget);
    });

    testWidgets('S14: filtered empty clears; empty starts a reading', (
      tester,
    ) async {
      final empty = TaroFakes();
      await pumpRouted(tester, const JournalListScreen(), fakes: empty);
      await tapText(tester, l10n.homeStartReading);
      expectRoute('/reading/spreads');

      await pumpRouted(tester, const JournalListScreen(), fakes: fakes);
      await tapText(tester, l10n.journalFilterFavourites);
      await tapText(tester, l10n.journalFilterReadings);
      fakes.journal.putReading(_complete.copyWith(favourite: false));
      fakes.journal.notify();
      await tester.pumpAndSettle();
      await tapText(tester, l10n.journalFilterFavourites);
      if (find.text(l10n.journalClearFilter).evaluate().isNotEmpty) {
        await tapText(tester, l10n.journalClearFilter);
      }
      expect(find.byType(JournalEntryTile), findsWidgets);
    });

    testWidgets('S14: a storage error retries', (
      tester,
    ) async {
      fakes.journalRepository.failNext(const Failure.storage(), on: 'search');
      await pumpRouted(tester, const JournalListScreen(), fakes: fakes);
      await tester.enterText(find.byType(TextField), 'moon');
      await tester.pumpAndSettle();
      await tapText(tester, l10n.commonRetry);
      expect(find.text(l10n.journalSearchEmpty('moon')), findsOneWidget);
    });

    testWidgets('S14: a list delete can be undone', (tester) async {
      await pumpRouted(tester, const JournalListScreen(), fakes: fakes);
      final container = ProviderScope.containerOf(
        tester.element(find.byType(JournalListScreen)),
      );
      await container
          .read(journalListControllerProvider.notifier)
          .delete(_complete.id);
      await tester.pumpAndSettle();
      await tapText(tester, l10n.commonUndo);
      expect(find.byType(JournalEntryTile), findsNWidgets(3));
    });

    testWidgets('S14: Clear filter after a filter that matches nothing', (
      tester,
    ) async {
      final plain = TaroFakes()..journal.putReading(_pending);
      await pumpRouted(tester, const JournalListScreen(), fakes: plain);
      await tapText(tester, l10n.journalFilterFavourites);
      expect(find.text(l10n.journalFilteredEmpty), findsOneWidget);
      await tapText(tester, l10n.journalClearFilter);
      expect(find.byType(JournalEntryTile), findsOneWidget);
    });

    testWidgets('S15: note, favourite, delete + undo, full reading, back', (
      tester,
    ) async {
      final router = await pumpRouted(
        tester,
        JournalEntryScreen(id: _complete.id.value),
        fakes: fakes,
        pushed: true,
      );
      await tester.enterText(find.byType(TextField), 'thoughts');
      await tester.pump(kJournalNoteAutosaveDelay);
      await tester.pumpAndSettle();
      await tapText(tester, l10n.commonUnfavourite);
      expect(find.text(l10n.commonFavourite), findsOneWidget);
      await tapText(tester, l10n.entryFullReading);
      expectRoute('/reading/${_complete.id.value}');
      router.pop();
      await tester.pumpAndSettle();

      await tapText(tester, l10n.entryDelete);
      await tapText(tester, l10n.commonCancel);
      expect(find.text(l10n.journalDeleted), findsNothing);
      await tapText(tester, l10n.entryDelete);
      await tapText(tester, l10n.commonDelete);
      expect(find.text(l10n.journalDeleted), findsOneWidget);
      await tapText(tester, l10n.commonUndo);
      expect(find.text(kTestQuestion), findsOneWidget);
      await tester.tap(find.bySemanticsLabel(l10n.commonBack));
      await tester.pumpAndSettle();
      expectRoute('/');
    });

    testWidgets('S15: pending finish, daily card, not found, storage retry', (
      tester,
    ) async {
      await pumpRouted(
        tester,
        JournalEntryScreen(id: _pending.id.value),
        fakes: fakes,
      );
      await tapText(tester, l10n.journalFinishReading);
      expectRoute('/reading/draw?resume=${_pending.id.value}');

      await pumpRouted(
        tester,
        const JournalEntryScreen(id: '2026-09-25'),
        fakes: fakes,
      );
      expect(find.text(l10n.commonDailyCard), findsOneWidget);

      await pumpRouted(
        tester,
        const JournalEntryScreen(id: 'missing'),
        fakes: fakes,
      );
      expect(find.text(l10n.readingNotFound), findsOneWidget);

      fakes.readings.failNext(const Failure.storage(), on: 'setFavourite');
      await pumpRouted(
        tester,
        JournalEntryScreen(id: _classic.id.value),
        fakes: fakes..journal.putReading(_classic),
      );
      await tapText(tester, l10n.commonFavourite);
      await tapText(tester, l10n.commonRetry);
      expect(find.textContaining(l10n.classicLabel), findsWidgets);
    });
  });
}
