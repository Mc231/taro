import 'package:flutter/painting.dart';
import 'package:taro_ui/src/tokens/generated/taro_tokens.g.dart';
import 'package:taro_ui/src/tokens/taro_typography.dart';

final RegExp _digits = RegExp(r'^\d+$');

const String _package = 'packages/$kTaroFontPackage/';

/// The `type.numeral` style for [numeral]. IM Fell English SC only has
/// old-style figures, and its zero is a small circle that reads as "○";
/// a digit numeral (The Fool's "0", RWS numbering) takes the lining
/// figures of the `type.cardName` serif instead. Roman numerals keep the
/// numeral face (BUG-20).
TextStyle numeralStyle(TaroTypeTokens type, String numeral) =>
    _digits.hasMatch(numeral)
    ? type.numeral.copyWith(
        // copyWith re-applies the font package, so pass the bare family.
        fontFamily: type.cardName.fontFamily?.replaceFirst(_package, ''),
        fontFamilyFallback: type.cardName.fontFamilyFallback,
      )
    : type.numeral;
