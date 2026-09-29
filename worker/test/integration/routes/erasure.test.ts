import { describe, expect, it } from 'vitest';
import type { BalanceDto } from '../../../src/domain/allowance';
import { DailyUsageRepo } from '../../../src/repos/DailyUsageRepo';
import { DeviceUsageRepo } from '../../../src/repos/DeviceUsageRepo';
import { IdempotencyRepo } from '../../../src/repos/IdempotencyRepo';
import { InstallRepo } from '../../../src/repos/InstallRepo';
import { LedgerRepo } from '../../../src/repos/LedgerRepo';
import { PurchaseRepo } from '../../../src/repos/PurchaseRepo';
import { ReadingRepo } from '../../../src/repos/ReadingRepo';
import { ReportRepo } from '../../../src/repos/ReportRepo';
import { RewardRepo } from '../../../src/repos/RewardRepo';
import { InstallService } from '../../../src/services/InstallService';
import { createHarness, uniqueId, type TestHarness } from '../../fakes/testDeps';
import { APP_HEADERS, authedApp, errorOf } from '../../helpers/app';
import { db, NOW, seedInstall, seedReading } from '../../helpers/db';

const TODAY = '2026-09-26';
const YESTERDAY = '2026-09-25';

function del(h: TestHarness, installId: string, key: string | null = uniqueId('idem')) {
  return authedApp(h).request('/v1/installs/me', {
    method: 'DELETE',
    headers: {
      ...APP_HEADERS,
      'X-Test-Install': installId,
      ...(key === null ? {} : { 'Idempotency-Key': key }),
    },
  });
}

async function count(sql: string, ...binds: unknown[]): Promise<number> {
  const row = await db
    .prepare(sql)
    .bind(...binds)
    .first<{ n: number }>();
  return row?.n ?? -1;
}

/** An Android install with every kind of per-install row (03 §3.6). */
async function seedEverything() {
  const deviceKeyHash = uniqueId('dev');
  const id = await seedInstall({
    platform: 'android',
    timezone: 'UTC',
    locale: 'de',
    deviceKeyHash,
  });
  const ledger = new LedgerRepo(db);
  const usage = new DailyUsageRepo(db);
  const device = new DeviceUsageRepo(db);
  const settled = await seedReading(id, { status: 'completed', localDate: YESTERDAY });
  const held = await seedReading(id, { status: 'held' });
  await new ReadingRepo(db)
    .holdStmt({
      id: held.id,
      attempt: 1,
      source: 'paid',
      holdLocalDate: null,
      holdExpiresAt: '2026-09-26T10:05:00.000Z',
    })
    .run();
  await new ReportRepo(db).insert({
    id: uniqueId('rep'),
    installId: id,
    clientReadingId: settled.clientReadingId,
    readingId: settled.id,
    localDate: YESTERDAY,
    reason: 'other',
    locale: 'de',
    promptVersion: 'v1',
    model: 'claude-sonnet-5',
    payloadEnc: Uint8Array.of(1, 2, 3),
    createdAt: NOW,
    expiresAt: '2026-12-25T10:00:00.000Z',
  });
  await new RewardRepo(db).insert({
    id: uniqueId('intent'),
    installId: id,
    localDate: YESTERDAY,
    amount: 1,
    issuedAt: NOW,
    expiresAt: '2026-09-26T10:15:00.000Z',
  });
  await new IdempotencyRepo(db).insert({
    installId: id,
    route: 'POST /v1/readings/holds',
    key: uniqueId('old'),
    requestHash: 'h',
    createdAt: NOW,
    expiresAt: '2026-10-03T10:00:00.000Z',
  });
  await new PurchaseRepo(db).insert({
    id: uniqueId('pur'),
    installId: id,
    platform: 'android',
    productId: 'com.vshyrochuk.taro.readings_3',
    storeTxnId: uniqueId('gpa'),
    purchaseToken: uniqueId('tok'),
    credits: 3,
    environment: 'production',
    isTest: false,
    accountTokenMatch: true,
    purchasedAt: NOW,
    grantedAt: NOW,
  });
  await db.batch([
    ledger.appendStmt({
      installId: id,
      bucket: 'paid',
      delta: 3,
      reason: 'purchase',
      refType: 'purchase',
      refId: uniqueId('p'),
      createdAt: NOW,
    }),
    ledger.appendStmt({
      installId: id,
      bucket: 'bonus',
      delta: 1,
      reason: 'ad_reward',
      refType: 'ad_reward',
      refId: uniqueId('r'),
      createdAt: NOW,
    }),
    usage.takeFreeStmt({ installId: id, localDate: YESTERDAY }, 1),
    usage.takeFreeStmt({ installId: id, localDate: TODAY }, 1),
    device.takeFreeStmt({ deviceKeyHash, localDate: YESTERDAY }, 1),
    device.takeFreeStmt({ deviceKeyHash, localDate: TODAY }, 1),
  ]);
  return { id, deviceKeyHash, settled, held };
}

