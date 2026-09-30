import cardsJson from '../../src/generated/deck/cards.json';
import type { CliDeps } from '../../src/admin/cli';
import { leakIndex, type GraderContext } from './graders';
import { parseCases, parseOutputFileInDir, parseOutputs, tierOfDir } from './io';
import { buildPhraseBook } from './phrases';
import { renderMarkdown, renderResultsJsonl, summarize } from './report';
import { runEval } from './runner';
import { SPEC_OUTPUT_SCHEMA } from './specSchema';
import type { EvalCase, RecordedOutput } from './types';

/**
 * `npm run eval:offline -- --cases <jsonl> [--cases <jsonl>…] --outputs <dir|jsonl|json> [--outputs …] --out <dir>
 *   [--prompt v1] [--tier <label>] [--banned <yaml>] [--allow-incomplete]`
 *
 * Grades pre-recorded model outputs (`{id, tier?, provider?, model?, output, refusal?}`)
 * against eval cases with the rule-based graders. In an `--outputs` directory,
 * `<id>.json` may also hold the raw model response of case `<id>`, files
 * starting with `_` or `.` are skipped, and a directory named `out_<tier>`
 * sets the tier unless `--tier` is given. It never calls a model and
 * needs no provider key. Writes `report.md`, `summary.json` and
 * `results.jsonl` into `--out`. Exit codes: 0 pass, 1 input error, 2 usage,
 * 3 the 05 §4.3 bar failed or the run is incomplete (0 for incomplete with
 * `--allow-incomplete`).
 */
export const USAGE =
  'usage: eval-offline --cases <jsonl> [--cases <jsonl>…] --outputs <dir|jsonl|json> [--outputs …] --out <dir> [--prompt v1] [--tier <label>] [--banned <yaml>] [--allow-incomplete]';

export const DEFAULT_BANNED = '../tools/store_copy/banned_phrases.yaml';

const REPEATABLE = new Set(['--cases', '--outputs']);
const SINGLE = new Set(['--out', '--prompt', '--tier', '--banned']);
const FLAGS = new Set(['--allow-incomplete']);

interface Args {
  readonly lists: ReadonlyMap<string, readonly string[]>;
  readonly options: ReadonlyMap<string, string>;
  readonly flags: ReadonlySet<string>;
}

export function parseEvalArgs(argv: readonly string[]): Args | string {
  const lists = new Map<string, string[]>();
  const options = new Map<string, string>();
  const flags = new Set<string>();
  for (let i = 0; i < argv.length; i++) {
    const arg = argv[i] ?? '';
    const eq = arg.indexOf('=');
    const name = eq >= 0 ? arg.slice(0, eq) : arg;
    if (FLAGS.has(name) && eq < 0) {
      flags.add(name);
      continue;
    }
    if (!REPEATABLE.has(name) && !SINGLE.has(name)) {
      return `unknown argument ${arg}`;
    }
    const value = eq >= 0 ? arg.slice(eq + 1) : argv[++i];
    if (value === undefined || value === '' || value.startsWith('--')) {
      return `${name} needs a value`;
    }
    if (REPEATABLE.has(name)) {
      lists.set(name, [...(lists.get(name) ?? []), value]);
    } else if (options.has(name)) {
      return `${name} given twice`;
    } else {
      options.set(name, value);
    }
  }
  return { lists, options, flags };
}

function isDataFile(path: string): boolean {
  return path.endsWith('.jsonl') || path.endsWith('.json');
}

export function cardNames(): Map<string, string> {
  return new Map(cardsJson.cards.map((card) => [card.id, card.name]));
}

/**
 * `spreads.<id>.reflectionPrompts` of a `prompt_data.json`; entries without
 * a positive integer count are skipped (the Worker's zod schema owns the file).
 */
export function reflectionPromptCounts(promptDataText: string): Record<string, number> {
  const data = JSON.parse(promptDataText) as { spreads?: Record<string, unknown> };
  const counts: Record<string, number> = {};
  for (const [id, spread] of Object.entries(data.spreads ?? {})) {
    const count = (spread as { reflectionPrompts?: unknown } | null)?.reflectionPrompts;
    if (typeof count === 'number' && Number.isInteger(count) && count > 0) {
      counts[id] = count;
    }
  }
  return counts;
}

async function optionalFile(deps: CliDeps, path: string): Promise<string | null> {
  try {
    return await deps.readFile(path);
  } catch {
    return null;
  }
}

/**
 * The grader context of a prompt version: its output schema (or the 03 §9.2
 * one), the banned phrases, the system prompt for leakage checks and the
 * reflection-prompt counts. Shared by `eval:offline` and the live `eval`.
 */
