import { beforeAll, describe, expect, it } from 'vitest';
import { AppleJwsVerifier } from '../../../src/adapters/apple/AppleJwsVerifier';
import { AppleAppStoreServerApi } from '../../../src/adapters/apple/AppStoreServerApi';
import type { Deps } from '../../../src/deps';
import { InstallRepo } from '../../../src/repos/InstallRepo';
import { LedgerRepo } from '../../../src/repos/LedgerRepo';
import {
  VerifyPurchaseGrantedSchema,
  VerifyPurchasePendingSchema,
} from '../../../src/routes/purchases';
import { SeqIdGenerator } from '../../fakes/SeqIdGenerator';
import { createHarness, uniqueId, type TestHarness } from '../../fakes/testDeps';
import {
  appleTransactionPayload,
  createAppleTestChain,
  signAppleJws,
  type AppleTestChain,
} from '../../helpers/apple_jws';
import { APP_HEADERS, authedApp, errorOf } from '../../helpers/app';
import { db, seedInstall } from '../../helpers/db';
import { json, pkcs8Pem, StubFetch } from '../../helpers/stubFetch';

/** `POST /v1/purchases/verify` **[idem]** (03 §6.2, §6.3; RC4, RC11). */
const ledger = new LedgerRepo(db);
const ANDROID = { ...APP_HEADERS, 'X-Taro-Platform': 'android' } as const;

let harnessCounter = 0;
function harness(overrides: Partial<Deps> = {}): TestHarness {
  harnessCounter++;
  const prefix = (0x7a000000 + harnessCounter).toString(16);
  return createHarness({ overrides: { ids: new SeqIdGenerator(prefix), ...overrides } });
}

let txnCounter = 0;
function txnId(): string {
  txnCounter++;
  return `2000000${String(800000000 + txnCounter)}`;
}

async function verify(
  h: TestHarness,
  installId: string,
  body: unknown,
  options: { key?: string | null; headers?: Record<string, string> } = {},
): Promise<Response> {
  const key = options.key === undefined ? uniqueId('idem') : options.key;
  return await authedApp(h).request('/v1/purchases/verify', {
    method: 'POST',
    headers: {
      ...APP_HEADERS,
      ...options.headers,
      'X-Test-Install': installId,
      'Content-Type': 'application/json',
      ...(key === null ? {} : { 'Idempotency-Key': key }),
    },
    body: JSON.stringify(body),
  });
}

function iosBody(transactionId: string, extra: Record<string, unknown> = {}) {
  return { platform: 'ios', productId: 'com.vshyrochuk.taro.readings_3', transactionId, ...extra };
}

