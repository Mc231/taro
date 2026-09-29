import { decodeJwt, decodeProtectedHeader } from 'jose';
import { beforeAll, describe, expect, it } from 'vitest';
import {
  ACCESS_TOKEN_CACHE_TTL_SEC,
  GoogleAccessTokenProvider,
  parseServiceAccount,
  PLAY_INTEGRITY_SCOPE,
} from '../../../src/adapters/google/GoogleAccessTokenProvider';
import {
  androidPackageNames,
  GooglePlayIntegrityVerifier,
  PLAY_INTEGRITY_BASE_URL,
} from '../../../src/adapters/google/PlayIntegrityVerifier';
import type { PlayIntegrityInput } from '../../../src/ports/PlayIntegrityVerifier';
import { bindings, uniqueId } from '../../fakes/testDeps';
import { FixedClock } from '../../fakes/FixedClock';
import { json, networkError, pkcs8Pem, StubFetch } from '../../helpers/stubFetch';
import decodeFixture from '../../fixtures/http/play_integrity/decode_integrity_token.json';
import tokenFixture from '../../fixtures/http/google/oauth_token.json';

const NOW = '2026-09-26T10:00:00.000Z';
const HASH = 'expected-request-hash';
const ALLOWED = [
  'TEAMID1234.com.vshyrochuk.taro',
  'com.vshyrochuk.taro',
  'com.vshyrochuk.taro.stg',
];

type Payload = (typeof decodeFixture)['tokenPayloadExternal'];

/** The sanitised recorded payload with the test's request hash and a fresh timestamp. */
function payload(edit: (p: Payload) => void = () => undefined): { tokenPayloadExternal: Payload } {
  const copy = structuredClone(decodeFixture.tokenPayloadExternal);
  copy.requestDetails.requestHash = HASH;
  edit(copy);
  return { tokenPayloadExternal: copy };
}

function verifier(
  stub: StubFetch,
  options: { requireRecognizedApp?: boolean; token?: () => Promise<string> } = {},
) {
  return new GooglePlayIntegrityVerifier({
    fetch: stub.fetch,
    clock: new FixedClock(NOW),
    accessToken: options.token ?? (() => Promise.resolve('access-token')),
    requireRecognizedApp: options.requireRecognizedApp ?? true,
  });
}

const input: PlayIntegrityInput = {
  token: 'integrity-token',
  expectedRequestHash: HASH,
  allowedPackageNames: ALLOWED,
};

