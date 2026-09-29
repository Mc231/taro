// Programmatic fixture repositories for the tools/content tests: a valid
// source tree (78 en cards, spreads, articles, glossary, crisis) that each
// test mutates to hit one failure mode.
import 'dart:io';

import 'package:taro_dart_tools/content.dart';

/// The real repository (for banned_phrases.yaml / required_sentences.yaml).
final Directory realRepo = findRepoRoot(Directory.current)!;

/// A fixed "today" for crisis checks.
final DateTime fixtureToday = DateTime.utc(2026, 9, 29);

const _en = [
  'quiet', 'river', 'light', 'morning', 'notice', 'gentle', 'path', //
  'reflect', 'open', 'calm', 'steady', 'window', 'garden', 'consider',
  'rhythm', 'patience',
];
const _de = [
  'ruhig', 'Fluss', 'Licht', 'Morgen', 'sanft', 'Weg', 'offen', 'Garten', //
];
const _ar = ['هدوء', 'نهر', 'ضوء', 'صباح', 'طريق', 'حديقة'];

/// [n] filler words in [locale], ending with a full stop.
String words(int n, {String locale = 'en', int seed = 0}) {
  final pool = switch (locale) {
    'de' => _de,
    'ar' => _ar,
    _ => _en,
  };
  if (locale == 'ja') return '${'静かな川の光' * (n ~/ 4 + 1)}。';
  final list = [for (var i = 0; i < n; i++) pool[(i + seed) % pool.length]];
  return '${list.join(' ')}.';
}

/// The glossary name of [id] in [locale].
String cardName(String id, String locale) => switch (locale) {
  'en' => 'Card $id',
  'ar' => 'بطاقة $id',
  'ja' => 'カード$id',
  _ => 'Karte $id',
};

String _q(String locale) => switch (locale) {
  'ar' => '؟',
  'ja' => '？',
  _ => '?',
};

List<String> _keywords(String locale, String prefix) => switch (locale) {
  'ar' => ['كلمة $prefix', 'نور $prefix', 'درب $prefix'],
  'ja' => ['光$prefix', '川$prefix', '道$prefix'],
  'de' => ['Licht $prefix', 'Weg $prefix', 'Ruhe $prefix'],
  _ => ['light $prefix', 'path $prefix', 'calm $prefix'],
};

String _question(String locale, int seed) => locale == 'ja'
    ? '何'
    : words(6, locale: locale, seed: seed).replaceAll('.', '');

/// A valid card text map (without cardId/reviewStatus/hash).
Map<String, Object?> cardTexts(String id, String locale) {
  String prose(int n, int seed) => words(n, locale: locale, seed: seed);
  final short = locale == 'ja' ? '静かな光$id' : prose(8, 1);
  return {
    'name': cardName(id, locale),
    'keywordsUpright': _keywords(locale, 'up'),
    'keywordsReversed': _keywords(locale, 'rev'),
    'shortUpright': short,
    'shortReversed': short,
    'meaningUpright': '${prose(80, 2)}\n\n${prose(80, 3)}',
    'meaningReversed': prose(150, 4),
    'aspects': {for (final k in kAspectKeys) k: prose(60, k.length)},
    'reflectionQuestions': [
      for (var i = 0; i < 3; i++) '${_question(locale, i)}${_q(locale)}',
    ],
    'imageryNote': prose(60, 5),
  };
}

/// A valid en card document.
Map<String, Object?> enCard(String id) => {
  'cardId': id,
  'reviewStatus': 'machine',
  if (suitOf(id) != null) 'element': kSuitElements[suitOf(id)],
  if (id == 'major_00') 'astrology': 'uranus',
  ...cardTexts(id, 'en'),
};

/// A valid translation of [id] into [locale], made from [en].
Map<String, Object?> translatedCard(
  String id,
  String locale,
  Map<String, Object?> en,
) => {
  'cardId': id,
  'reviewStatus': 'machine',
  'sourceHash': cardSourceHash(en),
  ...cardTexts(id, locale),
};

/// The en spreads document.
Map<String, Object?> enSpreads() => {
  'reviewStatus': 'machine',
  'spreads': [
    for (final MapEntry(key: id, value: positions) in kSpreadPositions.entries)
      {
        'id': id,
        'version': 1,
        'allowsReversals': true,
        'questionSuggestionKeys': [
          for (var n = 1; n <= 3; n++) 'spread_${id}_suggestion_$n',
        ],
        'whenToUse': words(20, seed: id.length),
        'positions': [
          for (final (i, p) in positions.indexed)
            {
              'id': p,
              'x': (i + 1) / (positions.length + 1),
              'y': 0.5,
              if (p == 'challenge' && id == 'celtic_cross') 'rotationDeg': 90,
              'meaning': words(8, seed: i),
            },
        ],
      },
  ],
};

/// A translated spreads document.
Map<String, Object?> translatedSpreads(
  String locale,
  Map<String, Object?> en,
) => {
  'reviewStatus': 'machine',
  'sourceHash': spreadsSourceHash(en),
  'whenToUse': {
    for (final id in kSpreadPositions.keys)
      id: words(20, locale: locale, seed: id.length),
  },
};

/// A valid article body.
String articleBody(String id, {String locale = 'en'}) =>
    '# ${locale == 'en' ? 'About $id' : '$id ${cardName('x', locale)}'}\n\n'
    '${words(120, locale: locale)}\n\n- ${words(5, locale: locale)}\n';

/// An article file.
String articleFile(String body, {String? sourceHash}) =>
    '---\nreviewStatus: machine\n'
    '${sourceHash == null ? '' : 'sourceHash: $sourceHash\n'}'
    '---\n$body';

