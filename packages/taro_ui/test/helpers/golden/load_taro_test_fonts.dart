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

/// The fonts `taro_ui` bundles (pubspec `flutter.fonts`, Phase 15): family
/// → files under [kTaroBundledFontsDir]. Tests load them under the
/// `packages/taro_ui/<family>` names that `TextStyle(package: 'taro_ui')`
/// asks for, so goldens render the real Taro typefaces.
const Map<String, List<String>> kTaroBundledFonts = {
  'Literata': [
    'Literata-Regular.ttf',
    'Literata-Medium.ttf',
    'Literata-SemiBold.ttf',
  ],
  'IBM Plex Sans': [
    'TaroSans-Regular.ttf',
    'TaroSans-Medium.ttf',
    'TaroSans-SemiBold.ttf',
  ],
  'IBM Plex Sans Arabic': [
    'TaroSansArabic-Regular.ttf',
    'TaroSansArabic-Medium.ttf',
    'TaroSansArabic-SemiBold.ttf',
  ],
  'IBM Plex Sans JP': ['TaroSansJP-Regular.ttf', 'TaroSansJP-SemiBold.ttf'],
  'IBM Plex Sans KR': ['TaroSansKR-Regular.ttf', 'TaroSansKR-SemiBold.ttf'],
  'Noto Serif Arabic': [
    'NotoNaskhArabic-Regular.ttf',
    'NotoNaskhArabic-Medium.ttf',
    'NotoNaskhArabic-SemiBold.ttf',
  ],
  'Noto Serif JP': ['NotoSerifJP-Regular.ttf', 'NotoSerifJP-SemiBold.ttf'],
  'Noto Serif KR': ['NotoSerifKR-Regular.ttf', 'NotoSerifKR-SemiBold.ttf'],
  'IM Fell English SC': ['IMFellEnglishSC-Regular.ttf'],
};

/// Repository-relative directory of the bundled `taro_ui` fonts.
const String kTaroBundledFontsDir = 'packages/taro_ui/fonts';

bool _loaded = false;

/// Locates [kTaroTestFontsDir] by walking up from [start] (default: the
/// current directory, which `flutter test` sets to the package root).
Directory findTaroTestFontsDir([Directory? start]) =>
    _findUp(kTaroTestFontsDir, start);

/// Locates [kTaroBundledFontsDir] like [findTaroTestFontsDir].
Directory findTaroBundledFontsDir([Directory? start]) =>
    _findUp(kTaroBundledFontsDir, start);

Directory _findUp(String relative, Directory? start) {
  Directory? dir = (start ?? Directory.current).absolute;
  while (dir != null) {
    final candidate = Directory('${dir.path}/$relative');
    if (candidate.existsSync()) return candidate;
    final parent = dir.parent;
    dir = parent.path == dir.path ? null : parent;
  }
  throw StateError('No $relative above ${Directory.current.path}');
}

/// Loads the Noto test fonts and the bundled `taro_ui` fonts into the engine
/// (06 QA8). Idempotent.
///
/// Called from each package's `flutter_test_config.dart`, so every test
/// renders real glyphs (including Arabic, Japanese and Korean) instead of the
/// `FlutterTest` boxes: Taro's own typefaces for the token text styles, Noto
/// Sans for Material's default families.
Future<void> loadTaroTestFonts({
  Directory? fontsDir,
  Directory? bundledFontsDir,
}) async {
  if (_loaded) return;
  final dir = fontsDir ?? findTaroTestFontsDir();
  final bundled = bundledFontsDir ?? findTaroBundledFontsDir();
  Future<ByteData> bytesOf(String file, [Directory? from]) async {
    final bytes = await File('${(from ?? dir).path}/$file').readAsBytes();
    return ByteData.sublistView(Uint8List.fromList(bytes));
  }

  await loadMaterialIconsFont();
  for (final MapEntry(key: family, value: files) in kTaroBundledFonts.entries) {
    final loader = FontLoader('packages/taro_ui/$family');
    for (final file in files) {
      loader.addFont(bytesOf(file, bundled));
    }
    await loader.load();
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

/// The Material Icons font of the pinned Flutter SDK (`FLUTTER_ROOT`, set by
/// `flutter test`), so icons render as glyphs in goldens instead of boxes.
/// Returns false when the SDK font is not found.
Future<bool> loadMaterialIconsFont({String? flutterRoot}) async {
  final root = flutterRoot ?? Platform.environment['FLUTTER_ROOT'];
  final file = File(
    '$root/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
  );
  if (root == null || !file.existsSync()) return false;
  final bytes = await file.readAsBytes();
  await (FontLoader(
    'MaterialIcons',
  )..addFont(Future.value(ByteData.sublistView(bytes)))).load();
  return true;
}

/// [theme] as used in tests. Since Phase 15 the Taro themes use the bundled
/// token fonts, which [loadTaroTestFonts] registers, so the theme is returned
/// unchanged; Material's default families still resolve to Noto Sans
/// ([kPlatformFontAliases]).
ThemeData withTaroTestFonts(ThemeData theme) => theme;