describe('POST /v1/purchases/verify — iOS', () => {
  it('200 granted with the 03 §6.2 step 5 body; the same key replays byte for byte', async () => {
    const h = harness();
    const id = await seedInstall({ timezone: 'Europe/Berlin' });
    const txn = h.appStore.add({ transactionId: txnId() });
    const key = uniqueId('idem');
    const res = await verify(h, id, iosBody(txn.transactionId), { key });
    expect(res.status).toBe(200);
    const text = await res.text();
    const body = VerifyPurchaseGrantedSchema.parse(JSON.parse(text));
    expect(body).toMatchObject({
      status: 'granted',
      productId: 'com.vshyrochuk.taro.readings_3',
      creditsGranted: 3,
      isFirstPurchase: true,
      balance: { paid: 3, ledgerVersion: 1, purchasesAllowed: true },
    });

    const replay = await verify(h, id, iosBody(txn.transactionId), { key });
    expect(replay.status).toBe(200);
    expect(replay.headers.get('Idempotent-Replayed')).toBe('true');
    expect(await replay.text()).toBe(text);
    expect(h.appStore.lookups).toHaveLength(1);

    // A new key (a retry from the outbox after a lost response) is already_granted.
    const again = await verify(h, id, iosBody(txn.transactionId));
    expect((await again.json<{ status: string }>()).status).toBe('already_granted');
    expect(await ledger.entries(id)).toHaveLength(1);
    h.logger.expectNoSensitive(id);
  });

  it('400 when the body platform differs from X-Taro-Platform, or the body is invalid', async () => {
    const h = harness();
    const id = await seedInstall();
    const mismatch = await verify(h, id, iosBody(txnId()), {
      headers: { 'X-Taro-Platform': 'android' },
    });
    expect(mismatch.status).toBe(400);
    expect(await errorOf(mismatch)).toMatchObject({
      code: 'VALIDATION_FAILED',
      details: { issues: [{ path: 'platform' }] },
    });
    for (const body of [
      { platform: 'ios', productId: 'x' },
      { platform: 'ios', productId: 'x', transactionId: 'abc' },
      { platform: 'web', productId: 'x', transactionId: '1' },
      { platform: 'android', productId: 'x' },
    ]) {
      const res = await verify(h, id, body);
      expect(res.status, JSON.stringify(body)).toBe(400);
    }
    expect(h.appStore.lookups).toEqual([]);
  });

  it('accepts the optional support transferToken (RC84); an empty one is 400', async () => {
    const h = harness();
    const id = await seedInstall();
    const txn = h.appStore.add({ transactionId: txnId() });
    const res = await verify(h, id, iosBody(txn.transactionId, { transferToken: 'tt1.a.b' }));
    expect(res.status).toBe(200);
    expect((await res.json<{ status: string }>()).status).toBe('granted');
    const empty = await verify(h, id, iosBody(txnId(), { transferToken: '' }));
    expect(empty.status).toBe(400);
  });

  it('400 without Idempotency-Key, 401 for an unknown or deleted install', async () => {
    const h = harness();
    const id = await seedInstall();
    const noKey = await verify(h, id, iosBody(txnId()), { key: null });
    expect((await errorOf(noKey)).code).toBe('IDEMPOTENCY_KEY_REQUIRED');
    expect((await verify(h, uniqueId('ghost'), iosBody(txnId()))).status).toBe(401);
    await new InstallRepo(db).setStatus(id, 'deleted');
    expect((await verify(h, id, iosBody(txnId()))).status).toBe(401);
  });

  it('422 PURCHASE_INVALID / PRODUCT_UNKNOWN are stored for replay; 409 is not (RC49)', async () => {
    const h = harness();
    const id = await seedInstall();
    const key = uniqueId('idem');
    const missing = await verify(h, id, iosBody(txnId()), { key });
    expect(missing.status).toBe(422);
    expect(await errorOf(missing)).toMatchObject({
      code: 'PURCHASE_INVALID',
      details: { reason: 'not_found' },
    });
    const replayed = await verify(h, id, iosBody('0'), { key });
    expect((await errorOf(replayed)).code).toBe('IDEMPOTENCY_KEY_REUSED');

    const removeAds = h.appStore.add({
      transactionId: txnId(),
      productId: 'com.vshyrochuk.taro.remove_ads',
      type: 'Non-Consumable',
    });
    const unknown = await verify(h, id, iosBody(removeAds.transactionId));
    expect((await errorOf(unknown)).code).toBe('PRODUCT_UNKNOWN');

    const owner = await seedInstall();
    const claimed = h.appStore.add({ transactionId: txnId() });
    expect((await verify(h, owner, iosBody(claimed.transactionId))).status).toBe(200);
    const claimKey = uniqueId('idem');
    const conflict = await verify(h, id, iosBody(claimed.transactionId), { key: claimKey });
    expect(conflict.status).toBe(409);
    expect(await errorOf(conflict)).toMatchObject({
      code: 'PURCHASE_ALREADY_CLAIMED',
      retryable: false,
      details: { transferEligible: false },
    });
    // The 409 row was deleted: the same key runs the handler again.
    const lookups = h.appStore.lookups.length;
    expect((await verify(h, id, iosBody(claimed.transactionId), { key: claimKey })).status).toBe(
      409,
    );
    expect(h.appStore.lookups.length).toBe(lookups + 1);
  });

  it('500 INTERNAL (retryable) while the App Store is unavailable', async () => {
    const h = harness();
    const id = await seedInstall();
    h.appStore.failure = 'unavailable';
    const res = await verify(h, id, iosBody(txnId()));
    expect(res.status).toBe(500);
    expect(await errorOf(res)).toMatchObject({ code: 'INTERNAL', retryable: true });
  });

  it('10 parallel verifies with fresh keys produce one ledger row (06 §7)', async () => {
    const h = harness();
    const id = await seedInstall();
    const txn = h.appStore.add({ transactionId: txnId() });
    const responses = await Promise.all(
      Array.from({ length: 10 }, () => verify(h, id, iosBody(txn.transactionId))),
    );
    const statuses = await Promise.all(
      responses.map(async (r) => [r.status, (await r.json<{ status: string }>()).status] as const),
    );
    expect(statuses.filter(([, s]) => s === 'granted')).toHaveLength(1);
    expect(statuses.every(([code]) => code === 200)).toBe(true);
    expect(await ledger.entries(id)).toHaveLength(1);
  });
});

