import type { RuntimeConfig } from '../config/schema';
import {
  budgetAlertLevel,
  budgetFloorUsd,
  budgetThresholds,
  tierFor,
  type BudgetAlertLevel,
  type BudgetThresholds,
  type BudgetTier,
} from '../domain/budget';
import { ApiError } from '../http/errors';
import type { Alerter } from '../ports/Alerter';
import type { Metrics } from '../ports/Metrics';
import { SpendRepo } from '../repos/SpendRepo';

/**
 * Budget guardrails (03 §10, RC64, RC97).
 *
 * - Accounting (§10.1): `record` upserts `ai_spend_daily` after every model
 *   call, whatever the provider, so the tiers see the total spend.
 * - Tiers (§10.2): `status` for `GET /v1/balance` and the hold (free paused
 *   in `freeStop`), `assertHoldAllowed` / `assertModelCallAllowed` for the
 *   hard stop, `AiRouter.aiTierFor` for the soft-tier model downgrade.
 * - Alerts: `check` in the 15-minute cron.
 *
 * `dau` = distinct installs with a reading or balance sync yesterday (UTC),
 * cached per isolate and day, and queried only once today's spend has
 * reached `budgetFloorUsd` (below it no tier depends on `dau`).
 */
export interface BudgetStatus {
  readonly tier: BudgetTier;
  readonly spendUsd: number;
}

export interface BudgetSnapshot extends BudgetStatus {
  readonly dau: number;
  readonly thresholds: BudgetThresholds;
  readonly level: BudgetAlertLevel;
}

/** Optional ports: metrics for `budget_block`, the alerter for `check`. */
export interface BudgetPorts {
  readonly metrics?: Metrics;
  readonly alerter?: Alerter;
}

export const MICRO_USD = 1_000_000;
const DAY_MS = 86_400_000;

/** `dau` per UTC day, shared by the requests of one isolate. */
export class DauCache {
  private day: string | undefined;
  private value = 0;

  get(day: string): number | undefined {
    return this.day === day ? this.value : undefined;
  }

  set(day: string, value: number): void {
    this.day = day;
    this.value = value;
  }
}

export const isolateDauCache = new DauCache();

/** `503 AI_BUDGET_EXHAUSTED` with `details.tier` (S31 `readingsPaused`, never a paywall, RC47). */
export function budgetExhaustedError(tier: 'freeStop' | 'hard'): ApiError {
  return new ApiError('AI_BUDGET_EXHAUSTED', { details: { tier } });
}

const ALERT_TEXT: Readonly<Record<Exclude<BudgetAlertLevel, 'none'>, string>> = {
  alert50: 'budget_alert: AI spend reached 50 % of the soft tier',
  alert80: 'budget_alert: AI spend reached 80 % of the soft tier',
  soft: 'budget_soft_hit: free readings moved to ai.model.freeFallback',
  freeStop: 'budget_free_stop: free readings paused until tomorrow (UTC)',
  hard: 'budget_hard_hit: all AI readings paused until tomorrow (UTC)',
};

export class BudgetService {
  private readonly spend: SpendRepo;

  constructor(
    db: D1Database,
    private readonly cache: DauCache = isolateDauCache,
    private readonly ports: BudgetPorts = {},
  ) {
    this.spend = new SpendRepo(db);
  }

  /** §10.1: one model call's cost into today's (UTC) `ai_spend_daily` row. */
  recordStmt(now: Date, costMicroUsd: number): D1PreparedStatement {
    return this.spend.addStmt(utcDay(now), Math.max(0, Math.round(costMicroUsd)));
  }

  async record(now: Date, costMicroUsd: number): Promise<void> {
    await this.recordStmt(now, costMicroUsd).run();
  }

