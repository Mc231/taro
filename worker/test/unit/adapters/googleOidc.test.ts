import { beforeAll, beforeEach, describe, expect, it } from 'vitest';
import {
  GOOGLE_JWKS_CACHE_KEY,
  GOOGLE_JWKS_CACHE_TTL_SEC,
  GOOGLE_JWKS_URL,
  GoogleJwksOidcVerifier,
  JWKS_REFETCH_MIN_INTERVAL_SEC,
  parseJwks,
} from '../../../src/adapters/google/GoogleOidcVerifier';
import { FixedClock } from '../../fakes/FixedClock';
import { bindings, TEST_PUBSUB_AUDIENCE, TEST_PUBSUB_SA } from '../../fakes/testDeps';
import { createOidcKey, jwks, pushToken, type OidcTestKey } from '../../helpers/googleOidc';
import { json, networkError, StubFetch } from '../../helpers/stubFetch';

/**
 * `GoogleJwksOidcVerifier` (03 §6.4, §15.2): Pub/Sub push OIDC tokens signed
 * with an RS256 key generated in the test, Google's JWKS served by a stubbed
 * `fetch` and cached in the real miniflare `CACHE_KV`. No network.
 */
const expected = { audience: TEST_PUBSUB_AUDIENCE, email: TEST_PUBSUB_SA };
const cache = bindings.CACHE_KV;
let key: OidcTestKey;
let clock: FixedClock;

beforeAll(async () => {
  key = await createOidcKey('kid-a');
});

beforeEach(async () => {
  await cache.delete(GOOGLE_JWKS_CACHE_KEY);
  clock = new FixedClock();
});

function verifierWith(stub: StubFetch): GoogleJwksOidcVerifier {
  return new GoogleJwksOidcVerifier({ fetch: stub.fetch, clock, cache });
}

describe('GoogleJwksOidcVerifier.verify', () => {
  it('accepts a push token with the expected issuer, audience and verified email', async () => {
    const stub = new StubFetch().reply(json(jwks(key)));
    const verifier = verifierWith(stub);
    expect(await verifier.verify(await pushToken(key, clock.now()), expected)).toBe(true);
    expect(stub.requests.map((r) => r.url)).toEqual([GOOGLE_JWKS_URL]);
    // Both issuer spellings Google uses are accepted.
    const bare = await pushToken(key, clock.now(), { iss: 'accounts.google.com' });
    expect(await verifier.verify(bare, expected)).toBe(true);
    // The JWKS came from the cache the second time.
    expect(stub.requests).toHaveLength(1);
  });

  it.each([
    ['another audience', { aud: 'https://evil.example/push' }],
    ['another service account', { email: 'other@taro-test.iam.gserviceaccount.com' }],
    ['an unverified email', { email_verified: false }],
    ['another issuer', { iss: 'https://evil.example' }],
    ['an expired token', { iatOffsetSec: -7200, expOffsetSec: 3600 }],
  ])('rejects %s', async (_name, claims) => {
    const verifier = verifierWith(new StubFetch().reply(json(jwks(key))));
    expect(await verifier.verify(await pushToken(key, clock.now(), claims), expected)).toBe(false);
  });

  it('rejects a token signed by a key Google does not publish, and garbage', async () => {
    const rogue = await createOidcKey('kid-a');
    const stub = new StubFetch().reply(json(jwks(key)));
    const verifier = verifierWith(stub);
    expect(await verifier.verify(await pushToken(rogue, clock.now()), expected)).toBe(false);
    expect(await verifier.verify('not-a-jwt', expected)).toBe(false);
    expect(await verifier.verify('', expected)).toBe(false);
  });

  it('refetches the JWKS for an unknown kid (key rotation), at most once per minute', async () => {
    const rotated = await createOidcKey('kid-b');
    const stub = new StubFetch().reply(json(jwks(key)), json(jwks(key, rotated)));
    const verifier = verifierWith(stub);
    expect(await verifier.verify(await pushToken(key, clock.now()), expected)).toBe(true);

    // Within the throttle window an unknown kid is not refetched.
    expect(await verifier.verify(await pushToken(rotated, clock.now()), expected)).toBe(false);
    expect(stub.requests).toHaveLength(1);

    clock.advance({ seconds: JWKS_REFETCH_MIN_INTERVAL_SEC + 1 });
    expect(await verifier.verify(await pushToken(rotated, clock.now()), expected)).toBe(true);
    expect(stub.requests).toHaveLength(2);
  });

  it('refetches once the cached set is older than its TTL', async () => {
    const stub = new StubFetch().reply(json(jwks(key)));
    const verifier = verifierWith(stub);
    expect(await verifier.verify(await pushToken(key, clock.now()), expected)).toBe(true);
    clock.advance({ seconds: GOOGLE_JWKS_CACHE_TTL_SEC + 1 });
    expect(await verifier.verify(await pushToken(key, clock.now()), expected)).toBe(true);
    expect(stub.requests).toHaveLength(2);
  });

  it('fails closed when the JWKS endpoint errors or is unreachable', async () => {
    const token = await pushToken(key, clock.now());
    expect(await verifierWith(new StubFetch().reply(json({}, 503))).verify(token, expected)).toBe(
      false,
    );
    expect(await verifierWith(new StubFetch().reply(networkError)).verify(token, expected)).toBe(
      false,
    );
    expect(
      await verifierWith(new StubFetch().reply(json({ keys: [] }))).verify(token, expected),
    ).toBe(false);
    expect(await cache.get(GOOGLE_JWKS_CACHE_KEY)).toBeNull();
  });

  it('uses a custom JWKS URL when given', async () => {
    const stub = new StubFetch().reply(json(jwks(key)));
    const verifier = new GoogleJwksOidcVerifier({
      fetch: stub.fetch,
      clock,
      cache,
      url: 'https://jwks.test.invalid/certs',
    });
    expect(await verifier.verify(await pushToken(key, clock.now()), expected)).toBe(true);
    expect(stub.requests[0]?.url).toBe('https://jwks.test.invalid/certs');
  });
});

describe('parseJwks', () => {
  it('requires a non-empty keys array', () => {
    expect(parseJwks({ keys: [{ kid: 'x' }] })).toEqual({ keys: [{ kid: 'x' }] });
    expect(() => parseJwks({ keys: [] })).toThrow('no keys');
    expect(() => parseJwks({})).toThrow('no keys');
    expect(() => parseJwks(null)).toThrow('no keys');
  });
});
