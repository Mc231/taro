import { beforeAll, describe, expect, it } from 'vitest';
import { AppleJwsVerifier } from '../../../src/adapters/apple/AppleJwsVerifier';
import { AppleAppStoreServerApi } from '../../../src/adapters/apple/AppStoreServerApi';
import { GOOGLE_JWKS_CACHE_KEY } from '../../../src/adapters/google/GoogleOidcVerifier';
import { buildApp, type App } from '../../../src/app';
import type { Deps } from '../../../src/deps';
import type { AppleNotification, AppleTransaction } from '../../../src/ports/StoreApis';
import { InstallRepo, type InstallRow } from '../../../src/repos/InstallRepo';
import { LedgerRepo } from '../../../src/repos/LedgerRepo';
import { PENDING_ACK_PREFIX } from '../../../src/repos/PendingAckRepo';
import { PurchaseRepo, type PurchaseRow } from '../../../src/repos/PurchaseRepo';
import { WebhookEventRepo } from '../../../src/repos/WebhookEventRepo';
import { PurchaseService, type VerifyGranted } from '../../../src/services/PurchaseService';
import { FakeAppStoreServerApi } from '../../fakes/FakeAppStoreServerApi';
import { FixedClock } from '../../fakes/FixedClock';
import { SeqIdGenerator } from '../../fakes/SeqIdGenerator';
import { bindings, createHarness, uniqueId, type TestHarness } from '../../fakes/testDeps';
import {
  appleTransactionPayload,
  createAppleTestChain,
  signAppleJws,
  type AppleTestChain,
} from '../../helpers/apple_jws';
import { APP_HEADERS, authedApp } from '../../helpers/app';
import { db, seedInstall } from '../../helpers/db';
import {
  createOidcKey,
  oidcVerifier,
  pushBody,
  pushToken,
  type OidcTestKey,
} from '../../helpers/googleOidc';
import { StubFetch } from '../../helpers/stubFetch';

/**
 * Store webhooks (03 §6.4–§6.5, 04 §12.12–§12.13, §12.21, §15; RC66):
 * `POST /v1/webhooks/appstore` (ASSN v2) and `POST /v1/webhooks/googleplay`
 * (RTDN via Pub/Sub push). Apple payloads come from `FakeAppStoreServerApi`
 * or, end to end, from the real adapter over a chain generated in the test;
 * Pub/Sub tokens are signed with an RS256 key generated in the test and
 * verified by the real `GoogleJwksOidcVerifier` over a stubbed JWKS fetch.
 */
const ledger = new LedgerRepo(db);
const purchases = new PurchaseRepo(db);
const installs = new InstallRepo(db);
const events = new WebhookEventRepo(db);

/** The value, or a thrown error when it is missing. */
function must<T>(value: T | null | undefined): T {
  if (value === null || value === undefined) {
    throw new Error('expected a value');
  }
  return value;
}

let oidcKey: OidcTestKey;
beforeAll(async () => {
  oidcKey = await createOidcKey('push-kid');
  await bindings.CACHE_KV.delete(GOOGLE_JWKS_CACHE_KEY);
});

let harnessCounter = 0;
function harness(overrides: Partial<Deps> = {}): TestHarness {
  harnessCounter++;
  const prefix = (0x6b000000 + harnessCounter).toString(16);
  const { verifier } = oidcVerifier(oidcKey, new FixedClock(), bindings.CACHE_KV);
  return createHarness({
    overrides: { ids: new SeqIdGenerator(prefix), googleOidc: verifier, ...overrides },
  });
}

let txnCounter = 0;
function txnId(): string {
  txnCounter++;
  return `4000000${String(900000000 + txnCounter)}`;
}

async function iosInstall(): Promise<InstallRow> {
  const id = uniqueId('wios');
  await seedInstall({ id, appleAccountToken: `acc-${id}` });
  return must(await installs.findById(id));
}

async function androidInstall(): Promise<InstallRow> {
  const id = uniqueId('wand');
  await seedInstall({ id, platform: 'android', playAccountHash: `play-${id}` });
  return must(await installs.findById(id));
}

