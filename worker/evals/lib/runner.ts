import { GRADERS, parseActual, type GraderContext } from './graders';
import type { CaseGrade, EvalCase, RecordedOutput } from './types';

/**
 * Grades recorded outputs against their cases. Outputs are matched by `id`
 * and grouped by `tier`, so one run can hold every routable provider + model
 * (RC97). The online `eval` / `eval:safety` commands produce the same
 * `RecordedOutput`s from a real provider and reuse this runner.
 */
export function gradeCase(c: EvalCase, o: RecordedOutput, ctx: GraderContext): CaseGrade {
  const actual = parseActual(o);
  const results = GRADERS.map((grader) => grader(c, o, actual, ctx));
  return {
    id: c.id,
    tier: o.tier,
    locale: c.locale,
    kind: c.kind,
    expectedCategory: c.expectedCategory,
    expectedOutcome: c.expectedOutcome,
    actualCategory: actual.classification,
    actualOutcome: actual.outcome,
    providerRefusal: actual.providerRefusal,
    results,
    pass: results.every((r) => r.status !== 'fail'),
  };
}

export interface TierRun {
  readonly tier: string;
  readonly providers: readonly string[];
  readonly models: readonly string[];
  readonly grades: readonly CaseGrade[];
  /** Case IDs without an output in this tier. */
  readonly missing: readonly string[];
}

export interface EvalRun {
  readonly tiers: readonly TierRun[];
  /** Output IDs that match no case. */
  readonly unknown: readonly string[];
  /** Input problems: duplicate case IDs, duplicate `(tier, id)` outputs. */
  readonly problems: readonly string[];
}

export function runEval(
  cases: readonly EvalCase[],
  outputs: readonly RecordedOutput[],
  ctx: GraderContext,
): EvalRun {
  const problems: string[] = [];
  const byId = new Map<string, EvalCase>();
  for (const c of cases) {
    if (byId.has(c.id)) {
      problems.push(`duplicate case id ${c.id}`);
    } else {
      byId.set(c.id, c);
    }
  }
  const unknown: string[] = [];
  const tiers = new Map<string, Map<string, RecordedOutput>>();
  for (const o of outputs) {
    if (!byId.has(o.id)) {
      unknown.push(o.id);
      continue;
    }
    const tier = tiers.get(o.tier) ?? new Map<string, RecordedOutput>();
    tiers.set(o.tier, tier);
    if (tier.has(o.id)) {
      problems.push(`duplicate output ${o.tier}/${o.id} (first one graded)`);
    } else {
      tier.set(o.id, o);
    }
  }
  const runs = [...tiers.entries()]
    .sort(([a], [b]) => a.localeCompare(b))
    .map(([tier, byCase]): TierRun => {
      const grades: CaseGrade[] = [];
      const missing: string[] = [];
      for (const c of byId.values()) {
        const o = byCase.get(c.id);
        if (o === undefined) {
          missing.push(c.id);
        } else {
          grades.push(gradeCase(c, o, ctx));
        }
      }
      const outs = [...byCase.values()];
      const distinct = (values: (string | null)[]): string[] =>
        [...new Set(values.filter((v): v is string => v !== null))].sort();
      return {
        tier,
        providers: distinct(outs.map((o) => o.provider)),
        models: distinct(outs.map((o) => o.model)),
        grades,
        missing,
      };
    });
  return { tiers: runs, unknown, problems };
}
