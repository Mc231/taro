import 'dart:io';

import 'package:taro_dart_tools/content.dart';
import 'package:test/test.dart';

import 'fixture.dart';

typedef _Mutation = void Function(FixtureRepo repo);

const _card = '$kSourceDir/en/cards/cups_03.yaml';
const _major = '$kSourceDir/en/cards/major_00.yaml';
const _spreads = '$kSourceDir/en/spreads.yaml';
const _glossary = '$kSourceDir/glossary.yaml';
const _crisis = '$kSourceDir/crisis/crisis_resources.yaml';
const _deck = '$kSourceDir/deck.yaml';
const _about = '$kSourceDir/en/articles/about.md';

void _card_(FixtureRepo r, void Function(Map<String, Object?>) f) =>
    r.edit(_card, f);

Map<String, Object?> _spread(Map<String, Object?> doc, int i) =>
    (doc['spreads']! as List)[i] as Map<String, Object?>;

Map<String, Object?> _position(Map<String, Object?> doc, int s, int p) =>
    (_spread(doc, s)['positions']! as List)[p] as Map<String, Object?>;

List<Object?> _entries(Map<String, Object?> doc, String country) =>
    (doc['countries']! as Map)[country] as List<Object?>;

Map<String, Object?> _entry(Map<String, Object?> doc, String country) =>
    _entries(doc, country).first! as Map<String, Object?>;

