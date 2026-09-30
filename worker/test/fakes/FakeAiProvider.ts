import {
  runWithPolicy,
  type AiAttemptOutcome,
  type AiAttemptRequest,
  type AiRuntime,
} from '../../src/adapters/ai/callPolicy';
import type { AiProviderId } from '../../src/config/schema';
import type {
  AiGenerateRequest,
  AiModerationResult,
  AiProvider,
  AiResult,
  AiUsage,
} from '../../src/ports/AiProvider';
import type { ExpectedReading, ReadingOutput } from '../../src/prompts/templates';

/**
 * Scriptable `AiProvider` (03 §15.3): route tests, the contract suite and
 * `wrangler dev` with `AI_PROVIDER=fake`. Each upstream attempt takes the next
 * scripted step (an outcome, or a function of the request); with nothing
 * queued it answers a valid reading that echoes the drawn cards. Attempts go
 * through the same `runWithPolicy` as the real adapters, so retries,
 * truncation and deadlines behave identically.
 */
export type FakeAiStep = AiAttemptOutcome | ((request: AiAttemptRequest) => AiAttemptOutcome);

export const FAKE_USAGE: AiUsage = {
  inputTokens: 800,
  outputTokens: 600,
  cacheReadTokens: 2900,
  cacheWriteTokens: 0,
};

/** A valid answered reading for `expected` (deterministic). */
export function fakeReading(expected: ExpectedReading): ReadingOutput {
  return {
    classification: 'none',
    title: 'A quiet turning point',
    overview: 'The cards point to a steady, reflective moment.',
    cards: expected.cards.map((card) => ({
      positionId: card.positionId,
      cardId: card.cardId,
      reversed: card.reversed,
      interpretation: 'This card invites you to notice what is already shifting.',
    })),
    synthesis: 'Together they suggest one small, concrete step today.',
    reflectionPrompts: Array.from(
      { length: expected.reflectionPrompts },
      (_, i) => `What would change if you tried step ${String(i + 1)}?`,
    ),
  };
}

const IMMEDIATE_RUNTIME: Omit<AiRuntime, 'clock'> = {
  crypto: { randomBytes: (length: number) => new Uint8Array(length) },
  sleep: () => Promise.resolve(),
  logger: { log: () => undefined },
};

export class FakeAiProvider implements AiProvider {
  readonly requests: AiAttemptRequest[] = [];
  readonly generateRequests: AiGenerateRequest[] = [];
  readonly moderated: string[] = [];
  private readonly steps: FakeAiStep[] = [];
  private moderationResult: AiModerationResult = { kind: 'ok', flagged: false, categories: [] };
  moderate?: (text: string, timeoutMs: number) => Promise<AiModerationResult>;

  constructor(
    readonly id: AiProviderId = 'anthropic',
    private readonly runtime: Partial<AiRuntime> & Pick<AiRuntime, 'clock'> = {
      clock: { now: () => new Date() },
    },
  ) {}

  /** Queues outcomes for the next attempts (consumed in order). */
  script(...steps: FakeAiStep[]): this {
    this.steps.push(...steps);
    return this;
  }

  /** Enables `moderate` and sets what it answers. */
  moderation(result: AiModerationResult): this {
    this.moderationResult = result;
    this.moderate = (text: string) => {
      this.moderated.push(text);
      return Promise.resolve(this.moderationResult);
    };
    return this;
  }

  get pending(): number {
    return this.steps.length;
  }

  generate(request: AiGenerateRequest): Promise<AiResult> {
    this.generateRequests.push(request);
    return runWithPolicy(this.id, request, { ...IMMEDIATE_RUNTIME, ...this.runtime }, (attempt) =>
      Promise.resolve(this.next(attempt)),
    );
  }

  private next(request: AiAttemptRequest): AiAttemptOutcome {
    this.requests.push(request);
    const step = this.steps.shift();
    if (step === undefined) {
      return {
        kind: 'ok',
        output: fakeReading(request.prompt.expected),
        model: request.model,
        usage: FAKE_USAGE,
      };
    }
    return typeof step === 'function' ? step(request) : step;
  }
}
