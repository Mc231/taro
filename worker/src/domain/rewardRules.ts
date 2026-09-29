import { isoSeconds } from './dayBoundary';

/**
 * Rewarded-ad rules (03 §7, 04 §9; BE14, RC35, RC56, RC57). Pure functions of
 * the stored state; `RewardService` gathers the inputs and enforces the same
 * cap and cooldown again inside the issuing SQL statement.
 */

/** A `cancelled` intent is still granted by an SSV callback within 2 minutes (03 §7.2). */
export const CANCEL_GRACE_SEC = 120;

export type IntentDenial =
  | { readonly kind: 'disabled' }
  | { readonly kind: 'capped'; readonly reason: 'cap' | 'cooldown'; readonly availableAt: string };

export interface IntentEligibilityInput {
  readonly now: Date;
  /** `rewarded.enabled`; `rewarded.dailyCap = 0` also means disabled (03 §8.2). */
  readonly enabled: boolean;
  readonly dailyCap: number;
  readonly cooldownSec: number;
  /** `MAX(daily_usage.rewarded_granted, device_daily_usage.rewarded_granted)` today. */
  readonly grantedToday: number;
  /** Latest `ad_rewards.granted_at` of the install (the cooldown anchor, RC57). */
  readonly lastGrantedAt: string | null;
  /** iOS `device_reused` on its registration day: rewarded starts tomorrow (03 §3.7). */
  readonly deviceReusedFirstDay: boolean;
  /** The next local midnight of the install (`free.resetsAt`). */
  readonly resetsAt: Date;
}

/**
 * Whether a new intent may be issued (03 §7.1): enabled, `grantedToday + 1 ≤
 * dailyCap`, and the cooldown since the **last grant** has passed. Returns
 * null when eligible. Cancelled or expired intents never count (RC57).
 */
export function intentDenial(input: IntentEligibilityInput): IntentDenial | null {
  if (!input.enabled || input.dailyCap <= 0) {
    return { kind: 'disabled' };
  }
  const nextDay = isoSeconds(input.resetsAt);
  if (input.deviceReusedFirstDay || input.grantedToday + 1 > input.dailyCap) {
    return { kind: 'capped', reason: 'cap', availableAt: nextDay };
  }
  const cooldownEnds = cooldownEndsAt(input.lastGrantedAt, input.cooldownSec);
  if (cooldownEnds !== null && cooldownEnds.getTime() > input.now.getTime()) {
    return { kind: 'capped', reason: 'cooldown', availableAt: isoSeconds(cooldownEnds) };
  }
  return null;
}

/** `last granted_at + rewarded.cooldownSec`, or null without a grant. */
export function cooldownEndsAt(lastGrantedAt: string | null, cooldownSec: number): Date | null {
  return lastGrantedAt === null ? null : new Date(Date.parse(lastGrantedAt) + cooldownSec * 1000);
}

/**
 * The SSV grant deadline of an intent cancelled at `now` (03 §7.2): the
 * earlier of its TTL and `now + CANCEL_GRACE_SEC`. `ad_rewards.expires_at`
 * of a `cancelled` row holds this deadline, so no extra column is needed.
 */
export function cancelledGrantDeadline(expiresAt: string, now: Date): string {
  const grace = new Date(now.getTime() + CANCEL_GRACE_SEC * 1000).toISOString();
  return grace < expiresAt ? grace : expiresAt;
}

/**
 * `ad_unit` against `rewarded.allowedAdUnitIds` (03 §7.1, §7.2). The client
 * sends the full ID (`ca-app-pub-…/1234567890`); an SSV callback carries the
 * ad unit's numeric part only, so both forms match an allowed full ID.
 */
export function adUnitAllowed(adUnit: string, allowed: readonly string[]): boolean {
  if (adUnit === '') {
    return false;
  }
  return allowed.some((id) => id === adUnit || id.slice(id.lastIndexOf('/') + 1) === adUnit);
}

export type SsvRejectReason =
  | 'malformed'
  | 'user_mismatch'
  | 'ad_unit'
  | 'unknown_intent'
  | 'expired'
  | 'cancelled'
  | 'already_granted'
  | 'rejected'
  | 'duplicate_txn';

export interface IntentState {
  readonly status: 'issued' | 'granted' | 'cancelled' | 'expired' | 'rejected';
  readonly expiresAt: string;
}

/**
 * Why an SSV callback cannot be granted for an intent in `state`, or null
 * when it can (03 §7.2 step 3). **No cap or cooldown re-check** (RC57): any
 * valid, unexpired, unused intent is granted, and a `cancelled` one while its
 * grace deadline has not passed.
 */
export function ssvIntentRejection(state: IntentState, now: Date): SsvRejectReason | null {
  const live = Date.parse(state.expiresAt) > now.getTime();
  switch (state.status) {
    case 'issued':
      return live ? null : 'expired';
    case 'cancelled':
      return live ? null : 'cancelled';
    case 'granted':
      return 'already_granted';
    case 'expired':
      return 'expired';
    case 'rejected':
      return 'rejected';
  }
}

/** The status the client sees (03 §7.3): an `issued` row past its TTL reads as `expired`. */
export function visibleStatus(state: IntentState, now: Date): IntentState['status'] {
  return state.status === 'issued' && Date.parse(state.expiresAt) <= now.getTime()
    ? 'expired'
    : state.status;
}
