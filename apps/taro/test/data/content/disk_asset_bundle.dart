import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// An [AssetBundle] over the real files under `apps/taro/` (the test's
/// working directory), so tests load exactly the committed generated
/// assets. [overrides] replace a key's bytes; [missing] keys fail to load.
final class DiskAssetBundle extends CachingAssetBundle {
  /// Creates the bundle.
  DiskAssetBundle({
    Map<String, List<int>>? overrides,
    Set<String>? missing,
  }) : overrides = overrides ?? {},
       missing = missing ?? {};

  /// Replacement bytes by asset key.
  final Map<String, List<int>> overrides;

  /// Keys that fail as if not bundled.
  final Set<String> missing;

  /// How often each key was loaded.
  final Map<String, int> loads = {};

  @override
  Future<ByteData> load(String key) async {
    loads[key] = (loads[key] ?? 0) + 1;
    if (missing.contains(key)) {
      throw FlutterError('Unable to load asset: "$key".');
    }
    final bytes = overrides[key] ?? File(key).readAsBytesSync();
    return ByteData.sublistView(Uint8List.fromList(bytes));
  }
}

/// A same-isolate runner (for tests that count calls).
Future<R> inlineRunner<R>(FutureOr<R> Function() computation) async =>
    computation();