/** Grants an iOS purchase to `owner` through `PurchaseService` (the verify path). */
async function buyIos(
  h: TestHarness,
  owner: InstallRow,
  overrides: Partial<AppleTransaction> = {},
): Promise<{ txn: AppleTransaction; row: PurchaseRow }> {
  const txn = h.appStore.add({
    transactionId: txnId(),
    appAccountToken: owner.appleAccountToken,
    ...overrides,
  });
  const result = (await new PurchaseService(h.deps).verify(owner, {
    platform: 'ios',
    productId: txn.productId,
    transactionId: txn.transactionId,
  })) as VerifyGranted;
  return { txn, row: must(await purchases.findById(result.purchaseId)) };
}

async function buyAndroid(h: TestHarness, owner: InstallRow, token = uniqueId('tok')) {
  h.playDeveloper.add(token, { obfuscatedExternalAccountId: owner.playAccountHash });
  const result = (await new PurchaseService(h.deps).verify(owner, {
    platform: 'android',
    productId: 'com.vshyrochuk.taro.readings_3',
    purchaseToken: token,
  })) as VerifyGranted;
  return { token, row: must(await purchases.findById(result.purchaseId)) };
}

function notification(
  fields: Partial<AppleNotification> & { readonly notificationType: string },
  txn?: AppleTransaction,
): { uuid: string; signedPayload: string } {
  const uuid = fields.notificationUUID ?? uniqueId('ntf');
  return {
    uuid,
    signedPayload: FakeAppStoreServerApi.notification({
      notificationUUID: uuid,
      ...(txn === undefined
        ? {}
        : { signedTransactionInfo: FakeAppStoreServerApi.signed(txn.transactionId) }),
      ...fields,
    }),
  };
}

async function postApple(app: App, signedPayload: unknown): Promise<Response> {
  return app.request('/v1/webhooks/appstore', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ signedPayload }),
  });
}

async function postPlay(
  app: App,
  body: unknown,
  authorization: string | null | Promise<string> = pushToken(oidcKey, new FixedClock().now()),
): Promise<Response> {
  const auth = authorization === null ? null : await authorization;
  return app.request('/v1/webhooks/googleplay', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      ...(auth === null ? {} : { Authorization: `Bearer ${auth}` }),
    },
    body: JSON.stringify(body),
  });
}

function rtdn(fields: Record<string, unknown>): Record<string, unknown> {
  return {
    version: '1.0',
    packageName: 'com.vshyrochuk.taro',
    eventTimeMillis: String(Date.parse('2026-09-26T10:00:00Z')),
    ...fields,
  };
}

async function eventStatus(id: string): Promise<string | undefined> {
  return (await events.find(id))?.status;
}

function handled(h: TestHarness): Record<string, unknown>[] {
  return h.logger.find('webhook_handled').map((e) => e.fields);
}

