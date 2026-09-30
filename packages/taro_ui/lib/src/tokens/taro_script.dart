import 'package:flutter/widgets.dart';

/// The text scripts the bundled fonts cover (01 §13, 01 §14.2
/// `font.family.{role}.{script}`).
enum TaroScript {
  /// Latin (en, de, es, fr, it, nl, pt, tr).
  latin,

  /// Cyrillic (uk).
  cyrillic,

  /// Arabic (ar).
  arabic,

  /// Japanese (ja).
  cjk,

  /// Korean (ko).
  hangul;

  /// The primary script of [locale]'s language.
  static TaroScript forLocale(Locale locale) => switch (locale.languageCode) {
    'ar' || 'fa' || 'ur' => TaroScript.arabic,
    'ja' || 'zh' => TaroScript.cjk,
    'ko' => TaroScript.hangul,
    'uk' || 'ru' || 'bg' || 'sr' => TaroScript.cyrillic,
    _ => TaroScript.latin,
  };
}
