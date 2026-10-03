import type { AiProviderId } from '../config/schema';
import type { Logger } from '../ports/Logger';
import type { AiCall, AiUsage } from '../ports/AiProvider';

/**
 * AI price table per `provider/model` (03 §9.6, RC32, RC97) and the cost of
 * one model call from the normalised `AiUsage`.
 *
 * Prices are USD per million tokens (standard tier, global routing, no batch),
 * checked against the vendors' pricing pages on {@link PRICES_CHECKED_ON}
 * (Phase 8 Sprint 8.1): platform.claude.com/docs/en/about-claude/pricing and
 * developers.openai.com/api/docs/pricing plus the OpenAI model pages.
 *
 * - `cacheWrite` is the 5-minute cache write for Anthropic (1.25x input; the
 *   Worker never asks for the 1-hour TTL) and the GPT-5.6+ cache write for
 *   OpenAI (1.25x input; older OpenAI models report no cache writes).
 * - `cacheRead` is 0.1x input except Claude Opus 5.5 (0.05x) and GPT-6.1 Sol
 *   (0.05x).
 * - The table holds every model the config may route to (the RC64 defaults,
 *   the Sprint 8.1 candidates, and `claude-opus-4-8`, which serves Opus 5
 *   refusals under `fallbacks: "default"`). A model outside it is priced at
 *   the component-wise maximum of the table and logs `pricing_unknown`.
 *
 * - A call served at the vendor's fast tier (`AiCall.fast`, OpenAI Fast mode,
 *   `ai.serviceTier`) costs {@link FAST_PRICE_FACTOR}x every component
 *   (gpt-6.1-sol Fast: 4 / 20, cached 0.20, checked 2026-10-03).
 *
 * `AiUsage` is normalised by the adapters: `inputTokens` are the uncached
 * input tokens only (Anthropic `input_tokens`; OpenAI `input_tokens` minus
 * `cached_tokens` and `cache_write_tokens`), and `outputTokens` include
 * thinking / reasoning tokens.
 */
export const PRICES_CHECKED_ON = '2026-09-30';

/** Fast mode (formerly Priority processing) multiplies every token price. */
export const FAST_PRICE_FACTOR = 2;

export interface ModelPrice {
  /** USD per million uncached input tokens. */
  readonly input: number;
  /** USD per million output tokens (thinking / reasoning included). */
  readonly output: number;
  /** USD per million cache-read input tokens. */
  readonly cacheRead: number;
  /** USD per million cache-write input tokens. */
  readonly cacheWrite: number;
}

export const PRICE_TABLE: Readonly<Record<string, ModelPrice>> = {
  'anthropic/claude-opus-5': { input: 5, output: 25, cacheRead: 0.5, cacheWrite: 6.25 },
  'anthropic/claude-opus-5-5': { input: 4, output: 20, cacheRead: 0.2, cacheWrite: 5 },
  'anthropic/claude-opus-4-8': { input: 5, output: 25, cacheRead: 0.5, cacheWrite: 6.25 },
  'anthropic/claude-sonnet-5': { input: 2, output: 10, cacheRead: 0.2, cacheWrite: 2.5 },
  'anthropic/claude-sonnet-5-5': { input: 2, output: 10, cacheRead: 0.2, cacheWrite: 2.5 },
  'anthropic/claude-haiku-4-5': { input: 1, output: 5, cacheRead: 0.1, cacheWrite: 1.25 },
  'openai/gpt-6.1-sol': { input: 2, output: 10, cacheRead: 0.1, cacheWrite: 2.5 },
  'openai/gpt-6-luna': { input: 0.1, output: 0.5, cacheRead: 0.01, cacheWrite: 0.125 },
};

/** The `readings.model` / Analytics Engine value: `provider/model` (RC97). */
export function modelKey(provider: AiProviderId, model: string): string {
  return `${provider}/${model}`;
}

/** The most expensive known price per component, over every provider. */
export function maxKnownPrice(
  table: Readonly<Record<string, ModelPrice>> = PRICE_TABLE,
): ModelPrice {
  const prices = Object.values(table);
  const max = (pick: (price: ModelPrice) => number) => Math.max(0, ...prices.map(pick));
  return {
    input: max((p) => p.input),
    output: max((p) => p.output),
    cacheRead: max((p) => p.cacheRead),
    cacheWrite: max((p) => p.cacheWrite),
  };
}

export interface PriceLookup {
  readonly price: ModelPrice;
  readonly known: boolean;
}

export function priceFor(
  provider: AiProviderId,
  model: string,
  table: Readonly<Record<string, ModelPrice>> = PRICE_TABLE,
): PriceLookup {
  const price = table[modelKey(provider, model)];
  return price === undefined
    ? { price: maxKnownPrice(table), known: false }
    : { price, known: true };
}

/** USD per million tokens → integer nano-USD per token (exact for prices with ≤ 3 decimals). */
function nanoPerToken(usdPerMTok: number): number {
  return Math.round(usdPerMTok * 1000);
}

function tokens(value: number): number {
  return Number.isFinite(value) && value > 0 ? Math.floor(value) : 0;
}

/**
 * Cost of one call in integer micro-USD (`readings.cost_micro_usd`,
 * `ai_spend_daily`), rounded up so spend is never under-counted. Negative or
 * non-finite token counts count as 0.
 */
export function costMicroUsd(usage: AiUsage, price: ModelPrice): number {
  const nano =
    tokens(usage.inputTokens) * nanoPerToken(price.input) +
    tokens(usage.outputTokens) * nanoPerToken(price.output) +
    tokens(usage.cacheReadTokens) * nanoPerToken(price.cacheRead) +
    tokens(usage.cacheWriteTokens) * nanoPerToken(price.cacheWrite);
  return Math.ceil(nano / 1000);
}

export interface CallCost {
  /** `provider/model`. */
  readonly model: string;
  readonly microUsd: number;
  readonly known: boolean;
}

/**
 * Cost of a call on `provider/model`. An entry missing from the table logs
 * `pricing_unknown` (warn) and uses {@link maxKnownPrice} (03 §9.6).
 */
export function callCost(
  provider: AiProviderId,
  model: string,
  usage: AiUsage,
  logger: Logger,
  table: Readonly<Record<string, ModelPrice>> = PRICE_TABLE,
): CallCost {
  const { price, known } = priceFor(provider, model, table);
  const key = modelKey(provider, model);
  if (!known) {
    logger.log('warn', 'pricing_unknown', { model: key });
  }
  return { model: key, microUsd: costMicroUsd(usage, price), known };
}

/** A price at the fast tier ({@link FAST_PRICE_FACTOR}x each component). */
export function fastPrice(price: ModelPrice): ModelPrice {
  return {
    input: price.input * FAST_PRICE_FACTOR,
    output: price.output * FAST_PRICE_FACTOR,
    cacheRead: price.cacheRead * FAST_PRICE_FACTOR,
    cacheWrite: price.cacheWrite * FAST_PRICE_FACTOR,
  };
}

/** Cost of one billed `AiCall` in micro-USD: {@link callCost}, times 2 at the fast tier. */
export function aiCallCost(
  call: AiCall,
  logger: Logger,
  table: Readonly<Record<string, ModelPrice>> = PRICE_TABLE,
): number {
  const { microUsd } = callCost(call.provider, call.model, call.usage, logger, table);
  return call.fast === true ? microUsd * FAST_PRICE_FACTOR : microUsd;
}
