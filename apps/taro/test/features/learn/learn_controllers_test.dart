import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderListenable;
import 'package:flutter_test/flutter_test.dart';
import 'package:taro/di/providers.dart';
import 'package:taro/features/learn/controller/about_controller.dart';
import 'package:taro/features/learn/controller/card_detail_controller.dart';
import 'package:taro/features/learn/controller/deck_browser_controller.dart';
import 'package:taro/features/learn/controller/spread_guide_controller.dart';
import 'package:taro_core/taro_core.dart';

import '../../helpers/pump_app.dart';

void main() {
  late TaroFakes fakes;

  setUp(() => fakes = TaroFakes());

  T keep<T>(ProviderContainer container, ProviderListenable<T> provider) {
    container.listen(provider, (_, _) {});
    return container.read(provider);
  }

  group('DeckBrowserController (S16)', () {
    test('loading, then 5 sections of the 78 cards', () async {
      final container = fakes.container();
      expect(
        keep(container, deckBrowserControllerProvider),
        const DeckBrowserState.loading(),
      );
      await pumpEventQueue();
      final content =
          container.read(deckBrowserControllerProvider) as DeckBrowserContent;
      expect(content.sections.map((s) => s.kind), DeckSectionKind.values);
      expect(content.sections.first.tiles, hasLength(22));
      expect(content.sections[1].tiles, hasLength(14));
      expect(content.sections.first.tiles.first.name, 'Card major_00');
    });

    test('search by name or keyword; searchEmpty; learn_search', () async {
      final container = fakes.container();
      keep(container, deckBrowserControllerProvider);
      await pumpEventQueue();
      final controller = container.read(deckBrowserControllerProvider.notifier);
      await controller.search('major_01');
      final content =
          container.read(deckBrowserControllerProvider) as DeckBrowserContent;
      expect(content.query, 'major_01');
      expect(content.sections.single.tiles.single.card.id.value, 'major_01');
      await controller.search('DOUBT');
      await controller.search('zzz');
      expect(
        container.read(deckBrowserControllerProvider),
        const DeckBrowserState.searchEmpty(query: 'zzz'),
      );
      await controller.search('');
      expect(
        fakes.analytics.events.map((e) => e.parameters['results_bucket']),
        ['1-5', '6+', '0'],
      );
    });

    test('search before load waits for the deck', () async {
      final container = fakes.container();
      keep(container, deckBrowserControllerProvider);
      await container
          .read(deckBrowserControllerProvider.notifier)
          .search('major');
      expect(fakes.analytics.events, isEmpty);
    });

    test('a missing deck or card text is a storage error', () async {
      fakes.content.failNext(const Failure.storage(), on: 'deck');
      var container = fakes.container();
      keep(container, deckBrowserControllerProvider);
      await pumpEventQueue();
      expect(
        container.read(deckBrowserControllerProvider),
        const DeckBrowserState.storageError(),
      );
      container.dispose();
      fakes.content.failNext(const Failure.storage(), on: 'cardText');
      container = fakes.container();
      keep(container, deckBrowserControllerProvider);
      await pumpEventQueue();
      expect(
        container.read(deckBrowserControllerProvider),
        const DeckBrowserState.storageError(),
      );
    });

    test('closing before the load finishes is safe', () async {
      final container = fakes.container();
      keep(container, deckBrowserControllerProvider);
      container.dispose();
      await pumpEventQueue();
    });
  });

  group('CardDetailController (S17)', () {
    const args = CardDetailArgs(
      cardId: CardId('cups_03'),
      origin: LearnCardOrigin.search,
    );

    test('upright with drawn count, position and prev/next; reversed; '
        'zoomed', () async {
      fakes.journal.putDailyCard(aDailyCard().withCard('cups_03').build());
      final container = fakes.container();
      expect(
        keep(container, cardDetailControllerProvider(args)),
        const CardDetailState.loading(),
      );
      await pumpEventQueue();
      final state = container.read(cardDetailControllerProvider(args));
      final view = (state as CardDetailUpright).view;
      expect(view.drawnCount, 1);
      expect(view.position, 3);
      expect(view.sectionSize, 14);
      expect(view.previous, const CardId('cups_02'));
      expect(view.next, const CardId('cups_04'));
      final controller = container.read(
        cardDetailControllerProvider(args).notifier,
      );
      await controller.setReversed(reversed: true);
      await controller.setReversed(reversed: true);
      expect(
        container.read(cardDetailControllerProvider(args)),
        isA<CardDetailReversed>(),
      );
      controller.zoom();
      expect(
        container.read(cardDetailControllerProvider(args)),
        CardDetailState.zoomed(view, reversed: true),
      );
      controller.closeZoom();
      expect(
        container.read(cardDetailControllerProvider(args)),
        isA<CardDetailReversed>(),
      );
      expect(fakes.analytics.events.map((e) => e.parameters), [
        {'card_id': 'cups_03', 'orientation': 'upright', 'origin': 'search'},
        {'card_id': 'cups_03', 'orientation': 'reversed', 'origin': 'search'},
      ]);
      fakes.journal.putReading(aReading().withSpread('single').build());
      fakes.journal.putDailyCard(
        aDailyCard().on('2026-09-22').withCard('cups_03').build(),
      );
      await pumpEventQueue();
      final updated = container.read(cardDetailControllerProvider(args));
      expect((updated as CardDetailReversed).view.drawnCount, 2);
    });

    test('the first and last cards have no previous / next', () async {
      final container = fakes.container();
      const first = CardDetailArgs(cardId: CardId('major_00'));
      const last = CardDetailArgs(cardId: CardId('pentacles_14'));
      keep(container, cardDetailControllerProvider(first));
      keep(container, cardDetailControllerProvider(last));
      await pumpEventQueue();
      final a = container.read(cardDetailControllerProvider(first));
      final b = container.read(cardDetailControllerProvider(last));
      expect((a as CardDetailUpright).view.previous, isNull);
      expect((b as CardDetailUpright).view.next, isNull);
      expect(a.view.sectionSize, 22);
    });

    test('toggles before load do nothing', () async {
      final container = fakes.container();
      keep(container, cardDetailControllerProvider(args));
      final controller = container.read(
        cardDetailControllerProvider(args).notifier,
      );
      await controller.setReversed(reversed: true);
      controller.zoom();
      expect(
        container.read(cardDetailControllerProvider(args)),
        const CardDetailState.loading(),
      );
    });

    test('missing deck card or text is a storage error', () async {
      fakes.content.failNext(const Failure.storage(), on: 'deck');
      var container = fakes.container();
      keep(container, cardDetailControllerProvider(args));
      await pumpEventQueue();
      expect(
        container.read(cardDetailControllerProvider(args)),
        const CardDetailState.storageError(),
      );
      container.dispose();
      fakes.content.failNext(const Failure.storage(), on: 'cardText');
      container = fakes.container();
      keep(container, cardDetailControllerProvider(args));
      await pumpEventQueue();
      expect(
        container.read(cardDetailControllerProvider(args)),
        const CardDetailState.storageError(),
      );
    });

    test('closing before the load finishes is safe', () async {
      final container = fakes.container();
      keep(container, cardDetailControllerProvider(args));
      container.dispose();
      await pumpEventQueue();
    });
  });

  group('SpreadGuideController (S18)', () {
    test('the list; disabled spreads are not startable; select logs', () async {
      fakes.config.current = aRemoteConfig().withSpreadsEnabled([
        'single',
        'three_ppf',
      ]).build();
      final container = fakes.container();
      final provider = spreadGuideControllerProvider(null);
      expect(keep(container, provider), const SpreadGuideState.loading());
      await pumpEventQueue();
      final content = container.read(provider) as SpreadGuideContent;
      expect(content.spreads, hasLength(6));
      expect(
        content.spreads.where((e) => e.startable).map((e) => e.spread.id.value),
        ['single', 'three_ppf'],
      );
      expect(content.selected, isNull);
      final controller = container.read(provider.notifier);
      await controller.select(const SpreadId('celtic_cross'));
      expect(
        (container.read(provider) as SpreadGuideContent).selected,
        const SpreadId('celtic_cross'),
      );
      controller.closeDetail();
      expect((container.read(provider) as SpreadGuideContent).selected, isNull);
      fakes.config.current = aRemoteConfig().build();
      await pumpEventQueue();
      expect(
        (container.read(provider) as SpreadGuideContent).spreads.every(
          (e) => e.startable,
        ),
        isTrue,
      );
      expect(fakes.analytics.events.single.parameters, {
        'spread_id': 'celtic_cross',
      });
    });

    test('opened on a spread logs it once loaded', () async {
      final container = fakes.container();
      final provider = spreadGuideControllerProvider(const SpreadId('single'));
      keep(container, provider);
      await pumpEventQueue();
      expect(
        (container.read(provider) as SpreadGuideContent).selected,
        const SpreadId('single'),
      );
      expect(fakes.analytics.events.single.parameters, {'spread_id': 'single'});
    });

    test('a content failure is a storage error', () async {
      fakes.content.failNext(const Failure.storage(), on: 'spreads');
      final container = fakes.container();
      final provider = spreadGuideControllerProvider(null);
      keep(container, provider);
      await pumpEventQueue();
      expect(container.read(provider), const SpreadGuideState.storageError());
    });
  });

  group('AboutController (S19)', () {
    test('content from the bundled article; storage error', () async {
      const article = Article(title: 'About', sections: []);
      final requests = <(ArticleId, String)>[];
      fakes.articles = (id, locale) async {
        requests.add((id, locale));
        return const Result.ok(article);
      };
      var container = fakes.container();
      expect(
        keep(container, aboutControllerProvider),
        const AboutState.loading(),
      );
      await pumpEventQueue();
      expect(
        container.read(aboutControllerProvider),
        const AboutState.content(article),
      );
      expect(requests, [(ArticleId.about, 'en')]);
      container.dispose();
      fakes.articles = (_, _) async => const Result.err(Failure.storage());
      container = fakes.container();
      keep(container, aboutControllerProvider);
      await pumpEventQueue();
      expect(
        container.read(aboutControllerProvider),
        const AboutState.storageError(),
      );
    });
  });
}
