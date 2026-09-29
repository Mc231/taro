import fc from 'fast-check';
import { describe, expect, it } from 'vitest';
import {
  freePaused,
  holdPlan,
  insufficientReason,
  nextSource,
  paidBlocked,
  purchases,
} from '../../../src/domain/consumptionOrder';

describe('holdPlan (free → bonus → paid, 04 MO5)', () => {
  const base = {
    freeDaily: 1,
    freePaused: false,
    deviceReusedFirstDay: false,
    lowTrustIpCapReached: false,
  };

  it('tries free first when nothing skips it', () => {
    expect(holdPlan(base)).toEqual({ buckets: ['free', 'bonus', 'paid'], freeSkip: null });
  });

  it.each([
    [{ freePaused: true }, 'paused'],
    [{ deviceReusedFirstDay: true }, 'deviceReused'],
    [{ lowTrustIpCapReached: true }, 'lowTrustCap'],
    [{ freeDaily: 0 }, 'noAllowance'],
  ] as const)('skips free for %o → %s', (override, skip) => {
    expect(holdPlan({ ...base, ...override })).toEqual({
      buckets: ['bonus', 'paid'],
      freeSkip: skip,
    });
  });

  it('property: bonus always precedes paid, free is first or absent', () => {
    fc.assert(
      fc.property(
        fc.record({
          freeDaily: fc.integer({ min: 0, max: 5 }),
          freePaused: fc.boolean(),
          deviceReusedFirstDay: fc.boolean(),
          lowTrustIpCapReached: fc.boolean(),
        }),
        (input) => {
          const plan = holdPlan(input);
          expect(plan.buckets.slice(-2)).toEqual(['bonus', 'paid']);
          expect(plan.buckets.includes('free')).toBe(plan.freeSkip === null);
        },
      ),
    );
  });
});

describe('nextSource / insufficientReason (03 §5.1, RC74)', () => {
  it('never names a bucket without a reading', () => {
    fc.assert(
      fc.property(
        fc.boolean(),
        fc.boolean(),
        fc.integer({ min: -5, max: 5 }),
        fc.integer({ min: -5, max: 5 }),
        (freeUsable, paused, bonus, paid) => {
          const source = nextSource({ freeUsable, freePaused: paused, bonus, paid });
          if (source === 'free') {
            expect(freeUsable && !paused).toBe(true);
          } else if (source === 'bonus') {
            expect(bonus).toBeGreaterThan(0);
          } else if (source === 'paid') {
            expect(paid).toBeGreaterThan(0);
            expect(bonus).toBeLessThanOrEqual(0);
          } else {
            expect(bonus <= 0 && paid <= 0 && !(freeUsable && !paused)).toBe(true);
          }
        },
      ),
    );
  });

  it('maps the failure reason', () => {
    expect(insufficientReason({ freeUsable: true, freePaused: true, lowTrustLimited: false })).toBe(
      'freePaused',
    );
    expect(insufficientReason({ freeUsable: false, freePaused: true, lowTrustLimited: true })).toBe(
      'lowTrustCap',
    );
    expect(
      insufficientReason({ freeUsable: false, freePaused: false, lowTrustLimited: false }),
    ).toBe('noCredits');
  });

  it('pauses free for the free-stop and hard tiers only', () => {
    expect(['normal', 'soft', 'freeStop', 'hard'].map((t) => freePaused(t as never))).toEqual([
      false,
      false,
      true,
      true,
    ]);
  });
});

describe('purchasesAllowed / paidBlocked (03 §5.1, RC66)', () => {
  it('paidBlocked = paid < 0', () => {
    expect([paidBlocked(-1), paidBlocked(0), paidBlocked(3)]).toEqual([true, false, false]);
  });

  it('first failing condition wins: blocked, refundDebt, storeDisabled', () => {
    expect(purchases({ status: 'blocked', paid: -2, storeEnabled: false })).toEqual({
      allowed: false,
      reason: 'blocked',
    });
    expect(purchases({ status: 'active', paid: -2, storeEnabled: false })).toEqual({
      allowed: false,
      reason: 'refundDebt',
    });
    expect(purchases({ status: 'active', paid: 0, storeEnabled: false })).toEqual({
      allowed: false,
      reason: 'storeDisabled',
    });
    expect(purchases({ status: 'active', paid: 0, storeEnabled: true })).toEqual({
      allowed: true,
      reason: null,
    });
  });
});
