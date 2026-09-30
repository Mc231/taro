import { describe, expect, it } from 'vitest';
import { DEFAULT_RUNTIME_CONFIG } from '../../../src/config/defaults';
import type { RuntimeConfig } from '../../../src/config/schema';
import { budgetThresholds, type BudgetTier } from '../../../src/domain/budget';
import { aiTierFor } from '../../../src/services/AiRouter';
import { ApiError } from '../../../src/http/errors';
import { SpendRepo } from '../../../src/repos/SpendRepo';
import {
  BudgetService,
  DauCache,
  MICRO_USD,
  budgetExhaustedError,
} from '../../../src/services/BudgetService';
import { CapturingAlerter } from '../../fakes/CapturingAlerter';
import { InMemoryMetrics } from '../../fakes/InMemoryMetrics';
import { createHarness } from '../../fakes/testDeps';
import { db, seedInstall } from '../../helpers/db';
import { ReadingDriver } from '../../helpers/readingDriver';

const config: RuntimeConfig = {
  ...DEFAULT_RUNTIME_CONFIG,
  'ai.budget.freeUsdPerDau': 0.03,
  'ai.budget.softFloorUsd': 50,
  'ai.budget.freeStopFloorUsd': 100,
  'ai.budget.dailyHardUsd': 300,
};

/** Each test uses its own UTC day so the shared `ai_spend_daily` rows never collide. */
let dayCounter = 0;
function freshDay(): Date {
  dayCounter++;
  return new Date(Date.UTC(2031, 0, 1 + dayCounter * 3, 12));
}

function service(ports: ConstructorParameters<typeof BudgetService>[2] = {}): BudgetService {
  return new BudgetService(db, new DauCache(), ports);
}

async function spend(now: Date, usd: number): Promise<void> {
  await new BudgetService(db, new DauCache()).record(now, usd * MICRO_USD);
}

async function rejected(promise: Promise<unknown>): Promise<ApiError> {
  try {
    await promise;
  } catch (err) {
    return err as ApiError;
  }
  throw new Error('expected a rejection');
}

describe('BudgetService accounting (03 §10.1)', () => {
  it('upserts ai_spend_daily after every model call, summing every provider', async () => {
    const now = freshDay();
    const budget = service();
    await budget.record(now, 12_345); // anthropic/claude-sonnet-5
    await budget.record(now, 1_000.4); // openai/gpt-6-luna (rounded)
    await budget.recordStmt(now, -5).run(); // never negative
    const row = await new SpendRepo(db).get(now.toISOString().slice(0, 10));
    expect(row).toEqual({ dateUtc: row.dateUtc, readings: 3, costMicroUsd: 13_345 });
    expect((await budget.status(config, now)).spendUsd).toBeCloseTo(0.013345);
  });
});

