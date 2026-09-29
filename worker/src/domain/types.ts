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
