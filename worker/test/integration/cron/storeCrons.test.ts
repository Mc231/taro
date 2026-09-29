import { describe, expect, it } from 'vitest';
import type { Deps } from '../../../src/deps';
import type { PlayDeveloperApi, PlayVoidedPurchase } from '../../../src/ports/StoreApis';
import { InstallRepo, type InstallRow } from '../../../src/repos/InstallRepo';
import { LedgerRepo } from '../../../src/repos/LedgerRepo';
import { PENDING_ACK_PREFIX, PendingAckRepo } from '../../../src/repos/PendingAckRepo';
import { PurchaseRepo, type PurchaseRow } from '../../../src/repos/PurchaseRepo';
import {
  CRON,
  DEFAULT_BATCH_LIMITS,
  retryPendingAcks,
  runScheduled,
  voidedPurchasesBackstop,
} from '../../../src/scheduled';
import { PurchaseService, type VerifyGranted } from '../../../src/services/PurchaseService';
import { RefundService } from '../../../src/services/RefundService';
import { VOIDED_LOOKBACK_MS } from '../../../src/services/WebhookService';
import { SeqIdGenerator } from '../../fakes/SeqIdGenerator';
import { bindings, createHarness, uniqueId, type TestHarness } from '../../fakes/testDeps';
import { db, seedInstall } from '../../helpers/db';

/**
 * Store crons (03 §6.4, §12; RC10): the daily Voided Purchases backstop and
 * the hourly retry of failed Google acknowledgements, against real D1/KV with
 * `FakePlayDeveloperApi`.
 */
const ledger = new LedgerRepo(db);
const purchases = new PurchaseRepo(db);
const installs = new InstallRepo(db);
const pendingAcks = new PendingAckRepo(bindings.CACHE_KV);

/** The value, or a thrown error when it is missing. */
function must<T>(value: T | null | undefined): T {
  if (value === null || value === undefined) {
    throw new Error('expected a value');
  }
  return value;
}

let harnessCounter = 0;
function harness(overrides: Partial<Deps> = {}): TestHarness {
  harnessCounter++;
  const prefix = (0x5c000000 + harnessCounter).toString(16);
  return createHarness({ overrides: { ids: new SeqIdGenerator(prefix), ...overrides } });
}

async function androidInstall(): Promise<InstallRow> {
  const id = uniqueId('cand');
  await seedInstall({ id, platform: 'android', playAccountHash: `play-${id}` });
  return must(await installs.findById(id));
}

async function buy(h: TestHarness, owner: InstallRow): Promise<PurchaseRow> {
  const token = uniqueId('ctok');
  h.playDeveloper.add(token, { obfuscatedExternalAccountId: owner.playAccountHash });
  const result = (await new PurchaseService(h.deps).verify(owner, {
    platform: 'android',
    productId: 'com.vshyrochuk.taro.readings_3',
    purchaseToken: token,
  })) as VerifyGranted;
  return must(await purchases.findById(result.purchaseId));
}

function voided(row: PurchaseRow, at: Date, overrides: Partial<PlayVoidedPurchase> = {}) {
  return {
    purchaseToken: row.purchaseToken ?? '',
    orderId: row.storeTxnId,
    voidedTimeMillis: at.getTime(),
    voidedSource: 0,
    voidedReason: 1,
    ...overrides,
  };
}

async function clearAllPendingAcks(): Promise<void> {
  const { keys } = await bindings.CACHE_KV.list({ prefix: PENDING_ACK_PREFIX });
  await Promise.all(keys.map((k) => bindings.CACHE_KV.delete(k.name)));
}

