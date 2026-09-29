import { describe, expect, it } from 'vitest';
import { SecretConfigError } from '../../../src/crypto/keyring';
import { toHex } from '../../../src/crypto/encoding';
import { WebCrypto } from '../../../src/adapters/cf/WebCrypto';
import type { Deps } from '../../../src/deps';
import { ApiError } from '../../../src/http/errors';
import { verifyTransferToken } from '../../../src/monetization/transferToken';
import type { AppleTransaction } from '../../../src/ports/StoreApis';
import { InstallRepo, type InstallRow } from '../../../src/repos/InstallRepo';
import { LedgerRepo } from '../../../src/repos/LedgerRepo';
import { PENDING_ACK_PREFIX } from '../../../src/repos/PendingAckRepo';
import { PurchaseRepo } from '../../../src/repos/PurchaseRepo';
import {
  PurchaseService,
  utcDayStart,
  type VerifyGranted,
  type VerifyRequest,
} from '../../../src/services/PurchaseService';
import { FakeAppStoreServerApi } from '../../fakes/FakeAppStoreServerApi';
import { SeqIdGenerator } from '../../fakes/SeqIdGenerator';
import {
  bindings,
  createHarness,
  TEST_TRANSFER_TOKEN_KEY,
  uniqueId,
  type TestHarness,
} from '../../fakes/testDeps';
import { db, seedInstall } from '../../helpers/db';

/**
 * `PurchaseService.verify` (03 §6.1–§6.3, BE8; RC9, RC10, RC63, RC66, RC85)
 * against real D1 with `FakeAppStoreServerApi` / `FakePlayDeveloperApi`
 * (04 §15). The real adapters are covered by their unit tests and by the
 * route test that drives a generated App Store chain end to end.
 */
const ledger = new LedgerRepo(db);
const purchases = new PurchaseRepo(db);
const installs = new InstallRepo(db);

let txnCounter = 0;
function txnId(): string {
  txnCounter++;
  return `2000000${String(700000000 + txnCounter)}`;
}

async function install(overrides: Parameters<typeof seedInstall>[0] = {}): Promise<InstallRow> {
  const id = await seedInstall(overrides);
  const row = await installs.findById(id);
  if (row === null) {
    throw new Error('seeded install missing');
  }
  return row;
}

async function iosInstall(): Promise<InstallRow> {
  const id = uniqueId('ios');
  return install({ id, appleAccountToken: `acc-${id}` });
}

async function androidInstall(): Promise<InstallRow> {
  const id = uniqueId('and');
  return install({ id, platform: 'android', playAccountHash: `play-${id}` });
}

function ios(transactionId: string, signedTransaction?: string): VerifyRequest {
  return {
    platform: 'ios',
    productId: 'com.vshyrochuk.taro.readings_3',
    transactionId,
    ...(signedTransaction === undefined ? {} : { signedTransaction }),
  };
}

function android(
  purchaseToken: string,
  productId = 'com.vshyrochuk.taro.readings_3',
): VerifyRequest {
  return { platform: 'android', productId, purchaseToken };
}

async function rejected(promise: Promise<unknown>): Promise<ApiError> {
  try {
    await promise;
  } catch (err) {
    if (err instanceof ApiError) {
      return err;
    }
    throw err;
  }
  throw new Error('expected an ApiError');
}

function granted(result: unknown): VerifyGranted {
  expect(result).toHaveProperty('purchaseId');
  return result as VerifyGranted;
}

let harnessCounter = 0;

/** A harness whose row IDs do not collide with other tests' (the file shares one D1). */
function freshHarness(overrides: Partial<Deps> = {}): TestHarness {
  harnessCounter++;
  const prefix = (0x5e000000 + harnessCounter).toString(16);
  return createHarness({ overrides: { ids: new SeqIdGenerator(prefix), ...overrides } });
}

function setup(overrides: Partial<Deps> = {}) {
  const h = freshHarness(overrides);
  return { h, service: new PurchaseService(h.deps) };
}

function addTxn(h: TestHarness, overrides: Partial<AppleTransaction> = {}): AppleTransaction {
  return h.appStore.add({ transactionId: txnId(), ...overrides });
}

async function paid(installId: string): Promise<number> {
  return (await ledger.balances(installId)).paid;
}

