import { describe, expect, it } from 'vitest';
import { buildApp, type App } from '../../../src/app';
import type { BalanceDto } from '../../../src/domain/allowance';
import { ATTESTATION_HEADER } from '../../../src/http/middleware/attestation';
import { ERROR_TABLE } from '../../../src/http/errors';
import { insufficientCreditsError } from '../../../src/services/BalanceService';
import type { RewardIntentDto } from '../../../src/services/RewardService';
import { FakeAdmobKeyProvider } from '../../fakes/FakeAdmobKeyProvider';
import { FakeAppStoreServerApi } from '../../fakes/FakeAppStoreServerApi';
import { SeqIdGenerator } from '../../fakes/SeqIdGenerator';
import { createHarness, uniqueId, type TestHarness } from '../../fakes/testDeps';
import { newSsvSigner, signedSsvPath } from '../../helpers/admobSsv';
import { APP_HEADERS } from '../../helpers/app';
import { idemKey, registerOk, uniqueIp } from '../../helpers/identity';
import { ReadingDriver } from '../../helpers/readingDriver';

/**
 * The 03 §15.2 money flow end to end (Phase 7 "Done when"): register →
 * balance → free hold → 402 → rewarded intent → SSV → bonus hold → purchase
 * verify → paid hold → REFUND webhook → `paidBlocked` + `purchasesAllowed =
 * false`. Every step goes through `buildApp` over real D1/KV except the
 * reading holds, which are simulated through `BalanceService` (ReadingDriver)
 * until Phase 8 adds `POST /v1/readings/holds`.
 */

const KEY_ID = 4242;
const AD_UNIT_ID = 'ca-app-pub-3940256099942544/1712485313';

class UniqueIds extends SeqIdGenerator {
  override opaque(): string {
    return `int${uniqueId('flow').replace(/-/g, '')}`;
  }
}

interface Flow {
  readonly h: TestHarness;
  readonly app: App;
  readonly headers: Record<string, string>;
  readonly installId: string;
  readonly appleAccountToken: string;
}

async function start(): Promise<Flow & { signer: Awaited<ReturnType<typeof newSsvSigner>> }> {
  const keys = new FakeAdmobKeyProvider();
  const signer = await newSsvSigner(KEY_ID);
  keys.set(KEY_ID, signer.spki);
  const h = createHarness({ overrides: { admobKeys: keys, ids: new UniqueIds() } });
  const app = buildApp(h.deps);
  const ip = uniqueIp();
  const reg = await registerOk(app, { headers: { ...APP_HEADERS, 'CF-Connecting-IP': ip } });
  const token = reg.body.purchaseBinding.appleAccountToken;
  if (token === undefined) {
    throw new Error('iOS registration returned no appleAccountToken');
  }
  return {
    h,
    app,
    signer,
    installId: reg.installId,
    appleAccountToken: token,
    headers: {
      ...APP_HEADERS,
      'CF-Connecting-IP': ip,
      Authorization: `Bearer ${reg.body.installToken}`,
      [ATTESTATION_HEADER]: 'aa1.YXNzZXJ0aW9u',
    },
  };
}

async function balance(f: Flow): Promise<BalanceDto> {
  const res = await f.app.request('/v1/balance', { headers: f.headers });
  expect(res.status).toBe(200);
  return res.json<BalanceDto>();
}

