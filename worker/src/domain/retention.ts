import { addDays } from './dayBoundary';

/**
 * Retention periods (03 §13, the single source; RC22, RC37, RC51). The
 * nightly cron deletes (or pseudonymises) what is older.
 */
export const RETENTION = {
  /** `readings` metadata, by `created_at`. */
  readingsMonths: 13,
  /** `ad_rewards` intents, by `issued_at`. */
  adRewardsMonths: 13,
  /** `daily_usage` and `device_daily_usage`, by `local_date`. */
  usageDays: 90,
  /** `reading_reports` (`expires_at = created_at + 90 days`, RC22). */
  reportDays: 90,
  /** Installs with no activity and balance 0 are pseudonymised. */
  inactiveInstallMonths: 24,
} as const;

/**
 * `now` minus `months` calendar months (UTC). A day that does not exist in
 * the target month is clamped to its last day (e.g. 31 Mar − 1 month = 28/29 Feb).
 */
export function monthsBefore(now: Date, months: number): string {
  const y = now.getUTCFullYear();
  const m = now.getUTCMonth() - months;
  const lastDay = new Date(Date.UTC(y, m + 1, 0)).getUTCDate();
  const shifted = new Date(now.getTime());
  shifted.setUTCFullYear(y, m, Math.min(now.getUTCDate(), lastDay));
  return shifted.toISOString();
}

/** The UTC calendar date `days` before `now` (`yyyy-mm-dd`). */
export function daysBeforeDate(now: Date, days: number): string {
  return addDays(now.toISOString().slice(0, 10), -days);
}

/** `expires_at` of a report filed at `now` (`now + 90 days`). */
export function reportExpiry(now: Date): string {
  return new Date(now.getTime() + RETENTION.reportDays * 86_400_000).toISOString();
}
