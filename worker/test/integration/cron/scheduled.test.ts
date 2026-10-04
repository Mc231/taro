import {
  createExecutionContext,
  createScheduledController,
  waitOnExecutionContext,
} from 'cloudflare:test';
import { env } from 'cloudflare:workers';
import { describe, expect, it } from 'vitest';
import wranglerToml from '../../../wrangler.toml?raw';
import worker from '../../../src/index';
import type { Env } from '../../../src/env';
import { IdempotencyRepo } from '../../../src/repos/IdempotencyRepo';
import { UsedChallengeRepo } from '../../../src/repos/UsedChallengeRepo';
import {
  CRON_JOBS,
  CRON_TRIGGER,
  drain,
  groupsDue,
  JOB_GROUP,
  runJobs,
  runScheduled,
  type CronJob,
  type JobGroup,
} from '../../../src/scheduled';
import { createHarness, uniqueId } from '../../fakes/testDeps';

const bindings = env as unknown as Env;
const PAST = '2020-01-01T00:00:00.000Z';
const FUTURE = '2999-01-01T00:00:00.000Z';

async function seedIdempotency(expiresAt: string): Promise<string> {
  const key = uniqueId('cr0');
  await new IdempotencyRepo(bindings.DB).insert({
    installId: uniqueId('cr1'),
    route: 'DELETE /v1/installs/me',
    key,
    requestHash: 'h',
    createdAt: PAST,
    expiresAt,
  });
  return key;
}

async function seedChallenge(expiresAt: string): Promise<string> {
  const nonce = uniqueId('cr2');
  await new UsedChallengeRepo(bindings.DB).consume(nonce, expiresAt);
  return nonce;
}

async function exists(table: string, column: string, value: string): Promise<boolean> {
  const row = await bindings.DB.prepare(`SELECT 1 AS hit FROM ${table} WHERE ${column} = ?1`)
    .bind(value)
    .first();
  return row !== null;
}

/** Scheduled instants (UTC) of the single 15-minute trigger. */
const AT = {
  quarter: Date.UTC(2026, 9, 4, 10, 15),
  quarterLate: Date.UTC(2026, 9, 4, 10, 45),
  hourly: Date.UTC(2026, 9, 4, 11, 0),
  hourlyLate: Date.UTC(2026, 9, 4, 11, 14, 59, 999),
  nightly: Date.UTC(2026, 9, 4, 3, 30),
  midnight: Date.UTC(2026, 9, 4, 0, 0),
  threeOClock: Date.UTC(2026, 9, 4, 3, 0),
  afterNightly: Date.UTC(2026, 9, 4, 3, 45),
};

/** Records which group each job ran in, without touching D1. */
function recordingJobs(ran: string[]): Record<JobGroup, readonly CronJob[]> {
  const job = (name: string): CronJob => ({
    name,
    run: () => {
      ran.push(name);
      return Promise.resolve(0);
    },
  });
  return {
    [JOB_GROUP.quarterHourly]: [job('q')],
    [JOB_GROUP.hourly]: [job('h')],
    [JOB_GROUP.daily]: [job('d')],
  };
}

async function fire(scheduledTime: number, cron: string = CRON_TRIGGER): Promise<void> {
  const ctx = createExecutionContext();
  worker.scheduled(createScheduledController({ cron, scheduledTime }), bindings, ctx);
  await waitOnExecutionContext(ctx);
}

