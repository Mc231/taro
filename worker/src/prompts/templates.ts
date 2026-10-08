import { z } from 'zod';
import outputSchemaV1 from '../../prompts/reading/v1/output.schema.json';
import promptDataV1 from '../../prompts/reading/v1/prompt_data.json';
import styleArV1 from '../../prompts/reading/v1/style.ar.md';
import styleDeV1 from '../../prompts/reading/v1/style.de.md';
import styleEnV1 from '../../prompts/reading/v1/style.en.md';
import styleEsV1 from '../../prompts/reading/v1/style.es.md';
import styleFrV1 from '../../prompts/reading/v1/style.fr.md';
import styleItV1 from '../../prompts/reading/v1/style.it.md';
import styleJaV1 from '../../prompts/reading/v1/style.ja.md';
import styleKoV1 from '../../prompts/reading/v1/style.ko.md';
import styleNlV1 from '../../prompts/reading/v1/style.nl.md';
import stylePtV1 from '../../prompts/reading/v1/style.pt.md';
import styleTrV1 from '../../prompts/reading/v1/style.tr.md';
import styleUkV1 from '../../prompts/reading/v1/style.uk.md';
import systemV1 from '../../prompts/reading/v1/system.md';
import userV1 from '../../prompts/reading/v1/user.md';
import outputSchemaV2 from '../../prompts/reading/v2/output.schema.json';
import promptDataV2 from '../../prompts/reading/v2/prompt_data.json';
import styleArV2 from '../../prompts/reading/v2/style.ar.md';
import styleDeV2 from '../../prompts/reading/v2/style.de.md';
import styleEnV2 from '../../prompts/reading/v2/style.en.md';
import styleEsV2 from '../../prompts/reading/v2/style.es.md';
import styleFrV2 from '../../prompts/reading/v2/style.fr.md';
import styleItV2 from '../../prompts/reading/v2/style.it.md';
import styleJaV2 from '../../prompts/reading/v2/style.ja.md';
import styleKoV2 from '../../prompts/reading/v2/style.ko.md';
import styleNlV2 from '../../prompts/reading/v2/style.nl.md';
import stylePtV2 from '../../prompts/reading/v2/style.pt.md';
import styleTrV2 from '../../prompts/reading/v2/style.tr.md';
import styleUkV2 from '../../prompts/reading/v2/style.uk.md';
import systemV2 from '../../prompts/reading/v2/system.md';
import userV2 from '../../prompts/reading/v2/user.md';
import { CLASSIFICATIONS, LOCALES, type Locale } from '../domain/types';

/**
 * The versioned, provider-neutral reading prompt templates (03 §9.2, RC97).
 * One directory per version under `worker/prompts/reading/`; a released
 * version is frozen (its hash is pinned in `versions.lock.json`, 06 §7), so a
 * change means a new directory and a new entry here.
 */
export const PROMPT_VERSIONS = ['v1', 'v2'] as const;
export type PromptVersion = (typeof PROMPT_VERSIONS)[number];

export function isPromptVersion(value: unknown): value is PromptVersion {
  return PROMPT_VERSIONS.includes(value as PromptVersion);
}

const wordRange = z.tuple([z.number().int().positive(), z.number().int().positive()]);

const sentenceRange = z.string().regex(/^\d+–\d+$/);

const spreadNotesSchema = z.strictObject({
  name: z.string().min(1),
  positions: z.record(z.string(), z.string().min(1)),
  /** The prompt's own position notes, worded positively (no "not a promise" to echo). */
  positionNotes: z.record(z.string(), z.string().min(1)),
  words: z.strictObject({
    overview: wordRange,
    card: wordRange,
    synthesis: wordRange,
    total: wordRange,
  }),
  /** Sentence counts per section, e.g. "3–5": a length anchor models follow in every language. */
  sentences: z.strictObject({
    overview: sentenceRange,
    card: sentenceRange,
    synthesis: sentenceRange,
  }),
  reflectionPrompts: z.number().int().min(1).max(3),
  note: z.string().min(1),
});

const localeNotesSchema = z.strictObject({
  /** Words (or characters) of this locale per English word of the 01 §7.4 budget. */
  factor: z.number().positive(),
  /** How the scaled budget is counted, e.g. "German words", "Japanese characters". */
  unit: z.string().min(1),
  /** The register, restated in the final instruction of the user message. */
  address: z.string().min(1),
  /** Everyday words of this locale the L3 lexicon rejects, repeated in the final self-check. */
  checkWords: z.string().min(1),
});

