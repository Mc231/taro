import { describe, expect, it } from 'vitest';
import type { BalanceDto } from '../../../src/domain/allowance';
import { ipPrefixHash, utcDay } from '../../../src/http/middleware/rateLimit';
import { DailyUsageRepo } from '../../../src/repos/DailyUsageRepo';
import { DeviceUsageRepo } from '../../../src/repos/DeviceUsageRepo';
import { InstallRepo } from '../../../src/repos/InstallRepo';
import { LedgerRepo } from '../../../src/repos/LedgerRepo';
import { RewardRepo } from '../../../src/repos/RewardRepo';
import { SpendRepo } from '../../../src/repos/SpendRepo';
import { BalanceService, installTimezone } from '../../../src/services/BalanceService';
import { BudgetService, DauCache } from '../../../src/services/BudgetService';
import { bindings, createHarness, uniqueId, type TestHarness } from '../../fakes/testDeps';
import { APP_HEADERS, authedApp, errorOf, testApp } from '../../helpers/app';
import { db, seedInstall } from '../../helpers/db';

const REGISTERED = '2026-09-26T10:00:00.000Z';

function get(h: TestHarness, installId: string | undefined, headers: Record<string, string> = {}) {
  return authedApp(h).request('/v1/balance', {
    headers: {
      ...APP_HEADERS,
      ...(installId === undefined ? {} : { 'X-Test-Install': installId }),
      ...headers,
    },
  });
}

async function balanceOf(h: TestHarness, installId: string, headers: Record<string, string> = {}) {
  const res = await get(h, installId, headers);
  expect(res.status).toBe(200);
  return res.json<BalanceDto>();
}

async function stateVersion(id: string): Promise<number> {
  return (await new InstallRepo(db).findById(id))?.stateVersion ?? -1;
}

