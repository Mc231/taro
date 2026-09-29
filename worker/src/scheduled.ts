import type { Deps } from './deps';
import { IdempotencyRepo } from './repos/IdempotencyRepo';
import { RewardRepo } from './repos/RewardRepo';
import { UsedChallengeRepo } from './repos/UsedChallengeRepo';
import { PurchaseService } from './services/PurchaseService';
import { WebhookService } from './services/WebhookService';

/**
 * Cron triggers (03 §12, GLOSSARY §6.1). The expressions must equal
 * `[env.*.triggers] crons` in `wrangler.toml` (a test compares them).
 */
export const CRON = {
  /** Budget tiers, stale holds, intent expiry, `AlertService.check` (Phase 7/8). */
  quarterHourly: '*/15 * * * *',
  /** Undelivered-reading refunds (Phase 8), idempotency + challenge purge, Google acks (Phase 7). */
  hourly: '7 * * * *',
  /** Voided Purchases backstop (Phase 7), retention purge, daily summary (Phase 8). */
  daily: '30 3 * * *',
} as const;

export type CronExpression = (typeof CRON)[keyof typeof CRON];

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
 * The job table. Phase 7 registers `releaseExpiredHolds`, `refundStaleHolds`,
 * intent expiry, Google acknowledgements and the Voided Purchases backstop;
 * Phase 8 `BudgetService.check`, `AlertService.check`,
 * `refundUndeliveredReadings`, the retention purge and the daily summary.
 */
export const CRON_JOBS: Readonly<Record<CronExpression, readonly CronJob[]>> = {
  [CRON.quarterHourly]: [expireRewardIntents],
  [CRON.hourly]: [purgeIdempotencyKeys, purgeUsedChallenges, retryPendingAcks],
  [CRON.daily]: [voidedPurchasesBackstop],
};

function isCron(cron: string): cron is CronExpression {
  return Object.values<string>(CRON).includes(cron);
}

/**
 * `scheduled()` (03 §12): runs the jobs of `cron` one after another. A job
 * that throws is logged and does not stop the others; each job is
 * idempotent, so the next run retries it.
 */
export async function runScheduled(
  deps: Deps,
  cron: string,
  jobs: Readonly<Record<CronExpression, readonly CronJob[]>> = CRON_JOBS,
  limits: BatchLimits = DEFAULT_BATCH_LIMITS,
): Promise<void> {
  if (!isCron(cron)) {
    deps.logger.log('warn', 'cron_unknown', { cron });
    return;
  }
  for (const job of jobs[cron]) {
    const started = deps.clock.now();
    try {
      const count = await job.run(deps, started, limits);
      deps.logger.log('info', 'cron_job', {
        cron,
        job: job.name,
        count,
        latencyMs: deps.clock.now().getTime() - started.getTime(),
      });
    } catch (err) {
      deps.logger.log('error', 'cron_job_failed', {
        cron,
        job: job.name,
        error: err instanceof Error ? err.name : 'unknown',
      });
    }
  }
}
