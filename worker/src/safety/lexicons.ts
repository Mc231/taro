import generated from '../generated/safety_lexicons.json';
import { LOCALES, type Locale, type RefusalCategory } from '../domain/types';
import { matchRules, nonClaimRegex, type MatchBook } from './phrases';

/**
 * The compiled safety lexicons (03 §9.4), loaded from
 * `src/generated/safety_lexicons.json`, which `npm run safety:lexicons`
 * builds from `worker/safety/lexicons/<locale>.json` and
 * `tools/store_copy/banned_phrases.yaml`. Regexes are built once per isolate.
 */

/** One L1 rule as generated: patterns are final regex sources (boundaries applied). */
export interface GeneratedL1Rule {
  readonly id: string;
  readonly category: RefusalCategory;
  readonly severity: 'high' | 'hint';
  readonly patterns: readonly string[];
  readonly unless: readonly string[];
}

/** Where an L3 phrase comes from. */
export type L3Source = 'banned_phrases' | 'certainty_patterns' | 'forbidden_claims';

export interface GeneratedL3Rule {
  readonly phrase: string;
  /** The 05 §9.5 concept row of a banned phrase, `guarantee` for certainty wording, `claim` otherwise. */
  readonly kind: string;
  readonly source: L3Source;
  /** Regex source over `normalize` (the banned-phrases syntax, compiled). */
  readonly pattern: string;
}

export interface GeneratedLexicon {
  readonly reviewed: boolean;
  readonly l1: readonly GeneratedL1Rule[];
  readonly l3: {
    readonly rules: readonly GeneratedL3Rule[];
    readonly allowedContexts: readonly string[];
    readonly nonClaimSpans: readonly string[];
  };
}

export interface GeneratedLexicons {
  readonly version: 1;
  readonly locales: Readonly<Record<Locale, GeneratedLexicon>>;
}

export interface L1Rule {
  readonly id: string;
  readonly category: RefusalCategory;
  readonly severity: 'high' | 'hint';
  readonly patterns: readonly RegExp[];
  readonly unless: readonly RegExp[];
}

export interface L3Rule {
  readonly phrase: string;
  readonly kind: string;
  readonly source: L3Source;
  readonly pattern: RegExp;
}

export interface SafetyLexicon {
  readonly locale: Locale;
  readonly reviewed: boolean;
  readonly l1: readonly L1Rule[];
  readonly l3: MatchBook<L3Rule>;
}

export type SafetyLexicons = Readonly<Record<Locale, SafetyLexicon>>;

/** Builds the regexes of a generated lexicon file. */
export function loadSafetyLexicons(data: GeneratedLexicons): SafetyLexicons {
  const out = {} as Record<Locale, SafetyLexicon>;
  for (const locale of LOCALES) {
    const lexicon = data.locales[locale];
    out[locale] = {
      locale,
      reviewed: lexicon.reviewed,
      l1: lexicon.l1.map((rule) => ({
        id: rule.id,
        category: rule.category,
        severity: rule.severity,
        patterns: rule.patterns.map((source) => new RegExp(source, 'u')),
        unless: rule.unless.map((source) => new RegExp(source, 'u')),
      })),
      l3: {
        rules: lexicon.l3.rules.map((rule) => ({
          phrase: rule.phrase,
          kind: rule.kind,
          source: rule.source,
          pattern: new RegExp(rule.pattern, 'u'),
        })),
        allowedContexts: lexicon.l3.allowedContexts,
        nonClaims: lexicon.l3.nonClaimSpans.map(nonClaimRegex),
      },
    };
  }
  return out;
}

let cached: SafetyLexicons | undefined;

/** The production lexicons (compiled on first use). */
export function safetyLexicons(): SafetyLexicons {
  cached ??= loadSafetyLexicons(generated as GeneratedLexicons);
  return cached;
}

export interface ForbiddenClaim {
  readonly phrase: string;
  readonly kind: string;
  readonly source: L3Source;
  readonly match: string;
}

/**
 * L3 forbidden claims in `text` (03 §9.4): the banned phrases of RC39, the
 * certainty wording and the L3-only claims, after allowed contexts and
 * non-claim spans are removed (the same spans the offline graders use).
 */
export function findForbiddenClaims(text: string, lexicon: SafetyLexicon): ForbiddenClaim[] {
  return matchRules(text, lexicon.l3).map(({ rule, match }) => ({
    phrase: rule.phrase,
    kind: rule.kind,
    source: rule.source,
    match,
  }));
}