export async function loadGraderContext(
  deps: CliDeps,
  prompt: string,
  bannedPath: string,
): Promise<{ readonly ctx: GraderContext; readonly schemaSource: string }> {
  const phrases = buildPhraseBook(await deps.readFile(bannedPath));
  const promptDir = `prompts/reading/${prompt}`;
  const schemaText = await optionalFile(deps, `${promptDir}/output.schema.json`);
  const systemText = await optionalFile(deps, `${promptDir}/system.md`);
  const promptData = await optionalFile(deps, `${promptDir}/prompt_data.json`);
  const schemaSource =
    schemaText === null
      ? `03 §9.2 (no ${promptDir}/output.schema.json)`
      : `${promptDir}/output.schema.json`;
  if (systemText === null) {
    deps.err(`note: no ${promptDir}/system.md; leakage checks markers only`);
  }
  const ctx: GraderContext = {
    schema: schemaText === null ? SPEC_OUTPUT_SCHEMA : (JSON.parse(schemaText) as unknown),
    phrases,
    leak: systemText === null ? null : leakIndex(systemText),
    cardNames: cardNames(),
    ...(promptData === null ? {} : { reflectionPrompts: reflectionPromptCounts(promptData) }),
  };
  return { ctx, schemaSource };
}

export async function main(
  argv: readonly string[],
  deps: CliDeps,
  now: () => Date,
): Promise<number> {
  const args = parseEvalArgs(argv);
  if (typeof args === 'string') {
    deps.err(`${args}\n${USAGE}`);
    return 2;
  }
  const casePaths = args.lists.get('--cases') ?? [];
  const outputPaths = args.lists.get('--outputs') ?? [];
  const outDir = args.options.get('--out');
  const prompt = args.options.get('--prompt') ?? 'v1';
  if (casePaths.length === 0 || outputPaths.length === 0 || outDir === undefined) {
    deps.err(`--cases, --outputs and --out are required\n${USAGE}`);
    return 2;
  }
  if (!/^v\d+$/u.test(prompt)) {
    deps.err(`--prompt must look like v1\n${USAGE}`);
    return 2;
  }
  const explicitTier = args.options.get('--tier');
  const inputErrors: string[] = [];
  const sources: string[] = [];
  try {
    const cases: EvalCase[] = [];
    for (const path of casePaths) {
      const parsed = parseCases(await deps.readFile(path), path);
      cases.push(...parsed.items);
      inputErrors.push(...parsed.errors);
      sources.push(path);
    }
    const outputs: RecordedOutput[] = [];
    for (const path of outputPaths) {
      if (isDataFile(path)) {
        const parsed = parseOutputs(await deps.readFile(path), path, explicitTier ?? 'default');
        outputs.push(...parsed.items);
        inputErrors.push(...parsed.errors);
        sources.push(path);
        continue;
      }
      if (deps.listDir === undefined) {
        throw new Error(`cannot list directory ${path}`);
      }
      const tier = explicitTier ?? tierOfDir(path) ?? 'default';
      const names = (await deps.listDir(path)).filter(isDataFile).sort();
      for (const name of names.filter((n) => n.startsWith('_') || n.startsWith('.'))) {
        deps.err(`note: skipped ${path.replace(/\/+$/u, '')}/${name} (leading _ or .)`);
      }
      const base = path.replace(/\/+$/u, '');
      const files = names
        .filter((n) => !n.startsWith('_') && !n.startsWith('.'))
        .map((name) => `${base}/${name}`);
      for (const file of files) {
        const parsed = parseOutputFileInDir(await deps.readFile(file), file, tier);
        outputs.push(...parsed.items);
        inputErrors.push(...parsed.errors);
      }
      // One entry per directory: a run over many `out_<tier>/` folders would
      // otherwise list every `<id>.json` in the report header.
      sources.push(
        files.length === 1 ? files.join('') : `${base}/ (${String(files.length)} files)`,
      );
    }
    const { ctx, schemaSource } = await loadGraderContext(
      deps,
      prompt,
      args.options.get('--banned') ?? DEFAULT_BANNED,
    );
    const run = runEval(cases, outputs, ctx);
    const summary = summarize(run, {
      promptVersion: prompt,
      mode: 'offline',
      generatedAt: now().toISOString(),
      sources,
      schemaSource,
      inputErrors,
    });
    const dir = outDir.replace(/\/+$/u, '');
    await deps.writeFile(`${dir}/report.md`, renderMarkdown(summary, run));
    await deps.writeFile(`${dir}/summary.json`, `${JSON.stringify(summary, null, 2)}\n`);
    await deps.writeFile(`${dir}/results.jsonl`, renderResultsJsonl(run));
    for (const problem of summary.problems) {
      deps.err(`input: ${problem}`);
    }
    for (const t of summary.tiers) {
      deps.out(
        `${t.tier}: ${t.verdict.toUpperCase()}  ${String(t.passed)}/${String(t.cases)} cases clean, ${String(t.missing.length)} missing`,
      );
      for (const b of t.bars.filter((x) => x.pass !== true)) {
        const rate = b.rate === null ? 'no data' : `${(b.rate * 100).toFixed(1)} %`;
        deps.out(
          `  ${b.id}: ${rate} (${String(b.ok)}/${String(b.n)}, need ${String(b.threshold * 100)} %)`,
        );
      }
    }
    deps.out(`verdict: ${summary.verdict.toUpperCase()}; report in ${dir}/report.md`);
    if (summary.verdict === 'pass') {
      return 0;
    }
    return summary.verdict === 'incomplete' && args.flags.has('--allow-incomplete') ? 0 : 3;
  } catch (err) {
    deps.err(`failed: ${(err as Error).message}`);
    return 1;
  }
}
