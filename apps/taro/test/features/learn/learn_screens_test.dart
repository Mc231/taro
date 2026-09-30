import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taro/di/providers.dart'
    show Article, ArticleEntry, ArticleSection;
import 'package:taro/features/learn/controller/about_controller.dart';
import 'package:taro/features/learn/controller/card_detail_controller.dart';
import 'package:taro/features/learn/controller/deck_browser_controller.dart';
import 'package:taro/features/learn/controller/spread_guide_controller.dart';
import 'package:taro/features/learn/view/about_screen.dart';
import 'package:taro/features/learn/view/card_detail_screen.dart';
import 'package:taro/features/learn/view/deck_browser_screen.dart';
import 'package:taro/features/learn/view/learn_labels.dart';
import 'package:taro/features/learn/view/spread_guide_screen.dart';
import 'package:taro/l10n/generated/taro_localizations.dart';
import 'package:taro_core/taro_core.dart';
import 'package:taro_ui/taro_ui.dart';

import '../skeleton_support.dart';

const CardId _cups3 = CardId('cups_03');

DeckCard _card(CardId id) => aDeck().build().card(id)!;

CardDetailView _detail({int drawn = 2, CardId? previous, CardId? next}) =>
    CardDetailView(
      card: _card(_cups3),
      text: aCardText(_cups3),
      drawnCount: drawn,
      position: 3,
      sectionSize: 14,
      previous: previous,
      next: next,
    );

const Article _article = Article(
  title: 'About',
  sections: [
    ArticleSection(
      heading: 'History',
      paragraphs: ['Tarot began as a card game.'],
      entries: [
        ArticleEntry(title: 'Is it free?', paragraphs: ['Yes, one a day.']),
      ],
    ),
  ],
);

