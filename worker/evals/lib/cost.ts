import type { AiProviderId } from '../../src/config/schema';
import { callCost, priceFor, type ModelPrice } from '../../src/domain/pricing';
import type { AiCall } from '../../src/ports/AiProvider';
import type { Logger } from '../../src/ports/Logger';

/**
 * Spend control of the live eval (Sprint 8.6). Real spend is priced from the
 * adapters' normalised `AiUsage` with the Worker's own price table
 * (`domain/pricing.ts`); estimates are deliberately rough and only guard the
 * `--max-usd` budget.
 */

/** A rough token count for budget estimates (about 3 characters per token). */
export function estimateTokens(text: string): number {
  return Math.ceil(text.length / 3);
}

/** Share of `max_tokens` a typical answer uses (thinking included), for the pre-flight projection. */
export const TYPICAL_OUTPUT_SHARE = 0.4;

/**
 * Worst case of one reading call: the prompt twice uncached and
 * `max_tokens` plus the 1.5x truncation retry (03 §9.3), doubled when an
 * Opus server-side refusal fallback may bill a second model.
 */
export function worstCaseUsd(
  inputTokens: number,
  maxTokens: number,
  price: ModelPrice,
  refusalFallback: boolean,
): number {
  const usd = (2 * inputTokens * price.input + 2.5 * maxTokens * price.output) / 1_000_000;
  return refusalFallback ? usd * 2 : usd;
}

/** A typical reading call: the system prefix read from the cache, the user part uncached. */
export function typicalUsd(
  systemTokens: number,
  userTokens: number,
  maxTokens: number,
  price: ModelPrice,
): number {
  return (
    (systemTokens * price.cacheRead +
      userTokens * price.input +
      TYPICAL_OUTPUT_SHARE * maxTokens * price.output) /
    1_000_000
  );
}

/** Price of a `provider/model`; an unknown model is priced at the table maximum. */
export function evalPrice(provider: AiProviderId, model: string): ModelPrice {
  return priceFor(provider, model).price;
}

/** Real cost of a result's calls in USD (logs `pricing_unknown` like the Worker). */
export function callsUsd(calls: readonly AiCall[], logger: Logger): number {
  const micro = calls.reduce(
    (sum, call) => sum + callCost(call.provider, call.model, call.usage, logger).microUsd,
    0,
  );
  return micro / 1_000_000;
}

/**
 * The `--max-usd` guard. `reserve` books a call's worst case before it
 * starts and refuses when spent + booked would pass the budget; `settle`
 * replaces the booking with the real cost. Works with concurrent calls.
 */
export class SpendGuard {
  private spentUsd = 0;
  private reservedUsd = 0;
  private readonly waiters: (() => void)[] = [];

  constructor(readonly maxUsd: number) {}

  get spent(): number {
    return this.spentUsd;
  }

  reserve(usd: number): boolean {
    if (this.spentUsd + this.reservedUsd + usd > this.maxUsd) {
      return false;
    }
    this.reservedUsd += usd;
    return true;
  }

  settle(reservedUsd: number, actualUsd: number): void {
    this.reservedUsd = Math.max(0, this.reservedUsd - reservedUsd);
    this.spentUsd += actualUsd;
    for (const wake of this.waiters.splice(0)) {
      wake();
    }
  }

  /**
   * `reserve`, but while other calls hold bookings it waits for one of them
   * to settle and tries again (their real cost is usually far below the
   * worst case). `false` = over budget with nothing in flight.
   */
  async acquire(usd: number): Promise<boolean> {
    while (!this.reserve(usd)) {
      if (this.reservedUsd === 0) {
        return false;
      }
      await new Promise<void>((resolve) => {
        this.waiters.push(resolve);
      });
    }
    return true;
  }
}

export function usd(value: number): string {
  return `$${value.toFixed(value < 1 ? 4 : 2)}`;
}
