import { z } from 'zod';
import { LOCALES, REFUSAL_CATEGORIES } from '../domain/types';
import {
  buildReadingPrompt,
  spreadPositionIds,
  type ReadingPromptCard,
  type ReadingPromptInput,
} from '../prompts/build';
import type { PromptVersion } from '../prompts/templates';

/**
 * Offline prompt rendering for evaluation (Phase 8 Sprints 8.2 and 8.6): turns
 * eval cases into the exact `system` / `user` text an AI provider receives,
 * without calling any provider. `scripts/render-prompt.ts` is the CLI.
 */
const hintSchema = z.enum(REFUSAL_CATEGORIES);

export const evalCaseSchema = z.object({
  id: z.string().regex(/^[A-Za-z0-9][A-Za-z0-9._-]{0,127}$/, 'id must be a safe file name'),
  locale: z.enum(LOCALES),
  spreadId: z.string().min(1),
  cards: z
    .array(
      z.object({
        cardId: z.string().min(1),
        reversed: z.boolean(),
        positionId: z.string().min(1).optional(),
      }),
    )
    .min(1),
  question: z.string().nullish(),
  prefilterHint: z.union([hintSchema, z.array(hintSchema), z.literal('none')]).optional(),
  regenerationNote: z.string().optional(),
});

export type EvalCase = z.infer<typeof evalCaseSchema>;

export type ParsedCases =
  | { readonly ok: true; readonly cases: readonly EvalCase[] }
  | { readonly ok: false; readonly error: string };

function issueText(error: z.ZodError): string {
  return error.issues
    .map(
      (issue) => `${issue.path.length === 0 ? '(case)' : issue.path.join('.')}: ${issue.message}`,
    )
    .join('; ');
}

/**
 * Parses a `.jsonl` file (one case per non-empty line) or a JSON file holding
 * one case or an array of cases. Case IDs must be unique.
 */
export function parseCases(text: string, jsonl: boolean): ParsedCases {
  const raw: { readonly where: string; readonly value: unknown }[] = [];
  if (jsonl) {
    const lines = text.split(/\r?\n/);
    for (const [index, line] of lines.entries()) {
      if (line.trim() === '') {
        continue;
      }
      try {
        raw.push({ where: `line ${String(index + 1)}`, value: JSON.parse(line) });
      } catch {
        return { ok: false, error: `line ${String(index + 1)}: not valid JSON` };
      }
    }
  } else {
    let parsed: unknown;
    try {
      parsed = JSON.parse(text);
    } catch {
      return { ok: false, error: 'not valid JSON' };
    }
    const values: unknown[] = Array.isArray(parsed) ? parsed : [parsed];
    values.forEach((value, index) => raw.push({ where: `case ${String(index + 1)}`, value }));
  }
  const cases: EvalCase[] = [];
  const ids = new Set<string>();
  for (const { where, value } of raw) {
    const result = evalCaseSchema.safeParse(value);
    if (!result.success) {
      return { ok: false, error: `${where}: ${issueText(result.error)}` };
    }
    if (ids.has(result.data.id)) {
      return { ok: false, error: `${where}: duplicate id ${result.data.id}` };
    }
    ids.add(result.data.id);
    cases.push(result.data);
  }
  if (cases.length === 0) {
    return { ok: false, error: 'no cases' };
  }
  return { ok: true, cases };
}

/** Cards without `positionId` take the spread's positions in draw order. */
function placeCards(evalCase: EvalCase): ReadingPromptCard[] | string {
  const positions = spreadPositionIds(evalCase.spreadId);
  if (positions === undefined) {
    return `unknown spread ${evalCase.spreadId}`;
  }
  const cards: ReadingPromptCard[] = [];
  for (const [index, card] of evalCase.cards.entries()) {
    const positionId = card.positionId ?? positions[index];
    if (positionId === undefined) {
      return `spread ${evalCase.spreadId} has only ${String(positions.length)} positions`;
    }
    cards.push({ positionId, cardId: card.cardId, reversed: card.reversed });
  }
  return cards;
}

export type RenderedCase =
  | { readonly ok: true; readonly input: ReadingPromptInput }
  | { readonly ok: false; readonly error: string };

export function renderCase(evalCase: EvalCase, version: PromptVersion): RenderedCase {
  const cards = placeCards(evalCase);
  if (typeof cards === 'string') {
    return { ok: false, error: cards };
  }
  const hint = evalCase.prefilterHint;
  const built = buildReadingPrompt(
    {
      spreadId: evalCase.spreadId,
      cards,
      locale: evalCase.locale,
      question: evalCase.question ?? null,
      prefilterHints:
        hint === undefined || hint === 'none' ? [] : Array.isArray(hint) ? hint : [hint],
      ...(evalCase.regenerationNote !== undefined
        ? { regenerationNote: evalCase.regenerationNote }
        : {}),
    },
    version,
  );
  return built.ok ? { ok: true, input: built.input } : { ok: false, error: built.error };
}

/** The text a provider receives: the system prefix, then the user message. */
export function providerView(input: ReadingPromptInput): string {
  return `=== SYSTEM ===\n${input.system}\n=== USER ===\n${input.user}\n`;
}
