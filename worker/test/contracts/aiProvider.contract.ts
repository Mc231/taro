import { describe, expect, it } from 'vitest';
import type { AiRuntime } from '../../src/adapters/ai/callPolicy';
import type { AiGenerateRequest, AiProvider, AiUsage } from '../../src/ports/AiProvider';
import { buildReadingPrompt, type ReadingPromptInput } from '../../src/prompts/build';
import { CapturingLogger } from '../fakes/CapturingLogger';
import { fakeReading } from '../fakes/FakeAiProvider';
import { FixedClock } from '../fakes/FixedClock';

/**
 * Shared `AiProvider` contract (03 §9.3, §15.2, RC97): every adapter and
 * `FakeAiProvider` must map the same recorded scenarios (`test/fixtures/ai/`)
 * into the same `AiResult` and normalised `AiUsage`. Each subject turns a
 * scenario (a list of steps, one per upstream attempt) into a provider.
 */
export const AI_SCENARIO_STEPS = [
  'ok',
  'cache_read',
  'refusal',
  'truncation',
  'invalid_json',
  'rate_limited',
  'overloaded',
  'server_error',
  'timeout',
] as const;
export type AiScenarioStep = (typeof AI_SCENARIO_STEPS)[number];

/** Normalised usage every subject must report per fixture (`input` = uncached only). */
export const CONTRACT_USAGE = {
  ok: { inputTokens: 812, outputTokens: 640, cacheReadTokens: 0, cacheWriteTokens: 2871 },
  cache_read: { inputTokens: 812, outputTokens: 655, cacheReadTokens: 2871, cacheWriteTokens: 0 },
  refusal: { inputTokens: 812, outputTokens: 12, cacheReadTokens: 2871, cacheWriteTokens: 0 },
  truncation: { inputTokens: 812, outputTokens: 1200, cacheReadTokens: 2871, cacheWriteTokens: 0 },
  invalid_json: { inputTokens: 812, outputTokens: 9, cacheReadTokens: 2871, cacheWriteTokens: 0 },
} as const satisfies Partial<Record<AiScenarioStep, AiUsage>>;

export const CONTRACT_MAX_TOKENS = 800;
export const CONTRACT_TIMEOUT_MS = 200;

/** The fixtures' reading answers this prompt (single spread, The Tower upright). */
export function contractPrompt(): ReadingPromptInput {
  const built = buildReadingPrompt({
    spreadId: 'single',
    locale: 'en',
    cards: [{ positionId: 'focus', cardId: 'major_16', reversed: false }],
    question: 'What should I focus on this week?',
  });
  if (!built.ok) {
    throw new Error(built.error);
  }
  return built.input;
}

export interface AiTestRuntime extends AiRuntime {
  readonly clock: FixedClock;
  readonly logger: CapturingLogger;
  readonly slept: number[];
}

/** FixedClock runtime whose backoff sleep advances the clock instead of waiting. */
export function testRuntime(clock = new FixedClock()): AiTestRuntime {
  const slept: number[] = [];
  return {
    clock,
    crypto: { randomBytes: (length: number) => new Uint8Array(length).fill(0x80) },
    sleep: (ms: number) => {
      slept.push(ms);
      clock.advance({ ms });
      return Promise.resolve();
    },
    logger: new CapturingLogger(),
    slept,
  };
}

export function contractRequest(
  runtime: AiRuntime,
  model: string,
  overrides: Partial<AiGenerateRequest> = {},
): AiGenerateRequest {
  const now = runtime.clock.now().getTime();
  return {
    model,
    prompt: contractPrompt(),
    maxTokens: CONTRACT_MAX_TOKENS,
    effort: 'low',
    refusalFallbacks: true,
    timeoutMs: CONTRACT_TIMEOUT_MS,
    maxRetries: 1,
    startedAt: now,
    deadlineAt: now + 55_000,
    ...overrides,
  };
}

export interface AiContractSubject {
  readonly provider: AiProvider;
  /** The requested model. */
  readonly model: string;
  /** The model the fixtures report as serving. */
  readonly servedModel: string;
  /** Upstream attempts made so far. */
  attempts(): number;
  /** The token limit sent on each attempt. */
  sentMaxTokens(): number[];
}

export interface AiContractOptions {
  readonly name: string;
  make(steps: readonly AiScenarioStep[], runtime: AiTestRuntime): AiContractSubject;
}

