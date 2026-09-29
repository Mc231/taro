/// `tools/content build`: compiles a validated [ContentSource] into the app
/// assets and the Worker feeds (Sprint 5.2; RC25, RC26, RC95).
///
/// Outputs (repository-relative), JSON with sorted keys, 2-space indent and a
/// trailing newline; lists keep the canonical order:
/// * `apps/taro/assets/deck/deck_meta.json`: `id`, `version`, `artSet`,
///   `locales`, `cards[]` (taro_core `DeckCard`), `checksums`;
/// * `apps/taro/assets/deck/<locale>.json` for each complete locale:
///   `locale`, `cards[]` (taro_core `CardText`), `spreads.<id>.whenToUse`,
///   `articles.<id>` (`markdown`, `reviewStatus`, `sourceHash`);
/// * `apps/taro/assets/deck/spreads.json`: taro_core `SpreadDefinition`s;
/// * `apps/taro/assets/deck/crisis_resources.json` and
///   `worker/src/generated/crisis_resources.json`: taro_core
///   `CrisisDirectory` (03 §9.5);
/// * `worker/src/generated/deck/cards.json`, `deck/spreads.json` and
///   `deck_prompt.<locale>.json` (03 §9.2 card context).
library;

import 'dart:io';

import 'package:taro_dart_tools/src/content/common.dart';
import 'package:taro_dart_tools/src/content/ids.dart';
import 'package:taro_dart_tools/src/content/source.dart';
import 'package:taro_dart_tools/src/content/validator.dart';

/// App asset paths.
const String kDeckMetaPath = '$kAppDeckDir/deck_meta.json';

/// App spreads asset.
const String kAppSpreadsPath = '$kAppDeckDir/spreads.json';

/// App crisis asset.
const String kAppCrisisPath = '$kAppDeckDir/crisis_resources.json';

/// Worker card feed.
const String kWorkerCardsPath = '$kWorkerGeneratedDir/deck/cards.json';

/// Worker spreads feed.
const String kWorkerSpreadsPath = '$kWorkerGeneratedDir/deck/spreads.json';

/// Worker crisis feed.
const String kWorkerCrisisPath = '$kWorkerGeneratedDir/crisis_resources.json';

/// The app asset with the texts of [locale].
String appLocalePath(String locale) => '$kAppDeckDir/$locale.json';

/// The Worker prompt feed of [locale].
String workerPromptPath(String locale) =>
    '$kWorkerGeneratedDir/deck_prompt.$locale.json';

/// Every path the build may own (written or deleted).
List<String> ownedPaths() => [
  kDeckMetaPath,
  kAppSpreadsPath,
  kAppCrisisPath,
  kWorkerCardsPath,
  kWorkerSpreadsPath,
  kWorkerCrisisPath,
  for (final l in kLocales) ...[appLocalePath(l), workerPromptPath(l)],
];

Map<String, Object?> _m(Object? v) => v! as Map<String, Object?>;
List<Object?> _l(Object? v) => v! as List<Object?>;

/// Compiles [source] (which must have passed [validate]) into
/// path → file content for [locales]. Paths the build owns that are not in
/// the result are stale and get deleted.
Map<String, String> compile(ContentSource source, List<String> locales) {
  final deck = _m(source.deck);
  final version = deck['version']! as int;
  final enCards = source.cards[kSourceLocale]!;
  final deckCards = [
    for (final id in kCardIds)
      {
        'id': id,
        'arcana': arcanaOf(id),
        'suit': suitOf(id),
        'number': numberOf(id),
        'element': _m(enCards[id])['element'],
        'astrology': _m(enCards[id])['astrology'],
        'artKey': id,
      },
  ];
  final enSpreads = _l(_m(source.spreads[kSourceLocale])['spreads']);
  final out = <String, String>{};

  final crisis = canonicalJson(_crisis(_m(source.crisis)));
  out[kAppCrisisPath] = crisis;
  out[kWorkerCrisisPath] = crisis;

  out[kAppSpreadsPath] = canonicalJson({
    'spreads': [
      for (final raw in enSpreads)
        {
          'id': _m(raw)['id'],
          'version': _m(raw)['version'],
          'allowsReversals': _m(raw)['allowsReversals'],
          'questionSuggestionKeys': _m(raw)['questionSuggestionKeys'],
          'positions': [
            for (final (i, p) in _l(_m(raw)['positions']).indexed)
              {
                'id': _m(p)['id'],
                'order': i + 1,
                'x': (_m(p)['x']! as num).toDouble(),
                'y': (_m(p)['y']! as num).toDouble(),
                'rotationDeg': ((_m(p)['rotationDeg'] ?? 0) as num).toDouble(),
              },
          ],
        },
    ],
  });

  out[kWorkerSpreadsPath] = canonicalJson({
    'version': version,
    'spreads': [
      for (final raw in enSpreads)
        {
          'id': _m(raw)['id'],
          'version': _m(raw)['version'],
          'allowsReversals': _m(raw)['allowsReversals'],
          'positions': [
            for (final (i, p) in _l(_m(raw)['positions']).indexed)
              {'id': _m(p)['id'], 'order': i + 1, 'meaning': _m(p)['meaning']},
          ],
        },
    ],
  });

  out[kWorkerCardsPath] = canonicalJson({
    'deckId': deck['id'],
    'version': version,
    'cards': [
      for (final card in deckCards)
        {
          ...card,
          'name': _m(enCards[card['id']])['name'],
          'keywordsUpright': _m(enCards[card['id']])['keywordsUpright'],
          'keywordsReversed': _m(enCards[card['id']])['keywordsReversed'],
        },
    ],
  });

  final checksums = <String, String>{
    'spreads.json': sha256Hex(out[kAppSpreadsPath]!),
    'crisis_resources.json': sha256Hex(crisis),
  };
  for (final locale in locales) {
    final texts = _localeTexts(source, locale);
    out[appLocalePath(locale)] = texts;
    checksums['$locale.json'] = sha256Hex(texts);
    out[workerPromptPath(locale)] = canonicalJson({
      'locale': locale,
      'version': version,
      'cards': {
        for (final id in kCardIds)
          id: {
            for (final k in const [
              'name',
              'keywordsUpright',
              'keywordsReversed',
              'shortUpright',
              'shortReversed',
            ])
              k: _m(source.cards[locale]![id])[k],
          },
      },
    });
  }

  out[kDeckMetaPath] = canonicalJson({
    'id': deck['id'],
    'version': version,
    'artSet': deck['artSet'],
    'locales': locales,
    'cards': deckCards,
    'checksums': checksums,
  });
  return out;
}

