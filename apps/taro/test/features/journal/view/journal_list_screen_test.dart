import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:taro/common/spread_text.dart';
import 'package:taro/features/journal/controller/journal_list_controller.dart';
import 'package:taro/features/journal/view/journal_list_screen.dart';
import 'package:taro/l10n/generated/taro_localizations.dart';
import 'package:taro/routing/routes.dart';
import 'package:taro_core/taro_core.dart';
import 'package:taro_ui/taro_ui.dart';

import '../../flow_view_support.dart';

/// Sunday 27 September 2026, evening.
final DateTime _now = DateTime(2026, 9, 27, 20);

final Reading _complete = aReading()
    .withId('r-complete')
    .onLocalDate('2026-09-26')
    .favourite()
    .withNote('A note')
    .build();
final Reading _pending = aReading()
    .withId('r-pending')
    .onLocalDate('2026-09-25')
    .pending()
    .build();
final Reading _failed = aReading()
    .withId('r-failed')
    .onLocalDate('2026-09-20')
    .failed(const Failure.network())
    .build();
final Reading _classic = aReading()
    .withId('r-classic')
    .onLocalDate('2026-08-25')
    .classic()
    .build();
final DailyCard _daily = aDailyCard()
    .on('2026-09-27')
    .withCard('major_17')
    .withNote('n')
    .build();

JournalPatterns _patterns() => JournalPatterns.compute(
  readings: [_complete, _pending, _failed, _classic],
  dailyCards: [
    _daily,
    aDailyCard().on('2026-09-26').withCard('major_17').build(),
  ],
  today: '2026-09-27',
);

JournalListState _content({JournalPatterns? patterns}) =>
    JournalListState.content(
      months: [
        JournalMonth(
          yearMonth: '2026-09',
          items: [
            JournalItem.dailyCard(_daily),
            JournalItem.reading(_complete),
            JournalItem.reading(_pending),
            JournalItem.reading(_failed),
          ],
        ),
        JournalMonth(
          yearMonth: '2026-08',
          items: [JournalItem.reading(_classic)],
        ),
      ],
      filters: const JournalFilters(),
      patterns: patterns,
    );

