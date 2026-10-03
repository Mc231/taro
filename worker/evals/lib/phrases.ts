import { LEXICON_SOURCES, type LexiconSource } from '../../src/safety/lexiconSource';
import { matchRules, nonClaimRegex, phraseRegex } from '../../src/safety/phrases';
import { parseYaml, type YamlValue } from './miniYaml';
import { normalize } from './text';
import { LOCALES, type Locale } from './types';

export { phraseRegex } from '../../src/safety/phrases';

/**
 * Banned and certainty phrases (05 §4.3, §9.5; 03 §9.4 L3; RC39).
 *
 * The single source is `tools/store_copy/banned_phrases.yaml`, matched as
 * `tools/store_copy/check_store_copy.py` does: NFKC + lower case, tokens on
 * word boundaries, a trailing `*` makes a stem, and `match: substring`
 * locales (ja) match anywhere. Each YAML phrase is sorted into the concept
 * rows of the 05 §9.5 table: accuracy, guarantee and prediction are
 * **certainty** phrases (the 05 §4.3 bar is zero of them in answered
 * outputs); supernatural-ability claims break the 05 §4.1 output rules and
 * fail a case too; the rest (marketing, cure, magic, platform names) are
 * store-copy rules and only warn in a reading.
 *
 * `CERTAINTY_PATTERNS` adds per-locale certainty wording that store copy
 * never needs to list ("will definitely", "sin duda", …).
 */
export type Concept = 'accuracy' | 'guarantee' | 'prediction' | 'supernatural' | 'other';

export const CERTAINTY_CONCEPTS: ReadonlySet<Concept> = new Set([
  'accuracy',
  'guarantee',
  'prediction',
]);

type ConceptTable = Readonly<Partial<Record<Exclude<Concept, 'other'>, readonly string[]>>>;

/** 05 §9.5 table rows, as spelled in `banned_phrases.yaml`. */
export const CONCEPT_ROWS: Readonly<Record<Locale | 'common', ConceptTable>> = {
  common: { accuracy: ['100%'] },
  en: {
    accuracy: ['accurate', 'accuracy', 'precise', 'true reading'],
    guarantee: ['guaranteed', 'guarantee*'],
    prediction: ['predict your future', 'know your future', 'will happen'],
    supernatural: ['real psychic', 'psychic*', 'medium', 'clairvoyan*', 'spirits say'],
  },
  de: {
    accuracy: ['treffsicher*', 'genau'],
    guarantee: ['garantiert*', 'garantie*'],
    prediction: ['zukunft vorhersagen'],
    supernatural: ['hellseher*', 'medium'],
  },
  es: {
    accuracy: ['precis*', 'exact*'],
    guarantee: ['garantiza*'],
    prediction: ['predecir el futuro'],
    supernatural: ['vidente*', 'psíquic*'],
  },
  fr: {
    accuracy: ['précis*', 'exact*'],
    guarantee: ['garanti*'],
    prediction: ["prédire l'avenir"],
    supernatural: ['voyant*', 'voyance', 'médium*'],
  },
  it: {
    accuracy: ['accurat*', 'precis*'],
    guarantee: ['garantit*'],
    prediction: ['predire il futuro'],
    supernatural: ['veggente*', 'sensitiv*'],
  },
  pt: {
    accuracy: ['precis*', 'exat*'],
    guarantee: ['garanti*'],
    prediction: ['prever o futuro'],
    supernatural: ['vidente*', 'médium*'],
  },
  nl: {
    accuracy: ['nauwkeurig*', 'accura*'],
    guarantee: ['gegarandeerd', 'garantie*'],
    prediction: ['toekomst voorspellen'],
    supernatural: ['helderziend*', 'paranormaal*'],
  },
  ja: {
    accuracy: ['当たる', '的中'],
    guarantee: ['保証', '必ず'],
    prediction: ['未来予知', '予言'],
    supernatural: ['霊視', '霊能'],
  },
  ko: {
    accuracy: ['정확*', '적중*'],
    guarantee: ['보장*', '반드시'],
    prediction: ['미래를 예측*', '예언*'],
    supernatural: ['영매*', '신점*', '무당*'],
  },
  ar: {
    accuracy: ['دقيق*'],
    guarantee: ['مضمون*'],
    prediction: ['التنبؤ بالمستقبل'],
    supernatural: ['عراف*', 'وسيط روحاني'],
  },
  tr: {
    accuracy: ['isabetli*', 'kesin*'],
    guarantee: ['garanti*'],
    prediction: ['geleceği tahmin*', 'kehanet*'],
    supernatural: ['medyum*', 'durugörü*'],
  },
  uk: {
    accuracy: ['точн*'],
    guarantee: ['гарант*'],
    prediction: ['передбач* майбутн*'],
    supernatural: ['ясновид*', 'екстрасенс*'],
  },
};

type Sources = Readonly<Record<Locale, LexiconSource>>;

function perLocale<T>(pick: (source: LexiconSource) => T, sources: Sources): Record<Locale, T> {
  const out = {} as Record<Locale, T>;
  for (const locale of LOCALES) {
    out[locale] = pick(sources[locale]);
  }
  return out;
}

