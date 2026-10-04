import type { Deps } from './deps';
import { daysBeforeDate, monthsBefore, RETENTION } from './domain/retention';
import { DailyUsageRepo } from './repos/DailyUsageRepo';
import { DeviceUsageRepo } from './repos/DeviceUsageRepo';
import { IdempotencyRepo } from './repos/IdempotencyRepo';
import { InstallRepo } from './repos/InstallRepo';
import { ReadingRepo } from './repos/ReadingRepo';
import { ReportRepo } from './repos/ReportRepo';
import { RewardRepo } from './repos/RewardRepo';
import { UsedChallengeRepo } from './repos/UsedChallengeRepo';
import { AlertService } from './services/AlertService';
import { BalanceService } from './services/BalanceService';
import { BudgetService, isolateDauCache } from './services/BudgetService';
import { PurchaseService } from './services/PurchaseService';
import { UNDELIVERED_AFTER_MS } from './services/ReadingService';
import { WebhookService } from './services/WebhookService';

/**
 * The one cron trigger (03 §12, GLOSSARY §6.1; Workers Free allows 5 crons per
 * account, so each env declares a single 15-minute cron). It must equal
 * `[env.*.triggers] crons` in `wrangler.toml` (a test compares them). The
 * hourly and nightly job groups ride on it, chosen by `scheduledTime`
 * (`groupsDue`).
 */
export const CRON_TRIGGER = '*/15 * * * *';

/** Job groups of the single trigger (03 §12). */
export const JOB_GROUP = {
  /** Every run: budget tiers, stale holds, intent expiry, `AlertService.check` (Phase 7/8). */
  quarterHourly: 'quarterHourly',
  /** Run in minute 0–14 of each UTC hour: undelivered refunds, idempotency + challenge purge, Google acks. */
  hourly: 'hourly',
  /** Run in [03:30, 03:45) UTC: Voided Purchases backstop, retention purge, daily summary (Phase 8). */
  daily: 'daily',
} as const;

export type JobGroup = (typeof JOB_GROUP)[keyof typeof JOB_GROUP];

const QUARTER_MINUTES = 15;
const NIGHTLY_HOUR_UTC = 3;
const NIGHTLY_MINUTE_UTC = 30;

/**
 * The groups due for a run scheduled at `scheduledTime` (epoch ms; Cloudflare
 * passes the cron's scheduled instant, not the start time). Each 15-minute
 * window holds exactly one run, so the hourly group runs once per hour (the
 * :00 run) and the nightly group once per day (the 03:30 UTC run).
 */
export function groupsDue(scheduledTime: number): JobGroup[] {
  const at = new Date(scheduledTime);
  const minute = at.getUTCMinutes();
  const groups: JobGroup[] = [JOB_GROUP.quarterHourly];
  if (minute < QUARTER_MINUTES) {
    groups.push(JOB_GROUP.hourly);
  }
  if (
    at.getUTCHours() === NIGHTLY_HOUR_UTC &&
    minute >= NIGHTLY_MINUTE_UTC &&
    minute < NIGHTLY_MINUTE_UTC + QUARTER_MINUTES
  ) {
    groups.push(JOB_GROUP.daily);
  }
  return groups;
}

/** Rows per bounded batch and batches per job run (03 §12: `LIMIT 500` loops within CPU limits). */
export interface BatchLimits {
  readonly batchSize: number;
  readonly maxBatches: number;
}

export const DEFAULT_BATCH_LIMITS: BatchLimits = { batchSize: 500, maxBatches: 20 };

/** One idempotent, bounded job. Returns the number of rows it touched. */
export interface CronJob {
  readonly name: string;
  run(deps: Deps, now: Date, limits: BatchLimits): Promise<number>;
}

/**
 * Repeats `step(batchSize)` until a batch comes back short or `maxBatches`
 * ran; the next cron run picks up whatever is left.
 */
export async function drain(
  limits: BatchLimits,
  step: (limit: number) => Promise<number>,
): Promise<number> {
  let total = 0;
  for (let batch = 0; batch < limits.maxBatches; batch++) {
    const changed = await step(limits.batchSize);
    total += changed;
    if (changed < limits.batchSize) {
      break;
    }
  }
  return total;
}

/** `idempotency_keys` past `expires_at` (7-day TTL, 03 §2.3). */
export const purgeIdempotencyKeys: CronJob = {
  name: 'purgeIdempotencyKeys',
  run: (deps, now, limits) => {
    const repo = new IdempotencyRepo(deps.db);
    return drain(limits, (limit) => repo.purgeExpired(now.toISOString(), limit));
  },
};

/** `used_challenges` past expiry (5-minute challenges, 03 §3.2). */
export const purgeUsedChallenges: CronJob = {
  name: 'purgeUsedChallenges',
  run: (deps, now, limits) => {
    const repo = new UsedChallengeRepo(deps.db);
    return drain(limits, (limit) => repo.purgeExpired(now.toISOString(), limit));
  },
};

