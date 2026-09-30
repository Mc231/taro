import type { RuntimeConfig } from '../config/schema';

/**
 * Budget tiers (03 §10.2, RC64) as pure functions of today's model spend
 * (UTC day, USD) and yesterday's `dau`:
 *
 * - soft     = max(`ai.budget.softFloorUsd`, `ai.budget.freeUsdPerDau` × dau)
 * - freeStop = max(`ai.budget.freeStopFloorUsd`, 2 × soft)
 * - hard     = `ai.budget.dailyHardUsd`
 *
 * The 50 % / 80 % alert levels are alerts only and are not a tier here.
 */
export type BudgetTier = 'normal' | 'soft' | 'freeStop' | 'hard';

/** Below this spend no tier above `normal` can apply, so `dau` is not needed. */
export function budgetFloorUsd(config: RuntimeConfig): number {
  return Math.min(config['ai.budget.softFloorUsd'], config['ai.budget.freeStopFloorUsd']);
}

/** Today's thresholds in USD for a given `dau`. */
export interface BudgetThresholds {
  readonly soft: number;
  readonly freeStop: number;
  readonly hard: number;
}

export function budgetThresholds(dau: number, config: RuntimeConfig): BudgetThresholds {
  const soft = Math.max(config['ai.budget.softFloorUsd'], config['ai.budget.freeUsdPerDau'] * dau);
  return {
    soft,
    freeStop: Math.max(config['ai.budget.freeStopFloorUsd'], 2 * soft),
    hard: config['ai.budget.dailyHardUsd'],
  };
}

export function tierFor(spendUsd: number, t: BudgetThresholds): BudgetTier {
  if (spendUsd >= t.hard) {
    return 'hard';
  }
  if (spendUsd >= t.freeStop) {
    return 'freeStop';
  }
  return spendUsd >= t.soft ? 'soft' : 'normal';
}

export function budgetTier(spendUsd: number, dau: number, config: RuntimeConfig): BudgetTier {
  return tierFor(spendUsd, budgetThresholds(dau, config));
}

/**
 * Alert level of the 15-minute cron (03 §10.2): the tier, or below the soft
 * tier the 50 % / 80 % of soft warnings (`budget_alert`).
 */
export type BudgetAlertLevel = 'none' | 'alert50' | 'alert80' | Exclude<BudgetTier, 'normal'>;

export function budgetAlertLevel(spendUsd: number, t: BudgetThresholds): BudgetAlertLevel {
  const tier = tierFor(spendUsd, t);
  if (tier !== 'normal') {
    return tier;
  }
  if (spendUsd >= 0.8 * t.soft) {
    return 'alert80';
  }
  return spendUsd >= 0.5 * t.soft ? 'alert50' : 'none';
}
