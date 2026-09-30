import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taro/data/content/asset_meaning_repository.dart'
    show kContentFallbackLocale;
import 'package:taro/data/content/content_asset_store.dart';
import 'package:taro/data/content/content_assets.dart';
import 'package:taro/data/content/content_manifest.dart';
import 'package:taro_core/taro_core.dart';

/// The authored articles bundled per locale (`articles` in
/// `assets/deck/<locale>.json`, built by `tools/content build` from
/// `content/source/<locale>/articles/*.md`; 01 §7.9, §11).
enum ArticleId {
  /// S19 "About tarot & Taro".
  about,

  /// S28 "Help & FAQ".
  faq,
}

/// One `###` entry of an article section: a FAQ question and its answer.
@immutable
final class ArticleEntry {
  /// Creates an entry.
  const ArticleEntry({required this.title, required this.paragraphs});

  /// The `###` heading (the question).
  final String title;

  /// The body blocks under it (paragraphs, list items joined per block).
  final List<String> paragraphs;

  @override
  bool operator ==(Object other) =>
      other is ArticleEntry &&
      other.title == title &&
      _listEquals(other.paragraphs, paragraphs);

  @override
  int get hashCode => Object.hash(title, Object.hashAll(paragraphs));
}

/// One `##` section of an article.
@immutable
final class ArticleSection {
  /// Creates a section.
  const ArticleSection({
    required this.heading,
    this.paragraphs = const [],
    this.entries = const [],
  });

  /// The `##` heading (empty for text before the first `##`).
  final String heading;

  /// Body blocks directly under the heading.
  final List<String> paragraphs;

  /// The `###` entries of the section.
  final List<ArticleEntry> entries;

  @override
  bool operator ==(Object other) =>
      other is ArticleSection &&
      other.heading == heading &&
      _listEquals(other.paragraphs, paragraphs) &&
      _listEquals(other.entries, entries);

  @override
  int get hashCode => Object.hash(
    heading,
    Object.hashAll(paragraphs),
    Object.hashAll(entries),
  );
}

/// A parsed article: the `#` title and its sections. The body blocks keep
/// their inline Markdown (`**bold**`, links); the view renders them.
@immutable
final class Article {
  /// Creates an article.
  const Article({required this.title, required this.sections});

  /// Parses the authored Markdown subset: `#` title, `##` sections, `###`
  /// entries; blank lines separate blocks; list lines stay in their block.
  factory Article.parse(String markdown) {
    var title = '';
    final sections = <ArticleSection>[];
    var heading = '';
    var paragraphs = <String>[];
    var entries = <ArticleEntry>[];
    String? entryTitle;
    var entryParagraphs = <String>[];
    final block = <String>[];

    void flushBlock() {
      if (block.isEmpty) return;
      final text = block.join('\n');
      block.clear();
      if (entryTitle != null) {
        entryParagraphs.add(text);
      } else {
        paragraphs.add(text);
      }
    }

    void flushEntry() {
      flushBlock();
      final t = entryTitle;
      if (t == null) return;
      entries.add(
        ArticleEntry(title: t, paragraphs: List.unmodifiable(entryParagraphs)),
      );
      entryTitle = null;
      entryParagraphs = <String>[];
    }

    void flushSection() {
      flushEntry();
      if (heading.isEmpty && paragraphs.isEmpty && entries.isEmpty) return;
      sections.add(
        ArticleSection(
          heading: heading,
          paragraphs: List.unmodifiable(paragraphs),
          entries: List.unmodifiable(entries),
        ),
      );
      paragraphs = <String>[];
      entries = <ArticleEntry>[];
    }

    for (final raw in markdown.split('\n')) {
      final line = raw.trimRight();
      if (line.startsWith('### ')) {
        flushEntry();
        entryTitle = line.substring(4).trim();
      } else if (line.startsWith('## ')) {
        flushSection();
        heading = line.substring(3).trim();
      } else if (line.startsWith('# ')) {
        flushSection();
        title = line.substring(2).trim();
      } else if (line.trim().isEmpty) {
        flushBlock();
      } else {
        block.add(line);
      }
    }
    flushSection();
    return Article(title: title, sections: List.unmodifiable(sections));
  }

  /// The `#` title.
  final String title;

  /// The sections in order.
  final List<ArticleSection> sections;

  @override
  bool operator ==(Object other) =>
      other is Article &&
      other.title == title &&
      _listEquals(other.sections, sections);

  @override
  int get hashCode => Object.hash(title, Object.hashAll(sections));
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// Loads article [id] for the app [locale] (falling back to English).
typedef ArticleLoader =
    Future<Result<Article>> Function(ArticleId id, String locale);

/// The bundled-article loader behind S19 and S28 (offline, no gating).
/// Tests override it with an in-memory loader.
final articleLoaderProvider = Provider<ArticleLoader>(
  (ref) => bundledArticleLoader(ContentAssetStore(rootBundle)),
);

/// An [ArticleLoader] over the checksum-verified content bundle in [store]:
/// `<locale>.json`, else [kContentFallbackLocale]; a missing or corrupt
/// file is a `StorageFailure`.
ArticleLoader bundledArticleLoader(ContentAssetStore store) =>
    (id, locale) async {
      for (final language in {locale, kContentFallbackLocale}) {
        final loaded = await guardContent(
          () => store.parseInBackground(
            ContentAssets.deckTextsFile(language),
            parseArticles,
          ),
        );
        final markdown = loaded.valueOrNull?[id.name];
        if (markdown != null) return Result.ok(Article.parse(markdown));
      }
      return const Result.err(Failure.storage());
    };

/// The `articles.<id>.markdown` strings of a compiled `<locale>.json`.
Map<String, String> parseArticles(Map<String, Object?> json) {
  final articles = json['articles'];
  if (articles is! Map<String, Object?>) return const {};
  return {
    for (final MapEntry(:key, :value) in articles.entries)
      if (value is Map<String, Object?>)
        key: ?ContentJson.opt<String>(value, 'markdown'),
  };
}
