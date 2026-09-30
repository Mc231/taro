import { z } from 'zod';
import ar from '../../safety/lexicons/ar.json';
import de from '../../safety/lexicons/de.json';
import en from '../../safety/lexicons/en.json';
import es from '../../safety/lexicons/es.json';
import fr from '../../safety/lexicons/fr.json';
import it from '../../safety/lexicons/it.json';
import ja from '../../safety/lexicons/ja.json';
import ko from '../../safety/lexicons/ko.json';
import nl from '../../safety/lexicons/nl.json';
import pt from '../../safety/lexicons/pt.json';
import tr from '../../safety/lexicons/tr.json';
import uk from '../../safety/lexicons/uk.json';
import { LOCALES, REFUSAL_CATEGORIES, type Locale, type RefusalCategory } from '../domain/types';

/**
 * The authored safety lexicons, `worker/safety/lexicons/<locale>.json`
 * (03 §9.4, BE12). They are **sources**: `npm run safety:lexicons` compiles
 * them with `tools/store_copy/banned_phrases.yaml` (RC39) into
 * `src/generated/safety_lexicons.json`, which is what the Worker loads. The
 * offline graders read the L3 certainty and non-claim lists from here too,
 * so the eval bar and production L3 never drift apart.
 */

/** The only categories whose high-precision L1 patterns short-circuit before the model. */
export const L1_BLOCK_CATEGORIES = ['self_harm', 'harm_to_others', 'sexual_minors'] as const;
export type L1BlockCategory = (typeof L1_BLOCK_CATEGORIES)[number];

export function isL1BlockCategory(value: RefusalCategory): value is L1BlockCategory {
  return (L1_BLOCK_CATEGORIES as readonly string[]).includes(value);
}

const l1RuleSchema = z
  .strictObject({
    /** Stable ID, unique per locale (`sh.*` self_harm, `ho.*` harm_to_others, `sm.*`, hints `*.hint`). */
    id: z.string().regex(/^[a-z0-9_.]+$/u),
    category: z.enum(REFUSAL_CATEGORIES),
    /** `high` short-circuits (L1 categories only); `hint` becomes a `<prefilter_hint>`. */
    severity: z.enum(['high', 'hint']),
    /** Regexes over `foldText`; every one must match. */
    patterns: z.array(z.string().min(1)).min(1),
    /** Regexes over `foldText`; any match cancels the rule (e.g. a parent asking about their child). */
    unless: z.array(z.string().min(1)).optional(),
  })
  .refine((rule) => rule.severity === 'hint' || isL1BlockCategory(rule.category), {
    message: 'only self_harm, harm_to_others and sexual_minors may be high severity',
  });

export const lexiconSourceSchema = z.strictObject({
  $comment: z.string().optional(),
  locale: z.enum(LOCALES),
  /** `false` until a native speaker has reviewed the file (Phase 18.4). */
  reviewed: z.boolean(),
  /** Wrap patterns in letter/number boundaries (off for ar, ja, ko: particles attach to words). */
  wordBoundaries: z.boolean(),
  l1: z.array(l1RuleSchema),
  l3: z.strictObject({
    /** Certainty wording beyond the store-copy list (banned-phrases syntax). */
    certainty: z.array(z.string().min(1)),
    /** L3-only claims: medication names, investment advice, "you will die" (banned-phrases syntax). */
    forbiddenClaims: z.array(z.string().min(1)),
    /** Spans that use a listed word without a claim (regex sources over `normalize`). */
    nonClaimSpans: z.array(z.string().min(1)),
  }),
});

export type LexiconSource = z.infer<typeof lexiconSourceSchema>;
export type L1RuleSource = LexiconSource['l1'][number];

const RAW: Readonly<Record<Locale, unknown>> = { en, ar, de, es, fr, it, ja, ko, nl, pt, tr, uk };

/** Parses one source; the locale must match its file. */
export function parseLexiconSource(locale: Locale, raw: unknown): LexiconSource {
  const source = lexiconSourceSchema.parse(raw);
  if (source.locale !== locale) {
    throw new Error(`lexicon ${locale}: file says locale ${source.locale}`);
  }
  return source;
}

export function parseLexiconSources(
  raw: Readonly<Record<Locale, unknown>>,
): Readonly<Record<Locale, LexiconSource>> {
  const out = {} as Record<Locale, LexiconSource>;
  for (const locale of LOCALES) {
    out[locale] = parseLexiconSource(locale, raw[locale]);
  }
  return out;
}

export const LEXICON_SOURCES: Readonly<Record<Locale, LexiconSource>> = parseLexiconSources(RAW);
