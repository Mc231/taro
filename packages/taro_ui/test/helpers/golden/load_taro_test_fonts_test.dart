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

  test('withTaroTestFonts sets the family and script fallbacks', () {
    final theme = withTaroTestFonts(ThemeData());
    final style = theme.textTheme.bodyMedium!;
    expect(style.fontFamily, kTaroTestFontFamily);
    expect(style.fontFamilyFallback, kTaroTestFontFallback);
    expect(
      theme.primaryTextTheme.titleLarge!.fontFamilyFallback,
      kTaroTestFontFallback,
    );
  });
}
