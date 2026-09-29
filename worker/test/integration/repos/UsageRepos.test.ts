import { describe, expect, it } from 'vitest';
import { DailyUsageRepo } from '../../../src/repos/DailyUsageRepo';
import { DeviceUsageRepo } from '../../../src/repos/DeviceUsageRepo';
import { uniqueId } from '../../fakes/testDeps';
import { db, seedInstall } from '../../helpers/db';

const daily = new DailyUsageRepo(db);
const device = new DeviceUsageRepo(db);
const DATE = '2026-09-26';

describe('DailyUsageRepo', () => {
  it('takes free readings up to the limit and reports changes == 0 after', async () => {
    const day = { installId: await seedInstall(), localDate: DATE };
    expect((await daily.takeFreeStmt(day, 2).run()).meta.changes).toBe(1);
    expect((await daily.takeFreeStmt(day, 2).run()).meta.changes).toBe(1);
    expect((await daily.takeFreeStmt(day, 2).run()).meta.changes).toBe(0);
    expect(await daily.find(day)).toEqual({
      ...day,
      freeLimit: 2,
      freeUsed: 2,
      rewardedGranted: 0,
      readingsTotal: 2,
      declinedCount: 0,
    });
  });

  it('keeps the snapshot on a mid-day decrease and applies an increase immediately (03 §5.2)', async () => {
    const day = { installId: await seedInstall(), localDate: DATE };
    await daily.ensureStmt(day, 2).run();
    await daily.ensureStmt(day, 1).run();
    expect((await daily.find(day))?.freeLimit).toBe(2);
    await daily.takeFreeStmt(day, 1).run();
    await daily.takeFreeStmt(day, 1).run();
    expect((await daily.takeFreeStmt(day, 1).run()).meta.changes).toBe(0);
    expect((await daily.takeFreeStmt(day, 3).run()).meta.changes).toBe(1);
    expect(await daily.find(day)).toMatchObject({ freeLimit: 3, freeUsed: 3 });
  });

  it('refunds on the hold date only while something was used', async () => {
    const day = { installId: await seedInstall(), localDate: DATE };
    await daily.takeFreeStmt(day, 1).run();
    expect((await daily.refundFreeStmt(day).run()).meta.changes).toBe(1);
    expect((await daily.refundFreeStmt(day).run()).meta.changes).toBe(0);
    expect(await daily.find(day)).toMatchObject({ freeUsed: 0, readingsTotal: 0 });
  });

  it('counts paid readings, rewarded grants and declines', async () => {
    const day = { installId: await seedInstall(), localDate: DATE };
    await daily.declinedStmt(day).run();
    expect(await daily.find(day)).toBeNull();
    await daily.countReadingStmt(day, 1).run();
    await daily.countReadingStmt(day, 1).run();
    await daily.rewardedGrantStmt(day, 1).run();
    await daily.rewardedGrantStmt(day, 1).run();
    await daily.declinedStmt(day).run();
    expect(await daily.find(day)).toMatchObject({
      freeLimit: 1,
      freeUsed: 0,
      readingsTotal: 2,
      rewardedGranted: 2,
      declinedCount: 1,
    });
    const fresh = { installId: day.installId, localDate: '2026-09-27' };
    await daily.rewardedGrantStmt(fresh, 1).run();
    expect((await daily.find(fresh))?.rewardedGranted).toBe(1);
  });

  it('erases past rows but keeps today (RC37) and purges by retention date', async () => {
    const installId = await seedInstall();
    for (const localDate of ['2026-06-01', '2026-09-25', DATE]) {
      await daily.ensureStmt({ installId, localDate }, 1).run();
    }
    await daily.erasePastStmt(installId, DATE).run();
    expect(await daily.find({ installId, localDate: '2026-09-25' })).toBeNull();
    expect(await daily.find({ installId, localDate: DATE })).not.toBeNull();

    const other = await seedInstall();
    await daily.ensureStmt({ installId: other, localDate: '2020-01-01' }, 1).run();
    await daily.ensureStmt({ installId: other, localDate: '2020-01-02' }, 1).run();
    expect(await daily.purgeBefore('2020-06-01', 1)).toBe(1);
    expect(await daily.purgeBefore('2020-06-01')).toBe(1);
    expect(await daily.purgeBefore('2020-06-01')).toBe(0);
  });
});

describe('DeviceUsageRepo', () => {
  it('shares the free reading across installs of one device (RC53)', async () => {
    const day = { deviceKeyHash: uniqueId('dev'), localDate: DATE };
    expect(await device.find(day)).toBeNull();
    expect((await device.takeFreeStmt(day, 1).run()).meta.changes).toBe(1);
    expect((await device.takeFreeStmt(day, 1).run()).meta.changes).toBe(0);
    expect((await device.takeFreeStmt(day, 2).run()).meta.changes).toBe(1);
    expect(await device.find(day)).toEqual({ ...day, freeUsed: 2, rewardedGranted: 0 });
  });

  it('takes nothing when the limit is zero', async () => {
    const day = { deviceKeyHash: uniqueId('dev'), localDate: DATE };
    expect((await device.takeFreeStmt(day, 0).run()).meta.changes).toBe(0);
    expect(await device.find(day)).toBeNull();
  });

  it('refunds, counts grants, erases past rows and purges', async () => {
    const hash = uniqueId('dev');
    const day = { deviceKeyHash: hash, localDate: DATE };
    await device.takeFreeStmt(day, 1).run();
    expect((await device.refundFreeStmt(day).run()).meta.changes).toBe(1);
    expect((await device.refundFreeStmt(day).run()).meta.changes).toBe(0);
    await device.rewardedGrantStmt(day).run();
    await device.rewardedGrantStmt(day).run();
    expect(await device.find(day)).toMatchObject({ freeUsed: 0, rewardedGranted: 2 });

    const old = { deviceKeyHash: hash, localDate: '2020-01-01' };
    await device.rewardedGrantStmt(old).run();
    await device.erasePastStmt(hash, DATE).run();
    expect(await device.find(old)).toBeNull();
    expect(await device.find(day)).not.toBeNull();

    await device
      .rewardedGrantStmt({ deviceKeyHash: uniqueId('dev'), localDate: '2019-01-01' })
      .run();
    expect(await device.purgeBefore('2019-06-01')).toBe(1);
  });
});