/// A crisis entry.
Map<String, Object?> crisisEntry(String name, {Object? verifiedAt}) => {
  'name': name,
  'phone': '+1 (555) 010-0000',
  'url': 'https://example.org/help',
  'hours': '24/7',
  'languages': ['en'],
  'verifiedAt': verifiedAt,
};

/// The crisis document.
Map<String, Object?> crisisDoc({Object? verifiedAt}) => {
  'localeFallback': {
    for (final l in kLocales) l: l == 'ar' ? null : (l == 'en' ? 'US' : 'DE'),
  },
  'countries': {
    for (final c in kRequiredCrisisCountries)
      c: [crisisEntry('Line $c', verifiedAt: verifiedAt)],
  },
  'international': [
    {
      'name': 'Find A Helpline',
      'url': 'https://findahelpline.com',
      'languages': <String>[],
      'verifiedAt': verifiedAt,
    },
  ],
};

/// The glossary document with en and [locales] names.
Map<String, Object?> glossaryDoc({
  List<String> locales = const [],
  Map<String, String> review = const {},
}) {
  Map<String, String> names(String en, String Function(String) other) => {
    'en': en,
    for (final l in locales) l: other(l),
  };
  return {
    'review': {'en': 'reviewed', ...review},
    'cards': {
      for (final id in kCardIds)
        id: {
          'en': cardName(id, 'en'),
          for (final l in locales) l: cardName(id, l),
        },
    },
    'suits': {
      for (final s in kSuitElements.keys) s: names(s, (l) => '$s $l'),
    },
    'arcana': {
      'major': names('Major Arcana', (l) => 'major $l'),
      'minor': names('Minor Arcana', (l) => 'minor $l'),
    },
    'positions': {
      for (final p in kPositionIds) p: names(p, (l) => '$p $l'),
    },
    'terms': {
      'upright': names('Upright', (l) => 'upright $l'),
    },
  };
}

/// A fixture repository in a temp directory.
final class FixtureRepo {
  FixtureRepo._(this.root);

  /// Creates a valid repository with en content and [locales] translations.
  factory FixtureRepo.create({
    List<String> locales = const [],
    Object? verifiedAt = '2026-09-01',
  }) {
    final root = Directory.systemTemp.createTempSync('taro_content_');
    final repo = FixtureRepo._(root);
    Directory('${root.path}/docs/specs').createSync(recursive: true);
    for (final path in [kBannedPhrasesPath, kRequiredSentencesPath]) {
      repo.write(path, File('${realRepo.path}/$path').readAsStringSync());
    }
    repo
      ..writeYaml('$kSourceDir/deck.yaml', {
        'id': 'rws_original',
        'version': 1,
        'artSet': 'placeholder',
      })
      ..writeYaml(
        '$kSourceDir/glossary.yaml',
        glossaryDoc(
          locales: locales,
          review: {for (final l in locales) l: 'reviewed'},
        ),
      )
      ..writeYaml(
        '$kSourceDir/crisis/crisis_resources.yaml',
        crisisDoc(verifiedAt: verifiedAt),
      );
    final spreads = enSpreads();
    repo.writeYaml('$kSourceDir/en/spreads.yaml', spreads);
    for (final id in kCardIds) {
      final en = enCard(id);
      repo.writeYaml(repo.cardPath('en', id), en);
      for (final l in locales) {
        repo.writeYaml(repo.cardPath(l, id), translatedCard(id, l, en));
      }
    }
    for (final a in kArticleIds) {
      final body = articleBody(a);
      repo.write('$kSourceDir/en/articles/$a.md', articleFile(body));
      for (final l in locales) {
        repo.write(
          '$kSourceDir/$l/articles/$a.md',
          articleFile(
            articleBody(a, locale: l),
            sourceHash: articleSourceHash(body.trim()),
          ),
        );
      }
    }
    for (final l in locales) {
      repo.writeYaml(
        '$kSourceDir/$l/spreads.yaml',
        translatedSpreads(l, spreads),
      );
    }
    return repo;
  }

  /// The temp root.
  final Directory root;

  /// Path of a card file.
  String cardPath(String locale, String id) =>
      '$kSourceDir/$locale/cards/$id.yaml';

  /// Writes [content] to [path].
  void write(String path, String content) => File('${root.path}/$path')
    ..parent.createSync(recursive: true)
    ..writeAsStringSync(content);

  /// Writes [doc] as YAML.
  void writeYaml(String path, Map<String, Object?> doc) =>
      write(path, toYaml(doc));

  /// Reads a file.
  String read(String path) => File('${root.path}/$path').readAsStringSync();

  /// Deletes a file.
  void delete(String path) => File('${root.path}/$path').deleteSync();

  /// Loads a YAML file as a map.
  Map<String, Object?> readYamlMap(String path) =>
      readYaml(root, path)! as Map<String, Object?>;

  /// Rewrites the YAML map at [path] through [edit].
  void edit(String path, void Function(Map<String, Object?> doc) edit) {
    final doc = readYamlMap(path);
    edit(doc);
    writeYaml(path, doc);
  }

  /// Removes the temp directory.
  void dispose() => root.deleteSync(recursive: true);
}

/// Output of one command run.
typedef RunResult = ({int code, String out, String err});

/// Runs a sync command against [repo].
RunResult run(
  int Function(List<String>, {ContentIo? io}) command,
  FixtureRepo repo, [
  List<String> args = const [],
]) {
  final out = StringBuffer();
  final err = StringBuffer();
  final code = command(
    ['--repo-root', repo.root.path, ...args],
    io: ContentIo(out: out, err: err, clock: () => fixtureToday),
  );
  return (code: code, out: out.toString(), err: err.toString());
}
