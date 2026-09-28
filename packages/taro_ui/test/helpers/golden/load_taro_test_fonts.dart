import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// The primary test font family (Noto Sans, Latin/Greek/Cyrillic).
const String kTaroTestFontFamily = 'NotoSans';

/// Fallback families for scripts Noto Sans lacks: Arabic, Japanese, Korean.
const List<String> kTaroTestFontFallback = [
  'NotoSansArabic',
  'NotoSansJP',
  'NotoSansKR',
];

/// Default platform families that Material and Cupertino text styles ask for
/// in tests; Noto Sans is registered under each, so text never falls back to
/// the square `FlutterTest` font.
const List<String> kPlatformFontAliases = [
  'Roboto',
  '.SF UI Text',
  '.SF UI Display',
  'CupertinoSystemText',
  'CupertinoSystemDisplay',
];

/// Font file per family, relative to [kTaroTestFontsDir].
const Map<String, String> kTaroTestFontFiles = {
  kTaroTestFontFamily: 'NotoSans-Regular.ttf',
  'NotoSansArabic': 'NotoSansArabic-Regular.ttf',
  'NotoSansJP': 'NotoSansJP-Regular.ttf',
  'NotoSansKR': 'NotoSansKR-Regular.ttf',
};

/// Repository-relative directory of the bundled test fonts (OFL, see
/// `fonts/NOTICE.md`).
const String kTaroTestFontsDir = 'packages/taro_ui/test/helpers/golden/fonts';

bool _loaded = false;

/// Locates [kTaroTestFontsDir] by walking up from [start] (default: the
/// current directory, which `flutter test` sets to the package root).
Directory findTaroTestFontsDir([Directory? start]) {
  Directory? dir = (start ?? Directory.current).absolute;
  while (dir != null) {
    final candidate = Directory('${dir.path}/$kTaroTestFontsDir');
    if (candidate.existsSync()) return candidate;
    final parent = dir.parent;
    dir = parent.path == dir.path ? null : parent;
  }
  throw StateError('No $kTaroTestFontsDir above ${Directory.current.path}');
}

/// Loads the bundled Noto test fonts into the engine (06 QA8). Idempotent.
///
/// Called from each package's `flutter_test_config.dart`, so every test
/// renders real glyphs (including Arabic, Japanese and Korean) instead of the
/// `FlutterTest` boxes.
Future<void> loadTaroTestFonts({Directory? fontsDir}) async {
  if (_loaded) return;
  final dir = fontsDir ?? findTaroTestFontsDir();
  Future<ByteData> bytesOf(String file) async {
    final bytes = await File('${dir.path}/$file').readAsBytes();
    return ByteData.sublistView(Uint8List.fromList(bytes));
  }

  for (final MapEntry(key: family, value: file) in kTaroTestFontFiles.entries) {
    final families = family == kTaroTestFontFamily
        ? [family, ...kPlatformFontAliases]
        : [family];
    for (final name in families) {
      await (FontLoader(name)..addFont(bytesOf(file))).load();
    }
  }
  _loaded = true;
}

/// [theme] with the test font family and the script fallbacks applied to its
/// text themes, so mixed-script text renders with real glyphs.
ThemeData withTaroTestFonts(ThemeData theme) => theme.copyWith(
  textTheme: theme.textTheme.apply(
    fontFamily: kTaroTestFontFamily,
    fontFamilyFallback: kTaroTestFontFallback,
  ),
  primaryTextTheme: theme.primaryTextTheme.apply(
    fontFamily: kTaroTestFontFamily,
    fontFamilyFallback: kTaroTestFontFallback,
  ),
);
