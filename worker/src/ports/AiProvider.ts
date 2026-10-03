import type { AI_EFFORTS, AI_SERVICE_TIERS, AiProviderId } from '../config/schema';
import type { ReadingPromptInput } from '../prompts/build';
import type { ReadingOutput } from '../prompts/templates';

/**
 * The LLM port (03 §9.3, RC38, RC97). One adapter per vendor
 * (`AnthropicProvider`, `OpenAiProvider`) plus `FakeAiProvider`; all of them
 * map into the same `AiResult` union and the normalised `AiUsage`, which the
 * shared contract suite (`test/contracts/aiProvider.contract.ts`) enforces.
 * `services/AiRouter` picks the adapter and model per tier.
 */

/**
 * Normalised token usage of one upstream call (pricing contract,
 * `domain/pricing.ts`): `inputTokens` are the uncached input tokens only,
 * `outputTokens` include thinking / reasoning tokens.
 */
export interface AiUsage {
  readonly inputTokens: number;
  readonly outputTokens: number;
  readonly cacheReadTokens: number;
  readonly cacheWriteTokens: number;
}

export const ZERO_USAGE: AiUsage = {
  inputTokens: 0,
  outputTokens: 0,
  cacheReadTokens: 0,
  cacheWriteTokens: 0,
};

export type AiEffort = (typeof AI_EFFORTS)[number];
export type AiServiceTier = (typeof AI_SERVICE_TIERS)[number];

/** One billed upstream call: the provider, the model that served it and its usage. */
export interface AiCall {
  readonly provider: AiProviderId;
  /** The serving model (may differ from the requested one after a server-side fallback). */
  readonly model: string;
  readonly usage: AiUsage;
  /** True when the vendor served the call at its fast (priority) tier, priced 2x (`domain/pricing.ts`). */
  readonly fast?: boolean;
}

/** One reading generation, with the time budget of the whole handler (RC52). */
export interface AiGenerateRequest {
  readonly model: string;
  readonly prompt: ReadingPromptInput;
  /** `ai.maxTokensBySpread[spread]`; the truncation retry uses 1.5x. */
  readonly maxTokens: number;
  readonly effort: AiEffort;
  /** `ai.serviceTier` (a hint: the OpenAI adapter maps `fast` to Fast mode; others ignore it). Absent = standard. */
  readonly serviceTier?: AiServiceTier;
  /** `ai.refusalFallbacks` (Anthropic Opus only; other adapters ignore it). */
  readonly refusalFallbacks: boolean;
  /** `ai.timeoutMs`: the cap of one upstream call. */
  readonly timeoutMs: number;
  /** `ai.maxRetries`: retries on 429 / overloaded / 5xx / network, within the first 15 s. */
  readonly maxRetries: number;
  /** Epoch ms the reading handler started. */
  readonly startedAt: number;
  /** Epoch ms by which the handler must finish (`startedAt + ai.deadlineMs`). */
  readonly deadlineAt: number;
}

interface AiResultBase {
  /** Every upstream call that reported usage (retries included), for pricing. */
  readonly calls: readonly AiCall[];
}

/** An answered call; `output` passed `parseReadingOutput` (it may still be a declined classification). */
export interface AiOk extends AiResultBase {
  readonly kind: 'ok';
  readonly output: ReadingOutput;
  /** `provider/model` of the serving model (`readings.model`). */
  readonly model: string;
}

/** The vendor refused; `category` is the vendor's own label when it gives one. */
export interface AiRefused extends AiResultBase {
  readonly kind: 'refused';
  readonly category: string | null;
  readonly model: string;
}

/** Cut by the output-token limit (after the one 1.5x retry). */
export interface AiTruncated extends AiResultBase {
  readonly kind: 'truncated';
  readonly model: string;
}

/** A normal end whose text is not valid JSON or fails the zod parse. */
export interface AiInvalidOutput extends AiResultBase {
  readonly kind: 'invalid_output';
  readonly model: string;
  readonly issues: readonly string[];
}

/** No usable answer from the vendor (after the retry policy). */
export interface AiOutage extends AiResultBase {
  readonly kind: 'timeout' | 'rate_limited' | 'upstream';
}

export type AiResult = AiOk | AiRefused | AiTruncated | AiInvalidOutput | AiOutage;
export type AiResultKind = AiResult['kind'];

/** Kinds after which `AiRouter` may try `ai.outageFallback.*` (never after a safety decision). */
export const AI_OUTAGE_KINDS: readonly AiResultKind[] = ['timeout', 'rate_limited', 'upstream'];

export function isAiOutage(result: AiResult): result is AiOutage {
  return AI_OUTAGE_KINDS.includes(result.kind);
}

/** Result of the optional moderation capability (03 §9.4, RC97). */
export type AiModerationResult =
  | { readonly kind: 'ok'; readonly flagged: boolean; readonly categories: readonly string[] }
  | { readonly kind: 'error' };

export interface AiProvider {
  readonly id: AiProviderId;
  generate(request: AiGenerateRequest): Promise<AiResult>;
  /** Present only on adapters with a moderation endpoint (`ai.moderation.provider`). */
  readonly moderate?: (text: string, timeoutMs: number) => Promise<AiModerationResult>;
}

/** The adapters `makeProdDeps` built: one per provider whose key is present (RC97). */
export type AiProviders = Readonly<Partial<Record<AiProviderId, AiProvider>>>;

/** Summed usage of a result's calls. */
export function totalUsage(calls: readonly AiCall[]): AiUsage {
  return calls.reduce<AiUsage>(
    (sum, call) => ({
      inputTokens: sum.inputTokens + call.usage.inputTokens,
      outputTokens: sum.outputTokens + call.usage.outputTokens,
      cacheReadTokens: sum.cacheReadTokens + call.usage.cacheReadTokens,
      cacheWriteTokens: sum.cacheWriteTokens + call.usage.cacheWriteTokens,
    }),
    ZERO_USAGE,
  );
}
