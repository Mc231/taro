import { describe, expect, it } from 'vitest';
import type { Deps } from '../../../src/deps';
import { InstallRepo, type InstallRow } from '../../../src/repos/InstallRepo';
import { LedgerRepo } from '../../../src/repos/LedgerRepo';
import { PurchaseRepo, type PurchaseRow } from '../../../src/repos/PurchaseRepo';
import { BalanceService } from '../../../src/services/BalanceService';
import { PurchaseService, type VerifyGranted } from '../../../src/services/PurchaseService';
import { RefundService } from '../../../src/services/RefundService';
import { SeqIdGenerator } from '../../fakes/SeqIdGenerator';
import { createHarness, uniqueId, type TestHarness } from '../../fakes/testDeps';
import { db, seedInstall } from '../../helpers/db';
import { ReadingDriver } from '../../helpers/readingDriver';

/**
 * `RefundService` (03 §6.5, MO16, 04 §12.12, §12.13, §12.21; RC66, RC67)
 * against real D1: clawback into a negative paid balance, `refund_count`,
 * the block threshold, re-grant after a reversed refund, idempotency and
 * races. Purchases are granted through `PurchaseService` with the store fakes.
 */
const ledger = new LedgerRepo(db);
const purchases = new PurchaseRepo(db);
const installs = new InstallRepo(db);

/** The value, or a thrown error when it is missing. */
function must<T>(value: T | null | undefined): T {
  if (value === null || value === undefined) {
    throw new Error('expected a value');
  }
  return value;
}

let harnessCounter = 0;
let txnCounter = 0;

function setup(overrides: Partial<Deps> = {}) {
  harnessCounter++;
  const prefix = (0x7e000000 + harnessCounter).toString(16);
  const h = createHarness({ overrides: { ids: new SeqIdGenerator(prefix), ...overrides } });
  return {
    h,
    refunds: new RefundService(h.deps),
    purchaseService: new PurchaseService(h.deps),
    balances: new BalanceService(h.deps),
    driver: new ReadingDriver(h),
  };
}

async function install(): Promise<InstallRow> {
  const id = uniqueId('rfd');
  await seedInstall({ id, appleAccountToken: `acc-${id}`, timezone: 'Europe/Berlin' });
  const row = await installs.findById(id);
  if (row === null) {
    throw new Error('seeded install missing');
  }
  return row;
}

/** Grants an iOS `readings_{credits}` purchase to `owner` and returns its row. */
async function buy(
  h: TestHarness,
  service: PurchaseService,
  owner: InstallRow,
  product = 'com.vshyrochuk.taro.readings_3',
): Promise<PurchaseRow> {
  txnCounter++;
  const transactionId = `3000000${String(800000000 + txnCounter)}`;
  h.appStore.add({ transactionId, productId: product, appAccountToken: owner.appleAccountToken });
  const fresh = (await installs.findById(owner.id)) ?? owner;
  const result = (await service.verify(fresh, {
    platform: 'ios',
    productId: product,
    transactionId,
  })) as VerifyGranted;
  const row = await purchases.findById(result.purchaseId);
  if (row === null) {
    throw new Error('purchase row missing');
  }
  return row;
}