describe('POST /v1/purchases/verify — real App Store adapter over a generated chain', () => {
  let chain: AppleTestChain;
  let privateKeyPem: string;

  beforeAll(async () => {
    chain = await createAppleTestChain();
    const keys = (await crypto.subtle.generateKey({ name: 'ECDSA', namedCurve: 'P-256' }, true, [
      'sign',
      'verify',
    ])) as CryptoKeyPair;
    privateKeyPem = await pkcs8Pem(keys.privateKey);
  });

  function withAdapter(stub: StubFetch): TestHarness {
    const clockless = createHarness();
    const appStore = new AppleAppStoreServerApi({
      fetch: stub.fetch,
      clock: clockless.clock,
      credentials: () => ({
        issuerId: 'issuer',
        keyId: 'KEY',
        privateKeyPem,
        bundleId: 'com.vshyrochuk.taro',
      }),
      jws: new AppleJwsVerifier({ clock: clockless.clock, rootCertificatePem: chain.rootPem }),
    });
    return harness({ appStore, clock: clockless.clock });
  }

  it('grants a transaction whose signedTransactionInfo chains to the root (sandbox after 4040010)', async () => {
    const transactionId = txnId();
    const stub = new StubFetch().reply(
      json({ errorCode: 4040010 }, 404),
      json({
        signedTransactionInfo: await signAppleJws(
          chain,
          appleTransactionPayload({ transactionId, environment: 'Sandbox' }),
        ),
      }),
    );
    const h = withAdapter(stub);
    const id = await seedInstall();
    const res = await verify(h, id, iosBody(transactionId));
    expect(res.status).toBe(200);
    expect(await res.json()).toMatchObject({ status: 'granted', creditsGranted: 3 });
    expect(stub.requests).toHaveLength(2);
  });

  it('rejects a bad signature with 422 invalid_signature and grants nothing', async () => {
    const transactionId = txnId();
    const stub = new StubFetch().reply(
      json({
        signedTransactionInfo: await signAppleJws(
          chain,
          appleTransactionPayload({ transactionId }),
          { tamperSignature: true },
        ),
      }),
    );
    const h = withAdapter(stub);
    const id = await seedInstall();
    const res = await verify(h, id, iosBody(transactionId));
    expect(res.status).toBe(422);
    expect(await errorOf(res)).toMatchObject({ details: { reason: 'invalid_signature' } });
    expect(await ledger.entries(id)).toEqual([]);
  });
});

describe('POST /v1/purchases/verify — Android', () => {
  function androidBody(purchaseToken: string) {
    return {
      platform: 'android',
      productId: 'com.vshyrochuk.taro.readings_30',
      purchaseToken,
      orderId: 'GPA.client-side',
    };
  }

  it('200 granted and acknowledged; 202 pending while the payment is pending', async () => {
    const h = harness();
    const id = await seedInstall({ platform: 'android' });
    const token = uniqueId('tok');
    h.playDeveloper.add(token, { productId: 'com.vshyrochuk.taro.readings_30' });
    const res = await verify(h, id, androidBody(token), { headers: ANDROID });
    expect(res.status).toBe(200);
    expect(await res.json()).toMatchObject({ status: 'granted', creditsGranted: 30 });
    expect(h.playDeveloper.acks).toHaveLength(1);

    const pendingToken = uniqueId('tok');
    h.playDeveloper.add(pendingToken, {
      productId: 'com.vshyrochuk.taro.readings_30',
      purchaseState: 2,
    });
    const pending = await verify(h, id, androidBody(pendingToken), { headers: ANDROID });
    expect(pending.status).toBe(202);
    expect(VerifyPurchasePendingSchema.parse(await pending.json())).toEqual({ status: 'pending' });
  });
});