/** `prompt_data.json`: the versioned wording and budgets that are data, not prose. */
export const promptDataSchema = z.strictObject({
  locales: z.record(z.enum(LOCALES), z.string().min(1)),
  localeNotes: z.record(z.enum(LOCALES), localeNotesSchema),
  spreads: z.record(z.string(), spreadNotesSchema),
  suits: z.strictObject({
    wands: z.string().min(1),
    cups: z.string().min(1),
    swords: z.string().min(1),
    pentacles: z.string().min(1),
  }),
  ranks: z.record(z.string().regex(/^(0[1-9]|1[0-4])$/), z.string().min(1)),
  /** One traditional image detail per card ID, rendered as the card's `Image:` line. */
  images: z.record(z.string().regex(/^(major_(0\d|1\d|2[01])|(wands|cups|swords|pentacles)_(0[1-9]|1[0-4]))$/), z.string().min(1)),
  phrases: z.strictObject({
    noQuestion: z.string().min(1),
    withQuestion: z.string().min(1),
    noHint: z.string().min(1),
    regenerationIntro: z.string().min(1),
    lengthConverted: z.string().includes('{factor}'),
    lengthFloor: z.string().min(1),
  }),
});

export type PromptData = z.infer<typeof promptDataSchema>;
export type SpreadNotes = z.infer<typeof spreadNotesSchema>;
export type OutputSchema = Readonly<Record<string, unknown>>;

export interface ReadingTemplateSet {
  readonly version: PromptVersion;
  /** `system.md`: the static prefix, with no placeholders. */
  readonly system: string;
  /** `user.md`: the per-reading message around the tagged data. */
  readonly user: string;
  /**
   * `output.schema.json`: the provider-neutral output contract (classification
   * first), a template that `outputSchemaFor` expands per spread.
   */
  readonly outputSchema: OutputSchema;
  readonly data: PromptData;
  /** `style.<locale>.md`: register, names, forms to avoid and rejected words (≤ 1 KB each). */
  readonly styles: Readonly<Record<Locale, string>>;
}

export const READING_TEMPLATES: Readonly<Record<PromptVersion, ReadingTemplateSet>> = {
  v1: {
    version: 'v1',
    system: systemV1,
    user: userV1,
    outputSchema: outputSchemaV1,
    data: promptDataSchema.parse(promptDataV1),
    styles: {
      en: styleEnV1,
      ar: styleArV1,
      de: styleDeV1,
      es: styleEsV1,
      fr: styleFrV1,
      it: styleItV1,
      ja: styleJaV1,
      ko: styleKoV1,
      nl: styleNlV1,
      pt: stylePtV1,
      tr: styleTrV1,
      uk: styleUkV1,
    },
  },
  v2: {
    version: 'v2',
    system: systemV2,
    user: userV2,
    outputSchema: outputSchemaV2,
    data: promptDataSchema.parse(promptDataV2),
    styles: {
      en: styleEnV2,
      ar: styleArV2,
      de: styleDeV2,
      es: styleEsV2,
      fr: styleFrV2,
      it: styleItV2,
      ja: styleJaV2,
      ko: styleKoV2,
      nl: styleNlV2,
      pt: stylePtV2,
      tr: styleTrV2,
      uk: styleUkV2,
    },
  },
};

/**
 * The files of a template set as `[name, text]` pairs, sorted by name: the
 * input of the version hash (JSON files in their parsed, re-serialised form).
 */
export function templateFiles(set: ReadingTemplateSet): [string, string][] {
  const files: [string, string][] = [
    ['system.md', set.system],
    ['user.md', set.user],
    ['output.schema.json', JSON.stringify(set.outputSchema)],
    ['prompt_data.json', JSON.stringify(set.data)],
    ...LOCALES.map((locale): [string, string] => [`style.${locale}.md`, set.styles[locale]]),
  ];
  return files.sort(([a], [b]) => (a < b ? -1 : 1));
}

/** Code points, as JSON Schema `maxLength` counts them. */
function codePoints(text: string): number {
  return Array.from(text).length;
}

const limited = (max: number) =>
  z.string().refine((text) => codePoints(text) <= max, `longer than ${String(max)} characters`);
const filled = (max: number) =>
  limited(max).refine((text) => text.trim() !== '', 'empty in an answered reading');

const outputCardSchema = z.strictObject({
  positionId: z.string(),
  cardId: z.string(),
  reversed: z.boolean(),
  interpretation: limited(900),
});

