import { parseReadingOutput, type ExpectedReading, type ReadingOutput } from '../prompts/templates';
import { findContacts } from '../safety/contacts';
import { checkLanguage } from '../safety/language';
import { findForbiddenClaims, safetyLexicons, type SafetyLexicon } from '../safety/lexicons';
import type { Locale, RefusalCategory } from './types';

/**
 * The L3 output validator (03 §9.4, BE12). Given the model's parsed JSON it
 * decides: an L2 decline (`classification` ≠ `none`), an answered reading
 * that may be shown, or a violation that earns one regeneration with a note
 * naming it (a second one → `failed` + refund). The zod parse, card/position
 * echo, lengths and the spread's reflection-prompt count come from
 * `parseReadingOutput` (`src/prompts/templates.ts`), which the offline
 * `schema` grader uses too; contacts and the language heuristic are the
 * graders' shared code in `src/safety/`.
 */
export type ViolationKind =
  'schema' | 'echo' | 'length' | 'reflection_prompts' | 'forbidden_claim' | 'contact' | 'language';

export interface Violation {
  readonly kind: ViolationKind;
  /** For the regeneration note only; logs carry just `kind` (BE13: no output text in logs). */
  readonly detail: string;
}

export type AnsweredReading = Extract<ReadingOutput, { classification: 'none' }>;

export type OutputVerdict =
  | { readonly kind: 'answered'; readonly reading: AnsweredReading }
  | { readonly kind: 'declined'; readonly category: RefusalCategory }
  | { readonly kind: 'invalid'; readonly violations: readonly Violation[] };

export interface ValidationContext {
  readonly locale: Locale;
  /** Drawn cards in position order and the spread's prompt count (`ReadingPromptInput.expected`). */
  readonly expected: ExpectedReading;
  /** Default: the production lexicon of `locale`. */
  readonly lexicon?: SafetyLexicon;
}

function issueKind(issue: string): ViolationKind {
  if (issue.startsWith('$.reflectionPrompts:') && issue.includes('expected')) {
    return 'reflection_prompts';
  }
  if (issue.includes('does not echo') || issue.includes(' drawn')) {
    return 'echo';
  }
  return issue.includes('longer than') ? 'length' : 'schema';
}

/** The prose of an answered reading, in wire order. */
export function readingText(reading: AnsweredReading): string {
  return [
    reading.title,
    reading.overview,
    ...reading.cards.map((card) => card.interpretation),
    reading.synthesis,
    ...reading.reflectionPrompts,
  ].join('\n');
}

export function validateReadingOutput(value: unknown, ctx: ValidationContext): OutputVerdict {
  const parsed = parseReadingOutput(value, ctx.expected);
  if (!parsed.ok) {
    return {
      kind: 'invalid',
      violations: parsed.issues.map((issue) => ({ kind: issueKind(issue), detail: issue })),
    };
  }
  const output = parsed.output;
  if (output.classification !== 'none') {
    return { kind: 'declined', category: output.classification };
  }
  const text = readingText(output);
  const lexicon = ctx.lexicon ?? safetyLexicons()[ctx.locale];
  const violations: Violation[] = [
    ...findForbiddenClaims(text, lexicon).map((hit): Violation => ({
      kind: 'forbidden_claim',
      detail: `forbidden wording "${hit.match}" (${hit.phrase})`,
    })),
    ...findContacts(text).map((found): Violation => ({
      kind: 'contact',
      detail: `contact detail ${found}`,
    })),
  ];
  const language = checkLanguage(text, ctx.locale);
  if (!language.ok && !language.weak) {
    violations.push({
      kind: 'language',
      detail: `not written in ${ctx.locale}: ${language.detail}`,
    });
  }
  return violations.length === 0
    ? { kind: 'answered', reading: output }
    : { kind: 'invalid', violations };
}

/** The `regenerationNote` of the one retry (03 §9.4): the violations, one per line. */
export function regenerationNote(violations: readonly Violation[]): string {
  return violations.map((violation) => `- ${violation.detail}`).join('\n');
}