/// Failure modes: mutation → expected substring of an error line.
final Map<String, (_Mutation, String)> _failures = {
  // --- structure --------------------------------------------------------
  'missing en card': ((r) => r.delete(_card), 'cups_03.yaml: missing'),
  'unknown file': (
    (r) => r.write('$kSourceDir/en/cards/cups_15.yaml', 'x: 1\n'),
    'cups_15.yaml: unknown file',
  ),
  'unknown locale folder': (
    (r) => r.write('$kSourceDir/xx/spreads.yaml', 'x: 1\n'),
    'xx/spreads.yaml: unknown file',
  ),
  'YAML syntax error': (
    (r) => r.write(_card, 'cardId: [unclosed\n'),
    'cups_03.yaml: cannot parse',
  ),
  'duplicate YAML key': (
    (r) => r.write(_card, 'cardId: cups_03\ncardId: cups_03\n'),
    'cannot parse',
  ),
  'card not a mapping': (
    (r) => r.write(_card, '- a\n'),
    'a card file must be a mapping',
  ),
  'non-string mapping key': (
    (r) => r.write(_card, '1: a\n'),
    'mapping key 1 is not a string',
  ),
  // --- card fields ------------------------------------------------------
  'cardId mismatch': (
    (r) => _card_(r, (d) => d['cardId'] = 'cups_04'),
    'differs from the file name',
  ),
  'unknown card key': (
    (r) => _card_(r, (d) => d['meaning'] = 'x'),
    'unknown key "meaning"',
  ),
  'missing card key': (
    (r) => _card_(r, (d) => d.remove('imageryNote')),
    'missing key "imageryNote"',
  ),
  'bad reviewStatus': (
    (r) => _card_(r, (d) => d['reviewStatus'] = 'draft'),
    'reviewStatus must be one of machine | reviewed',
  ),
  'sourceHash in en': (
    (r) => _card_(r, (d) => d['sourceHash'] = 'a' * 64),
    'sourceHash must be absent in en',
  ),
  'wrong suit element': (
    (r) => _card_(r, (d) => d['element'] = 'fire'),
    'element must be water for cups',
  ),
  'unknown element': (
    (r) => r.edit(_major, (d) => d['element'] = 'metal'),
    'element must be one of',
  ),
  'bad astrology key': (
    (r) => r.edit(_major, (d) => d['astrology'] = 'Uranus!'),
    'astrology must be a snake_case key',
  ),
  'name differs from glossary': (
    (r) => _card_(r, (d) => d['name'] = 'Three of Cups'),
    'differs from glossary',
  ),
  'too few keywords': (
    (r) => _card_(r, (d) => d['keywordsUpright'] = ['a', 'b']),
    'keywordsUpright: 2 items, expected 3–6',
  ),
  'keyword too long': (
    (r) => _card_(r, (d) => d['keywordsReversed'] = ['a', 'b', 'x' * 25]),
    'keywordsReversed[2]: 25 characters, at most 24',
  ),
  'duplicate keyword': (
    (r) => _card_(r, (d) => d['keywordsUpright'] = ['Calm', 'calm', 'x']),
    'duplicate "calm"',
  ),
  'keywords not a list': (
    (r) => _card_(r, (d) => d['keywordsUpright'] = 'calm'),
    'keywordsUpright must be a list',
  ),
  'short too long': (
    (r) => _card_(r, (d) => d['shortUpright'] = 'x' * 161),
    'shortUpright: 161 characters, at most 160',
  ),
  'line break in short': (
    (r) => _card_(r, (d) => d['shortReversed'] = 'a\nb'),
    'line break in a single-line field',
  ),
  'meaning too short': (
    (r) => _card_(r, (d) => d['meaningUpright'] = words(119)),
    'meaningUpright: 119 words, expected 120–220',
  ),
  'meaning too long': (
    (r) => _card_(r, (d) => d['meaningReversed'] = words(201)),
    'meaningReversed: 201 words, expected 100–200',
  ),
  'aspects missing key': (
    (r) => _card_(r, (d) => (d['aspects']! as Map).remove('workUpright')),
    'aspects: missing key "workUpright"',
  ),
  'aspects not a mapping': (
    (r) => _card_(r, (d) => d['aspects'] = 'x'),
    'aspects must be a mapping',
  ),
  'aspect too short': (
    (r) => _card_(r, (d) => (d['aspects']! as Map)['growthReversed'] = 'x'),
    'aspects.growthReversed: 1 words, expected 40–90',
  ),
  'two questions': (
    (r) => _card_(r, (d) => d['reflectionQuestions'] = ['a?', 'b?']),
    'reflectionQuestions: 2 items, expected 3',
  ),
  'question without ?': (
    (r) => _card_(r, (d) => d['reflectionQuestions'] = ['a?', 'b?', 'c.']),
    'reflectionQuestions[2] must end with ?',
  ),
  'questions not a list': (
    (r) => _card_(r, (d) => d['reflectionQuestions'] = 'a?'),
    'reflectionQuestions must be a list',
  ),
  'question too long': (
    (r) => _card_(
      r,
      (d) => d['reflectionQuestions'] = ['a?', 'b?', '${'x' * 120}?'],
    ),
    'reflectionQuestions[2]: 121 characters, at most 120',
  ),
  'non-string text': (
    (r) => _card_(r, (d) => d['shortUpright'] = 3),
    'shortUpright must be a string',
  ),
  'leading whitespace': (
    (r) => _card_(r, (d) => d['shortUpright'] = ' calm'),
    'leading or trailing whitespace',
  ),
  'empty text': (
    (r) => _card_(r, (d) => d['shortUpright'] = ''),
    'shortUpright: empty',
  ),
  'tab': ((r) => _card_(r, (d) => d['shortUpright'] = 'a\tb'), 'tab character'),
  'carriage return': (
    (r) => _card_(r, (d) => d['shortUpright'] = 'a\rb'),
    'carriage return',
  ),
  // --- plain text -------------------------------------------------------
  'Markdown emphasis': (
    (r) => _card_(r, (d) => d['shortUpright'] = 'a **bold** step'),
    'Markdown emphasis "*" (plain text only)',
  ),
  'Markdown code': (
    (r) => _card_(r, (d) => d['shortUpright'] = 'a `code` step'),
    'Markdown code',
  ),
  'Markdown strikethrough': (
    (r) => _card_(r, (d) => d['shortUpright'] = 'a ~~x~~ step'),
    'strikethrough',
  ),
  'Markdown underscore emphasis': (
    (r) => _card_(r, (d) => d['shortUpright'] = 'a __x__ step'),
    'Markdown emphasis "__"',
  ),
  'Markdown link': (
    (r) => _card_(r, (d) => d['shortUpright'] = 'see [x](https://a.b)'),
    'Markdown link',
  ),
  'Markdown heading': (
    (r) => _card_(
      r,
      (d) => d['meaningReversed'] = '${words(60)}\n# Title\n${words(60)}',
    ),
    'Markdown block marker at line start: "#"',
  ),
  'Markdown list': (
    (r) => _card_(
      r,
      (d) => d['meaningReversed'] = '${words(60)}\n- item\n${words(60)}',
    ),
    'Markdown block marker at line start: "-"',
  ),
  'HTML tag': (
    (r) => _card_(r, (d) => d['shortUpright'] = 'a <b>bold</b> step'),
    'HTML tag',
  ),
  'HTML entity': (
    (r) => _card_(r, (d) => d['shortUpright'] = 'a &amp; b'),
    'HTML entity',
  ),
  // --- banned phrases ---------------------------------------------------
  'banned word': (
    (r) => _card_(r, (d) => d['shortUpright'] = 'This is guaranteed calm.'),
    'banned phrase "guaranteed"',
  ),
  'banned stem': (
    (r) => _card_(r, (d) => d['shortUpright'] = 'A psychical moment.'),
    'banned phrase "psychic*"',
  ),
  'banned phrase across words': (
    (r) => _card_(r, (d) => d['shortUpright'] = 'This WILL   happen soon.'),
    'banned phrase "will happen"',
  ),
  'banned common phrase': (
    (r) => _card_(r, (d) => d['shortUpright'] = 'Be 100% calm.'),
    'banned phrase "100%"',
  ),
  'banned in keywords': (
    (r) => _card_(r, (d) => d['keywordsUpright'] = ['a', 'b', 'healing']),
    'keywordsUpright[2]: banned phrase "healing"',
  ),
  // --- bidi -------------------------------------------------------------
  'bidi override': (
    (r) => _card_(r, (d) => d['shortUpright'] = 'a\u202Eb'),
    'forbidden bidi control U+202E',
  ),
  'BOM': (
    (r) => _card_(r, (d) => d['shortUpright'] = 'a\uFEFFb'),
    'forbidden bidi control U+FEFF',
  ),
  'unbalanced isolate': (
    (r) => _card_(r, (d) => d['shortUpright'] = 'a\u2066b'),
    'unbalanced bidi isolates',
  ),
  'isolate close first': (
    (r) => _card_(r, (d) => d['shortUpright'] = 'a\u2069b\u2066c'),
    'unbalanced bidi isolates',
  ),
  'RLM outside ar': (
    (r) => _card_(r, (d) => d['shortUpright'] = 'a\u200Fb'),
    'bidi mark U+200F outside ar',
  ),
  // --- spreads ----------------------------------------------------------
  'missing en spreads': ((r) => r.delete(_spreads), 'spreads.yaml: missing'),
  'spreads not a mapping': (
    (r) => r.write(_spreads, '- a\n'),
    'spreads.yaml must be a mapping',
  ),
  'spreads not a list': (
    (r) => r.edit(_spreads, (d) => d['spreads'] = 'x'),
    'spreads must be a list',
  ),
  'spread order': (
    (r) => r.edit(_spreads, (d) {
      final list = d['spreads']! as List;
      d['spreads'] = [list[1], list[0], ...list.skip(2)];
    }),
    'spreads must be exactly [single, three_ppf',
  ),
  'spread unknown key': (
    (r) => r.edit(_spreads, (d) => _spread(d, 0)['cost'] = 1),
    'spread single: unknown key "cost"',
  ),
  'spread bad version': (
    (r) => r.edit(_spreads, (d) => _spread(d, 0)['version'] = 0),
    'version must be an integer >= 1',
  ),
  'allowsReversals not bool': (
    (r) => r.edit(_spreads, (d) => _spread(d, 0)['allowsReversals'] = 'yes'),
    'allowsReversals must be true or false',
  ),
  'suggestion keys not a list': (
    (r) =>
        r.edit(_spreads, (d) => _spread(d, 0)['questionSuggestionKeys'] = 'x'),
    'questionSuggestionKeys must be a list',
  ),
  'too few suggestion keys': (
    (r) => r.edit(
      _spreads,
      (d) => _spread(d, 0)['questionSuggestionKeys'] = [
        'spread_single_suggestion_1',
      ],
    ),
    '1 questionSuggestionKeys, expected 3–4',
  ),
  'duplicate suggestion keys': (
    (r) => r.edit(
      _spreads,
      (d) => _spread(d, 0)['questionSuggestionKeys'] = [
        for (var i = 0; i < 3; i++) 'spread_single_suggestion_1',
      ],
    ),
    'duplicate questionSuggestionKeys',
  ),
  'suggestion key pattern': (
    (r) => r.edit(
      _spreads,
      (d) => _spread(d, 0)['questionSuggestionKeys'] = [
        'spread_single_suggestion_1',
        'spread_single_suggestion_2',
        'spread_three_ppf_suggestion_3',
      ],
    ),
    'must be spread_single_suggestion_<1-4>',
  ),
  'whenToUse too short': (
    (r) => r.edit(_spreads, (d) => _spread(d, 0)['whenToUse'] = words(3)),
    'whenToUse: 3 words, expected 15–80',
  ),
  'positions not a list': (
    (r) => r.edit(_spreads, (d) => _spread(d, 0)['positions'] = 'x'),
    'positions must be a list',
  ),
  'duplicate position': (
    (r) => r.edit(_spreads, (d) {
      final positions = _spread(d, 1)['positions']! as List;
      positions[1] = {...positions[0]! as Map<String, Object?>};
    }),
    'spread three_ppf/past: duplicate position id',
  ),
  'wrong position ids': (
    (r) => r.edit(_spreads, (d) => _position(d, 0, 0)['id'] = 'center'),
    'positions must be [focus] in draw order, got [center]',
  ),
  'x outside 0..1': (
    (r) => r.edit(_spreads, (d) => _position(d, 5, 0)['x'] = 1.2),
    'celtic_cross/present: x must be a number in 0..1, got 1.2',
  ),
  'y not a number': (
    (r) => r.edit(_spreads, (d) => _position(d, 5, 0)['y'] = 'top'),
    'y must be a number in 0..1',
  ),
  'rotation out of range': (
    (r) => r.edit(_spreads, (d) => _position(d, 5, 1)['rotationDeg'] = 400),
    'rotationDeg must be a number in -360..360',
  ),
  'position missing meaning': (
    (r) => r.edit(_spreads, (d) => _position(d, 0, 0).remove('meaning')),
    'spread single/focus: missing key "meaning"',
  ),
  'position meaning too long': (
    (r) => r.edit(_spreads, (d) => _position(d, 0, 0)['meaning'] = words(41)),
    'meaning: 41 words, expected 5–40',
  ),
  'position not a mapping': (
    (r) =>
        r.edit(_spreads, (d) => (_spread(d, 0)['positions']! as List)[0] = 'x'),
    'positions[0] must be a mapping',
  ),
  // --- articles ---------------------------------------------------------
  'missing en article': ((r) => r.delete(_about), 'about.md: missing'),
  'no front matter': (
    (r) => r.write(_about, articleBody('about')),
    'missing front matter',
  ),
  'unterminated front matter': (
    (r) => r.write(_about, '---\nreviewStatus: machine\n# x\n'),
    'unterminated front matter',
  ),
  'front matter not a mapping': (
    (r) => r.write(_about, '---\n- a\n---\n${articleBody('about')}'),
    'front matter must be a mapping',
  ),
  'front matter unknown key': (
    (r) => r.write(
      _about,
      '---\nreviewStatus: machine\ntitle: x\n---\n${articleBody('about')}',
    ),
    'front matter: unknown key "title"',
  ),
  'article without heading': (
    (r) => r.write(_about, articleFile(words(150))),
    'must start with a level-1 heading',
  ),
  'article raw HTML': (
    (r) =>
        r.write(_about, articleFile('${articleBody('about')}\n<div>x</div>\n')),
    'raw HTML tag',
  ),
  'article too short': (
    (r) => r.write(_about, articleFile('# About\n\nShort.')),
    '2 words, expected 100–3000',
  ),
  'article banned phrase': (
    (r) => r.write(
      _about,
      articleFile('${articleBody('about')}\nWe are the best.\n'),
    ),
    'banned phrase "best"',
  ),
  'article bidi': (
    (r) => r.write(_about, articleFile('${articleBody('about')}\u202E')),
    'forbidden bidi control',
  ),
  // --- glossary ---------------------------------------------------------
  'missing glossary': ((r) => r.delete(_glossary), 'glossary.yaml: missing'),
  'glossary not a mapping': (
    (r) => r.write(_glossary, '- a\n'),
    'glossary.yaml must be a mapping',
  ),
  'glossary missing section': (
    (r) => r.edit(_glossary, (d) => d.remove('terms')),
    'glossary: missing key "terms"',
  ),
  'glossary missing card': (
    (r) => r.edit(_glossary, (d) => (d['cards']! as Map).remove('cups_03')),
    'cards: missing "cups_03"',
  ),
  'glossary unknown card': (
    (r) =>
        r.edit(_glossary, (d) => (d['cards']! as Map)['cups_15'] = {'en': 'x'}),
    'cards: unknown "cups_15"',
  ),
  'glossary section not a mapping': (
    (r) => r.edit(_glossary, (d) => d['suits'] = ['wands']),
    'suits must be a mapping',
  ),
  'glossary entry not a mapping': (
    (r) => r.edit(_glossary, (d) => (d['arcana']! as Map)['major'] = 'Major'),
    'arcana.major must be a locale → name mapping',
  ),
  'glossary entry without en': (
    (r) =>
        r.edit(_glossary, (d) => (d['terms']! as Map)['upright'] = {'de': 'x'}),
    'terms.upright: missing en',
  ),
  'glossary unknown locale': (
    (r) => r.edit(
      _glossary,
      (d) => (d['terms']! as Map)['upright'] = {'en': 'x', 'xx': 'y'},
    ),
    'terms.upright: unknown locale "xx"',
  ),
  'glossary non-string name': (
    (r) =>
        r.edit(_glossary, (d) => (d['terms']! as Map)['upright'] = {'en': 1}),
    'terms.upright.en must be a string',
  ),
  'glossary name whitespace': (
    (r) => r.edit(
      _glossary,
      (d) => (d['terms']! as Map)['upright'] = {'en': 'Upright '},
    ),
    'terms.upright.en: leading or trailing whitespace',
  ),
  'glossary banned phrase': (
    (r) => r.edit(
      _glossary,
      (d) => (d['terms']! as Map)['upright'] = {'en': 'Psychic'},
    ),
    'terms.upright.en: banned phrase "psychic*"',
  ),
  'glossary term not snake_case': (
    (r) => r.edit(_glossary, (d) => (d['terms']! as Map)['Up'] = {'en': 'x'}),
    'terms: "Up" not snake_case',
  ),
  'glossary review without en': (
    (r) => r.edit(_glossary, (d) => d['review'] = {'de': 'machine'}),
    'review: missing en',
  ),
  'glossary review bad value': (
    (r) => r.edit(_glossary, (d) => d['review'] = {'en': 'done'}),
    'review.en: must be machine | reviewed',
  ),
  'glossary review unknown locale': (
    (r) => r.edit(
      _glossary,
      (d) => d['review'] = {'en': 'machine', 'xx': 'machine'},
    ),
    'review: unknown locale "xx"',
  ),
  'glossary review not a mapping': (
    (r) => r.edit(_glossary, (d) => d['review'] = 'x'),
    'review must be a mapping',
  ),
  'glossary without card locale name': (
    (r) => r.edit(
      _glossary,
      (d) => (d['cards']! as Map)['cups_03'] = {'de': 'x'},
    ),
    'glossary.yaml has no en name for cups_03',
  ),
  // --- deck -------------------------------------------------------------
  'missing deck.yaml': ((r) => r.delete(_deck), 'deck.yaml: missing'),
  'deck not a mapping': (
    (r) => r.write(_deck, '1\n'),
    'deck.yaml must be a mapping',
  ),
  'deck bad version': (
    (r) => r.edit(_deck, (d) => d['version'] = '1'),
    'version must be an integer >= 1',
  ),
  'deck bad id': (
    (r) => r.edit(_deck, (d) => d['id'] = 'RWS'),
    'id must be a snake_case string',
  ),
  // --- crisis -----------------------------------------------------------
  'missing crisis': (
    (r) => r.delete(_crisis),
    'crisis_resources.yaml: missing',
  ),
  'crisis not a mapping': (
    (r) => r.write(_crisis, '- a\n'),
    'crisis_resources.yaml must be a mapping',
  ),
  'crisis missing country': (
    (r) => r.edit(_crisis, (d) => (d['countries']! as Map).remove('UA')),
    'countries: missing UA (05 §4.2)',
  ),
  'crisis bad country code': (
    (r) => r.edit(
      _crisis,
      (d) => (d['countries']! as Map)['usa'] = [
        crisisEntry('x'),
      ],
    ),
    'countries: "usa" is not ISO alpha-2',
  ),
  'crisis empty country list': (
    (r) => r.edit(_crisis, (d) => (d['countries']! as Map)['US'] = <Object?>[]),
    'countries.US must be a non-empty list',
  ),
  'crisis fallback to unknown country': (
    (r) => r.edit(_crisis, (d) => (d['localeFallback']! as Map)['de'] = 'AT'),
    'localeFallback.de: "AT" is not in countries',
  ),
  'crisis fallback missing locale': (
    (r) => r.edit(_crisis, (d) => (d['localeFallback']! as Map).remove('uk')),
    'localeFallback: missing key "uk"',
  ),
  'crisis without findahelpline': (
    (r) => r.edit(
      _crisis,
      (d) => d['international'] = [crisisEntry('Other')],
    ),
    'international: must include https://findahelpline.com',
  ),
  'crisis entry without contact': (
    (r) => r.edit(_crisis, (d) {
      _entry(d, 'US')
        ..remove('phone')
        ..remove('url');
    }),
    'countries.US[0]: needs at least one of phone, sms, url',
  ),
  'crisis bad phone': (
    (r) => r.edit(_crisis, (d) => _entry(d, 'US')['phone'] = 988),
    'countries.US[0].phone must be a quoted number',
  ),
  'crisis bad sms': (
    (r) => r.edit(_crisis, (d) => _entry(d, 'US')['sms'] = 'text HOME'),
    'countries.US[0].sms must be a quoted number',
  ),
  'crisis http url': (
    (r) => r.edit(_crisis, (d) => _entry(d, 'US')['url'] = 'http://a.b'),
    'countries.US[0].url must be an https URL',
  ),
  'crisis empty hours': (
    (r) => r.edit(_crisis, (d) => _entry(d, 'US')['hours'] = ' '),
    'countries.US[0].hours must be a non-empty string',
  ),
  'crisis empty name': (
    (r) => r.edit(_crisis, (d) => _entry(d, 'US')['name'] = ''),
    'countries.US[0].name must be a non-empty string',
  ),
  'crisis bad languages': (
    (r) => r.edit(_crisis, (d) => _entry(d, 'US')['languages'] = ['English']),
    'languages must be a list of BCP 47 tags',
  ),
  'crisis bad date': (
    (r) => r.edit(_crisis, (d) => _entry(d, 'US')['verifiedAt'] = '2026-02-30'),
    'verifiedAt must be null or a YYYY-MM-DD date',
  ),
  'crisis future date': (
    (r) => r.edit(_crisis, (d) => _entry(d, 'US')['verifiedAt'] = '2026-10-01'),
    'verifiedAt 2026-10-01 is in the future',
  ),
  'crisis entry unknown key': (
    (r) => r.edit(_crisis, (d) => _entry(d, 'US')['email'] = 'a@b.c'),
    'countries.US[0]: unknown key "email"',
  ),
  'crisis entry not a mapping': (
    (r) => r.edit(_crisis, (d) => (d['countries']! as Map)['US'] = ['x']),
    'countries.US[0] must be a mapping',
  ),
  'crisis countries not a mapping': (
    (r) => r.edit(_crisis, (d) => d['countries'] = ['US']),
    'countries must be a mapping',
  ),
};

