import 'package:taro/data/content/content_asset_store.dart';
import 'package:taro/data/content/content_assets.dart';
import 'package:taro/data/content/content_manifest.dart';
import 'package:taro_core/taro_core.dart';

/// The fallback locale of the card texts (01 §11).
const String kContentFallbackLocale = 'en';

/// The per-locale card texts from `assets/deck/<locale>.json` (01 §10.1).
///
/// A locale is parsed lazily on first use, in a background isolate (02 §17),
/// and cached; concurrent first calls share one parse.
final class AssetMeaningRepository {
  /// Creates the repository over [store].
  AssetMeaningRepository(this.store);

  /// The bundled content.
  final ContentAssetStore store;

  final Map<String, Future<Map<CardId, CardText>>> _locales = {};

  /// The text of [cardId] in [locale] (`uk`, `pt-BR`, `pt_BR`, …). A locale
  /// without a compiled file, or a card missing from it, falls back to
  /// [kContentFallbackLocale].
  Future<Result<CardText>> cardText(CardId cardId, String locale) =>
      guardContent(() async {
        final manifest = await store.manifest();
        final language = contentLanguage(locale, manifest.locales);
        final texts = await _texts(language);
        return texts[cardId] ??
            (await _texts(kContentFallbackLocale))[cardId] ??
            (throw FormatException('no text for ${cardId.value}'));
      });

  /// Every card text of the compiled [language], parsed once. A failed
  /// parse is not cached, so the next call retries.
  Future<Map<CardId, CardText>> _texts(String language) async {
    final pending = _locales.putIfAbsent(
      language,
      () => store.parseInBackground(
        ContentAssets.deckTextsFile(language),
        parseCardTexts,
      ),
    );
    try {
      return await pending;
    } on Object {
      if (identical(_locales[language], pending)) {
        _locales.remove(language)?.ignore();
      }
      rethrow;
    }
  }
}

/// Parses a compiled `<locale>.json` into its card texts by card ID.
Map<CardId, CardText> parseCardTexts(Map<String, Object?> json) => {
  for (final raw in ContentJson.list(json, 'cards'))
    if (parseCardText(ContentJson.object(raw)) case final text)
      text.cardId: text,
};

/// The compiled language for [locale]: its language subtag when [compiled]
/// has it, else [kContentFallbackLocale].
String contentLanguage(String locale, List<String> compiled) {
  final language = locale.split(RegExp('[-_]')).first.toLowerCase();
  return compiled.contains(language) ? language : kContentFallbackLocale;
}

/// Parses one compiled [CardText]; throws a [FormatException].
CardText parseCardText(Map<String, Object?> json) {
  final aspects = ContentJson.map(json, 'aspects');
  String aspect(String key) => ContentJson.req<String>(aspects, key);
  return CardText(
    cardId: CardId.parse(ContentJson.req<String>(json, 'cardId')),
    locale: ContentJson.req<String>(json, 'locale'),
    name: ContentJson.req<String>(json, 'name'),
    keywordsUpright: ContentJson.strings(json, 'keywordsUpright'),
    keywordsReversed: ContentJson.strings(json, 'keywordsReversed'),
    shortUpright: ContentJson.req<String>(json, 'shortUpright'),
    shortReversed: ContentJson.req<String>(json, 'shortReversed'),
    meaningUpright: ContentJson.req<String>(json, 'meaningUpright'),
    meaningReversed: ContentJson.req<String>(json, 'meaningReversed'),
    aspects: CardAspects(
      relationshipsUpright: aspect('relationshipsUpright'),
      relationshipsReversed: aspect('relationshipsReversed'),
      workUpright: aspect('workUpright'),
      workReversed: aspect('workReversed'),
      growthUpright: aspect('growthUpright'),
      growthReversed: aspect('growthReversed'),
    ),
    reflectionQuestions: ContentJson.strings(json, 'reflectionQuestions'),
    sourceHash: ContentJson.req<String>(json, 'sourceHash'),
    reviewStatus: ReviewStatus.values.byName(
      ContentJson.req<String>(json, 'reviewStatus'),
    ),
    imageryNote: ContentJson.opt<String>(json, 'imageryNote'),
  );
}