  async status(config: RuntimeConfig, now: Date): Promise<BudgetStatus> {
    const today = utcDay(now);
    const spendUsd = (await this.spend.get(today)).costMicroUsd / MICRO_USD;
    const dau = spendUsd >= budgetFloorUsd(config) ? await this.dau(today) : 0;
    return { tier: tierFor(spendUsd, budgetThresholds(dau, config)), spendUsd };
  }

  /** Tier, thresholds and alert level with a fresh `dau` (the cron path). */
  async snapshot(config: RuntimeConfig, now: Date): Promise<BudgetSnapshot> {
    const today = utcDay(now);
    const spendUsd = (await this.spend.get(today)).costMicroUsd / MICRO_USD;
    const dau = await this.dau(today);
    const thresholds = budgetThresholds(dau, config);
    return {
      tier: tierFor(spendUsd, thresholds),
      spendUsd,
      dau,
      thresholds,
      level: budgetAlertLevel(spendUsd, thresholds),
    };
  }

  /**
   * Hold time (§10.2): the hard tier stops every reading before anything is
   * held, so nothing is charged. Returns the tier for the rest of the hold
   * (the free-stop tier only pauses the free bucket, see
   * `insufficientHoldError`).
   */
  async assertHoldAllowed(config: RuntimeConfig, now: Date): Promise<BudgetTier> {
    const { tier } = await this.status(config, now);
    if (tier === 'hard') {
      this.ports.metrics?.write({ event: 'budget_block', code: 'hard' });
      throw budgetExhaustedError('hard');
    }
    return tier;
  }

  /**
   * Before the model call (§10.2): in the hard tier the call is not made and
   * the caller refunds the hold ("an in-flight reading is refunded, never
   * charged"). Below it the reading goes ahead; the tier picks the free model.
   */
  async assertModelCallAllowed(config: RuntimeConfig, now: Date): Promise<BudgetTier> {
    return this.assertHoldAllowed(config, now);
  }

  /**
   * A hold that found no bucket (`insufficient`): when the free bucket was
   * skipped only because of the free-stop tier, the install gets
   * `503 AI_BUDGET_EXHAUSTED` (`tier=freeStop`) instead of the `402` paywall
   * (RC47). Returns null for every other reason (the caller answers 402).
   */
  freeStopError(reason: string): ApiError | null {
    if (reason !== 'freePaused') {
      return null;
    }
    this.ports.metrics?.write({ event: 'budget_block', code: 'freeStop' });
    return budgetExhaustedError('freeStop');
  }

  /**
   * The 15-minute cron (§10.2, §12): sends the current alert level through
   * the `Alerter` (dedupe bucket `budget_tier:{level}`, so a higher level is
   * never swallowed by a lower one in the same hour). Returns the number of
   * alerts sent (0 or 1).
   */
  async check(config: RuntimeConfig, now: Date): Promise<number> {
    const snap = await this.snapshot(config, now);
    const alerter = this.ports.alerter;
    if (snap.level === 'none' || alerter === undefined) {
      return 0;
    }
    await alerter.send({
      kind: 'budget_tier',
      dedupeKey: `budget_tier:${snap.level}`,
      message: ALERT_TEXT[snap.level],
      fields: {
        level: snap.level,
        spendUsd: round2(snap.spendUsd),
        dau: snap.dau,
        softUsd: round2(snap.thresholds.soft),
        freeStopUsd: round2(snap.thresholds.freeStop),
        hardUsd: round2(snap.thresholds.hard),
      },
    });
    return 1;
  }

  private async dau(today: string): Promise<number> {
    const cached = this.cache.get(today);
    if (cached !== undefined) {
      return cached;
    }
    const start = Date.parse(`${today}T00:00:00.000Z`);
    const value = await this.spend.activeInstalls(
      new Date(start - DAY_MS).toISOString(),
      new Date(start).toISOString(),
    );
    this.cache.set(today, value);
    return value;
  }
}

function utcDay(now: Date): string {
  return now.toISOString().slice(0, 10);
}

function round2(value: number): number {
  return Math.round(value * 100) / 100;
}