describe('GooglePlayIntegrityVerifier (Standard API only, RC87)', () => {
  it('decodes via decodeIntegrityToken and reports the verdicts', async () => {
    const stub = new StubFetch().reply(json(payload()));
    expect(await verifier(stub).verify(input)).toEqual({
      ok: true,
      deviceVerdict: 'device',
      appRecognized: true,
      packageName: 'com.vshyrochuk.taro',
      licensed: true,
    });
    const [request] = stub.requests;
    expect(request?.url).toBe(
      `${PLAY_INTEGRITY_BASE_URL}/com.vshyrochuk.taro:decodeIntegrityToken`,
    );
    expect(request?.headers.get('authorization')).toBe('Bearer access-token');
    expect(JSON.parse(request?.body ?? '')).toEqual({ integrity_token: 'integrity-token' });
  });

  it('tries the next allowed package when Google rejects the first (staging .stg, RC78)', async () => {
    const stub = new StubFetch().reply(
      json({ error: { code: 400, status: 'INVALID_ARGUMENT' } }, 400),
      json(
        payload((p) => {
          p.requestDetails.requestPackageName = 'com.vshyrochuk.taro.stg';
          p.appIntegrity.packageName = 'com.vshyrochuk.taro.stg';
        }),
      ),
    );
    expect(await verifier(stub).verify(input)).toMatchObject({
      ok: true,
      packageName: 'com.vshyrochuk.taro.stg',
    });
    expect(stub.requests.map((r) => r.url)).toEqual([
      `${PLAY_INTEGRITY_BASE_URL}/com.vshyrochuk.taro:decodeIntegrityToken`,
      `${PLAY_INTEGRITY_BASE_URL}/com.vshyrochuk.taro.stg:decodeIntegrityToken`,
    ]);
  });

  it.each<[string, (p: Payload) => void, string]>([
    [
      'a different request hash',
      (p) => {
        p.requestDetails.requestHash = 'other';
      },
      'request_hash',
    ],
    [
      'a package outside attest.allowedAppIds',
      (p) => {
        p.requestDetails.requestPackageName = 'com.evil';
      },
      'package',
    ],
    [
      'a mismatching appIntegrity.packageName',
      (p) => {
        p.appIntegrity.packageName = 'com.evil';
      },
      'package',
    ],
    [
      'a token older than 120 s',
      (p) => {
        p.requestDetails.timestampMillis = String(Date.parse(NOW) - 121_000);
      },
      'stale',
    ],
    [
      'a timestamp far in the future',
      (p) => {
        p.requestDetails.timestampMillis = String(Date.parse(NOW) + 121_000);
      },
      'stale',
    ],
    [
      'a missing timestamp',
      (p) => {
        p.requestDetails.timestampMillis = 'x';
      },
      'stale',
    ],
    [
      'an unrecognised app version in prod',
      (p) => {
        p.appIntegrity.appRecognitionVerdict = 'UNRECOGNIZED_VERSION';
      },
      'app_unrecognized',
    ],
  ])('rejects %s', async (_label, edit, detail) => {
    const stub = new StubFetch().reply(json(payload(edit)));
    expect(await verifier(stub).verify(input)).toEqual({ ok: false, reason: 'invalid', detail });
  });

  it('maps device verdicts and app recognition outside prod', async () => {
    const run = async (edit: (p: Payload) => void, requireRecognizedApp = true) =>
      verifier(new StubFetch().reply(json(payload(edit))), { requireRecognizedApp }).verify(input);
    expect(
      await run((p) => {
        p.deviceIntegrity.deviceRecognitionVerdict = ['MEETS_BASIC_INTEGRITY'];
      }),
    ).toMatchObject({ deviceVerdict: 'basic' });
    expect(
      await run((p) => {
        p.deviceIntegrity.deviceRecognitionVerdict = ['MEETS_STRONG_INTEGRITY'];
      }),
    ).toMatchObject({ deviceVerdict: 'device' });
    expect(
      await run((p) => {
        p.deviceIntegrity.deviceRecognitionVerdict = [];
      }),
    ).toMatchObject({ deviceVerdict: 'none' });
    expect(
      await run((p) => {
        p.appIntegrity.appRecognitionVerdict = 'UNEVALUATED';
      }),
    ).toMatchObject({ ok: true, appRecognized: false });
    expect(
      await run((p) => {
        p.appIntegrity.appRecognitionVerdict = 'UNRECOGNIZED_VERSION';
      }, false),
    ).toMatchObject({ ok: true, appRecognized: false });
    const minimal = await verifier(
      new StubFetch().reply(
        json({
          tokenPayloadExternal: {
            requestDetails: {
              requestHash: HASH,
              requestPackageName: 'com.vshyrochuk.taro',
              timestampMillis: Date.parse(NOW),
            },
          },
        }),
      ),
    ).verify(input);
    expect(minimal).toEqual({
      ok: true,
      deviceVerdict: 'none',
      appRecognized: false,
      packageName: 'com.vshyrochuk.taro',
    });
  });

  it('reports outages as unavailable and unknown tokens as invalid', async () => {
    const unavailable = { ok: false, reason: 'unavailable', detail: 'decode_unavailable' };
    expect(await verifier(new StubFetch().reply(json({}, 503))).verify(input)).toEqual(unavailable);
    expect(await verifier(new StubFetch().reply(json({}, 429))).verify(input)).toEqual(unavailable);
    expect(await verifier(new StubFetch().reply(networkError)).verify(input)).toEqual(unavailable);
    expect(
      await verifier(new StubFetch(), {
        token: () => Promise.reject(new Error('no token')),
      }).verify(input),
    ).toEqual(unavailable);
    const rejected = { ok: false, reason: 'invalid', detail: 'decode_rejected' };
    expect(await verifier(new StubFetch().reply(json({}, 400))).verify(input)).toEqual(rejected);
    expect(await verifier(new StubFetch().reply(json({}))).verify(input)).toEqual(rejected);
    expect(await verifier(new StubFetch().reply(new Response('{oops'))).verify(input)).toEqual(
      rejected,
    );
    expect(
      await verifier(new StubFetch()).verify({ ...input, allowedPackageNames: ['TEAM.com.x'] }),
    ).toEqual(rejected);
  });

  it('keeps only Java package names from attest.allowedAppIds', () => {
    expect(
      androidPackageNames([
        '{TEAM}.com.vshyrochuk.taro',
        'TEAMID1234.com.vshyrochuk.taro',
        'com.vshyrochuk.taro',
        'nodots',
      ]),
    ).toEqual(['com.vshyrochuk.taro']);
  });
});

