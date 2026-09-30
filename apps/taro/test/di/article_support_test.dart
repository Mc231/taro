import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taro/data/content/content_asset_store.dart';
import 'package:taro/di/article_source.dart';
import 'package:taro/di/providers.dart';
import 'package:taro_core/taro_core.dart';

import '../data/content/disk_asset_bundle.dart';
import '../helpers/pump_app.dart';

final supportLoaderTestProvider =
    Provider<Future<Result<SupportInfo>> Function()>(
      (ref) =>
          () => loadSupportInfo(ref),
    );

const String _markdown = '''
# Frequently asked questions

Intro line one
intro line two.

## Readings

Section text.

### How do free readings work?

Free readings reset at midnight.

- one
- two

### Why declined?

Safety rules.
## Empty section
''';

void main() {
  group('Article.parse', () {
    test('title, sections, entries and blocks', () {
      final article = Article.parse(_markdown);
      expect(article.title, 'Frequently asked questions');
      expect(article.sections, hasLength(3));
      expect(article.sections.first.heading, '');
      expect(article.sections.first.paragraphs, [
        'Intro line one\nintro line two.',
      ]);
      final readings = article.sections[1];
      expect(readings.heading, 'Readings');
      expect(readings.paragraphs, ['Section text.']);
      expect(readings.entries, const [
        ArticleEntry(
          title: 'How do free readings work?',
          paragraphs: ['Free readings reset at midnight.', '- one\n- two'],
        ),
        ArticleEntry(title: 'Why declined?', paragraphs: ['Safety rules.']),
      ]);
      expect(
        article.sections.last,
        const ArticleSection(heading: 'Empty section'),
      );
      expect(Article.parse(_markdown), article);
      expect(Article.parse(_markdown).hashCode, article.hashCode);
      expect(article == const Article(title: 'x', sections: []), isFalse);
      expect(
        readings.entries.first ==
            const ArticleEntry(
              title: 'How do free readings work?',
              paragraphs: [],
            ),
        isFalse,
      );
      expect(readings.hashCode, Article.parse(_markdown).sections[1].hashCode);
    });

    test('an empty document', () {
      expect(Article.parse(''), const Article(title: '', sections: []));
    });
  });

  group('bundledArticleLoader', () {
    ContentAssetStore store([DiskAssetBundle? bundle]) =>
        ContentAssetStore(bundle ?? DiskAssetBundle(), runner: inlineRunner);

    test(
      'loads the bundled FAQ and About; other locales fall back to en',
      () async {
        final load = bundledArticleLoader(store());
        final faq = (await load(ArticleId.faq, 'en')).valueOrNull!;
        expect(faq.title, 'Frequently asked questions');
        expect(faq.sections.expand((s) => s.entries), isNotEmpty);
        final about = (await load(ArticleId.about, 'uk')).valueOrNull!;
        expect(about.title, contains('About'));
      },
    );

    test('a missing bundle is a storage failure', () async {
      final load = bundledArticleLoader(
        store(DiskAssetBundle(missing: {'assets/deck/deck_meta.json'})),
      );
      expect(
        await load(ArticleId.faq, 'en'),
        const Result<Article>.err(Failure.storage()),
      );
    });

    test('parseArticles ignores malformed entries', () {
      expect(parseArticles(const {}), isEmpty);
      expect(
        parseArticles(const {
          'articles': {
            'faq': {'markdown': '# FAQ'},
            'bad': 3,
            'none': <String, Object?>{},
          },
        }),
        {'faq': '# FAQ'},
      );
    });

    test('the provider builds over the root bundle', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(articleLoaderProvider), isA<ArticleLoader>());
    });
  });

  group('SupportInfo (RC43)', () {
    test('the Support ID is the first 8 hex chars of SHA-256(installId)', () {
      expect(
        supportIdOf(const InstallId('abc')),
        'ba7816bf',
      );
    });

    test('loadSupportInfo reads the install, app info and locale', () async {
      final fakes = TaroFakes()..locale = 'uk';
      final container = fakes.container();
      final info = await container.read(supportLoaderTestProvider).call();
      expect(
        info.valueOrNull,
        SupportInfo(
          email: 'support@example.com',
          supportId: supportIdOf(kTestInstallId),
          appVersion: kTestAppVersion,
          buildNumber: kTestBuildNumber,
          platform: AppPlatform.ios,
          osVersion: '18.0',
          locale: 'uk',
        ),
      );
      expect(info.valueOrNull.hashCode, isNot(0));
      expect(
        info.valueOrNull ==
            const SupportInfo(
              email: 'x',
              supportId: 'y',
              appVersion: '1',
              buildNumber: '1',
              platform: AppPlatform.android,
              osVersion: '1',
              locale: 'en',
            ),
        isFalse,
      );
    });
  });
}
