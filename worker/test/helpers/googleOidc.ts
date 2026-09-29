import { exportJWK, generateKeyPair, SignJWT, type JWK } from 'jose';
import { GoogleJwksOidcVerifier } from '../../src/adapters/google/GoogleOidcVerifier';
import { toBase64, utf8 } from '../../src/crypto/encoding';
import type { Clock } from '../../src/ports/Clock';
import { TEST_PUBSUB_AUDIENCE, TEST_PUBSUB_SA } from '../fakes/testDeps';
import { json, StubFetch } from './stubFetch';

/**
 * Pub/Sub push OIDC material generated in the test (03 §15.2, 06 §7): an
 * RS256 key pair standing in for one of Google's signing keys, its JWKS, and
 * a signer for push tokens. Nothing here is a real Google key.
 */
export interface OidcTestKey {
  readonly kid: string;
  readonly privateKey: CryptoKey;
  readonly jwk: JWK;
}

export async function createOidcKey(kid = 'test-kid-1'): Promise<OidcTestKey> {
  const { privateKey, publicKey } = await generateKeyPair('RS256', { extractable: true });
  const jwk = { ...(await exportJWK(publicKey)), kid, alg: 'RS256', use: 'sig' };
  return { kid, privateKey, jwk };
}

export function jwks(...keys: readonly OidcTestKey[]): { keys: JWK[] } {
  return { keys: keys.map((k) => k.jwk) };
}

export interface PushClaims {
  readonly iss?: string;
  readonly aud?: string;
  readonly email?: string;
  readonly email_verified?: boolean;
  /** Seconds relative to `now` (default: issued now, expires in 1 h). */
  readonly iatOffsetSec?: number;
  readonly expOffsetSec?: number;
}

/** A Pub/Sub push token as Google signs it (`accounts.google.com`, RS256). */
export async function pushToken(
  key: OidcTestKey,
  now: Date,
  claims: PushClaims = {},
): Promise<string> {
  const iat = Math.floor(now.getTime() / 1000) + (claims.iatOffsetSec ?? 0);
  return new SignJWT({
    email: claims.email ?? TEST_PUBSUB_SA,
    email_verified: claims.email_verified ?? true,
  })
    .setProtectedHeader({ alg: 'RS256', kid: key.kid, typ: 'JWT' })
    .setIssuer(claims.iss ?? 'https://accounts.google.com')
    .setAudience(claims.aud ?? TEST_PUBSUB_AUDIENCE)
    .setIssuedAt(iat)
    .setExpirationTime(iat + (claims.expOffsetSec ?? 3600))
    .sign(key.privateKey);
}

/** The real verifier over a stubbed JWKS endpoint and the given KV cache. */
export function oidcVerifier(
  key: OidcTestKey,
  clock: Clock,
  cache: KVNamespace,
): { verifier: GoogleJwksOidcVerifier; stub: StubFetch } {
  const stub = new StubFetch().reply(() => json(jwks(key)));
  return { verifier: new GoogleJwksOidcVerifier({ fetch: stub.fetch, clock, cache }), stub };
}

/** A Pub/Sub push body carrying `notification` as base64 JSON. */
export function pushBody(messageId: string, notification: unknown): Record<string, unknown> {
  return {
    message: {
      messageId,
      data: toBase64(utf8(JSON.stringify(notification))),
      publishTime: '2026-09-26T10:00:00Z',
    },
    subscription: 'projects/taro-test/subscriptions/rtdn',
  };
}
