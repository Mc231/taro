import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taro/data/content/content_assets.dart';
import 'package:taro/data/content/content_manifest.dart';
import 'package:taro_core/taro_core.dart';

import 'disk_asset_bundle.dart';

Map<String, Object?> _meta() =>
    jsonDecode(File(ContentAssets.deckMeta()).readAsStringSync())
        as Map<String, Object?>;

void main() {
  group('ContentManifest', () {
    test('loads the real deck_meta.json', () async {
      final manifest = await ContentManifest.load(DiskAssetBundle());
      expect(manifest.deckId, 'rws_original');
      expect(manifest.version, greaterThanOrEqualTo(1));
      expect(manifest.locales, contains('en'));
      expect(manifest.cards, hasLength(Deck.size));
      expect(
        manifest.checksums.keys,
        containsAll(['en.json', 'spreads.json', 'crisis_resources.json']),
      );
      final deck = manifest.deck();
      expect(Deck.problemsOf(deck.cards), isEmpty);
      final fool = deck.card(const CardId('major_00'))!;
      expect(fool.arcana, Arcana.major);
      expect(fool.suit, isNull);
      final cup = deck.card(const CardId('cups_03'))!;
      expect(
        (cup.suit, cup.element, cup.number),
        (
          Suit.cups,
          Element.water,
          3,
        ),
      );
    });

    test('every checksum matches its committed file', () async {
      final bundle = DiskAssetBundle();
      final manifest = await ContentManifest.load(bundle);
      for (final name in manifest.checksums.keys) {
        final json = await manifest.loadJson(bundle, name);
        expect(json, isNotEmpty, reason: name);
      }
    });

    test('verify throws a StorageFailure-carrying exception on mismatch', () {
      final manifest = ContentManifest.fromJson(_meta());
      final bytes = File(ContentAssets.file('spreads.json')).readAsBytesSync();
      expect(() => manifest.verify('spreads.json', bytes), returnsNormally);
      final tampered = [...bytes]..[10] ^= 1;
      expect(
        () => manifest.verify('spreads.json', tampered),
        throwsA(
          isA<ContentIntegrityException>()
              .having((e) => e.fileName, 'fileName', 'spreads.json')
              .having((e) => e.reason, 'reason', contains('mismatch'))
              .having((e) => e.failure, 'failure', const Failure.storage())
              .having((e) => '$e', 'toString', contains('spreads.json')),
        ),
      );
      expect(
        () => manifest.verify('xx.json', bytes),
        throwsA(
          isA<ContentIntegrityException>().having(
            (e) => e.reason,
            'reason',
            contains('no checksum'),
          ),
        ),
      );
    });

    test('loadJson rejects tampered bytes', () async {
      final key = ContentAssets.file('crisis_resources.json');
      final original = File(key).readAsBytesSync();
      final bundle = DiskAssetBundle(
        overrides: {
          key: [...original, 0x20],
        },
      );
      final manifest = await ContentManifest.load(bundle);
      await expectLater(
        manifest.loadJson(bundle, 'crisis_resources.json'),
        throwsA(isA<ContentIntegrityException>()),
      );
    });

    test('decodeVerified requires a JSON object', () {
      final bytes = Uint8List.fromList(utf8.encode('[1]'));
      final hash = sha256.convert(bytes).toString();
      expect(
        () => decodeVerified('a.json', hash, bytes),
        throwsFormatException,
      );
    });

    test('fromJson rejects wrong shapes', () {
      for (final edit in <void Function(Map<String, Object?>)>[
        (m) => m.remove('id'),
        (m) => m['version'] = '1',
        (m) => m['locales'] = [1],
        (m) => m['checksums'] = {'en.json': 1},
        (m) => m['cards'] = ['x'],
        (m) => (m['cards']! as List)[0] = {
          ...((m['cards']! as List)[0] as Map<String, Object?>),
          'astrology': 3,
        },
        (m) => (m['cards']! as List)[0] = {
          ...((m['cards']! as List)[0] as Map<String, Object?>),
          'id': 'major_99',
        },
      ]) {
        final meta = _meta();
        edit(meta);
        expect(() => ContentManifest.fromJson(meta), throwsFormatException);
      }
    });

    test('deck() rejects a deck that is not the 78 canonical cards', () {
      final meta = _meta();
      (meta['cards']! as List).removeLast();
      expect(
        () => ContentManifest.fromJson(meta).deck(),
        throwsArgumentError,
      );
    });

    test('isolateRunner runs in another isolate', () async {
      expect(await isolateRunner(() => 6 * 7), 42);
    });
  });

  group('ContentJson', () {
    test('object and strings', () {
      expect(() => ContentJson.object([]), throwsFormatException);
      expect(
        ContentJson.strings({
          'a': <Object?>['x'],
        }, 'a'),
        ['x'],
      );
      expect(
        () => ContentJson.strings({
          'a': <Object?>[1],
        }, 'a'),
        throwsFormatException,
      );
      expect(ContentJson.opt<String>({}, 'a'), isNull);
      expect(
        () => ContentJson.opt<String>({'a': 1}, 'a'),
        throwsFormatException,
      );
      expect(ContentJson.map({'a': <String, Object?>{}}, 'a'), isEmpty);
    });
  });
}