describe('RefundService.revoke (03 §6.5)', () => {
  it('claws back the credits into a negative paid balance: paidBlocked + purchasesAllowed=false (refundDebt)', async () => {
    const { h, refunds, purchaseService, balances, driver } = setup();
    const owner = await install();
    const purchase = await buy(h, purchaseService, owner);
    // Spend two of the three credits (free first, then paid).
    await driver.hold(owner.id);
    await driver.hold(owner.id);
    await driver.hold(owner.id);
    expect((await ledger.balances(owner.id)).paid).toBe(1);
    const before = await installs.findById(owner.id);

    h.clock.advance({ minutes: 5 });
    expect(await refunds.revoke(purchase, 'apple')).toEqual({ revoked: true, blocked: false });

    expect(await purchases.findById(purchase.id)).toMatchObject({
      status: 'revoked',
      revokedAt: '2026-09-26T10:05:00.000Z',
    });
    const entries = (await ledger.entries(owner.id)).filter((e) => e.reason === 'refund_revoke');
    expect(entries.map((e) => [e.bucket, e.delta, e.refType, e.refId])).toEqual([
      ['paid', -3, 'purchase', purchase.id],
    ]);
    const after = await installs.findById(owner.id);
    expect(after).toMatchObject({ refundCount: 1, status: 'active' });
    expect(after?.stateVersion).toBe((before?.stateVersion ?? 0) + 1);

    const balance = await balances.read(owner.id);
    expect(balance).toMatchObject({
      paid: -2,
      paidBlocked: true,
      purchasesAllowed: false,
      purchasesBlockedReason: 'refundDebt',
      ledgerVersion: after?.stateVersion,
    });
    expect(h.metrics.points).toContainEqual(
      expect.objectContaining({ event: 'purchase_revoked', code: 'apple', credits: 3 }),
    );
    h.logger.expectNoSensitive(owner.id);
  });

  it('a second revoke of the same purchase changes nothing (duplicate webhook, cron after RTDN)', async () => {
    const { h, refunds, purchaseService } = setup();
    const owner = await install();
    const purchase = await buy(h, purchaseService, owner);
    await refunds.revoke(purchase, 'google');
    const version = (await installs.findById(owner.id))?.stateVersion;

    expect(await refunds.revoke(purchase, 'voided_backstop')).toEqual({
      revoked: false,
      blocked: false,
    });
    expect((await ledger.balances(owner.id)).paid).toBe(0);
    expect(await installs.findById(owner.id)).toMatchObject({
      refundCount: 1,
      stateVersion: version,
    });
    expect(h.logger.find('purchase_revoke_duplicate')).toHaveLength(1);
  });

  it('parallel revokes of one purchase claw back exactly once', async () => {
    const { h, refunds, purchaseService } = setup();
    const owner = await install();
    const purchase = await buy(h, purchaseService, owner, 'com.vshyrochuk.taro.readings_10');
    const results = await Promise.all(
      Array.from({ length: 8 }, () => refunds.revoke(purchase, 'apple')),
    );
    expect(results.filter((r) => r.revoked)).toHaveLength(1);
    expect((await ledger.balances(owner.id)).paid).toBe(0);
    expect(await installs.findById(owner.id)).toMatchObject({ refundCount: 1 });
  });

  it('blocks at abuse.refundBlockThreshold: purchases disabled, free/bonus/positive paid keep working, a new verified purchase is still granted', async () => {
    const { h, refunds, purchaseService, balances, driver } = setup();
    const owner = await install();
    const bought: PurchaseRow[] = [];
    for (let i = 0; i < 4; i++) {
      bought.push(await buy(h, purchaseService, owner));
    }
    await driver.grant(owner.id, 'bonus', 1);

    expect(await refunds.revoke(must(bought[0]), 'apple')).toEqual({
      revoked: true,
      blocked: false,
    });
    expect(await refunds.revoke(must(bought[1]), 'apple')).toEqual({
      revoked: true,
      blocked: false,
    });
    expect(await refunds.revoke(must(bought[2]), 'apple')).toEqual({
      revoked: true,
      blocked: true,
    });
    expect(await installs.findById(owner.id)).toMatchObject({ refundCount: 3, status: 'blocked' });
    expect(h.logger.find('install_blocked').map((e) => e.fields)).toEqual([
      { inst: owner.id.slice(0, 8), reason: 'refund_threshold', refundCount: 3 },
    ]);

    // Paid is still +3 (the fourth pack): blocked, not in debt.
    expect(await balances.read(owner.id)).toMatchObject({
      paid: 3,
      bonus: 1,
      paidBlocked: false,
      purchasesAllowed: false,
      purchasesBlockedReason: 'blocked',
      canRead: true,
      nextSource: 'free',
    });
    // Free, then bonus, then positive paid still work.
    expect(await driver.hold(owner.id)).toMatchObject({ kind: 'held', chargeSource: 'free' });
    expect(await driver.hold(owner.id)).toMatchObject({ kind: 'held', chargeSource: 'bonus' });
    expect(await driver.hold(owner.id)).toMatchObject({ kind: 'held', chargeSource: 'paid' });

    // A verified purchase that still arrives is granted (RC66), never 403.
    const late = await buy(h, purchaseService, owner);
    expect(late.status).toBe('granted');
    expect(h.metrics.points).toContainEqual(
      expect.objectContaining({ event: 'blocked_purchase', code: 'blocked' }),
    );
    // A fourth refund keeps the install blocked (and does not report a new block).
    expect(await refunds.revoke(must(bought[3]), 'apple')).toEqual({
      revoked: true,
      blocked: false,
    });
  });

  it('honours a lower threshold from config', async () => {
    const { h, refunds, purchaseService } = setup();
    h.config.set({ 'abuse.refundBlockThreshold': 1 });
    const owner = await install();
    const purchase = await buy(h, purchaseService, owner);
    expect(await refunds.revoke(purchase, 'google')).toEqual({ revoked: true, blocked: true });
  });
});

describe('RefundService.regrant (REFUND_REVERSED, 03 §6.4)', () => {
  it('re-grants a revoked purchase once; refund → reversal → refund cycles get distinct ledger refs', async () => {
    const { h, refunds, purchaseService, balances } = setup();
    const owner = await install();
    const purchase = await buy(h, purchaseService, owner);

    expect(await refunds.regrant(purchase)).toBe(false); // not revoked
    await refunds.revoke(purchase, 'apple');
    const version = (await installs.findById(owner.id))?.stateVersion ?? 0;
    expect(await refunds.regrant(purchase)).toBe(true);
    expect(await refunds.regrant(purchase)).toBe(false);
    expect(await purchases.findById(purchase.id)).toMatchObject({
      status: 'reversal_regranted',
      revokedAt: null,
    });
    expect(await installs.findById(owner.id)).toMatchObject({
      stateVersion: version + 1,
      refundCount: 1,
    });

    expect((await refunds.revoke(purchase, 'apple')).revoked).toBe(true);
    expect(await refunds.regrant(purchase)).toBe(true);
    expect((await refunds.revoke(purchase, 'apple')).revoked).toBe(true);

    const moves = (await ledger.entries(owner.id))
      .filter((e) => e.refType === 'purchase')
      .map((e) => [e.reason, e.delta, e.refId]);
    expect(moves).toEqual([
      ['purchase', 3, purchase.id],
      ['refund_revoke', -3, purchase.id],
      ['purchase_reversal_regrant', 3, purchase.id],
      ['refund_revoke', -3, `${purchase.id}#2`],
      ['purchase_reversal_regrant', 3, `${purchase.id}#2`],
      ['refund_revoke', -3, `${purchase.id}#3`],
    ]);
    // Three refunds reached the threshold: a reversal does not lower refund_count.
    expect(await balances.read(owner.id)).toMatchObject({
      paid: 0,
      purchasesAllowed: false,
      purchasesBlockedReason: 'blocked',
    });
    expect(h.logger.find('purchase_regranted')).toHaveLength(2);
    expect(h.logger.find('purchase_regrant_skipped')).toHaveLength(2);
  });
});
