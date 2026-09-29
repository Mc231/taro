import { describe, expect, it } from 'vitest';
import { buildApp, type App } from '../../../src/app';
import type { BalanceDto } from '../../../src/domain/allowance';
import { ATTESTATION_HEADER } from '../../../src/http/middleware/attestation';
import { DailyUsageRepo } from '../../../src/repos/DailyUsageRepo';
import { DeviceUsageRepo } from '../../../src/repos/DeviceUsageRepo';
import { InstallRepo } from '../../../src/repos/InstallRepo';
import { LedgerRepo } from '../../../src/repos/LedgerRepo';
import { RewardRepo } from '../../../src/repos/RewardRepo';
import { WebhookEventRepo } from '../../../src/repos/WebhookEventRepo';
import { CRON, runScheduled } from '../../../src/scheduled';
import type { RewardIntentDto } from '../../../src/services/RewardService';
import { FakeAdmobKeyProvider } from '../../fakes/FakeAdmobKeyProvider';
import { SeqIdGenerator } from '../../fakes/SeqIdGenerator';
import { createHarness, uniqueId, type TestHarness } from '../../fakes/testDeps';
import {
  newSsvSigner,
  signedSsvPath,
  type SsvParams,
  type SsvSigner,
} from '../../helpers/admobSsv';
import { APP_HEADERS, errorOf } from '../../helpers/app';
import { db } from '../../helpers/db';
import {
  ANDROID_HEADERS,
  idemKey,
  newDeviceKey,
  noneAttestation,
  registerOk,
  uniqueIp,
} from '../../helpers/identity';

/**
 * Rewarded ads via AdMob SSV (Sprint 7.4; 03 §7, 04 §9, 06 §7; BE14, RC33,
 * RC35, RC56, RC57). SSV callbacks are signed with a P-256 key generated in
 * the test and served by `FakeAdmobKeyProvider`; no network.
 */

const KEY_ID = 3335741209;
const AD_UNIT_ID = 'ca-app-pub-3940256099942544/1712485313';
/** The numeric part AdMob sends as SSV `ad_unit`. */
const SSV_AD_UNIT = '1712485313';

/** Opaque intent IDs unique across the harnesses of this file (shared D1). */
class UniqueIds extends SeqIdGenerator {
  override opaque(): string {
    return `int${uniqueId('rw').replace(/-/g, '')}`;
  }
}

interface Ctx {
  readonly h: TestHarness;
  readonly app: App;
  readonly keys: FakeAdmobKeyProvider;
  readonly signer: SsvSigner;
}

async function setup(): Promise<Ctx> {
  const keys = new FakeAdmobKeyProvider();
  const signer = await newSsvSigner(KEY_ID);
  keys.set(KEY_ID, signer.spki);
  const h = createHarness({ overrides: { admobKeys: keys, ids: new UniqueIds() } });
  h.config.set({ 'abuse.lowTrust.powBits': 8 });
  return { h, app: buildApp(h.deps), keys, signer };
}

interface Client {
  readonly installId: string;
  readonly token: string;
  readonly headers: Record<string, string>;
}

async function client(
  ctx: Ctx,
  options: { platform?: 'ios' | 'android'; deviceKey?: string; lowTrust?: boolean } = {},
): Promise<Client> {
  const platform = options.platform ?? 'ios';
  const ip = uniqueIp();
  const base = platform === 'ios' ? APP_HEADERS : ANDROID_HEADERS;
  const reg = await registerOk(ctx.app, {
    platform,
    headers: { ...base, 'CF-Connecting-IP': ip },
    ...(options.deviceKey === undefined ? {} : { deviceKey: options.deviceKey }),
    ...(options.lowTrust === true ? { attestation: noneAttestation(8) } : {}),
  });
  const attestation =
    options.lowTrust === true ? 'none' : platform === 'ios' ? 'aa1.YXNzZXJ0aW9u' : 'pi1.token';
  return {
    installId: reg.installId,
    token: reg.body.installToken,
    headers: {
      ...base,
      'CF-Connecting-IP': ip,
      Authorization: `Bearer ${reg.body.installToken}`,
      [ATTESTATION_HEADER]: attestation,
    },
  };
}

