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
  CRON,
  CRON_JOBS,
  drain,
  runScheduled,
  type CronExpression,
  type CronJob,
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

describe('scheduled() (03 §12)', () => {
  it('declares exactly the three 03 §12 crons in every wrangler env', () => {
    expect(Object.values(CRON)).toEqual(['*/15 * * * *', '7 * * * *', '30 3 * * *']);
    const declared = [...wranglerToml.matchAll(/^crons = (\[.*\])$/gm)].map(
      (m) => JSON.parse(m[1] ?? '[]') as string[],
    );
    expect(declared).toEqual([Object.values(CRON), Object.values(CRON), Object.values(CRON)]);
    expect(CRON_JOBS[CRON.hourly].map((job) => job.name)).toEqual([
      'purgeIdempotencyKeys',
      'purgeUsedChallenges',
      'retryPendingAcks',
    ]);
    expect(CRON_JOBS[CRON.quarterHourly].map((job) => job.name)).toContain('expireRewardIntents');
    expect(CRON_JOBS[CRON.daily].map((job) => job.name)).toEqual(['voidedPurchasesBackstop']);
  });

  it('the hourly trigger purges expired idempotency keys and used challenges via the entrypoint', async () => {
    const expiredKey = await seedIdempotency(PAST);
    const liveKey = await seedIdempotency(FUTURE);
    const expiredNonce = await seedChallenge(PAST);
    const liveNonce = await seedChallenge(FUTURE);

    const ctx = createExecutionContext();
    worker.scheduled(
      createScheduledController({ cron: CRON.hourly, scheduledTime: Date.now() }),
      bindings,
      ctx,
    );
    await waitOnExecutionContext(ctx);

    expect(await exists('idempotency_keys', 'key', expiredKey)).toBe(false);
    expect(await exists('idempotency_keys', 'key', liveKey)).toBe(true);
    expect(await exists('used_challenges', 'nonce', expiredNonce)).toBe(false);
    expect(await exists('used_challenges', 'nonce', liveNonce)).toBe(true);
  });

  it('the other triggers do not purge idempotency keys', async () => {
    const expiredKey = await seedIdempotency(PAST);
    const h = createHarness();
    await runScheduled(h.deps, CRON.quarterHourly);
    await runScheduled(h.deps, CRON.daily);
    expect(await exists('idempotency_keys', 'key', expiredKey)).toBe(true);
    expect(h.logger.find('cron_job').map((e) => e.fields['job'])).not.toContain(
      'purgeIdempotencyKeys',
    );
  });

  it('logs each job with its count, and an unknown cron as a warning', async () => {
    await seedChallenge(PAST);
    const h = createHarness();
    await runScheduled(h.deps, CRON.hourly);
    const logged = h.logger.find('cron_job').map((e) => e.fields);
    expect(logged.map((f) => f['job'])).toEqual([
      'purgeIdempotencyKeys',
      'purgeUsedChallenges',
      'retryPendingAcks',
    ]);
    expect(logged[1]).toMatchObject({ cron: CRON.hourly, latencyMs: 0 });
    expect(Number(logged[1]?.['count'])).toBeGreaterThanOrEqual(1);

    await runScheduled(h.deps, '0 0 * * *');
    expect(h.logger.find('cron_unknown').map((e) => e.fields)).toEqual([{ cron: '0 0 * * *' }]);
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
    const jobs: Record<CronExpression, readonly CronJob[]> = {
      [CRON.quarterHourly]: [boom, odd, ok],
      [CRON.hourly]: [],
      [CRON.daily]: [],
    };
    await runScheduled(h.deps, CRON.quarterHourly, jobs);
    expect(ran).toEqual(['ok']);
    expect(h.logger.find('cron_job_failed').map((e) => e.fields)).toEqual([
      { cron: CRON.quarterHourly, job: 'boom', error: 'RangeError' },
      { cron: CRON.quarterHourly, job: 'odd', error: 'unknown' },
    ]);
  });

  it('drains in bounded batches and stops at maxBatches', async () => {
    for (let i = 0; i < 5; i++) {
      await seedIdempotency(PAST);
    }
    const h = createHarness();
    const batches: number[] = [];
    await runScheduled(
      h.deps,
      CRON.hourly,
      {
        [CRON.quarterHourly]: [],
        [CRON.hourly]: [
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
        [CRON.daily]: [],
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