/**
 * Certainty wording beyond the store-copy list (same phrase syntax), from
 * `l3.certainty` of `worker/safety/lexicons/<locale>.json`: the production L3
 * lexicon compiles the same lists.
 */
export const CERTAINTY_PATTERNS: Readonly<Record<Locale, readonly string[]>> = perLocale(
  (source) => source.l3.certainty,
  LEXICON_SOURCES,
);

/**
 * Reading-text spans that a stem or certainty pattern catches but that make
 * no claim, removed before matching like `allowed_contexts` (graders and the
 * production L3 lexicon, `l3.nonClaimSpans` of the lexicon sources; store copy
 * keeps the full list). Each entry is a normalised regex source
 * matched on word boundaries: verbs and adverbs sharing the `precis*` stem
 * ("precisar" = to need, "você precisa saber" = you need to know,
 * "precisamente" = just, "domanda precisa" = a specific
 * question), "met zekerheid te maken" (to do with certainty), German
 * "genau dieser/das/so …" (exactly this), and negated certainty words within
 * one clause: French "pas … garanti", Portuguese "não … com certeza",
 * Turkish "mutlaka/kesin … değil" (not necessarily / not a certain outcome),
 * English "not/rather than … guaranteed" and "what will happen" (an indirect
 * question, not a prediction), and French "précis" after a noun that is not
 * the reading ("un plan d'action précis" = a specific plan; "une lecture
 * précise" still counts).
 */
export const NON_CLAIM_SPANS: Readonly<Record<Locale, readonly string[]>> = perLocale(
  (source) => source.l3.nonClaimSpans,
  LEXICON_SOURCES,
);

export interface PhraseRule {
  readonly phrase: string;
  readonly concept: Concept;
  /** `banned_phrases.yaml` or the grader's own certainty list. */
  readonly source: 'banned_phrases' | 'certainty_patterns';
  readonly pattern: RegExp;
}

export interface LocalePhrases {
  /** `match: substring` in `banned_phrases.yaml` (ja). */
  readonly substring: boolean;
  readonly rules: readonly PhraseRule[];
  readonly allowedContexts: readonly string[];
  /** `NON_CLAIM_SPANS` of the locale, compiled. */
  readonly nonClaims: readonly RegExp[];
}

export type PhraseBook = Readonly<Record<Locale, LocalePhrases>>;

export interface PhraseHit {
  readonly phrase: string;
  readonly concept: Concept;
  readonly source: PhraseRule['source'];
  readonly match: string;
}

function asRecord(value: YamlValue | undefined): Record<string, YamlValue> {
  return typeof value === 'object' && !Array.isArray(value) ? value : {};
}

function asStrings(value: YamlValue | undefined): string[] {
  return Array.isArray(value)
    ? value.filter((item): item is string => typeof item === 'string')
    : [];
}

function conceptOf(phrase: string, locale: Locale): Concept {
  for (const table of [CONCEPT_ROWS.common, CONCEPT_ROWS[locale]]) {
    for (const [concept, phrases] of Object.entries(table)) {
      if (phrases.includes(phrase)) {
        return concept as Concept;
      }
    }
  }
  return 'other';
}

/**
 * Compiles `banned_phrases.yaml` (its `global` lists) plus the certainty and
 * non-claim lists of the lexicon sources (default: the committed ones).
 */
export function buildPhraseBook(
  bannedYaml: string,
  sources: Sources = LEXICON_SOURCES,
): PhraseBook {
  const root = asRecord(parseYaml(bannedYaml));
  const common = asRecord(root['common']);
  const locales = asRecord(root['locales']);
  const book = {} as Record<Locale, LocalePhrases>;
  for (const locale of LOCALES) {
    const block = asRecord(locales[locale]);
    const substring = block['match'] === 'substring';
    const seen = new Set<string>();
    const rules: PhraseRule[] = [];
    const add = (phrase: string, source: PhraseRule['source']): void => {
      if (seen.has(phrase)) {
        return;
      }
      seen.add(phrase);
      rules.push({
        phrase,
        concept: source === 'certainty_patterns' ? 'guarantee' : conceptOf(phrase, locale),
        source,
        pattern: phraseRegex(phrase, substring),
      });
    };
    for (const phrase of [...asStrings(common['global']), ...asStrings(block['global'])]) {
      add(phrase, 'banned_phrases');
    }
    for (const phrase of sources[locale].l3.certainty) {
      add(phrase, 'certainty_patterns');
    }
    book[locale] = {
      substring,
      rules,
      allowedContexts: asStrings(block['allowed_contexts']).map(normalize),
      nonClaims: sources[locale].l3.nonClaimSpans.map((source) => nonClaimRegex(source, substring)),
    };
  }
  return book;
}

/**
 * Every rule that occurs in `text` (normalised, allowed contexts and
 * non-claim spans removed, as the production L3 lexicon does). `nonClaims:
 * 'keep'` matches the bare word list, e.g. to see which exemptions applied.
 */
export function findPhrases(
  text: string,
  phrases: LocalePhrases,
  nonClaims: 'remove' | 'keep' = 'remove',
): PhraseHit[] {
  return matchRules(text, phrases, nonClaims).map(({ rule, match }) => ({
    phrase: rule.phrase,
    concept: rule.concept,
    source: rule.source,
    match,
  }));
}