export function aiProviderContract(options: AiContractOptions): void {
  describe(`AiProvider contract: ${options.name}`, () => {
    async function run(
      steps: readonly AiScenarioStep[],
      overrides: Partial<AiGenerateRequest> = {},
    ) {
      const runtime = testRuntime();
      const subject = options.make(steps, runtime);
      const request = contractRequest(runtime, subject.model, overrides);
      const result = await subject.provider.generate(request);
      return { result, subject, runtime, request };
    }

    it('ok: parses the reading and reports normalised usage at the serving model', async () => {
      const { result, subject, request } = await run(['ok']);
      const served = `${subject.provider.id}/${subject.servedModel}`;
      expect(result).toEqual({
        kind: 'ok',
        output: fakeReading(request.prompt.expected),
        model: served,
        calls: [
          { provider: subject.provider.id, model: subject.servedModel, usage: CONTRACT_USAGE.ok },
        ],
      });
      expect(subject.attempts()).toBe(1);
    });

    it('usage with cache reads: cached tokens are not counted as input', async () => {
      const { result } = await run(['cache_read']);
      expect(result.kind).toBe('ok');
      expect(result.calls.map((c) => c.usage)).toEqual([CONTRACT_USAGE.cache_read]);
    });

    it('refusal → refused, no retry, usage kept for the budget', async () => {
      const { result, subject } = await run(['refusal']);
      expect(result.kind).toBe('refused');
      expect(result.calls.map((c) => c.usage)).toEqual([CONTRACT_USAGE.refusal]);
      expect(subject.attempts()).toBe(1);
    });

    it('truncation → one retry at 1.5x max tokens, then truncated', async () => {
      const { result, subject } = await run(['truncation', 'truncation']);
      expect(result.kind).toBe('truncated');
      expect(subject.sentMaxTokens()).toEqual([CONTRACT_MAX_TOKENS, CONTRACT_MAX_TOKENS * 1.5]);
      expect(result.calls).toHaveLength(2);
    });

    it('truncation then ok → ok with both calls priced', async () => {
      const { result } = await run(['truncation', 'ok']);
      expect(result.kind).toBe('ok');
      expect(result.calls.map((c) => c.usage)).toEqual([
        CONTRACT_USAGE.truncation,
        CONTRACT_USAGE.ok,
      ]);
    });

    it('truncation with under 15 s left → truncated without a retry', async () => {
      const { result, subject, runtime } = await run(['truncation'], {
        deadlineAt: new FixedClock().now().getTime() + 14_000,
      });
      expect(result.kind).toBe('truncated');
      expect(subject.attempts()).toBe(1);
      expect(runtime.slept).toEqual([]);
    });

    it('invalid JSON → invalid_output, no retry', async () => {
      const { result, subject } = await run(['invalid_json']);
      expect(result.kind).toBe('invalid_output');
      expect(result.kind === 'invalid_output' && result.issues.length).toBeGreaterThan(0);
      expect(subject.attempts()).toBe(1);
    });

    it('429 twice → one jittered retry, then rate_limited', async () => {
      const { result, subject, runtime } = await run(['rate_limited', 'rate_limited']);
      expect(result).toEqual({ kind: 'rate_limited', calls: [] });
      expect(subject.attempts()).toBe(2);
      expect(runtime.slept).toHaveLength(1);
      expect(runtime.slept[0]).toBeGreaterThanOrEqual(500);
      expect(runtime.slept[0]).toBeLessThan(1500);
    });

    it('429 then ok → ok', async () => {
      const { result, subject } = await run(['rate_limited', 'ok']);
      expect(result.kind).toBe('ok');
      expect(subject.attempts()).toBe(2);
    });

    it('overloaded twice → upstream after one retry', async () => {
      const { result, subject } = await run(['overloaded', 'overloaded']);
      expect(result).toEqual({ kind: 'upstream', calls: [] });
      expect(subject.attempts()).toBe(2);
    });

    it('5xx twice → upstream after one retry', async () => {
      const { result, subject } = await run(['server_error', 'server_error']);
      expect(result).toEqual({ kind: 'upstream', calls: [] });
      expect(subject.attempts()).toBe(2);
    });

    it('no retry once 15 s have elapsed since the handler started', async () => {
      const start = new FixedClock().now().getTime();
      const { result, subject } = await run(['rate_limited', 'ok'], { startedAt: start - 15_000 });
      expect(result.kind).toBe('rate_limited');
      expect(subject.attempts()).toBe(1);
    });

    it('maxRetries 0 → no retry', async () => {
      const { result, subject } = await run(['server_error', 'ok'], { maxRetries: 0 });
      expect(result.kind).toBe('upstream');
      expect(subject.attempts()).toBe(1);
    });

    it('timeout → timeout, never retried', async () => {
      const { result, subject } = await run(['timeout', 'ok']);
      expect(result).toEqual({ kind: 'timeout', calls: [] });
      expect(subject.attempts()).toBe(1);
    });

    it('deadline already passed → timeout without an upstream call', async () => {
      const start = new FixedClock().now().getTime();
      const { result, subject } = await run(['ok'], { deadlineAt: start });
      expect(result).toEqual({ kind: 'timeout', calls: [] });
      expect(subject.attempts()).toBe(0);
    });
  });
}