describe('POST /v1/webhooks/appstore (03 §6.4)', () => {
  it('REFUND revokes the purchase: negative paid → paidBlocked + purchasesAllowed=false (04 §12.21)', async () => {
    const h = harness();
    const owner = await iosInstall();
    const { txn, row } = await buyIos(h, owner);
    await ledger.append({
      installId: owner.id,
      bucket: 'paid',
      delta: -2,
      reason: 'reading_hold',
      refType: 'reading',
      refId: `spent-${owner.id}`,
      createdAt: '2026-09-26T10:00:00.000Z',
    });
    const app = buildApp(h.deps);
    const { uuid, signedPayload } = notification({ notificationType: 'REFUND' }, txn);

    const res = await postApple(app, signedPayload);
    expect(res.status).toBe(200);
    expect(await res.text()).toBe('');
    expect(await purchases.findById(row.id)).toMatchObject({ status: 'revoked' });
    expect(await eventStatus(uuid)).toBe('processed');
    expect(handled(h)).toContainEqual({
      source: 'apple',
      type: 'REFUND',
      status: 'processed',
      detail: 'revoked',
    });

    const balance = await authedApp(h).request('/v1/balance', {
      headers: { ...APP_HEADERS, 'X-Test-Install': owner.id },
    });
    expect(await balance.json()).toMatchObject({
      paid: -2,
      paidBlocked: true,
      purchasesAllowed: false,
      purchasesBlockedReason: 'refundDebt',
    });
    h.logger.expectNoSensitive(owner.id, signedPayload);
  });

  it('a duplicate delivery (same notificationUUID) changes nothing', async () => {
    const h = harness();
    const owner = await iosInstall();
    const { txn } = await buyIos(h, owner);
    const app = buildApp(h.deps);
    const { signedPayload } = notification({ notificationType: 'REFUND' }, txn);
    expect((await postApple(app, signedPayload)).status).toBe(200);
    expect((await postApple(app, signedPayload)).status).toBe(200);
    expect((await ledger.balances(owner.id)).paid).toBe(0);
    expect(await installs.findById(owner.id)).toMatchObject({ refundCount: 1 });
    expect(h.logger.find('webhook_duplicate').map((e) => e.fields)).toEqual([
      { source: 'apple', type: 'REFUND', status: 'processed' },
    ]);
    // A second REFUND notification (new UUID) for the same transaction: already revoked.
    await postApple(app, notification({ notificationType: 'REFUND' }, txn).signedPayload);
    expect((await ledger.balances(owner.id)).paid).toBe(0);
    expect(handled(h).map((f) => f['detail'])).toEqual(['revoked', 'already_revoked']);
  });

  it('REFUND_REVERSED re-grants once with purchase_reversal_regrant', async () => {
    const h = harness();
    const owner = await iosInstall();
    const { txn, row } = await buyIos(h, owner);
    const app = buildApp(h.deps);
    await postApple(app, notification({ notificationType: 'REFUND' }, txn).signedPayload);
    const reversed = notification({ notificationType: 'REFUND_REVERSED' }, txn);
    expect((await postApple(app, reversed.signedPayload)).status).toBe(200);
    expect(await purchases.findById(row.id)).toMatchObject({ status: 'reversal_regranted' });
    expect((await ledger.balances(owner.id)).paid).toBe(3);
    // A reversal for a purchase that is not revoked is a no-op.
    await postApple(app, notification({ notificationType: 'REFUND_REVERSED' }, txn).signedPayload);
    expect((await ledger.balances(owner.id)).paid).toBe(3);
    expect(handled(h).map((f) => f['detail'])).toEqual(['revoked', 'regranted', 'not_revoked']);
  });

  it('ONE_TIME_CHARGE grants to the install bound by appAccountToken (crash before verify)', async () => {
    const h = harness();
    const owner = await iosInstall();
    const txn = h.appStore.add({
      transactionId: txnId(),
      appAccountToken: owner.appleAccountToken,
      productId: 'com.vshyrochuk.taro.readings_10',
    });
    const app = buildApp(h.deps);
    const first = notification({ notificationType: 'ONE_TIME_CHARGE' }, txn);
    expect((await postApple(app, first.signedPayload)).status).toBe(200);
    expect(await purchases.findByStoreTxn('ios', txn.transactionId)).toMatchObject({
      installId: owner.id,
      credits: 10,
      accountTokenMatch: true,
    });
    expect((await ledger.balances(owner.id)).paid).toBe(10);

    // The app's later verify answers from the stored grant.
    const verified = (await new PurchaseService(h.deps).verify(owner, {
      platform: 'ios',
      productId: txn.productId,
      transactionId: txn.transactionId,
    })) as VerifyGranted;
    expect(verified.status).toBe('already_granted');
    // A second notification for the same transaction is processed, not granted twice.
    await postApple(app, notification({ notificationType: 'ONE_TIME_CHARGE' }, txn).signedPayload);
    expect((await ledger.balances(owner.id)).paid).toBe(10);
    expect(handled(h).map((f) => f['detail'])).toEqual(['granted', 'already_granted']);
  });

  it('ONE_TIME_CHARGE is ignored when unbound, unknown, wrong product, revoked or over the sandbox cap', async () => {
    const h = harness();
    const owner = await iosInstall();
    const app = buildApp(h.deps);
    const cases: [Partial<AppleTransaction>, string][] = [
      [{ appAccountToken: null }, 'unbound'],
      [{ appAccountToken: '00000000-0000-4000-8000-000000000000' }, 'unbound'],
      [{ productId: 'com.vshyrochuk.taro.remove_ads' }, 'PRODUCT_UNKNOWN'],
      [{ revocationDate: Date.parse('2026-09-26T09:59:30Z') }, 'revoked'],
      [{ bundleId: 'com.example.other' }, 'wrong_bundle'],
    ];
    for (const [overrides] of cases) {
      const txn = h.appStore.add({
        transactionId: txnId(),
        appAccountToken: owner.appleAccountToken,
        ...overrides,
      });
      const { uuid, signedPayload } = notification({ notificationType: 'ONE_TIME_CHARGE' }, txn);
      expect((await postApple(app, signedPayload)).status).toBe(200);
      expect(await eventStatus(uuid)).toBe('ignored');
    }
    h.config.set({ 'purchases.sandboxMaxCreditsPerInstallPerDay': 1 });
    const sandbox = h.appStore.add({
      transactionId: txnId(),
      appAccountToken: owner.appleAccountToken,
      environment: 'Sandbox',
    });
    await postApple(
      app,
      notification({ notificationType: 'ONE_TIME_CHARGE' }, sandbox).signedPayload,
    );
    expect(handled(h).map((f) => f['detail'])).toEqual([...cases.map((c) => c[1]), 'sandbox_cap']);
    expect((await ledger.balances(owner.id)).paid).toBe(0);
  });

  it('CONSUMPTION_REQUEST is ignored while purchases.apple.sendConsumptionInfo is off (default, BE Q4)', async () => {
    const h = harness();
    const owner = await iosInstall();
    const { txn } = await buyIos(h, owner);
    const { uuid, signedPayload } = notification(
      { notificationType: 'CONSUMPTION_REQUEST', consumptionRequestReason: 'UNINTENDED_PURCHASE' },
      txn,
    );
    expect((await postApple(buildApp(h.deps), signedPayload)).status).toBe(200);
    expect(h.appStore.consumptionCalls).toEqual([]);
    expect(await eventStatus(uuid)).toBe('ignored');
  });

  it('CONSUMPTION_REQUEST sends delivery and consumption when switched on', async () => {
    const h = harness();
    h.config.set({ 'purchases.apple.sendConsumptionInfo': true });
    const owner = await iosInstall();
    const { txn } = await buyIos(h, owner);
    const app = buildApp(h.deps);
    await postApple(
      app,
      notification({ notificationType: 'CONSUMPTION_REQUEST', environment: 'Sandbox' }, txn)
        .signedPayload,
    );
    expect(h.appStore.consumptionCalls).toEqual([
      {
        transactionId: txn.transactionId,
        environment: 'sandbox',
        info: {
          consumptionStatus: 1,
          deliveryStatus: 0,
          appAccountToken: owner.appleAccountToken,
        },
      },
    ]);

    // Unknown purchase and unbound transaction: nothing sent.
    const unknown = h.appStore.add({ transactionId: txnId() });
    await postApple(
      app,
      notification({ notificationType: 'CONSUMPTION_REQUEST' }, unknown).signedPayload,
    );
    const other = await iosInstall();
    const { txn: unboundTxn } = await buyIos(h, other);
    h.appStore.add({ ...unboundTxn, appAccountToken: null });
    await postApple(
      app,
      notification({ notificationType: 'CONSUMPTION_REQUEST' }, unboundTxn).signedPayload,
    );
    expect(h.appStore.consumptionCalls).toHaveLength(1);
    expect(handled(h).map((f) => f['detail'])).toEqual([
      'consumption_info_sent',
      'unknown_purchase',
      'unbound',
    ]);
  });

  it('a failed handler answers 500, records failed, and the retry is processed', async () => {
    const h = harness();
    h.config.set({ 'purchases.apple.sendConsumptionInfo': true });
    const owner = await iosInstall();
    const { txn } = await buyIos(h, owner);
    const app = buildApp(h.deps);
    const { uuid, signedPayload } = notification({ notificationType: 'CONSUMPTION_REQUEST' }, txn);
    h.appStore.consumptionFails = true;
    expect((await postApple(app, signedPayload)).status).toBe(500);
    expect(await eventStatus(uuid)).toBe('failed');
    expect(h.logger.find('webhook_failed').map((e) => e.fields)).toEqual([
      { source: 'apple', type: 'CONSUMPTION_REQUEST', error: 'Error' },
    ]);
    h.appStore.consumptionFails = false;
    expect((await postApple(app, signedPayload)).status).toBe(200);
    expect(await eventStatus(uuid)).toBe('processed');
  });

  it('TEST is logged; REVOKE, other types and foreign bundles are ignored', async () => {
    const h = harness();
    const owner = await iosInstall();
    const { txn } = await buyIos(h, owner);
    const app = buildApp(h.deps);
    const test = notification({ notificationType: 'TEST' });
    expect((await postApple(app, test.signedPayload)).status).toBe(200);
    expect(h.logger.find('appstore_test_notification')).toHaveLength(1);
    for (const type of ['REVOKE', 'DID_RENEW', 'CONSUMPTION_REQUEST']) {
      await postApple(app, notification({ notificationType: type }, txn).signedPayload);
    }
    await postApple(
      app,
      notification({ notificationType: 'REFUND', bundleId: 'com.example.other' }, txn)
        .signedPayload,
    );
    // Types that need a transaction but carry none, and refunds of unknown purchases.
    await postApple(app, notification({ notificationType: 'REFUND' }).signedPayload);
    await postApple(app, notification({ notificationType: 'ONE_TIME_CHARGE' }).signedPayload);
    const stranger = h.appStore.add({ transactionId: txnId() });
    await postApple(app, notification({ notificationType: 'REFUND' }, stranger).signedPayload);
    expect(handled(h).map((f) => [f['status'], f['detail']])).toEqual([
      ['processed', 'test'],
      ['ignored', 'unhandled_type'],
      ['ignored', 'unhandled_type'],
      ['ignored', 'consumption_info_disabled'],
      ['ignored', 'wrong_bundle'],
      ['ignored', 'no_transaction'],
      ['ignored', 'no_transaction'],
      ['ignored', 'unknown_purchase'],
    ]);
    expect(await purchases.findByStoreTxn('ios', txn.transactionId)).toMatchObject({
      status: 'granted',
    });
  });

  it('400 only for a bad signature (outer or inner) or an invalid body; nothing recorded', async () => {
    const h = harness();
    const app = buildApp(h.deps);
    expect((await postApple(app, 'not-a-jws')).status).toBe(400);
    const badInner = FakeAppStoreServerApi.notification({
      notificationUUID: uniqueId('ntf'),
      notificationType: 'REFUND',
      signedTransactionInfo: 'forged',
    });
    expect((await postApple(app, badInner)).status).toBe(400);
    expect((await postApple(app, '')).status).toBe(400);
    const noBody = await app.request('/v1/webhooks/appstore', { method: 'POST' });
    expect(noBody.status).toBe(400);
    expect(h.metrics.points.filter((p) => p.event === 'webhook_sig_failed')).toEqual([
      { event: 'webhook_sig_failed', code: 'apple:payload' },
      { event: 'webhook_sig_failed', code: 'apple:transaction' },
    ]);
  });

  describe('end to end through the real adapter (chain generated in the test)', () => {
    let chain: AppleTestChain;
    beforeAll(async () => {
      chain = await createAppleTestChain({ name: 'Webhook' });
    });

    function realAppStore(clock: FixedClock): AppleAppStoreServerApi {
      return new AppleAppStoreServerApi({
        fetch: new StubFetch().fetch,
        clock,
        credentials: () => {
          throw new Error('no network in this test');
        },
        jws: new AppleJwsVerifier({ clock, rootCertificatePem: chain.rootPem }),
      });
    }

    it('verifies signedPayload and the inner JWS, then refunds; a tampered payload is 400', async () => {
      const seed = harness();
      const owner = await iosInstall();
      const { txn, row } = await buyIos(seed, owner);
      const h = harness({ appStore: realAppStore(new FixedClock()) });
      const app = buildApp(h.deps);
      const inner = await signAppleJws(
        chain,
        appleTransactionPayload({
          transactionId: txn.transactionId,
          originalTransactionId: txn.transactionId,
          appAccountToken: owner.appleAccountToken,
        }),
      );
      const payload = {
        notificationType: 'REFUND',
        notificationUUID: uniqueId('ntf'),
        version: '2.0',
        data: {
          bundleId: 'com.vshyrochuk.taro',
          environment: 'Production',
          signedTransactionInfo: inner,
        },
      };
      const tampered = await signAppleJws(chain, payload, { tamperSignature: true });
      expect((await postApple(app, tampered)).status).toBe(400);
      expect(await purchases.findById(row.id)).toMatchObject({ status: 'granted' });

      expect((await postApple(app, await signAppleJws(chain, payload))).status).toBe(200);
      expect(await purchases.findById(row.id)).toMatchObject({ status: 'revoked' });

      // A valid outer payload wrapping a forged inner transaction is 400 too.
      const forgedInner = await signAppleJws(chain, appleTransactionPayload(), {
        tamperSignature: true,
      });
      const wrapped = await signAppleJws(chain, {
        ...payload,
        notificationUUID: uniqueId('ntf'),
        data: { ...payload.data, signedTransactionInfo: forgedInner },
      });
      expect((await postApple(app, wrapped)).status).toBe(400);
    });
  });
});

