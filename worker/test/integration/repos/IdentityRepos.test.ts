import { describe, expect, it } from 'vitest';
import { InstallRepo, type Reregistration } from '../../../src/repos/InstallRepo';
import { UsedChallengeRepo } from '../../../src/repos/UsedChallengeRepo';
import { uniqueId } from '../../fakes/testDeps';
import { db, NOW, seedInstall } from '../../helpers/db';

describe('UsedChallengeRepo (03 §3.2)', () => {
  const repo = new UsedChallengeRepo(db);

  it('consumes a nonce once', async () => {
    const nonce = uniqueId('nonce');
    expect(await repo.consume(nonce, '2026-09-26T10:05:00.000Z')).toBe(true);
    expect(await repo.consume(nonce, '2026-09-26T10:05:00.000Z')).toBe(false);
  });

  it('purges expired nonces in bounded batches', async () => {
    const old = [uniqueId('old'), uniqueId('old'), uniqueId('old')];
    for (const nonce of old) {
      await repo.consume(nonce, '2020-01-01T00:00:00.000Z');
    }
    const live = uniqueId('live');
    await repo.consume(live, '2099-01-01T00:00:00.000Z');
    expect(await repo.purgeExpired('2021-01-01T00:00:00.000Z', 2)).toBe(2);
    expect(await repo.purgeExpired('2021-01-01T00:00:00.000Z')).toBeGreaterThanOrEqual(1);
    expect(await repo.consume(old[0] ?? '', '2020-01-01T00:00:00.000Z')).toBe(true);
    expect(await repo.consume(live, '2099-01-01T00:00:00.000Z')).toBe(false);
  });
});

describe('InstallRepo identity methods (03 §3.3, §3.4)', () => {
  const repo = new InstallRepo(db);

  function reregistration(id: string, overrides: Partial<Reregistration> = {}): Reregistration {
    return {
      id,
      expectedGeneration: 1,
      trust: 'low',
      appVersion: '1.3.0',
      locale: 'fr',
      timezone: 'Asia/Tokyo',
      deviceKeyHash: null,
      attestKeyId: null,
      attestPublicKey: null,
      attestCounter: null,
      attestEnv: null,
      integrityVerdict: 'basic',
      appleAccountToken: 'token-new',
      playAccountHash: null,
      reregisterCountDay: '2026-09-26:1',
      now: NOW,
      ...overrides,
    };
  }

  it('re-registers as a compare-and-set on token_generation', async () => {
    const id = await seedInstall({ timezone: 'Europe/Berlin', appleAccountToken: uniqueId('apl') });
    expect(await repo.reregister(reregistration(id))).toBe(2);
    expect(await repo.findById(id)).toMatchObject({
      tokenGeneration: 2,
      trust: 'low',
      timezone: 'Europe/Berlin',
      locale: 'fr',
      integrityVerdict: 'basic',
      reregisterCountDay: '2026-09-26:1',
    });
    expect((await repo.findById(id))?.appleAccountToken).not.toBe('token-new');
    // A stale generation loses.
    expect(await repo.reregister(reregistration(id))).toBeNull();
  });

  it('advances the App Attest counter only upwards', async () => {
    const id = await seedInstall();
    expect(await repo.advanceAttestCounter(id, 1)).toBe(true);
    expect(await repo.advanceAttestCounter(id, 1)).toBe(false);
    expect(await repo.advanceAttestCounter(id, 5)).toBe(true);
    expect((await repo.findById(id))?.attestCounter).toBe(5);
    expect(await repo.advanceAttestCounter(uniqueId('none'), 1)).toBe(false);
  });
});