async function createIntent(
  ctx: Ctx,
  c: Client,
  options: { adUnitId?: string; key?: string } = {},
): Promise<Response> {
  return ctx.app.request('/v1/rewards/intents', {
    method: 'POST',
    headers: {
      ...c.headers,
      'content-type': 'application/json',
      'Idempotency-Key': options.key ?? idemKey(),
    },
    body: JSON.stringify({ adUnitId: options.adUnitId ?? AD_UNIT_ID }),
  });
}

async function intentOk(ctx: Ctx, c: Client): Promise<RewardIntentDto> {
  const res = await createIntent(ctx, c);
  if (res.status !== 201) {
    throw new Error(`intent: ${String(res.status)} ${await res.text()}`);
  }
  return res.json<RewardIntentDto>();
}

async function cancel(ctx: Ctx, c: Client, intentId: string): Promise<Response> {
  return ctx.app.request(`/v1/rewards/intents/${intentId}/cancel`, {
    method: 'POST',
    headers: c.headers,
  });
}

async function status(ctx: Ctx, c: Client, intentId: string): Promise<Response> {
  return ctx.app.request(`/v1/rewards/intents/${intentId}`, { headers: c.headers });
}

async function ssv(
  ctx: Ctx,
  intentId: string,
  overrides: Partial<SsvParams> = {},
  signer: SsvSigner = ctx.signer,
): Promise<Response> {
  const path = await signedSsvPath(signer, {
    ad_network: '5450213213286189855',
    ad_unit: SSV_AD_UNIT,
    custom_data: intentId,
    reward_amount: '5',
    reward_item: 'Reward',
    timestamp: String(ctx.h.clock.now().getTime() - 1500),
    transaction_id: uniqueId('txn'),
    user_id: intentId,
    ...overrides,
  });
  return ctx.app.request(path);
}

async function bonus(installId: string): Promise<number> {
  return (await new LedgerRepo(db).balances(installId)).bonus;
}

async function rewardRow(intentId: string) {
  const row = await new RewardRepo(db).findById(intentId);
  if (row === null) {
    throw new Error('no intent row');
  }
  return row;
}

async function stateVersion(installId: string): Promise<number> {
  return (await new InstallRepo(db).findById(installId))?.stateVersion ?? -1;
}

async function grantedToday(installId: string): Promise<number> {
  return (
    (await new DailyUsageRepo(db).find({ installId, localDate: '2026-09-26' }))?.rewardedGranted ??
    0
  );
}

/** Issues an intent and grants it through SSV. */
async function earn(ctx: Ctx, c: Client): Promise<RewardIntentDto> {
  const intent = await intentOk(ctx, c);
  expect((await ssv(ctx, intent.intentId)).status).toBe(200);
  return intent;
}

