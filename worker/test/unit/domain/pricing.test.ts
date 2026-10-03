import { describe, expect, it } from 'vitest';
import { DEFAULT_SERVER_CONFIG } from '../../../src/config/defaults';
import {
  aiCallCost,
  callCost,
  FAST_PRICE_FACTOR,
  fastPrice,
  costMicroUsd,
  maxKnownPrice,
  modelKey,
  PRICE_TABLE,
  priceFor,
  type ModelPrice,
} from '../../../src/domain/pricing';
import type { AiUsage } from '../../../src/ports/AiProvider';
import { CapturingLogger } from '../../fakes/CapturingLogger';

function known(provider: 'anthropic' | 'openai', model: string): ModelPrice {
  const lookup = priceFor(provider, model);
  expect(lookup.known).toBe(true);
  return lookup.price;
}

function usage(overrides: Partial<AiUsage> = {}): AiUsage {
  return { inputTokens: 0, outputTokens: 0, cacheReadTokens: 0, cacheWriteTokens: 0, ...overrides };
}

describe('PRICE_TABLE (03 §9.6, Sprint 8.1 2026-09-30)', () => {
  it('prices every default tier model (RC64) under its default provider (RC97)', () => {
    const tiers = [
      ['ai.provider.paid', 'ai.model.paid'],
      ['ai.provider.free', 'ai.model.free'],
      ['ai.provider.freeFallback', 'ai.model.freeFallback'],
    ] as const;
    for (const [provider, model] of tiers) {
      expect(priceFor(DEFAULT_SERVER_CONFIG[provider], DEFAULT_SERVER_CONFIG[model]).known).toBe(
        true,
      );
    }
  });

  it('holds the verified Anthropic and OpenAI list prices', () => {
    expect(PRICE_TABLE['anthropic/claude-opus-5']).toEqual({
      input: 5,
      output: 25,
      cacheRead: 0.5,
      cacheWrite: 6.25,
    });
    expect(PRICE_TABLE['anthropic/claude-sonnet-5']).toMatchObject({ input: 2, output: 10 });
    expect(PRICE_TABLE['anthropic/claude-haiku-4-5']).toMatchObject({ input: 1, output: 5 });
    expect(PRICE_TABLE['openai/gpt-6.1-sol']).toMatchObject({ cacheRead: 0.1 });
    expect(PRICE_TABLE['openai/gpt-6-luna']).toMatchObject({ input: 0.1, output: 0.5 });
  });

  it('keys are provider/model and every price is non-negative with cheaper cache reads', () => {
    for (const [key, price] of Object.entries(PRICE_TABLE)) {
      expect(key).toMatch(/^(anthropic\/claude-|openai\/gpt-)/);
      expect(price.cacheRead).toBeLessThan(price.input);
      expect(price.cacheWrite).toBeGreaterThanOrEqual(price.input);
      expect(price.output).toBeGreaterThan(price.input);
    }
  });
});

describe('costMicroUsd', () => {
  const opus = known('anthropic', 'claude-opus-5');

  it('sums input, output, cache read and cache write at their own rates', () => {
    // 400 × 5 + 800 × 25 + 3000 × 0.5 + 0 = 2000 + 20000 + 1500 micro-USD
    expect(
      costMicroUsd(usage({ inputTokens: 400, outputTokens: 800, cacheReadTokens: 3000 }), opus),
    ).toBe(23500);
    expect(costMicroUsd(usage({ cacheWriteTokens: 1000 }), opus)).toBe(6250);
  });

  it('rounds fractional micro-USD up and never floats off', () => {
    const luna = known('openai', 'gpt-6-luna');
    // 7 × 0.01 = 0.07 micro-USD → 1
    expect(costMicroUsd(usage({ cacheReadTokens: 7 }), luna)).toBe(1);
    // 10 × 0.1 = 1 exactly: integer nano-USD arithmetic, no 1.0000000000000002 → 2
    expect(costMicroUsd(usage({ inputTokens: 10 }), luna)).toBe(1);
    expect(costMicroUsd(usage({ inputTokens: 1_000_000 }), luna)).toBe(100_000);
    expect(costMicroUsd(usage(), luna)).toBe(0);
  });

  it('treats negative, fractional and non-finite token counts defensively', () => {
    expect(
      costMicroUsd(
        usage({
          inputTokens: -5,
          outputTokens: Number.NaN,
          cacheReadTokens: Infinity,
          cacheWriteTokens: 1.9,
        }),
        opus,
      ),
    ).toBe(7);
  });
});