/** A declined answer: a refusal category; the other fields are ignored (03 §9.2). */
const declinedOutputSchema = z.strictObject({
  classification: z.enum(CLASSIFICATIONS).exclude(['none']),
  title: limited(80),
  overview: limited(700),
  cards: z.array(outputCardSchema),
  synthesis: limited(1400),
  reflectionPrompts: z.array(limited(200)).min(1).max(3),
});

/** An answered reading: every section filled (the JSON Schema cannot say so portably). */
const answeredOutputSchema = z.strictObject({
  classification: z.literal('none'),
  title: filled(80),
  overview: filled(700),
  cards: z
    .array(outputCardSchema.extend({ interpretation: filled(900) }))
    .min(1),
  synthesis: filled(1400),
  reflectionPrompts: z.array(filled(200)).min(1).max(3),
});

/**
 * The Worker-side check of a reading in its `ReadingOutput` form (03 §9.2,
 * §9.3; the model's keyed JSON goes through `parseModelOutput` first). It
 * enforces what `output.schema.json` states but vendor strict modes may drop
 * (`maxLength`), and what no portable schema can state: with
 * `classification: "none"` every section is non-empty, and, given the drawn
 * cards, the output echoes them in order and has the spread's prompt count.
 */
export const readingOutputSchema = z.discriminatedUnion('classification', [
  answeredOutputSchema,
  declinedOutputSchema,
]);

/**
 * The Worker's form of a reading (what `AiResult.ok`, L3, the store and the
 * DTO carry): `cards` in position order with their `positionId`, and
 * `reflectionPrompts` as a list. The model's wire form keys both by name
 * (`ModelReadingOutput`); `parseModelOutput` converts.
 */
export type ReadingOutput = z.infer<typeof readingOutputSchema>;

export interface ExpectedReading {
  readonly cards: readonly {
    readonly positionId: string;
    readonly cardId: string;
    readonly reversed: boolean;
  }[];
  readonly reflectionPrompts: number;
}

export type ParsedReadingOutput =
  | { readonly ok: true; readonly output: ReadingOutput }
  | { readonly ok: false; readonly issues: readonly string[] };

export function parseReadingOutput(
  value: unknown,
  expected?: ExpectedReading,
): ParsedReadingOutput {
  const parsed = readingOutputSchema.safeParse(value);
  if (!parsed.success) {
    return {
      ok: false,
      issues: parsed.error.issues.map(
        (issue) => `${['$', ...issue.path.map(String)].join('.')}: ${issue.message}`,
      ),
    };
  }
  const output = parsed.data;
  if (expected === undefined || output.classification !== 'none') {
    return { ok: true, output };
  }
  const issues: string[] = [];
  if (output.cards.length !== expected.cards.length) {
    issues.push(
      `$.cards: ${String(output.cards.length)} entries, ${String(expected.cards.length)} drawn`,
    );
  }
  expected.cards.forEach((want, index) => {
    const got = output.cards[index];
    if (
      got !== undefined &&
      (got.positionId !== want.positionId ||
        got.cardId !== want.cardId ||
        got.reversed !== want.reversed)
    ) {
      issues.push(`$.cards.${String(index)}: does not echo ${want.positionId}/${want.cardId}`);
    }
  });
  if (output.reflectionPrompts.length !== expected.reflectionPrompts) {
    issues.push(
      `$.reflectionPrompts: ${String(output.reflectionPrompts.length)}, expected ${String(expected.reflectionPrompts)}`,
    );
  }
  return issues.length === 0 ? { ok: true, output } : { ok: false, issues };
}

// --- the model's wire form (03 §9.2) -------------------------------------

/** The `cards` property name of the template that stands for every position ID. */
export const POSITION_KEY_PLACEHOLDER = '<positionId>';
/** The `reflectionPrompts` property name of the template that stands for prompt1..promptN. */
export const PROMPT_KEY_PLACEHOLDER = 'prompt<n>';

/** The wire key of the `n`-th reflection prompt (1-based). */
export function reflectionPromptKey(n: number): string {
  return `prompt${String(n)}`;
}

type SchemaObject = Readonly<Record<string, unknown>>;

function isSchemaObject(value: unknown): value is SchemaObject {
  return typeof value === 'object' && value !== null && !Array.isArray(value);
}

