import crisisJson from '../generated/crisis_resources.json';
import type { AiModerationResult } from '../ports/AiProvider';
import type { Locale, RefusalCategory } from './types';

/**
 * Safety policy (03 §9.4, RC27; GLOSSARY §5.2): what a declined reading
 * carries per refusal category, the fixed moderation → category table
 * (RC97), crisis-resource selection (03 §9.5, RC25, RC81) and the
 * declined-per-day limit (RC74). Pure: no I/O, no clock.
 */

export interface CategoryPolicy {
  /** Client ARB key of the declined message (GLOSSARY §5.2). */
  readonly messageKey: string;
  /** The client may suggest a reflective rephrasing (01 "rephrase"). */
  readonly canRephrase: boolean;
  /** The response carries crisis resources (01 "crisis"). */
  readonly crisisResources: boolean;
  /** Logged as a metric only: no question-derived detail anywhere (03 §9.4). */
  readonly metricOnly: boolean;
}

const rephrase = (messageKey: string): CategoryPolicy => ({
  messageKey,
  canRephrase: true,
  crisisResources: false,
  metricOnly: false,
});

/** The 03 §9.4 table. Every category is declined and never charged. */
export const SAFETY_POLICY: Readonly<Record<RefusalCategory, CategoryPolicy>> = {
  self_harm: {
    messageKey: 'safetyDeclinedSelfHarm',
    canRephrase: false,
    crisisResources: true,
    metricOnly: false,
  },
  harm_to_others: {
    messageKey: 'safetyDeclinedHarmToOthers',
    canRephrase: false,
    crisisResources: true,
    metricOnly: false,
  },
  health: rephrase('safetyDeclinedHealth'),
  pregnancy: rephrase('safetyDeclinedPregnancy'),
  death: rephrase('safetyDeclinedDeath'),
  legal: rephrase('safetyDeclinedLegal'),
  financial: rephrase('safetyDeclinedFinancial'),
  gambling: rephrase('safetyDeclinedGambling'),
  sexual_minors: {
    messageKey: 'safetyDeclinedSexualMinors',
    canRephrase: false,
    crisisResources: false,
    metricOnly: true,
  },
  hate_or_harassment: rephrase('safetyDeclinedHateOrHarassment'),
};

/** `readings.safety_layer` (GLOSSARY §5.2). Provider moderation of the question declines as L2. */
export type SafetyLayer = 'L1' | 'L2' | 'L3' | 'model_refusal';

// --- crisis resources (03 §9.5) ------------------------------------------

/** The canonical `CrisisResource` (RC81). At least one of `phone`, `sms`, `url`. */
export interface CrisisResource {
  readonly name: string;
  readonly phone?: string;
  readonly sms?: string;
  readonly url?: string;
  readonly hours?: string;
  readonly languages: readonly string[];
  readonly verifiedAt: string | null;
}

export interface CrisisDirectory {
  readonly countries: Readonly<Record<string, readonly CrisisResource[]>>;
  readonly localeFallback: Readonly<Record<string, string | null>>;
  readonly international: readonly CrisisResource[];
}

/** `src/generated/crisis_resources.json` (built by `tools/content build`, RC25). */
export const CRISIS_DIRECTORY: CrisisDirectory = crisisJson;

/** At most this many entries per response, always including `international`. */
export const MAX_CRISIS_RESOURCES = 3;

/**
 * Crisis resources for a declined reading: `cf.country` (used transiently,
 * never stored) → `localeFallback[locale]` → none, then `international`;
 * entries speaking the reading locale first, at most three in all.
 */