describe('POST /v1/rewards/intents [idem][attest] (03 §7.1)', () => {
  it('issues an intent with customData == userId == intentId and a snapshot amount (RC56)', async () => {
    const ctx = await setup();
    const c = await client(ctx);
    const before = await stateVersion(c.installId);

    const res = await createIntent(ctx, c);
    expect(res.status).toBe(201);
    const body = await res.json<RewardIntentDto>();
    expect(body).toEqual({
      intentId: body.intentId,
      customData: body.intentId,
      userId: body.intentId,
      amount: 1,
      expiresAt: '2026-09-26T10:15:00Z',
    });
    expect(body.intentId).not.toContain(c.installId);
    expect(await rewardRow(body.intentId)).toMatchObject({
      installId: c.installId,
      status: 'issued',
      amount: 1,
      adUnit: AD_UNIT_ID,
      localDate: '2026-09-26',
      expiresAt: '2026-09-26T10:15:00.000Z',
    });
    expect(await stateVersion(c.installId)).toBe(before + 1);
    expect(ctx.h.metrics.points.some((p) => p.event === 'reward_issued')).toBe(true);
    ctx.h.logger.expectNoSensitive(c.installId, c.token);
  });

  it('replays the same Idempotency-Key and requires call attestation', async () => {
    const ctx = await setup();
    const c = await client(ctx);
    const key = idemKey();
    const first = await createIntent(ctx, c, { key });
    const again = await createIntent(ctx, c, { key });
    expect(again.status).toBe(201);
    expect(again.headers.get('Idempotent-Replayed')).toBe('true');
    expect(await again.json()).toEqual(await first.json());

    const unattested = Object.fromEntries(
      Object.entries(c.headers).filter(([name]) => name !== ATTESTATION_HEADER),
    );
    const res = await createIntent(ctx, { ...c, headers: unattested });
    expect(res.status).toBe(401);
    expect((await errorOf(res)).code).toBe('ATTESTATION_REQUIRED');
  });

  it('returns 403 REWARDED_DISABLED when rewarded.enabled is off or dailyCap is 0', async () => {
    const ctx = await setup();
    const c = await client(ctx);
    ctx.h.config.set({ 'rewarded.enabled': false });
    const off = await createIntent(ctx, c);
    expect(off.status).toBe(403);
    expect((await errorOf(off)).code).toBe('REWARDED_DISABLED');
    ctx.h.config.set({ 'rewarded.enabled': true, 'rewarded.dailyCap': 0 });
    expect((await errorOf(await createIntent(ctx, c))).code).toBe('REWARDED_DISABLED');
  });

  it('rejects an ad unit outside rewarded.allowedAdUnitIds with 400', async () => {
    const ctx = await setup();
    const c = await client(ctx);
    const res = await createIntent(ctx, c, { adUnitId: 'ca-app-pub-1/999' });
    expect(res.status).toBe(400);
    expect(await errorOf(res)).toMatchObject({
      code: 'VALIDATION_FAILED',
      details: { issues: [{ path: 'adUnitId', code: 'not_allowed' }] },
    });
  });

  it('keeps at most one open intent: a new intent cancels the previous one (RC57)', async () => {
    const ctx = await setup();
    const c = await client(ctx);
    const first = await intentOk(ctx, c);
    const second = await intentOk(ctx, c);
    expect((await rewardRow(first.intentId)).status).toBe('cancelled');
    expect((await rewardRow(first.intentId)).expiresAt).toBe('2026-09-26T10:02:00.000Z');
    expect((await rewardRow(second.intentId)).status).toBe('issued');
  });

  it('three cancelled intents leave the install eligible (RC57)', async () => {
    const ctx = await setup();
    const c = await client(ctx);
    for (let i = 0; i < 3; i++) {
      const intent = await intentOk(ctx, c);
      expect((await cancel(ctx, c, intent.intentId)).status).toBe(204);
    }
    expect((await createIntent(ctx, c)).status).toBe(201);
    const balance = await ctx.app.request('/v1/balance', { headers: c.headers });
    expect((await balance.json<BalanceDto>()).rewarded).toMatchObject({
      grantedToday: 0,
      available: true,
    });
  });

  it('measures the cooldown from the last grant, not from the intent (RC35)', async () => {
    const ctx = await setup();
    const c = await client(ctx);
    const intent = await intentOk(ctx, c);
    ctx.h.clock.advance({ seconds: 200 }); // granted 200 s after the intent was issued
    expect((await ssv(ctx, intent.intentId)).status).toBe(200);

    ctx.h.clock.advance({ seconds: 250 }); // 450 s after issue, 250 s after the grant
    const cooling = await createIntent(ctx, c);
    expect(cooling.status).toBe(409);
    expect(await errorOf(cooling)).toMatchObject({
      code: 'REWARDED_DAILY_CAP',
      details: { reason: 'cooldown', availableAt: '2026-09-26T10:08:20Z' },
    });

    ctx.h.clock.advance({ seconds: 50 });
    expect((await createIntent(ctx, c)).status).toBe(201);
  });

  it('caps at rewarded.dailyCap grants per local day until the next reset', async () => {
    const ctx = await setup();
    ctx.h.config.set({ 'rewarded.cooldownSec': 0, 'rewarded.dailyCap': 2 });
    const c = await client(ctx);
    await earn(ctx, c);
    await earn(ctx, c);
    const res = await createIntent(ctx, c);
    expect(res.status).toBe(409);
    // Registered in Europe/Berlin: the local day ends at 22:00 UTC.
    expect(await errorOf(res)).toMatchObject({
      code: 'REWARDED_DAILY_CAP',
      details: { reason: 'cap', availableAt: '2026-09-26T22:00:00Z' },
    });
  });

  it('shares the cap between installs on the same Android device key (RC53)', async () => {
    const ctx = await setup();
    ctx.h.config.set({ 'rewarded.cooldownSec': 0, 'rewarded.dailyCap': 1 });
    const deviceKey = newDeviceKey();
    const first = await client(ctx, { platform: 'android', deviceKey });
    const second = await client(ctx, { platform: 'android', deviceKey });
    await earn(ctx, first);
    const install = await new InstallRepo(db).findById(first.installId);
    expect(
      (
        await new DeviceUsageRepo(db).find({
          deviceKeyHash: install?.deviceKeyHash ?? '',
          localDate: '2026-09-26',
        })
      )?.rewardedGranted,
    ).toBe(1);

    const res = await createIntent(ctx, second);
    expect(res.status).toBe(409);
    expect((await errorOf(res)).details).toMatchObject({ reason: 'cap' });
  });

  it('gives low-trust installs rewarded ads only within the per-IP-prefix cap (03 Q8)', async () => {
    const ctx = await setup();
    ctx.h.config.set({ 'abuse.lowTrust.freePerIpPerDay': 1 });
    const c = await client(ctx, { lowTrust: true });
    expect((await createIntent(ctx, c)).status).toBe(201);
    const res = await createIntent(ctx, c);
    expect(res.status).toBe(409);
    expect(await errorOf(res)).toMatchObject({
      code: 'REWARDED_DAILY_CAP',
      details: { reason: 'cap', availableAt: '2026-09-27T00:00:00Z' },
    });
  });
});

