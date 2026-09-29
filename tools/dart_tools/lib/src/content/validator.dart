/// `tools/content validate`: every rule of Sprint 5.2 over a loaded
/// [ContentSource] (schemas in `tools/content/schema/`, prose rules in
/// apps/taro/content/source/README.md).
library;

import 'package:taro_dart_tools/src/content/banned.dart';
import 'package:taro_dart_tools/src/content/common.dart';
import 'package:taro_dart_tools/src/content/ids.dart';
import 'package:taro_dart_tools/src/content/source.dart';
import 'package:taro_dart_tools/src/content/text_rules.dart';

/// The two `reviewStatus` values (taro_core `ReviewStatus`).
const List<String> kReviewStatuses = ['machine', 'reviewed'];

/// Aspect keys of a card, in schema order.
const List<String> kAspectKeys = [
  'relationshipsUpright',
  'relationshipsReversed',
  'workUpright',
  'workReversed',
  'growthUpright',
  'growthReversed',
];

/// The translatable card fields (the input of the card `sourceHash`).
const List<String> kCardTextKeys = [
  'name',
  'keywordsUpright',
  'keywordsReversed',
  'shortUpright',
  'shortReversed',
  'meaningUpright',
  'meaningReversed',
  'aspects',
  'reflectionQuestions',
  'imageryNote',
];

/// Word bounds of the prose card fields (01 §10.1).
const Map<String, (int, int)> kCardWordBounds = {
  'meaningUpright': (120, 220),
  'meaningReversed': (100, 200),
  'imageryNote': (40, 100),
};

/// Word bounds of every aspect text.
const (int, int) kAspectWords = (40, 90);

/// Word bounds of `whenToUse`.
const (int, int) kWhenToUseWords = (15, 80);

/// Word bounds of a position `meaning` (en only).
const (int, int) kPositionMeaningWords = (5, 40);

/// Word bounds of an article body.
const (int, int) kArticleWords = (100, 3000);

/// Maximum crisis-entry age in days for a release (03 §9.5, BE Q3).
const int kCrisisMaxAgeDays = 200;

/// The `sourceHash` of an en card: SHA-256 of the compact sorted JSON of
/// its [kCardTextKeys].
String cardSourceHash(Map<String, Object?> enCard) => sha256Hex(
  compactJson({
    for (final k in kCardTextKeys)
      if (enCard.containsKey(k)) k: enCard[k],
  }),
);

/// The `sourceHash` of `en/spreads.yaml`: the `whenToUse` text per spread.
String spreadsSourceHash(Map<String, Object?> enSpreads) {
  final list = enSpreads['spreads'];
  return sha256Hex(
    compactJson({
      if (list is List)
        for (final s in list.whereType<Map<String, Object?>>())
          '${s['id']}': s['whenToUse'],
    }),
  );
}

/// The `sourceHash` of an en article: SHA-256 of its body.
String articleSourceHash(String body) => sha256Hex(body);

/// The outcome of a validation run.
final class ValidationResult {
  /// Creates a result.
  ValidationResult(this.issues, this.completeLocales);

  /// Every issue, errors and reports, in discovery order.
  final List<Issue> issues;

  /// Locales whose cards, spreads and articles are all present and valid
  /// (the locales `build` compiles), in [kLocales] order.
  final List<String> completeLocales;

  /// The errors.
  List<Issue> get errors =>
      issues.where((i) => i.severity == Severity.error).toList();

  /// The report lines.
  List<Issue> get reports =>
      issues.where((i) => i.severity == Severity.report).toList();
}

/// Validation options.
final class ValidateOptions {
  /// Creates options.
  const ValidateOptions({
    required this.today,
    this.release = false,
    this.strictLocales = false,
    this.arbKeys,
  });

  /// The current UTC date (verifiedAt must not be later).
  final DateTime today;

  /// Crisis entries must be verified within [kCrisisMaxAgeDays].
  final bool release;

  /// Missing and stale translations are errors instead of reports.
  final bool strictLocales;

  /// The `app_en.arb` keys, when that file exists (suggestion keys are
  /// reported when missing from it).
  final Set<String>? arbKeys;
}