export function selectCrisisResources(
  country: string | null | undefined,
  locale: Locale,
  directory: CrisisDirectory = CRISIS_DIRECTORY,
): CrisisResource[] {
  const byCountry = (code: string | null | undefined): readonly CrisisResource[] =>
    code === null || code === undefined ? [] : (directory.countries[code.toUpperCase()] ?? []);
  let national = byCountry(country);
  if (national.length === 0) {
    national = byCountry(directory.localeFallback[locale]);
  }
  const speaks = (resource: CrisisResource): number =>
    resource.languages.includes(locale) ? 0 : 1;
  const ordered = [...national].sort((a, b) => speaks(a) - speaks(b));
  const international = directory.international.slice(0, MAX_CRISIS_RESOURCES);
  return [...ordered.slice(0, MAX_CRISIS_RESOURCES - international.length), ...international];
}

// --- the declined response ------------------------------------------------

/** `safety` of a declined reading (03 §9.1). */
export interface DeclinedSafety {
  readonly category: RefusalCategory;
  readonly messageKey: string;
  readonly crisisResources: readonly CrisisResource[];
  readonly canRephrase: boolean;
}

export function declinedSafety(
  category: RefusalCategory,
  where: { readonly country: string | null | undefined; readonly locale: Locale },
  directory: CrisisDirectory = CRISIS_DIRECTORY,
): DeclinedSafety {
  const policy = SAFETY_POLICY[category];
  return {
    category,
    messageKey: policy.messageKey,
    crisisResources: policy.crisisResources
      ? selectCrisisResources(where.country, where.locale, directory)
      : [],
    canRephrase: policy.canRephrase,
  };
}

// --- optional provider moderation (03 §9.4, RC97) ---------------------------

/**
 * The fixed table from a moderation endpoint's category names (OpenAI
 * `omni-moderation`) to the nearest refusal category. Categories with no
 * refusal counterpart (adult `sexual`, non-violent `illicit`) are absent: a
 * question flagged only for them is left to L2.
 */
export const MODERATION_CATEGORY_MAP: Readonly<Record<string, RefusalCategory>> = {
  'self-harm': 'self_harm',
  'self-harm/intent': 'self_harm',
  'self-harm/instructions': 'self_harm',
  'sexual/minors': 'sexual_minors',
  violence: 'harm_to_others',
  'violence/graphic': 'harm_to_others',
  'illicit/violent': 'harm_to_others',
  hate: 'hate_or_harassment',
  'hate/threatening': 'hate_or_harassment',
  harassment: 'hate_or_harassment',
  'harassment/threatening': 'hate_or_harassment',
};

/** When several flagged categories map, the first of these wins. */
const MODERATION_PRIORITY: readonly RefusalCategory[] = [
  'self_harm',
  'sexual_minors',
  'harm_to_others',
  'hate_or_harassment',
];

/**
 * The refusal category of a moderated **question**, or `null` to go on. A
 * moderation error never blocks a reading (our own layers still apply).
 */
export function moderationInputCategory(result: AiModerationResult): RefusalCategory | null {
  if (result.kind !== 'ok' || !result.flagged) {
    return null;
  }
  const mapped = new Set(
    result.categories
      .map((name) => MODERATION_CATEGORY_MAP[name])
      .filter((category): category is RefusalCategory => category !== undefined),
  );
  return MODERATION_PRIORITY.find((category) => mapped.has(category)) ?? null;
}

/** A flagged answered **output** is an L3 failure; an error is not. */
export function moderationOutputFlagged(result: AiModerationResult): boolean {
  return result.kind === 'ok' && result.flagged;
}

// --- declined-per-day limit (RC74) -----------------------------------------

/** `details.reason` of the 429 once the limit is reached (GLOSSARY §5.1). */
export const DECLINED_LIMIT_REASON = 'declinedLimit' as const;

/**
 * Whether a new reading must get `429 RATE_LIMITED reason=declinedLimit`:
 * `daily_usage.declined_count` of the install's local day has reached
 * `safety.maxDeclinedPerDay`. Only `declined` readings are counted there
 * (`ledgerRules` `countsAsDecline`); `failed` readings never are (RC74).
 */
export function declinedLimitReached(declinedToday: number, maxDeclinedPerDay: number): boolean {
  return declinedToday >= maxDeclinedPerDay;
}