describe('BudgetService tiers (03 §10.2, RC64)', () => {
  it('reports each tier from today’s spend', async () => {
    const cases: [number, BudgetTier][] = [
      [0, 'normal'],
      [49, 'normal'],
      [50, 'soft'],
      [100, 'freeStop'],
      [300, 'hard'],
    ];
    for (const [usd, tier] of cases) {
      const now = freshDay();
      await spend(now, usd);
      expect((await service().status(config, now)).tier).toBe(tier);
    }
  });

  it('sizes soft and free stop from yesterday’s dau (cached per day)', async () => {
    const now = freshDay();
    const yesterday = new Date(now.getTime() - 86_400_000).toISOString();
    for (let i = 0; i < 4; i++) {
      await seedInstall({ now: yesterday });
    }
    // 4 installs × $20 per DAU = $80 soft, $160 free stop.
    const scaled = { ...config, 'ai.budget.freeUsdPerDau': 20 };
    await spend(now, 120);
    const cache = new DauCache();
    const budget = new BudgetService(db, cache);
    const snap = await budget.snapshot(scaled, now);
    expect(snap).toMatchObject({ tier: 'soft', dau: 4, level: 'soft' });
    expect(snap.thresholds).toEqual({ soft: 80, freeStop: 160, hard: 300 });
    // A later install is not counted until tomorrow: the value is cached for the day.
    await seedInstall({ now: yesterday });
    expect((await budget.snapshot(scaled, now)).dau).toBe(4);
    expect(cache.get(now.toISOString().slice(0, 10))).toBe(4);
  });

  it('never queries dau below the floor', async () => {
    const now = freshDay();
    const cache = new DauCache();
    await new BudgetService(db, cache).status(config, now);
    expect(cache.get(now.toISOString().slice(0, 10))).toBeUndefined();
  });

  it('the free path never returns AI_BUDGET_EXHAUSTED below the free-stop tier', async () => {
    const h = createHarness();
    for (const dau of [0, 10, 5000]) {
      const t = budgetThresholds(dau, config);
      for (const usd of [
        0,
        t.soft * 0.5,
        t.soft * 0.8,
        t.soft,
        (t.soft + t.freeStop) / 2,
        t.freeStop - 0.01,
      ]) {
        const now = freshDay();
        await spend(now, usd);
        const budget = new BudgetService(db, dauCacheWith(now, dau), { metrics: h.metrics });
        const tier = await budget.assertHoldAllowed(config, now);
        expect(['normal', 'soft']).toContain(tier);
        expect(await budget.assertModelCallAllowed(config, now)).toBe(tier);
      }
    }
    // And a free-only install really holds its free reading in the soft tier.
    const driver = new ReadingDriver(h);
    driver.budget.tier = 'soft';
    const id = await seedInstall();
    expect(await driver.hold(id)).toMatchObject({ kind: 'held', chargeSource: 'free' });
    expect(aiTierFor('free', 'soft')).toBe('freeFallback');
    expect(h.metrics.count('budget_block')).toBe(0);
  });

  it('free stop: an install with paid credits keeps reading, a free-only install gets 503 tier=freeStop', async () => {
    const h = createHarness();
    const driver = new ReadingDriver(h);
    driver.budget.tier = 'freeStop';
    const budget = new BudgetService(db, new DauCache(), { metrics: h.metrics });

    const payer = await seedInstall();
    await driver.grant(payer, 'paid', 1);
    expect(await driver.hold(payer)).toMatchObject({ kind: 'held', chargeSource: 'paid' });

    const freeOnly = await seedInstall();
    const result = await driver.hold(freeOnly);
    expect(result).toMatchObject({ kind: 'insufficient', reason: 'freePaused' });
    const error = result.kind === 'insufficient' ? budget.freeStopError(result.reason) : null;
    expect(error?.code).toBe('AI_BUDGET_EXHAUSTED');
    expect(error?.options.details).toEqual({ tier: 'freeStop' });
    expect(budget.freeStopError('noCredits')).toBeNull();
    expect(h.metrics.points).toContainEqual({ event: 'budget_block', code: 'freeStop' });
    expect(await driver.balances(freeOnly)).toEqual({ bonus: 0, paid: 0 });
  });

  it('hard stop: paid is never charged (the hold is refused before anything is held)', async () => {
    const h = createHarness();
    const now = freshDay();
    await spend(now, 300);
    const budget = new BudgetService(db, new DauCache(), { metrics: h.metrics });
    const driver = new ReadingDriver(h);
    const payer = await seedInstall();
    await driver.grant(payer, 'paid', 2);

    const err = await rejected(budget.assertHoldAllowed(config, now));
    expect(err).toBeInstanceOf(ApiError);
    expect(err.code).toBe('AI_BUDGET_EXHAUSTED');
    expect(err.options.details).toEqual({ tier: 'hard' });
    expect(await driver.balances(payer)).toEqual({ bonus: 0, paid: 2 });
    expect(h.metrics.points).toContainEqual({ event: 'budget_block', code: 'hard' });

    // In flight: the pre-model check fails, the caller refunds the hold, nothing is charged.
    driver.budget.tier = 'normal';
    const free = await driver.hold(payer);
    await driver.balance.commit({ readingId: free.readingId });
    const held = await driver.hold(payer);
    expect(held).toMatchObject({ kind: 'held', chargeSource: 'paid' });
    await expect(budget.assertModelCallAllowed(config, now)).rejects.toThrow('AI_BUDGET_EXHAUSTED');
    await driver.balance.refund({ readingId: held.readingId, reason: 'budget' });
    expect(await driver.balances(payer)).toEqual({ bonus: 0, paid: 2 });
    expect(budgetExhaustedError('hard').options.details).toEqual({ tier: 'hard' });
  });
});

describe('BudgetService.check (15-minute cron)', () => {
  it('sends one alert for the current level, deduplicated per level', async () => {
    const levels: [number, string, string][] = [
      [25, 'alert50', 'budget_alert'],
      [40, 'alert80', 'budget_alert'],
      [50, 'soft', 'budget_soft_hit'],
      [100, 'freeStop', 'budget_free_stop'],
      [300, 'hard', 'budget_hard_hit'],
    ];
    for (const [usd, level, text] of levels) {
      const now = freshDay();
      await spend(now, usd);
      const alerter = new CapturingAlerter();
      expect(await service({ alerter }).check(config, now)).toBe(1);
      expect(alerter.alerts).toHaveLength(1);
      expect(alerter.alerts[0]).toMatchObject({
        kind: 'budget_tier',
        dedupeKey: `budget_tier:${level}`,
        fields: { level, spendUsd: usd, dau: 0, softUsd: 50, freeStopUsd: 100, hardUsd: 300 },
      });
      expect(alerter.alerts[0]?.message).toContain(text);
    }
  });

  it('sends nothing below 50 % of soft or without an alerter', async () => {
    const now = freshDay();
    await spend(now, 10);
    const alerter = new CapturingAlerter();
    expect(await service({ alerter }).check(config, now)).toBe(0);
    await spend(now, 300);
    expect(await service({ metrics: new InMemoryMetrics() }).check(config, now)).toBe(0);
    expect(alerter.alerts).toEqual([]);
  });
});

/** A `DauCache` preset to `dau` for `now`'s day. */
function dauCacheWith(now: Date, dau: number): DauCache {
  const cache = new DauCache();
  cache.set(now.toISOString().slice(0, 10), dau);
  return cache;
}