String _localeTexts(ContentSource source, String locale) {
  final isEn = locale == kSourceLocale;
  final enCards = source.cards[kSourceLocale]!;
  final spreads = _m(source.spreads[locale]);
  final enSpreads = _m(source.spreads[kSourceLocale]);
  final whenToUse = isEn
      ? {
          for (final s in _l(enSpreads['spreads']))
            '${_m(s)['id']}': _m(s)['whenToUse'],
        }
      : _m(spreads['whenToUse']);
  return canonicalJson({
    'locale': locale,
    'cards': [
      for (final id in kCardIds)
        () {
          final card = _m(source.cards[locale]![id]);
          return {
            'cardId': id,
            'locale': locale,
            for (final k in kCardTextKeys) k: card[k],
            'sourceHash': isEn
                ? cardSourceHash(_m(enCards[id]))
                : card['sourceHash'],
            'reviewStatus': card['reviewStatus'],
          };
        }(),
    ],
    'spreads': {
      for (final id in kSpreadPositions.keys) id: {'whenToUse': whenToUse[id]},
    },
    'articles': {
      for (final id in kArticleIds)
        id: () {
          final article = source.articles[locale]![id]!;
          final front = _m(article.frontMatter);
          return {
            'markdown': article.body,
            'reviewStatus': front['reviewStatus'],
            'sourceHash': isEn
                ? articleSourceHash(article.body)
                : front['sourceHash'],
          };
        }(),
    },
  });
}

Map<String, Object?> _resource(Object? raw) {
  final e = _m(raw);
  return {
    'name': e['name'],
    for (final k in const ['phone', 'sms', 'url', 'hours'])
      if (e[k] != null) k: e[k],
    'languages': e['languages'],
    'verifiedAt': e['verifiedAt'],
  };
}

Map<String, Object?> _crisis(Map<String, Object?> crisis) => {
  'countries': {
    for (final MapEntry(key: code, value: list) in _m(
      crisis['countries'],
    ).entries)
      code: [for (final e in _l(list)) _resource(e)],
  },
  'localeFallback': {
    for (final locale in kLocales) locale: _m(crisis['localeFallback'])[locale],
  },
  'international': [
    for (final e in _l(crisis['international'])) _resource(e),
  ],
};

/// The difference between the generated files and the repository.
final class BuildPlan {
  /// Creates a plan.
  BuildPlan(this.write, this.delete, this.unchanged);

  /// Files to create or overwrite.
  final Map<String, String> write;

  /// Owned files that are no longer generated.
  final List<String> delete;

  /// Files already up to date.
  final List<String> unchanged;

  /// Whether the repository already matches.
  bool get isClean => write.isEmpty && delete.isEmpty;
}

/// Compares [generated] with the files under [root].
BuildPlan plan(Directory root, Map<String, String> generated) {
  final write = <String, String>{};
  final unchanged = <String>[];
  for (final MapEntry(key: path, value: content) in generated.entries) {
    final file = File('${root.path}/$path');
    if (file.existsSync() && file.readAsStringSync() == content) {
      unchanged.add(path);
    } else {
      write[path] = content;
    }
  }
  final delete = [
    for (final path in ownedPaths())
      if (!generated.containsKey(path) &&
          File('${root.path}/$path').existsSync())
        path,
  ];
  return BuildPlan(write, delete, unchanged);
}

/// Applies [buildPlan] to [root].
void apply(Directory root, BuildPlan buildPlan) {
  for (final MapEntry(key: path, value: content) in buildPlan.write.entries) {
    File('${root.path}/$path')
      ..parent.createSync(recursive: true)
      ..writeAsStringSync(content);
  }
  for (final path in buildPlan.delete) {
    File('${root.path}/$path').deleteSync();
  }
}