describe('voidedPurchasesBackstop (daily, 03 §6.4)', () => {
  it('revokes voided purchases of the last two days the RTDN missed, once', async () => {
    const h = harness();
    const owner = await androidInstall();
    const missed = await buy(h, owner);
    const byOrder = await buy(h, owner);
    const old = await buy(h, owner);
    const alreadyRevoked = await buy(h, owner);
    await new RefundService(h.deps).revoke(alreadyRevoked, 'google');
    const now = h.clock.now();
    h.playDeveloper.voided.push(
      voided(missed, new Date(now.getTime() - 3600_000)),
      voided(byOrder, new Date(now.getTime() - 3600_000), { purchaseToken: 'rotated-token' }),
      voided(old, new Date(now.getTime() - VOIDED_LOOKBACK_MS - 1)),
      voided(alreadyRevoked, now),
      {
        purchaseToken: 'never-granted',
        orderId: null,
        voidedTimeMillis: now.getTime(),
        voidedSource: null,
        voidedReason: null,
      },
    );

    expect(await voidedPurchasesBackstop.run(h.deps, now, DEFAULT_BATCH_LIMITS)).toBe(2);
    expect(await purchases.findById(missed.id)).toMatchObject({ status: 'revoked' });
    expect(await purchases.findById(byOrder.id)).toMatchObject({ status: 'revoked' });
    expect(await purchases.findById(old.id)).toMatchObject({ status: 'granted' });
    expect((await ledger.balances(owner.id)).paid).toBe(3);
    expect(h.metrics.points.filter((p) => p.code === 'voided_backstop')).toHaveLength(2);

    // Idempotent: the next run finds nothing new.
    expect(await voidedPurchasesBackstop.run(h.deps, now, DEFAULT_BATCH_LIMITS)).toBe(0);
    expect(await installs.findById(owner.id)).toMatchObject({ refundCount: 3, status: 'blocked' });
  });

  it('pages through the list, bounded by maxBatches, with the two-day window', async () => {
    const h = harness();
    const owner = await androidInstall();
    const rows = [await buy(h, owner), await buy(h, owner), await buy(h, owner)];
    const now = h.clock.now();
    const calls: { startTimeMillis: number; endTimeMillis?: number; pageToken?: string }[] = [];
    h.playDeveloper.listVoidedPurchases = (
      input: Parameters<PlayDeveloperApi['listVoidedPurchases']>[0],
    ) => {
      calls.push(input);
      const page = Number(input.pageToken ?? '0');
      const row = must(rows[page]);
      return Promise.resolve({
        ok: true as const,
        purchases: [voided(row, now)],
        nextPageToken: page + 1 < rows.length ? String(page + 1) : null,
      });
    };
    expect(await voidedPurchasesBackstop.run(h.deps, now, { batchSize: 500, maxBatches: 2 })).toBe(
      2,
    );
    expect(calls).toEqual([
      {
        packageName: 'com.vshyrochuk.taro',
        startTimeMillis: now.getTime() - VOIDED_LOOKBACK_MS,
        endTimeMillis: now.getTime(),
      },
      {
        packageName: 'com.vshyrochuk.taro',
        startTimeMillis: now.getTime() - VOIDED_LOOKBACK_MS,
        endTimeMillis: now.getTime(),
        pageToken: '1',
      },
    ]);
    // The next run (unbounded here) reaches the last page.
    expect(await voidedPurchasesBackstop.run(h.deps, now, DEFAULT_BATCH_LIMITS)).toBe(1);
  });

  it('a store failure fails the job (logged by runScheduled), nothing revoked', async () => {
    const h = harness();
    h.playDeveloper.failure = 'unavailable';
    await runScheduled(h.deps, CRON.daily);
    expect(h.logger.find('cron_job_failed').map((e) => e.fields)).toEqual([
      { cron: CRON.daily, job: 'voidedPurchasesBackstop', error: 'Error' },
    ]);
  });
});

describe('retryPendingAcks (hourly, RC10)', () => {
  it('acknowledges pending purchases and clears their markers', async () => {
    await clearAllPendingAcks();
    const h = harness();
    const owner = await androidInstall();
    h.playDeveloper.ackFails = true;
    const pending = await buy(h, owner);
    expect((await pendingAcks.list()).map((m) => m.purchaseId)).toEqual([pending.id]);

    // Still failing: the marker stays and the failure is logged.
    expect(await retryPendingAcks.run(h.deps, h.clock.now(), DEFAULT_BATCH_LIMITS)).toBe(0);
    expect(h.logger.find('pending_ack_retry_failed').map((e) => e.fields)).toEqual([
      { purchaseId: pending.id },
    ]);

    h.playDeveloper.ackFails = false;
    await runScheduled(h.deps, CRON.hourly);
    const job = h.logger
      .find('cron_job')
      .map((e) => e.fields)
      .find((f) => f['job'] === 'retryPendingAcks');
    expect(job).toMatchObject({ count: 1 });
    expect(await pendingAcks.list()).toEqual([]);
    expect(h.playDeveloper.acks.at(-1)?.purchaseToken).toBe(pending.purchaseToken);
  });

  it('clears markers of purchases already acknowledged, consumed, revoked, unknown to the store or to D1', async () => {
    await clearAllPendingAcks();
    const h = harness();
    const owner = await androidInstall();
    h.playDeveloper.ackFails = true;
    const acked = await buy(h, owner);
    const consumed = await buy(h, owner);
    const revoked = await buy(h, owner);
    const vanished = await buy(h, owner);
    const outage = await buy(h, owner);
    h.playDeveloper.ackFails = false;
    const set = (row: PurchaseRow, fields: Record<string, number>) => {
      const entry = h.playDeveloper.purchases.get(row.purchaseToken ?? '');
      if (entry !== undefined) {
        entry.purchase = { ...entry.purchase, ...fields };
      }
    };
    set(acked, { acknowledgementState: 1 });
    set(consumed, { consumptionState: 1 });
    await new RefundService(h.deps).revoke(revoked, 'google');
    h.playDeveloper.purchases.delete(vanished.purchaseToken ?? '');
    await pendingAcks.mark('no-such-purchase', h.clock.now().toISOString());
    const acksBefore = h.playDeveloper.acks.length;

    // One purchase hits a store outage: its marker survives for the next run.
    const realGet = h.playDeveloper.getProductPurchase.bind(h.playDeveloper);
    h.playDeveloper.getProductPurchase = (ref) =>
      ref.purchaseToken === outage.purchaseToken
        ? Promise.resolve({ ok: false as const, reason: 'unavailable' as const })
        : realGet(ref);

    expect(await retryPendingAcks.run(h.deps, h.clock.now(), DEFAULT_BATCH_LIMITS)).toBe(5);
    expect(h.playDeveloper.acks.length).toBe(acksBefore);
    expect((await pendingAcks.list()).map((m) => m.purchaseId)).toEqual([outage.id]);
  });
});
