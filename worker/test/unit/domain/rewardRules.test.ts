import { describe, expect, it } from 'vitest';
import {
  adUnitAllowed,
  cancelledGrantDeadline,
  cooldownEndsAt,
  intentDenial,
  ssvIntentRejection,
  visibleStatus,
  type IntentEligibilityInput,
} from '../../../src/domain/rewardRules';

const NOW = new Date('2026-09-26T10:00:00.000Z');
const RESETS = new Date('2026-09-26T22:00:00.000Z');

function input(overrides: Partial<IntentEligibilityInput> = {}): IntentEligibilityInput {
  return {
    now: NOW,
    enabled: true,
    dailyCap: 3,
    cooldownSec: 300,
    grantedToday: 0,
    lastGrantedAt: null,
    deviceReusedFirstDay: false,
    resetsAt: RESETS,
    ...overrides,
  };
}

describe('intentDenial (03 §7.1, RC35, RC57)', () => {
  it('allows an intent under the cap with no recent grant', () => {
    expect(intentDenial(input())).toBeNull();
    expect(intentDenial(input({ grantedToday: 2 }))).toBeNull();
  });

  it('is disabled when rewarded.enabled is off or dailyCap is 0', () => {
    expect(intentDenial(input({ enabled: false }))).toEqual({ kind: 'disabled' });
    expect(intentDenial(input({ dailyCap: 0 }))).toEqual({ kind: 'disabled' });
  });

  it('caps at grantedToday + 1 > dailyCap until the next local midnight', () => {
    expect(intentDenial(input({ grantedToday: 3 }))).toEqual({
      kind: 'capped',
      reason: 'cap',
      availableAt: '2026-09-26T22:00:00Z',
    });
  });

  it('caps a device_reused install on its registration day (03 §3.7)', () => {
    expect(intentDenial(input({ deviceReusedFirstDay: true }))).toMatchObject({ reason: 'cap' });
  });

  it('measures the cooldown from the last grant (RC35)', () => {
    expect(intentDenial(input({ lastGrantedAt: '2026-09-26T09:58:00.000Z' }))).toEqual({
      kind: 'capped',
      reason: 'cooldown',
      availableAt: '2026-09-26T10:03:00Z',
    });
    expect(intentDenial(input({ lastGrantedAt: '2026-09-26T09:55:00.000Z' }))).toBeNull();
    expect(intentDenial(input({ lastGrantedAt: '2026-09-26T09:58:00.000Z', cooldownSec: 0 }))).toBe(
      null,
    );
  });

  it('computes the cooldown end only with a grant', () => {
    expect(cooldownEndsAt(null, 300)).toBeNull();
    expect(cooldownEndsAt('2026-09-26T10:00:00.000Z', 60)?.toISOString()).toBe(
      '2026-09-26T10:01:00.000Z',
    );
  });
});

describe('cancelledGrantDeadline (03 §7.2)', () => {
  it('is now + 2 min, never later than the TTL', () => {
    expect(cancelledGrantDeadline('2026-09-26T10:15:00.000Z', NOW)).toBe(
      '2026-09-26T10:02:00.000Z',
    );
    expect(cancelledGrantDeadline('2026-09-26T10:01:00.000Z', NOW)).toBe(
      '2026-09-26T10:01:00.000Z',
    );
  });
});

describe('adUnitAllowed', () => {
  const allowed = ['ca-app-pub-3940256099942544/1712485313'];

  it('matches the full ID (client) and the numeric part (SSV)', () => {
    expect(adUnitAllowed('ca-app-pub-3940256099942544/1712485313', allowed)).toBe(true);
    expect(adUnitAllowed('1712485313', allowed)).toBe(true);
  });

  it('rejects other and empty ad units', () => {
    expect(adUnitAllowed('999', allowed)).toBe(false);
    expect(adUnitAllowed('ca-app-pub-1/1712485313x', allowed)).toBe(false);
    expect(adUnitAllowed('', allowed)).toBe(false);
  });
});

describe('ssvIntentRejection (03 §7.2, RC57)', () => {
  const live = '2026-09-26T10:05:00.000Z';
  const past = '2026-09-26T09:59:59.000Z';

  it('grants a live issued or cancelled-in-grace intent', () => {
    expect(ssvIntentRejection({ status: 'issued', expiresAt: live }, NOW)).toBeNull();
    expect(ssvIntentRejection({ status: 'cancelled', expiresAt: live }, NOW)).toBeNull();
  });

  it('rejects expired, out-of-grace, used and rejected intents', () => {
    expect(ssvIntentRejection({ status: 'issued', expiresAt: past }, NOW)).toBe('expired');
    expect(ssvIntentRejection({ status: 'cancelled', expiresAt: past }, NOW)).toBe('cancelled');
    expect(ssvIntentRejection({ status: 'granted', expiresAt: live }, NOW)).toBe('already_granted');
    expect(ssvIntentRejection({ status: 'expired', expiresAt: live }, NOW)).toBe('expired');
    expect(ssvIntentRejection({ status: 'rejected', expiresAt: live }, NOW)).toBe('rejected');
  });

  it('shows an issued intent past its TTL as expired before the cron runs', () => {
    expect(visibleStatus({ status: 'issued', expiresAt: past }, NOW)).toBe('expired');
    expect(visibleStatus({ status: 'issued', expiresAt: live }, NOW)).toBe('issued');
    expect(visibleStatus({ status: 'cancelled', expiresAt: past }, NOW)).toBe('cancelled');
  });
});
