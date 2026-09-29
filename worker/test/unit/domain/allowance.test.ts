import { describe, expect, it } from 'vitest';
import { DEFAULT_RUNTIME_CONFIG } from '../../../src/config/defaults';
import type { RuntimeConfig } from '../../../src/config/schema';
import {
  computeBalance,
  currentFreeDaily,
  freeRemaining,
  type AllowanceInput,
} from '../../../src/domain/allowance';
import { budgetFloorUsd, budgetTier } from '../../../src/domain/budget';

const NOW = new Date('2026-09-26T09:12:44.500Z');

function input(overrides: Partial<AllowanceInput> = {}, config: Partial<RuntimeConfig> = {}) {
  const base: AllowanceInput = {
    now: NOW,
    timezone: 'Europe/Berlin',
    install: {
      trust: 'high',
      status: 'active',
      deviceReused: false,
      createdAt: '2026-09-01T00:00:00.000Z',
      stateVersion: 412,
    },
    usage: null,
    device: null,
    balances: { paid: 0, bonus: 0 },
    lastGrantedAt: null,
    budgetTier: 'normal',
    lowTrustIpCapReached: false,
    config: { ...DEFAULT_RUNTIME_CONFIG, ...config },
  };
  return { ...base, ...overrides };
}

function usage(fields: Partial<NonNullable<AllowanceInput['usage']>> = {}) {
  return {
    installId: 'i',
    localDate: '2026-09-26',
    freeLimit: 1,
    freeUsed: 0,
    rewardedGranted: 0,
    readingsTotal: 0,
    declinedCount: 0,
    ...fields,
  };
}

