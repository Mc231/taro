import { describe, expect, it } from 'vitest';
import { DEFAULT_RUNTIME_CONFIG } from '../../../src/config/defaults';
import {
  budgetAlertLevel,
  budgetFloorUsd,
  budgetThresholds,
  budgetTier,
  tierFor,
} from '../../../src/domain/budget';

const config = {
  ...DEFAULT_RUNTIME_CONFIG,
  'ai.budget.freeUsdPerDau': 0.03,
  'ai.budget.softFloorUsd': 50,
  'ai.budget.freeStopFloorUsd': 100,
  'ai.budget.dailyHardUsd': 300,
};

describe('domain/budget (03 §10.2, RC64)', () => {
  it('thresholds scale with dau above the floors', () => {
    expect(budgetThresholds(0, config)).toEqual({ soft: 50, freeStop: 100, hard: 300 });
    expect(budgetThresholds(1000, config)).toEqual({ soft: 50, freeStop: 100, hard: 300 });
    const big = budgetThresholds(3000, config);
    expect(big.soft).toBeCloseTo(90);
    expect(big.freeStop).toBeCloseTo(180);
    expect(budgetFloorUsd(config)).toBe(50);
  });

  it('maps spend to each tier', () => {
    expect(budgetTier(0, 0, config)).toBe('normal');
    expect(budgetTier(49.99, 0, config)).toBe('normal');
    expect(budgetTier(50, 0, config)).toBe('soft');
    expect(budgetTier(100, 0, config)).toBe('freeStop');
    expect(budgetTier(300, 0, config)).toBe('hard');
    // The hard stop is absolute, even when the dau-scaled free stop is above it.
    expect(budgetTier(300, 1_000_000, config)).toBe('hard');
    expect(budgetTier(150, 3000, config)).toBe('soft');
  });

  it('alert levels: 50 % and 80 % of soft, then the tiers', () => {
    const t = budgetThresholds(0, config);
    expect(budgetAlertLevel(24.99, t)).toBe('none');
    expect(budgetAlertLevel(25, t)).toBe('alert50');
    expect(budgetAlertLevel(40, t)).toBe('alert80');
    expect(budgetAlertLevel(50, t)).toBe('soft');
    expect(budgetAlertLevel(100, t)).toBe('freeStop');
    expect(budgetAlertLevel(300, t)).toBe('hard');
    expect(tierFor(0, t)).toBe('normal');
  });
});
