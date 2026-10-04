import 'package:flutter/painting.dart';

final RegExp _letter = RegExp(r'\p{L}', unicode: true);

/// Whether [rune] is in a right-to-left script block (Hebrew, Arabic,
/// Syriac, Thaana, NKo, Samaritan, Mandaic, their presentation forms and
/// the supplementary RTL planes).
bool _isRtl(int rune) =>
    (rune >= 0x0590 && rune <= 0x08FF) ||
    (rune >= 0xFB1D && rune <= 0xFDFF) ||
    (rune >= 0xFE70 && rune <= 0xFEFF) ||
    (rune >= 0x10800 && rune <= 0x10FFF) ||
    (rune >= 0x1E800 && rune <= 0x1EFFF);

/// The direction of the first strongly directional character of [text]
/// (Unicode "first strong", UAX #9 P2), or `null` when it has none (digits,
/// punctuation, emoji). User text (a question, a note) follows its own
/// direction, not the UI locale's (BUG-11).
TextDirection? firstStrongDirection(String text) {
  for (final rune in text.runes) {
    if (_isRtl(rune)) return TextDirection.rtl;
    if (_letter.hasMatch(String.fromCharCode(rune))) return TextDirection.ltr;
  }
  return null;
}

/// [text] in a first-strong isolate (U+2068 … U+2069): user text embedded
/// in localised copy or shown in an RTL UI keeps its own order, so an
/// English question ends with "?" on the right in Arabic.
String firstStrongIsolate(String text) => '\u2068$text\u2069';
