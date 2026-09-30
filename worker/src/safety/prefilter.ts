import type { Locale, RefusalCategory } from '../domain/types';
import { isL1BlockCategory, L1_BLOCK_CATEGORIES, type L1BlockCategory } from './lexiconSource';
import { safetyLexicons, type L1Rule, type SafetyLexicon, type SafetyLexicons } from './lexicons';
import { foldText } from './text';

/**
 * The L1 prefilter (03 §9.4, BE12): the question is folded (`foldText`) and
 * checked against the lexicon of the reading locale **and** the English one
 * (users mix languages). A high-precision `self_harm`, `harm_to_others` or
 * `sexual_minors` rule declines the reading before any model call; every
 * other match only becomes a `<prefilter_hint>` for the model (L2 decides).
 * A question with Japanese, Korean, Arabic or Cyrillic text is also checked
 * against that locale's lexicon.
 */
export type PrefilterResult =
  | {
      readonly kind: 'block';
      readonly category: L1BlockCategory;
      /** `<locale>:<rule id>` of the deciding rule (logs and metrics; never the question). */
      readonly rule: string;
    }
  | { readonly kind: 'pass'; readonly hints: readonly RefusalCategory[] };

function fires(rule: L1Rule, folded: string): boolean {
  return (
    rule.patterns.every((pattern) => pattern.test(folded)) &&
    !rule.unless.some((pattern) => pattern.test(folded))
  );
}

/** Non-Latin scripts whose presence adds that locale's lexicon (a mixed-language question). */
const SCRIPT_LOCALES: readonly (readonly [RegExp, Locale])[] = [
  [/[\p{Script=Hiragana}\p{Script=Katakana}\p{Script=Han}]/u, 'ja'],
  [/\p{Script=Hangul}/u, 'ko'],
  [/\p{Script=Arabic}/u, 'ar'],
  [/\p{Script=Cyrillic}/u, 'uk'],
];

/**
 * The lexicons a question is checked against: its locale, English (03
 * §9.4), and the locale of any other script it contains.
 */
export function lexiconLocales(folded: string, locale: Locale): Locale[] {
  const locales = new Set<Locale>([locale, 'en']);
  for (const [script, scriptLocale] of SCRIPT_LOCALES) {
    if (script.test(folded)) {
      locales.add(scriptLocale);
    }
  }
  return [...locales];
}

function lexiconsFor(folded: string, locale: Locale, lexicons: SafetyLexicons): SafetyLexicon[] {
  return lexiconLocales(folded, locale).map((l) => lexicons[l]);
}

export function prefilter(
  question: string | null | undefined,
  locale: Locale,
  lexicons: SafetyLexicons = safetyLexicons(),
): PrefilterResult {
  const folded = foldText(question ?? '');
  if (folded === '') {
    return { kind: 'pass', hints: [] };
  }
  const blocks = new Map<L1BlockCategory, string>();
  const hints = new Set<RefusalCategory>();
  for (const lexicon of lexiconsFor(folded, locale, lexicons)) {
    for (const rule of lexicon.l1) {
      if (!fires(rule, folded)) {
        continue;
      }
      if (rule.severity === 'high' && isL1BlockCategory(rule.category)) {
        if (!blocks.has(rule.category)) {
          blocks.set(rule.category, `${lexicon.locale}:${rule.id}`);
        }
      } else {
        hints.add(rule.category);
      }
    }
  }
  // Fixed priority when several crisis rules fire: the user's own safety first.
  for (const category of L1_BLOCK_CATEGORIES) {
    const rule = blocks.get(category);
    if (rule !== undefined) {
      return { kind: 'block', category, rule };
    }
  }
  return { kind: 'pass', hints: [...hints] };
}
