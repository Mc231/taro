/// Asset paths of the generated content bundle (01 §11, 02 §2.2). Only
/// `tools/content build` and `tools/content/placeholder_art` write these
/// files (RC26).
abstract final class ContentAssets {
  /// Asset key prefix of the bundled content.
  static const String packagePrefix = 'assets';

  /// Folder of the generated content bundle.
  static const String deckDir = '$packagePrefix/deck';

  /// Art key of the card back in every art set.
  static const String cardBackKey = 'card_back';

  /// Path of the generated deck metadata file (the content manifest).
  static String deckMeta() => '$deckDir/deck_meta.json';

  /// File name of the card texts for [languageCode] (e.g. `en.json`), as
  /// listed in the manifest checksums.
  static String deckTextsFile(String languageCode) => '$languageCode.json';

  /// Path of the generated card texts for [languageCode] (e.g. `en`).
  static String deckTexts(String languageCode) =>
      '$deckDir/${deckTextsFile(languageCode)}';

  /// File name of the spread definitions.
  static const String spreadsFile = 'spreads.json';

  /// File name of the crisis-line directory (RC25).
  static const String crisisResourcesFile = 'crisis_resources.json';

  /// Path of a checksummed content [fileName] (see the manifest).
  static String file(String fileName) => '$deckDir/$fileName';

  /// Path of the art for [artKey] (a card ID or [cardBackKey]) in [artSet].
  static String art(String artSet, String artKey) =>
      '$deckDir/art/$artSet/$artKey.webp';

  /// Path of the card back of [artSet].
  static String cardBack(String artSet) => art(artSet, cardBackKey);
}