void main() {
  late TaroLocalizations l10n;

  setUpAll(() async => l10n = await enL10n());

  test('LearnLabels', () {
    for (final kind in DeckSectionKind.values) {
      expect(LearnLabels.section(l10n, kind), isNotEmpty);
    }
    expect(LearnLabels.originOf('search'), LearnCardOrigin.search);
    expect(LearnLabels.originOf(null), LearnCardOrigin.deck);
  });

  group('S16 deck browser view', () {
    testWidgets('every state', (tester) async {
      final cards = <CardId>[];
      var spreads = 0;
      var about = 0;
      var retry = 0;
      final searches = <String>[];
      Future<void> pump(DeckBrowserState state) => pumpTaroWidget(
        tester,
        DeckBrowserLayout(
          state: state,
          onSearch: searches.add,
          onCard: cards.add,
          onSpreads: () => spreads++,
          onAbout: () => about++,
          onRetry: () => retry++,
        ),
      );
      await pump(const DeckBrowserState.loading());
      expect(find.byType(TaroLoadingView), findsOneWidget);
      await pump(const DeckBrowserState.searchEmpty(query: 'xyz'));
      expect(find.text(l10n.learnSearchEmpty('xyz')), findsOneWidget);
      await pump(const DeckBrowserState.storageError());
      await tapText(tester, l10n.commonRetry);
      await pump(
        DeckBrowserState.content(
          sections: [
            DeckSection(
              kind: DeckSectionKind.cups,
              tiles: [DeckTile(card: _card(_cups3), name: 'Three of Cups')],
            ),
          ],
        ),
      );
      expect(find.text(l10n.suitCups), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'cups');
      await tapText(tester, l10n.learnSpreadsGuide);
      await tapText(tester, l10n.learnAbout);
      await tapText(tester, 'Three of Cups');
      expect(cards, [_cups3]);
      expect(searches, ['cups']);
      expect((spreads, about, retry), (1, 1, 1));
    });
  });

  group('S17 card detail view', () {
    testWidgets('every state', (tester) async {
      final reversed = <bool>[];
      final opened = <CardId>[];
      var zoom = 0;
      var closeZoom = 0;
      var journal = 0;
      var back = 0;
      var retry = 0;
      Future<void> pump(CardDetailState state) => pumpTaroWidget(
        tester,
        CardDetailLayout(
          state: state,
          onReversed: reversed.add,
          onZoom: () => zoom++,
          onCloseZoom: () => closeZoom++,
          onCard: opened.add,
          onJournal: () => journal++,
          onBack: () => back++,
          onRetry: () => retry++,
        ),
      );
      final text = aCardText(_cups3);
      await pump(const CardDetailState.loading());
      expect(find.byType(TaroLoadingView), findsOneWidget);
      await pump(const CardDetailState.storageError());
      await tapText(tester, l10n.commonRetry);

      await pump(
        CardDetailState.upright(
          _detail(previous: const CardId('cups_02'), next: _cups3),
        ),
      );
      expect(find.text(text.name), findsOneWidget);
      expect(find.text(l10n.cardPosition(l10n.suitCups, 3, 14)), findsOne);
      expect(find.text(text.meaningUpright), findsOneWidget);
      await tapText(tester, l10n.commonReversed);
      await tapText(tester, l10n.cardZoomOpen);
      await tapText(tester, l10n.cardDrawnTimes(2));
      await tapText(tester, l10n.cardPreviousAction);
      await tapText(tester, l10n.cardNextAction);
      await tester.tap(find.bySemanticsLabel(l10n.commonBack));

      await pump(CardDetailState.reversed(_detail(drawn: 0)));
      expect(find.text(text.meaningReversed), findsOneWidget);
      expect(find.text(l10n.cardPreviousAction), findsNothing);

      await pump(CardDetailState.zoomed(_detail(), reversed: true));
      expect(find.bySemanticsLabel(l10n.cardZoomSemantics), findsWidgets);
      await tapText(tester, l10n.commonClose);

      expect(reversed, [true]);
      expect(opened, [const CardId('cups_02'), _cups3]);
      expect((zoom, closeZoom, journal, back, retry), (1, 1, 1, 1, 1));
    });
  });

  group('S18 spread guide view', () {
    testWidgets('list, detail, loading, storage error', (tester) async {
      final selected = <SpreadId>[];
      final started = <SpreadId>[];
      var back = 0;
      var retry = 0;
      final spreads = [
        for (final s in allSpreads())
          SpreadGuideEntry(spread: s, startable: s.id.value != 'celtic_cross'),
      ];
      Future<void> pump(SpreadGuideState state) => pumpTaroWidget(
        tester,
        SpreadGuideLayout(
          state: state,
          onSelect: selected.add,
          onBack: () => back++,
          onStart: started.add,
          onRetry: () => retry++,
        ),
      );
      await pump(const SpreadGuideState.loading());
      expect(find.byType(TaroLoadingView), findsOneWidget);
      await pump(const SpreadGuideState.storageError());
      await tapText(tester, l10n.commonRetry);
      await pump(SpreadGuideState.content(spreads: spreads));
      await tapText(tester, l10n.spread_three_ppf_name);
      await pump(
        SpreadGuideState.content(
          spreads: spreads,
          selected: const SpreadId('three_ppf'),
        ),
      );
      expect(find.text(l10n.spread_three_ppf_whenToUse), findsOneWidget);
      expect(find.text(l10n.spread_three_ppf_pos_past_name), findsOneWidget);
      await tapText(tester, l10n.spreadGuideStart);
      await tester.tap(find.bySemanticsLabel(l10n.commonBack));
      await pump(
        SpreadGuideState.content(
          spreads: spreads,
          selected: const SpreadId('celtic_cross'),
        ),
      );
      expect(find.text(l10n.spreadGuideStart), findsNothing);
      expect(selected, [const SpreadId('three_ppf')]);
      expect(started, [const SpreadId('three_ppf')]);
      expect((back, retry), (1, 1));
    });
  });

  group('S19 about view', () {
    testWidgets('every state ends with the disclaimer', (tester) async {
      var back = 0;
      var retry = 0;
      Future<void> pump(AboutState state) => pumpTaroWidget(
        tester,
        AboutLayout(
          state: state,
          onBack: () => back++,
          onRetry: () => retry++,
        ),
      );
      await pump(const AboutState.loading());
      expect(find.byType(TaroLoadingView), findsOneWidget);
      await pump(const AboutState.storageError());
      await tapText(tester, l10n.commonRetry);
      await pump(const AboutState.content(_article));
      expect(find.text('History'), findsOneWidget);
      expect(find.text('Is it free?'), findsOneWidget);
      expect(find.text(l10n.disclaimerShort), findsOneWidget);
      await tester.tap(find.bySemanticsLabel(l10n.commonBack));
      expect((back, retry), (1, 1));
    });
  });

  group('learn screens with fakes', () {
    late TaroFakes fakes;

    setUp(() => fakes = TaroFakes());

    testWidgets('S16: search, open a card, spreads guide, about', (
      tester,
    ) async {
      final router = await pumpRouted(
        tester,
        const DeckBrowserScreen(),
        fakes: fakes,
      );
      final name = aCardText(const CardId('major_00')).name;
      await tapText(tester, name);
      expectRoute('/learn/card/major_00?origin=deck');
      router.pop();
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextField),
        name.substring(0, 4).toLowerCase(),
      );
      await tester.pumpAndSettle();
      await tapText(tester, name);
      expectRoute('/learn/card/major_00?origin=search');
      router.pop();
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '');
      await tester.pumpAndSettle();
      await tapText(tester, l10n.learnSpreadsGuide);
      expectRoute('/learn/spreads');
      router.pop();
      await tester.pumpAndSettle();
      await tapText(tester, l10n.learnAbout);
      expectRoute('/learn/about');
    });

    testWidgets('S16: storage error retries', (tester) async {
      fakes.content.failNext(const Failure.storage(), on: 'deck');
      await pumpRouted(tester, const DeckBrowserScreen(), fakes: fakes);
      await tapText(tester, l10n.commonRetry);
      expect(find.text(l10n.learnSpreadsGuide), findsOneWidget);
    });

    testWidgets('S17: toggle, zoom, neighbours, journal, retry', (
      tester,
    ) async {
      fakes.journal.putReading(aReading().build());
      final router = await pumpRouted(
        tester,
        const CardDetailScreen(cardId: CardId('major_01')),
        fakes: fakes,
        pushed: true,
      );
      await tapText(tester, l10n.commonReversed);
      expect(
        find.text(aCardText(const CardId('major_01')).meaningReversed),
        findsOneWidget,
      );
      await tapText(tester, l10n.cardZoomOpen);
      await tapText(tester, l10n.commonClose);
      await tapText(tester, l10n.cardNextAction);
      expectRoute('/learn/card/major_02');
      router.pop();
      await tester.pumpAndSettle();
      router.push<void>('/under-test').ignore();
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel(l10n.commonBack));
      await tester.pumpAndSettle();
      expectRoute('/');

      fakes.content.failNext(const Failure.storage(), on: 'deck');
      await pumpRouted(
        tester,
        const CardDetailScreen(cardId: CardId('major_00')),
        fakes: fakes,
      );
      await tapText(tester, l10n.commonRetry);
      expect(
        find.text(aCardText(const CardId('major_00')).name),
        findsOneWidget,
      );
      await tapText(tester, l10n.cardDrawnTimes(1));
      expectRoute('/journal');
    });

    testWidgets('S18: detail, back to list, start, retry', (tester) async {
      await pumpRouted(
        tester,
        const SpreadGuideScreen(),
        fakes: fakes,
        pushed: true,
      );
      await tapText(tester, l10n.spread_single_name);
      expect(find.text(l10n.spread_single_whenToUse), findsOneWidget);
      await tester.tap(find.bySemanticsLabel(l10n.commonBack));
      await tester.pumpAndSettle();
      expect(find.text(l10n.spread_three_sao_name), findsOneWidget);
      await tester.tap(find.bySemanticsLabel(l10n.commonBack));
      await tester.pumpAndSettle();
      expectRoute('/');

      await pumpRouted(
        tester,
        const SpreadGuideScreen(initial: SpreadId('single')),
        fakes: fakes,
      );
      await tapText(tester, l10n.spreadGuideStart);
      expectRoute('/reading/question?spread=single');

      fakes.content.failNext(const Failure.storage(), on: 'spreads');
      await pumpRouted(tester, const SpreadGuideScreen(), fakes: fakes);
      await tapText(tester, l10n.commonRetry);
      expect(find.text(l10n.spread_single_name), findsOneWidget);
    });

    testWidgets('S19: article, back, retry', (tester) async {
      var fail = true;
      fakes.articles = (id, locale) async {
        if (fail) {
          fail = false;
          return const Result.err(Failure.storage());
        }
        return const Result.ok(_article);
      };
      await pumpRouted(tester, const AboutScreen(), fakes: fakes, pushed: true);
      await tapText(tester, l10n.commonRetry);
      expect(find.text('History'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel(l10n.commonBack));
      await tester.pumpAndSettle();
      expectRoute('/');
    });
  });
}