describe('GET /v1/balance (03 §5.1)', () => {
  it('returns the BalanceDto of a fresh install and snapshots today’s daily_usage row', async () => {
    const h = createHarness();
    h.clock.set('2026-09-26T09:12:44.000Z');
    const id = await seedInstall({ timezone: 'Europe/Berlin', now: REGISTERED });
    const res = await get(h, id);
    expect(res.status).toBe(200);
    expect(res.headers.get('Date')).toBe('Sat, 26 Sep 2026 09:12:44 GMT');
    expect(await res.json()).toEqual({
      free: {
        limit: 1,
        used: 0,
        remaining: 1,
        localDate: '2026-09-26',
        resetsAt: '2026-09-26T22:00:00Z',
        timezone: 'Europe/Berlin',
        paused: false,
      },
      bonus: 0,
      paid: 0,
      canRead: true,
      canReadReason: null,
      nextSource: 'free',
      rewarded: {
        enabled: true,
        amount: 1,
        dailyCap: 3,
        grantedToday: 0,
        available: true,
        cooldownEndsAt: null,
      },
      paidBlocked: false,
      purchasesAllowed: true,
      purchasesBlockedReason: null,
      ledgerVersion: 0,
      serverTime: '2026-09-26T09:12:44Z',
    });
    const row = await new DailyUsageRepo(db).find({ installId: id, localDate: '2026-09-26' });
    expect(row).toMatchObject({ freeLimit: 1, freeUsed: 0 });
    // The lazy snapshot is not a balance mutation: no state_version bump.
    expect(await stateVersion(id)).toBe(0);
  });

  it('reports paid and bonus as ledger SUMs with ledgerVersion = installs.state_version (RC67)', async () => {
    const h = createHarness();
    const id = await seedInstall({ timezone: 'UTC' });
    const ledger = new LedgerRepo(db);
    const now = h.clock.now().toISOString();
    await db.batch([
      ledger.appendStmt({
        installId: id,
        bucket: 'paid',
        delta: 10,
        reason: 'purchase',
        refType: 'purchase',
        refId: uniqueId('p'),
        createdAt: now,
      }),
      ledger.appendStmt({
        installId: id,
        bucket: 'paid',
        delta: -3,
        reason: 'refund_revoke',
        refType: 'purchase',
        refId: uniqueId('p'),
        createdAt: now,
      }),
      ledger.appendStmt({
        installId: id,
        bucket: 'bonus',
        delta: 2,
        reason: 'ad_reward',
        refType: 'ad_reward',
        refId: uniqueId('r'),
        createdAt: now,
      }),
      new InstallRepo(db).bumpStateVersionStmt(id),
      new InstallRepo(db).bumpStateVersionStmt(id),
    ]);
    const b = await balanceOf(h, id);
    expect(b).toMatchObject({ paid: 7, bonus: 2, ledgerVersion: 2, paidBlocked: false });
  });

  it('refund debt: paidBlocked and purchasesAllowed=false (RC66)', async () => {
    const h = createHarness();
    const id = await seedInstall({ timezone: 'UTC' });
    await new LedgerRepo(db).append({
      installId: id,
      bucket: 'paid',
      delta: -1,
      reason: 'refund_revoke',
      refType: 'purchase',
      refId: uniqueId('p'),
      createdAt: h.clock.now().toISOString(),
    });
    const b = await balanceOf(h, id);
    expect(b).toMatchObject({
      paid: -1,
      paidBlocked: true,
      purchasesAllowed: false,
      purchasesBlockedReason: 'refundDebt',
    });
  });

  it('applies a mid-day readings.freeDaily increase to the stored snapshot (§5.2)', async () => {
    const h = createHarness();
    const id = await seedInstall({ timezone: 'UTC' });
    const usage = new DailyUsageRepo(db);
    await usage.takeFreeStmt({ installId: id, localDate: '2026-09-26' }, 1).run();
    expect((await balanceOf(h, id)).free).toMatchObject({ limit: 1, used: 1, remaining: 0 });
    h.config.set({ 'readings.freeDaily': 2 });
    expect((await balanceOf(h, id)).free).toMatchObject({ limit: 2, used: 1, remaining: 1 });
    expect(await usage.find({ installId: id, localDate: '2026-09-26' })).toMatchObject({
      freeLimit: 2,
    });
    // A later decrease does not reduce today's snapshot.
    h.config.set({ 'readings.freeDaily': 1 });
    expect((await balanceOf(h, id)).free).toMatchObject({ limit: 2, remaining: 1 });
  });

  it('updates last_seen_at at most hourly, and app_version when it changes', async () => {
    const h = createHarness();
    const id = await seedInstall({ timezone: 'UTC', appVersion: '1.2.0+14', now: REGISTERED });
    const repo = new InstallRepo(db);
    h.clock.set('2026-09-26T10:59:59.000Z');
    await balanceOf(h, id);
    expect((await repo.findById(id))?.lastSeenAt).toBe(REGISTERED);

    h.clock.set('2026-09-26T11:00:00.000Z');
    await balanceOf(h, id);
    expect((await repo.findById(id))?.lastSeenAt).toBe('2026-09-26T11:00:00.000Z');

    h.clock.set('2026-09-26T11:05:00.000Z');
    await balanceOf(h, id, { 'X-Taro-App-Version': '1.3.0+20' });
    expect(await repo.findById(id)).toMatchObject({
      lastSeenAt: '2026-09-26T11:05:00.000Z',
      appVersion: '1.3.0+20',
    });
  });

  it('rewarded: grantedToday and the cooldown come from D1 (RC57)', async () => {
    const h = createHarness();
    const id = await seedInstall({ timezone: 'UTC' });
    const rewards = new RewardRepo(db);
    const intentId = uniqueId('intent');
    await rewards.insert({
      id: intentId,
      installId: id,
      localDate: '2026-09-26',
      amount: 1,
      issuedAt: '2026-09-26T09:58:00.000Z',
      expiresAt: '2026-09-26T10:13:00.000Z',
    });
    await db.batch([
      rewards.grantStmt({
        id: intentId,
        admobTxnId: uniqueId('txn'),
        adUnit: 'unit',
        now: '2026-09-26T09:59:00.000Z',
      }),
      new DailyUsageRepo(db).rewardedGrantStmt({ installId: id, localDate: '2026-09-26' }, 1),
    ]);
    const b = await balanceOf(h, id);
    expect(b.rewarded).toEqual({
      enabled: true,
      amount: 1,
      dailyCap: 3,
      grantedToday: 1,
      available: false,
      cooldownEndsAt: '2026-09-26T10:04:00Z',
    });
  });

  it('Android: the device row limits a second install on the same device (§3.7)', async () => {
    const h = createHarness();
    const deviceKeyHash = uniqueId('dev');
    const first = await seedInstall({ platform: 'android', deviceKeyHash, timezone: 'UTC' });
    const second = await seedInstall({ platform: 'android', deviceKeyHash, timezone: 'UTC' });
    await db.batch([
      new DailyUsageRepo(db).takeFreeStmt({ installId: first, localDate: '2026-09-26' }, 1),
      new DeviceUsageRepo(db).takeFreeStmt({ deviceKeyHash, localDate: '2026-09-26' }, 1),
    ]);
    const b = await balanceOf(h, second, { 'X-Taro-Platform': 'android' });
    expect(b.free).toMatchObject({ used: 0, remaining: 0 });
    expect(b).toMatchObject({ canRead: false, canReadReason: 'noCredits' });
  });

  it('low trust: the per-IP-prefix free cap is peeked, not consumed (§2.4)', async () => {
    const h = createHarness();
    const id = await seedInstall({ trust: 'low', timezone: 'UTC' });
    const ip = '203.0.113.77';
    const fresh = await balanceOf(h, id, { 'CF-Connecting-IP': ip });
    expect(fresh).toMatchObject({ canRead: true, nextSource: 'free' });

    const hash = await ipPrefixHash(h.deps, ip);
    const key = `lt:ip:${hash}:${utcDay(h.clock.now())}`;
    expect(await bindings.RL_KV.get(key)).toBeNull();
    await bindings.RL_KV.put(key, '3');
    const capped = await balanceOf(h, id, { 'CF-Connecting-IP': ip });
    expect(capped.free.remaining).toBe(0);
    expect(capped).toMatchObject({ canRead: false, canReadReason: 'lowTrustCap' });
    expect(await bindings.RL_KV.get(key)).toBe('3');
  });

  it('budget tiers: free stop pauses free, hard stop pauses all (RC64)', async () => {
    const h = createHarness();
    h.clock.set('2026-10-15T12:00:00.000Z');
    const id = await seedInstall({ timezone: 'UTC', now: '2026-10-15T11:30:00.000Z' });
    const spend = new SpendRepo(db);
    await spend.add('2026-10-15', 100_000_000); // $100 = free-stop floor at a small dau
    const cache = new DauCache();
    const service = new BalanceService(h.deps, new BudgetService(db, cache));
    const paused = await service.read(id);
    expect(paused?.free.paused).toBe(true);
    expect(paused).toMatchObject({ canRead: false, canReadReason: 'readingsPaused' });
    expect(cache.get('2026-10-15')).toBeGreaterThanOrEqual(0);

    await spend.add('2026-10-15', 200_000_000); // $300 = hard
    expect(await service.read(id)).toMatchObject({ canReadReason: 'readingsPaused' });

    // The cached dau is reused on the same day.
    cache.set('2026-10-15', 1_000_000);
    await spend.add('2026-10-14', 1);
    expect(
      await new BudgetService(db, cache).status(await h.config.snapshot(), h.clock.now()),
    ).toMatchObject({ tier: 'hard', spendUsd: 300 });
  });

  it('BudgetService counts yesterday’s active installs as dau', async () => {
    const h = createHarness();
    await seedInstall({ now: '2026-11-04T08:00:00.000Z' });
    await seedInstall({ now: '2026-11-04T20:00:00.000Z' });
    await new SpendRepo(db).add('2026-11-05', 60_000_000);
    const cache = new DauCache();
    const status = await new BudgetService(db, cache).status(
      await h.config.snapshot(),
      new Date('2026-11-05T12:00:00.000Z'),
    );
    expect(cache.get('2026-11-05')).toBe(2);
    expect(status).toEqual({ tier: 'soft', spendUsd: 60 });
  });

  it('401 without a token, for an unknown install and for a deleted install', async () => {
    const h = createHarness();
    expect((await errorOf(await get(h, undefined))).code).toBe('UNAUTHENTICATED');
    expect((await errorOf(await get(h, uniqueId('ghost')))).code).toBe('UNAUTHENTICATED');
    const id = await seedInstall();
    await new InstallRepo(db).setStatus(id, 'deleted');
    const res = await get(h, id);
    expect(res.status).toBe(401);
    expect(res.headers.get('Date')).not.toBeNull();
  });

  it('is wired behind the real install-token auth by default', async () => {
    const h = createHarness();
    const id = await seedInstall({ timezone: 'UTC' });
    const res = await testApp(h).request('/v1/balance', {
      headers: { ...APP_HEADERS, 'X-Test-Install': id },
    });
    expect(res.status).toBe(401);
    expect((await errorOf(res)).code).toBe('UNAUTHENTICATED');
  });

  it('a blocked install still reads its balance but cannot buy (§2.4)', async () => {
    const h = createHarness();
    const id = await seedInstall({ timezone: 'UTC' });
    await new InstallRepo(db).setStatus(id, 'blocked');
    expect(await balanceOf(h, id)).toMatchObject({
      canRead: true,
      purchasesAllowed: false,
      purchasesBlockedReason: 'blocked',
    });
  });

  it('requires the X-Taro-* client headers and applies the per-install burst limit', async () => {
    const h = createHarness();
    const id = await seedInstall({ timezone: 'UTC' });
    const noHeaders = await authedApp(h).request('/v1/balance', {
      headers: { 'X-Test-Install': id },
    });
    expect(noHeaders.status).toBe(400);
    expect((await errorOf(noHeaders)).code).toBe('VALIDATION_FAILED');

    h.burst.limitPerKey = 1;
    expect((await get(h, id)).status).toBe(200);
    const limited = await get(h, id);
    expect(limited.status).toBe(429);
    expect(await errorOf(limited)).toMatchObject({
      code: 'RATE_LIMITED',
      details: { reason: 'burst' },
    });
    expect(h.burst.keys).toContain(`inst:${id}`);
  });

  it('falls back to UTC for an install without a stored timezone', async () => {
    const h = createHarness();
    const id = await seedInstall({ timezone: null });
    expect((await balanceOf(h, id)).free).toMatchObject({
      timezone: 'UTC',
      resetsAt: '2026-09-27T00:00:00Z',
    });
    expect(installTimezone({ timezone: 'Not/AZone' })).toBe('UTC');
  });

  it('never logs the install ID in full', async () => {
    const h = createHarness();
    const id = await seedInstall({ timezone: 'UTC' });
    await balanceOf(h, id, { 'CF-Connecting-IP': '198.51.100.1' });
    h.logger.expectNoSensitive(id, `hash-${id}`, '198.51.100.1');
  });
});