/// Validates [source] with [banned] phrases.
ValidationResult validate(
  ContentSource source,
  BannedPhrases banned,
  ValidateOptions options,
) => _Validator(source, banned, options).run();

final RegExp _snake = RegExp(r'^[a-z][a-z0-9_]*$');
final RegExp _country = RegExp(r'^[A-Z]{2}$');
final RegExp _phone = RegExp(r'^[0-9+][0-9 ()+-]*$');
final RegExp _url = RegExp(r'^https://\S+$');
final RegExp _language = RegExp(r'^[a-z]{2,3}(-[A-Za-z0-9]{2,8})*$');
final RegExp _date = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$');

final class _Validator {
  _Validator(this.source, this.banned, this.options);

  final ContentSource source;
  final BannedPhrases banned;
  final ValidateOptions options;
  final List<Issue> issues = [];
  final Map<String, String> enCardHashes = {};
  final Set<String> invalidLocales = {};
  Map<String, Map<String, Object?>> glossaryCards = {};
  String? enSpreadsHash;
  final Map<String, String> enArticleHashes = {};

  void error(String path, String message, {String? locale}) {
    issues.add(Issue.error(path, message, locale: locale));
    if (locale != null) invalidLocales.add(locale);
  }

  void report(String path, String message, String locale) {
    issues.add(
      options.strictLocales
          ? Issue.error(path, message, locale: locale)
          : Issue.report(path, message, locale: locale),
    );
  }

  ValidationResult run() {
    issues.addAll(source.issues);
    for (final issue in source.issues) {
      final match = RegExp('^$kSourceDir/([a-z]{2})/').firstMatch(issue.path);
      if (match != null) invalidLocales.add(match[1]!);
    }
    _deck();
    _glossary();
    _cards();
    _spreads();
    _articles();
    _crisis();
    final complete = [
      for (final locale in kLocales)
        if (!invalidLocales.contains(locale) && _isComplete(locale)) locale,
    ];
    return ValidationResult(issues, complete);
  }

  bool _isComplete(String locale) =>
      (source.cards[locale]?.length ?? 0) == kCardIds.length &&
      source.spreads.containsKey(locale) &&
      kArticleIds.every(
        (id) => source.articles[locale]?.containsKey(id) ?? false,
      );

  // --- generic field helpers ---------------------------------------------

  Map<String, Object?>? mapping(Object? value, String path, String what) {
    if (value is Map<String, Object?>) return value;
    error(path, '$what must be a mapping', locale: _localeOf(path));
    return null;
  }

  String? _localeOf(String path) =>
      RegExp('^$kSourceDir/([a-z]{2})/').firstMatch(path)?[1];

  void keys(
    Map<String, Object?> map,
    String path,
    String where, {
    required Set<String> required,
    Set<String> optional = const {},
  }) {
    final locale = _localeOf(path);
    for (final k in required.difference(map.keys.toSet()).toList()..sort()) {
      error(path, '$where: missing key "$k"', locale: locale);
    }
    for (final k in map.keys) {
      if (!required.contains(k) && !optional.contains(k)) {
        error(path, '$where: unknown key "$k"', locale: locale);
      }
    }
  }

  /// Checks one text value; returns it when it is a string.
  String? text(
    Object? value,
    String path,
    String field,
    String locale, {
    required bool singleLine,
    bool plainText = true,
    int? maxChars,
    (int, int)? words,
  }) {
    if (value == null) return null;
    if (value is! String) {
      error(path, '$field must be a string', locale: locale);
      return null;
    }
    for (final p in whitespaceProblems(value, singleLine: singleLine)) {
      error(path, '$field: $p', locale: locale);
    }
    if (plainText) {
      for (final p in markupProblems(value)) {
        error(path, '$field: $p (plain text only)', locale: locale);
      }
    }
    for (final p in bidiProblems(value, locale)) {
      error(path, '$field: $p', locale: locale);
    }
    if (locale == 'ar' && value.trim().isNotEmpty && !hasArabic(value)) {
      error(path, '$field: no Arabic script in an ar text', locale: locale);
    }
    if (maxChars != null && charCount(value) > maxChars) {
      error(
        path,
        '$field: ${charCount(value)} characters, at most $maxChars',
        locale: locale,
      );
    }
    if (words != null) {
      final problem = boundProblem(value, locale, words.$1, words.$2);
      if (problem != null) error(path, '$field: $problem', locale: locale);
    }
    for (final phrase in banned.hits(value, locale)) {
      error(path, '$field: banned phrase "$phrase"', locale: locale);
    }
    return value;
  }

