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
import { CLASSIFICATIONS, LOCALES, type Locale } from '../domain/types';

/**
 * The versioned, provider-neutral reading prompt templates (03 §9.2, RC97).
 * One directory per version under `worker/prompts/reading/`; a released
 * version is frozen (its hash is pinned in `versions.lock.json`, 06 §7), so a
 * change means a new directory and a new entry here.
 */
export const PROMPT_VERSIONS = ['v1'] as const;
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
  /** `output.schema.json`: the provider-neutral output contract (classification first). */
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
 * The Worker-side parse of a model's reading JSON (03 §9.2, §9.3 "JSON.parse,
 * then zod"). It enforces what `output.schema.json` states but vendor strict
 * modes may drop (`maxLength`), and what no portable schema can state: with
 * `classification: "none"` every section is non-empty, and, given the drawn
 * cards, the output echoes them in order and has the spread's prompt count.
 */
export const readingOutputSchema = z.discriminatedUnion('classification', [
  answeredOutputSchema,
  declinedOutputSchema,
]);

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
