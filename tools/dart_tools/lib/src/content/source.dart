/// Loads `apps/taro/content/source/` into raw (schema-unchecked) values.
///
/// Layout (apps/taro/content/source/README.md): `deck.yaml`,
/// `glossary.yaml`, `crisis/crisis_resources.yaml`,
/// `<locale>/cards/<cardId>.yaml`, `<locale>/spreads.yaml`,
/// `<locale>/articles/{about,faq}.md` and `README.md`. Every other file is
/// reported as unknown; dot-files are ignored.
library;

import 'dart:io';

import 'package:taro_dart_tools/src/content/common.dart';
import 'package:taro_dart_tools/src/content/ids.dart';

/// A Learn article: front matter plus Markdown body.
final class Article {
  /// Creates an article.
  const Article(this.frontMatter, this.body);

  /// Parsed front matter (a mapping when well-formed).
  final Object? frontMatter;

  /// Markdown after the front matter, trimmed.
  final String body;
}

/// Splits `---\n<yaml>\n---\n<body>`; throws a [ContentFormatException]
/// when the front matter block is missing or unterminated.
Article parseArticle(String text, String path) {
  final normalized = text.replaceAll('\r\n', '\n');
  if (!normalized.startsWith('---\n')) {
    throw ContentFormatException(path, 'missing front matter ("---" first)');
  }
  final end = normalized.indexOf('\n---\n', 3);
  if (end < 0) {
    throw ContentFormatException(path, 'unterminated front matter');
  }
  final yaml = normalized.substring(4, end);
  final body = normalized.substring(end + 5).trim();
  return Article(parseYaml(yaml, path), body);
}

/// Everything read from the source folder.
final class ContentSource {
  ContentSource._(this.root);

  /// Loads the source under [root]/[kSourceDir].
  factory ContentSource.load(Directory root) {
    final source = ContentSource._(root);
    final dir = Directory('${root.path}/$kSourceDir');
    if (!dir.existsSync()) {
      source.issues.add(const Issue.error(kSourceDir, 'source folder missing'));
      return source;
    }
    final files = [
      for (final entity in dir.listSync(recursive: true))
        if (entity is File) entity.path.substring(dir.path.length + 1),
    ]..sort();
    for (final rel in files) {
      if (!rel.split('/').any((part) => part.startsWith('.'))) {
        source._loadFile(rel);
      }
    }
    return source;
  }

  /// The repository root.
  final Directory root;

  /// `deck.yaml`, or `null` when absent.
  Object? deck;

  /// Whether `deck.yaml` exists.
  bool hasDeck = false;

  /// `glossary.yaml`, or `null` when absent.
  Object? glossary;

  /// Whether `glossary.yaml` exists.
  bool hasGlossary = false;

  /// `crisis/crisis_resources.yaml`, or `null` when absent.
  Object? crisis;

  /// Whether the crisis file exists.
  bool hasCrisis = false;

  /// Card files: locale → card ID → parsed YAML.
  final Map<String, Map<String, Object?>> cards = {};

  /// Spread files: locale → parsed YAML.
  final Map<String, Object?> spreads = {};

  /// Articles: locale → article ID → article.
  final Map<String, Map<String, Article>> articles = {};

  /// Load problems (unknown files, parse errors).
  final List<Issue> issues = [];

  static final RegExp _card = RegExp(r'^([a-z]{2})/cards/([a-z0-9_]+)\.yaml$');
  static final RegExp _spreads = RegExp(r'^([a-z]{2})/spreads\.yaml$');
  static final RegExp _article = RegExp(r'^([a-z]{2})/articles/([a-z]+)\.md$');

  void _loadFile(String rel) {
    final path = '$kSourceDir/$rel';
    try {
      if (rel == 'README.md') return;
      if (rel == 'deck.yaml') {
        hasDeck = true;
        deck = readYaml(root, path);
        return;
      }
      if (rel == 'glossary.yaml') {
        hasGlossary = true;
        glossary = readYaml(root, path);
        return;
      }
      if (rel == 'crisis/crisis_resources.yaml') {
        hasCrisis = true;
        crisis = readYaml(root, path);
        return;
      }
      final card = _card.firstMatch(rel);
      if (card != null &&
          kLocales.contains(card[1]) &&
          kCardIds.contains(card[2])) {
        (cards[card[1]!] ??= {})[card[2]!] = readYaml(root, path);
        return;
      }
      final spread = _spreads.firstMatch(rel);
      if (spread != null && kLocales.contains(spread[1])) {
        spreads[spread[1]!] = readYaml(root, path);
        return;
      }
      final article = _article.firstMatch(rel);
      if (article != null &&
          kLocales.contains(article[1]) &&
          kArticleIds.contains(article[2])) {
        final text = File('${root.path}/$path').readAsStringSync();
        (articles[article[1]!] ??= {})[article[2]!] = parseArticle(text, path);
        return;
      }
      issues.add(
        Issue.error(
          path,
          'unknown file (not part of the README layout; check the locale, '
          'card ID or file name)',
        ),
      );
    } on ContentFormatException catch (e) {
      issues.add(Issue.error(e.path, 'cannot parse: ${e.message}'));
    } on FileSystemException catch (e) {
      issues.add(Issue.error(path, 'cannot read: ${e.message}'));
    }
  }
}