void main() {
  late TaroLocalizations l10n;

  setUpAll(() async {
    await initializeDateFormatting('en');
    l10n = await enL10n();
  });

  group('S14 layout', () {
    late List<String> calls;

    setUp(() => calls = []);

    Future<void> pump(
      WidgetTester tester,
      JournalListState state, {
      JournalFilters filters = const JournalFilters(),
      PatternsRange range = PatternsRange.d30,
      Widget? banner,
      double textScale = 1,
    }) => pumpTaroWidget(
      tester,
      JournalListLayout(
        state: state,
        filters: filters,
        range: range,
        now: () => _now,
        cardNames: const {CardId('major_17'): 'The Star'},
        banner: banner,
        onType: (type) => calls.add('type:${type.name}'),
        onSpread: (spread) => calls.add('spread:${spread?.value}'),
        onClearCard: () => calls.add('clearCard'),
        onSearch: (text) => calls.add('search:$text'),
        onClearFilters: () => calls.add('clear'),
        onOpen: (item) => calls.add('open'),
        onFinish: (id) => calls.add('finish:${id.value}'),
        onDelete: (id) => calls.add('delete:${id.value}'),
        onOpenCard: (id) => calls.add('card:${id.value}'),
        onRange: (range) => calls.add('range:${range.name}'),
        onStartReading: () => calls.add('start'),
        onOpenDaily: () => calls.add('daily'),
        onRetry: () => calls.add('retry'),
      ),
      textScale: textScale,
    );

    const banner = SizedBox(key: Key('banner'), height: 50);

    testWidgets('loading, empty, storageError: no controls, no banner', (
      tester,
    ) async {
      await pump(tester, const JournalListState.loading(), banner: banner);
      expect(find.byType(TaroLoadingView), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
      expect(find.byKey(const Key('banner')), findsNothing);

      await pump(tester, const JournalListState.empty(), banner: banner);
      expect(find.text(l10n.journalEmptyTitle), findsOneWidget);
      expect(find.byType(TaroCardBack), findsNWidgets(3));
      expect(find.byKey(const Key('banner')), findsNothing);
      await tapText(tester, l10n.homeStartReading);
      await tapText(tester, l10n.homeDailyReveal);

      await pump(tester, const JournalListState.storageError());
      await tapText(tester, l10n.commonRetry);
      expect(calls, ['start', 'daily', 'retry']);
    });

    testWidgets('filteredEmpty and searchEmpty keep the controls', (
      tester,
    ) async {
      await pump(
        tester,
        const JournalListState.filteredEmpty(
          filters: JournalFilters(type: JournalTypeFilter.favourites),
        ),
        filters: const JournalFilters(type: JournalTypeFilter.favourites),
        banner: banner,
      );
      expect(find.byKey(const Key('banner')), findsOneWidget);
      expect(find.text(l10n.journalFilteredEmpty), findsOneWidget);
      await tapText(tester, l10n.journalClearFilter);

      await tester.pumpWidget(const SizedBox());
      await pump(tester, const JournalListState.searchEmpty(query: 'moon'));
      expect(find.text(l10n.journalSearchEmpty('moon')), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'sun');
      expect(calls, ['clear', 'search:sun']);
    });

    testWidgets('content: months, rows, pending finish, badges', (
      tester,
    ) async {
      await pump(tester, _content(), banner: banner);
      expect(find.byKey(const Key('banner')), findsOneWidget);
      expect(find.text('September 2026'), findsOneWidget);
      expect(find.byType(JournalEntryTile), findsNWidgets(4));
      // The daily card row is titled by its card; "Today" by the clock.
      expect(find.text('The Star'), findsOneWidget);
      expect(
        find.text(l10n.commonItemSeparator(l10n.commonDailyCard, 'Today')),
        findsOneWidget,
      );
      // Pending: spread · date, prefixed by the tile; the failed one too.
      final spread = SpreadText.name(l10n, _pending.spreadId);
      expect(
        find.textContaining(
          l10n.commonItemSeparator(l10n.journalPending, spread),
        ),
        findsOneWidget,
      );
      expect(find.textContaining(l10n.journalFailedLabel), findsOneWidget);
      await tapText(tester, l10n.journalFinishReading);
      await tester.tap(find.text('The Star'));
      await revealText(tester, 'August 2026');
      expect(find.text(l10n.classicLabel), findsOneWidget);
      expect(calls, ['finish:r-pending', 'open']);
    });

    testWidgets('a reading row deletes by swipe or semantics action', (
      tester,
    ) async {
      await pump(tester, _content());
      await tester.drag(find.byType(Dismissible).first, const Offset(-500, 0));
      await tester.pumpAndSettle();
      expect(calls, ['delete:r-complete']);
      // The row stays until the journal drops it.
      expect(find.byType(Dismissible), findsNWidgets(3));
      final semantics = tester.widget<Semantics>(
        find
            .ancestor(
              of: find.byType(Dismissible).first,
              matching: find.byWidgetPredicate(
                (w) =>
                    w is Semantics &&
                    w.properties.customSemanticsActions != null,
              ),
            )
            .first,
      );
      final actions = semantics.properties.customSemanticsActions!;
      expect(actions.keys.single.label, l10n.commonDelete);
      actions.values.single();
      expect(calls, ['delete:r-complete', 'delete:r-complete']);
    });

    testWidgets('chips, active spread and card filters, the filter sheet', (
      tester,
    ) async {
      await pump(
        tester,
        _content(),
        filters: const JournalFilters(
          spreadId: SpreadId('three_ppf'),
          cardId: CardId('major_17'),
        ),
      );
      await tapText(tester, l10n.journalFilterDailyCards);
      await tapText(tester, l10n.spread_three_ppf_name);
      await tapText(
        tester,
        l10n.commonItemSeparator(l10n.journalFilterCard, 'The Star'),
      );
      await tapText(tester, l10n.journalFilterMore);
      expect(find.byType(TaroRadioTile<SpreadId?>), findsWidgets);
      await tapText(tester, l10n.journalFilterAnySpread);
      await tapText(tester, l10n.journalFilterApply);
      // Apply without a change: nothing.
      await tapText(tester, l10n.journalFilterMore);
      await tapText(tester, l10n.journalFilterApply);
      expect(calls, [
        'type:dailyCards',
        'spread:null',
        'clearCard',
        'spread:null',
      ]);
    });

    testWidgets('Patterns: chart, most drawn, ratios, 30/90 toggle', (
      tester,
    ) async {
      final patterns = _patterns();
      await pump(tester, _content(patterns: patterns));
      expect(find.byType(PatternsChart), findsOneWidget);
      expect(
        find.text(l10n.journalPatternsCardsDrawn(patterns.last30.cards)),
        findsOneWidget,
      );
      expect(find.text(l10n.journalPatternsFootnote), findsOneWidget);
      await tapFound(tester, find.textContaining('Most drawn'));
      await tapText(tester, l10n.journalPatternsRange90);
      await pump(
        tester,
        _content(patterns: patterns),
        range: PatternsRange.d90,
      );
      expect(find.text(l10n.journalPatternsTitle(90)), findsOneWidget);
      expect(calls, ['card:major_00', 'range:d90']);
    });

    testWidgets('content at 200 % text does not overflow', (tester) async {
      await pump(tester, _content(patterns: _patterns()), textScale: 2);
      expect(tester.takeException(), isNull);
    });
  });

  group('S14 with fakes', () {
    late TaroFakes fakes;

    setUp(() {
      fakes = TaroFakes(clock: FakeClock(_now));
      fakes.journal
        ..putReading(_complete)
        ..putReading(_pending)
        ..putDailyCard(_daily);
    });

    testWidgets('filters, search, finish, open', (tester) async {
      final router = await pumpRouted(
        tester,
        const JournalListScreen(),
        fakes: fakes,
      );
      expect(find.byType(JournalEntryTile), findsNWidgets(3));
      await tapText(tester, l10n.journalFilterDailyCards);
      expect(find.byType(JournalEntryTile), findsOneWidget);
      await tapText(tester, l10n.journalFilterFavourites);
      expect(find.byType(JournalEntryTile), findsOneWidget);
      await tapText(tester, l10n.journalFilterAll);
      await tester.enterText(find.byType(TextField), 'zzz');
      await tester.pumpAndSettle();
      expect(find.text(l10n.journalSearchEmpty('zzz')), findsOneWidget);
      await tester.enterText(find.byType(TextField), '');
      await tester.pumpAndSettle();
      await tapText(tester, l10n.journalFilterMore);
      await tapText(tester, l10n.spread_three_ppf_name);
      await tapText(tester, l10n.journalFilterApply);
      expect(find.byType(JournalEntryTile), findsNWidgets(2));
      await tapText(tester, l10n.spread_three_ppf_name);
      await tapText(tester, l10n.journalFinishReading);
      expectRoute('/reading/draw?resume=${_pending.id.value}');
      router.pop();
      await tester.pumpAndSettle();
      await tester.tap(find.byType(JournalEntryTile).first);
      await tester.pumpAndSettle();
      expect(find.textContaining('route:/journal/'), findsOneWidget);
    });

    testWidgets('the card query filters; empty starts a reading', (
      tester,
    ) async {
      await pumpRouted(
        tester,
        JournalListScreen(cardId: _daily.cardId.value),
        fakes: fakes,
      );
      await tester.pumpAndSettle();
      expect(find.byType(JournalEntryTile), findsOneWidget);
      final chip = find.textContaining(l10n.journalFilterCard);
      await tester.ensureVisible(chip);
      await tester.pumpAndSettle();
      await tester.tap(chip);
      await tester.pumpAndSettle();
      expect(find.byType(JournalEntryTile), findsNWidgets(3));

      await pumpRouted(tester, const JournalListScreen(), fakes: TaroFakes());
      await tapText(tester, l10n.homeStartReading);
      expectRoute(RoutePaths.readingSpreads);
    });

    testWidgets('a filter matching nothing clears', (
      tester,
    ) async {
      final plain = TaroFakes()..journal.putReading(_pending);
      await pumpRouted(tester, const JournalListScreen(), fakes: plain);
      await tapText(tester, l10n.journalFilterFavourites);
      expect(find.text(l10n.journalFilteredEmpty), findsOneWidget);
      await tapText(tester, l10n.journalClearFilter);
      expect(find.byType(JournalEntryTile), findsOneWidget);
    });

    testWidgets('a storage error retries', (tester) async {
      fakes.journalRepository.failNext(const Failure.storage(), on: 'search');
      await pumpRouted(tester, const JournalListScreen(), fakes: fakes);
      await tester.enterText(find.byType(TextField), 'moon');
      await tester.pumpAndSettle();
      await tapText(tester, l10n.commonRetry);
      expect(find.byType(JournalEntryTile), findsNWidgets(3));
    });

    testWidgets('swipe delete asks, then Undo restores within 5 s', (
      tester,
    ) async {
      await pumpRouted(tester, const JournalListScreen(), fakes: fakes);
      Future<void> swipe() async {
        await tester.drag(
          find.byType(Dismissible).first,
          const Offset(-500, 0),
        );
        await tester.pumpAndSettle();
      }

      await swipe();
      await tapText(tester, l10n.commonCancel);
      expect(fakes.journal.readings, hasLength(2));
      await swipe();
      await tapText(tester, l10n.commonDelete);
      expect(find.byType(JournalEntryTile), findsNWidgets(2));
      expect(find.text(l10n.journalDeleted), findsOneWidget);
      await tester.tap(find.text(l10n.commonUndo));
      await tester.pumpAndSettle();
      expect(find.byType(JournalEntryTile), findsNWidgets(3));

      // Without Undo the toast goes when the window ends.
      await swipe();
      await tapText(tester, l10n.commonDelete);
      expect(find.text(l10n.journalDeleted), findsOneWidget);
      await tester.pump(ReadingRepository.undoWindow);
      await tester.pumpAndSettle();
      expect(find.text(l10n.journalDeleted), findsNothing);
      expect(find.byType(JournalEntryTile), findsNWidgets(2));
    });

    testWidgets('Patterns: most drawn opens the card, range is logged', (
      tester,
    ) async {
      for (final day in ['2026-09-21', '2026-09-22', '2026-09-23']) {
        fakes.journal.putDailyCard(
          aDailyCard().on(day).withCard('major_17').build(),
        );
      }
      await pumpRouted(tester, const JournalListScreen(), fakes: fakes);
      await tester.pumpAndSettle();
      expect(find.byType(PatternsChart), findsOneWidget);
      await tapText(tester, l10n.journalPatternsRange90);
      expect(
        fakes.analytics.events.whereType<PatternsViewedEvent>().map(
          (e) => e.range,
        ),
        [PatternsRange.d30, PatternsRange.d90],
      );
      await tapFound(tester, find.textContaining('Most drawn'));
      expectRoute(RoutePaths.learnCard('major_17'));
    });
  });
}
