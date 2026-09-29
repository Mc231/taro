import { createLocalJWKSet, decodeProtectedHeader, jwtVerify, type JSONWebKeySet } from 'jose';
import type { Clock } from '../../ports/Clock';
import type { GoogleOidcVerifier } from '../../ports/StoreApis';

/**
 * Pub/Sub push OIDC token verification for `POST /v1/webhooks/googleplay`
 * (03 §6.4): an RS256 JWT signed by Google (`Authorization: Bearer …`) with
 * issuer `accounts.google.com`, `aud == GOOGLE_PUBSUB_AUDIENCE`,
 * `email == GOOGLE_PUBSUB_SA` and `email_verified == true`.
 *
 * Google's JWKS (`https://www.googleapis.com/oauth2/v3/certs`) is cached in
 * `CACHE_KV` (`google:jwks`, GLOSSARY §6.1) for `GOOGLE_JWKS_CACHE_TTL_SEC`.
 * A token whose `kid` is not in the cached set triggers one refetch (Google
 * rotates keys), at most once per `JWKS_REFETCH_MIN_INTERVAL_SEC`, so forged
 * tokens with random `kid`s cannot hammer Google. Never throws: any failure,
 * including an unreachable JWKS endpoint, is `false` (Pub/Sub retries).
 */
export const GOOGLE_JWKS_URL = 'https://www.googleapis.com/oauth2/v3/certs';
export const GOOGLE_JWKS_CACHE_KEY = 'google:jwks';
export const GOOGLE_JWKS_CACHE_TTL_SEC = 6 * 3600;
export const JWKS_REFETCH_MIN_INTERVAL_SEC = 60;
export const GOOGLE_ISSUERS = ['accounts.google.com', 'https://accounts.google.com'];

export interface GoogleJwksOidcVerifierOptions {
  readonly fetch: typeof fetch;
  readonly clock: Clock;
  readonly cache: KVNamespace;
  readonly url?: string;
}

interface CachedJwks {
  readonly fetchedAt: number;
  readonly jwks: JSONWebKeySet;
}

function hasKid(jwks: JSONWebKeySet, kid: string | undefined): boolean {
  return kid !== undefined && jwks.keys.some((key) => key.kid === kid);
}

/** Parses a JWKS document; throws when it has no keys. */
export function parseJwks(document: unknown): JSONWebKeySet {
  const keys = (document as { keys?: unknown } | null)?.keys;
  if (!Array.isArray(keys) || keys.length === 0) {
    throw new Error('google jwks: no keys');
  }
  return { keys: keys as JSONWebKeySet['keys'] };
}

export class GoogleJwksOidcVerifier implements GoogleOidcVerifier {
  constructor(private readonly options: GoogleJwksOidcVerifierOptions) {}

  async verify(
    jwt: string,
    expected: { readonly audience: string; readonly email: string },
  ): Promise<boolean> {
    try {
      const { kid } = decodeProtectedHeader(jwt);
      const jwks = await this.keys(kid);
      const { payload } = await jwtVerify(jwt, createLocalJWKSet(jwks), {
        algorithms: ['RS256'],
        issuer: GOOGLE_ISSUERS,
        audience: expected.audience,
        currentDate: this.options.clock.now(),
      });
      return payload['email'] === expected.email && payload['email_verified'] === true;
    } catch {
      return false;
    }
  }

  private async keys(kid: string | undefined): Promise<JSONWebKeySet> {
    const nowMs = this.options.clock.now().getTime();
    const cached = await this.options.cache.get<CachedJwks>(GOOGLE_JWKS_CACHE_KEY, 'json');
    const fresh = cached !== null && nowMs - cached.fetchedAt < GOOGLE_JWKS_CACHE_TTL_SEC * 1000;
    if (
      fresh &&
      (hasKid(cached.jwks, kid) || nowMs - cached.fetchedAt < JWKS_REFETCH_MIN_INTERVAL_SEC * 1000)
    ) {
      return cached.jwks;
    }
    const res = await this.options.fetch(this.options.url ?? GOOGLE_JWKS_URL, {
      headers: { accept: 'application/json' },
    });
    if (!res.ok) {
      throw new Error(`google jwks: HTTP ${String(res.status)}`);
    }
    const jwks = parseJwks(await res.json());
    await this.options.cache.put(
      GOOGLE_JWKS_CACHE_KEY,
      JSON.stringify({ fetchedAt: nowMs, jwks } satisfies CachedJwks),
      { expirationTtl: GOOGLE_JWKS_CACHE_TTL_SEC },
    );
    return jwks;
  }
}
