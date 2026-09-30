import type { AiRuntime } from '../../src/adapters/ai/callPolicy';
import { AnthropicProvider } from '../../src/adapters/anthropic/AnthropicProvider';
import { OpenAiProvider } from '../../src/adapters/openai/OpenAiProvider';
import type { CliDeps } from '../../src/admin/cli';
import { AI_PROVIDER_IDS, type AiProviderId } from '../../src/config/schema';
import { DEFAULT_RUNTIME_CONFIG } from '../../src/config/defaults';
import type { RuntimeConfig } from '../../src/config/schema';
import {
  isAiOutage,
  totalUsage,
  ZERO_USAGE,
  type AiProvider,
  type AiResult,
  type AiUsage,
} from '../../src/ports/AiProvider';
import { buildReadingPrompt, type ReadingPromptInput } from '../../src/prompts/build';
import {
  isPromptVersion,
  PROMPT_VERSIONS,
  type PromptVersion,
  type ReadingOutput,
} from '../../src/prompts/templates';
import { prefilter } from '../../src/safety/prefilter';
import { maxTokensFor } from '../../src/services/AiRouter';
import { cardNames, DEFAULT_BANNED, loadGraderContext } from './cli';
import {
  callsUsd,
  estimateTokens,
  evalPrice,
  SpendGuard,
  typicalUsd,
  usd,
  worstCaseUsd,
} from './cost';
import { parseCases } from './io';
import {
  JUDGE_MAX_TOKENS,
  judgeMarkdown,
  judgeReading,
  makeJudge,
  type JudgeClient,
  type JudgedCase,
} from './judge';
import { renderMarkdown, renderResultsJsonl, summarize } from './report';
import { runEval } from './runner';
import { selectSample } from './sample';
import type { EvalCase, RecordedOutput } from './types';

/**
 * Live mode of the eval runner (Phase 8 Sprint 8.6, 03 §15.4, 05 §4.3, RC60,
 * RC97):
 *
 *   npm run eval        -- --provider anthropic|openai --model <id> --max-usd <n> [--prompt v1] …
 *   npm run eval:safety -- --provider anthropic|openai --model <id> --max-usd <n> [--prompt v1] …
 *
 * It calls the real adapters (`AnthropicProvider`, `OpenAiProvider`) directly
 * with the Worker's prompt builder, L1 prefilter and default `ai.*` config,
 * then grades the answers with the same rule graders as `eval:offline`.
 * The key comes from `ANTHROPIC_API_KEY` / `OPENAI_API_KEY` in the
 * environment and is never printed. `--max-usd` is required: the run refuses
 * to start when the projected spend is over it, and stops starting calls when
 * spent + the worst case of the next call would pass it. Exit codes: 0 pass,
 * 1 input or key error, 2 usage, 3 the 05 §4.3 bar failed or the run is
 * incomplete (0 with `--allow-incomplete`), 4 over budget.
 */
export type Suite = 'quality' | 'safety';

export const SUITE_CASES: Readonly<Record<Suite, string>> = {
  quality: 'evals/cases/quality.jsonl',
  safety: 'evals/safety/prompts.jsonl',
};

export const KEY_ENV: Readonly<Record<AiProviderId, string>> = {
  anthropic: 'ANTHROPIC_API_KEY',
  openai: 'OPENAI_API_KEY',
};

export const DEFAULT_REPORTS_DIR = 'evals/reports';
export const DEFAULT_CONCURRENCY = 4;
export const MAX_CONCURRENCY = 16;
/** Budget estimate of one judge call (input tokens). */
export const JUDGE_INPUT_TOKENS = 3000;

export function usage(suite: Suite): string {
  const name = suite === 'safety' ? 'eval:safety' : 'eval';
  return `usage: ${name} --provider ${AI_PROVIDER_IDS.join('|')} --model <id> --max-usd <usd> [--prompt v1] [--cases <jsonl>…] [--sample smoke|all] [--limit <n>] [--concurrency <n>] [--env dev|staging] [--tier <label>] [--out <dir>] [--banned <yaml>] [--judge] [--judge-model <id>] [--skip-l1] [--allow-incomplete]`;
}