describe('GET /v1/ads/admob/ssv (03 §7.2)', () => {
  it('grants the snapshot amount (never reward_amount) to bonus in one batch', async () => {
    const ctx = await setup();
    const c = await client(ctx);
    const intent = await intentOk(ctx, c);
    const version = await stateVersion(c.installId);

    const res = await ssv(ctx, intent.intentId, { reward_amount: '5', transaction_id: 'txn-a1' });
    expect(res.status).toBe(200);
    expect(await bonus(c.installId)).toBe(1);
    expect(await grantedToday(c.installId)).toBe(1);
    expect(await stateVersion(c.installId)).toBe(version + 1);
    expect(await rewardRow(intent.intentId)).toMatchObject({
      status: 'granted',
      admobTxnId: 'txn-a1',
      adUnit: SSV_AD_UNIT,
      grantedAt: '2026-09-26T10:00:00.000Z',
    });
    expect(await new WebhookEventRepo(db).find('ssv:txn-a1')).toMatchObject({
      source: 'admob',
      status: 'processed',
    });
    const entries = await new LedgerRepo(db).entries(c.installId);
    expect(entries).toEqual([
      expect.objectContaining({
        bucket: 'bonus',
        delta: 1,
        reason: 'ad_reward',
        refType: 'ad_reward',
        refId: intent.intentId,
      }),
    ]);
    expect(ctx.h.metrics.points).toContainEqual(
      expect.objectContaining({ event: 'reward_granted', credits: 1, latencyMs: 1500 }),
    );
    ctx.h.logger.expectNoSensitive(c.installId, c.token);
  });

  it('GET /v1/rewards/intents/{intentId} reports the grant with the balance (03 §7.3)', async () => {
    const ctx = await setup();
    const c = await client(ctx);
    const intent = await intentOk(ctx, c);
    const issued = await status(ctx, c, intent.intentId);
    expect(await issued.json()).toEqual({ status: 'issued', amount: 1 });

    await ssv(ctx, intent.intentId);
    const granted = await status(ctx, c, intent.intentId);
    const body = await granted.json<{ status: string; amount: number; balance: BalanceDto }>();
    expect(body.status).toBe('granted');
    expect(body.amount).toBe(1);
    expect(body.balance.bonus).toBe(1);
    expect(body.balance.rewarded).toMatchObject({ grantedToday: 1, available: false });
  });

  it('answers 403 for a tampered query and an unknown key_id, and grants nothing', async () => {
    const ctx = await setup();
    const c = await client(ctx);
    const intent = await intentOk(ctx, c);
    const path = await signedSsvPath(ctx.signer, {
      ad_unit: SSV_AD_UNIT,
      custom_data: intent.intentId,
      reward_amount: '1',
      transaction_id: 'txn-t1',
      user_id: intent.intentId,
    });
    const tampered = await ctx.app.request(path.replace('reward_amount=1', 'reward_amount=2'));
    expect(tampered.status).toBe(403);

    const stranger = await newSsvSigner(777);
    expect((await ssv(ctx, intent.intentId, {}, stranger)).status).toBe(403);
    expect(await bonus(c.installId)).toBe(0);
    expect(ctx.h.logger.find('ssv_rejected')[0]?.fields).toMatchObject({ reason: 'signature' });
    expect(ctx.h.metrics.points).toContainEqual(
      expect.objectContaining({ event: 'webhook_sig_failed', code: 'admob' }),
    );
  });

  it('answers 500 while the verifier keys cannot be fetched, so AdMob retries', async () => {
    const ctx = await setup();
    ctx.keys.failWith = new Error('admob keys: HTTP 503');
    const res = await ssv(ctx, 'anything');
    expect(res.status).toBe(500);
  });

  it('rejects with 200 and ssv_rejected{reason}: wrong ad unit, user mismatch, unknown or malformed', async () => {
    const ctx = await setup();
    const c = await client(ctx);
    const a = await intentOk(ctx, c);
    expect((await ssv(ctx, a.intentId, { ad_unit: '999' })).status).toBe(200);
    expect(await rewardRow(a.intentId)).toMatchObject({
      status: 'rejected',
      rejectReason: 'ad_unit',
    });

    const b = await intentOk(ctx, c);
    expect((await ssv(ctx, b.intentId, { user_id: c.installId })).status).toBe(200);
    expect((await rewardRow(b.intentId)).status).toBe('rejected');

    expect((await ssv(ctx, 'no-such-intent')).status).toBe(200);
    expect((await ssv(ctx, b.intentId, { transaction_id: '' })).status).toBe(200);
    expect(
      (await ssv(ctx, b.intentId, { custom_data: undefined, user_id: undefined })).status,
    ).toBe(200);
    // A rejected intent stays rejected.
    expect((await ssv(ctx, b.intentId)).status).toBe(200);

    expect(ctx.h.logger.find('ssv_rejected').map((e) => e.fields['reason'])).toEqual([
      'ad_unit',
      'user_mismatch',
      'unknown_intent',
      'malformed',
      'malformed',
      'rejected',
    ]);
    expect(await bonus(c.installId)).toBe(0);
    const res = await status(ctx, c, b.intentId);
    expect(await res.json()).toEqual({ status: 'rejected', amount: 1 });
  });

  it('rejects callbacks without transaction_id or ad_unit, and replays a known grant as a duplicate', async () => {
    const ctx = await setup();
    const c = await client(ctx);
    const a = await intentOk(ctx, c);
    expect((await ssv(ctx, a.intentId, { transaction_id: undefined })).status).toBe(200);
    expect((await ssv(ctx, a.intentId, { ad_unit: undefined })).status).toBe(200);
    expect(ctx.h.logger.find('ssv_rejected').map((e) => e.fields['reason'])).toEqual([
      'malformed',
      'ad_unit',
    ]);

    ctx.h.clock.advance({ seconds: 301 });
    const b = await intentOk(ctx, c);
    expect((await ssv(ctx, b.intentId, { transaction_id: 'txn-replay' })).status).toBe(200);
    // Without its dedupe row, the same transaction is still recognised on the intent.
    await db.prepare(`DELETE FROM webhook_events WHERE id = 'ssv:txn-replay'`).run();
    expect((await ssv(ctx, b.intentId, { transaction_id: 'txn-replay' })).status).toBe(200);
    expect(ctx.h.logger.find('ssv_duplicate')).toHaveLength(1);
    expect(await bonus(c.installId)).toBe(1);
  });

  it('rejects an expired intent and a used one', async () => {
    const ctx = await setup();
    const c = await client(ctx);
    const used = await earn(ctx, c);
    expect((await ssv(ctx, used.intentId)).status).toBe(200);

    ctx.h.clock.advance({ seconds: 301 });
    const stale = await intentOk(ctx, c);
    ctx.h.clock.advance({ seconds: 900 });
    expect(await (await status(ctx, c, stale.intentId)).json()).toEqual({
      status: 'expired',
      amount: 1,
    });
    expect((await ssv(ctx, stale.intentId)).status).toBe(200);
    expect(ctx.h.logger.find('ssv_rejected').map((e) => e.fields['reason'])).toEqual([
      'already_granted',
      'expired',
    ]);
    expect(await bonus(c.installId)).toBe(1);
  });

  it('honours an intent issued under the cap after the cap was reduced (RC57)', async () => {
    const ctx = await setup();
    ctx.h.config.set({ 'rewarded.cooldownSec': 0 });
    const c = await client(ctx);
    await earn(ctx, c);
    const intent = await intentOk(ctx, c);
    ctx.h.config.set({ 'rewarded.dailyCap': 1, 'rewarded.cooldownSec': 3600 });
    expect((await ssv(ctx, intent.intentId)).status).toBe(200);
    expect(await bonus(c.installId)).toBe(2);
    expect(await grantedToday(c.installId)).toBe(2);
  });

  it('grants the intent snapshot even when rewarded.amount changed after issue', async () => {
    const ctx = await setup();
    ctx.h.config.set({ 'rewarded.amount': 2 });
    const c = await client(ctx);
    const intent = await intentOk(ctx, c);
    expect(intent.amount).toBe(2);
    ctx.h.config.set({ 'rewarded.amount': 1 });
    await ssv(ctx, intent.intentId);
    expect(await bonus(c.installId)).toBe(2);
  });

  it('grants a cancelled intent within the 2-minute grace, not after it', async () => {
    const ctx = await setup();
    ctx.h.config.set({ 'rewarded.cooldownSec': 0 });
    const c = await client(ctx);
    const inGrace = await intentOk(ctx, c);
    expect((await cancel(ctx, c, inGrace.intentId)).status).toBe(204);
    ctx.h.clock.advance({ seconds: 119 });
    expect((await ssv(ctx, inGrace.intentId)).status).toBe(200);
    expect((await rewardRow(inGrace.intentId)).status).toBe('granted');

    const late = await intentOk(ctx, c);
    await cancel(ctx, c, late.intentId);
    ctx.h.clock.advance({ seconds: 121 });
    expect((await ssv(ctx, late.intentId)).status).toBe(200);
    expect((await rewardRow(late.intentId)).status).toBe('cancelled');
    expect(ctx.h.logger.find('ssv_rejected').map((e) => e.fields['reason'])).toEqual(['cancelled']);
    expect(await bonus(c.installId)).toBe(1);
  });

  it('grants a duplicate transaction_id once, also when delivered in parallel', async () => {
    const ctx = await setup();
    const c = await client(ctx);
    const intent = await intentOk(ctx, c);
    const path = await signedSsvPath(ctx.signer, {
      ad_unit: SSV_AD_UNIT,
      custom_data: intent.intentId,
      transaction_id: 'txn-dup',
      user_id: intent.intentId,
    });
    const results = await Promise.all([
      ctx.app.request(path),
      ctx.app.request(path),
      ctx.app.request(path),
    ]);
    expect(results.map((r) => r.status)).toEqual([200, 200, 200]);
    expect((await ctx.app.request(path)).status).toBe(200);
    expect(await bonus(c.installId)).toBe(1);
    expect(await new LedgerRepo(db).entries(c.installId)).toHaveLength(1);
    expect(ctx.h.logger.find('ssv_duplicate').length).toBeGreaterThanOrEqual(1);
    expect(ctx.h.logger.find('ssv_rejected')).toEqual([]);
  });

  it('rejects a transaction_id already used by another intent (admob_txn_id UNIQUE)', async () => {
    const ctx = await setup();
    ctx.h.config.set({ 'rewarded.cooldownSec': 0 });
    const c = await client(ctx);
    const first = await intentOk(ctx, c);
    await ssv(ctx, first.intentId, { transaction_id: 'txn-reuse' });
    // Lose the dedupe row so only the UNIQUE column can catch the reuse.
    await db.prepare(`DELETE FROM webhook_events WHERE id = 'ssv:txn-reuse'`).run();
    const second = await intentOk(ctx, c);
    expect((await ssv(ctx, second.intentId, { transaction_id: 'txn-reuse' })).status).toBe(200);
    expect((await rewardRow(second.intentId)).status).toBe('issued');
    expect(ctx.h.logger.find('ssv_rejected')[0]?.fields).toMatchObject({
      reason: 'duplicate_txn',
    });
    expect(await bonus(c.installId)).toBe(1);
  });
});