/** Replaces the one templated property of `node` by `keys`, all required, in order. */
function expandTemplate(
  node: unknown,
  placeholder: string,
  keys: readonly string[],
): SchemaObject {
  const properties = isSchemaObject(node) ? node['properties'] : undefined;
  const entry = isSchemaObject(properties) ? properties[placeholder] : undefined;
  if (!isSchemaObject(node) || entry === undefined) {
    throw new Error(`output schema template has no "${placeholder}" property`);
  }
  return {
    ...node,
    properties: Object.fromEntries(keys.map((key) => [key, entry])),
    required: [...keys],
    additionalProperties: false,
  };
}

/**
 * The output schema of one request (03 §9.2): the template with one required
 * `cards` property per position of the spread (in draw order) and
 * `prompt1..promptN` for its reflection prompts, every object closed. Vendor
 * strict modes enforce required properties but not `minItems`/`maxItems`
 * (Anthropic rejects them), so keyed objects are the portable way to fix both
 * counts. It depends only on the spread, never on the drawn cards, so each
 * vendor compiles one grammar per spread.
 */
export function outputSchemaFor(
  template: OutputSchema,
  positionIds: readonly string[],
  reflectionPrompts: number,
): OutputSchema {
  const properties = template['properties'];
  if (!isSchemaObject(properties)) {
    throw new Error('output schema template has no properties');
  }
  return {
    ...template,
    properties: {
      ...properties,
      cards: expandTemplate(properties['cards'], POSITION_KEY_PLACEHOLDER, positionIds),
      reflectionPrompts: expandTemplate(
        properties['reflectionPrompts'],
        PROMPT_KEY_PLACEHOLDER,
        Array.from({ length: reflectionPrompts }, (_, i) => reflectionPromptKey(i + 1)),
      ),
    },
  };
}

const modelCardSchema = z.strictObject({
  cardId: z.string(),
  reversed: z.boolean(),
  interpretation: z.string(),
});

/** The model's JSON as `outputSchemaFor` describes it; lengths are checked after conversion. */
const modelOutputSchema = z.strictObject({
  classification: z.enum(CLASSIFICATIONS),
  title: z.string(),
  overview: z.string(),
  cards: z.record(z.string(), modelCardSchema),
  synthesis: z.string(),
  reflectionPrompts: z.record(z.string(), z.string()),
});

export type ModelReadingOutput = z.infer<typeof modelOutputSchema>;

/** Entries in `order` first, then any other key in object order (the sort is stable). */
function inOrder<T>(record: Readonly<Record<string, T>>, order: readonly string[]): [string, T][] {
  const rank = (key: string): number => {
    const index = order.indexOf(key);
    return index === -1 ? order.length : index;
  };
  return Object.entries(record).sort(([a], [b]) => rank(a) - rank(b));
}

/**
 * Parses the model's reading JSON (03 §9.2, §9.3 "JSON.parse, then zod"): the
 * keyed wire form, converted to `ReadingOutput` (cards in the drawn order, then
 * any unexpected key; prompts by number), then `parseReadingOutput`, which
 * checks lengths, filled sections, the card echo and the prompt count.
 */
export function parseModelOutput(value: unknown, expected?: ExpectedReading): ParsedReadingOutput {
  const parsed = modelOutputSchema.safeParse(value);
  if (!parsed.success) {
    return {
      ok: false,
      issues: parsed.error.issues.map(
        (issue) => `${['$', ...issue.path.map(String)].join('.')}: ${issue.message}`,
      ),
    };
  }
  const wire = parsed.data;
  const positions = expected?.cards.map((card) => card.positionId) ?? [];
  const promptKeys = Array.from({ length: expected?.reflectionPrompts ?? 0 }, (_, i) =>
    reflectionPromptKey(i + 1),
  );
  return parseReadingOutput(
    {
      classification: wire.classification,
      title: wire.title,
      overview: wire.overview,
      cards: inOrder(wire.cards, positions).map(([positionId, card]) => ({ positionId, ...card })),
      synthesis: wire.synthesis,
      reflectionPrompts: inOrder(wire.reflectionPrompts, promptKeys).map(([, prompt]) => prompt),
    },
    expected,
  );
}

/** The wire form of a `ReadingOutput` (eval recordings, fixtures): the inverse of `parseModelOutput`. */
export function toModelOutput(output: ReadingOutput): ModelReadingOutput {
  return {
    classification: output.classification,
    title: output.title,
    overview: output.overview,
    cards: Object.fromEntries(
      output.cards.map(({ positionId, ...card }) => [positionId, card]),
    ),
    synthesis: output.synthesis,
    reflectionPrompts: Object.fromEntries(
      output.reflectionPrompts.map((prompt, i) => [reflectionPromptKey(i + 1), prompt]),
    ),
  };
}