void main() {
  group('valid source', () {
    late FixtureRepo repo;
    setUpAll(() => repo = FixtureRepo.create());
    tearDownAll(() => repo.dispose());

    test('en only: OK with an 11-locale staleness report', () {
      final r = run(runContentValidate, repo);
      expect(r.err, isEmpty);
      expect(r.code, 0);
      expect(r.out, contains('complete locales: en;'));
      for (final l in kTargetLocales) {
        expect(r.out, contains('report [$l]: 5 item(s)'));
        expect(r.out, contains('$l/cards: missing: 78 of 78 cards'));
      }
    });

    test('--strict-locales turns the report into errors', () {
      final r = run(runContentValidate, repo, ['--strict-locales']);
      expect(r.code, 1);
      expect(r.err, contains('de/spreads.yaml: missing'));
      expect(r.err, contains('missing: 107 de glossary names'));
    });

    test('--print-hashes prints en hashes', () {
      final r = run(runContentValidate, repo, ['--print-hashes']);
      expect(r.code, 0);
      final hash = cardSourceHash(enCard('major_00'));
      expect(r.out, contains('hash en/cards/major_00.yaml $hash'));
      expect(r.out, contains('hash en/spreads.yaml '));
      expect(r.out, contains('hash en/articles/faq.md '));
    });

    test('--release fails on verified entries older than 200 days', () {
      final old = FixtureRepo.create(verifiedAt: '2026-02-01');
      addTearDown(old.dispose);
      expect(run(runContentValidate, old).code, 0);
      final r = run(runContentValidate, old, ['--release']);
      expect(r.code, 1);
      expect(r.err, contains('countries.US[0]: verified 240 days ago (> 200)'));
    });

    test('--release fails on unverified entries; dev only reports', () {
      final fresh = FixtureRepo.create(verifiedAt: null);
      addTearDown(fresh.dispose);
      final dev = run(runContentValidate, fresh);
      expect(dev.code, 0);
      expect(dev.out, contains('17 of 17 entries unverified'));
      final r = run(runContentValidate, fresh, ['--release']);
      expect(r.code, 1);
      expect(r.err, contains('international[0]: unverified'));
      expect(run(runContentValidate, repo, ['--release']).code, 0);
    });

    test('suggestion keys missing from app_en.arb are reported', () {
      repo.write(
        'apps/taro/lib/l10n/arb/app_en.arb',
        '{"spread_single_suggestion_1": "x"}',
      );
      addTearDown(() => repo.delete('apps/taro/lib/l10n/arb/app_en.arb'));
      final r = run(runContentValidate, repo);
      expect(r.code, 0);
      expect(r.out, contains('ARB key "spread_single_suggestion_2" not in'));
      expect(r.out, isNot(contains('"spread_single_suggestion_1" not in')));
    });

    test('an unparsable app_en.arb is ignored', () {
      repo.write('apps/taro/lib/l10n/arb/app_en.arb', '{');
      addTearDown(() => repo.delete('apps/taro/lib/l10n/arb/app_en.arb'));
      expect(run(runContentValidate, repo).out, isNot(contains('ARB key')));
    });

    test('dot-files and README.md are ignored', () {
      repo.write('$kSourceDir/en/.DS_Store', 'x');
      addTearDown(() => repo.delete('$kSourceDir/en/.DS_Store'));
      repo.write('$kSourceDir/README.md', '# x');
      addTearDown(() => repo.delete('$kSourceDir/README.md'));
      expect(run(runContentValidate, repo).code, 0);
    });

    test('the disclaimer and allowed contexts are not banned', () {
      const path = '$kSourceDir/en/articles/faq.md';
      final before = repo.read(path);
      addTearDown(() => repo.write(path, before));
      repo.write(
        path,
        articleFile(
          '${articleBody('faq')}\nTaro is not medical, legal, financial or '
          'psychological advice.\n',
        ),
      );
      expect(run(runContentValidate, repo).code, 0);
    });
  });

  group('failure modes', () {
    for (final MapEntry(key: name, value: (mutate, expected))
        in _failures.entries) {
      test(name, () {
        final repo = FixtureRepo.create();
        addTearDown(repo.dispose);
        mutate(repo);
        final r = run(runContentValidate, repo);
        expect(r.err, contains(expected));
        expect(r.code, 1);
        expect(r.err, contains('content validate:'));
      });
    }
  });

  group('translations', () {
    late FixtureRepo repo;
    setUp(() => repo = FixtureRepo.create(locales: ['de', 'ar', 'ja']));
    tearDown(() => repo.dispose());

    test('complete translations are valid and complete', () {
      final r = run(runContentValidate, repo);
      expect(r.err, isEmpty);
      expect(r.code, 0);
      expect(r.out, contains('complete locales: en, ar, de, ja;'));
      expect(r.out, isNot(contains('report [de]')));
    });

    test('an en change flags the translations stale', () {
      repo
        ..edit(_card, (d) => d['shortUpright'] = 'A new calm line.')
        ..write(_about, articleFile('${articleBody('about')}\nMore.\n'))
        ..edit(_spreads, (d) => _spread(d, 0)['whenToUse'] = words(21));
      final r = run(runContentValidate, repo);
      expect(r.code, 0);
      expect(r.out, contains('de/cards/cups_03.yaml: stale: the en card'));
      expect(r.out, contains('ja/articles/about.md: stale: the en article'));
      expect(r.out, contains('ar/spreads.yaml: stale: en/spreads.yaml'));
      final strict = run(runContentValidate, repo, ['--strict-locales']);
      expect(strict.code, 1);
    });

    test('a partly translated locale is reported, not complete', () {
      repo.delete(repo.cardPath('de', 'cups_03'));
      final r = run(runContentValidate, repo);
      expect(r.code, 0);
      expect(r.out, contains('de/cards: missing: 1 of 78 cards (cups_03)'));
      expect(r.out, contains('complete locales: en, ar, ja;'));
    });

    test('many missing cards are sampled', () {
      for (final id in kCardIds.take(6)) {
        repo.delete(repo.cardPath('de', id));
      }
      expect(
        run(runContentValidate, repo).out,
        contains(
          'missing: 6 of 78 cards (major_00, major_01, major_02, '
          'major_03, major_04, …)',
        ),
      );
    });

    final translationFailures = <String, (_Mutation, String)>{
      'missing sourceHash': (
        (r) =>
            r.edit(r.cardPath('de', 'cups_03'), (d) => d.remove('sourceHash')),
        'de/cards/cups_03.yaml: card: missing key "sourceHash"',
      ),
      'bad sourceHash': (
        (r) =>
            r.edit(r.cardPath('de', 'cups_03'), (d) => d['sourceHash'] = 'x'),
        'sourceHash must be 64 lowercase hex',
      ),
      'element in a translation': (
        (r) =>
            r.edit(r.cardPath('de', 'cups_03'), (d) => d['element'] = 'water'),
        'card: unknown key "element"',
      ),
      'name differs from the locale glossary': (
        (r) => r.edit(r.cardPath('de', 'cups_03'), (d) => d['name'] = 'Drei'),
        'name "Drei" differs from glossary "Karte cups_03"',
      ),
      'glossary lacks the locale name': (
        (r) => r.edit(_glossary, (d) {
          ((d['cards']! as Map)['cups_03']! as Map).remove('de');
        }),
        'glossary.yaml has no de name for cups_03',
      ),
      'de word bounds widened': (
        (r) => r.edit(
          r.cardPath('de', 'cups_03'),
          (d) => d['meaningUpright'] = words(309, locale: 'de'),
        ),
        'meaningUpright: 309 words, expected 84–308',
      ),
      'de banned phrase': (
        (r) => r.edit(
          r.cardPath('de', 'cups_03'),
          (d) => d['shortUpright'] = 'Das ist garantiert ruhig.',
        ),
        'banned phrase "garantiert*"',
      ),
      'ja character cap': (
        (r) => r.edit(
          r.cardPath('ja', 'cups_03'),
          (d) => d['imageryNote'] = '光' * 401,
        ),
        'imageryNote: 401 characters, at most 400 for ja',
      ),
      'ja substring banned phrase': (
        (r) => r.edit(
          r.cardPath('ja', 'cups_03'),
          (d) => d['shortUpright'] = 'これは必ず起きる',
        ),
        'banned phrase "必ず"',
      ),
      'ar without Arabic script': (
        (r) => r.edit(
          r.cardPath('ar', 'cups_03'),
          (d) => d['shortUpright'] = 'calm light.',
        ),
        'shortUpright: no Arabic script in an ar text',
      ),
      'ar mark at the edge': (
        (r) => r.edit(
          r.cardPath('ar', 'cups_03'),
          (d) => d['shortUpright'] = '\u200Fهدوء',
        ),
        'bidi mark at the start or end',
      ),
      'ar question mark': (
        (r) => r.edit(
          r.cardPath('ar', 'cups_03'),
          (d) => d['reflectionQuestions'] = ['هدوء؟', 'نهر؟', 'ضوء?'],
        ),
        'reflectionQuestions[2] must end with ؟',
      ),
      'de spreads missing key': (
        (r) => r.edit('$kSourceDir/de/spreads.yaml', (d) {
          (d['whenToUse']! as Map).remove('single');
        }),
        'whenToUse: missing key "single"',
      ),
      'de spreads whenToUse not a mapping': (
        (r) =>
            r.edit('$kSourceDir/de/spreads.yaml', (d) => d['whenToUse'] = 'x'),
        'whenToUse must be a mapping',
      ),
      'de spreads not a mapping': (
        (r) => r.write('$kSourceDir/de/spreads.yaml', '- x\n'),
        'de/spreads.yaml: spreads.yaml must be a mapping',
      ),
      'de article without sourceHash': (
        (r) => r.write(
          '$kSourceDir/de/articles/faq.md',
          articleFile(articleBody('faq', locale: 'de')),
        ),
        'front matter: missing key "sourceHash"',
      ),
    };
    for (final MapEntry(key: name, value: (mutate, expected))
        in translationFailures.entries) {
      test(name, () {
        mutate(repo);
        final r = run(runContentValidate, repo);
        expect(r.err, contains(expected));
        expect(r.code, 1);
      });
    }

    test('a failing locale is not complete', () {
      repo.write('$kSourceDir/de/cards/cups_03.yaml', 'x: [\n');
      final result = validate(
        ContentSource.load(repo.root),
        BannedPhrases.none(),
        ValidateOptions(today: fixtureToday),
      );
      expect(result.completeLocales, ['en', 'ar', 'ja']);
      expect(hasErrors(result.issues), isTrue);
    });
  });

  group('command line', () {
    test('--help', () {
      final out = StringBuffer();
      expect(runContentValidate(['--help'], io: ContentIo(out: out)), 0);
      expect(out.toString(), contains('--strict-locales'));
    });

    test('bad option is a usage error', () {
      final err = StringBuffer();
      expect(runContentValidate(['--nope'], io: ContentIo(err: err)), 64);
      expect(err.toString(), contains('content validate:'));
    });

    test('extra argument is a usage error', () {
      final err = StringBuffer();
      expect(runContentValidate(['x'], io: ContentIo(err: err)), 64);
      expect(err.toString(), contains('unexpected argument "x"'));
    });

    test('no repository root', () {
      final err = StringBuffer();
      final code = runContentValidate(
        [],
        io: ContentIo(err: err, cwd: Directory.systemTemp),
      );
      expect(code, 1);
      expect(err.toString(), contains('no repository root'));
    });

    test('finds the root from the working directory', () {
      final out = StringBuffer();
      final code = runContentValidate(
        ['--help'],
        io: ContentIo(out: out, cwd: Directory.current),
      );
      expect(code, 0);
    });

    test('missing source folder', () {
      final repo = FixtureRepo.create();
      addTearDown(repo.dispose);
      Directory('${repo.root.path}/$kSourceDir').deleteSync(recursive: true);
      final r = run(runContentValidate, repo);
      expect(r.code, 1);
      expect(r.err, contains('source folder missing'));
    });

    test('broken banned_phrases.yaml', () {
      final repo = FixtureRepo.create();
      addTearDown(repo.dispose);
      repo.write(kBannedPhrasesPath, 'a: [\n');
      final r = run(runContentValidate, repo);
      expect(r.code, 1);
      expect(r.err, contains('banned_phrases.yaml'));
    });

    test('banned_phrases.yaml that is not a mapping', () {
      final repo = FixtureRepo.create();
      addTearDown(repo.dispose);
      repo.write(kBannedPhrasesPath, '- a\n');
      expect(run(runContentValidate, repo).err, contains('must be a mapping'));
    });

    test('a missing banned_phrases.yaml is an error', () {
      final repo = FixtureRepo.create();
      addTearDown(repo.dispose);
      repo.delete(kBannedPhrasesPath);
      final r = run(runContentValidate, repo);
      expect(r.code, 1);
      expect(r.err, contains('banned_phrases.yaml is missing'));
    });

    test('without required_sentences.yaml the disclaimer is not exempt', () {
      final repo = FixtureRepo.create();
      addTearDown(repo.dispose);
      repo.delete(kRequiredSentencesPath);
      expect(run(runContentValidate, repo).code, 0);
    });

    test('an unreadable (non-UTF-8) file is an error', () {
      final repo = FixtureRepo.create();
      addTearDown(repo.dispose);
      File('${repo.root.path}/$_card').writeAsBytesSync([0xff, 0xfe, 0x00]);
      final r = run(runContentValidate, repo);
      expect(r.code, 1);
      expect(r.err, contains('cups_03.yaml: cannot read'));
    });
  });
}
