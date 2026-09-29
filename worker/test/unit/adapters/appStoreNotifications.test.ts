import { jwtVerify, importSPKI } from 'jose';
import { beforeAll, describe, expect, it } from 'vitest';
import { AppleJwsVerifier } from '../../../src/adapters/apple/AppleJwsVerifier';
import {
  APP_STORE_PRODUCTION_URL,
  APP_STORE_SANDBOX_URL,
  AppleAppStoreServerApi,
  consumptionRequest,
  toAppleNotification,
  type AppStoreCredentials,
} from '../../../src/adapters/apple/AppStoreServerApi';
import { toBase64 } from '../../../src/crypto/encoding';
import { SecretConfigError } from '../../../src/crypto/keyring';
import type { AppleConsumptionInfo } from '../../../src/ports/StoreApis';
import { FixedClock } from '../../fakes/FixedClock';
import {
  appleTransactionPayload,
  createAppleTestChain,
  signAppleJws,
  type AppleTestChain,
} from '../../helpers/apple_jws';
import { json, networkError, pkcs8Pem, StubFetch } from '../../helpers/stubFetch';

/**
 * App Store Server Notifications v2 and consumption information in the real
 * adapter (03 §6.4, BE Q4): payloads signed by a CA generated in the test
 * (06 §7), `fetch` stubbed. No network, no real Apple key.
 */
const TXN = '2000000712345678';
const INFO: AppleConsumptionInfo = {
  consumptionStatus: 2,
  deliveryStatus: 0,
  appAccountToken: 'abcdef01-2345-4678-9abc-def012345678',
};

function notificationPayload(overrides: Record<string, unknown> = {}): Record<string, unknown> {
  return {
    notificationType: 'REFUND',
    notificationUUID: '9f0c1a2b-3c4d-4e5f-8a9b-0c1d2e3f4a5b',
    version: '2.0',
    signedDate: Date.parse('2026-09-26T10:00:00Z'),
    data: {
      appAppleId: 1234567890,
      bundleId: 'com.vshyrochuk.taro',
      environment: 'Production',
      signedTransactionInfo: 'inner.jws.value',
    },
    ...overrides,
  };
}