  void reviewStatus(Object? value, String path, String locale) {
    if (value != null && !kReviewStatuses.contains(value)) {
      error(
        path,
        'reviewStatus must be one of ${kReviewStatuses.join(' | ')}, got '
        '"$value"',
        locale: locale,
      );
    }
  }

  void sourceHashField(
    Map<String, Object?> map,
    String path,
    String locale,
    String? current,
    String what,
  ) {
    final hash = map['sourceHash'];
    if (locale == kSourceLocale) {
      if (map.containsKey('sourceHash')) {
        error(path, 'sourceHash must be absent in en', locale: locale);
      }
      return;
    }
    if (hash is! String || !kHashPattern.hasMatch(hash)) {
      if (map.containsKey('sourceHash')) {
        error(path, 'sourceHash must be 64 lowercase hex', locale: locale);
      }
      return;
    }
    if (current != null && hash != current) {
      report(path, 'stale: $what changed since this translation', locale);
    }
  }

  // --- deck.yaml ----------------------------------------------------------

  void _deck() {
    const path = '$kSourceDir/deck.yaml';
    if (!source.hasDeck) {
      error(path, 'missing');
      return;
    }
    final deck = mapping(source.deck, path, 'deck.yaml');
    if (deck == null) return;
    keys(deck, path, 'deck', required: {'id', 'version', 'artSet'});
    for (final k in ['id', 'artSet']) {
      final v = deck[k];
      if (v != null && (v is! String || !_snake.hasMatch(v))) {
        error(path, '$k must be a snake_case string');
      }
    }
    final version = deck['version'];
    if (version != null && (version is! int || version < 1)) {
      error(path, 'version must be an integer >= 1');
    }
  }

  // --- glossary.yaml ------------------------------------------------------

  void _glossary() {
    const path = '$kSourceDir/glossary.yaml';
    if (!source.hasGlossary) {
      error(path, 'missing');
      return;
    }
    final glossary = mapping(source.glossary, path, 'glossary.yaml');
    if (glossary == null) return;
    keys(
      glossary,
      path,
      'glossary',
      required: {'review', 'cards', 'suits', 'arcana', 'positions', 'terms'},
    );
    final review = glossary['review'];
    if (review != null) {
      final map = mapping(review, path, 'review');
      if (map != null) {
        if (!map.containsKey(kSourceLocale)) {
          error(path, 'review: missing en');
        }
        for (final entry in map.entries) {
          if (!kLocales.contains(entry.key)) {
            error(path, 'review: unknown locale "${entry.key}"');
          } else if (!kReviewStatuses.contains(entry.value)) {
            error(path, 'review.${entry.key}: must be machine | reviewed');
          }
        }
      }
    }
    final sections = <String, List<String>?>{
      'cards': kCardIds,
      'suits': kSuitElements.keys.toList(),
      'arcana': const ['major', 'minor'],
      'positions': kPositionIds,
      'terms': null,
    };
    final missing = <String, int>{};
    for (final MapEntry(key: section, value: expected) in sections.entries) {
      final raw = glossary[section];
      if (raw == null) continue;
      final map = mapping(raw, path, section);
      if (map == null) continue;
      if (expected != null) {
        for (final id in expected) {
          if (!map.containsKey(id)) error(path, '$section: missing "$id"');
        }
        for (final id in map.keys) {
          if (!expected.contains(id)) error(path, '$section: unknown "$id"');
        }
      } else {
        for (final id in map.keys) {
          if (!_snake.hasMatch(id)) {
            error(path, '$section: "$id" not snake_case');
          }
        }
      }
      final entries = <String, Map<String, Object?>>{};
      for (final MapEntry(key: id, value: names) in map.entries) {
        if (names is! Map<String, Object?>) {
          error(path, '$section.$id must be a locale → name mapping');
          continue;
        }
        entries[id] = names;
        if (!names.containsKey(kSourceLocale)) {
          error(path, '$section.$id: missing en');
        }
        for (final MapEntry(key: locale, value: name) in names.entries) {
          if (!kLocales.contains(locale)) {
            error(path, '$section.$id: unknown locale "$locale"');
            continue;
          }
          if (name is! String) {
            error(path, '$section.$id.$locale must be a string');
            continue;
          }
          for (final p in [
            ...whitespaceProblems(name, singleLine: true),
            ...markupProblems(name),
            ...bidiProblems(name, locale),
          ]) {
            error(path, '$section.$id.$locale: $p');
          }
          for (final phrase in banned.hits(name, locale)) {
            error(path, '$section.$id.$locale: banned phrase "$phrase"');
          }
        }
        for (final locale in kTargetLocales) {
          if (!names.containsKey(locale)) {
            missing.update(locale, (n) => n + 1, ifAbsent: () => 1);
          }
        }
      }
      if (section == 'cards') glossaryCards = entries;
    }
    for (final locale in kTargetLocales) {
      final n = missing[locale];
      if (n != null) report(path, 'missing: $n $locale glossary names', locale);
    }
  }

