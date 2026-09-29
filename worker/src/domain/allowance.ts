import type { RuntimeConfig } from '../config/schema';
import type { DailyUsageRow } from '../repos/DailyUsageRepo';
import type { DeviceUsageRow } from '../repos/DeviceUsageRepo';
import type { InstallStatus } from '../repos/InstallRepo';
import type { Balances } from '../repos/LedgerRepo';
import type { BudgetTier } from './budget';
import { isoSeconds, localDate, nextResetUtc } from './dayBoundary';
import type { Trust } from './types';

/**
 * `BalanceDto` (03 §5.1; RC6, RC64, RC66, RC67, RC74) as a pure function of
 * the install's stored state, the active config and the budget tier.
 * `BalanceService` gathers the inputs in one D1 batch.
 */

export type CanReadReason = 'noCredits' | 'dailyLimit' | 'lowTrustCap' | 'readingsPaused';
export type NextSource = 'free' | 'bonus' | 'paid';
export type PurchasesBlockedReason = 'blocked' | 'refundDebt' | 'storeDisabled';

export interface FreeAllowanceDto {
  readonly limit: number;
  readonly used: number;
  readonly remaining: number;
  readonly localDate: string;
  readonly resetsAt: string;
  readonly timezone: string;
  readonly paused: boolean;
}

export interface RewardedStatusDto {
  readonly enabled: boolean;
  readonly amount: number;
  readonly dailyCap: number;
  readonly grantedToday: number;
  readonly available: boolean;
  readonly cooldownEndsAt: string | null;
}

export interface BalanceDto {
  readonly free: FreeAllowanceDto;
  readonly bonus: number;
  readonly paid: number;
  readonly canRead: boolean;
  readonly canReadReason: CanReadReason | null;
  readonly nextSource: NextSource | null;
  readonly rewarded: RewardedStatusDto;
  readonly paidBlocked: boolean;
  readonly purchasesAllowed: boolean;
  readonly purchasesBlockedReason: PurchasesBlockedReason | null;
  readonly ledgerVersion: number;
  readonly serverTime: string;
}

/** The install columns the balance depends on. */
export interface AllowanceInstall {
  readonly trust: Trust;
  readonly status: InstallStatus;
  /** iOS DeviceCheck `bit0` was already set at registration (03 §3.7). */
  readonly deviceReused: boolean;
  readonly createdAt: string;
  readonly stateVersion: number;
}

export interface AllowanceInput {
  readonly now: Date;
  readonly timezone: string;
  readonly install: AllowanceInstall;
  /** Today's `daily_usage` row (null before the lazy snapshot). */
  readonly usage: DailyUsageRow | null;
  /** Today's `device_daily_usage` row (Android with a device key only). */
  readonly device: DeviceUsageRow | null;
  readonly balances: Balances;
  /** Latest `ad_rewards.granted_at` of the install (cooldown anchor, RC57). */
  readonly lastGrantedAt: string | null;
  readonly budgetTier: BudgetTier;
  /** Low-trust free readings per IP prefix are used up today (03 §2.4). */
  readonly lowTrustIpCapReached: boolean;
  readonly config: RuntimeConfig;
}

/** `readings.freeDaily`, capped by `abuse.lowTrust.freeDaily` for low trust (03 §5.1). */
export function currentFreeDaily(trust: Trust, config: RuntimeConfig): number {
  const freeDaily = config['readings.freeDaily'];
  return trust === 'low' ? Math.min(freeDaily, config['abuse.lowTrust.freeDaily']) : freeDaily;
}

/** An iOS `device_reused` install gets free readings and rewarded ads from its next local day. */
function reusedDeviceFirstDay(input: AllowanceInput, today: string): boolean {
  return (
    input.install.deviceReused &&
    localDate(new Date(input.install.createdAt), input.timezone) === today
  );
}

interface FreeState {
  readonly limit: number;
  readonly used: number;
  /** Before the low-trust IP cap (which only `canRead` / `nextSource` apply). */
  readonly remaining: number;
  /** A high-trust install would still have a free reading: low trust is the reason. */
  readonly lowTrustLimited: boolean;
}

function freeState(input: AllowanceInput, today: string): FreeState {
  const current = currentFreeDaily(input.install.trust, input.config);
  const limit = Math.max(input.usage?.freeLimit ?? 0, current);
  const used = input.usage?.freeUsed ?? 0;
  let remaining = Math.max(0, limit - used);
  if (input.device !== null) {
    remaining = Math.min(remaining, Math.max(0, current - input.device.freeUsed));
  }
  if (reusedDeviceFirstDay(input, today)) {
    remaining = 0;
  }
  const highTrustRemaining = Math.max(0, input.config['readings.freeDaily'] - used);
  const lowTrustLimited =
    input.install.trust === 'low' &&
    (input.lowTrustIpCapReached || (remaining === 0 && highTrustRemaining > 0));
  return { limit, used, remaining, lowTrustLimited };
}

