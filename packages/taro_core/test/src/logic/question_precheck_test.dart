import 'package:test/test.dart';

import 'logic_support.dart';

void main() {
  const max = 300;

  group('QuestionPrecheck.check (01 §7.2, RC45)', () {
    test('trims; empty or blank is a valid "no question"', () {
      for (final input in ['', '   ', '\n\t ']) {
        final c = QuestionPrecheck.check(input, maxChars: max);
        expect(c.question, isNull);
        expect(c.length, 0);
        expect(c.isValid, isTrue);
        expect(c.personalDetailsWarning, isFalse);
      }
      final c = QuestionPrecheck.check('  What now?  ', maxChars: max);
      expect(c.question, 'What now?');
      expect(c.length, 9);
      expect(c.isValid, isTrue);
    });

    // Samples whose single grapheme spans several code units or points.
    final samples = <String, String>{
      'emoji ZWJ family': '👨‍👩‍👧',
      'flag': '🇺🇦',
      'combining mark': 'é',
      'ar': 'ب',
      'ja': '字',
      'skin tone': '👍🏽',
    };

    for (final MapEntry(key: name, value: g) in samples.entries) {
      test('300 graphemes of $name pass, 301 are too long', () {
        final ok = 'a${g * (max - 1)}';
        final check = QuestionPrecheck.check(ok, maxChars: max);
        expect(check.length, max);
        expect(check.isValid, isTrue, reason: name);
        final over = QuestionPrecheck.check('$ok$g', maxChars: max);
        expect(over.length, max + 1);
        expect(over.problem, QuestionProblem.tooLong);
        expect(over.isValid, isFalse);
      });

      test('limit keeps 300 whole graphemes of $name', () {
        final long = 'a${g * max}';
        final limited = QuestionPrecheck.limit(long, maxChars: max);
        expect(limited, 'a${g * (max - 1)}');
        expect(QuestionPrecheck.limit('ab', maxChars: max), 'ab');
      });
    }

    test('Arabic and Japanese questions are text', () {
      for (final q in ['ماذا أحتاج أن أفهم؟', '今の状況で何を学べますか？']) {
        expect(QuestionPrecheck.check(q, maxChars: max).isValid, isTrue);
      }
    });

    test('emoji, punctuation or symbols only are rejected', () {
      for (final q in ['🔮', '???', '!!! 🙏🏽 ...', '— … ¿', '́́', '★☆']) {
        final c = QuestionPrecheck.check(q, maxChars: max);
        expect(c.problem, QuestionProblem.noText, reason: q);
        expect(c.question, q.trim());
      }
    });

    test('text wins over tooLong only when there is text', () {
      final c = QuestionPrecheck.check('?' * 400, maxChars: max);
      expect(c.problem, QuestionProblem.noText);
    });

    test('a digit counts as text', () {
      expect(QuestionPrecheck.check('2026?', maxChars: max).isValid, isTrue);
    });
  });

  group('QuestionPrecheck.looksPersonal (warn, never block)', () {
    final warn = [
      'mail me at anna.k@example.com please',
      'Call +1 (555) 123-4567 tonight?',
      'is 0671234567 his number',
      'رقمي ٠٥٥١٢٣٤٥٦٧',
      '050 123 45 67',
    ];
    final noWarn = [
      'Will 2026 be a good year?',
      'I am 34 and at a crossroads',
      'What about @work?',
      'a@b',
      '12-3',
      'Room 101, floor 3',
    ];

    for (final q in warn) {
      test('warns: $q', () {
        expect(QuestionPrecheck.looksPersonal(q), isTrue);
        final c = QuestionPrecheck.check(q, maxChars: max);
        expect(c.personalDetailsWarning, isTrue);
        expect(c.isValid, isTrue);
      });
    }

    for (final q in noWarn) {
      test('no warning: $q', () {
        expect(QuestionPrecheck.looksPersonal(q), isFalse);
      });
    }
  });
}
