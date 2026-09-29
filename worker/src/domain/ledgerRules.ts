import type { HoldSource, HoldState, ReadingStatus } from '../repos/ReadingRepo';
import type { LedgerReason } from '../repos/LedgerRepo';

/**
 * Ledger and hold rules (03 §4, §5.3; 04 §5.2; RC7, RC49, RC52, RC62).
 * Pure functions only: `BalanceService` turns them into D1 batches.
 *
 * - Every reading costs exactly one credit, whatever the spread (RC62).
 * - A hold belongs to one attempt of one reading and is a compare-and-set on
 *   `readings.hold_state`: `none | refunded → held → consumed | refunded`.
 * - Each `(reading, attempt)` has at most one hold and at most one refund.
 *   A new hold after a refund is a new attempt (`attempt + 1`), which gives
 *   the ledger a fresh `ref_id = {readingId}#{attempt}` (RC49).
 */
export const READING_COST = 1;

/** Why a hold is given back (03 §5.3 step 3, §9.0, §9.1). */
export type RefundReason =
  /** The pre-draw hold expired unused (`releaseExpiredHolds`, a renewal of an expired hold). */
  | 'expired'
  /** Another reading of the install took the one open hold (03 §9.0). */
  | 'released'
  /** A `held`/`generating` row the stale-hold cron found abandoned (`refundStaleHolds`). */
  | 'abandoned'
  /** Generation failed or the deadline passed. */
  | 'failed'
  /** The budget hard stop hit a reading in flight (03 §10.2). */
  | 'budget'
  /** L1/L2/L3 safety refusal: free, counts toward `safety.maxDeclinedPerDay`. */
  | 'declined'
  /** Completed but never acknowledged; the body expired (RC51). */
  | 'undelivered';

export interface RefundRule {
  /** Ledger reason of the `+1` entry for a bonus or paid hold. */
  readonly ledgerReason: Extract<LedgerReason, 'reading_refund' | 'reading_undelivered'>;
  /** `readings.status` after the refund. */
  readonly status: ReadingStatus;
  /** `daily_usage.declined_count + 1` (only declines count, RC74). */
  readonly countsAsDecline: boolean;
}

const REFUND_RULES: Readonly<Record<RefundReason, RefundRule>> = {
  expired: { ledgerReason: 'reading_refund', status: 'expired_hold', countsAsDecline: false },
  released: { ledgerReason: 'reading_refund', status: 'expired_hold', countsAsDecline: false },
  abandoned: { ledgerReason: 'reading_refund', status: 'failed', countsAsDecline: false },
  failed: { ledgerReason: 'reading_refund', status: 'failed', countsAsDecline: false },
  budget: { ledgerReason: 'reading_refund', status: 'failed', countsAsDecline: false },
  declined: { ledgerReason: 'reading_refund', status: 'declined', countsAsDecline: true },
  undelivered: {
    ledgerReason: 'reading_undelivered',
    status: 'expired_refunded',
    countsAsDecline: false,
  },
};

export function refundRule(reason: RefundReason): RefundRule {
  return REFUND_RULES[reason];
}

/** A hold may be taken from `none` (first attempt) or `refunded` (a new attempt). */
export function canHold(state: HoldState): boolean {
  return state === 'none' || state === 'refunded';
}

/**
 * The attempt a new hold belongs to: the row's attempt while nothing was ever
 * held for it, otherwise the next one (a refunded attempt is never re-used).
 */
export function nextAttempt(state: HoldState, attempt: number): number {
  return state === 'refunded' ? attempt + 1 : attempt;
}

/** Bonus and paid holds are ledger entries; a free hold lives in the usage tables. */
export function isLedgerBucket(source: HoldSource): source is 'bonus' | 'paid' {
  return source !== 'free';
}

/** `true` once a live hold has less than `minRemainingSec` left (or has passed). */
export function holdExpired(expiresAt: string | null, now: Date, minRemainingSec = 0): boolean {
  if (expiresAt === null) {
    return false;
  }
  return Date.parse(expiresAt) - now.getTime() <= minRemainingSec * 1000;
}
