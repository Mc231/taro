import { describe, expect, it } from 'vitest';
import { PurchaseRepo, type NewPurchase } from '../../../src/repos/PurchaseRepo';
import { RewardRepo, type NewReward } from '../../../src/repos/RewardRepo';
import { uniqueId } from '../../fakes/testDeps';
import { db, NOW, seedInstall } from '../../helpers/db';

const purchases = new PurchaseRepo(db);
const rewards = new RewardRepo(db);

function purchase(installId: string, overrides: Partial<NewPurchase> = {}): NewPurchase {
  const id = uniqueId('purc');
  return {
    id,
    installId,
    platform: 'ios',
    productId: 'com.vshyrochuk.taro.readings_10',
    storeTxnId: `txn-${id}`,
    credits: 10,
    environment: 'production',
    isTest: false,
    accountTokenMatch: true,
    purchasedAt: NOW,
    grantedAt: NOW,
    ...overrides,
  };
}

describe('PurchaseRepo', () => {
  it('stores a granted purchase with is_test (RC7) and finds it three ways', async () => {
    const installId = await seedInstall();
    const p = purchase(installId, {
      platform: 'android',
      purchaseToken: `tok-${installId}`,
      originalTxnId: 'orig',
      environment: 'sandbox',
      isTest: true,
      accountTokenMatch: false,
    });
    expect(await purchases.insert(p)).toBe(true);
    const row = await purchases.findById(p.id);
    expect(row).toEqual({ ...p, status: 'granted', revokedAt: null });
    expect(await purchases.findByStoreTxn('android', p.storeTxnId)).toEqual(row);
    expect(await purchases.findByPurchaseToken(`tok-${installId}`)).toEqual(row);
    expect(await purchases.findByStoreTxn('ios', p.storeTxnId)).toBeNull();
    expect(await purchases.findById('missing')).toBeNull();
    expect(await purchases.findByPurchaseToken('missing')).toBeNull();
  });

  it('defaults optional store fields to null and rejects a second claim of a transaction', async () => {
    const installId = await seedInstall();
    const p = purchase(installId);
    await purchases.insert(p);
    expect(await purchases.findById(p.id)).toMatchObject({
      originalTxnId: null,
      purchaseToken: null,
      isTest: false,
    });
    expect(await purchases.insert({ ...p, id: uniqueId('dupe') })).toBe(false);
  });

  it('revokes and re-grants with compare-and-set (03 §6.5)', async () => {
    const installId = await seedInstall();
    const p = purchase(installId);
    await purchases.insert(p);
    expect(await purchases.markRegranted(p.id)).toBe(false);
    expect(await purchases.markRevoked(p.id, NOW)).toBe(true);
    expect(await purchases.markRevoked(p.id, NOW)).toBe(false);
    expect(await purchases.findById(p.id)).toMatchObject({ status: 'revoked', revokedAt: NOW });
    expect(await purchases.markRegranted(p.id)).toBe(true);
    expect(await purchases.findById(p.id)).toMatchObject({
      status: 'reversal_regranted',
      revokedAt: null,
    });
  });

  it('sums test-purchase credits per install and globally (RC63)', async () => {
    const a = await seedInstall();
    const b = await seedInstall();
    const since = '2030-01-01T00:00:00.000Z';
    const later = '2030-01-02T00:00:00.000Z';
    await purchases.insert(purchase(a, { isTest: true, credits: 3, grantedAt: later }));
    await purchases.insert(purchase(a, { isTest: true, credits: 30, grantedAt: later }));
    await purchases.insert(purchase(b, { isTest: true, credits: 10, grantedAt: later }));
    await purchases.insert(purchase(a, { isTest: false, credits: 10, grantedAt: later }));
    await purchases.insert(purchase(a, { isTest: true, credits: 10, grantedAt: NOW }));
    expect(await purchases.testCreditsSince(a, since)).toBe(33);
    expect(await purchases.testCreditsSince(null, since)).toBe(43);
    expect(await purchases.testCreditsSince('nobody', since)).toBe(0);
  });
});

function reward(installId: string, overrides: Partial<NewReward> = {}): NewReward {
  return {
    id: uniqueId('intent'),
    installId,
    localDate: '2026-09-26',
    amount: 1,
    issuedAt: NOW,
    expiresAt: '2026-09-26T10:15:00.000Z',
    ...overrides,
  };
}

describe('RewardRepo', () => {
  it('issues an intent and grants it once while unexpired', async () => {
    const installId = await seedInstall();
    const r = reward(installId, { adUnit: 'unit-a' });
    await rewards.insert(r);
    expect(await rewards.findById(r.id)).toEqual({
      ...r,
      status: 'issued',
      admobTxnId: null,
      rejectReason: null,
      grantedAt: null,
    });
    const grant = (txn: string, now = '2026-09-26T10:05:00.000Z') =>
      rewards.grantStmt({ id: r.id, admobTxnId: txn, adUnit: 'unit-b', now }).run();
    expect((await grant(`t-${r.id}`)).meta.changes).toBe(1);
    expect((await grant(`t2-${r.id}`)).meta.changes).toBe(0);
    expect(await rewards.findById(r.id)).toMatchObject({
      status: 'granted',
      admobTxnId: `t-${r.id}`,
      adUnit: 'unit-b',
      grantedAt: '2026-09-26T10:05:00.000Z',
    });
    expect(await rewards.lastGrantedAt(installId)).toBe('2026-09-26T10:05:00.000Z');
    expect(await rewards.findById('missing')).toBeNull();
  });

  it('refuses to grant an expired intent', async () => {
    const r = reward(await seedInstall());
    await rewards.insertStmt(r).run();
    const res = await rewards
      .grantStmt({
        id: r.id,
        admobTxnId: `t-${r.id}`,
        adUnit: 'u',
        now: '2026-09-26T11:00:00.000Z',
      })
      .run();
    expect(res.meta.changes).toBe(0);
    expect((await rewards.findById(r.id))?.adUnit).toBeNull();
  });

  it('cancels (own install only), rejects and expires issued intents', async () => {
    const installId = await seedInstall();
    const a = reward(installId);
    const b = reward(installId);
    const c = reward(installId, { expiresAt: '2000-01-01T00:00:00.000Z' });
    for (const r of [a, b, c]) {
      await rewards.insert(r);
    }
    expect(await rewards.cancel(a.id, 'someone-else')).toBe(false);
    expect(await rewards.cancel(a.id, installId)).toBe(true);
    expect(await rewards.cancel(a.id, installId)).toBe(false);
    expect(await rewards.reject(b.id, 'ad_unit')).toBe(true);
    expect(await rewards.reject(b.id, 'again')).toBe(false);
    expect(await rewards.findById(b.id)).toMatchObject({
      status: 'rejected',
      rejectReason: 'ad_unit',
    });
    expect(await rewards.expireDue('2001-01-01T00:00:00.000Z')).toBe(1);
    expect((await rewards.findById(c.id))?.status).toBe('expired');
    expect(await rewards.lastGrantedAt(installId)).toBeNull();
  });

  it('erases every intent of an install (RC37)', async () => {
    const installId = await seedInstall();
    const r = reward(installId);
    await rewards.insert(r);
    await rewards.eraseStmt(installId).run();
    expect(await rewards.findById(r.id)).toBeNull();
  });
});