describe('POST /v1/rewards/intents/{intentId}/cancel and GET (03 §7.3)', () => {
  it('cancels idempotently and hides other installs’ intents (404)', async () => {
    const ctx = await setup();
    const c = await client(ctx);
    const other = await client(ctx);
    const intent = await intentOk(ctx, c);
    const version = await stateVersion(c.installId);

    expect((await cancel(ctx, other, intent.intentId)).status).toBe(404);
    expect((await status(ctx, other, intent.intentId)).status).toBe(404);
    expect((await cancel(ctx, c, intent.intentId)).status).toBe(204);
    expect((await cancel(ctx, c, intent.intentId)).status).toBe(204);
    expect(await stateVersion(c.installId)).toBe(version + 1);
    expect(await (await status(ctx, c, intent.intentId)).json()).toEqual({
      status: 'cancelled',
      amount: 1,
    });
    const missing = await cancel(ctx, c, 'missing-intent');
    expect(missing.status).toBe(404);
    expect((await errorOf(missing)).code).toBe('NOT_FOUND');
  });
});

describe('expireRewardIntents cron (03 §12)', () => {
  it('marks issued intents past expires_at expired and bumps state_version', async () => {
    const ctx = await setup();
    const c = await client(ctx);
    const intent = await intentOk(ctx, c);
    const version = await stateVersion(c.installId);
    ctx.h.clock.advance({ seconds: 901 });
    await runScheduled(ctx.h.deps, CRON.quarterHourly);
    expect((await rewardRow(intent.intentId)).status).toBe('expired');
    expect(await stateVersion(c.installId)).toBe(version + 1);
    expect(ctx.h.logger.find('cron_job')).toContainEqual(
      expect.objectContaining({
        fields: expect.objectContaining({ job: 'expireRewardIntents' }) as unknown,
      }),
    );
  });
});