/** Free readings left before the low-trust IP cap; `BalanceService` peeks the cap only if > 0. */
export function freeRemaining(input: AllowanceInput): number {
  return freeState(input, localDate(input.now, input.timezone)).remaining;
}

function rewardedStatus(input: AllowanceInput, today: string): RewardedStatusDto {
  const { config, now } = input;
  const enabled = config['rewarded.enabled'];
  const dailyCap = config['rewarded.dailyCap'];
  const grantedToday = Math.max(
    input.usage?.rewardedGranted ?? 0,
    input.device?.rewardedGranted ?? 0,
  );
  let cooldownEndsAt: string | null = null;
  if (input.lastGrantedAt !== null) {
    const ends = Date.parse(input.lastGrantedAt) + config['rewarded.cooldownSec'] * 1000;
    if (ends > now.getTime()) {
      cooldownEndsAt = isoSeconds(new Date(ends));
    }
  }
  const available =
    enabled &&
    grantedToday < dailyCap &&
    cooldownEndsAt === null &&
    !reusedDeviceFirstDay(input, today);
  return {
    enabled,
    amount: config['rewarded.amount'],
    dailyCap,
    grantedToday,
    available,
    cooldownEndsAt,
  };
}

function purchases(input: AllowanceInput): {
  allowed: boolean;
  reason: PurchasesBlockedReason | null;
} {
  let reason: PurchasesBlockedReason | null = null;
  if (input.install.status === 'blocked') {
    reason = 'blocked';
  } else if (input.balances.paid < 0) {
    reason = 'refundDebt';
  } else if (!input.config['store.enabled']) {
    reason = 'storeDisabled';
  }
  return { allowed: reason === null, reason };
}

interface ReadDecision {
  readonly canRead: boolean;
  readonly canReadReason: CanReadReason | null;
  readonly nextSource: NextSource | null;
}

/**
 * `canRead` / `canReadReason` / `nextSource` (RC44 order on the server side):
 * kill switch or hard budget stop → `readingsPaused`; per-day cap →
 * `dailyLimit` (never a paywall, RC74); then free (unless paused by the
 * free-stop tier or the low-trust caps), bonus, paid; with nothing left the
 * reason says why (free paused → `readingsPaused`, low trust → `lowTrustCap`,
 * otherwise `noCredits`).
 */
function readDecision(input: AllowanceInput, free: FreeState, paused: boolean): ReadDecision {
  const denied = (reason: CanReadReason): ReadDecision => ({
    canRead: false,
    canReadReason: reason,
    nextSource: null,
  });
  const allowed = (source: NextSource): ReadDecision => ({
    canRead: true,
    canReadReason: null,
    nextSource: source,
  });
  const { config, balances } = input;
  if (!config['readings.enabled'] || input.budgetTier === 'hard') {
    return denied('readingsPaused');
  }
  if ((input.usage?.readingsTotal ?? 0) >= config['readings.maxPerInstallPerDay']) {
    return denied('dailyLimit');
  }
  const freeUsable = free.remaining > 0 && !input.lowTrustIpCapReached;
  if (freeUsable && !paused) {
    return allowed('free');
  }
  if (balances.bonus > 0) {
    return allowed('bonus');
  }
  if (balances.paid > 0) {
    return allowed('paid');
  }
  if (freeUsable) {
    return denied('readingsPaused');
  }
  return denied(free.lowTrustLimited ? 'lowTrustCap' : 'noCredits');
}

export function computeBalance(input: AllowanceInput): BalanceDto {
  const today = localDate(input.now, input.timezone);
  const free = freeState(input, today);
  const paused = input.budgetTier === 'freeStop';
  const decision = readDecision(input, free, paused);
  const purchase = purchases(input);
  return {
    free: {
      limit: free.limit,
      used: free.used,
      remaining: input.lowTrustIpCapReached ? 0 : free.remaining,
      localDate: today,
      resetsAt: isoSeconds(nextResetUtc(input.now, input.timezone)),
      timezone: input.timezone,
      paused,
    },
    bonus: input.balances.bonus,
    paid: input.balances.paid,
    ...decision,
    rewarded: rewardedStatus(input, today),
    paidBlocked: input.balances.paid < 0,
    purchasesAllowed: purchase.allowed,
    purchasesBlockedReason: purchase.reason,
    ledgerVersion: input.install.stateVersion,
    serverTime: isoSeconds(input.now),
  };
}