describe('PurchaseService.verifyApple (03 §6.2)', () => {
  it('grants a valid consumable once: purchases + ledger + state_version in one batch', async () => {
    const { h, service } = setup();
    const caller = await iosInstall();
    const txn = addTxn(h, { appAccountToken: caller.appleAccountToken });

    const result = granted(await service.verify(caller, ios(txn.transactionId)));
    expect(result).toMatchObject({
      status: 'granted',
      productId: 'com.vshyrochuk.taro.readings_3',
      creditsGranted: 3,
      isFirstPurchase: true,
    });
    expect(result.balance).toMatchObject({ paid: 3, ledgerVersion: caller.stateVersion + 1 });
    expect(await purchases.findByStoreTxn('ios', txn.transactionId)).toMatchObject({
      id: result.purchaseId,
      installId: caller.id,
      credits: 3,
      status: 'granted',
      environment: 'production',
      isTest: false,
      accountTokenMatch: true,
      originalTxnId: txn.transactionId,
      purchasedAt: '2026-09-26T09:59:00.000Z',
      grantedAt: '2026-09-26T10:00:00.000Z',
    });
    expect(
      (await ledger.entries(caller.id)).map((e) => [
        e.bucket,
        e.delta,
        e.reason,
        e.refType,
        e.refId,
      ]),
    ).toEqual([['paid', 3, 'purchase', 'purchase', result.purchaseId]]);
    expect(h.metrics.points).toContainEqual({
      event: 'purchase_granted',
      platform: 'ios',
      credits: 3,
      code: 'production',
    });
    expect(h.metrics.count('blocked_purchase')).toBe(0);
    h.logger.expectNoSensitive(caller.id);
  });

  it('answers a replay by the same install with the stored grant (already_granted)', async () => {
    const { h, service } = setup();
    const caller = await iosInstall();
    const first = addTxn(h);
    const second = addTxn(h, { productId: 'com.vshyrochuk.taro.readings_10' });

    const grant = granted(await service.verify(caller, ios(first.transactionId)));
    const replay = granted(await service.verify(caller, ios(first.transactionId)));
    expect(replay).toMatchObject({
      status: 'already_granted',
      purchaseId: grant.purchaseId,
      creditsGranted: 3,
      isFirstPurchase: true,
    });
    expect(replay.balance.ledgerVersion).toBe(grant.balance.ledgerVersion);

    h.clock.advance({ minutes: 1 });
    const later = granted(await service.verify(caller, ios(second.transactionId)));
    expect(later).toMatchObject({ status: 'granted', creditsGranted: 10, isFirstPurchase: false });
    expect(granted(await service.verify(caller, ios(first.transactionId))).isFirstPurchase).toBe(
      true,
    );
    expect(await paid(caller.id)).toBe(13);
    expect(await ledger.entries(caller.id)).toHaveLength(2);
  });

  it('grants quantity × catalog credits', async () => {
    const { h, service } = setup();
    const caller = await iosInstall();
    const txn = addTxn(h, { quantity: 2, productId: 'com.vshyrochuk.taro.readings_10' });
    expect(granted(await service.verify(caller, ios(txn.transactionId))).creditsGranted).toBe(20);
  });

  it('rejects a wrong bundle, unless the environment allows it (staging adds .stg, RC78)', async () => {
    const { h, service } = setup();
    const caller = await iosInstall();
    const txn = addTxn(h, { bundleId: 'com.vshyrochuk.taro.stg' });
    const err = await rejected(service.verify(caller, ios(txn.transactionId)));
    expect([err.code, err.options.details]).toEqual([
      'PURCHASE_INVALID',
      { reason: 'wrong_bundle' },
    ]);
    expect(await ledger.entries(caller.id)).toEqual([]);

    h.config.set({
      'purchases.allowedBundleIds': ['com.vshyrochuk.taro', 'com.vshyrochuk.taro.stg'],
    });
    expect(granted(await service.verify(caller, ios(txn.transactionId))).status).toBe('granted');
  });

  it('rejects unknown products and Remove Ads with PRODUCT_UNKNOWN', async () => {
    const { h, service } = setup();
    const caller = await iosInstall();
    for (const productId of ['com.vshyrochuk.taro.readings_5', 'com.vshyrochuk.taro.remove_ads']) {
      const txn = addTxn(h, { productId, type: 'Non-Consumable' });
      expect((await rejected(service.verify(caller, ios(txn.transactionId)))).code).toBe(
        'PRODUCT_UNKNOWN',
      );
    }
  });

  it.each([
    ['not_consumable', { type: 'Non-Consumable' }],
    ['revoked', { revocationDate: Date.parse('2026-09-26T09:59:30Z') }],
    ['environment', { environment: 'Xcode' }],
  ] as const)('rejects %s with 422 PURCHASE_INVALID', async (reason, overrides) => {
    const { h, service } = setup();
    const caller = await iosInstall();
    const txn = addTxn(h, overrides);
    const err = await rejected(service.verify(caller, ios(txn.transactionId)));
    expect([err.code, err.options.details]).toEqual(['PURCHASE_INVALID', { reason }]);
    expect(await purchases.findByStoreTxn('ios', txn.transactionId)).toBeNull();
  });

  it('maps store lookups: not found and bad signature → 422, outage → 500 (retryable)', async () => {
    const { h, service } = setup();
    const caller = await iosInstall();
    const missing = await rejected(service.verify(caller, ios(txnId())));
    expect([missing.code, missing.options.details]).toEqual([
      'PURCHASE_INVALID',
      { reason: 'not_found' },
    ]);
    h.appStore.failure = 'invalid';
    const bad = await rejected(service.verify(caller, ios(txnId())));
    expect(bad.options.details).toEqual({ reason: 'invalid_signature' });
    h.appStore.failure = 'unavailable';
    expect((await rejected(service.verify(caller, ios(txnId())))).code).toBe('INTERNAL');
    expect(h.logger.find('purchase_store_unavailable')).toHaveLength(1);
  });

  it('rejects a store answer for another transaction ID', async () => {
    const { h, service } = setup();
    const caller = await iosInstall();
    const other = addTxn(h);
    h.appStore.transactions.set('2000000999999999', other);
    const err = await rejected(service.verify(caller, ios('2000000999999999')));
    expect(err.options.details).toEqual({ reason: 'transaction_mismatch' });
  });

  it('accepts sandbox in prod, tagged environment=sandbox + is_test (App Review, RC63)', async () => {
    const { h, service } = setup({ environment: 'prod' });
    const caller = await iosInstall();
    const txn = addTxn(h, { environment: 'Sandbox' });
    granted(await service.verify(caller, ios(txn.transactionId)));
    expect(await purchases.findByStoreTxn('ios', txn.transactionId)).toMatchObject({
      environment: 'sandbox',
      isTest: true,
    });
    expect(h.metrics.points).toContainEqual({
      event: 'sandbox_grant',
      platform: 'ios',
      credits: 3,
    });
    expect(h.metrics.points).toContainEqual(
      expect.objectContaining({ event: 'purchase_granted', code: 'sandbox' }),
    );
  });

  it('caps sandbox credits per install per UTC day → 422 sandbox_cap (RC63)', async () => {
    const { h, service } = setup({ environment: 'prod' });
    h.config.set({ 'purchases.sandboxGlobalCreditsPerDay': 100000 });
    const caller = await iosInstall();
    const big = addTxn(h, { environment: 'Sandbox', productId: 'com.vshyrochuk.taro.readings_30' });
    granted(await service.verify(caller, ios(big.transactionId)));
    const more = addTxn(h, { environment: 'Sandbox' });
    const err = await rejected(service.verify(caller, ios(more.transactionId)));
    expect([err.code, err.options.details]).toEqual([
      'PURCHASE_INVALID',
      { reason: 'sandbox_cap' },
    ]);
    expect(await purchases.findByStoreTxn('ios', more.transactionId)).toBeNull();
    expect(await paid(caller.id)).toBe(30);
    expect(h.logger.find('sandbox_cap')).toHaveLength(1);

    // A production purchase is never capped.
    const real = addTxn(h);
    expect(granted(await service.verify(caller, ios(real.transactionId))).status).toBe('granted');
    // The next UTC day has a fresh cap.
    h.clock.set('2026-09-27T00:00:01.000Z');
    expect(granted(await service.verify(caller, ios(more.transactionId))).status).toBe('granted');
  });

  it('caps sandbox credits globally and alerts at half the global cap (RC63)', async () => {
    const { h, service } = setup({ environment: 'prod' });
    h.clock.set('2026-10-02T12:00:00.000Z');
    h.config.set({
      'purchases.sandboxGlobalCreditsPerDay': 70,
      'purchases.sandboxMaxCreditsPerInstallPerDay': 30,
    });
    const day = utcDayStart(h.clock.now());
    expect(day).toBe('2026-10-02T00:00:00.000Z');
    const a = await iosInstall();
    const b = await iosInstall();
    const c = await iosInstall();
    granted(
      await service.verify(
        a,
        ios(
          addTxn(h, { environment: 'Sandbox', productId: 'com.vshyrochuk.taro.readings_30' })
            .transactionId,
        ),
      ),
    );
    expect(h.alerter.alerts).toEqual([]);
    granted(
      await service.verify(
        b,
        ios(
          addTxn(h, { environment: 'Sandbox', productId: 'com.vshyrochuk.taro.readings_30' })
            .transactionId,
        ),
      ),
    );
    expect(h.alerter.alerts).toEqual([
      {
        kind: 'sandbox_volume',
        message: 'Sandbox/test grants today: 60 of 70 credits',
        fields: { credits: 60, cap: 70 },
      },
    ]);
    const err = await rejected(
      service.verify(
        c,
        ios(
          addTxn(h, { environment: 'Sandbox', productId: 'com.vshyrochuk.taro.readings_30' })
            .transactionId,
        ),
      ),
    );
    expect(err.options.details).toEqual({ reason: 'sandbox_cap' });
    expect(
      granted(
        await service.verify(
          c,
          ios(
            addTxn(h, { environment: 'Sandbox', productId: 'com.vshyrochuk.taro.readings_10' })
              .transactionId,
          ),
        ),
      ).creditsGranted,
    ).toBe(10);
  });

  it('grants a blocked or indebted install like any other and emits blocked_purchase (RC66)', async () => {
    const { h, service } = setup();
    const blocked = await install();
    await installs.setStatus(blocked.id, 'blocked');
    const blockedRow = await installs.findById(blocked.id);
    const result = granted(
      await service.verify(blockedRow ?? blocked, ios(addTxn(h).transactionId)),
    );
    expect(result.status).toBe('granted');
    expect(result.balance).toMatchObject({
      purchasesAllowed: false,
      purchasesBlockedReason: 'blocked',
    });
    expect(h.metrics.points).toContainEqual({
      event: 'blocked_purchase',
      platform: 'ios',
      code: 'blocked',
    });

    const indebted = await iosInstall();
    await ledger.append({
      installId: indebted.id,
      bucket: 'paid',
      delta: -10,
      reason: 'refund_revoke',
      refType: 'purchase',
      refId: uniqueId('refund'),
      createdAt: '2026-09-26T09:00:00.000Z',
    });
    const debt = granted(await service.verify(indebted, ios(addTxn(h).transactionId)));
    expect(debt.balance).toMatchObject({ paid: -7, paidBlocked: true });
    expect(h.logger.find('blocked_purchase').map((e) => e.fields['reason'])).toEqual([
      'blocked',
      'refundDebt',
    ]);
  });

  describe('binding (RC85) and transfers (03 §6.6)', () => {
    it('refuses a token bound to another active install: 409, granted to the owner instead', async () => {
      const { h, service } = setup();
      const owner = await iosInstall();
      const caller = await iosInstall();
      const txn = addTxn(h, { appAccountToken: owner.appleAccountToken });

      const err = await rejected(service.verify(caller, ios(txn.transactionId)));
      expect([err.code, err.options.details]).toEqual([
        'PURCHASE_ALREADY_CLAIMED',
        { transferEligible: false },
      ]);
      expect(await ledger.entries(caller.id)).toEqual([]);
      expect(await purchases.findByStoreTxn('ios', txn.transactionId)).toMatchObject({
        installId: owner.id,
        accountTokenMatch: true,
      });
      expect(await paid(owner.id)).toBe(3);
      h.logger.expectNoSensitive(owner.id, caller.id, String(owner.appleAccountToken));

      // The owner's own verify is an idempotent replay.
      expect(granted(await service.verify(owner, ios(txn.transactionId))).status).toBe(
        'already_granted',
      );
    });

    it('adds a transferToken when the caller proves the store account with its JWS', async () => {
      const { h, service } = setup();
      const owner = await iosInstall();
      const caller = await iosInstall();
      const txn = addTxn(h, { appAccountToken: owner.appleAccountToken });
      const err = await rejected(
        service.verify(
          caller,
          ios(txn.transactionId, FakeAppStoreServerApi.signed(txn.transactionId)),
        ),
      );
      const details = err.options.details as { transferEligible: boolean; transferToken: string };
      expect(details.transferEligible).toBe(true);
      const claims = await verifyTransferToken(
        new WebCrypto(),
        new TextEncoder().encode(TEST_TRANSFER_TOKEN_KEY),
        details.transferToken,
        h.clock.now(),
      );
      const stored = await purchases.findByStoreTxn('ios', txn.transactionId);
      expect(claims).toEqual({
        purchaseId: stored?.id,
        newInstallId: caller.id,
        expiresAt: h.clock.now().getTime() / 1000 + 7 * 24 * 3600,
      });
      h.logger.expectNoSensitive(details.transferToken);
    });

    it('first claim wins for an unbound or unknown token; a later claimant gets 409', async () => {
      const { h, service } = setup();
      const first = await iosInstall();
      const second = await iosInstall();
      const unbound = addTxn(h);
      const unknown = addTxn(h, { appAccountToken: '00000000-0000-5000-8000-00000000abcd' });
      granted(await service.verify(first, ios(unbound.transactionId)));
      granted(await service.verify(first, ios(unknown.transactionId)));
      expect(await purchases.findByStoreTxn('ios', unknown.transactionId)).toMatchObject({
        accountTokenMatch: false,
      });

      const plain = await rejected(service.verify(second, ios(unbound.transactionId)));
      expect(plain.options.details).toEqual({ transferEligible: false });
      // A JWS of a different transaction proves nothing.
      const other = addTxn(h);
      const wrongProof = await rejected(
        service.verify(
          second,
          ios(unbound.transactionId, FakeAppStoreServerApi.signed(other.transactionId)),
        ),
      );
      expect(wrongProof.options.details).toEqual({ transferEligible: false });
      const garbage = await rejected(service.verify(second, ios(unbound.transactionId, 'nope')));
      expect(garbage.options.details).toEqual({ transferEligible: false });
      const proven = await rejected(
        service.verify(
          second,
          ios(unbound.transactionId, FakeAppStoreServerApi.signed(unbound.transactionId)),
        ),
      );
      expect(proven.options.details).toMatchObject({ transferEligible: true });
      expect(await ledger.entries(second.id)).toEqual([]);
    });

    it('lets the caller claim a token bound to a blocked install (only active installs bind)', async () => {
      const { h, service } = setup();
      const owner = await iosInstall();
      await installs.setStatus(owner.id, 'blocked');
      const caller = await iosInstall();
      const txn = addTxn(h, { appAccountToken: owner.appleAccountToken });
      expect(granted(await service.verify(caller, ios(txn.transactionId))).status).toBe('granted');
      expect(await purchases.findByStoreTxn('ios', txn.transactionId)).toMatchObject({
        installId: caller.id,
        accountTokenMatch: false,
      });
    });

    it('refuses without a grant when the owner is over the sandbox cap', async () => {
      const { h, service } = setup();
      h.config.set({ 'purchases.sandboxMaxCreditsPerInstallPerDay': 0 });
      const owner = await iosInstall();
      const caller = await iosInstall();
      const txn = addTxn(h, { appAccountToken: owner.appleAccountToken, environment: 'Sandbox' });
      const err = await rejected(
        service.verify(
          caller,
          ios(txn.transactionId, FakeAppStoreServerApi.signed(txn.transactionId)),
        ),
      );
      expect(err.options.details).toEqual({ transferEligible: false });
      expect(await purchases.findByStoreTxn('ios', txn.transactionId)).toBeNull();
    });

    it('still answers 409 (without a token) when TRANSFER_TOKEN_KEY is missing', async () => {
      const h = freshHarness();
      const deps: Deps = {
        ...h.deps,
        keys: {
          ...h.deps.keys,
          transferToken: () => {
            throw new SecretConfigError('TRANSFER_TOKEN_KEY is not set');
          },
        },
      };
      const service = new PurchaseService(deps);
      const owner = await iosInstall();
      const caller = await iosInstall();
      const txn = addTxn(h, { appAccountToken: owner.appleAccountToken });
      const err = await rejected(
        service.verify(
          caller,
          ios(txn.transactionId, FakeAppStoreServerApi.signed(txn.transactionId)),
        ),
      );
      expect(err.options.details).toEqual({ transferEligible: false });
      expect(h.logger.find('transfer_token_unavailable')).toHaveLength(1);
    });
  });

  it('10 parallel verifies of one transaction produce one ledger row (06 §7)', async () => {
    const { h, service } = setup();
    const caller = await iosInstall();
    const txn = addTxn(h);
    const results = await Promise.all(
      Array.from({ length: 10 }, () => service.verify(caller, ios(txn.transactionId))),
    );
    const statuses = results.map((r) => r.status).sort();
    expect(statuses.filter((s) => s === 'granted')).toHaveLength(1);
    expect(statuses.filter((s) => s === 'already_granted')).toHaveLength(9);
    expect(new Set(results.map((r) => granted(r).purchaseId)).size).toBe(1);
    expect(await ledger.entries(caller.id)).toHaveLength(1);
    expect(await paid(caller.id)).toBe(3);
    expect((await installs.findById(caller.id))?.stateVersion).toBe(caller.stateVersion + 1);
  });
});

