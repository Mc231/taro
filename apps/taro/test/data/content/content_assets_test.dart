import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:taro/common/card_art.dart';
import 'package:taro/data/content/content_assets.dart';
import 'package:taro/data/content/content_manifest.dart';
import 'package:taro_core/taro_core.dart';

import 'disk_asset_bundle.dart';

void main() {
  group('ContentAssets', () {
    test('deckMeta points into the package asset folder', () {
      expect(ContentAssets.deckMeta(), 'assets/deck/deck_meta.json');
    });

    test('deckTexts is per language', () {
      expect(ContentAssets.deckTexts('uk'), 'assets/deck/uk.json');
      expect(ContentAssets.deckTextsFile('uk'), 'uk.json');
    });

    test('content files and art paths', () {
      expect(
        ContentAssets.file(ContentAssets.spreadsFile),
        'assets/deck/spreads.json',
      );
      expect(
        ContentAssets.file(ContentAssets.crisisResourcesFile),
        'assets/deck/crisis_resources.json',
      );
      expect(
        ContentAssets.art('placeholder', 'cups_03'),
        'assets/deck/art/placeholder/cups_03.webp',
      );
      expect(
        ContentAssets.cardBack('placeholder'),
        'assets/deck/art/placeholder/card_back.webp',
      );
    });
  });

  test('the bundled art set has every card and a card back', () async {
    final manifest = await ContentManifest.load(DiskAssetBundle());
    expect(manifest.artSet, 'codex_v1');
    expect(manifest.artSet, CardArt.defaultArtSet);
    for (final card in manifest.cards) {
      expect(card.artKey, card.id.value);
      final file = File(ContentAssets.art(manifest.artSet, card.artKey));
      expect(file.existsSync(), isTrue, reason: file.path);
    }
    expect(File(ContentAssets.cardBack(manifest.artSet)).existsSync(), isTrue);
    for (final key in [...manifest.cards.map((c) => c.artKey), 'card_back']) {
      final x3 = File('assets/deck/art/${manifest.artSet}/3.0x/$key.webp');
      expect(x3.existsSync(), isTrue, reason: x3.path);
      expect(x3.lengthSync(), lessThanOrEqualTo(150000), reason: x3.path);
    }
    expect(manifest.cards.map((c) => c.id), kCardIds);
  });

  test('pubspec declares the deck and art folders', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(pubspec, contains('    - assets/deck/\n'));
    expect(pubspec, contains('    - assets/deck/art/placeholder/\n'));
    expect(pubspec, contains('    - assets/deck/art/codex_v1/\n'));
  });
}
