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

export function budgetTier(spendUsd: number, dau: number, config: RuntimeConfig): BudgetTier {
  if (spendUsd >= config['ai.budget.dailyHardUsd']) {
    return 'hard';
  }
  const soft = Math.max(config['ai.budget.softFloorUsd'], config['ai.budget.freeUsdPerDau'] * dau);
  const freeStop = Math.max(config['ai.budget.freeStopFloorUsd'], 2 * soft);
  if (spendUsd >= freeStop) {
    return 'freeStop';
  }
  return spendUsd >= soft ? 'soft' : 'normal';
}
