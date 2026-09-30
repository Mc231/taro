/// The name of each app locale in its own language (CLDR endonyms, 01
/// §7.10 Language). They are never translated: a speaker finds their
/// language by its own name whatever the current UI language, so they are
/// data, not ARB strings.
const Map<String, String> kLanguageEndonyms = {
  'en': 'English',
  'es': 'Español',
  'pt': 'Português',
  'fr': 'Français',
  'de': 'Deutsch',
  'it': 'Italiano',
  'nl': 'Nederlands',
  'tr': 'Türkçe',
  'uk': 'Українська',
  'ar': 'العربية',
  'ja': '日本語',
  'ko': '한국어',
};

/// The endonym of [locale] (a language tag; the language subtag decides),
/// or the tag itself when it is not an app locale.
String languageEndonym(String locale) =>
    kLanguageEndonyms[locale.split(RegExp('[-_]')).first] ?? locale;
