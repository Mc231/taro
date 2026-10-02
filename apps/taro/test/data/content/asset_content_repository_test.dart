import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taro/data/content/asset_content_repository.dart';
import 'package:taro/data/content/asset_meaning_repository.dart';
import 'package:taro/data/content/asset_spread_repository.dart';
import 'package:taro/data/content/content_assets.dart';
import 'package:taro_core/taro_core.dart';

// The allowed exception: taro_core's contract suites by relative path.
import '../../../../../packages/taro_core/test/contracts/content_contracts.dart';
import '../../../../../packages/taro_core/test/contracts/contract_support.dart';
import 'disk_asset_bundle.dart';

AssetContentRepository _repo(DiskAssetBundle bundle) =>
    AssetContentRepository.fromBundle(bundle, runner: inlineRunner);

void main() {
  // Real Isolate.run, real committed assets.
  runContentRepositoryContract(
    () => AssetContentRepository.fromBundle(DiskAssetBundle()),
  );

  group('real assets', () {
    late DiskAssetBundle bundle;
    late AssetContentRepository content;

    setUp(() {
      bundle = DiskAssetBundle();
      content = _repo(bundle);
    });

    test('the deck is 78 cards and cached', () async {
      final deck = expectOk(await content.deck());
      expect(deck.cards, hasLength(78));
      expect(deck.id, 'rws_original');
      expect(deck.artSet, 'codex_v1');
      expect(expectOk(await content.deck()), same(deck));
      expect(bundle.loads[ContentAssets.deckMeta()], 1);
    });

    test(
      'six spreads in 01 §10.3 order; Celtic Cross challenge is 90°',
      () async {
        final spreads = expectOk(await content.spreads());
        expect(spreads.map((s) => s.id), kSpreadIds);
        final cross = spreads.last;
        expect(cross.cardCount, 10);
        expect(
          cross.position(const PositionId('challenge'))!.rotationDeg,
          90,
        );
        expect(
          spreads.first.questionSuggestionKeys,
          everyElement(startsWith('spread_single_suggestion_')),
        );
        expect(expectOk(await content.spreads()), same(spreads));
      },
    );

    test('all 78 English texts are complete', () async {
      for (final id in kCardIds) {
        final text = expectOk(await content.cardText(id, 'en'));
        expect(text.locale, 'en');
        expect(text.keywordsUpright.length, inInclusiveRange(3, 6));
        expect(text.keywordsReversed.length, inInclusiveRange(3, 6));
        expect(text.reflectionQuestions, hasLength(3));
        expect(text.shortUpright.length, lessThanOrEqualTo(160));
        expect(text.aspects.growthReversed, isNotEmpty);
        expect(text.imageryNote, isNotNull);
        expect(text.sourceHash, hasLength(64));
      }
      final fool = expectOk(
        await content.cardText(const CardId('major_00'), 'en'),
      );
      expect(fool.name, 'The Fool');
      // One parse for all 79 calls.
      expect(bundle.loads[ContentAssets.deckTexts('en')], 1);
    });

    test(
      'regional locales use their language; unknown fall back to en',
      () async {
        const id = CardId('cups_03');
        final en = expectOk(await content.cardText(id, 'en'));
        expect(expectOk(await content.cardText(id, 'sv')), en);
        expect(expectOk(await content.cardText(id, 'pt-BR')).locale, 'pt');
        // Phase 18: every shipped locale has its own deck texts.
        final uk = expectOk(await content.cardText(id, 'uk'));
        expect(uk.locale, 'uk');
        expect(uk.name, isNot(en.name));
        expect(expectOk(await content.cardText(id, 'EN_gb')), en);
      },
    );

    test('crisis fallback by region', () async {
      final de = expectOk(await content.fallbackCrisisResources('DE'));
      expect(de.first.name, 'TelefonSeelsorge');
      expect(de.last.url, contains('findahelpline.com'));
      final unknown = expectOk(await content.fallbackCrisisResources('ZZ'));
      expect(unknown, hasLength(1));
    });
  });

  group('failures are StorageFailure', () {
    test('checksum mismatch of a locale file', () async {
      final key = ContentAssets.deckTexts('en');
      final bytes = File(key).readAsBytesSync();
      final content = _repo(
        DiskAssetBundle(
          overrides: {
            key: [...bytes]..[100] ^= 1,
          },
        ),
      );
      expect(
        expectErr(await content.cardText(const CardId('major_00'), 'en')),
        const Failure.storage(),
      );
      // The deck itself does not depend on en.json.
      expect((await content.deck()).isOk, isTrue);
    });

    test('checksum mismatch of spreads.json', () async {
      final key = ContentAssets.file(ContentAssets.spreadsFile);
      final content = _repo(
        DiskAssetBundle(
          overrides: {
            key: File(key).readAsBytesSync() + [10],
          },
        ),
      );
      expect(expectErr(await content.spreads()), const Failure.storage());
    });

    test('a missing manifest fails every call, then retries', () async {
      final bundle = DiskAssetBundle(missing: {ContentAssets.deckMeta()});
      final content = _repo(bundle);
      expect(expectErr(await content.deck()), const Failure.storage());
      expect(expectErr(await content.spreads()), const Failure.storage());
      expect(
        expectErr(await content.cardText(const CardId('major_00'), 'en')),
        const Failure.storage(),
      );
      expect(
        expectErr(await content.fallbackCrisisResources('DE')),
        const Failure.storage(),
      );
      bundle.missing.clear();
      expect((await content.deck()).isOk, isTrue);
      expect(bundle.loads[ContentAssets.deckMeta()], 5);
    });

    test('a failed locale parse is retried', () async {
      final key = ContentAssets.deckTexts('en');
      final bundle = DiskAssetBundle(missing: {key});
      final content = _repo(bundle);
      const id = CardId('major_01');
      expect((await content.cardText(id, 'en')).isErr, isTrue);
      bundle.missing.clear();
      expect(expectOk(await content.cardText(id, 'en')).name, 'The Magician');
      expect(bundle.loads[key], 2);
    });
  });

  group('parsers', () {
    test('contentLanguage', () {
      expect(contentLanguage('uk-UA', ['en', 'uk']), 'uk');
      expect(contentLanguage('pt_BR', ['en']), 'en');
      expect(contentLanguage('', ['en']), 'en');
    });

    test('a card missing from every locale file is a StorageFailure', () async {
      final texts =
          jsonDecode(
                File(ContentAssets.deckTexts('en')).readAsStringSync(),
              )
              as Map<String, Object?>;
      (texts['cards']! as List).removeAt(0);
      final en = utf8.encode(jsonEncode(texts));
      final meta =
          jsonDecode(
                File(ContentAssets.deckMeta()).readAsStringSync(),
              )
              as Map<String, Object?>;
      (meta['checksums']! as Map<String, Object?>)['en.json'] = sha256
          .convert(en)
          .toString();
      final content = _repo(
        DiskAssetBundle(
          overrides: {
            ContentAssets.deckTexts('en'): en,
            ContentAssets.deckMeta(): utf8.encode(jsonEncode(meta)),
          },
        ),
      );
      expect(
        expectErr(await content.cardText(const CardId('major_00'), 'en')),
        const Failure.storage(),
      );
      expect(
        (await content.cardText(const CardId('major_01'), 'en')).isOk,
        isTrue,
      );
      expect(parseCardTexts({'cards': <Object?>[]}), isEmpty);
    });

    test('parseSpread rejects a broken invariant', () {
      Map<String, Object?> spread(double x) => {
        'id': 'single',
        'version': 1,
        'allowsReversals': true,
        'questionSuggestionKeys': <Object?>[],
        'positions': <Object?>[
          {'id': 'focus', 'order': 1, 'x': x, 'y': 0.5, 'rotationDeg': 0},
        ],
      };
      expect(parseSpread(spread(0.5)).positions.single.x, 0.5);
      expect(() => parseSpread(spread(1.5)), throwsFormatException);
    });
  });
}