/** `ad_rewards` still `issued` past `expires_at` → `expired` (03 §7.3, §12). */
export const expireRewardIntents: CronJob = {
  name: 'expireRewardIntents',
  run: (deps, now, limits) => {
    const repo = new RewardRepo(deps.db);
    return drain(limits, (limit) => repo.expireDue(now.toISOString(), limit));
  },
};

/**
 * Failed Google acknowledgements (`ack:pending:*`, 03 §6.3 step 4, §12,
 * RC10): re-checked with the store and acknowledged, `batchSize` markers per
 * run.
 */
export const retryPendingAcks: CronJob = {
  name: 'retryPendingAcks',
  run: (deps, _now, limits) => new PurchaseService(deps).retryPendingAcks(limits.batchSize),
};

/**
 * Google Voided Purchases backstop (03 §6.4, §12): the last two days of
 * `voidedpurchases.list`, revoking anything the RTDN missed. At most
 * `maxBatches` pages per run.
 */
export const voidedPurchasesBackstop: CronJob = {
  name: 'voidedPurchasesBackstop',
  run: (deps, now, limits) => new WebhookService(deps).voidedBackstop(now, limits.maxBatches),
};

/**
 * Pre-draw holds past `hold_expires_at` that were never submitted (03 §9.0,
 * §12): refunded (`expired_hold`), metric `hold_abandoned`. The refund is a
 * compare-and-set, so a hold renewed or used in the meantime is untouched.
 */
export const releaseExpiredHolds: CronJob = {
  name: 'releaseExpiredHolds',
  run: (deps, now, limits) => {
    const readings = new ReadingRepo(deps.db);
    const balance = new BalanceService(deps);
    return drain(limits, async (limit) => {
      const rows = await readings.expiredHolds(now.toISOString(), limit);
      for (const row of rows) {
        await balance.refund({ readingId: row.id, reason: 'expired', attempt: row.attempt });
      }
      return rows.length;
    });
  },
};

/**
 * `generating` rows past `ai.deadlineMs + 60 s` (isolate eviction, deploy
 * cut-over; 03 §9.1, RC52): refunded, `failed`, `error_code='abandoned'`,
 * metric `hold_abandoned`. A late commit re-takes the hold (03 §5.3 step 4).
 */
export const refundStaleHolds: CronJob = {
  name: 'refundStaleHolds',
  run: (deps, now, limits) => {
    const readings = new ReadingRepo(deps.db);
    const balance = new BalanceService(deps);
    return drain(limits, async (limit) => {
      const rows = await readings.staleGenerating(now.toISOString(), limit);
      for (const row of rows) {
        const result = await balance.refund({
          readingId: row.id,
          reason: 'abandoned',
          attempt: row.attempt,
        });
        if (result.refunded) {
          await readings.setErrorCode(row.id, 'abandoned');
        }
      }
      return rows.length;
    });
  },
};

/**
 * Completed readings never acknowledged within 7 days (RC51, 03 §9.1):
 * refunded once (`reading_undelivered`, `expired_refunded`), metric
 * `reading_undelivered_refund`.
 */
export const refundUndeliveredReadings: CronJob = {
  name: 'refundUndeliveredReadings',
  run: (deps, now, limits) => {
    const readings = new ReadingRepo(deps.db);
    const balance = new BalanceService(deps);
    const cutoff = new Date(now.getTime() - UNDELIVERED_AFTER_MS).toISOString();
    return drain(limits, async (limit) => {
      const rows = await readings.undelivered(cutoff, limit);
      for (const row of rows) {
        await balance.refundUndelivered(row.id);
      }
      return rows.length;
    });
  },
};

/** `BudgetService.check` (03 §10.2, §12): the budget tier alerts. */
export const budgetCheck: CronJob = {
  name: 'budgetCheck',
  run: async (deps, now) =>
    new BudgetService(deps.db, isolateDauCache, { alerter: deps.alerter }).check(
      await deps.config.snapshot(),
      now,
    ),
};

/** `AlertService.check` (03 §14.1): 5xx rate, `reading_failed` rate, webhook signature failures. */
export const alertCheck: CronJob = {
  name: 'alertCheck',
  run: async (deps) => new AlertService(deps).check(await deps.config.snapshot()),
};

/** Retention (03 §13, RC22): `reading_reports` past `expires_at` (90 days). */
export const purgeReadingReports: CronJob = {
  name: 'purgeReadingReports',
  run: (deps, now, limits) => {
    const repo = new ReportRepo(deps.db);
    return drain(limits, (limit) => repo.purgeExpired(now.toISOString(), limit));
  },
};

/** Retention (03 §13): `readings` metadata older than 13 months (rows a live report references stay). */
export const purgeReadings: CronJob = {
  name: 'purgeReadings',
  run: (deps, now, limits) => {
    const repo = new ReadingRepo(deps.db);
    const cutoff = monthsBefore(now, RETENTION.readingsMonths);
    return drain(limits, (limit) => repo.purgeCreatedBefore(cutoff, limit));
  },
};