  // --- cards --------------------------------------------------------------

  void _cards() {
    final en = source.cards[kSourceLocale] ?? const {};
    for (final id in kCardIds) {
      final path = '$kSourceDir/en/cards/$id.yaml';
      if (!en.containsKey(id)) {
        error(path, 'missing', locale: kSourceLocale);
        continue;
      }
      final card = _card(en[id], path, id, kSourceLocale);
      if (card != null) enCardHashes[id] = cardSourceHash(card);
    }
    for (final locale in kTargetLocales) {
      final cards = source.cards[locale] ?? const {};
      final missing = kCardIds.where((id) => !cards.containsKey(id)).toList();
      for (final id in kCardIds) {
        if (!cards.containsKey(id)) continue;
        _card(cards[id], '$kSourceDir/$locale/cards/$id.yaml', id, locale);
      }
      if (missing.isNotEmpty) {
        final detail = missing.length < kCardIds.length
            ? ' (${_sample(missing)})'
            : '';
        report(
          '$kSourceDir/$locale/cards',
          'missing: ${missing.length} of ${kCardIds.length} cards$detail',
          locale,
        );
      }
    }
  }

  static String _sample(List<String> ids) =>
      ids.length <= 5 ? ids.join(', ') : '${ids.take(5).join(', ')}, …';

  Map<String, Object?>? _card(
    Object? raw,
    String path,
    String id,
    String locale,
  ) {
    final card = mapping(raw, path, 'a card file');
    if (card == null) return null;
    final isEn = locale == kSourceLocale;
    keys(
      card,
      path,
      'card',
      required: {
        'cardId',
        'reviewStatus',
        ...kCardTextKeys,
        if (!isEn) 'sourceHash',
      },
      optional: {
        if (isEn) ...{'element', 'astrology'},
      },
    );
    if (card.containsKey('cardId') && card['cardId'] != id) {
      error(
        path,
        'cardId "${card['cardId']}" differs from the file name',
        locale: locale,
      );
    }
    reviewStatus(card['reviewStatus'], path, locale);
    sourceHashField(card, path, locale, enCardHashes[id], 'the en card');
    if (isEn) _elementAstrology(card, path, id);
    final name = text(card['name'], path, 'name', locale, singleLine: true);
    if (name != null) {
      final expected = glossaryCards[id]?[locale];
      if (expected == null) {
        error(
          path,
          'glossary.yaml has no $locale name for $id',
          locale: locale,
        );
      } else if (expected != name) {
        error(
          path,
          'name "$name" differs from glossary "$expected"',
          locale: locale,
        );
      }
    }
    for (final k in ['keywordsUpright', 'keywordsReversed']) {
      _keywords(card[k], path, k, locale);
    }
    for (final k in ['shortUpright', 'shortReversed']) {
      text(card[k], path, k, locale, singleLine: true, maxChars: 160);
    }
    for (final MapEntry(key: k, value: bounds) in kCardWordBounds.entries) {
      text(card[k], path, k, locale, singleLine: false, words: bounds);
    }
    final aspects = card['aspects'];
    if (aspects != null) {
      final map = mapping(aspects, path, 'aspects');
      if (map != null) {
        keys(map, path, 'aspects', required: kAspectKeys.toSet());
        for (final k in kAspectKeys) {
          text(
            map[k],
            path,
            'aspects.$k',
            locale,
            singleLine: false,
            words: kAspectWords,
          );
        }
      }
    }
    _questions(card['reflectionQuestions'], path, locale);
    return card;
  }

