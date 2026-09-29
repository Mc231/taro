import { decodeJwt, decodeProtectedHeader, importSPKI, jwtVerify } from 'jose';
import { beforeAll, describe, expect, it } from 'vitest';
import { AppleJwsVerifier } from '../../../src/adapters/apple/AppleJwsVerifier';
import {
  APP_STORE_PRODUCTION_URL,
  APP_STORE_SANDBOX_URL,
  AppleAppStoreServerApi,
  toAppleTransaction,
  type AppStoreCredentials,
} from '../../../src/adapters/apple/AppStoreServerApi';
import { toBase64 } from '../../../src/crypto/encoding';
import { SecretConfigError } from '../../../src/crypto/keyring';
import { FixedClock } from '../../fakes/FixedClock';
import {
  appleTransactionPayload,
  createAppleTestChain,
  signAppleJws,
  type AppleTestChain,
} from '../../helpers/apple_jws';
import { json, networkError, pkcs8Pem, StubFetch } from '../../helpers/stubFetch';

/** App Store Server API adapter (03 §6.2, 05 §1 2.1): stubbed fetch, generated keys (06 §7). */
const TXN = '2000000712345678';

describe('AppleAppStoreServerApi', () => {
  let chain: AppleTestChain;
  let credentials: AppStoreCredentials;
  let publicPem: string;
  const clock = new FixedClock('2026-09-26T10:00:00.000Z');

  beforeAll(async () => {
    chain = await createAppleTestChain();
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

  function api(stub: StubFetch, creds: () => AppStoreCredentials = () => credentials) {
    return new AppleAppStoreServerApi({
      fetch: stub.fetch,
      clock,
      credentials: creds,
      jws: new AppleJwsVerifier({ clock, rootCertificatePem: chain.rootPem }),
    });
  }

  async function signed(overrides: Record<string, unknown> = {}): Promise<Response> {
    return json({
      signedTransactionInfo: await signAppleJws(chain, appleTransactionPayload(overrides)),
    });
  }

  it('calls production with an ES256 JWT and returns the verified transaction', async () => {
    const stub = new StubFetch().reply(
      await signed({ appAccountToken: 'ABCDEF01-2345-4678-9ABC-DEF012345678' }),
    );
    const result = await api(stub).getTransaction(TXN);
    expect(result).toEqual({
      ok: true,
      transaction: {
        transactionId: TXN,
        originalTransactionId: TXN,
        bundleId: 'com.vshyrochuk.taro',
        productId: 'com.vshyrochuk.taro.readings_3',
        type: 'Consumable',
        environment: 'Production',
        appAccountToken: 'abcdef01-2345-4678-9abc-def012345678',
        purchaseDate: Date.parse('2026-09-26T09:59:00Z'),
        revocationDate: null,
        quantity: 1,
      },
    });
    expect(stub.requests).toHaveLength(1);
    const request = stub.requests[0];
    expect(request?.url).toBe(`${APP_STORE_PRODUCTION_URL}/inApps/v1/transactions/${TXN}`);
    const jwt = String(request?.headers.get('authorization')).replace(/^Bearer /, '');
    expect(decodeProtectedHeader(jwt)).toEqual({ alg: 'ES256', kid: 'ASCKEY1234', typ: 'JWT' });
    const { payload } = await jwtVerify(jwt, await importSPKI(publicPem, 'ES256'), {
      audience: 'appstoreconnect-v1',
      issuer: 'issuer-uuid',
      currentDate: clock.now(),
    });
    expect(payload['bid']).toBe('com.vshyrochuk.taro');
    expect(decodeJwt(jwt).exp).toBe(Math.floor(clock.now().getTime() / 1000) + 1200);
  });

  it('retries against sandbox only on 4040010 (App Review)', async () => {
    const stub = new StubFetch().reply(
      json({ errorCode: 4040010, errorMessage: 'Transaction id not found.' }, 404),
      await signed({ environment: 'Sandbox' }),
    );
    const result = await api(stub).getTransaction(TXN);
    expect(result.ok && result.transaction.environment).toBe('Sandbox');
    expect(stub.requests.map((r) => r.url)).toEqual([
      `${APP_STORE_PRODUCTION_URL}/inApps/v1/transactions/${TXN}`,
      `${APP_STORE_SANDBOX_URL}/inApps/v1/transactions/${TXN}`,
    ]);
  });

  it('maps missing transactions to not_found', async () => {
    const both = new StubFetch().reply(json({ errorCode: 4040010 }, 404));
    expect(await api(both).getTransaction(TXN)).toEqual({ ok: false, reason: 'not_found' });
    expect(both.requests).toHaveLength(2);

    const invalidId = new StubFetch().reply(json({ errorCode: 4000006 }, 400));
    expect(await api(invalidId).getTransaction(TXN)).toEqual({ ok: false, reason: 'not_found' });
    expect(invalidId.requests).toHaveLength(1);

    const noBody = new StubFetch().reply(new Response('nope', { status: 404 }));
    expect(await api(noBody).getTransaction(TXN)).toEqual({ ok: false, reason: 'not_found' });

    const malformed = new StubFetch();
    expect(await api(malformed).getTransaction('12ab/../x')).toEqual({
      ok: false,
      reason: 'not_found',
    });
    expect(malformed.requests).toHaveLength(0);
  });

  it('maps outages, auth errors and missing secrets to unavailable', async () => {
    for (const reply of [json({}, 500), json({}, 401), json({}, 429)]) {
      const stub = new StubFetch().reply(reply);
      expect(await api(stub).getTransaction(TXN)).toEqual({ ok: false, reason: 'unavailable' });
    }
    const offline = new StubFetch().reply(networkError);
    expect(await api(offline).getTransaction(TXN)).toEqual({ ok: false, reason: 'unavailable' });

    const unset = new StubFetch();
    const missing = api(unset, () => {
      throw new SecretConfigError('APPLE_ASC_* is not set');
    });
    expect(await missing.getTransaction(TXN)).toEqual({ ok: false, reason: 'unavailable' });
    expect(unset.requests).toHaveLength(0);
  });

  it('maps an unverifiable or malformed answer to invalid', async () => {
    const tampered = new StubFetch().reply(
      json({
        signedTransactionInfo: await signAppleJws(chain, appleTransactionPayload(), {
          tamperSignature: true,
        }),
      }),
    );
    expect(await api(tampered).getTransaction(TXN)).toEqual({ ok: false, reason: 'invalid' });
    for (const body of [json({}), new Response('not json', { status: 200 })]) {
      const stub = new StubFetch().reply(body);
      expect(await api(stub).getTransaction(TXN)).toEqual({ ok: false, reason: 'invalid' });
    }
    const incomplete = new StubFetch().reply(await signed({ bundleId: undefined }));
    expect(await api(incomplete).getTransaction(TXN)).toEqual({ ok: false, reason: 'invalid' });
  });

  it('verifies a client-supplied signedTransaction locally', async () => {
    const stub = new StubFetch();
    const client = api(stub);
    const jws = await signAppleJws(chain, appleTransactionPayload({ quantity: 2 }));
    const ok = await client.verifySignedTransaction(jws);
    expect(ok.ok && ok.transaction.quantity).toBe(2);
    expect(await client.verifySignedTransaction('x.y.z')).toEqual({ ok: false, reason: 'invalid' });
    expect(stub.requests).toHaveLength(0);
  });
});

describe('toAppleTransaction', () => {
  it('requires the identifying fields and normalises optional ones', () => {
    const base = appleTransactionPayload();
    expect(toAppleTransaction(base)).toMatchObject({ quantity: 1, appAccountToken: null });
    for (const field of ['transactionId', 'bundleId', 'productId', 'type', 'environment']) {
      expect(toAppleTransaction({ ...base, [field]: '' }), field).toBeNull();
    }
    expect(
      toAppleTransaction({
        ...base,
        originalTransactionId: 5,
        quantity: 0,
        revocationDate: 1_790_000_000_000,
        purchaseDate: 'soon',
      }),
    ).toMatchObject({
      originalTransactionId: null,
      quantity: 1,
      revocationDate: 1_790_000_000_000,
      purchaseDate: null,
    });
    expect(toAppleTransaction({ ...base, quantity: 3.7 })?.quantity).toBe(3);
  });
});