/** Retention (03 §13): `ad_rewards` issued more than 13 months ago. */
export const purgeAdRewards: CronJob = {
  name: 'purgeAdRewards',
  run: (deps, now, limits) => {
    const repo = new RewardRepo(deps.db);
    const cutoff = monthsBefore(now, RETENTION.adRewardsMonths);
    return drain(limits, (limit) => repo.purgeIssuedBefore(cutoff, limit));
  },
};

/** Retention (03 §13): `daily_usage` rows older than 90 days. */
export const purgeDailyUsage: CronJob = {
  name: 'purgeDailyUsage',
  run: (deps, now, limits) => {
    const repo = new DailyUsageRepo(deps.db);
    const cutoff = daysBeforeDate(now, RETENTION.usageDays);
    return drain(limits, (limit) => repo.purgeBefore(cutoff, limit));
  },
};

/** Retention (03 §13, RC53): `device_daily_usage` rows older than 90 days. */
export const purgeDeviceUsage: CronJob = {
  name: 'purgeDeviceUsage',
  run: (deps, now, limits) => {
    const repo = new DeviceUsageRepo(deps.db);
    const cutoff = daysBeforeDate(now, RETENTION.usageDays);
    return drain(limits, (limit) => repo.purgeBefore(cutoff, limit));
  },
};

/** Retention (03 §13, RC37): installs inactive for 24 months with balance 0 → pseudonymised. */
export const pseudonymiseInactiveInstalls: CronJob = {
  name: 'pseudonymiseInactiveInstalls',
  run: (deps, now, limits) => {
    const repo = new InstallRepo(deps.db);
    const cutoff = monthsBefore(now, RETENTION.inactiveInstallMonths);
    return drain(limits, (limit) => repo.pseudonymiseInactive(cutoff, limit));
  },
};

/** The nightly retention purge (03 §12, §13), reports before the readings they reference. */
export const RETENTION_JOBS: readonly CronJob[] = [
  purgeReadingReports,
  purgeReadings,
  purgeAdRewards,
  purgeDailyUsage,
  purgeDeviceUsage,
  pseudonymiseInactiveInstalls,
];

/**
 * The job table. Phase 7 registers `releaseExpiredHolds`, `refundStaleHolds`,
 * intent expiry, Google acknowledgements and the Voided Purchases backstop;
 * Phase 8 `BudgetService.check`, `AlertService.check`,
 * `refundUndeliveredReadings`, the retention purge and the daily summary.
 */
export const CRON_JOBS: Readonly<Record<JobGroup, readonly CronJob[]>> = {
  [JOB_GROUP.quarterHourly]: [
    releaseExpiredHolds,
    refundStaleHolds,
    expireRewardIntents,
    budgetCheck,
    alertCheck,
  ],
  [JOB_GROUP.hourly]: [
    refundUndeliveredReadings,
    purgeIdempotencyKeys,
    purgeUsedChallenges,
    retryPendingAcks,
  ],
  [JOB_GROUP.daily]: [voidedPurchasesBackstop, ...RETENTION_JOBS],
};

/**
 * `scheduled()` (03 §12): every group `groupsDue(scheduledTime)` names, in
 * order quarter-hourly, hourly, nightly. Any other cron is logged and ignored.
 */
export async function runScheduled(
  deps: Deps,
  cron: string,
  scheduledTime: number,
  jobs: Readonly<Record<JobGroup, readonly CronJob[]>> = CRON_JOBS,
  limits: BatchLimits = DEFAULT_BATCH_LIMITS,
): Promise<void> {
  if (cron !== CRON_TRIGGER) {
    deps.logger.log('warn', 'cron_unknown', { cron });
    return;
  }
  for (const group of groupsDue(scheduledTime)) {
    await runJobs(deps, group, jobs, limits);
  }
}

/**
 * Runs the jobs of `group` one after another. A job that throws is logged
 * and does not stop the others; each job is idempotent, so the next run
 * retries it.
 */
export async function runJobs(
  deps: Deps,
  group: JobGroup,
  jobs: Readonly<Record<JobGroup, readonly CronJob[]>> = CRON_JOBS,
  limits: BatchLimits = DEFAULT_BATCH_LIMITS,
): Promise<void> {
  for (const job of jobs[group]) {
    const started = deps.clock.now();
    try {
      const count = await job.run(deps, started, limits);
      deps.logger.log('info', 'cron_job', {
        group,
        job: job.name,
        count,
        latencyMs: deps.clock.now().getTime() - started.getTime(),
      });
    } catch (err) {
      deps.logger.log('error', 'cron_job_failed', {
        group,
        job: job.name,
        error: err instanceof Error ? err.name : 'unknown',
      });
    }
  }
}
