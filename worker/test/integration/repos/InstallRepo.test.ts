import { describe, expect, it } from 'vitest';
import { InstallRepo } from '../../../src/repos/InstallRepo';
import { uniqueId } from '../../fakes/testDeps';
import { db, NOW, seedInstall } from '../../helpers/db';

const repo = new InstallRepo(db);

describe('InstallRepo', () => {
  it('inserts with DDL defaults and reads the row back', async () => {
    const id = await seedInstall({ platform: 'android', trust: 'low' });
    expect(await repo.findById(id)).toEqual({
      id,
      platform: 'android',
      status: 'active',
      trust: 'low',
      tokenGeneration: 1,
      stateVersion: 0,
      installSecretHash: `hash-${id}`,
      deviceKeyHash: null,
      deviceReused: false,
      appVersion: null,
      locale: null,
      timezone: null,
      tzChangedAt: null,
      attestKeyId: null,
      attestPublicKey: null,
      attestCounter: null,
      attestEnv: null,
      integrityVerdict: null,
      appleAccountToken: null,
      playAccountHash: null,
      refundCount: 0,
      reregisterCountDay: null,
      createdAt: NOW,
      lastSeenAt: NOW,
    });
  });

  it('stores every registration column, including the SPKI blob', async () => {
    const id = uniqueId('full');
    const key = new Uint8Array([48, 89, 48, 19, 6, 7]);
    await seedInstall({
      id,
      deviceKeyHash: 'dkh',
      deviceReused: true,
      appVersion: '1.2.0+14',
      locale: 'de',
      timezone: 'Europe/Berlin',
      attestKeyId: 'kid',
      attestPublicKey: key,
      attestCounter: 0,
      attestEnv: 'development',
      integrityVerdict: 'device',
      appleAccountToken: `aat-${id}`,
      playAccountHash: `pah-${id}`,
    });
    const row = await repo.findById(id);
    expect(row).toMatchObject({
      deviceKeyHash: 'dkh',
      deviceReused: true,
      appVersion: '1.2.0+14',
      locale: 'de',
      timezone: 'Europe/Berlin',
      attestKeyId: 'kid',
      attestCounter: 0,
      attestEnv: 'development',
      integrityVerdict: 'device',
    });
    expect(row?.attestPublicKey).toEqual(key);
    expect((await repo.findByAppleAccountToken(`aat-${id}`))?.id).toBe(id);
    expect((await repo.findByPlayAccountHash(`pah-${id}`))?.id).toBe(id);
  });

  it('returns false for a duplicate ID or binding and null for unknown lookups', async () => {
    const id = await seedInstall({ appleAccountToken: 'dup-token' });
    expect(
      await repo.insert({ id, platform: 'ios', trust: 'high', installSecretHash: 'x', now: NOW }),
    ).toBe(false);
    expect(
      await repo.insert({
        id: uniqueId('other'),
        platform: 'ios',
        trust: 'high',
        installSecretHash: 'x',
        appleAccountToken: 'dup-token',
        now: NOW,
      }),
    ).toBe(false);
    expect(await repo.findById('missing')).toBeNull();
    expect(await repo.findByAppleAccountToken('missing')).toBeNull();
    expect(await repo.findByPlayAccountHash('missing')).toBeNull();
  });

  it('touches last_seen_at and keeps app_version when none is given', async () => {
    const id = await seedInstall({ appVersion: '1.0.0' });
    expect(await repo.touch(id, '2026-09-27T00:00:00.000Z', null)).toBe(true);
    expect(await repo.findById(id)).toMatchObject({
      lastSeenAt: '2026-09-27T00:00:00.000Z',
      appVersion: '1.0.0',
    });
    await repo.touch(id, '2026-09-28T00:00:00.000Z', '1.1.0');
    expect((await repo.findById(id))?.appVersion).toBe('1.1.0');
    expect(await repo.touch('missing', NOW, null)).toBe(false);
  });

  it('updates timezone, status, token generation and refund count', async () => {
    const id = await seedInstall();
    expect(await repo.updateTimezone(id, 'Asia/Kolkata', NOW)).toBe(true);
    expect(await repo.setStatus(id, 'blocked')).toBe(true);
    expect(await repo.bumpTokenGeneration(id)).toBe(2);
    expect(await repo.incrementRefundCount(id)).toBe(1);
    expect(await repo.findById(id)).toMatchObject({
      timezone: 'Asia/Kolkata',
      tzChangedAt: NOW,
      status: 'blocked',
      tokenGeneration: 2,
      refundCount: 1,
    });
    expect(await repo.bumpTokenGeneration('missing')).toBeNull();
    expect(await repo.incrementRefundCount('missing')).toBeNull();
    expect(await repo.updateTimezone('missing', 'UTC', NOW)).toBe(false);
    expect(await repo.setStatus('missing', 'active')).toBe(false);
  });

  it('bumps state_version and nulls locale in batches (RC67, RC37)', async () => {
    const id = await seedInstall({ locale: 'fr' });
    await db.batch([
      repo.bumpStateVersionStmt(id),
      repo.bumpStateVersionStmt(id),
      repo.eraseLocaleStmt(id),
    ]);
    expect(await repo.findById(id)).toMatchObject({
      stateVersion: 2,
      locale: null,
      status: 'active',
    });
  });
});
