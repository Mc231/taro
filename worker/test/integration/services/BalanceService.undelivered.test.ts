import { describe, expect, it } from 'vitest';
import { createHarness } from '../../fakes/testDeps';
import { db, seedInstall } from '../../helpers/db';
import { ReadingDriver } from '../../helpers/readingDriver';

/** `BalanceService.refundUndelivered` (RC51, 03 §9.1): once, only for unacknowledged readings. */
describe('BalanceService.refundUndelivered', () => {
  it('refunds a consumed paid reading once and marks it expired_refunded', async () => {
    const driver = new ReadingDriver(createHarness());
    const id = await seedInstall();
    await driver.grant(id, 'paid', 1);
    await driver.hold(id); // takes today's free reading
    const paid = await driver.hold(id);
    expect(paid).toMatchObject({ kind: 'held', chargeSource: 'paid' });
    await driver.commit(paid.readingId);
    expect(await driver.balances(id)).toEqual({ paid: 0, bonus: 0 });

    const first = await driver.balance.refundUndelivered(paid.readingId);
    expect(first).toMatchObject({ refunded: true, source: 'paid' });
    expect((await driver.reading(paid.readingId))?.status).toBe('expired_refunded');
    expect(await driver.balances(id)).toEqual({ paid: 1, bonus: 0 });
    expect(await driver.balance.refundUndelivered(paid.readingId)).toMatchObject({
      refunded: false,
    });
    expect(await driver.balance.refundUndelivered('missing')).toEqual({
      refunded: false,
      source: null,
      attempt: null,
    });
  });

  it('never refunds an acknowledged reading; an uncharged one only expires', async () => {
    const driver = new ReadingDriver(createHarness());
    const id = await seedInstall();
    const acked = await driver.hold(id);
    await driver.commit(acked.readingId);
    await db
      .prepare(`UPDATE readings SET acked_at = '2026-09-26T10:00:00.000Z' WHERE id = ?1`)
      .bind(acked.readingId)
      .run();
    expect((await driver.balance.refundUndelivered(acked.readingId)).refunded).toBe(false);
    expect((await driver.reading(acked.readingId))?.status).toBe('completed');

    const row = await driver.open(id);
    await db
      .prepare(
        `UPDATE readings SET status = 'completed', hold_state = 'refunded', charge_source = 'none'
          WHERE id = ?1`,
      )
      .bind(row.id)
      .run();
    expect(await driver.balance.refundUndelivered(row.id)).toEqual({
      refunded: false,
      source: null,
      attempt: 1,
    });
    expect((await driver.reading(row.id))?.status).toBe('expired_refunded');
  });
});
