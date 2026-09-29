/// Per-locale banned phrases from `tools/store_copy/banned_phrases.yaml`
/// (RC39, 05 §9.5), matched like `tools/store_copy/check_store_copy.py`:
/// case-folded, curly apostrophes as `'`, whitespace squashed; a phrase
/// matches on word boundaries and a token ending in `*` is a stem; locales
/// with `match: substring` match anywhere. The locale's required disclaimer
/// sentence and its `allowed_contexts` are removed before matching.
///
/// Deviation: Dart has no NFKC normalizer, so full-width/compatibility forms
/// are not folded (the Python store-copy check still covers ARB and store
/// text; deck content is authored and reviewed in normal forms).
library;

import 'package:taro_dart_tools/src/content/common.dart';

/// Case-folds [text] and straightens apostrophes.
String normalizeForMatch(String text) =>
    text.replaceAll('’', "'").replaceAll('‘', "'").toLowerCase();

String _squash(String text) => normalizeForMatch(
  text,
).split(RegExp(r'\s+')).where((t) => t.isNotEmpty).join(' ');

const _w = r'[\p{L}\p{N}\p{M}_]';

/// Compiles one banned [phrase] (see the library docs).
RegExp phrasePattern(String phrase, {required bool substring}) {
  final tokens = normalizeForMatch(
    phrase,
  ).split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();
  if (tokens.isEmpty) throw ArgumentError.value(phrase, 'phrase', 'empty');
  String stem(String t) =>
      RegExp.escape(t.endsWith('*') ? t.substring(0, t.length - 1) : t);
  if (substring) {
    return RegExp(tokens.map(stem).join(r'\s*'), unicode: true);
  }
  final parts = [
    for (final t in tokens) stem(t) + (t.endsWith('*') ? '$_w*' : ''),
  ];
  final tail = tokens.last.endsWith('*') ? '' : '(?!$_w)';
  return RegExp('(?<!$_w)${parts.join(r'\s+')}$tail', unicode: true);
}

/// The banned-phrase rules of every locale.
final class BannedPhrases {
  BannedPhrases._(this._phrases, this._exempt);

  /// Parses the banned-phrase and required-sentence YAML documents.
  factory BannedPhrases.parse(Object? banned, Object? required) {
    if (banned is! Map<String, Object?>) {
      throw const ContentFormatException(
        kBannedPhrasesPath,
        'must be a mapping',
      );
    }
    List<String> strings(Object? value) =>
        value is List ? [for (final v in value) '$v'] : const [];
    final common = banned['common'];
    final commonGlobal = common is Map ? strings(common['global']) : <String>[];
    final locales = banned['locales'];
    final disclaimers = required is Map
        ? required['description_disclaimer']
        : null;
    final phrases = <String, List<(String, RegExp)>>{};
    final exempt = <String, List<String>>{};
    if (locales is Map) {
      for (final entry in locales.entries) {
        final locale = '${entry.key}';
        final rules = entry.value is Map
            ? entry.value as Map
            : const <String, Object?>{};
        final substring = rules['match'] == 'substring';
        phrases[locale] = [
          for (final p in [...commonGlobal, ...strings(rules['global'])])
            (p, phrasePattern(p, substring: substring)),
        ];
        exempt[locale] = [
          if (disclaimers is Map && disclaimers[locale] is String)
            _squash(disclaimers[locale] as String),
          for (final c in strings(rules['allowed_contexts'])) _squash(c),
        ];
      }
    }
    return BannedPhrases._(phrases, exempt);
  }

  /// No rules at all (used when a test needs none).
  factory BannedPhrases.none() => BannedPhrases._(const {}, const {});

  final Map<String, List<(String, RegExp)>> _phrases;
  final Map<String, List<String>> _exempt;

  /// The locales that have rules.
  Iterable<String> get locales => _phrases.keys;

  /// The phrases banned in [locale] (for the translation prompt).
  List<String> phrasesFor(String locale) => [
    for (final (phrase, _) in _phrases[locale] ?? const <(String, RegExp)>[])
      phrase,
  ];

  /// Banned phrases found in [text] for [locale].
  List<String> hits(String text, String locale) {
    var clean = _squash(text);
    for (final span in _exempt[locale] ?? const <String>[]) {
      clean = clean.replaceAll(span, ' ');
    }
    return [
      for (final (phrase, pattern)
          in _phrases[locale] ?? const <(String, RegExp)>[])
        if (pattern.hasMatch(clean)) phrase,
    ];
  }
}
