import { describe, expect, it } from 'vitest';
import { ApiError } from '../../../src/http/errors';
import { InstallRepo, type InstallRow } from '../../../src/repos/InstallRepo';
import { PurchaseService, type VerifyRequest } from '../../../src/services/PurchaseService';
import { SeqIdGenerator } from '../../fakes/SeqIdGenerator';
import { createHarness, uniqueId, type TestHarness } from '../../fakes/testDeps';
import { db, seedInstall } from '../../helpers/db';

async function mustInstall(id: string): Promise<InstallRow> {
  const row = await new InstallRepo(db).findById(id);
  if (row === null) {
    throw new Error('install missing');
  }
  return row;
}

/**
 * Sprint 7.5 metrics wired into `PurchaseService` (03 §14.1, 04 §12.3, §14):
 * one `purchase_verify` per call with its outcome (the verify error rate is
 * `code = internal` over all), and a support alert for `blocked_purchase`.
 */
const installs = new InstallRepo(db);

let counter = 0;
function harness(): TestHarness {
  counter++;
  return createHarness({
    overrides: { ids: new SeqIdGenerator((0x7c000000 + counter).toString(16)) },
  });
}

function txnId(): string {
  counter++;
  return `2000000${String(600000000 + counter)}`;
}

async function install(): Promise<InstallRow> {
  const id = await seedInstall({ id: uniqueId('met') });
  const row = await installs.findById(id);
  if (row === null) {
    throw new Error('seeded install missing');
  }
  return row;
}

function ios(transactionId: string): VerifyRequest {
  return { platform: 'ios', productId: 'com.vshyrochuk.taro.readings_3', transactionId };
}

describe('PurchaseService metrics (Sprint 7.5)', () => {
  it('writes purchase_verify with the outcome for grants, replays, rejections and outages', async () => {
    const h = harness();
    const service = new PurchaseService(h.deps);
    const buyer = await install();
    const txn = h.appStore.add({ transactionId: txnId() }).transactionId;

    expect((await service.verify(buyer, ios(txn))).status).toBe('granted');
    expect((await service.verify(buyer, ios(txn))).status).toBe('already_granted');
    await expect(service.verify(buyer, ios(txnId()))).rejects.toBeInstanceOf(ApiError);
    h.appStore.failure = 'unavailable';
    await expect(service.verify(buyer, ios(txnId()))).rejects.toMatchObject({ code: 'INTERNAL' });

    const verifies = h.metrics.points.filter((p) => p.event === 'purchase_verify');
    expect(verifies.map((p) => [p.platform, p.code])).toEqual([
      ['ios', 'granted'],
      ['ios', 'already_granted'],
      ['ios', 'purchase_invalid'],
      ['ios', 'internal'],
    ]);
    expect(verifies.every((p) => typeof p.latencyMs === 'number' && p.latencyMs >= 0)).toBe(true);
  });

  it('counts a non-ApiError failure as internal and rethrows it', async () => {
    const h = harness();
    const service = new PurchaseService(h.deps);
    const buyer = await install();
    h.appStore.getTransaction = () => Promise.reject(new Error('boom'));
    await expect(service.verify(buyer, ios(txnId()))).rejects.toThrow('boom');
    expect(h.metrics.points.at(-1)).toMatchObject({ event: 'purchase_verify', code: 'internal' });
  });

  it('writes pending for an Android pending purchase', async () => {
    const h = harness();
    const service = new PurchaseService(h.deps);
    const id = await seedInstall({ id: uniqueId('mea'), platform: 'android' });
    const row = await mustInstall(id);
    const token = uniqueId('tok');
    h.playDeveloper.add(token, { purchaseState: 2 });
    const result = await service.verify(row, {
      platform: 'android',
      productId: 'com.vshyrochuk.taro.readings_3',
      purchaseToken: token,
    });
    expect(result.status).toBe('pending');
    expect(h.metrics.points.at(-1)).toMatchObject({
      event: 'purchase_verify',
      platform: 'android',
      code: 'pending',
    });
  });

  it('alerts support when a blocked install is granted (03 §6.5)', async () => {
    const h = harness();
    const service = new PurchaseService(h.deps);
    const buyer = await install();
    await installs.setStatus(buyer.id, 'blocked');
    const blocked = await mustInstall(buyer.id);
    await service.verify(blocked, ios(h.appStore.add({ transactionId: txnId() }).transactionId));
    expect(h.alerter.alerts).toEqual([
      expect.objectContaining({
        kind: 'blocked_purchase',
        fields: { inst: buyer.id.slice(0, 8), reason: 'blocked', platform: 'ios' },
      }),
    ]);
    expect(JSON.stringify(h.alerter.alerts)).not.toContain(buyer.id);
  });
});