describe('priceFor / maxKnownPrice / callCost', () => {
  it('returns the table entry for a known model', () => {
    expect(priceFor('openai', 'gpt-6.1-sol')).toEqual({
      price: PRICE_TABLE['openai/gpt-6.1-sol'],
      known: true,
    });
    expect(modelKey('anthropic', 'claude-sonnet-5')).toBe('anthropic/claude-sonnet-5');
  });

  it('uses the most expensive known price of any provider for an unknown model', () => {
    const max = maxKnownPrice();
    expect(max).toEqual({ input: 5, output: 25, cacheRead: 0.5, cacheWrite: 6.25 });
    expect(priceFor('openai', 'gpt-99')).toEqual({ price: max, known: false });
    // A model priced under the other provider is still unknown for this one.
    expect(priceFor('openai', 'claude-opus-5').known).toBe(false);
  });

  it('takes the maximum per component across providers', () => {
    const table = {
      'anthropic/a': { input: 3, output: 9, cacheRead: 0.1, cacheWrite: 4 },
      'openai/b': { input: 1, output: 12, cacheRead: 0.3, cacheWrite: 1 },
    };
    expect(maxKnownPrice(table)).toEqual({ input: 3, output: 12, cacheRead: 0.3, cacheWrite: 4 });
    expect(maxKnownPrice({})).toEqual({ input: 0, output: 0, cacheRead: 0, cacheWrite: 0 });
  });

  it('costs a known call without logging', () => {
    const logger = new CapturingLogger();
    const cost = callCost(
      'anthropic',
      'claude-sonnet-5',
      usage({ inputTokens: 1000, outputTokens: 1000 }),
      logger,
    );
    expect(cost).toEqual({ model: 'anthropic/claude-sonnet-5', microUsd: 12000, known: true });
    expect(logger.entries).toHaveLength(0);
  });

  it('logs pricing_unknown with provider/model only and prices at the maximum', () => {
    const logger = new CapturingLogger();
    const cost = callCost('openai', 'gpt-7-new', usage({ outputTokens: 1000 }), logger);
    expect(cost).toEqual({ model: 'openai/gpt-7-new', microUsd: 25000, known: false });
    expect(logger.find('pricing_unknown')).toEqual([
      { level: 'warn', event: 'pricing_unknown', fields: { model: 'openai/gpt-7-new' } },
    ]);
  });

  it('prices a fast-tier call at 2x every component (aiCallCost, fastPrice)', () => {
    const logger = new CapturingLogger();
    const u = usage({ inputTokens: 1000, outputTokens: 1000, cacheReadTokens: 3000 });
    const standard = callCost('openai', 'gpt-6.1-sol', u, logger).microUsd;
    expect(aiCallCost({ provider: 'openai', model: 'gpt-6.1-sol', usage: u }, logger)).toBe(
      standard,
    );
    expect(
      aiCallCost({ provider: 'openai', model: 'gpt-6.1-sol', usage: u, fast: true }, logger),
    ).toBe(standard * FAST_PRICE_FACTOR);
    expect(FAST_PRICE_FACTOR).toBe(2);
    expect(fastPrice({ input: 2, output: 10, cacheRead: 0.1, cacheWrite: 2.5 })).toEqual({
      input: 4,
      output: 20,
      cacheRead: 0.2,
      cacheWrite: 5,
    });
  });
});