export interface LiveOptions {
  readonly provider: AiProviderId;
  readonly model: string;
  readonly prompt: PromptVersion;
  readonly maxUsd: number;
  readonly cases: readonly string[];
  readonly sample: 'smoke' | 'all';
  readonly limit: number | null;
  readonly concurrency: number;
  readonly env: string | null;
  readonly tier: string;
  readonly out: string;
  readonly banned: string;
  /** `null` = judge off. */
  readonly judgeModel: string | null;
  readonly skipL1: boolean;
  readonly allowIncomplete: boolean;
}

const LIST_OPTIONS = new Set(['--cases']);
const VALUE_OPTIONS = new Set([
  '--provider',
  '--model',
  '--prompt',
  '--max-usd',
  '--sample',
  '--limit',
  '--concurrency',
  '--env',
  '--tier',
  '--out',
  '--banned',
  '--judge-model',
]);
const FLAG_OPTIONS = new Set(['--judge', '--skip-l1', '--allow-incomplete']);
const MODEL_ID = /^[A-Za-z0-9][A-Za-z0-9._:-]*$/u;

function positiveInt(value: string | undefined): number | null | 'invalid' {
  if (value === undefined) {
    return null;
  }
  return /^[1-9]\d*$/u.test(value) ? Number(value) : 'invalid';
}

export function parseLiveArgs(argv: readonly string[], suite: Suite): LiveOptions | string {
  const lists = new Map<string, string[]>();
  const values = new Map<string, string>();
  const flags = new Set<string>();
  for (let i = 0; i < argv.length; i++) {
    const arg = argv[i] ?? '';
    const eq = arg.indexOf('=');
    const name = eq >= 0 ? arg.slice(0, eq) : arg;
    if (FLAG_OPTIONS.has(name) && eq < 0) {
      flags.add(name);
      continue;
    }
    if (!LIST_OPTIONS.has(name) && !VALUE_OPTIONS.has(name)) {
      return `unknown argument ${arg}`;
    }
    const value = eq >= 0 ? arg.slice(eq + 1) : argv[++i];
    if (value === undefined || value === '' || value.startsWith('--')) {
      return `${name} needs a value`;
    }
    if (LIST_OPTIONS.has(name)) {
      lists.set(name, [...(lists.get(name) ?? []), value]);
    } else if (values.has(name)) {
      return `${name} given twice`;
    } else {
      values.set(name, value);
    }
  }
  const provider = values.get('--provider');
  if (provider === undefined || !(AI_PROVIDER_IDS as readonly string[]).includes(provider)) {
    return `--provider must be one of ${AI_PROVIDER_IDS.join(', ')}`;
  }
  const model = values.get('--model');
  if (model === undefined || !MODEL_ID.test(model)) {
    return '--model is required (a model id such as claude-sonnet-5)';
  }
  const maxUsdText = values.get('--max-usd');
  if (maxUsdText === undefined) {
    return '--max-usd is required: a live eval spends real money (the owner approves the budget)';
  }
  const maxUsd = Number(maxUsdText);
  if (!/^\d+(\.\d+)?$/u.test(maxUsdText) || !(maxUsd > 0)) {
    return '--max-usd must be a positive amount in USD';
  }
  const prompt = values.get('--prompt') ?? 'v1';
  if (!isPromptVersion(prompt)) {
    return `--prompt must be one of ${PROMPT_VERSIONS.join(', ')}`;
  }
  const sample = values.get('--sample') ?? 'all';
  if (sample !== 'smoke' && sample !== 'all') {
    return '--sample must be smoke or all';
  }
  const limit = positiveInt(values.get('--limit'));
  const concurrency = positiveInt(values.get('--concurrency'));
  if (limit === 'invalid' || concurrency === 'invalid' || (concurrency ?? 1) > MAX_CONCURRENCY) {
    return `--limit and --concurrency must be positive integers (concurrency ≤ ${String(MAX_CONCURRENCY)})`;
  }
  const env = values.get('--env') ?? null;
  if (env !== null && env !== 'dev' && env !== 'staging') {
    return '--env must be dev or staging (prod keys are never used for evals)';
  }
  const judgeModel = values.get('--judge-model');
  if (judgeModel !== undefined && !MODEL_ID.test(judgeModel)) {
    return '--judge-model must be a model id';
  }
  const explicit = lists.get('--cases') ?? [];
  const cases =
    explicit.length > 0
      ? explicit
      : sample === 'smoke'
        ? [SUITE_CASES.safety, SUITE_CASES.quality]
        : [SUITE_CASES[suite]];
  return {
    provider: provider as AiProviderId,
    model,
    prompt,
    maxUsd,
    cases,
    sample,
    limit,
    concurrency: concurrency ?? DEFAULT_CONCURRENCY,
    env,
    tier: values.get('--tier') ?? 'live',
    out: (values.get('--out') ?? DEFAULT_REPORTS_DIR).replace(/\/+$/u, ''),
    banned: values.get('--banned') ?? DEFAULT_BANNED,
    judgeModel: flags.has('--judge') || judgeModel !== undefined ? (judgeModel ?? model) : null,
    skipL1: flags.has('--skip-l1'),
    allowIncomplete: flags.has('--allow-incomplete'),
  };
}

