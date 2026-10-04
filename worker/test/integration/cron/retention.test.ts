import {
  createExecutionContext,
  createScheduledController,
  waitOnExecutionContext,
} from 'cloudflare:test';
import { describe, expect, it } from 'vitest';
import worker from '../../../src/index';
import { InstallRepo } from '../../../src/repos/InstallRepo';
import { LedgerRepo } from '../../../src/repos/LedgerRepo';
import { ReportRepo } from '../../../src/repos/ReportRepo';
import { RewardRepo } from '../../../src/repos/RewardRepo';
import {
  CRON_JOBS,
  CRON_TRIGGER,
  JOB_GROUP,
  RETENTION_JOBS,
  runJobs,
} from '../../../src/scheduled';
import { bindings, createHarness, uniqueId } from '../../fakes/testDeps';
import { db, seedInstall, seedReading } from '../../helpers/db';
import { ReadingDriver } from '../../helpers/readingDriver';

const OLD = '2020-01-15T00:00:00.000Z';
const NIGHT = '2026-09-30T03:30:00.000Z';

async function exists(table: string, column: string, value: string): Promise<boolean> {
  const row = await db
    .prepare(`SELECT 1 AS hit FROM ${table} WHERE ${column} = ?1`)
    .bind(value)
    .first();
  return row !== null;
}

async function seedReport(
  installId: string,
  readingId: string | null,
  crid: string,
  expiresAt: string,
) {
  const id = uniqueId('rep');
  await new ReportRepo(db).insert({
    id,
    installId,
    clientReadingId: crid,
    readingId,
    localDate: '2020-01-15',
    reason: 'other',
    locale: 'en',
    promptVersion: 'v1',
    model: 'anthropic/claude-sonnet-5',
    payloadEnc: new Uint8Array([1, 2, 3]),
    createdAt: OLD,
    expiresAt,
  });
  return id;
}

async function seedReward(installId: string, issuedAt: string): Promise<string> {
  const id = uniqueId('rew');
  await new RewardRepo(db).insert({
    id,
    installId,
    localDate: issuedAt.slice(0, 10),
    amount: 1,
    issuedAt,
    expiresAt: issuedAt,
  });
  return id;
}

async function seedUsage(
  installId: string,
  localDate: string,
  deviceKeyHash: string,
): Promise<void> {
  await db.batch([
    db
      .prepare(`INSERT INTO daily_usage (install_id, local_date, free_limit) VALUES (?1, ?2, 1)`)
      .bind(installId, localDate),
    db
      .prepare(`INSERT INTO device_daily_usage (device_key_hash, local_date) VALUES (?1, ?2)`)
      .bind(deviceKeyHash, localDate),
  ]);
}

async function usageRows(installId: string): Promise<string[]> {
  const { results } = await db
    .prepare(`SELECT local_date FROM daily_usage WHERE install_id = ?1 ORDER BY local_date`)
    .bind(installId)
    .all<{ local_date: string }>();
  return results.map((r) => r.local_date);
}

