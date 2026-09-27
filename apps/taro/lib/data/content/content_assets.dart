/// Asset paths of the generated content bundle (01 §11, 02 §2.2).
abstract final class ContentAssets {
  /// Asset key prefix of the bundled content.
  static const String packagePrefix = 'assets';

  /// Path of the generated deck metadata file.
  static String deckMeta() => '$packagePrefix/deck/deck_meta.json';

  /// Path of the generated card texts for [languageCode] (e.g. `en`).
  static String deckTexts(String languageCode) =>
      '$packagePrefix/deck/$languageCode.json';
}