/** `<date>-<promptVersion>-<provider>-<model>` plus `-quality` / `-smoke` for those runs. */
export function reportBase(options: LiveOptions, suite: Suite, date: string): string {
  const model = options.model.replace(/[^A-Za-z0-9.-]+/gu, '-');
  const suffix = [
    suite === 'quality' ? 'quality' : null,
    options.sample === 'smoke' ? 'smoke' : null,
  ]
    .filter((s): s is string => s !== null)
    .map((s) => `-${s}`)
    .join('');
  return `${options.out}/${date}-${options.prompt}-${options.provider}-${model}${suffix}`;
}

/** Real network and adapters; tests pass `makeProvider` / `makeJudge` stubs. */
export interface LiveDeps {
  readonly now: () => Date;
  readonly fetch: typeof fetch;
  readonly runtime: AiRuntime;
  readonly config?: RuntimeConfig;
  readonly makeProvider?: (provider: AiProviderId, apiKey: string) => AiProvider;
  readonly makeJudge?: (provider: AiProviderId, apiKey: string, model: string) => JudgeClient;
}

export function realProvider(
  provider: AiProviderId,
  apiKey: string,
  runtime: AiRuntime,
  fetchImpl: typeof fetch,
): AiProvider {
  return provider === 'anthropic'
    ? new AnthropicProvider({ apiKey, runtime, fetch: fetchImpl })
    : new OpenAiProvider({ apiKey, runtime, fetch: fetchImpl });
}

/** How one case ended. */
export type CaseLayer =
  | 'l1_block'
  | 'answered'
  | 'declined'
  | 'provider_refused'
  | 'truncated'
  | 'invalid_output'
  | 'timeout'
  | 'rate_limited'
  | 'upstream'
  | 'not_run';

interface Planned {
  readonly c: EvalCase;
  readonly spreadId: string;
  /** Set for an L1 hard block (no model call). */
  readonly block: string | null;
  readonly prompt: ReadingPromptInput | null;
  readonly maxTokens: number;
}

interface CaseRun {
  readonly id: string;
  readonly spreadId: string;
  readonly layer: CaseLayer;
  readonly usd: number;
  readonly usage: AiUsage;
  readonly detail: string | null;
}

function layerOf(result: AiResult): CaseLayer {
  switch (result.kind) {
    case 'ok':
      return result.output.classification === 'none' ? 'answered' : 'declined';
    case 'refused':
      return 'provider_refused';
    default:
      return result.kind;
  }
}

function recordOf(
  result: AiResult,
  base: Pick<RecordedOutput, 'id' | 'tier' | 'provider' | 'model'>,
): RecordedOutput | null {
  if (isAiOutage(result)) {
    return null;
  }
  const model = result.model;
  if (result.kind === 'ok') {
    return { ...base, model, output: JSON.stringify(result.output), refusal: null };
  }
  if (result.kind === 'refused') {
    return { ...base, model, output: '', refusal: { category: result.category } };
  }
  // Truncated or unparseable: the graders see no reading (schema fails).
  return { ...base, model, output: '', refusal: null };
}

function addUsage(a: AiUsage, b: AiUsage): AiUsage {
  return {
    inputTokens: a.inputTokens + b.inputTokens,
    outputTokens: a.outputTokens + b.outputTokens,
    cacheReadTokens: a.cacheReadTokens + b.cacheReadTokens,
    cacheWriteTokens: a.cacheWriteTokens + b.cacheWriteTokens,
  };
}

const LAYERS: readonly CaseLayer[] = [
  'l1_block',
  'answered',
  'declined',
  'provider_refused',
  'truncated',
  'invalid_output',
  'timeout',
  'rate_limited',
  'upstream',
  'not_run',
];