describe('scheduled() (03 §12)', () => {
  it('declares exactly one cron, */15, in every wrangler env', () => {
    expect(CRON_TRIGGER).toBe('*/15 * * * *');
    const declared = [...wranglerToml.matchAll(/^crons = (\[.*\])$/gm)].map(
      (m) => JSON.parse(m[1] ?? '[]') as string[],
    );
    expect(declared).toEqual([[CRON_TRIGGER], [CRON_TRIGGER], [CRON_TRIGGER]]);
    expect(CRON_JOBS[JOB_GROUP.hourly].map((job) => job.name)).toEqual([
      'refundUndeliveredReadings',
      'purgeIdempotencyKeys',
      'purgeUsedChallenges',
      'retryPendingAcks',
    ]);
    expect(CRON_JOBS[JOB_GROUP.quarterHourly].map((job) => job.name)).toContain(
      'expireRewardIntents',
    );
    expect(CRON_JOBS[JOB_GROUP.daily].map((job) => job.name)).toContain('voidedPurchasesBackstop');
  });

  it('groupsDue: hourly in minute 0-14, nightly only in [03:30, 03:45) UTC', () => {
    expect(groupsDue(AT.quarter)).toEqual(['quarterHourly']);
    expect(groupsDue(AT.quarterLate)).toEqual(['quarterHourly']);
    expect(groupsDue(AT.hourly)).toEqual(['quarterHourly', 'hourly']);
    expect(groupsDue(AT.hourlyLate)).toEqual(['quarterHourly', 'hourly']);
    expect(groupsDue(AT.midnight)).toEqual(['quarterHourly', 'hourly']);
    expect(groupsDue(AT.threeOClock)).toEqual(['quarterHourly', 'hourly']);
    expect(groupsDue(AT.nightly)).toEqual(['quarterHourly', 'daily']);
    expect(groupsDue(AT.afterNightly)).toEqual(['quarterHourly']);
    expect(groupsDue(Date.UTC(2026, 9, 4, 4, 30))).toEqual(['quarterHourly']);
  });

  it('runs each hourly job once per hour and each nightly job once per day', () => {
    const day = Date.UTC(2026, 9, 4);
    const runs = Array.from({ length: 96 }, (_, i) => groupsDue(day + i * 15 * 60_000));
    expect(runs.filter((g) => g.includes('quarterHourly'))).toHaveLength(96);
    expect(runs.filter((g) => g.includes('hourly'))).toHaveLength(24);
    expect(runs.filter((g) => g.includes('daily'))).toHaveLength(1);
  });

  it('a quarter-hour run performs only the 15-minute jobs', async () => {
    const ran: string[] = [];
    const h = createHarness();
    await runScheduled(h.deps, CRON_TRIGGER, AT.quarter, recordingJobs(ran));
    expect(ran).toEqual(['q']);
  });

  it('the hourly slot performs the 15-minute and hourly jobs', async () => {
    const ran: string[] = [];
    const h = createHarness();
    await runScheduled(h.deps, CRON_TRIGGER, AT.hourly, recordingJobs(ran));
    expect(ran).toEqual(['q', 'h']);
  });

  it('the nightly slot performs the 15-minute and nightly jobs (its hour ran hourly at 03:00)', async () => {
    const ran: string[] = [];
    const h = createHarness();
    await runScheduled(h.deps, CRON_TRIGGER, AT.nightly, recordingJobs(ran));
    expect(ran).toEqual(['q', 'd']);
    const logged = h.logger.find('cron_job').map((e) => e.fields['group']);
    expect(logged).toEqual(['quarterHourly', 'daily']);
  });

  it('the hourly slot purges expired idempotency keys and used challenges via the entrypoint', async () => {
    const expiredKey = await seedIdempotency(PAST);
    const liveKey = await seedIdempotency(FUTURE);
    const expiredNonce = await seedChallenge(PAST);
    const liveNonce = await seedChallenge(FUTURE);

    await fire(AT.hourly);

    expect(await exists('idempotency_keys', 'key', expiredKey)).toBe(false);
    expect(await exists('idempotency_keys', 'key', liveKey)).toBe(true);
    expect(await exists('used_challenges', 'nonce', expiredNonce)).toBe(false);
    expect(await exists('used_challenges', 'nonce', liveNonce)).toBe(true);
  });

  it('quarter-hour and nightly runs do not purge idempotency keys', async () => {
    const expiredKey = await seedIdempotency(PAST);
    await fire(AT.quarter);
    await fire(AT.nightly);
    expect(await exists('idempotency_keys', 'key', expiredKey)).toBe(true);
    const h = createHarness();
    await runScheduled(h.deps, CRON_TRIGGER, AT.nightly);
    expect(h.logger.find('cron_job').map((e) => e.fields['job'])).not.toContain(
      'purgeIdempotencyKeys',
    );
  });

  it('logs each job with its group and count, and an unknown cron as a warning', async () => {
    await seedChallenge(PAST);
    const h = createHarness();
    await runJobs(h.deps, JOB_GROUP.hourly);
    const logged = h.logger.find('cron_job').map((e) => e.fields);
    expect(logged.map((f) => f['job'])).toEqual([
      'refundUndeliveredReadings',
      'purgeIdempotencyKeys',
      'purgeUsedChallenges',
      'retryPendingAcks',
    ]);
    expect(logged[2]).toMatchObject({ group: JOB_GROUP.hourly, latencyMs: 0 });
    expect(Number(logged[2]?.['count'])).toBeGreaterThanOrEqual(1);

    const ran: string[] = [];
    await runScheduled(h.deps, '7 * * * *', AT.hourly, recordingJobs(ran));
    expect(ran).toEqual([]);
    expect(h.logger.find('cron_unknown').map((e) => e.fields)).toEqual([{ cron: '7 * * * *' }]);
  });

  it('keeps running the other jobs when one throws', async () => {
    const h = createHarness();
    const ran: string[] = [];
    const ok: CronJob = {
      name: 'ok',
      run: () => {
        ran.push('ok');
        return Promise.resolve(1);
      },
    };
    const boom: CronJob = { name: 'boom', run: () => Promise.reject(new RangeError('x')) };
    // eslint-disable-next-line @typescript-eslint/prefer-promise-reject-errors -- non-Error rejection path
    const odd: CronJob = { name: 'odd', run: () => Promise.reject('x') };
    const jobs: Record<JobGroup, readonly CronJob[]> = {
      [JOB_GROUP.quarterHourly]: [boom, odd, ok],
      [JOB_GROUP.hourly]: [],
      [JOB_GROUP.daily]: [],
    };
    await runJobs(h.deps, JOB_GROUP.quarterHourly, jobs);
    expect(ran).toEqual(['ok']);
    expect(h.logger.find('cron_job_failed').map((e) => e.fields)).toEqual([
      { group: JOB_GROUP.quarterHourly, job: 'boom', error: 'RangeError' },
      { group: JOB_GROUP.quarterHourly, job: 'odd', error: 'unknown' },
    ]);
  });

  it('drains in bounded batches and stops at maxBatches', async () => {
    for (let i = 0; i < 5; i++) {
      await seedIdempotency(PAST);
    }
    const h = createHarness();
    const batches: number[] = [];
    await runJobs(
      h.deps,
      JOB_GROUP.hourly,
      {
        [JOB_GROUP.quarterHourly]: [],
        [JOB_GROUP.hourly]: [
          {
            name: 'counted',
            run: (deps, now, limits) =>
              drain(limits, async (limit) => {
                const n = await new IdempotencyRepo(deps.db).purgeExpired(now.toISOString(), limit);
                batches.push(n);
                return n;
              }),
          },
        ],
        [JOB_GROUP.daily]: [],
      },
      { batchSize: 2, maxBatches: 2 },
    );
    expect(batches).toEqual([2, 2]);

    const counts = [3, 3, 1, 9];
    const steps: number[] = [];
    expect(
      await drain({ batchSize: 3, maxBatches: 10 }, (limit) => {
        steps.push(limit);
        return Promise.resolve(counts.shift() ?? 0);
      }),
    ).toBe(7);
    expect(steps).toEqual([3, 3, 3]);
  });
});
