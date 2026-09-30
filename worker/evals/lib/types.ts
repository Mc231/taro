/**
 * Shared types of the eval runner (Phase 8 Sprint 8.6, 03 §15.4, 05 §4.3).
 *
 * Case data (`evals/cases/**`, `evals/safety/**`) is outside the coverage
 * gate; everything in `evals/lib/` is covered code (RC61).
 */

/** The 12 app locales (01, GLOSSARY). */
export const LOCALES = [
  'en',
  'de',
  'es',
  'fr',
  'it',
  'pt',
  'nl',
  'ja',
  'ko',
  'ar',
  'tr',
  'uk',
] as const;
export type Locale = (typeof LOCALES)[number];

/** Canonical refusal categories (03 §9.4). */
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

/** The model's `classification` field (03 §9.2): `none` or a refusal category. */
export type Classification = 'none' | RefusalCategory;

/**
 * What the user sees (03 §9.4 table, 01 §7.5): a reading, a declined
 * reading with crisis resources, a declined reading that may be rephrased, or
 * any other decline (`sexual_minors`, or a provider refusal without category).
 */
export const OUTCOMES = ['answered', 'refused', 'crisis', 'rephrase'] as const;
export type Outcome = (typeof OUTCOMES)[number];

/** Categories whose decline carries crisis resources (03 §9.4). */
export const CRISIS_CATEGORIES: ReadonlySet<Classification> = new Set([
  'self_harm',
  'harm_to_others',
]);

/** `canRephrase: true` categories (03 §9.4). */
export const REPHRASE_CATEGORIES: ReadonlySet<Classification> = new Set([
  'health',
  'pregnancy',
  'death',
  'legal',
  'financial',
  'gambling',
  'hate_or_harassment',
]);

export function isLocale(value: unknown): value is Locale {
  return typeof value === 'string' && (LOCALES as readonly string[]).includes(value);
}

export function isClassification(value: unknown): value is Classification {
  return (
    value === 'none' ||
    (typeof value === 'string' && (REFUSAL_CATEGORIES as readonly string[]).includes(value))
  );
}

export function isOutcome(value: unknown): value is Outcome {
  return typeof value === 'string' && (OUTCOMES as readonly string[]).includes(value);
}

/** The user-visible outcome of a classification (03 §9.4). */
export function outcomeOf(classification: Classification): Outcome {
  if (classification === 'none') {
    return 'answered';
  }
  if (CRISIS_CATEGORIES.has(classification)) {
    return 'crisis';
  }
  return REPHRASE_CATEGORIES.has(classification) ? 'rephrase' : 'refused';
}

export interface DrawnCard {
  readonly positionId: string;
  readonly cardId: string;
  readonly reversed: boolean;
}

/** One eval case (a line of `evals/cases/*.jsonl` or `evals/safety/prompts.jsonl`). */
export interface EvalCase {
  readonly id: string;
  readonly locale: Locale;
  /** Expected model classification, when the case names one. */
  readonly expectedCategory: Classification | null;
  readonly expectedOutcome: Outcome;
  /** Free label such as `benign`, `refusal`, `jailbreak`, `injection`, `quality`. */
  readonly kind: string | null;
  readonly spreadId: string | null;
  readonly cards: readonly DrawnCard[] | null;
  readonly question: string | null;
}

/** A provider's own refusal signal, as the adapter maps it (03 §9.3). */
export interface ProviderRefusal {
  readonly category: string | null;
}

/** One pre-recorded model answer (offline mode input). */
export interface RecordedOutput {
  readonly id: string;
  /** Routing tier (`paid`, `free`, `freeFallback`) or any run label. */
  readonly tier: string;
  readonly provider: string | null;
  readonly model: string | null;
  /** The raw text the model returned (expected: the JSON of 03 §9.2). */
  readonly output: string;
  readonly refusal: ProviderRefusal | null;
}

export const GRADER_NAMES = [
  'schema',
  'classification',
  'crisis',
  'language',
  'certainty',
  'banned_phrases',
  'card_echo',
  'length',
  'contacts',
  'leakage',
] as const;
export type GraderName = (typeof GRADER_NAMES)[number];

/** `skip` = not applicable to this case; `warn` = advisory, never fails a case. */
export type GradeStatus = 'pass' | 'fail' | 'warn' | 'skip';

export interface GradeResult {
  readonly grader: GraderName;
  readonly status: GradeStatus;
  readonly messages: readonly string[];
}

/** The reading object of 03 §9.2, loosely typed (only what the graders read). */
export interface ParsedReading {
  readonly classification: unknown;
  readonly title: unknown;
  readonly overview: unknown;
  readonly cards: unknown;
  readonly synthesis: unknown;
  readonly reflectionPrompts: unknown;
}

/** What the model's answer amounts to, after parsing. */
export interface ActualResult {
  /** `null` when neither the JSON nor the provider named a category. */
  readonly classification: Classification | null;
  /** `invalid` = unparseable answer without a provider refusal. */
  readonly outcome: Outcome | 'invalid';
  readonly providerRefusal: boolean;
  /** The parsed JSON object, when there is one (lenient parse). */
  readonly reading: Readonly<Record<string, unknown>> | null;
  /** `JSON.parse` succeeded on the raw text as is (production parity). */
  readonly strictJson: boolean;
}

export interface CaseGrade {
  readonly id: string;
  readonly tier: string;
  readonly locale: Locale;
  readonly kind: string | null;
  readonly expectedCategory: Classification | null;
  readonly expectedOutcome: Outcome;
  readonly actualCategory: Classification | null;
  readonly actualOutcome: Outcome | 'invalid';
  readonly providerRefusal: boolean;
  readonly results: readonly GradeResult[];
  /** No grader failed. */
  readonly pass: boolean;
}
