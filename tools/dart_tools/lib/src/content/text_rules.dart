/// Plain-text, word-count and bidi rules for content fields (01 §10.1, 01 §11
/// step 5; apps/taro/content/source/README.md "Text rules").
library;

final RegExp _wordChar = RegExp(r'[\p{L}\p{N}]', unicode: true);
final RegExp _whitespace = RegExp(r'\s+');

/// Words in [text]: whitespace-separated tokens with a letter or digit.
int wordCount(String text) =>
    text.split(_whitespace).where(_wordChar.hasMatch).length;

/// Unicode code points in [text].
int charCount(String text) => text.runes.length;

/// Word bounds `[min, max]` for a field in [locale], widened ×0.7 / ×1.4
/// outside `en`. For `ja` the result is `null` (see [jaCharCap]).
({int min, int max})? wordBounds(String locale, int min, int max) {
  if (locale == 'en') return (min: min, max: max);
  if (locale == 'ja') return null;
  return (min: (min * 0.7).floor(), max: (max * 1.4).ceil());
}

/// The character cap for a `ja` field whose English word maximum is [max].
int jaCharCap(int max) => max * 4;

/// A word/length bound problem of [text] in [locale], or `null`.
String? boundProblem(String text, String locale, int min, int max) {
  final bounds = wordBounds(locale, min, max);
  if (bounds == null) {
    final chars = charCount(text);
    final cap = jaCharCap(max);
    return chars > cap ? '$chars characters, at most $cap for ja' : null;
  }
  final words = wordCount(text);
  if (words < bounds.min || words > bounds.max) {
    return '$words words, expected ${bounds.min}–${bounds.max}';
  }
  return null;
}

final List<(RegExp, String)> _markdownInline = [
  (RegExp(r'\*'), 'Markdown emphasis "*"'),
  (RegExp('`'), 'Markdown code "`"'),
  (RegExp('~~'), 'Markdown strikethrough "~~"'),
  (RegExp('__'), 'Markdown emphasis "__"'),
  (RegExp(r'\]\('), 'Markdown link "]("'),
];

final RegExp _markdownLineStart = RegExp(r'^\s*(#|>|- |\+ |\d+\. )');
final RegExp _htmlTag = RegExp('</?[A-Za-z!][^>]*>');
final RegExp _htmlEntity = RegExp(r'&(#\d+|#x[0-9A-Fa-f]+|[A-Za-z]+);');

String _firstToken(String line) => line.trimLeft().split(' ').first;

/// Markdown or HTML found in a plain-text field.
List<String> markupProblems(String text) => [
  for (final (pattern, label) in _markdownInline)
    if (pattern.hasMatch(text)) label,
  for (final line in text.split('\n'))
    if (_markdownLineStart.hasMatch(line))
      'Markdown block marker at line start: "${_firstToken(line)}"',
  if (_htmlTag.hasMatch(text)) 'HTML tag',
  if (_htmlEntity.hasMatch(text)) 'HTML entity',
];

/// Raw HTML in a Markdown article.
List<String> articleMarkupProblems(String markdown) => [
  if (_htmlTag.hasMatch(markdown)) 'raw HTML tag',
  if (_htmlEntity.hasMatch(markdown)) 'HTML entity',
];

/// Leading/trailing whitespace and line-break problems.
List<String> whitespaceProblems(String text, {required bool singleLine}) => [
  if (text.trim().isEmpty) 'empty',
  if (text.isNotEmpty && text.trim() != text) 'leading or trailing whitespace',
  if (singleLine && text.contains('\n')) 'line break in a single-line field',
  if (text.contains('\r')) 'carriage return',
  if (text.contains('\t')) 'tab character',
];

const _embeddings = {0x202A, 0x202B, 0x202C, 0x202D, 0x202E, 0xFEFF};
const _isolateOpen = {0x2066, 0x2067, 0x2068};
const _isolateClose = 0x2069;
const _marks = {0x200E, 0x200F, 0x061C};

String _hex(int rune) =>
    'U+${rune.toRadixString(16).toUpperCase().padLeft(4, '0')}';

/// Bidi control-character problems of [text] in [locale].
List<String> bidiProblems(String text, String locale) {
  final problems = <String>[];
  var depth = 0;
  var unbalanced = false;
  final runes = text.runes.toList();
  for (final rune in runes) {
    if (_embeddings.contains(rune)) {
      problems.add('forbidden bidi control ${_hex(rune)}');
    } else if (_isolateOpen.contains(rune)) {
      depth++;
    } else if (rune == _isolateClose) {
      depth--;
      if (depth < 0) unbalanced = true;
    } else if (_marks.contains(rune) && locale != 'ar') {
      problems.add('bidi mark ${_hex(rune)} outside ar');
    }
  }
  if (unbalanced || depth != 0) problems.add('unbalanced bidi isolates');
  if (locale == 'ar' &&
      runes.isNotEmpty &&
      (_marks.contains(runes.first) || _marks.contains(runes.last))) {
    problems.add('bidi mark at the start or end');
  }
  return problems.toSet().toList();
}

final RegExp _arabic = RegExp(
  '[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF\uFB50-\uFDFF\uFE70-\uFEFC]',
);

/// Whether [text] contains Arabic script.
bool hasArabic(String text) => _arabic.hasMatch(text);

/// The accepted question endings for [locale].
Set<String> questionEndings(String locale) => switch (locale) {
  'ar' => {'؟'},
  'ja' => {'？', '?'},
  _ => {'?'},
};
