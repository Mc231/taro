import 'package:flutter/services.dart';
import 'package:taro/data/content/content_manifest.dart';
import 'package:taro_core/taro_core.dart';

/// The bundled content of one [AssetBundle]: loads the [ContentManifest]
/// once and hands out checksum-verified JSON files (01 §11, RC26). Shared
/// by the `Asset*Repository` classes.
final class ContentAssetStore {
  /// Creates the store over [bundle]; [runner] parses the large per-locale
  /// files off the UI isolate (default [isolateRunner]).
  ContentAssetStore(this.bundle, {BackgroundRunner? runner})
    : runner = runner ?? isolateRunner;

  /// Where the assets come from (`rootBundle` in the app).
  final AssetBundle bundle;

  /// Runs the per-locale parse in the background.
  final BackgroundRunner runner;

  Future<ContentManifest>? _manifest;

  /// The manifest, loaded on first use and cached. A failed load is not
  /// cached, so the next call retries.
  Future<ContentManifest> manifest() async {
    final pending = _manifest ??= ContentManifest.load(bundle);
    try {
      return await pending;
    } on Object {
      if (identical(_manifest, pending)) _manifest = null;
      rethrow;
    }
  }

  /// The verified JSON object of [fileName], decoded on this isolate (for
  /// the small files).
  Future<Map<String, Object?>> json(String fileName) async =>
      (await manifest()).loadJson(bundle, fileName);

  /// Verifies, decodes and [parse]s [fileName] on [runner] (for the large
  /// per-locale files; [parse] must be a top-level or static function).
  Future<T> parseInBackground<T>(
    String fileName,
    T Function(Map<String, Object?> json) parse,
  ) async {
    final m = await manifest();
    final bytes = await m.loadBytes(bundle, fileName);
    return _parseOn(runner, fileName, m.checksums[fileName], bytes, parse);
  }
}

// Top-level so the closure sent to another isolate captures only its
// arguments (never the store or its AssetBundle).
Future<T> _parseOn<T>(
  BackgroundRunner runner,
  String fileName,
  String? expected,
  Uint8List bytes,
  T Function(Map<String, Object?> json) parse,
) => runner(() => parse(decodeVerified(fileName, expected, bytes)));

/// Runs [body] and maps every error to `Err(StorageFailure)`: bundled
/// content that is missing, corrupt or fails its checksum is a storage
/// failure (02 §3); repositories never throw across the port.
Future<Result<T>> guardContent<T>(Future<T> Function() body) async {
  try {
    return Ok(await body());
  } on Object {
    return const Err(StorageFailure());
  }
}