describe('PurchaseService.verifyGoogle (03 §6.3)', () => {
  it('grants purchaseState 0 keyed by orderId and acknowledges server-side (RC10)', async () => {
    const { h, service } = setup();
    const caller = await androidInstall();
    const token = uniqueId('tok');
    h.playDeveloper.add(token, {
      productId: 'com.vshyrochuk.taro.readings_10',
      obfuscatedExternalAccountId: caller.playAccountHash,
    });
    const result = granted(
      await service.verify(caller, android(token, 'com.vshyrochuk.taro.readings_10')),
    );
    expect(result).toMatchObject({ status: 'granted', creditsGranted: 10, isFirstPurchase: true });
    expect(await purchases.findByPurchaseToken(token)).toMatchObject({
      platform: 'android',
      storeTxnId: `GPA.${token}`,
      purchaseToken: token,
      environment: 'production',
      isTest: false,
      accountTokenMatch: true,
    });
    expect(h.playDeveloper.lookups).toEqual([
      {
        packageName: 'com.vshyrochuk.taro',
        productId: 'com.vshyrochuk.taro.readings_10',
        purchaseToken: token,
      },
    ]);
    expect(h.playDeveloper.acks).toHaveLength(1);
    expect(h.logger.find('binding_mismatch')).toEqual([]);

    // Consumed afterwards by the client: a re-verify still answers already_granted, no second ack.
    const entry = h.playDeveloper.purchases.get(token);
    if (entry !== undefined) {
      entry.purchase = { ...entry.purchase, consumptionState: 1 };
    }
    const replay = granted(
      await service.verify(caller, android(token, 'com.vshyrochuk.taro.readings_10')),
    );
    expect(replay).toMatchObject({ status: 'already_granted', purchaseId: result.purchaseId });
    expect(h.playDeveloper.acks).toHaveLength(1);
    h.logger.expectNoSensitive(caller.id, token);
  });

  it('answers 202 pending for state 2 and 422 for cancelled or unknown states', async () => {
    const { h, service } = setup();
    const caller = await androidInstall();
    const pending = uniqueId('tok');
    h.playDeveloper.add(pending, { purchaseState: 2 });
    expect(await service.verify(caller, android(pending))).toEqual({ status: 'pending' });
    expect(await purchases.findByPurchaseToken(pending)).toBeNull();
    expect(h.playDeveloper.acks).toEqual([]);

    for (const [state, reason] of [
      [1, 'cancelled'],
      [7, 'invalid_state'],
    ] as const) {
      const token = uniqueId('tok');
      h.playDeveloper.add(token, { purchaseState: state });
      const err = await rejected(service.verify(caller, android(token)));
      expect([err.code, err.options.details]).toEqual(['PURCHASE_INVALID', { reason }]);
    }
  });

  it('rejects a consumed purchase it never granted, and unknown products before calling Google', async () => {
    const { h, service } = setup();
    const caller = await androidInstall();
    const token = uniqueId('tok');
    h.playDeveloper.add(token, { consumptionState: 1 });
    expect((await rejected(service.verify(caller, android(token)))).options.details).toEqual({
      reason: 'consumed',
    });
    const unknown = await rejected(
      service.verify(caller, android(token, 'com.vshyrochuk.taro.remove_ads')),
    );
    expect(unknown.code).toBe('PRODUCT_UNKNOWN');
    expect(h.playDeveloper.lookups).toHaveLength(1);
    expect(
      (await rejected(service.verify(caller, android(uniqueId('tok'))))).options.details,
    ).toEqual({
      reason: 'not_found',
    });
    h.playDeveloper.failure = 'unavailable';
    expect((await rejected(service.verify(caller, android(token)))).code).toBe('INTERNAL');
  });

  it('first valid claim wins; another install gets 409 with a transferToken (the token proves the account)', async () => {
    const { h, service } = setup();
    const owner = await androidInstall();
    const caller = await androidInstall();
    const token = uniqueId('tok');
    h.playDeveloper.add(token, { obfuscatedExternalAccountId: owner.playAccountHash });
    granted(await service.verify(owner, android(token)));
    const err = await rejected(service.verify(caller, android(token)));
    expect(err.code).toBe('PURCHASE_ALREADY_CLAIMED');
    expect(err.options.details).toMatchObject({ transferEligible: true });
    expect(await ledger.entries(caller.id)).toEqual([]);
  });

  it('logs an obfuscated-ID mismatch but still grants (RC9)', async () => {
    const { h, service } = setup();
    const caller = await androidInstall();
    const token = uniqueId('tok');
    h.playDeveloper.add(token, { obfuscatedExternalAccountId: 'someone-else' });
    expect(granted(await service.verify(caller, android(token))).status).toBe('granted');
    expect(await purchases.findByPurchaseToken(token)).toMatchObject({ accountTokenMatch: false });
    expect(h.logger.find('binding_mismatch')).toHaveLength(1);
    expect(h.metrics.count('binding_mismatch')).toBe(1);
  });

  it('tags license-tester purchases is_test and applies the sandbox caps (RC63)', async () => {
    const { h, service } = setup();
    h.clock.set('2026-10-05T08:00:00.000Z');
    const caller = await androidInstall();
    const big = uniqueId('tok');
    h.playDeveloper.add(big, { purchaseType: 0, productId: 'com.vshyrochuk.taro.readings_30' });
    granted(await service.verify(caller, android(big, 'com.vshyrochuk.taro.readings_30')));
    expect(await purchases.findByPurchaseToken(big)).toMatchObject({
      isTest: true,
      environment: 'sandbox',
    });
    const more = uniqueId('tok');
    h.playDeveloper.add(more, { purchaseType: 0 });
    const err = await rejected(service.verify(caller, android(more)));
    expect(err.options.details).toEqual({ reason: 'sandbox_cap' });
    expect(h.playDeveloper.acks).toHaveLength(1);
  });

  it('records a failed acknowledgement as pendingAck and keeps the grant', async () => {
    const { h, service } = setup();
    const caller = await androidInstall();
    const token = uniqueId('tok');
    h.playDeveloper.add(token);
    h.playDeveloper.ackFails = true;
    const result = granted(await service.verify(caller, android(token)));
    expect(result.status).toBe('granted');
    expect(await paid(caller.id)).toBe(3);
    expect(h.logger.find('pending_ack')).toEqual([
      { level: 'warn', event: 'pending_ack', fields: { purchaseId: result.purchaseId } },
    ]);
    expect(await bindings.CACHE_KV.get(`${PENDING_ACK_PREFIX}${result.purchaseId}`)).not.toBeNull();

    // A retried verify acknowledges again (still unacknowledged at Google).
    h.playDeveloper.ackFails = false;
    expect(granted(await service.verify(caller, android(token))).status).toBe('already_granted');
    expect(h.playDeveloper.acks).toHaveLength(2);
  });

  it('keys a purchase without orderId by the token hash', async () => {
    const { h, service } = setup();
    const caller = await androidInstall();
    const token = uniqueId('tok');
    h.playDeveloper.add(token, { orderId: null, acknowledgementState: 1 });
    granted(await service.verify(caller, android(token)));
    const hash = toHex(await new WebCrypto().sha256(token));
    expect(await purchases.findByPurchaseToken(token)).toMatchObject({
      storeTxnId: `token:${hash}`,
    });
    expect(h.playDeveloper.acks).toEqual([]);
  });

  it('10 parallel verifies of one token produce one ledger row', async () => {
    const { h, service } = setup();
    const caller = await androidInstall();
    const token = uniqueId('tok');
    h.playDeveloper.add(token);
    const results = await Promise.all(
      Array.from({ length: 10 }, () => service.verify(caller, android(token))),
    );
    expect(results.filter((r) => r.status === 'granted')).toHaveLength(1);
    expect(await ledger.entries(caller.id)).toHaveLength(1);
  });
});