  void _elementAstrology(Map<String, Object?> card, String path, String id) {
    final element = card['element'];
    final suit = suitOf(id);
    if (element != null && !kElements.contains(element)) {
      error(
        path,
        'element must be one of ${kElements.join(' | ')}',
        locale: 'en',
      );
    } else if (suit != null && element != kSuitElements[suit]) {
      error(
        path,
        'element must be ${kSuitElements[suit]} for $suit',
        locale: 'en',
      );
    }
    final astrology = card['astrology'];
    if (astrology != null &&
        (astrology is! String || !_snake.hasMatch(astrology))) {
      error(path, 'astrology must be a snake_case key', locale: 'en');
    }
  }

  void _keywords(Object? value, String path, String field, String locale) {
    if (value == null) return;
    if (value is! List) {
      error(path, '$field must be a list', locale: locale);
      return;
    }
    if (value.length < 3 || value.length > 6) {
      error(
        path,
        '$field: ${value.length} items, expected 3–6',
        locale: locale,
      );
    }
    final seen = <String>{};
    for (final (i, item) in value.indexed) {
      final kw = text(
        item,
        path,
        '$field[$i]',
        locale,
        singleLine: true,
        maxChars: 24,
      );
      if (kw != null && !seen.add(kw.toLowerCase())) {
        error(path, '$field: duplicate "$kw"', locale: locale);
      }
    }
  }

  void _questions(Object? value, String path, String locale) {
    if (value == null) return;
    if (value is! List) {
      error(path, 'reflectionQuestions must be a list', locale: locale);
      return;
    }
    if (value.length != 3) {
      error(
        path,
        'reflectionQuestions: ${value.length} items, expected 3',
        locale: locale,
      );
    }
    final endings = questionEndings(locale);
    for (final (i, item) in value.indexed) {
      final q = text(
        item,
        path,
        'reflectionQuestions[$i]',
        locale,
        singleLine: true,
        maxChars: 120,
      );
      if (q != null && !endings.any(q.endsWith)) {
        error(
          path,
          'reflectionQuestions[$i] must end with ${endings.join(' or ')}',
          locale: locale,
        );
      }
    }
  }

  // --- spreads ------------------------------------------------------------

  void _spreads() {
    const enPath = '$kSourceDir/en/spreads.yaml';
    if (!source.spreads.containsKey(kSourceLocale)) {
      error(enPath, 'missing', locale: kSourceLocale);
    } else {
      final spreads = mapping(
        source.spreads[kSourceLocale],
        enPath,
        'spreads.yaml',
      );
      if (spreads != null) {
        _enSpreads(spreads, enPath);
        enSpreadsHash = spreadsSourceHash(spreads);
      }
    }
    for (final locale in kTargetLocales) {
      final path = '$kSourceDir/$locale/spreads.yaml';
      if (!source.spreads.containsKey(locale)) {
        report(path, 'missing', locale);
        continue;
      }
      final map = mapping(source.spreads[locale], path, 'spreads.yaml');
      if (map == null) continue;
      keys(
        map,
        path,
        'spreads',
        required: {'reviewStatus', 'sourceHash', 'whenToUse'},
      );
      reviewStatus(map['reviewStatus'], path, locale);
      sourceHashField(map, path, locale, enSpreadsHash, 'en/spreads.yaml');
      final when = map['whenToUse'];
      if (when == null) continue;
      final texts = mapping(when, path, 'whenToUse');
      if (texts == null) continue;
      keys(texts, path, 'whenToUse', required: kSpreadPositions.keys.toSet());
      for (final id in kSpreadPositions.keys) {
        text(
          texts[id],
          path,
          'whenToUse.$id',
          locale,
          singleLine: false,
          words: kWhenToUseWords,
        );
      }
    }
  }