describe('GoogleAccessTokenProvider (service account, 50 min CACHE_KV cache)', () => {
  let privateKeyPem: string;

  beforeAll(async () => {
    const keys = (await crypto.subtle.generateKey(
      {
        name: 'RSASSA-PKCS1-v1_5',
        modulusLength: 2048,
        publicExponent: Uint8Array.of(1, 0, 1),
        hash: 'SHA-256',
      },
      true,
      ['sign', 'verify'],
    )) as CryptoKeyPair;
    privateKeyPem = await pkcs8Pem(keys.privateKey);
  });

  function provider(stub: StubFetch, clock = new FixedClock(NOW), cacheKey = uniqueId('oauth')) {
    return new GoogleAccessTokenProvider({
      fetch: stub.fetch,
      clock,
      cache: bindings.CACHE_KV,
      serviceAccount: () => ({
        clientEmail: 'sa@taro.iam.gserviceaccount.com',
        privateKeyPem,
        tokenUri: 'https://oauth2.googleapis.com/token',
      }),
      scope: PLAY_INTEGRITY_SCOPE,
      cacheKey,
    });
  }

  it('exchanges a signed RS256 assertion for an access token and caches it', async () => {
    const stub = new StubFetch().reply(json(tokenFixture));
    const clock = new FixedClock(NOW);
    const p = provider(stub, clock);
    expect(await p.token()).toBe(tokenFixture.access_token);
    expect(await p.token()).toBe(tokenFixture.access_token);
    expect(stub.requests).toHaveLength(1);

    const form = new URLSearchParams(stub.requests[0]?.body);
    expect(form.get('grant_type')).toBe('urn:ietf:params:oauth:grant-type:jwt-bearer');
    const assertion = form.get('assertion') ?? '';
    expect(decodeProtectedHeader(assertion)).toEqual({ alg: 'RS256', typ: 'JWT' });
    expect(decodeJwt(assertion)).toMatchObject({
      iss: 'sa@taro.iam.gserviceaccount.com',
      aud: 'https://oauth2.googleapis.com/token',
      scope: PLAY_INTEGRITY_SCOPE,
    });

    clock.advance({ seconds: ACCESS_TOKEN_CACHE_TTL_SEC + 1 });
    stub.reply(json({ ...tokenFixture, access_token: 'second' }));
    expect(await p.token()).toBe('second');
  });

  it('rejects when Google does not issue a token', async () => {
    await expect(
      provider(new StubFetch().reply(json({ error: 'invalid_grant' }, 400))).token(),
    ).rejects.toThrow(/400/);
    await expect(provider(new StubFetch().reply(json({}))).token()).rejects.toThrow(/200/);
  });

  it('parses GOOGLE_SERVICE_ACCOUNT_JSON', () => {
    expect(
      parseServiceAccount(JSON.stringify({ client_email: 'a@b', private_key: 'pem' })),
    ).toEqual({
      clientEmail: 'a@b',
      privateKeyPem: 'pem',
      tokenUri: 'https://oauth2.googleapis.com/token',
    });
    expect(
      parseServiceAccount(
        JSON.stringify({ client_email: 'a@b', private_key: 'pem', token_uri: 'https://t' }),
      ).tokenUri,
    ).toBe('https://t');
    expect(() => parseServiceAccount(undefined)).toThrow(/not set/);
    expect(() => parseServiceAccount(' ')).toThrow(/not set/);
    expect(() => parseServiceAccount('{}')).toThrow(/client_email/);
  });
});
