/// Canonical content identifiers (GLOSSARY §1, §2; 01 §10.1, §10.3; RC1,
/// RC2). The tools keep their own copy so `tools/dart_tools` stays free of
/// the app packages; `content_ids_test.dart` pins them to the specs.
library;

/// The 12 app locales, `en` first (01 §13).
const List<String> kLocales = [
  'en',
  'ar',
  'de',
  'es',
  'fr',
  'it',
  'ja',
  'ko',
  'nl',
  'pt',
  'tr',
  'uk',
];

/// The source language.
const String kSourceLocale = 'en';

/// The non-source locales (translated in Phase 18).
final List<String> kTargetLocales = List.unmodifiable(
  kLocales.where((l) => l != kSourceLocale),
);

/// Minor-arcana suits in GLOSSARY §1 order, with their elements.
const Map<String, String> kSuitElements = {
  'wands': 'fire',
  'cups': 'water',
  'swords': 'air',
  'pentacles': 'earth',
};

/// The classical elements (01 §10.1 `Element`).
const List<String> kElements = ['fire', 'water', 'air', 'earth'];

String _two(int n) => n.toString().padLeft(2, '0');

/// The 78 card IDs in GLOSSARY §1 order.
final List<String> kCardIds = List.unmodifiable([
  for (var n = 0; n <= 21; n++) 'major_${_two(n)}',
  for (final suit in kSuitElements.keys)
    for (var n = 1; n <= 14; n++) '${suit}_${_two(n)}',
]);

/// The six v1 spreads and their position IDs in draw order (01 §10.3).
const Map<String, List<String>> kSpreadPositions = {
  'single': ['focus'],
  'three_ppf': ['past', 'present', 'future'],
  'three_sao': ['situation', 'action', 'outcome'],
  'relationship': ['you', 'other', 'connection', 'challenge', 'potential'],
  'two_paths': [
    'situation',
    'path_a',
    'path_a_outcome',
    'path_b',
    'path_b_outcome',
  ],
  'celtic_cross': [
    'present',
    'challenge',
    'foundation',
    'recent_past',
    'potential',
    'near_future',
    'self',
    'environment',
    'hopes_fears',
    'outcome',
  ],
};

/// Every distinct position ID, in first-appearance order.
final List<String> kPositionIds = List.unmodifiable(
  {for (final ids in kSpreadPositions.values) ...ids}.toList(),
);

/// The Learn articles (01 §7.9).
const List<String> kArticleIds = ['about', 'faq'];

/// Countries every crisis directory must list (05 §4.2).
const List<String> kRequiredCrisisCountries = [
  'US',
  'GB',
  'IE',
  'CA',
  'AU',
  'DE',
  'FR',
  'ES',
  'IT',
  'NL',
  'JP',
  'KR',
  'TR',
  'UA',
  'BR',
  'PT',
];

/// The international crisis entry that must always be present.
const String kFindAHelplineHost = 'findahelpline.com';

/// `major` or `minor` for [cardId].
String arcanaOf(String cardId) =>
    cardId.startsWith('major_') ? 'major' : 'minor';

/// The suit of [cardId], or `null` for a major card.
String? suitOf(String cardId) =>
    cardId.startsWith('major_') ? null : cardId.split('_').first;

/// The number of [cardId] (0–21 major, 1–14 minor).
int numberOf(String cardId) => int.parse(cardId.split('_').last);