  void _enSpreads(Map<String, Object?> map, String path) {
    const en = kSourceLocale;
    keys(map, path, 'spreads', required: {'reviewStatus', 'spreads'});
    reviewStatus(map['reviewStatus'], path, en);
    final list = map['spreads'];
    if (list == null) return;
    if (list is! List) {
      error(path, 'spreads must be a list', locale: en);
      return;
    }
    final ids = [for (final s in list) s is Map ? s['id'] : null];
    final expected = kSpreadPositions.keys.toList();
    if (ids.length != expected.length ||
        !List.generate(
          ids.length,
          (i) => ids[i] == expected[i],
        ).every((b) => b)) {
      error(
        path,
        'spreads must be exactly [${expected.join(', ')}] in this order, got '
        '[${ids.join(', ')}]',
        locale: en,
      );
    }
    for (final (i, raw) in list.indexed) {
      final spread = mapping(raw, path, 'spreads[$i]');
      if (spread == null) continue;
      final id = spread['id'];
      final where = 'spread ${id ?? '#$i'}';
      keys(
        spread,
        path,
        where,
        required: {
          'id',
          'version',
          'allowsReversals',
          'questionSuggestionKeys',
          'whenToUse',
          'positions',
        },
      );
      final version = spread['version'];
      if (version != null && (version is! int || version < 1)) {
        error(path, '$where: version must be an integer >= 1', locale: en);
      }
      if (spread.containsKey('allowsReversals') &&
          spread['allowsReversals'] is! bool) {
        error(
          path,
          '$where: allowsReversals must be true or false',
          locale: en,
        );
      }
      _suggestionKeys(spread['questionSuggestionKeys'], path, where, '$id');
      text(
        spread['whenToUse'],
        path,
        '$where: whenToUse',
        en,
        singleLine: false,
        words: kWhenToUseWords,
      );
      _positions(spread['positions'], path, where, kSpreadPositions['$id']);
    }
  }

  void _suggestionKeys(Object? value, String path, String where, String id) {
    if (value == null) return;
    if (value is! List) {
      error(
        path,
        '$where: questionSuggestionKeys must be a list',
        locale: 'en',
      );
      return;
    }
    if (value.length < 3 || value.length > 4) {
      error(
        path,
        '$where: ${value.length} questionSuggestionKeys, expected 3–4',
        locale: 'en',
      );
    }
    if (value.toSet().length != value.length) {
      error(path, '$where: duplicate questionSuggestionKeys', locale: 'en');
    }
    final pattern = RegExp('^spread_${RegExp.escape(id)}_suggestion_[1-4]\$');
    for (final key in value) {
      if (key is! String || !pattern.hasMatch(key)) {
        error(
          path,
          '$where: suggestion key "$key" must be spread_${id}_suggestion_<1-4>',
          locale: 'en',
        );
      } else if (options.arbKeys != null && !options.arbKeys!.contains(key)) {
        issues.add(
          Issue.report(
            path,
            '$where: ARB key "$key" not in app_en.arb yet',
            locale: 'en',
          ),
        );
      }
    }
  }