function liveMarkdown(
  options: LiveOptions,
  suite: Suite,
  runs: readonly CaseRun[],
  spent: number,
  projected: number,
  aborted: boolean,
  judgeUsd: number,
): string[] {
  const counts = LAYERS.map((layer) => [layer, runs.filter((r) => r.layer === layer).length]);
  const tokens = runs.reduce((sum, r) => addUsage(sum, r.usage), ZERO_USAGE);
  const lines = [
    '## Live run',
    '',
    `Provider \`${options.provider}\`, model \`${options.model}\`, prompt \`${options.prompt}\`, suite \`${suite}\`, sample \`${options.sample}\`${options.env === null ? '' : `, env \`${options.env}\``}. L1 prefilter ${options.skipL1 ? 'skipped (model only)' : 'on (production order)'}; no L3 regeneration.`,
    '',
    `Spend: ${usd(spent)} of the ${usd(options.maxUsd)} budget (projected ${usd(projected)}; LLM judge ${usd(judgeUsd)}). Tokens: ${String(tokens.inputTokens)} input, ${String(tokens.cacheReadTokens)} cache read, ${String(tokens.cacheWriteTokens)} cache write, ${String(tokens.outputTokens)} output.${aborted ? ' **Stopped early: the next call could have passed the budget.**' : ''}`,
    '',
    '| Outcome | Cases |',
    '|---|---|',
    ...counts.filter(([, n]) => n !== 0).map(([layer, n]) => `| ${String(layer)} | ${String(n)} |`),
    '',
    '### Measured cost per reading (model calls only)',
    '',
    '| Spread | Calls | Mean | Max |',
    '|---|---|---|---|',
  ];
  const bySpread = new Map<string, number[]>();
  for (const r of runs.filter((x) => x.usd > 0)) {
    bySpread.set(r.spreadId, [...(bySpread.get(r.spreadId) ?? []), r.usd]);
  }
  for (const [spread, costs] of [...bySpread.entries()].sort(([a], [b]) => a.localeCompare(b))) {
    const mean = costs.reduce((a, b) => a + b, 0) / costs.length;
    lines.push(
      `| ${spread} | ${String(costs.length)} | ${usd(mean)} | ${usd(Math.max(...costs))} |`,
    );
  }
  lines.push('');
  const errors = runs.filter((r) => r.detail !== null);
  if (errors.length > 0) {
    lines.push('Calls without a gradable answer:', '');
    for (const r of errors) {
      lines.push(`- \`${r.id}\`: ${r.layer} (${String(r.detail).replace(/\s+/gu, ' ')})`);
    }
    lines.push('');
  }
  return lines;
}

async function loadCases(
  deps: CliDeps,
  paths: readonly string[],
): Promise<{ cases: EvalCase[]; errors: string[] }> {
  const cases: EvalCase[] = [];
  const errors: string[] = [];
  for (const path of paths) {
    const parsed = parseCases(await deps.readFile(path), path);
    cases.push(...parsed.items);
    errors.push(...parsed.errors);
    const skipped = parsed.skipped ?? [];
    if (skipped.length > 0) {
      deps.err(
        `note: ${path}: skipped ${String(skipped.length)} request-validation case(s) (rejected before any model call)`,
      );
    }
  }
  return { cases, errors };
}