describe('retention purge in the nightly cron (03 §12, §13; RC22, RC37, RC51)', () => {
  it('registers the retention jobs on the daily trigger, reports before readings', () => {
    const names = CRON_JOBS[JOB_GROUP.daily].map((job) => job.name);
    expect(names).toEqual(expect.arrayContaining(RETENTION_JOBS.map((job) => job.name)));
    expect(RETENTION_JOBS.map((job) => job.name)).toEqual([
      'purgeReadingReports',
      'purgeReadings',
      'purgeAdRewards',
      'purgeDailyUsage',
      'purgeDeviceUsage',
      'pseudonymiseInactiveInstalls',
    ]);
    expect(CRON_JOBS[JOB_GROUP.quarterHourly].map((job) => job.name)).toEqual(
      expect.arrayContaining(['budgetCheck', 'alertCheck']),
    );
  });

  it('deletes what is past its period and keeps the rest', async () => {
    const h = createHarness();
    h.clock.set(NIGHT);
    const id = await seedInstall();

    // readings: 13 months; one old reading is still referenced by a live report.
    const oldReading = await seedReading(id, { createdAt: '2025-08-29T00:00:00.000Z' });
    const keptReading = await seedReading(id, { createdAt: '2025-08-31T00:00:00.000Z' });
    const reported = await seedReading(id, { createdAt: OLD, status: 'completed' });
    const liveReport = await seedReport(
      id,
      reported.id,
      reported.clientReadingId,
      '2026-12-01T00:00:00.000Z',
    );
    // reading_reports: past expires_at.
    const deadReading = await seedReading(id, { createdAt: '2026-09-01T00:00:00.000Z' });
    const expiredReport = await seedReport(id, deadReading.id, deadReading.clientReadingId, NIGHT);
    // ad_rewards: 13 months.
    const oldReward = await seedReward(id, '2025-08-29T23:59:59.000Z');
    const keptReward = await seedReward(id, '2025-08-30T03:30:00.000Z');
    // daily_usage / device_daily_usage: 90 days (cutoff 2026-07-02).
    await seedUsage(id, '2026-07-01', `dk-${id}`);
    await seedUsage(id, '2026-07-02', `dk-${id}`);

    await runJobs(h.deps, JOB_GROUP.daily, {
      [JOB_GROUP.quarterHourly]: [],
      [JOB_GROUP.hourly]: [],
      [JOB_GROUP.daily]: RETENTION_JOBS,
    });

    expect(await exists('reading_reports', 'id', expiredReport)).toBe(false);
    expect(await exists('reading_reports', 'id', liveReport)).toBe(true);
    expect(await exists('readings', 'id', oldReading.id)).toBe(false);
    expect(await exists('readings', 'id', keptReading.id)).toBe(true);
    expect(await exists('readings', 'id', reported.id)).toBe(true);
    expect(await exists('readings', 'id', deadReading.id)).toBe(true);
    expect(await exists('ad_rewards', 'id', oldReward)).toBe(false);
    expect(await exists('ad_rewards', 'id', keptReward)).toBe(true);
    expect(await usageRows(id)).toEqual(['2026-07-02']);
    const { results } = await db
      .prepare(`SELECT local_date FROM device_daily_usage WHERE device_key_hash = ?1`)
      .bind(`dk-${id}`)
      .all<{ local_date: string }>();
    expect(results.map((r) => r.local_date)).toEqual(['2026-07-02']);

    const logged = h.logger.find('cron_job').map((e) => [e.fields['job'], e.fields['count']]);
    expect(logged).toContainEqual(['purgeReadingReports', 1]);
    expect(logged).toContainEqual(['purgeAdRewards', 1]);
    expect(h.logger.find('cron_job_failed')).toEqual([]);
  });

  it('pseudonymises installs inactive for 24 months with balance 0 only', async () => {
    const h = createHarness();
    h.clock.set(NIGHT);
    const driver = new ReadingDriver(h);
    const repo = new InstallRepo(db);
    const idle = await seedInstall({
      now: '2024-09-29T00:00:00.000Z',
      locale: 'de',
      timezone: 'Europe/Berlin',
      appVersion: '1.0.0+1',
      deviceKeyHash: `dkh-${uniqueId('dk')}`,
    });
    const recent = await seedInstall({ now: '2024-10-01T00:00:00.000Z' });
    const withCredits = await seedInstall({ now: OLD });
    await driver.grant(withCredits, 'paid', 1);
    const spentAll = await seedInstall({ now: OLD });
    await driver.grant(spentAll, 'bonus', 1);
    await new LedgerRepo(db).append({
      installId: spentAll,
      bucket: 'bonus',
      delta: -1,
      reason: 'admin_adjust',
      refType: 'admin',
      refId: uniqueId('adj'),
      createdAt: OLD,
    });
    const withRecentReading = await seedInstall({ now: OLD });
    await seedReading(withRecentReading, { createdAt: '2026-01-01T00:00:00.000Z' });
    const before = await repo.findById(idle);

    await runJobs(h.deps, JOB_GROUP.daily, {
      [JOB_GROUP.quarterHourly]: [],
      [JOB_GROUP.hourly]: [],
      [JOB_GROUP.daily]: RETENTION_JOBS,
    });

    const after = await repo.findById(idle);
    expect(after).toMatchObject({
      id: idle,
      status: 'deleted',
      locale: null,
      timezone: null,
      appVersion: null,
      deviceKeyHash: null,
      installSecretHash: `hash-${idle}`,
      tokenGeneration: (before?.tokenGeneration ?? 0) + 1,
    });
    expect((await repo.findById(spentAll))?.status).toBe('deleted');
    for (const kept of [recent, withCredits, withRecentReading]) {
      expect((await repo.findById(kept))?.status).toBe('active');
    }
    expect(await new RewardRepo(db).purgeIssuedBefore(OLD)).toBe(0);
    // Idempotent: a second run touches nothing new.
    const count = await new InstallRepo(db).pseudonymiseInactive('2024-09-30T03:30:00.000Z');
    expect(count).toBe(0);
  });

  it('keeps an install whose reading hold is still held', async () => {
    const repo = new InstallRepo(db);
    const held = await seedInstall({ now: OLD });
    await seedReading(held, { createdAt: OLD });
    await db
      .prepare(`UPDATE readings SET hold_state = 'held' WHERE install_id = ?1`)
      .bind(held)
      .run();
    await repo.pseudonymiseInactive('2024-09-30T03:30:00.000Z');
    expect((await repo.findById(held))?.status).toBe('active');
  });

  it('runs through the Worker entrypoint via createScheduledController', async () => {
    const id = await seedInstall();
    const expired = await seedReport(id, null, uniqueId('crid'), OLD);
    const ctx = createExecutionContext();
    worker.scheduled(
      createScheduledController({
        cron: CRON_TRIGGER,
        scheduledTime: Date.UTC(2026, 0, 1, 3, 30),
      }),
      bindings,
      ctx,
    );
    await waitOnExecutionContext(ctx);
    expect(await exists('reading_reports', 'id', expired)).toBe(false);
  });
});