  void _positions(
    Object? value,
    String path,
    String where,
    List<String>? expected,
  ) {
    if (value == null) return;
    if (value is! List) {
      error(path, '$where: positions must be a list', locale: 'en');
      return;
    }
    final ids = <String>[];
    final seen = <Object?>{};
    for (final (i, raw) in value.indexed) {
      final pos = mapping(raw, path, '$where positions[$i]');
      if (pos == null) continue;
      final id = pos['id'];
      final at = '$where/${id ?? '#$i'}';
      keys(
        pos,
        path,
        at,
        required: {'id', 'x', 'y', 'meaning'},
        optional: {'rotationDeg'},
      );
      if (!seen.add(id)) {
        error(path, '$at: duplicate position id', locale: 'en');
      }
      if (id is String) ids.add(id);
      for (final axis in ['x', 'y']) {
        final v = pos[axis];
        if (v == null) continue;
        if (v is! num || v < 0 || v > 1) {
          error(
            path,
            '$at: $axis must be a number in 0..1, got $v',
            locale: 'en',
          );
        }
      }
      final rotation = pos['rotationDeg'];
      if (rotation != null &&
          (rotation is! num || rotation < -360 || rotation > 360)) {
        error(
          path,
          '$at: rotationDeg must be a number in -360..360',
          locale: 'en',
        );
      }
      text(
        pos['meaning'],
        path,
        '$at: meaning',
        'en',
        singleLine: false,
        words: kPositionMeaningWords,
      );
    }
    if (expected != null && ids.join(',') != expected.join(',')) {
      error(
        path,
        '$where: positions must be [${expected.join(', ')}] in draw order, '
        'got [${ids.join(', ')}]',
        locale: 'en',
      );
    }
  }

  // --- articles -----------------------------------------------------------

  void _articles() {
    for (final locale in kLocales) {
      for (final id in kArticleIds) {
        final path = '$kSourceDir/$locale/articles/$id.md';
        final article = source.articles[locale]?[id];
        if (article == null) {
          if (locale == kSourceLocale) {
            error(path, 'missing', locale: locale);
          } else {
            report(path, 'missing', locale);
          }
          continue;
        }
        _article(article, path, id, locale);
      }
    }
  }

  void _article(Article article, String path, String id, String locale) {
    final front = mapping(article.frontMatter, path, 'front matter');
    if (front != null) {
      keys(
        front,
        path,
        'front matter',
        required: {'reviewStatus', if (locale != kSourceLocale) 'sourceHash'},
      );
      reviewStatus(front['reviewStatus'], path, locale);
      if (locale == kSourceLocale) {
        enArticleHashes[id] = articleSourceHash(article.body);
      }
      sourceHashField(
        front,
        path,
        locale,
        enArticleHashes[id],
        'the en article',
      );
    }
    final body = article.body;
    if (!body.startsWith('# ')) {
      error(
        path,
        'the body must start with a level-1 heading "# …"',
        locale: locale,
      );
    }
    for (final p in articleMarkupProblems(body)) {
      error(path, p, locale: locale);
    }
    for (final p in bidiProblems(body, locale)) {
      error(path, p, locale: locale);
    }
    final bound = boundProblem(
      body,
      locale,
      kArticleWords.$1,
      kArticleWords.$2,
    );
    if (bound != null) error(path, bound, locale: locale);
    for (final phrase in banned.hits(body, locale)) {
      error(path, 'banned phrase "$phrase"', locale: locale);
    }
  }

  // --- crisis -------------------------------------------------------------

  void _crisis() {
    const path = '$kSourceDir/crisis/crisis_resources.yaml';
    if (!source.hasCrisis) {
      error(path, 'missing');
      return;
    }
    final crisis = mapping(source.crisis, path, 'crisis_resources.yaml');
    if (crisis == null) return;
    keys(
      crisis,
      path,
      'crisis',
      required: {'localeFallback', 'countries', 'international'},
    );
    final countries = crisis['countries'] == null
        ? null
        : mapping(crisis['countries'], path, 'countries');
    final fallback = crisis['localeFallback'] == null
        ? null
        : mapping(crisis['localeFallback'], path, 'localeFallback');
    var unverified = 0;
    var total = 0;
    void entries(Object? value, String where) {
      if (value is! List || value.isEmpty) {
        error(path, '$where must be a non-empty list');
        return;
      }
      for (final (i, raw) in value.indexed) {
        total++;
        if (!_resource(raw, path, '$where[$i]')) unverified++;
      }
    }

    if (countries != null) {
      for (final code in countries.keys) {
        if (!_country.hasMatch(code)) {
          error(path, 'countries: "$code" is not ISO alpha-2');
        }
        entries(countries[code], 'countries.$code');
      }
      for (final code in kRequiredCrisisCountries) {
        if (!countries.containsKey(code)) {
          error(path, 'countries: missing $code (05 §4.2)');
        }
      }
    }
    if (fallback != null) {
      keys(fallback, path, 'localeFallback', required: kLocales.toSet());
      for (final MapEntry(key: locale, value: code) in fallback.entries) {
        if (code != null &&
            (countries == null || !countries.containsKey(code))) {
          error(path, 'localeFallback.$locale: "$code" is not in countries');
        }
      }
    }
    if (crisis.containsKey('international')) {
      final international = crisis['international'];
      entries(international, 'international');
      final hasFind =
          international is List &&
          international.any(
            (e) => e is Map && '${e['url']}'.contains(kFindAHelplineHost),
          );
      if (!hasFind) {
        error(path, 'international: must include https://$kFindAHelplineHost');
      }
    }
    if (unverified > 0 && !options.release) {
      issues.add(
        Issue.report(
          path,
          '$unverified of $total entries unverified (verifiedAt null or older '
          'than $kCrisisMaxAgeDays days); validate --release fails on them',
        ),
      );
    }
  }