describe('computeBalance (03 §5.1)', () => {
  it('matches the 03 §5.1 example shape for a fresh day', () => {
    expect(computeBalance(input({ balances: { bonus: 2, paid: 5 } }))).toEqual({
      free: {
        limit: 1,
        used: 0,
        remaining: 1,
        localDate: '2026-09-26',
        resetsAt: '2026-09-26T22:00:00Z',
        timezone: 'Europe/Berlin',
        paused: false,
      },
      bonus: 2,
      paid: 5,
      canRead: true,
      canReadReason: null,
      nextSource: 'free',
      rewarded: {
        enabled: true,
        amount: 1,
        dailyCap: 3,
        grantedToday: 0,
        available: true,
        cooldownEndsAt: null,
      },
      paidBlocked: false,
      purchasesAllowed: true,
      purchasesBlockedReason: null,
      ledgerVersion: 412,
      serverTime: '2026-09-26T09:12:44Z',
    });
  });

  it('consumes free, then bonus, then paid (nextSource)', () => {
    const used = usage({ freeUsed: 1, readingsTotal: 1 });
    expect(computeBalance(input({ usage: used, balances: { bonus: 1, paid: 3 } })).nextSource).toBe(
      'bonus',
    );
    expect(computeBalance(input({ usage: used, balances: { bonus: 0, paid: 3 } })).nextSource).toBe(
      'paid',
    );
    const none = computeBalance(input({ usage: used }));
    expect(none).toMatchObject({ canRead: false, canReadReason: 'noCredits', nextSource: null });
    expect(none.free).toMatchObject({ limit: 1, used: 1, remaining: 0 });
  });

  it('raises the snapshot to a higher current freeDaily, never lowers it', () => {
    const raised = computeBalance(
      input({ usage: usage({ freeLimit: 1, freeUsed: 1 }) }, { 'readings.freeDaily': 2 }),
    );
    expect(raised.free).toMatchObject({ limit: 2, used: 1, remaining: 1 });
    const lowered = computeBalance(
      input({ usage: usage({ freeLimit: 3, freeUsed: 1 }) }, { 'readings.freeDaily': 1 }),
    );
    expect(lowered.free).toMatchObject({ limit: 3, remaining: 2 });
  });

  it('dailyLimit wins over credits and is never a paywall reason (RC74)', () => {
    const b = computeBalance(
      input({ usage: usage({ readingsTotal: 30 }), balances: { bonus: 5, paid: 5 } }),
    );
    expect(b).toMatchObject({ canRead: false, canReadReason: 'dailyLimit', nextSource: null });
  });

  it('kill switch and hard budget stop → readingsPaused', () => {
    expect(
      computeBalance(input({ balances: { bonus: 1, paid: 1 } }, { 'readings.enabled': false })),
    ).toMatchObject({ canRead: false, canReadReason: 'readingsPaused' });
    expect(computeBalance(input({ budgetTier: 'hard' }))).toMatchObject({
      canRead: false,
      canReadReason: 'readingsPaused',
    });
  });

  it('free-stop tier pauses free and skips to bonus/paid (RC64)', () => {
    const withBonus = computeBalance(
      input({ budgetTier: 'freeStop', balances: { bonus: 1, paid: 0 } }),
    );
    expect(withBonus.free.paused).toBe(true);
    expect(withBonus.free.remaining).toBe(1);
    expect(withBonus).toMatchObject({ canRead: true, nextSource: 'bonus' });

    const freeOnly = computeBalance(input({ budgetTier: 'freeStop' }));
    expect(freeOnly).toMatchObject({ canRead: false, canReadReason: 'readingsPaused' });

    const nothing = computeBalance(
      input({ budgetTier: 'freeStop', usage: usage({ freeUsed: 1 }) }),
    );
    expect(nothing).toMatchObject({ canRead: false, canReadReason: 'noCredits' });
    expect(computeBalance(input({ budgetTier: 'soft' })).free.paused).toBe(false);
  });

  it('low trust: abuse.lowTrust.freeDaily caps the allowance and explains a missing free reading', () => {
    const low = { ...input().install, trust: 'low' as const };
    const cfg = { 'readings.freeDaily': 2, 'abuse.lowTrust.freeDaily': 1 };
    expect(currentFreeDaily('low', { ...DEFAULT_RUNTIME_CONFIG, ...cfg })).toBe(1);
    expect(currentFreeDaily('high', { ...DEFAULT_RUNTIME_CONFIG, ...cfg })).toBe(2);

    const fresh = computeBalance(input({ install: low }, cfg));
    expect(fresh.free).toMatchObject({ limit: 1, remaining: 1 });
    expect(fresh.nextSource).toBe('free');

    const usedOne = computeBalance(input({ install: low, usage: usage({ freeUsed: 1 }) }, cfg));
    expect(usedOne).toMatchObject({ canRead: false, canReadReason: 'lowTrustCap' });

    const ipCapped = computeBalance(input({ install: low, lowTrustIpCapReached: true }));
    expect(ipCapped.free.remaining).toBe(0);
    expect(ipCapped).toMatchObject({ canRead: false, canReadReason: 'lowTrustCap' });

    const ipCappedWithPaid = computeBalance(
      input({ install: low, lowTrustIpCapReached: true, balances: { bonus: 0, paid: 2 } }),
    );
    expect(ipCappedWithPaid).toMatchObject({ canRead: true, nextSource: 'paid' });

    const usedAllLow = computeBalance(input({ install: low, usage: usage({ freeUsed: 1 }) }));
    expect(usedAllLow.canReadReason).toBe('noCredits');
  });

  it('Android device row: a second install on the device gets no second free reading (§3.7)', () => {
    const device = { deviceKeyHash: 'd', localDate: '2026-09-26', freeUsed: 1, rewardedGranted: 2 };
    const b = computeBalance(input({ device }));
    expect(b.free).toMatchObject({ used: 0, remaining: 0 });
    expect(b.canReadReason).toBe('noCredits');
    expect(b.rewarded.grantedToday).toBe(2);
    expect(freeRemaining(input({ device: { ...device, freeUsed: 0 } }))).toBe(1);
  });

  it('iOS device_reused: free and rewarded start on the next local day (§3.7)', () => {
    const reused = {
      ...input().install,
      deviceReused: true,
      createdAt: '2026-09-26T05:00:00.000Z',
    };
    const firstDay = computeBalance(input({ install: reused }));
    expect(firstDay.free.remaining).toBe(0);
    expect(firstDay.rewarded.available).toBe(false);
    const nextDay = computeBalance(
      input({ install: reused, now: new Date('2026-09-27T09:00:00Z') }),
    );
    expect(nextDay.free.remaining).toBe(1);
    expect(nextDay.rewarded.available).toBe(true);
  });

  it('rewarded: cap, cooldown anchored on the last grant, disabled', () => {
    const capped = computeBalance(input({ usage: usage({ rewardedGranted: 3 }) }));
    expect(capped.rewarded).toMatchObject({ grantedToday: 3, available: false });

    const cooling = computeBalance(input({ lastGrantedAt: '2026-09-26T09:10:00.000Z' }));
    expect(cooling.rewarded).toMatchObject({
      available: false,
      cooldownEndsAt: '2026-09-26T09:15:00Z',
    });
    const cooled = computeBalance(input({ lastGrantedAt: '2026-09-26T09:00:00.000Z' }));
    expect(cooled.rewarded).toMatchObject({ available: true, cooldownEndsAt: null });

    const off = computeBalance(input({}, { 'rewarded.enabled': false }));
    expect(off.rewarded).toMatchObject({ enabled: false, available: false });
  });

  it('purchases: blocked > refundDebt > storeDisabled (RC66); paidBlocked = paid < 0', () => {
    const blocked = computeBalance(
      input({
        install: { ...input().install, status: 'blocked' },
        balances: { bonus: 0, paid: -1 },
      }),
    );
    expect(blocked).toMatchObject({
      purchasesAllowed: false,
      purchasesBlockedReason: 'blocked',
      paidBlocked: true,
    });
    // A blocked install keeps its free reading.
    expect(blocked.nextSource).toBe('free');

    const debt = computeBalance(input({ balances: { bonus: 0, paid: -2 } }));
    expect(debt).toMatchObject({ purchasesBlockedReason: 'refundDebt', paidBlocked: true });

    const storeOff = computeBalance(input({}, { 'store.enabled': false }));
    expect(storeOff).toMatchObject({
      purchasesAllowed: false,
      purchasesBlockedReason: 'storeDisabled',
      paidBlocked: false,
    });
  });
});

describe('budget tiers (03 §10.2, RC64)', () => {
  const config = DEFAULT_RUNTIME_CONFIG;

  it('orders normal < soft < freeStop < hard at the defaults', () => {
    // Defaults: soft floor 50, free-stop floor 100, hard 300, $0.03 per DAU.
    expect(budgetFloorUsd(config)).toBe(50);
    expect(budgetTier(0, 0, config)).toBe('normal');
    expect(budgetTier(49.99, 0, config)).toBe('normal');
    expect(budgetTier(50, 0, config)).toBe('soft');
    expect(budgetTier(100, 0, config)).toBe('freeStop');
    expect(budgetTier(300, 0, config)).toBe('hard');
  });

  it('scales soft and free-stop with dau', () => {
    // dau 5000 → soft = max(50, 150) = 150, freeStop = max(100, 300) = 300 = hard.
    expect(budgetTier(120, 5000, config)).toBe('normal');
    expect(budgetTier(150, 5000, config)).toBe('soft');
    expect(budgetTier(299, 5000, config)).toBe('soft');
    // dau 2000 → soft 60, freeStop 120.
    expect(budgetTier(119, 2000, config)).toBe('soft');
    expect(budgetTier(120, 2000, config)).toBe('freeStop');
  });
});
