import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'load_taro_test_fonts.dart';

double _width(String text, String family) {
  final painter = TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(fontFamily: family, fontSize: 20),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  final width = painter.width;
  painter.dispose();
  return width;
}

void main() {
  test('every font file exists', () {
    final dir = findTaroTestFontsDir();
    for (final file in kTaroTestFontFiles.values) {
      expect(File('${dir.path}/$file').existsSync(), isTrue, reason: file);
    }
    expect(File('${dir.path}/OFL.txt').existsSync(), isTrue);
  });

  test('findTaroTestFontsDir fails outside the repository', () {
    expect(
      () => findTaroTestFontsDir(Directory.systemTemp),
      throwsStateError,
    );
  });

  testWidgets('Noto Sans is proportional, not the square test font', (
    tester,
  ) async {
    // flutter_test_config.dart already loaded the fonts; a second call is a
    // no-op.
    await loadTaroTestFonts();
    for (final family in [kTaroTestFontFamily, 'Roboto']) {
      expect(_width('iiii', family), lessThan(_width('MMMM', family)));
    }
  });

  test('every bundled taro_ui font file exists and is declared', () {
    final dir = findTaroBundledFontsDir();
    final pubspec = File('${dir.parent.path}/pubspec.yaml').readAsStringSync();
    for (final MapEntry(key: family, value: files)
        in kTaroBundledFonts.entries) {
      expect(pubspec, contains('- family: $family'), reason: family);
      for (final file in files) {
        expect(File('${dir.path}/$file').existsSync(), isTrue, reason: file);
        expect(pubspec, contains('asset: fonts/$file'), reason: file);
      }
    }
  });

  testWidgets('the bundled token fonts are loaded under their package names', (
    tester,
  ) async {
    for (final family in kTaroBundledFonts.keys) {
      final name = 'packages/taro_ui/$family';
      expect(
        _width('iiii', name),
        lessThan(_width('MMMM', name)),
        reason: name,
      );
    }
  });

  test('loadMaterialIconsFont needs the Flutter SDK', () async {
    expect(await loadMaterialIconsFont(flutterRoot: '/nonexistent'), isFalse);
    expect(await loadMaterialIconsFont(), isTrue);
  });

  test('withTaroTestFonts keeps the theme (token fonts are loaded)', () {
    final theme = ThemeData();
    expect(withTaroTestFonts(theme), same(theme));
  });
}
