import type { Locale } from '../domain/types';
import { letterTokens } from './text';

/**
 * Output-language heuristic (03 §9.4 L3): a script check for ar/ja/ko/uk and
 * a stop-word ratio for the Latin-script locales. English card names that the
 * model keeps in a non-Latin reading are tolerated by the ratio thresholds.
 */
export type LatinLocale = Exclude<Locale, 'ja' | 'ko' | 'ar' | 'uk'>;

export const STOP_WORDS: Readonly<Record<LatinLocale, ReadonlySet<string>>> = {
  en: new Set(
    'the and of to is you your that it this with for are what how may can be as on not or an if about'.split(
      ' ',
    ),
  ),
  de: new Set(
    'der die das und ist nicht du dich dir dein deine ein eine mit auf für zu sich auch wie was es den dem im kann wenn oder'.split(
      ' ',
    ),
  ),
  es: new Set(
    'el la los las de que y en un una es por con para tu te lo se del al su más como puede esta este'.split(
      ' ',
    ),
  ),
  fr: new Set(
    'le la les de des du et est un une que qui tu te ton ta tes vous votre dans pour pas sur avec ce cette peut'.split(
      ' ',
    ),
  ),
  it: new Set(
    'il lo la gli le di che e è un una per con non sono tu ti tuo tua del della nel questo questa può come'.split(
      ' ',
    ),
  ),
  pt: new Set(
    'o a os as de que e um uma é do da dos das em no na para com não você seu sua pode isso este esta'.split(
      ' ',
    ),
  ),
  nl: new Set(
    'de het een en van is dat je jij jouw niet op te met voor zijn wat hoe kan dit er maar ook naar bij'.split(
      ' ',
    ),
  ),
  tr: new Set(
    'bir ve bu için ile da de ne sen senin sana olarak daha çok gibi ama mi mı olan kendi şu her nasıl değil'.split(
      ' ',
    ),
  ),
};

const LATIN_LOCALES = Object.keys(STOP_WORDS) as LatinLocale[];

/** Minimum share of letters in the locale's script. */
export const SCRIPT_MIN_RATIO = 0.6;
/** Minimum stop-word share for a Latin-script locale. */
export const STOP_WORD_MIN_RATIO = 0.12;
/** Below this many letters (script) or tokens (Latin) the check only warns. */
export const MIN_SAMPLE = 40;
const MIN_TOKENS = 20;

const SCRIPT: Readonly<Record<'ja' | 'ko' | 'ar' | 'uk', RegExp>> = {
  ja: /[\p{Script=Hiragana}\p{Script=Katakana}\p{Script=Han}ー]/u,
  ko: /\p{Script=Hangul}/u,
  ar: /\p{Script=Arabic}/u,
  uk: /\p{Script=Cyrillic}/u,
};

export interface LanguageVerdict {
  readonly ok: boolean;
  /** Too little text for a confident verdict. */
  readonly weak: boolean;
  readonly detail: string;
}

function pct(value: number): string {
  return `${(value * 100).toFixed(0)}%`;
}

export function checkLanguage(text: string, locale: Locale): LanguageVerdict {
  const letters = Array.from(text.normalize('NFC')).filter((ch) => /\p{L}/u.test(ch));
  if (locale === 'ja' || locale === 'ko' || locale === 'ar' || locale === 'uk') {
    return checkScript(letters, locale);
  }
  return checkLatin(text, letters, locale);
}

function checkScript(letters: string[], locale: 'ja' | 'ko' | 'ar' | 'uk'): LanguageVerdict {
  const script = SCRIPT[locale];
  const inScript = letters.filter((ch) => script.test(ch)).length;
  const ratio = letters.length === 0 ? 0 : inScript / letters.length;
  const weak = letters.length < MIN_SAMPLE;
  if (ratio < SCRIPT_MIN_RATIO) {
    return { ok: false, weak, detail: `${pct(ratio)} of letters in the ${locale} script` };
  }
  if (
    locale === 'ja' &&
    !letters.some((ch) => /[\p{Script=Hiragana}\p{Script=Katakana}]/u.test(ch))
  ) {
    return { ok: false, weak, detail: 'no kana: looks like Chinese, not Japanese' };
  }
  if (locale === 'uk') {
    const russian = letters.filter((ch) => /[ыэъёЫЭЪЁ]/u.test(ch)).length;
    const ukrainian = letters.filter((ch) => /[іїєґІЇЄҐ]/u.test(ch)).length;
    if (russian > 0 || (!weak && ukrainian === 0)) {
      return {
        ok: false,
        weak,
        detail: `Cyrillic but not Ukrainian (${String(russian)} Russian-only letters, ${String(ukrainian)} Ukrainian-only letters)`,
      };
    }
  }
  return { ok: true, weak, detail: `${pct(ratio)} of letters in the ${locale} script` };
}

function checkLatin(text: string, letters: string[], locale: LatinLocale): LanguageVerdict {
  const latin = letters.filter((ch) => /\p{Script=Latin}/u.test(ch)).length;
  const latinRatio = letters.length === 0 ? 0 : latin / letters.length;
  const tokens = letterTokens(text);
  const weak = tokens.length < MIN_TOKENS;
  if (latinRatio < 0.8) {
    return { ok: false, weak, detail: `only ${pct(latinRatio)} Latin letters` };
  }
  const scores = LATIN_LOCALES.map((candidate) => ({
    candidate,
    ratio:
      tokens.length === 0
        ? 0
        : tokens.filter((token) => STOP_WORDS[candidate].has(token)).length / tokens.length,
  })).sort((a, b) => b.ratio - a.ratio);
  const own = scores.find((score) => score.candidate === locale)?.ratio ?? 0;
  const best = scores[0] ?? { candidate: locale, ratio: 0 };
  if (own < best.ratio) {
    return {
      ok: false,
      weak,
      detail: `reads as ${best.candidate} (${pct(best.ratio)} stop words) rather than ${locale} (${pct(own)})`,
    };
  }
  if (own < STOP_WORD_MIN_RATIO) {
    return { ok: false, weak, detail: `${pct(own)} ${locale} stop words` };
  }
  return { ok: true, weak, detail: `${pct(own)} ${locale} stop words` };
}