describe('DELETE /v1/installs/me (03 §3.6, RC37)', () => {
  it('erases personal usage data and keeps the install, ledger, purchases and today’s allowance', async () => {
    const h = createHarness();
    const { id, deviceKeyHash, held } = await seedEverything();
    const before = await new InstallRepo(db).findById(id);
    const balanceBefore = await (
      await authedApp(h).request('/v1/balance', {
        headers: { ...APP_HEADERS, 'X-Taro-Platform': 'android', 'X-Test-Install': id },
      })
    ).json<BalanceDto>();

    const key = uniqueId('idem');
    const res = await del(h, id, key);
    expect(res.status).toBe(204);
    expect(await res.text()).toBe('');
    expect(res.headers.get('Date')).not.toBeNull();

    // Deleted.
    expect(await count('SELECT COUNT(*) AS n FROM reading_reports WHERE install_id = ?1', id)).toBe(
      0,
    );
    expect(await count('SELECT COUNT(*) AS n FROM ad_rewards WHERE install_id = ?1', id)).toBe(0);
    expect(
      await count(
        'SELECT COUNT(*) AS n FROM daily_usage WHERE install_id = ?1 AND local_date = ?2',
        id,
        YESTERDAY,
      ),
    ).toBe(0);
    expect(
      await count(
        'SELECT COUNT(*) AS n FROM device_daily_usage WHERE device_key_hash = ?1 AND local_date = ?2',
        deviceKeyHash,
        YESTERDAY,
      ),
    ).toBe(0);
    // Only a still-held reading survives (the stale-hold cron refunds from it).
    const readings = await db
      .prepare('SELECT id FROM readings WHERE install_id = ?1')
      .bind(id)
      .all<{ id: string }>();
    expect(readings.results.map((r) => r.id)).toEqual([held.id]);
    // Only this request's own idempotency row remains, so a retry replays the 204.
    const keys = await db
      .prepare('SELECT route, key, state FROM idempotency_keys WHERE install_id = ?1')
      .bind(id)
      .all();
    expect(keys.results).toEqual([{ route: 'DELETE /v1/installs/me', key, state: 'done' }]);

    // Kept.
    expect(
      await count(
        'SELECT COUNT(*) AS n FROM daily_usage WHERE install_id = ?1 AND local_date = ?2',
        id,
        TODAY,
      ),
    ).toBe(1);
    expect(
      await count(
        'SELECT COUNT(*) AS n FROM device_daily_usage WHERE device_key_hash = ?1 AND local_date = ?2',
        deviceKeyHash,
        TODAY,
      ),
    ).toBe(1);
    expect(await count('SELECT COUNT(*) AS n FROM ledger WHERE install_id = ?1', id)).toBe(2);
    expect(await count('SELECT COUNT(*) AS n FROM purchases WHERE install_id = ?1', id)).toBe(1);
    const after = await new InstallRepo(db).findById(id);
    expect(after).toMatchObject({
      status: 'active',
      locale: null,
      timezone: 'UTC',
      deviceKeyHash,
      installSecretHash: before?.installSecretHash,
      tokenGeneration: before?.tokenGeneration,
      stateVersion: (before?.stateVersion ?? 0) + 1,
    });

    // The balance is unchanged and today's free reading is not re-granted.
    const balanceAfter = await (
      await authedApp(h).request('/v1/balance', {
        headers: { ...APP_HEADERS, 'X-Taro-Platform': 'android', 'X-Test-Install': id },
      })
    ).json<BalanceDto>();
    expect(balanceAfter).toMatchObject({
      paid: balanceBefore.paid,
      bonus: balanceBefore.bonus,
      free: { used: 1, remaining: 0 },
      ledgerVersion: balanceBefore.ledgerVersion + 1,
    });
    expect(balanceAfter.paid).toBe(3);
    h.logger.expectNoSensitive(id, `hash-${id}`);
  });

  it('replays the 204 for a network retry with the same key', async () => {
    const h = createHarness();
    const id = await seedInstall({ timezone: 'UTC', locale: 'en' });
    const key = uniqueId('idem');
    expect((await del(h, id, key)).status).toBe(204);
    const replay = await del(h, id, key);
    expect(replay.status).toBe(204);
    expect(replay.headers.get('Idempotent-Replayed')).toBe('true');
    expect((await new InstallRepo(db).findById(id))?.stateVersion).toBe(1);
  });

  it('a fresh key erases again (idempotent effect, RC55)', async () => {
    const h = createHarness();
    const id = await seedInstall({ timezone: 'UTC' });
    expect((await del(h, id)).status).toBe(204);
    expect((await del(h, id)).status).toBe(204);
    expect((await new InstallRepo(db).findById(id))?.status).toBe('active');
  });

  it('uses the install’s local date for "today" (Pago Pago is still yesterday in UTC terms)', async () => {
    const h = createHarness();
    const id = await seedInstall({ timezone: 'Pacific/Pago_Pago' });
    const usage = new DailyUsageRepo(db);
    await usage.takeFreeStmt({ installId: id, localDate: YESTERDAY }, 1).run();
    await usage.takeFreeStmt({ installId: id, localDate: TODAY }, 1).run();
    expect((await del(h, id)).status).toBe(204);
    // 10:00Z is 23:00 on the 25th in Pago Pago: the 25th is today and kept.
    expect(await usage.find({ installId: id, localDate: YESTERDAY })).not.toBeNull();
    expect(await usage.find({ installId: id, localDate: TODAY })).toBeNull();
  });

  it('erases every idempotency row when called outside an [idem] request', async () => {
    const h = createHarness();
    const id = await seedInstall({ timezone: 'UTC' });
    await new IdempotencyRepo(db).insert({
      installId: id,
      route: 'PUT /v1/installs/me/timezone',
      key: uniqueId('k'),
      requestHash: 'h',
      createdAt: NOW,
      expiresAt: '2026-10-03T10:00:00.000Z',
    });
    const install = await new InstallRepo(db).findById(id);
    if (install === null) throw new Error('seed failed');
    await new InstallService(h.deps).erase(install, undefined);
    expect(
      await count('SELECT COUNT(*) AS n FROM idempotency_keys WHERE install_id = ?1', id),
    ).toBe(0);
  });

  it('requires Idempotency-Key and a token', async () => {
    const h = createHarness();
    const id = await seedInstall();
    const noKey = await del(h, id, null);
    expect(noKey.status).toBe(400);
    expect((await errorOf(noKey)).code).toBe('IDEMPOTENCY_KEY_REQUIRED');
    const res = await authedApp(h).request('/v1/installs/me', {
      method: 'DELETE',
      headers: { ...APP_HEADERS, 'Idempotency-Key': uniqueId('idem') },
    });
    expect(res.status).toBe(401);
  });
});
