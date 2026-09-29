import 'package:taro_dart_tools/content.dart';
import 'package:test/test.dart';

import 'fixture.dart';

void main() {
  group('ids', () {
    test('canonical IDs (GLOSSARY §1, 01 §10.3)', () {
      expect(kCardIds, hasLength(78));
      expect(kCardIds.first, 'major_00');
      expect(kCardIds[22], 'wands_01');
      expect(kCardIds.last, 'pentacles_14');
      expect(kLocales, hasLength(12));
      expect(kTargetLocales, isNot(contains('en')));
      expect(kSpreadPositions['celtic_cross'], hasLength(10));
      expect(kPositionIds.toSet(), hasLength(kPositionIds.length));
      expect(arcanaOf('major_21'), 'major');
      expect(suitOf('cups_14'), 'cups');
      expect(numberOf('cups_14'), 14);
    });
  });

  group('text rules', () {
    test('word count ignores punctuation-only tokens', () {
      expect(wordCount('a - b — c 3'), 4);
      expect(charCount('añ😀'), 3);
    });

    test('bounds per locale', () {
      expect(wordBounds('en', 120, 220), (min: 120, max: 220));
      expect(wordBounds('de', 120, 220), (min: 84, max: 308));
      expect(wordBounds('ja', 120, 220), isNull);
      expect(
        boundProblem('光' * 10, 'ja', 1, 2),
        '10 characters, at most 8 for ja',
      );
      expect(boundProblem('光', 'ja', 1, 2), isNull);
    });

    test('bidi marks are fine inside ar text', () {
      expect(bidiProblems('هدوء\u200Fنهر', 'ar'), isEmpty);
      expect(bidiProblems('a\u2066b\u2069', 'en'), isEmpty);
    });

    test('article markup', () {
      expect(articleMarkupProblems('# a\n\n**b** [c](https://d)'), isEmpty);
      expect(articleMarkupProblems('a &nbsp; b'), ['HTML entity']);
    });

    test('question endings', () {
      expect(questionEndings('ja'), {'？', '?'});
    });
  });

  group('banned phrases', () {
    test('word boundaries and stems', () {
      final banned = BannedPhrases.parse(
        {
          'common': {
            'global': ['#1'],
          },
          'locales': {
            'en': {
              'global': ['best', 'guarantee*', 'will happen'],
              'allowed_contexts': ['not the best advice'],
            },
            'ja': {
              'match': 'substring',
              'global': ['必ず'],
            },
            'xx': 'not a mapping',
          },
        },
        {
          'description_disclaimer': {'en': 'It is the best disclaimer.'},
        },
      );
      expect(banned.locales, containsAll(['en', 'ja', 'xx']));
      expect(banned.hits('The bestest day', 'en'), isEmpty);
      expect(banned.hits('The best day', 'en'), ['best']);
      expect(banned.hits('Guaranteed!', 'en'), ['guarantee*']);
      expect(banned.hits('It’s #1', 'en'), ['#1']);
      expect(banned.hits('This is not the best advice.', 'en'), isEmpty);
      expect(banned.hits('It is the best   disclaimer.', 'en'), isEmpty);
      expect(banned.hits('これは必ず', 'ja'), ['必ず']);
      expect(banned.hits('best', 'fr'), isEmpty);
      expect(banned.phrasesFor('en'), contains('best'));
      expect(banned.phrasesFor('fr'), isEmpty);
      expect(BannedPhrases.none().hits('best', 'en'), isEmpty);
    });

    test('empty phrase is rejected', () {
      expect(
        () => phrasePattern('  ', substring: false),
        throwsArgumentError,
      );
    });
  });

  group('YAML writer', () {
    test('round-trips every string shape', () {
      final doc = <String, Object?>{
        'short': 'a: b # not a comment',
        'long': words(30),
        'multi': 'First paragraph.\n\nSecond: "quoted".',
        'edgy': ' leading space',
        'tabbed': 'a\tb',
        'long edgy': '${words(20)} ',
        'number': 1.5,
        'flag': true,
        'none': null,
        'list': ['x', 'y\nz', words(20)],
        'nested': {
          'inner': ['a'],
          'deeper': {'k': 'v'},
        },
        'emptyList': <Object?>[],
        'emptyMap': <String, Object?>{},
        'listOfMaps': [
          {'a': 1},
          ['b'],
        ],
        'arabic': 'هدوء\u200Fنهر',
      };
      final yaml = toYaml(doc, header: ['generated']);
      expect(yaml, startsWith('# generated\n'));
      expect(yaml, contains('multi: |-\n'));
      expect(yaml, contains('long: >-\n'));
      expect(parseYaml(yaml, 'x.yaml'), doc);
    });
  });

  group('common', () {
    test('canonical JSON sorts keys and ends with a newline', () {
      expect(
        canonicalJson({
          'b': 1,
          'a': [
            {'d': 1, 'c': 2},
          ],
        }),
        '{\n  "a": [\n    {\n      "c": 2,\n      "d": 1\n    }\n  ],\n'
        '  "b": 1\n}\n',
      );
      expect(sha256Hex(''), hasLength(64));
    });

    test('issue and exception strings', () {
      expect(const Issue.error('p', 'm').toString(), 'error: p: m');
      expect(
        const Issue(Severity.report, 'p', 'm').toString(),
        'report: p: m',
      );
      expect(const ContentFormatException('p', 'm').toString(), 'p: m');
      expect(const ClaudeException('m').toString(), 'ClaudeException: m');
    });

    test('parseArticle handles CRLF', () {
      final article = parseArticle(
        '---\r\nreviewStatus: machine\r\n---\r\n# A\r\n',
        'a.md',
      );
      expect(article.body, '# A');
      expect(article.frontMatter, {'reviewStatus': 'machine'});
    });
  });
}