describe('03 §15.2 money flow (register → … → refund webhook)', () => {
  it('moves free → 402 → bonus → paid → refund debt with the balance agreeing at every step', async () => {
    const f = await start();
    const driver = new ReadingDriver(f.h);

    // 1. Balance after registration: one free reading, nothing else.
    const initial = await balance(f);
    expect(initial).toMatchObject({
      bonus: 0,
      paid: 0,
      canRead: true,
      nextSource: 'free',
      paidBlocked: false,
      purchasesAllowed: true,
    });
    expect(initial.free.remaining).toBe(1);

    // 2. Free reading: hold + commit.
    const free = await driver.hold(f.installId);
    expect(free).toMatchObject({ kind: 'held', chargeSource: 'free' });
    expect(await driver.commit(free.readingId)).toMatchObject({
      outcome: 'committed',
      chargeSource: 'free',
    });
    const afterFree = await balance(f);
    expect(afterFree.free.remaining).toBe(0);
    expect(afterFree.canRead).toBe(false);

    // 3. Next hold → 402 INSUFFICIENT_CREDITS with freeResetsAt.
    const denied = await driver.hold(f.installId);
    if (denied.kind !== 'insufficient') {
      throw new Error(`expected 402, got ${denied.kind}`);
    }
    const error = insufficientCreditsError(denied);
    expect(error.code).toBe('INSUFFICIENT_CREDITS');
    expect(ERROR_TABLE[error.code].status).toBe(402);
    expect(error.options.details).toMatchObject({ freeResetsAt: expect.any(String) as unknown });

    // 4. Rewarded intent → signed SSV → bonus credit.
    const intentRes = await f.app.request('/v1/rewards/intents', {
      method: 'POST',
      headers: { ...f.headers, 'content-type': 'application/json', 'Idempotency-Key': idemKey() },
      body: JSON.stringify({ adUnitId: AD_UNIT_ID }),
    });
    expect(intentRes.status).toBe(201);
    const intent = await intentRes.json<RewardIntentDto>();
    const ssvPath = await signedSsvPath(f.signer, {
      ad_network: '5450213213286189855',
      ad_unit: '1712485313',
      custom_data: intent.intentId,
      reward_amount: '5',
      reward_item: 'Reward',
      timestamp: String(f.h.clock.now().getTime() - 1000),
      transaction_id: uniqueId('ssvtxn'),
      user_id: intent.intentId,
    });
    expect((await f.app.request(ssvPath)).status).toBe(200);
    const status = await f.app.request(`/v1/rewards/intents/${intent.intentId}`, {
      headers: f.headers,
    });
    expect(await status.json()).toMatchObject({ status: 'granted', amount: intent.amount });
    const afterReward = await balance(f);
    expect(afterReward).toMatchObject({ bonus: intent.amount, canRead: true, nextSource: 'bonus' });

    // 5. Bonus reading: hold + commit.
    const bonus = await driver.hold(f.installId);
    expect(bonus).toMatchObject({ kind: 'held', chargeSource: 'bonus' });
    await driver.commit(bonus.readingId);
    expect((await balance(f)).bonus).toBe(intent.amount - 1);

    // 6. Purchase verify (iOS, readings_3) → paid credits.
    const txn = f.h.appStore.add({
      transactionId: '5000000123456789',
      appAccountToken: f.appleAccountToken,
    });
    const verify = await f.app.request('/v1/purchases/verify', {
      method: 'POST',
      headers: { ...f.headers, 'Content-Type': 'application/json', 'Idempotency-Key': idemKey() },
      body: JSON.stringify({
        platform: 'ios',
        productId: txn.productId,
        transactionId: txn.transactionId,
      }),
    });
    expect(verify.status).toBe(200);
    expect(await verify.json()).toMatchObject({
      status: 'granted',
      creditsGranted: 3,
      isFirstPurchase: true,
      balance: { paid: 3 },
    });

    // 7. Paid reading: hold + commit (bonus is exhausted first when intent.amount == 1).
    for (let i = 0; i < intent.amount - 1; i++) {
      const drain = await driver.hold(f.installId);
      await driver.commit(drain.readingId);
    }
    const paid = await driver.hold(f.installId);
    expect(paid).toMatchObject({ kind: 'held', chargeSource: 'paid' });
    await driver.commit(paid.readingId);
    expect(await balance(f)).toMatchObject({ bonus: 0, paid: 2, purchasesAllowed: true });

    // 8. Spend the rest, then the App Store REFUND webhook claws back all 3 → paid −3.
    for (let i = 0; i < 2; i++) {
      const spend = await driver.hold(f.installId);
      expect(spend).toMatchObject({ kind: 'held', chargeSource: 'paid' });
      await driver.commit(spend.readingId);
    }
    const refund = await f.app.request('/v1/webhooks/appstore', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        signedPayload: FakeAppStoreServerApi.notification({
          notificationUUID: uniqueId('ntf'),
          notificationType: 'REFUND',
          signedTransactionInfo: FakeAppStoreServerApi.signed(txn.transactionId),
        }),
      }),
    });
    expect(refund.status).toBe(200);

    // 9. paidBlocked + purchasesAllowed = false (refund debt), and no read is possible.
    const final = await balance(f);
    expect(final).toMatchObject({
      bonus: 0,
      paid: -3,
      paidBlocked: true,
      purchasesAllowed: false,
      purchasesBlockedReason: 'refundDebt',
      canRead: false,
    });
    expect(final.ledgerVersion).toBeGreaterThan(initial.ledgerVersion);
    expect((await driver.hold(f.installId)).kind).toBe('insufficient');

    f.h.logger.expectNoSensitive(f.installId, f.appleAccountToken);
  });
});
