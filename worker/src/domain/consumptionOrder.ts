import type { BudgetTier } from './budget';

/**
 * Consumption order and purchase eligibility (03 §5.1, §5.3; 04 MO5, §5.5,
 * §12.21; RC6, RC64, RC66, RC74).
 *
 * Readings are taken **free → bonus → paid**. The free bucket is skipped
 * while the budget free-stop tier is active, on the first local day of an
 * iOS `device_reused` install, and while the low-trust IP-prefix cap is
 * reached. The per-install and per-device (Android) free counters are
 * checked by the hold's D1 gate itself (03 §5.3 step 1), because only the
 * database sees concurrent holds.
 */
export type HoldBucket = 'free' | 'bonus' | 'paid';
export type InsufficientReason = 'noCredits' | 'lowTrustCap' | 'freePaused';
export type PurchasesBlockedReason = 'blocked' | 'refundDebt' | 'storeDisabled';

/** Why the free bucket is not even tried. */
export type FreeSkip = 'paused' | 'deviceReused' | 'lowTrustCap' | 'noAllowance';

/** A budget tier that pauses the free allowance (the hard tier stops everything earlier). */
export function freePaused(tier: BudgetTier): boolean {
  return tier === 'freeStop' || tier === 'hard';
}

export interface HoldPlanInput {
  /** Today's free allowance for this install (`readings.freeDaily`, low-trust capped). */
  readonly freeDaily: number;
  readonly freePaused: boolean;
  /** iOS `device_reused` on the install's first local day (03 §3.7). */
  readonly deviceReusedFirstDay: boolean;
  /** Low-trust install whose IP prefix used up today's free readings (03 §2.4). */
  readonly lowTrustIpCapReached: boolean;
}

export interface HoldPlan {
  /** Buckets to try, in order; the batch applies the first whose gate passes. */
  readonly buckets: readonly HoldBucket[];
  readonly freeSkip: FreeSkip | null;
}

export function holdPlan(input: HoldPlanInput): HoldPlan {
  let freeSkip: FreeSkip | null = null;
  if (input.freePaused) {
    freeSkip = 'paused';
  } else if (input.deviceReusedFirstDay) {
    freeSkip = 'deviceReused';
  } else if (input.lowTrustIpCapReached) {
    freeSkip = 'lowTrustCap';
  } else if (input.freeDaily < 1) {
    freeSkip = 'noAllowance';
  }
  const buckets: HoldBucket[] = freeSkip === null ? ['free', 'bonus', 'paid'] : ['bonus', 'paid'];
  return { buckets, freeSkip };
}

export interface NextSourceInput {
  /** A free reading is left and usable (after device, reuse and low-trust caps). */
  readonly freeUsable: boolean;
  readonly freePaused: boolean;
  readonly bonus: number;
  readonly paid: number;
}

/** The bucket the next reading consumes, or null when none is left (`nextSource`, 03 §5.1). */
export function nextSource(input: NextSourceInput): HoldBucket | null {
  if (input.freeUsable && !input.freePaused) {
    return 'free';
  }
  if (input.bonus > 0) {
    return 'bonus';
  }
  return input.paid > 0 ? 'paid' : null;
}

export interface InsufficientInput {
  readonly freeUsable: boolean;
  readonly freePaused: boolean;
  /** A high-trust install would still have a free reading (03 §5.1). */
  readonly lowTrustLimited: boolean;
}

/**
 * `details.reason` of `402 INSUFFICIENT_CREDITS` (03 §2.2, RC74): a free
 * reading held back only by the free-stop tier → `freePaused` (S31, never a
 * paywall, RC47); low trust is the reason → `lowTrustCap`; else `noCredits`.
 */
export function insufficientReason(input: InsufficientInput): InsufficientReason {
  if (input.freeUsable && input.freePaused) {
    return 'freePaused';
  }
  return input.lowTrustLimited ? 'lowTrustCap' : 'noCredits';
}

/** `paidBlocked = paid < 0`: a refund clawback left a debt (03 §6.5, MO16). */
export function paidBlocked(paid: number): boolean {
  return paid < 0;
}

export interface PurchasesInput {
  readonly status: 'active' | 'blocked' | 'deleted';
  readonly paid: number;
  readonly storeEnabled: boolean;
}

/**
 * `purchasesAllowed = status != blocked && paid >= 0 && store.enabled`, with
 * the first failing condition as `purchasesBlockedReason` (03 §5.1, RC66).
 */
export function purchases(input: PurchasesInput): {
  readonly allowed: boolean;
  readonly reason: PurchasesBlockedReason | null;
} {
  let reason: PurchasesBlockedReason | null = null;
  if (input.status === 'blocked') {
    reason = 'blocked';
  } else if (paidBlocked(input.paid)) {
    reason = 'refundDebt';
  } else if (!input.storeEnabled) {
    reason = 'storeDisabled';
  }
  return { allowed: reason === null, reason };
}
