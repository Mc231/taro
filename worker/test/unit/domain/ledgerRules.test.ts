import { describe, expect, it } from 'vitest';
import {
  canHold,
  holdExpired,
  isLedgerBucket,
  nextAttempt,
  READING_COST,
  refundRule,
} from '../../../src/domain/ledgerRules';

describe('ledgerRules (03 §5.3, RC49, RC52, RC62)', () => {
  it('a reading costs one credit', () => {
    expect(READING_COST).toBe(1);
  });

  it('holds only from none or refunded; a refunded attempt is never reused', () => {
    expect(['none', 'held', 'consumed', 'refunded'].map((s) => canHold(s as never))).toEqual([
      true,
      false,
      false,
      true,
    ]);
    expect(nextAttempt('none', 1)).toBe(1);
    expect(nextAttempt('refunded', 1)).toBe(2);
  });

  it('maps refund reasons to ledger reason, status and decline counting', () => {
    expect(refundRule('undelivered')).toEqual({
      ledgerReason: 'reading_undelivered',
      status: 'expired_refunded',
      countsAsDecline: false,
    });
    expect(refundRule('declined')).toMatchObject({ status: 'declined', countsAsDecline: true });
    expect(refundRule('expired').status).toBe('expired_hold');
    expect(refundRule('released').status).toBe('expired_hold');
    expect(refundRule('abandoned').status).toBe('failed');
    expect(refundRule('budget').ledgerReason).toBe('reading_refund');
  });

  it('only bonus and paid holds are ledger entries', () => {
    expect([isLedgerBucket('free'), isLedgerBucket('bonus'), isLedgerBucket('paid')]).toEqual([
      false,
      true,
      true,
    ]);
  });

  it('holdExpired with a safety margin', () => {
    const now = new Date('2026-09-26T10:00:00.000Z');
    expect(holdExpired(null, now)).toBe(false);
    expect(holdExpired('2026-09-26T10:00:00Z', now)).toBe(true);
    expect(holdExpired('2026-09-26T10:01:00Z', now)).toBe(false);
    expect(holdExpired('2026-09-26T10:01:00Z', now, 120)).toBe(true);
  });
});