describe('AppleAppStoreServerApi notifications', () => {
  let chain: AppleTestChain;
  let credentials: AppStoreCredentials;
  let publicPem: string;
  const clock = new FixedClock('2026-09-26T10:00:00.000Z');

  beforeAll(async () => {
    chain = await createAppleTestChain({ name: 'Notifications' });
    const keys = (await crypto.subtle.generateKey({ name: 'ECDSA', namedCurve: 'P-256' }, true, [
      'sign',
      'verify',
    ])) as CryptoKeyPair;
    const spki = new Uint8Array(
      (await crypto.subtle.exportKey('spki', keys.publicKey)) as ArrayBuffer,
    );
    publicPem = `-----BEGIN PUBLIC KEY-----\n${toBase64(spki)}\n-----END PUBLIC KEY-----`;
    credentials = {
      issuerId: 'issuer-uuid',
      keyId: 'ASCKEY1234',
      privateKeyPem: await pkcs8Pem(keys.privateKey),
      bundleId: 'com.vshyrochuk.taro',
    };
  });

  function api(stub = new StubFetch(), creds: () => AppStoreCredentials = () => credentials) {
    return new AppleAppStoreServerApi({
      fetch: stub.fetch,
      clock,
      credentials: creds,
      jws: new AppleJwsVerifier({ clock, rootCertificatePem: chain.rootPem }),
    });
  }

  describe('verifyNotification', () => {
    it('verifies the signedPayload chain and decodes the fields the Worker uses', async () => {
      const result = await api().verifyNotification(
        await signAppleJws(chain, notificationPayload({ subtype: 'SUMMARY' })),
      );
      expect(result).toEqual({
        ok: true,
        notification: {
          notificationType: 'REFUND',
          subtype: 'SUMMARY',
          notificationUUID: '9f0c1a2b-3c4d-4e5f-8a9b-0c1d2e3f4a5b',
          bundleId: 'com.vshyrochuk.taro',
          environment: 'Production',
          signedTransactionInfo: 'inner.jws.value',
          consumptionRequestReason: null,
        },
      });
    });

    it('rejects a bad signature, a foreign root and a payload without type or UUID', async () => {
      const verify = (jws: string) => api().verifyNotification(jws);
      expect(
        await verify(await signAppleJws(chain, notificationPayload(), { tamperSignature: true })),
      ).toEqual({ ok: false, reason: 'invalid' });
      const other = await createAppleTestChain({ name: 'Other' });
      expect(await verify(await signAppleJws(other, notificationPayload()))).toEqual({
        ok: false,
        reason: 'invalid',
      });
      expect(
        await verify(await signAppleJws(chain, notificationPayload({ notificationUUID: '' }))),
      ).toEqual({ ok: false, reason: 'invalid' });
      expect(await verify('garbage')).toEqual({ ok: false, reason: 'invalid' });
    });
  });

  it('toAppleNotification tolerates a missing or non-object data field (TEST, summaries)', () => {
    const base = { notificationType: 'TEST', notificationUUID: 'u-1' };
    for (const data of [undefined, null, [1], 'x']) {
      expect(toAppleNotification({ ...base, data })).toEqual({
        notificationType: 'TEST',
        subtype: null,
        notificationUUID: 'u-1',
        bundleId: null,
        environment: null,
        signedTransactionInfo: null,
        consumptionRequestReason: null,
      });
    }
    expect(toAppleNotification({ notificationType: 'TEST' })).toBeNull();
    expect(
      toAppleNotification({
        ...base,
        data: { consumptionRequestReason: 'UNINTENDED_PURCHASE' },
      })?.consumptionRequestReason,
    ).toBe('UNINTENDED_PURCHASE');
  });

  it('the inner signedTransactionInfo verifies with the same chain', async () => {
    const result = await api().verifySignedTransaction(
      await signAppleJws(chain, appleTransactionPayload({ transactionId: TXN })),
    );
    expect(result.ok).toBe(true);
  });

  describe('sendConsumptionInfo', () => {
    it('PUTs the ConsumptionRequest to the notification environment with an ES256 JWT', async () => {
      const stub = new StubFetch().reply(new Response(null, { status: 202 }));
      expect(await api(stub).sendConsumptionInfo(TXN, 'production', INFO)).toBe(true);
      const [request] = stub.requests;
      expect(request?.method).toBe('PUT');
      expect(request?.url).toBe(
        `${APP_STORE_PRODUCTION_URL}/inApps/v1/transactions/consumption/${TXN}`,
      );
      expect(JSON.parse(request?.body ?? '{}')).toEqual(consumptionRequest(INFO));
      const token = (request?.headers.get('authorization') ?? '').replace(/^Bearer /, '');
      const { payload } = await jwtVerify(token, await importSPKI(publicPem, 'ES256'), {
        audience: 'appstoreconnect-v1',
        currentDate: clock.now(),
      });
      expect(payload).toMatchObject({ iss: 'issuer-uuid', bid: 'com.vshyrochuk.taro' });

      const sandbox = new StubFetch().reply(new Response(null, { status: 202 }));
      expect(await api(sandbox).sendConsumptionInfo(TXN, 'sandbox', INFO)).toBe(true);
      expect(sandbox.requests[0]?.url).toBe(
        `${APP_STORE_SANDBOX_URL}/inApps/v1/transactions/consumption/${TXN}`,
      );
    });

    it('declares only delivery and consumption; everything else is undeclared', () => {
      expect(consumptionRequest(INFO)).toEqual({
        customerConsented: true,
        consumptionStatus: 2,
        deliveryStatus: 0,
        appAccountToken: INFO.appAccountToken,
        platform: 1,
        sampleContentProvided: false,
        accountTenure: 0,
        playTime: 0,
        lifetimeDollarsPurchased: 0,
        lifetimeDollarsRefunded: 0,
        userStatus: 0,
        refundPreference: 0,
      });
    });

    it('is false on an error status, a network error, missing secrets or a bad ID', async () => {
      expect(
        await api(new StubFetch().reply(json({ errorCode: 4000000 }, 400))).sendConsumptionInfo(
          TXN,
          'production',
          INFO,
        ),
      ).toBe(false);
      expect(
        await api(new StubFetch().reply(networkError)).sendConsumptionInfo(TXN, 'production', INFO),
      ).toBe(false);
      const unset = () => {
        throw new SecretConfigError('APPLE_ASC_* is not set');
      };
      const stub = new StubFetch();
      expect(await api(stub, unset).sendConsumptionInfo(TXN, 'production', INFO)).toBe(false);
      expect(await api(stub).sendConsumptionInfo('../1', 'production', INFO)).toBe(false);
      expect(stub.requests).toHaveLength(0);
    });
  });
});