describe('POST /v1/webhooks/googleplay (03 §6.4)', () => {
  it('voidedPurchaseNotification revokes by purchaseToken; 204; duplicate messageId is a no-op', async () => {
    const h = harness();
    const owner = await androidInstall();
    const { token, row } = await buyAndroid(h, owner);
    const app = buildApp(h.deps);
    const messageId = uniqueId('msg');
    const body = pushBody(
      messageId,
      rtdn({
        voidedPurchaseNotification: {
          purchaseToken: token,
          orderId: row.storeTxnId,
          productType: 2,
          refundType: 1,
        },
      }),
    );
    const res = await postPlay(app, body);
    expect(res.status).toBe(204);
    expect(await purchases.findById(row.id)).toMatchObject({ status: 'revoked' });
    expect(await eventStatus(messageId)).toBe('processed');
    expect((await postPlay(app, body)).status).toBe(204);
    expect(await installs.findById(owner.id)).toMatchObject({ refundCount: 1 });
    expect(h.logger.find('webhook_duplicate')).toHaveLength(1);
    // The same void under a new messageId: already revoked.
    await postPlay(
      app,
      pushBody(uniqueId('msg'), rtdn({ voidedPurchaseNotification: { purchaseToken: token } })),
    );
    expect(await installs.findById(owner.id)).toMatchObject({ refundCount: 1 });
    expect(handled(h).map((f) => f['detail'])).toEqual(['revoked', 'already_revoked']);
    h.logger.expectNoSensitive(owner.id, token);
  });

  it('ONE_TIME_PRODUCT_PURCHASED of a license tester over the sandbox cap is ignored, not acknowledged', async () => {
    const h = harness();
    h.config.set({ 'purchases.sandboxMaxCreditsPerInstallPerDay': 1 });
    const owner = await androidInstall();
    const token = uniqueId('tok');
    h.playDeveloper.add(token, {
      obfuscatedExternalAccountId: owner.playAccountHash,
      purchaseType: 0,
    });
    const body = pushBody(
      uniqueId('msg'),
      rtdn({
        oneTimeProductNotification: {
          notificationType: 1,
          purchaseToken: token,
          sku: 'com.vshyrochuk.taro.readings_3',
        },
      }),
    );
    expect((await postPlay(buildApp(h.deps), body)).status).toBe(204);
    expect(handled(h).map((f) => f['detail'])).toEqual(['sandbox_cap']);
    expect(h.playDeveloper.acks).toEqual([]);
    expect(await purchases.findByPurchaseToken(token)).toBeNull();
  });

  it('voided: falls back to orderId; subscriptions and unknown purchases are ignored', async () => {
    const h = harness();
    const owner = await androidInstall();
    const { row } = await buyAndroid(h, owner);
    const app = buildApp(h.deps);
    await postPlay(
      app,
      pushBody(
        uniqueId('msg'),
        rtdn({
          voidedPurchaseNotification: { purchaseToken: 'unknown-token', orderId: row.storeTxnId },
        }),
      ),
    );
    expect(await purchases.findById(row.id)).toMatchObject({ status: 'revoked' });
    await postPlay(
      app,
      pushBody(
        uniqueId('msg'),
        rtdn({ voidedPurchaseNotification: { purchaseToken: 'x', productType: 1 } }),
      ),
    );
    await postPlay(
      app,
      pushBody(uniqueId('msg'), rtdn({ voidedPurchaseNotification: { purchaseToken: 'nope' } })),
    );
    await postPlay(app, pushBody(uniqueId('msg'), rtdn({ voidedPurchaseNotification: {} })));
    expect(handled(h).map((f) => f['detail'])).toEqual([
      'revoked',
      'subscription',
      'unknown_purchase',
      'unknown_purchase',
    ]);
  });

  it('ONE_TIME_PRODUCT_PURCHASED grants to the bound install and acknowledges', async () => {
    const h = harness();
    const owner = await androidInstall();
    const token = uniqueId('tok');
    h.playDeveloper.add(token, {
      obfuscatedExternalAccountId: owner.playAccountHash,
      productId: 'com.vshyrochuk.taro.readings_30',
    });
    const app = buildApp(h.deps);
    const purchased = rtdn({
      oneTimeProductNotification: {
        version: '1.0',
        notificationType: 1,
        purchaseToken: token,
        sku: 'com.vshyrochuk.taro.readings_30',
      },
    });
    expect((await postPlay(app, pushBody(uniqueId('msg'), purchased))).status).toBe(204);
    expect(await purchases.findByPurchaseToken(token)).toMatchObject({
      installId: owner.id,
      credits: 30,
    });
    expect((await ledger.balances(owner.id)).paid).toBe(30);
    expect(h.playDeveloper.acks.map((a) => a.purchaseToken)).toEqual([token]);

    // Redelivery under a new messageId: already granted, nothing to acknowledge.
    await postPlay(app, pushBody(uniqueId('msg'), purchased));
    expect((await ledger.balances(owner.id)).paid).toBe(30);
    expect(h.playDeveloper.acks).toHaveLength(1);
    expect(handled(h).map((f) => [f['status'], f['detail']])).toEqual([
      ['processed', 'granted'],
      ['processed', 'already_granted'],
    ]);
  });

  it('ONE_TIME_PRODUCT_PURCHASED: a failed acknowledgement leaves a pendingAck marker', async () => {
    const h = harness();
    const owner = await androidInstall();
    const token = uniqueId('tok');
    h.playDeveloper.add(token, { obfuscatedExternalAccountId: owner.playAccountHash });
    h.playDeveloper.ackFails = true;
    const body = pushBody(
      uniqueId('msg'),
      rtdn({
        oneTimeProductNotification: {
          notificationType: 1,
          purchaseToken: token,
          sku: 'com.vshyrochuk.taro.readings_3',
        },
      }),
    );
    expect((await postPlay(buildApp(h.deps), body)).status).toBe(204);
    const row = await purchases.findByPurchaseToken(token);
    expect(await bindings.CACHE_KV.get(`${PENDING_ACK_PREFIX}${row?.id ?? ''}`)).not.toBeNull();
  });

  it('ONE_TIME_PRODUCT_PURCHASED is ignored when unbound, pending, consumed, unknown or canceled', async () => {
    const h = harness();
    const owner = await androidInstall();
    const app = buildApp(h.deps);
    const send = (token: string, sku = 'com.vshyrochuk.taro.readings_3', type = 1) =>
      postPlay(
        app,
        pushBody(
          uniqueId('msg'),
          rtdn({
            oneTimeProductNotification: { notificationType: type, purchaseToken: token, sku },
          }),
        ),
      );
    h.playDeveloper.add('t-unbound');
    h.playDeveloper.add('t-stranger', { obfuscatedExternalAccountId: 'play-nobody' });
    h.playDeveloper.add('t-pending', {
      purchaseState: 2,
      obfuscatedExternalAccountId: owner.playAccountHash,
    });
    h.playDeveloper.add('t-consumed', {
      consumptionState: 1,
      obfuscatedExternalAccountId: owner.playAccountHash,
    });
    await send('t-unbound');
    await send('t-stranger');
    await send('t-pending');
    await send('t-consumed');
    await send('t-missing');
    await send('t-unbound', 'com.vshyrochuk.taro.remove_ads');
    await send('t-unbound', 'com.vshyrochuk.taro.readings_3', 2);
    await postPlay(
      app,
      pushBody(uniqueId('msg'), rtdn({ oneTimeProductNotification: { notificationType: 1 } })),
    );
    expect(handled(h).map((f) => f['detail'])).toEqual([
      'unbound',
      'unbound',
      'state_2',
      'consumed',
      'not_found',
      'product_unknown',
      'one_time_canceled',
      'malformed',
    ]);
    expect(h.logger.find('webhook_handled').map((e) => e.fields['type'])).toContain(
      'ONE_TIME_PRODUCT_CANCELED',
    );
    expect((await ledger.balances(owner.id)).paid).toBe(0);
  });

  it('a store outage answers 500 so Pub/Sub retries', async () => {
    const h = harness();
    const owner = await androidInstall();
    h.playDeveloper.add('t-outage', { obfuscatedExternalAccountId: owner.playAccountHash });
    h.playDeveloper.failure = 'unavailable';
    const messageId = uniqueId('msg');
    const body = pushBody(
      messageId,
      rtdn({
        oneTimeProductNotification: {
          notificationType: 1,
          purchaseToken: 't-outage',
          sku: 'com.vshyrochuk.taro.readings_3',
        },
      }),
    );
    const app = buildApp(h.deps);
    expect((await postPlay(app, body)).status).toBe(500);
    expect(await eventStatus(messageId)).toBe('failed');
    h.playDeveloper.failure = null;
    expect((await postPlay(app, body)).status).toBe(204);
    expect((await ledger.balances(owner.id)).paid).toBe(3);
  });

  it('testNotification is logged; other packages, other kinds and undecodable data are ignored', async () => {
    const h = harness();
    const app = buildApp(h.deps);
    await postPlay(app, pushBody(uniqueId('msg'), rtdn({ testNotification: { version: '1.0' } })));
    await postPlay(
      app,
      pushBody(uniqueId('msg'), rtdn({ packageName: 'com.example.other', testNotification: {} })),
    );
    await postPlay(
      app,
      pushBody(uniqueId('msg'), rtdn({ subscriptionNotification: { notificationType: 4 } })),
    );
    await postPlay(app, pushBody(uniqueId('msg'), rtdn({})));
    const undecodable = uniqueId('msg');
    await postPlay(app, { message: { messageId: undecodable, data: '%%%' } });
    await postPlay(app, { message: { messageId: uniqueId('msg') } });
    expect(h.logger.find('googleplay_test_notification')).toHaveLength(1);
    expect(
      h.logger.find('webhook_handled').map((e) => [e.fields['type'], e.fields['detail']]),
    ).toEqual([
      ['testNotification', 'test'],
      ['testNotification', 'wrong_package'],
      ['subscriptionNotification', 'unhandled_type'],
      ['unknown', 'unhandled_type'],
      ['undecodable', 'undecodable'],
      ['undecodable', 'undecodable'],
    ]);
    expect(await eventStatus(undecodable)).toBe('ignored');
  });

  it('401 without a valid Pub/Sub OIDC token; nothing is read or recorded', async () => {
    const h = harness();
    const app = buildApp(h.deps);
    const messageId = uniqueId('msg');
    const body = pushBody(messageId, rtdn({ testNotification: {} }));
    const now = new FixedClock().now();
    expect((await postPlay(app, body, null)).status).toBe(401);
    expect((await postPlay(app, body, 'garbage')).status).toBe(401);
    expect(
      (await postPlay(app, body, pushToken(oidcKey, now, { aud: 'https://evil.example' }))).status,
    ).toBe(401);
    expect(
      (await postPlay(app, body, pushToken(oidcKey, now, { email: 'x@evil.example' }))).status,
    ).toBe(401);
    // A malformed body with no token is still 401 (auth runs before validation).
    expect((await postPlay(app, { nope: true }, null)).status).toBe(401);
    expect(await events.find(messageId)).toBeNull();
    expect(h.metrics.points.filter((p) => p.event === 'webhook_sig_failed')).toHaveLength(5);

    // Valid token, invalid body → 400.
    expect((await postPlay(app, { nope: true })).status).toBe(400);
  });

  it('refuses every push while GOOGLE_PUBSUB_AUDIENCE / _SA are unset', async () => {
    const h = harness({ pubsubPush: { audience: undefined, email: undefined } });
    const res = await postPlay(
      buildApp(h.deps),
      pushBody(uniqueId('msg'), rtdn({ testNotification: {} })),
    );
    expect(res.status).toBe(401);
    expect(h.logger.find('pubsub_push_unconfigured')).toHaveLength(1);
  });
});
