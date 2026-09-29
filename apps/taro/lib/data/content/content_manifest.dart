import 'dart:async';
import 'dart:convert';
import 'dart:isolate';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:taro/data/content/content_assets.dart';
import 'package:taro_core/taro_core.dart';

/// Runs a computation off the UI isolate; [Isolate.run] in production
/// (02 §17). Tests may inject a same-isolate runner.
typedef BackgroundRunner = Future<R> Function<R>(FutureOr<R> Function());

/// The production [BackgroundRunner].
Future<R> isolateRunner<R>(FutureOr<R> Function() computation) =>
    Isolate.run(computation);

/// A bundled content file is missing from the manifest or its bytes do not
/// match the recorded checksum. Repositories turn it into [failure].
final class ContentIntegrityException implements Exception {
  /// Creates the exception for [fileName].
  const ContentIntegrityException(this.fileName, this.reason);

  /// The content file, e.g. `en.json`.
  final String fileName;

  /// What is wrong.
  final String reason;

  /// The failure the repositories return: a corrupt bundle is a
  /// [StorageFailure].
  StorageFailure get failure => const StorageFailure();

  @override
  String toString() => 'ContentIntegrityException($fileName: $reason)';
}

/// `assets/deck/deck_meta.json` (01 §11): deck identity, the locale-free
/// cards, the compiled locales and a SHA-256 per content file. Every other
/// content file is verified against it at load.
final class ContentManifest {
  /// Creates a manifest.
  ContentManifest({
    required this.deckId,
    required this.version,
    required this.artSet,
    required List<String> locales,
    required List<DeckCard> cards,
    required Map<String, String> checksums,
  }) : locales = List.unmodifiable(locales),
       cards = List.unmodifiable(cards),
       checksums = Map.unmodifiable(checksums);

  /// Parses `deck_meta.json`; throws a [FormatException] on a wrong shape.
  factory ContentManifest.fromJson(Map<String, Object?> json) {
    final checksums = ContentJson.map(json, 'checksums');
    return ContentManifest(
      deckId: ContentJson.req<String>(json, 'id'),
      version: ContentJson.req<int>(json, 'version'),
      artSet: ContentJson.req<String>(json, 'artSet'),
      locales: ContentJson.strings(json, 'locales'),
      cards: [
        for (final c in ContentJson.list(json, 'cards'))
          _deckCard(ContentJson.object(c)),
      ],
      checksums: {
        for (final MapEntry(:key, :value) in checksums.entries)
          key: value is String
              ? value
              : throw FormatException('checksum of $key is not a string'),
      },
    );
  }

  /// Loads and parses the manifest from [bundle].
  static Future<ContentManifest> load(AssetBundle bundle) async {
    final raw = await bundle.loadString(ContentAssets.deckMeta(), cache: false);
    return ContentManifest.fromJson(ContentJson.object(jsonDecode(raw)));
  }

  /// Deck ID, `rws_original`.
  final String deckId;

  /// Content version.
  final int version;

  /// The bundled art set, e.g. `placeholder`.
  final String artSet;

  /// Locales with a compiled `<locale>.json`.
  final List<String> locales;

  /// The 78 cards in canonical order.
  final List<DeckCard> cards;

  /// SHA-256 (hex) by content file name.
  final Map<String, String> checksums;

  /// The deck; throws an [ArgumentError] unless it is the 78 canonical
  /// cards.
  Deck deck() => Deck.validated(
    id: deckId,
    version: version,
    cards: cards,
    artSet: artSet,
  );

  /// Throws a [ContentIntegrityException] unless [bytes] hash to the
  /// checksum recorded for [fileName].
  void verify(String fileName, List<int> bytes) =>
      verifyChecksum(fileName, checksums[fileName], bytes);

  /// The raw bytes of [fileName] from [bundle] (not yet verified).
  Future<Uint8List> loadBytes(AssetBundle bundle, String fileName) async {
    final data = await bundle.load(ContentAssets.file(fileName));
    return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  }

  /// Loads [fileName] from [bundle], verifies its checksum and decodes its
  /// JSON object.
  Future<Map<String, Object?>> loadJson(
    AssetBundle bundle,
    String fileName,
  ) async => decodeVerified(
    fileName,
    checksums[fileName],
    await loadBytes(bundle, fileName),
  );
}

/// Throws a [ContentIntegrityException] unless [bytes] hash to [expected].
void verifyChecksum(String fileName, String? expected, List<int> bytes) {
  if (expected == null) {
    throw ContentIntegrityException(fileName, 'no checksum in the manifest');
  }
  final actual = sha256.convert(bytes).toString();
  if (actual != expected) {
    throw ContentIntegrityException(
      fileName,
      'checksum mismatch (expected $expected, got $actual)',
    );
  }
}

/// Verifies [bytes] against [expected], then decodes them as a UTF-8 JSON
/// object. Top-level so it can run in another isolate.
Map<String, Object?> decodeVerified(
  String fileName,
  String? expected,
  Uint8List bytes,
) {
  verifyChecksum(fileName, expected, bytes);
  return ContentJson.object(jsonDecode(utf8.decode(bytes)));
}

DeckCard _deckCard(Map<String, Object?> json) {
  final suit = ContentJson.opt<String>(json, 'suit');
  final element = ContentJson.opt<String>(json, 'element');
  return DeckCard(
    id: CardId.parse(ContentJson.req<String>(json, 'id')),
    arcana: Arcana.values.byName(ContentJson.req<String>(json, 'arcana')),
    suit: suit == null ? null : Suit.values.byName(suit),
    number: ContentJson.req<int>(json, 'number'),
    artKey: ContentJson.req<String>(json, 'artKey'),
    element: element == null ? null : Element.values.byName(element),
    astrology: ContentJson.opt<String>(json, 'astrology'),
  );
}

/// JSON readers of the content repositories: each throws a
/// [FormatException] on a wrong shape.
abstract final class ContentJson {
  /// [value] as a JSON object.
  static Map<String, Object?> object(Object? value) =>
      value is Map<String, Object?>
      ? value
      : throw const FormatException('expected a JSON object');

  /// A required field of type [T].
  static T req<T>(Map<String, Object?> json, String key) {
    final value = json[key];
    if (value is T) return value;
    throw FormatException('"$key" is missing or not a $T');
  }

  /// An optional field of type [T].
  static T? opt<T>(Map<String, Object?> json, String key) {
    final value = json[key];
    if (value == null || value is T) return value as T?;
    throw FormatException('"$key" is not a $T');
  }

  /// A required list.
  static List<Object?> list(Map<String, Object?> json, String key) =>
      req<List<Object?>>(json, key);

  /// A required list of strings.
  static List<String> strings(Map<String, Object?> json, String key) => [
    for (final s in list(json, key))
      s is String ? s : throw FormatException('"$key" must hold strings'),
  ];

  /// A required object.
  static Map<String, Object?> map(Map<String, Object?> json, String key) =>
      req<Map<String, Object?>>(json, key);
}
