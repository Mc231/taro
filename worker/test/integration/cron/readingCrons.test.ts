import {
  createExecutionContext,
  createScheduledController,
  waitOnExecutionContext,
} from 'cloudflare:test';
import { describe, expect, it } from 'vitest';
import worker from '../../../src/index';
import { ReadingRepo } from '../../../src/repos/ReadingRepo';
import { CRON_TRIGGER } from '../../../src/scheduled';
import { bindings, createHarness } from '../../fakes/testDeps';
import { db, seedInstall } from '../../helpers/db';
import { ReadingDriver } from '../../helpers/readingDriver';

/**
 * The reading crons through the `scheduled` entrypoint (03 §12; RC51, RC52):
 * `releaseExpiredHolds` + `refundStaleHolds` every 15 minutes,
 * `refundUndeliveredReadings` hourly. Rows are dated 2001, so the real clock
 * of the entrypoint is always past every cutoff.
 */
const PAST = '2001-01-01T10:00:00.000Z';

/** Scheduled instants of the single trigger: a :15 run (15-minute jobs only) and a :00 run (+ hourly). */
const QUARTER_RUN = Date.UTC(2026, 0, 1, 10, 15);
const HOURLY_RUN = Date.UTC(2026, 0, 1, 11, 0);

async function trigger(scheduledTime: number): Promise<void> {
  const ctx = createExecutionContext();
  worker.scheduled(createScheduledController({ cron: CRON_TRIGGER, scheduledTime }), bindings, ctx);
  await waitOnExecutionContext(ctx);
}

describe('reading crons via scheduled()', () => {
  it('release expired holds, refund stale generating rows, refund undelivered readings', async () => {
    const h = createHarness();
    h.clock.set(PAST);
    const driver = new ReadingDriver(h);
    const readings = new ReadingRepo(db);
    const id = await seedInstall();
    await driver.grant(id, 'paid', 3);

    const expired = await driver.hold(id);
    const stale = await driver.hold(id, undefined, { status: 'generating' });
    expect(await readings.markGenerating(stale.readingId, 1, PAST)).toBe(true);
    const undelivered = await driver.hold(id);
    await driver.commit(undelivered.readingId);
    expect(await driver.balances(id)).toEqual({ paid: 1, bonus: 0 });

    await trigger(QUARTER_RUN);
    expect(await driver.reading(expired.readingId)).toMatchObject({
      status: 'expired_hold',
      holdState: 'refunded',
    });
    expect(await driver.reading(stale.readingId)).toMatchObject({
      status: 'failed',
      holdState: 'refunded',
      errorCode: 'abandoned',
    });

    await trigger(HOURLY_RUN);
    await trigger(HOURLY_RUN);
    expect((await driver.reading(undelivered.readingId))?.status).toBe('expired_refunded');
    // Two holds refunded (the first took the free reading) and one undelivered, each once.
    expect(await driver.balances(id)).toEqual({ paid: 3, bonus: 0 });
    expect((await driver.usage(id, '2001-01-01'))?.freeUsed).toBe(0);
  });
});