  /// Checks one entry; returns whether it counts as verified.
  bool _resource(Object? raw, String path, String where) {
    final entry = mapping(raw, path, where);
    if (entry == null) return true;
    keys(
      entry,
      path,
      where,
      required: {'name', 'languages', 'verifiedAt'},
      optional: {'phone', 'sms', 'url', 'hours'},
    );
    final name = entry['name'];
    if (name != null && (name is! String || name.trim().isEmpty)) {
      error(path, '$where.name must be a non-empty string');
    }
    if (!entry.containsKey('phone') &&
        !entry.containsKey('sms') &&
        !entry.containsKey('url')) {
      error(path, '$where: needs at least one of phone, sms, url');
    }
    for (final k in ['phone', 'sms']) {
      final v = entry[k];
      if (entry.containsKey(k) && (v is! String || !_phone.hasMatch(v))) {
        error(
          path,
          '$where.$k must be a quoted number (digits, spaces, +, -, ( ))',
        );
      }
    }
    final url = entry['url'];
    if (entry.containsKey('url') && (url is! String || !_url.hasMatch(url))) {
      error(path, '$where.url must be an https URL');
    }
    final hours = entry['hours'];
    if (entry.containsKey('hours') &&
        (hours is! String || hours.trim().isEmpty)) {
      error(path, '$where.hours must be a non-empty string');
    }
    final languages = entry['languages'];
    if (entry.containsKey('languages')) {
      if (languages is! List ||
          languages.any((l) => l is! String || !_language.hasMatch(l))) {
        error(path, '$where.languages must be a list of BCP 47 tags');
      }
    }
    final verifiedAt = entry['verifiedAt'];
    if (verifiedAt == null) {
      if (options.release) {
        error(path, '$where: unverified (verifiedAt null) in a release');
      }
      return false;
    }
    final date = verifiedAt is String ? _parseDate(verifiedAt) : null;
    if (date == null) {
      error(path, '$where.verifiedAt must be null or a YYYY-MM-DD date');
      return true;
    }
    final today = DateTime.utc(
      options.today.year,
      options.today.month,
      options.today.day,
    );
    if (date.isAfter(today)) {
      error(path, '$where.verifiedAt $verifiedAt is in the future');
      return true;
    }
    final age = today.difference(date).inDays;
    if (age > kCrisisMaxAgeDays) {
      if (options.release) {
        error(path, '$where: verified $age days ago (> $kCrisisMaxAgeDays)');
      }
      return false;
    }
    return true;
  }

  static DateTime? _parseDate(String raw) {
    final m = _date.firstMatch(raw);
    if (m == null) return null;
    final (y, mo, d) = (int.parse(m[1]!), int.parse(m[2]!), int.parse(m[3]!));
    final date = DateTime.utc(y, mo, d);
    return date.year == y && date.month == mo && date.day == d ? date : null;
  }
}

/// Whether [issues] contain an error.
bool hasErrors(Iterable<Issue> issues) =>
    issues.any((i) => i.severity == Severity.error);