export async function main(
  argv: readonly string[],
  deps: CliDeps,
  live: LiveDeps,
  suite: Suite,
): Promise<number> {
  const options = parseLiveArgs(argv, suite);
  if (typeof options === 'string') {
    deps.err(`${options}\n${usage(suite)}`);
    return 2;
  }
  const keyName = KEY_ENV[options.provider];
  const apiKey = deps.env?.[keyName] ?? '';
  if (apiKey === '') {
    deps.err(
      `${keyName} is not set; a live eval needs the ${options.provider} key of the target env`,
    );
    return 1;
  }
  try {
    const config = live.config ?? DEFAULT_RUNTIME_CONFIG;
    const loaded = await loadCases(deps, options.cases);
    const inputErrors = [...loaded.errors];
    let selected = loaded.cases;
    if (options.sample === 'smoke') {
      const sample = selectSample(selected);
      selected = [...sample.cases];
      for (const [quota, left] of Object.entries(sample.unmet)) {
        deps.err(`note: smoke quota ${quota} short by ${String(left)}`);
      }
    }
    if (options.limit !== null) {
      selected = selected.slice(0, options.limit);
    }
    const { ctx, schemaSource } = await loadGraderContext(deps, options.prompt, options.banned);
    const price = evalPrice(options.provider, options.model);
    const judgePrice =
      options.judgeModel === null ? null : evalPrice(options.provider, options.judgeModel);
    const fallback =
      config['ai.refusalFallbacks'] &&
      options.provider === 'anthropic' &&
      options.model.startsWith('claude-opus-');
    const plan: Planned[] = [];
    for (const c of selected) {
      if (c.spreadId === null || c.cards === null) {
        inputErrors.push(`${c.id}: no spreadId/cards, cannot run live`);
        continue;
      }
      const l1 = options.skipL1 ? null : prefilter(c.question, c.locale);
      const maxTokens = maxTokensFor(config, c.spreadId);
      if (l1?.kind === 'block') {
        plan.push({ c, spreadId: c.spreadId, block: l1.category, prompt: null, maxTokens });
        continue;
      }
      const built = buildReadingPrompt(
        {
          spreadId: c.spreadId,
          cards: c.cards,
          locale: c.locale,
          question: c.question,
          prefilterHints: l1?.hints ?? [],
        },
        options.prompt,
      );
      if (!built.ok) {
        inputErrors.push(`${c.id}: ${built.error}`);
        continue;
      }
      plan.push({ c, spreadId: c.spreadId, block: null, prompt: built.input, maxTokens });
    }
    const judgeTypical =
      judgePrice === null
        ? 0
        : (JUDGE_INPUT_TOKENS * judgePrice.input + 0.3 * JUDGE_MAX_TOKENS * judgePrice.output) /
          1_000_000;
    const judgeWorst =
      judgePrice === null
        ? 0
        : (2 * JUDGE_INPUT_TOKENS * judgePrice.input + JUDGE_MAX_TOKENS * judgePrice.output) /
          1_000_000;
    const projected = plan.reduce((sum, p) => {
      if (p.prompt === null) {
        return sum;
      }
      const judged = p.c.expectedOutcome === 'answered' ? judgeTypical : 0;
      return (
        sum +
        judged +
        typicalUsd(
          estimateTokens(p.prompt.system),
          estimateTokens(p.prompt.user),
          p.maxTokens,
          price,
        )
      );
    }, 0);
    const calls = plan.filter((p) => p.prompt !== null).length;
    deps.out(
      `plan: ${String(plan.length)} case(s) on ${options.provider}/${options.model} (prompt ${options.prompt}): ${String(calls)} model call(s), ${String(plan.length - calls)} L1 block(s); projected ~${usd(projected)}, budget ${usd(options.maxUsd)}`,
    );
    if (projected > options.maxUsd) {
      deps.err(
        `projected spend ${usd(projected)} is over --max-usd ${usd(options.maxUsd)}; use --limit, --sample smoke or a larger approved budget`,
      );
      return 4;
    }

    const provider = (
      live.makeProvider ?? ((p, key) => realProvider(p, key, live.runtime, live.fetch))
    )(options.provider, apiKey);
    const judge =
      options.judgeModel === null
        ? null
        : (live.makeJudge ?? ((p, key, model) => makeJudge(p, key, model, live.fetch)))(
            options.provider,
            apiKey,
            options.judgeModel,
          );
    const guard = new SpendGuard(options.maxUsd);
    const outputs: RecordedOutput[] = [];
    const runs: CaseRun[] = [];
    const judged: JudgedCase[] = [];
    let judgeUsd = 0;
    const state = { aborted: false };
    let next = 0;
    let done = 0;
    const base = { tier: options.tier, provider: options.provider, model: options.model };

    const report = (run: CaseRun): void => {
      runs.push(run);
      done++;
      deps.out(
        `[${String(done)}/${String(plan.length)}] ${run.id}: ${run.layer} ${usd(run.usd)} (spent ${usd(guard.spent)} of ${usd(options.maxUsd)})`,
      );
    };

    const runJudge = async (p: Planned, reading: ReadingOutput): Promise<void> => {
      if (judge === null || !(await guard.acquire(judgeWorst))) {
        return;
      }
      const outcome = await judgeReading(judge, p.c, reading, cardNames());
      const cost = callsUsd(outcome.calls, live.runtime.logger);
      guard.settle(judgeWorst, cost);
      judgeUsd += cost;
      judged.push({ id: p.c.id, locale: p.c.locale, outcome });
    };

    const runOne = async (p: Planned): Promise<void> => {
      if (p.prompt === null) {
        outputs.push({ ...base, id: p.c.id, output: '', refusal: { category: p.block } });
        report({
          id: p.c.id,
          spreadId: p.spreadId,
          layer: 'l1_block',
          usd: 0,
          usage: ZERO_USAGE,
          detail: null,
        });
        return;
      }
      const inputTokens = estimateTokens(p.prompt.system) + estimateTokens(p.prompt.user);
      const reserved = worstCaseUsd(inputTokens, p.maxTokens, price, fallback);
      if (!(await guard.acquire(reserved))) {
        state.aborted = true;
        return;
      }
      const startedAt = live.now().getTime();
      let result: AiResult;
      try {
        result = await provider.generate({
          model: options.model,
          prompt: p.prompt,
          maxTokens: p.maxTokens,
          effort: config['ai.effort'],
          refusalFallbacks: config['ai.refusalFallbacks'],
          timeoutMs: config['ai.timeoutMs'],
          maxRetries: config['ai.maxRetries'],
          startedAt,
          deadlineAt: startedAt + config['ai.deadlineMs'],
        });
      } catch {
        result = { kind: 'upstream', calls: [] };
      }
      const cost = callsUsd(result.calls, live.runtime.logger);
      guard.settle(reserved, cost);
      const record = recordOf(result, { ...base, id: p.c.id });
      if (record !== null) {
        outputs.push(record);
      }
      const layer = layerOf(result);
      report({
        id: p.c.id,
        spreadId: p.spreadId,
        layer,
        usd: cost,
        usage: totalUsage(result.calls),
        detail:
          result.kind === 'invalid_output'
            ? result.issues.slice(0, 3).join('; ')
            : result.kind === 'truncated' || isAiOutage(result)
              ? result.kind
              : null,
      });
      if (result.kind === 'ok' && result.output.classification === 'none') {
        await runJudge(p, result.output);
      }
    };

    const worker = async (): Promise<void> => {
      while (!state.aborted) {
        const p = plan[next++];
        if (p === undefined) {
          return;
        }
        await runOne(p);
      }
    };
    await Promise.all(
      Array.from({ length: Math.min(options.concurrency, Math.max(1, plan.length)) }, worker),
    );
    const ran = new Set(runs.map((r) => r.id));
    for (const p of plan.filter((x) => !ran.has(x.c.id))) {
      runs.push({
        id: p.c.id,
        spreadId: p.spreadId,
        layer: 'not_run',
        usd: 0,
        usage: ZERO_USAGE,
        detail: null,
      });
    }

    const run = runEval(selected, outputs, ctx);
    const summary = summarize(run, {
      promptVersion: options.prompt,
      mode: 'online',
      generatedAt: live.now().toISOString(),
      sources: [...options.cases, `live ${options.provider}/${options.model}`],
      schemaSource,
      inputErrors,
    });
    const path = reportBase(options, suite, summary.generatedAt.slice(0, 10));
    const markdown = [
      renderMarkdown(summary, run).trimEnd(),
      '',
      ...liveMarkdown(options, suite, runs, guard.spent, projected, state.aborted, judgeUsd),
      ...(options.judgeModel === null ? [] : judgeMarkdown(judged, options.judgeModel)),
    ];
    await deps.writeFile(`${path}.md`, `${markdown.join('\n').trimEnd()}\n`);
    await deps.writeFile(
      `${path}.summary.json`,
      `${JSON.stringify({ ...summary, spentUsd: guard.spent, projectedUsd: projected, aborted: state.aborted }, null, 2)}\n`,
    );
    await deps.writeFile(`${path}.results.jsonl`, renderResultsJsonl(run));
    await deps.writeFile(
      `${path}.outputs.jsonl`,
      `${outputs.map((o) => JSON.stringify(o)).join('\n')}\n`,
    );
    for (const problem of summary.problems) {
      deps.err(`input: ${problem}`);
    }
    deps.out(
      `verdict: ${summary.verdict.toUpperCase()}; spent ${usd(guard.spent)} of ${usd(options.maxUsd)}; report in ${path}.md`,
    );
    if (state.aborted) {
      deps.err('stopped early: the next call could have passed --max-usd');
      return 4;
    }
    if (summary.verdict === 'pass') {
      return 0;
    }
    return summary.verdict === 'incomplete' && options.allowIncomplete ? 0 : 3;
  } catch (err) {
    deps.err(`failed: ${(err as Error).message}`);
    return 1;
  }
}
