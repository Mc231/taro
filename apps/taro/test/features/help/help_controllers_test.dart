import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taro/app_state/crisis_handoff.dart';
import 'package:taro/di/providers.dart';
import 'package:taro/features/help/controller/crisis_resources_controller.dart';
import 'package:taro/features/help/controller/faq_controller.dart';
import 'package:taro_core/taro_core.dart';

import '../../helpers/pump_app.dart';

const Article _faq = Article(
  title: 'FAQ',
  sections: [
    ArticleSection(
      heading: 'Readings',
      entries: [
        ArticleEntry(
          title: 'How do free readings work?',
          paragraphs: ['Daily.'],
        ),
        ArticleEntry(title: 'Why declined?', paragraphs: ['Safety rules.']),
      ],
    ),
    ArticleSection(
      heading: 'Purchases',
      entries: [
        ArticleEntry(
          title: 'Can I restore readings?',
          paragraphs: ['Move readings with a transfer code.'],
        ),
      ],
    ),
  ],
);

void main() {
  late TaroFakes fakes;

  setUp(() => fakes = TaroFakes());

  group('CrisisResourcesController (S27)', () {
    ProviderContainer open(String? region, CrisisResourcesOrigin origin) {
      final container = fakes.container(
        extra: [crisisRegionProvider.overrideWithValue(region)],
      )..listen(crisisResourcesControllerProvider(origin), (_, _) {});
      return container;
    }

    test('the device region picks local lines (never sent); another '
        'country; viewed event', () async {
      final container = open('de', CrisisResourcesOrigin.reading);
      final provider = crisisResourcesControllerProvider(
        CrisisResourcesOrigin.reading,
      );
      expect(container.read(provider), const CrisisResourcesState.loading());
      await pumpEventQueue();
      final content = container.read(provider) as CrisisResourcesContent;
      expect(content.country, 'DE');
      expect(content.hasLocalLines, isTrue);
      expect(content.resources.length, lessThanOrEqualTo(3));
      expect(content.countries, contains('DE'));
      expect(fakes.analytics.events.single.parameters, {'origin': 'reading'});
      container.read(provider.notifier).chooseCountry('zz');
      final other = container.read(provider) as CrisisResourcesContent;
      expect(other.country, 'ZZ');
      expect(other.hasLocalLines, isFalse);
    });

    test(
      'no region falls back to the locale, else international only',
      () async {
        final container = open(null, CrisisResourcesOrigin.help);
        await pumpEventQueue();
        final content =
            container.read(
                  crisisResourcesControllerProvider(CrisisResourcesOrigin.help),
                )
                as CrisisResourcesContent;
        expect(content.country, isNull);
        expect(content.resources, isNotEmpty);
      },
    );

    test('from a reading: the Worker lines first, then international; '
        'another country switches to the bundle', () async {
      final container = open('DE', CrisisResourcesOrigin.reading);
      final worker = aCrisisResource(name: 'Samaritans', phone: '116 123');
      container.read(crisisHandoffProvider.notifier).offer([
        worker,
        aCrisisResource(name: 'Shout', phone: null).copyWith(sms: '85258'),
        aCrisisResource(name: 'Third', phone: '1'),
      ]);
      final provider = crisisResourcesControllerProvider(
        CrisisResourcesOrigin.reading,
      );
      await pumpEventQueue();
      final content = container.read(provider) as CrisisResourcesContent;
      expect(content.country, isNull);
      expect(content.hasLocalLines, isTrue);
      expect(content.resources.map((r) => r.name), [
        'Samaritans',
        'Shout',
        'Find A Helpline',
      ]);
      container.read(provider.notifier).chooseCountry('us');
      final other = container.read(provider) as CrisisResourcesContent;
      expect(other.resources.first.name, '988 Lifeline');
    });

    test('from Help: the Worker lines are ignored', () async {
      final container = open('DE', CrisisResourcesOrigin.help);
      container.read(crisisHandoffProvider.notifier).offer([
        aCrisisResource(name: 'Samaritans', phone: '116 123'),
      ]);
      await pumpEventQueue();
      final content =
          container.read(
                crisisResourcesControllerProvider(CrisisResourcesOrigin.help),
              )
              as CrisisResourcesContent;
      expect(content.country, 'DE');
      expect(
        content.resources.map((r) => r.name),
        isNot(contains('Samaritans')),
      );
    });

    test('a broken bundle is a storage error', () async {
      fakes.crisis.failNext(const Failure.storage(), on: 'directory');
      final container = open('DE', CrisisResourcesOrigin.settings);
      await pumpEventQueue();
      expect(
        container.read(
          crisisResourcesControllerProvider(CrisisResourcesOrigin.settings),
        ),
        const CrisisResourcesState.storageError(),
      );
      expect(fakes.analytics.events, isEmpty);
    });

    test('the default region comes from the platform locale', () {
      final container = fakes.container();
      expect(
        () => container.read(crisisRegionProvider),
        returnsNormally,
      );
    });
  });

  group('FaqController (S28)', () {
    ProviderContainer open([Result<Article> article = const Result.ok(_faq)]) {
      fakes.articles = (_, _) async => article;
      return fakes.container()..listen(faqControllerProvider, (_, _) {});
    }

    test(
      'content with the Support ID card; expand; search; searchEmpty',
      () async {
        final container = open();
        expect(container.read(faqControllerProvider), const FaqState.loading());
        await pumpEventQueue();
        final content = container.read(faqControllerProvider) as FaqContent;
        expect(content.sections, _faq.sections);
        expect(content.support?.supportId, supportIdOf(kTestInstallId));
        expect(content.support?.email, 'support@example.com');
        final controller = container.read(faqControllerProvider.notifier)
          ..toggle('Why declined?');
        expect(
          (container.read(faqControllerProvider) as FaqContent).expanded,
          {'Why declined?'},
        );
        controller.toggle('Why declined?');
        expect(
          (container.read(faqControllerProvider) as FaqContent).expanded,
          isEmpty,
        );
        controller.search('TRANSFER');
        final hits = container.read(faqControllerProvider) as FaqContent;
        expect(hits.sections.single.heading, 'Purchases');
        expect(hits.query, 'TRANSFER');
        controller.search('nothing matches');
        expect(
          container.read(faqControllerProvider),
          isA<FaqSearchEmpty>().having((s) => s.support, 'support', isNotNull),
        );
      },
    );

    test('a missing article is a storage error', () async {
      final container = open(const Result.err(Failure.storage()));
      await pumpEventQueue();
      expect(
        container.read(faqControllerProvider),
        const FaqState.storageError(),
      );
    });

    test('an unknown install leaves the support card empty', () async {
      fakes.install.failNext(const Failure.storage(), on: 'getOrCreate');
      final container = open();
      await pumpEventQueue();
      expect(
        (container.read(faqControllerProvider) as FaqContent).support,
        isNull,
      );
    });

    test('closing before the load finishes is safe', () async {
      open().dispose();
      await pumpEventQueue();
    });
  });
}
