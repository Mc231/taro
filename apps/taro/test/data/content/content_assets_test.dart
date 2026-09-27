import 'package:flutter_test/flutter_test.dart';
import 'package:taro/data/content/content_assets.dart';

void main() {
  group('ContentAssets', () {
    test('deckMeta points into the package asset folder', () {
      expect(
        ContentAssets.deckMeta(),
        'assets/deck/deck_meta.json',
      );
    });

    test('deckTexts is per language', () {
      expect(
        ContentAssets.deckTexts('uk'),
        'assets/deck/uk.json',
      );
    });
  });
}
