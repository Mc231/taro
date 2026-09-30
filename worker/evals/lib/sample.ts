import { prefilter } from '../../src/safety/prefilter';
import { LOCALES, REFUSAL_CATEGORIES, type EvalCase } from './types';

/**
 * The `smoke` sample of the live eval (Sprint 8.6): about 50 cases picked
 * deterministically so that one cheap run still touches every locale, every
 * spread, every 03 §9.4 category, the benign-but-tricky controls, prompt
 * injections / jailbreaks, the empty question and the L1 prefilter paths
 * (a `<prefilter_hint>` and a hard block). It is a quick check between full
 * runs; the 05 §4.3 bar still needs the full suites.
 */
export const SMOKE_SPREADS = [
  'single',
  'three_ppf',
  'three_sao',
  'relationship',
  'two_paths',
  'celtic_cross',
] as const;

/** One quota: the cases it counts and how many the sample needs. */
export interface Quota {
  readonly id: string;
  readonly need: number;
  readonly matches: (c: EvalCase, l1: L1Probe) => boolean;
}

/** What the L1 prefilter does with a case's question. */
export type L1Probe = 'block' | 'hint' | 'pass';

export function l1Probe(c: EvalCase): L1Probe {
  const result = prefilter(c.question, c.locale);
  if (result.kind === 'block') {
    return 'block';
  }
  return result.hints.length > 0 ? 'hint' : 'pass';
}

const isKind =
  (...kinds: string[]) =>
  (c: EvalCase): boolean =>
    c.kind !== null && kinds.includes(c.kind);

export const SMOKE_QUOTAS: readonly Quota[] = [
  ...LOCALES.map((locale) => ({
    id: `locale:${locale}`,
    need: 4,
    matches: (c: EvalCase) => c.locale === locale,
  })),
  ...SMOKE_SPREADS.map((spread) => ({
    id: `spread:${spread}`,
    need: 2,
    matches: (c: EvalCase) => c.spreadId === spread,
  })),
  ...REFUSAL_CATEGORIES.map((category) => ({
    id: `category:${category}`,
    need: category === 'self_harm' ? 4 : 2,
    matches: (c: EvalCase) => c.expectedCategory === category,
  })),
  { id: 'benign', need: 6, matches: (c) => c.expectedOutcome === 'answered' },
  { id: 'kind:benign_tricky', need: 4, matches: isKind('benign_tricky') },
  { id: 'kind:jailbreak', need: 3, matches: isKind('jailbreak') },
  { id: 'kind:injection', need: 3, matches: isKind('injection') },
  { id: 'question:empty', need: 1, matches: (c) => (c.question ?? '').trim() === '' },
  { id: 'l1:hint', need: 3, matches: (_c, l1) => l1 === 'hint' },
  { id: 'l1:block', need: 2, matches: (_c, l1) => l1 === 'block' },
];

export interface Sample {
  readonly cases: readonly EvalCase[];
  /** Quotas the input could not fill (id → how many are still missing). */
  readonly unmet: Readonly<Record<string, number>>;
}

/**
 * Greedy set cover: repeatedly takes the case that fills the most open
 * quota slots, ties broken by input order, so the same inputs always give
 * the same sample. Only cases with a spread and cards (runnable live) count.
 */
export function selectSample(
  cases: readonly EvalCase[],
  quotas: readonly Quota[] = SMOKE_QUOTAS,
  probe: (c: EvalCase) => L1Probe = l1Probe,
): Sample {
  const pool = cases
    .filter((c) => c.spreadId !== null && c.cards !== null)
    .map((c) => {
      const l1 = probe(c);
      return { c, hits: quotas.filter((q) => q.matches(c, l1)).map((q) => q.id) };
    });
  const open = new Map(quotas.map((q) => [q.id, q.need]));
  const taken = new Set<number>();
  const picked: EvalCase[] = [];
  for (;;) {
    let best = -1;
    let bestScore = 0;
    pool.forEach((entry, index) => {
      if (taken.has(index)) {
        return;
      }
      const score = entry.hits.filter((id) => (open.get(id) ?? 0) > 0).length;
      if (score > bestScore) {
        best = index;
        bestScore = score;
      }
    });
    const entry = pool[best];
    if (entry === undefined) {
      break;
    }
    taken.add(best);
    picked.push(entry.c);
    for (const id of entry.hits) {
      open.set(id, Math.max(0, (open.get(id) ?? 0) - 1));
    }
  }
  const unmet = Object.fromEntries([...open.entries()].filter(([, left]) => left > 0));
  return { cases: picked, unmet };
}
