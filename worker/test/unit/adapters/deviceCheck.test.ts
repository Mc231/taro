import { decodeJwt, decodeProtectedHeader, importSPKI, jwtVerify, exportSPKI } from 'jose';
import { beforeAll, describe, expect, it } from 'vitest';
import {
  AppleDeviceCheckApi,
  DEVICECHECK_DEVELOPMENT_URL,
  DEVICECHECK_PRODUCTION_URL,
  type DeviceCheckCredentials,
} from '../../../src/adapters/apple/DeviceCheckApi';
import { FixedClock } from '../../fakes/FixedClock';
import { SeqIdGenerator } from '../../fakes/SeqIdGenerator';
import { json, networkError, pkcs8Pem, StubFetch } from '../../helpers/stubFetch';

let keys: CryptoKeyPair;
let credentials: DeviceCheckCredentials;

beforeAll(async () => {
  keys = (await crypto.subtle.generateKey({ name: 'ECDSA', namedCurve: 'P-256' }, true, [
    'sign',
    'verify',
  ])) as CryptoKeyPair;
  credentials = {
    keyId: 'DCKEY12345',
    teamId: 'TEAMID1234',
    privateKeyPem: await pkcs8Pem(keys.privateKey),
  };
});

function api(stub: StubFetch, options: { development?: boolean; missing?: boolean } = {}) {
  return new AppleDeviceCheckApi({
    fetch: stub.fetch,
    clock: new FixedClock('2026-09-26T10:00:00.000Z'),
    ids: new SeqIdGenerator(),
    development: options.development ?? false,
    credentials: () => {
      if (options.missing === true) {
        throw new Error('APPLE_DEVICECHECK_* is not set');
      }
      return credentials;
    },
  });
}

describe('AppleDeviceCheckApi (03 §3.7, RC53)', () => {
  it('queries the two bits with an ES256 JWT (kid = key ID, iss = team ID)', async () => {
    const stub = new StubFetch().reply(
      json({ bit0: true, bit1: false, last_update_time: '2026-09' }),
    );
    expect(await api(stub).queryBits('device-token')).toEqual({
      ok: true,
      bit0: true,
      bit1: false,
    });

    const [request] = stub.requests;
    expect(request?.url).toBe(`${DEVICECHECK_PRODUCTION_URL}/query_two_bits`);
    expect(request?.method).toBe('POST');
    expect(JSON.parse(request?.body ?? '')).toEqual({
      device_token: 'device-token',
      transaction_id: '00000000-0000-4000-8000-000000000001',
      timestamp: Date.parse('2026-09-26T10:00:00.000Z'),
    });
    const jwt = (request?.headers.get('authorization') ?? '').replace('Bearer ', '');
    expect(decodeProtectedHeader(jwt)).toEqual({ alg: 'ES256', kid: 'DCKEY12345' });
    expect(decodeJwt(jwt)).toMatchObject({ iss: 'TEAMID1234', iat: 1790416800 });
    const publicKey = await importSPKI(await exportSPKI(keys.publicKey), 'ES256');
    await expect(
      jwtVerify(jwt, publicKey, { currentDate: new Date('2026-09-26T10:00:00Z') }),
    ).resolves.toBeDefined();
  });

  it('treats Apple’s "Failed to find bit state" as both bits unset', async () => {
    const stub = new StubFetch().reply(new Response('Failed to find bit state', { status: 200 }));
    expect(await api(stub, { development: true }).queryBits('t')).toEqual({
      ok: true,
      bit0: false,
      bit1: false,
    });
    expect(stub.requests[0]?.url).toBe(`${DEVICECHECK_DEVELOPMENT_URL}/query_two_bits`);
  });

  it('fails soft on non-200, bad JSON, network errors and missing credentials', async () => {
    expect(await api(new StubFetch().reply(json({}, 400))).queryBits('t')).toEqual({ ok: false });
    expect(await api(new StubFetch().reply(new Response('{oops'))).queryBits('t')).toEqual({
      ok: false,
    });
    expect(await api(new StubFetch().reply(networkError)).queryBits('t')).toEqual({ ok: false });
    const stub = new StubFetch().reply(json({}));
    expect(await api(stub, { missing: true }).queryBits('t')).toEqual({ ok: false });
    expect(stub.requests).toHaveLength(0);
  });

  it('updates the bits', async () => {
    const stub = new StubFetch().reply(new Response('', { status: 200 }), json({}, 500));
    const client = api(stub);
    expect(await client.updateBits('t', { bit0: true, bit1: false })).toBe(true);
    expect(stub.requests[0]?.url).toBe(`${DEVICECHECK_PRODUCTION_URL}/update_two_bits`);
    expect(JSON.parse(stub.requests[0]?.body ?? '')).toMatchObject({ bit0: true, bit1: false });
    expect(await client.updateBits('t', { bit0: true, bit1: true })).toBe(false);
    expect(
      await api(new StubFetch().reply(networkError)).updateBits('t', { bit0: true, bit1: false }),
    ).toBe(false);
  });
});
