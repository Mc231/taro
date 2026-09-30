/** Shared wire enums (GLOSSARY §4.1, §5.1). */
export const PLATFORMS = ['ios', 'android'] as const;
export type Platform = (typeof PLATFORMS)[number];

export type Trust = 'high' | 'low';

/** The 12 app locales (GLOSSARY §15; `pt` = pt-BR). */
export const LOCALES = [
  'en',
  'ar',
  'de',
  'es',
  'fr',
  'it',
  'ja',
  'ko',
  'nl',
  'pt',
  'tr',
  'uk',
] as const;
export type Locale = (typeof LOCALES)[number];

export function isPlatform(value: unknown): value is Platform {
  return PLATFORMS.includes(value as Platform);
}

export function isLocale(value: unknown): value is Locale {
  return LOCALES.includes(value as Locale);
}

/**
 * Refusal categories (03 §9.4, RC27; GLOSSARY §5.2), canonical for every spec.
 * The model's `classification` adds `none` (03 §9.2).
 */
export const REFUSAL_CATEGORIES = [
  'health',
  'pregnancy',
  'death',
  'legal',
  'financial',
  'gambling',
  'self_harm',
  'harm_to_others',
  'sexual_minors',
  'hate_or_harassment',
] as const;
export type RefusalCategory = (typeof REFUSAL_CATEGORIES)[number];

export const CLASSIFICATIONS = ['none', ...REFUSAL_CATEGORIES] as const;
export type Classification = (typeof CLASSIFICATIONS)[number];

export function isRefusalCategory(value: unknown): value is RefusalCategory {
  return REFUSAL_CATEGORIES.includes(value as RefusalCategory);
}
