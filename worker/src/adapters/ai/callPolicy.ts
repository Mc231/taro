import type { AiProviderId } from '../../config/schema';
import { modelKey } from '../../domain/pricing';
import type {
  AiCall,
  AiEffort,
  AiGenerateRequest,
  AiServiceTier,
  AiResult,
  AiUsage,
} from '../../ports/AiProvider';
import type { Clock } from '../../ports/Clock';
import type { Crypto } from '../../ports/Crypto';
import type { Logger } from '../../ports/Logger';
import type { ReadingPromptInput } from '../../prompts/build';
import type { ReadingOutput } from '../../prompts/templates';

/**
 * The retry and deadline policy every AI adapter shares (03 §9.3, RC52):
 *
 * - each upstream call gets `timeout = min(ai.timeoutMs, deadline - elapsed)`;
 *   none is started once the deadline has passed;
 * - `rate_limited` / retryable `upstream` (429, overloaded, 5xx, network) are
 *   retried up to `ai.maxRetries` times, only while under 15 s have elapsed,
 *   after a jittered 500-1500 ms backoff; a timeout is not retried (the call
 *   already used its share of the deadline);
 * - `truncated` is retried once with 1.5x the token limit, only when at least
 *   15 s of the deadline remain;
 * - `refused` and `invalid_output` return at once (L3 regeneration is the
 *   reading service's decision, not the adapter's).
 *
 * Adapters implement one `AiAttempt`; `runWithPolicy` turns it into an `AiResult`.
 */
export const RETRY_WINDOW_MS = 15_000;
export const MIN_REMAINING_FOR_REGENERATION_MS = 15_000;
export const TRUNCATION_RETRY_FACTOR = 1.5;
export const BACKOFF_MIN_MS = 500;
export const BACKOFF_SPREAD_MS = 1000;

/** Runtime of the adapters: time, jitter, backoff sleep, logs (deps object, 03 §1). */
export interface AiRuntime {
  readonly clock: Clock;
  readonly crypto: Pick<Crypto, 'randomBytes'>;
  readonly sleep: (ms: number) => Promise<void>;
  readonly logger: Logger;
}

/** What one upstream call is asked to do. */
export interface AiAttemptRequest {
  readonly model: string;
  readonly prompt: ReadingPromptInput;
  readonly maxTokens: number;
  readonly effort: AiEffort;
  readonly serviceTier?: AiServiceTier;
  readonly refusalFallbacks: boolean;
  readonly timeoutMs: number;
}

interface Answered {
  /** The serving model, without the provider prefix. */
  readonly model: string;
  readonly usage: AiUsage;
  /** The call was served at the vendor's fast tier (priced 2x). */
  readonly fast?: boolean;
}

/** The outcome of one upstream call, before the policy. */
export type AiAttemptOutcome =
  | (Answered & { readonly kind: 'ok'; readonly output: ReadingOutput })
  | (Answered & { readonly kind: 'refused'; readonly category: string | null })
  | (Answered & { readonly kind: 'truncated' })
  | (Answered & { readonly kind: 'invalid_output'; readonly issues: readonly string[] })
  | { readonly kind: 'timeout' }
  | {
      readonly kind: 'rate_limited' | 'upstream';
      readonly retryable: boolean;
      /** HTTP status or a short vendor code, for the log only. */
      readonly detail?: string;
    };

export type AiAttempt = (request: AiAttemptRequest) => Promise<AiAttemptOutcome>;

/** Jittered backoff in [500, 1500) ms from two random bytes. */
export function backoffMs(crypto: Pick<Crypto, 'randomBytes'>): number {
  const [hi = 0, lo = 0] = crypto.randomBytes(2);
  return BACKOFF_MIN_MS + Math.floor((((hi << 8) | lo) / 65536) * BACKOFF_SPREAD_MS);
}

export async function runWithPolicy(
  provider: AiProviderId,
  request: AiGenerateRequest,
  runtime: AiRuntime,
  attempt: AiAttempt,
): Promise<AiResult> {
  const calls: AiCall[] = [];
  const now = () => runtime.clock.now().getTime();
  let maxTokens = request.maxTokens;
  let retries = 0;
  let truncationRetried = false;
  for (;;) {
    const remaining = request.deadlineAt - now();
    if (remaining <= 0) {
      return { kind: 'timeout', calls };
    }
    const outcome = await safeAttempt(attempt, runtime, provider, {
      model: request.model,
      prompt: request.prompt,
      maxTokens,
      effort: request.effort,
      ...(request.serviceTier === undefined ? {} : { serviceTier: request.serviceTier }),
      refusalFallbacks: request.refusalFallbacks,
      timeoutMs: Math.min(request.timeoutMs, remaining),
    });
    switch (outcome.kind) {
      case 'ok':
      case 'refused':
      case 'truncated':
      case 'invalid_output': {
        calls.push({
          provider,
          model: outcome.model,
          usage: outcome.usage,
          ...(outcome.fast === true ? { fast: true } : {}),
        });
        const model = modelKey(provider, outcome.model);
        if (outcome.kind === 'ok') {
          return { kind: 'ok', output: outcome.output, model, calls };
        }
        if (outcome.kind === 'refused') {
          return { kind: 'refused', category: outcome.category, model, calls };
        }
        if (outcome.kind === 'invalid_output') {
          return { kind: 'invalid_output', issues: outcome.issues, model, calls };
        }
        if (!truncationRetried && request.deadlineAt - now() >= MIN_REMAINING_FOR_REGENERATION_MS) {
          truncationRetried = true;
          maxTokens = Math.ceil(maxTokens * TRUNCATION_RETRY_FACTOR);
          runtime.logger.log('info', 'ai_truncated_retry', { provider, maxTokens });
          continue;
        }
        return { kind: 'truncated', model, calls };
      }
      case 'timeout':
        runtime.logger.log('warn', 'ai_call_failed', { provider, kind: 'timeout' });
        return { kind: 'timeout', calls };
      case 'rate_limited':
      case 'upstream': {
        runtime.logger.log('warn', 'ai_call_failed', {
          provider,
          kind: outcome.kind,
          detail: outcome.detail,
        });
        if (
          outcome.retryable &&
          retries < request.maxRetries &&
          now() - request.startedAt < RETRY_WINDOW_MS
        ) {
          retries++;
          await runtime.sleep(backoffMs(runtime.crypto));
          continue;
        }
        return { kind: outcome.kind, calls };
      }
    }
  }
}

/** An adapter bug must not escape the port as a throw (no throws across boundaries). */
async function safeAttempt(
  attempt: AiAttempt,
  runtime: AiRuntime,
  provider: AiProviderId,
  request: AiAttemptRequest,
): Promise<AiAttemptOutcome> {
  try {
    return await attempt(request);
  } catch (error) {
    runtime.logger.log('error', 'ai_adapter_error', {
      provider,
      error: error instanceof Error ? error.name : 'unknown',
    });
    return { kind: 'upstream', retryable: false, detail: 'adapter_error' };
  }
}

/** A real timer sleep (production runtime). */
export function timerSleep(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}
