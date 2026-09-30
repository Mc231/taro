import 'package:flutter/painting.dart';
import 'package:taro_ui/src/tokens/generated/taro_tokens.g.dart';
import 'package:taro_ui/src/tokens/taro_script.dart';

/// The `font.family.{role}` tokens of one type role.
typedef _RoleFamilies = ({
  String latin,
  String cyrillic,
  String arabic,
  String cjk,
  String hangul,
});

/// Swaps the type roles to a script's families at runtime (BRIEF §3.7: each
/// `type.*` references `font.family.<role>.latin`; the app picks the script).
extension TaroTypeScript on TaroTypeTokens {
  /// These roles with [script]'s family first and the other scripts' families
  /// as fallbacks, so mixed-script text still renders from bundled fonts.
  TaroTypeTokens forScript(TaroScript script, TaroFontTokens fonts) {
    final f = fonts.family;
    TextStyle swap(TextStyle style, _RoleFamilies role) {
      final ordered = [
        _pick(role, script),
        for (final s in TaroScript.values)
          if (s != script) _pick(role, s),
      ];
      final distinct = <String>[];
      for (final family in ordered) {
        if (!distinct.contains(family)) distinct.add(family);
      }
      return TextStyle(
        fontFamily: distinct.first,
        fontFamilyFallback: distinct.skip(1).toList(),
        package: kTaroFontPackage,
        fontSize: style.fontSize,
        fontWeight: style.fontWeight,
        height: style.height,
        letterSpacing: style.letterSpacing,
        leadingDistribution: style.leadingDistribution,
      );
    }

    return TaroTypeTokens(
      display: swap(display, (
        latin: f.display.latin,
        cyrillic: f.display.cyrillic,
        arabic: f.display.arabic,
        cjk: f.display.cjk,
        hangul: f.display.hangul,
      )),
      headline: swap(headline, (
        latin: f.headline.latin,
        cyrillic: f.headline.cyrillic,
        arabic: f.headline.arabic,
        cjk: f.headline.cjk,
        hangul: f.headline.hangul,
      )),
      cardName: swap(cardName, (
        latin: f.cardName.latin,
        cyrillic: f.cardName.cyrillic,
        arabic: f.cardName.arabic,
        cjk: f.cardName.cjk,
        hangul: f.cardName.hangul,
      )),
      bodyReading: swap(bodyReading, (
        latin: f.bodyReading.latin,
        cyrillic: f.bodyReading.cyrillic,
        arabic: f.bodyReading.arabic,
        cjk: f.bodyReading.cjk,
        hangul: f.bodyReading.hangul,
      )),
      title: swap(title, (
        latin: f.title.latin,
        cyrillic: f.title.cyrillic,
        arabic: f.title.arabic,
        cjk: f.title.cjk,
        hangul: f.title.hangul,
      )),
      titleSmall: swap(titleSmall, (
        latin: f.titleSmall.latin,
        cyrillic: f.titleSmall.cyrillic,
        arabic: f.titleSmall.arabic,
        cjk: f.titleSmall.cjk,
        hangul: f.titleSmall.hangul,
      )),
      body: swap(body, (
        latin: f.body.latin,
        cyrillic: f.body.cyrillic,
        arabic: f.body.arabic,
        cjk: f.body.cjk,
        hangul: f.body.hangul,
      )),
      label: swap(label, (
        latin: f.label.latin,
        cyrillic: f.label.cyrillic,
        arabic: f.label.arabic,
        cjk: f.label.cjk,
        hangul: f.label.hangul,
      )),
      caption: swap(caption, (
        latin: f.caption.latin,
        cyrillic: f.caption.cyrillic,
        arabic: f.caption.arabic,
        cjk: f.caption.cjk,
        hangul: f.caption.hangul,
      )),
      numeral: swap(numeral, (
        latin: f.numeral.latin,
        cyrillic: f.numeral.cyrillic,
        arabic: f.numeral.arabic,
        cjk: f.numeral.cjk,
        hangul: f.numeral.hangul,
      )),
    );
  }
}

/// The Flutter package that bundles the token fonts.
const String kTaroFontPackage = 'taro_ui';

String _pick(_RoleFamilies role, TaroScript script) => switch (script) {
  TaroScript.latin => role.latin,
  TaroScript.cyrillic => role.cyrillic,
  TaroScript.arabic => role.arabic,
  TaroScript.cjk => role.cjk,
  TaroScript.hangul => role.hangul,
};
