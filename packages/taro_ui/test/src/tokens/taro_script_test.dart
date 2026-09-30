import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taro_ui/taro_ui.dart';

void main() {
  test('forLocale maps the 12 locales to scripts', () {
    const expected = {
      'en': TaroScript.latin,
      'de': TaroScript.latin,
      'es': TaroScript.latin,
      'fr': TaroScript.latin,
      'it': TaroScript.latin,
      'nl': TaroScript.latin,
      'pt': TaroScript.latin,
      'tr': TaroScript.latin,
      'uk': TaroScript.cyrillic,
      'ar': TaroScript.arabic,
      'ja': TaroScript.cjk,
      'ko': TaroScript.hangul,
    };
    for (final MapEntry(key: code, value: script) in expected.entries) {
      expect(TaroScript.forLocale(Locale(code)), script, reason: code);
    }
  });

  test('forScript puts the script family first, others as fallbacks', () {
    const type = TaroTypeTokens.light;
    const fonts = TaroFontTokens.light;
    final arabic = type.forScript(TaroScript.arabic, fonts);
    expect(arabic.body.fontFamily, 'packages/taro_ui/IBM Plex Sans Arabic');
    expect(arabic.bodyReading.fontFamily, 'packages/taro_ui/Noto Serif Arabic');
    expect(arabic.body.fontFamilyFallback, [
      'packages/taro_ui/IBM Plex Sans',
      'packages/taro_ui/IBM Plex Sans JP',
      'packages/taro_ui/IBM Plex Sans KR',
    ]);
    // Metrics are kept.
    expect(arabic.body.fontSize, type.body.fontSize);
    expect(arabic.body.height, type.body.height);

    final korean = type.forScript(TaroScript.hangul, fonts);
    expect(korean.title.fontFamily, 'packages/taro_ui/IBM Plex Sans KR');
    final japanese = type.forScript(TaroScript.cjk, fonts);
    expect(japanese.headline.fontFamily, 'packages/taro_ui/Noto Serif JP');
    final cyrillic = type.forScript(TaroScript.cyrillic, fonts);
    expect(cyrillic.display.fontFamily, 'packages/taro_ui/Literata');
    // The numeral face is one family for every script.
    expect(korean.numeral.fontFamilyFallback, isEmpty);
    final latin = type.forScript(TaroScript.latin, fonts);
    expect(latin.cardName.fontFamily, type.cardName.fontFamily);
    expect(latin.label.fontWeight, type.label.fontWeight);
    expect(latin.caption.letterSpacing, type.caption.letterSpacing);
  });

  test('stroke constants', () {
    expect(TaroStrokes.hairline, lessThan(TaroStrokes.control));
    expect(TaroStrokes.focusRing, 2);
    expect(TaroStrokes.focusGap, 2);
  });
}
