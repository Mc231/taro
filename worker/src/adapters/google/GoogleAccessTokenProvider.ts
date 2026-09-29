import { importPKCS8, SignJWT } from 'jose';
import type { Clock } from '../../ports/Clock';

/**
 * OAuth 2.0 access tokens for a Google service account (JWT bearer grant,
 * RFC 7523), cached in `CACHE_KV` for 50 minutes (03 §3.3, GLOSSARY §6.1).
 * Google tokens live 60 minutes, so a cached one always has ≥ 10 minutes left.
 * Rejects when the secret is missing or Google does not issue a token; the
 * caller maps that to `unavailable`.
 */
export interface ServiceAccount {
  readonly clientEmail: string;
  readonly privateKeyPem: string;
  readonly tokenUri: string;
}

export interface GoogleAccessTokenOptions {
  readonly fetch: typeof fetch;
  readonly clock: Clock;
  readonly cache: KVNamespace;
  /** Parsed `GOOGLE_SERVICE_ACCOUNT_JSON`, resolved on first use. */
  readonly serviceAccount: () => ServiceAccount;
  readonly scope: string;
  readonly cacheKey: string;
}

export const PLAY_INTEGRITY_SCOPE = 'https://www.googleapis.com/auth/playintegrity';
export const ACCESS_TOKEN_CACHE_TTL_SEC = 50 * 60;
const DEFAULT_TOKEN_URI = 'https://oauth2.googleapis.com/token';
const ASSERTION_TTL_SEC = 3600;

interface CachedToken {
  readonly token: string;
  readonly expiresAt: number;
}

/** Parses `GOOGLE_SERVICE_ACCOUNT_JSON` (the downloaded key file). Throws when unusable. */
export function parseServiceAccount(raw: string | undefined): ServiceAccount {
  if (raw === undefined || raw.trim() === '') {
    throw new Error('GOOGLE_SERVICE_ACCOUNT_JSON is not set');
  }
  const json = JSON.parse(raw) as Record<string, unknown>;
  const clientEmail = json['client_email'];
  const privateKey = json['private_key'];
  const tokenUri = json['token_uri'];
  if (typeof clientEmail !== 'string' || typeof privateKey !== 'string') {
    throw new Error('GOOGLE_SERVICE_ACCOUNT_JSON lacks client_email or private_key');
  }
  return {
    clientEmail,
    privateKeyPem: privateKey,
    tokenUri: typeof tokenUri === 'string' ? tokenUri : DEFAULT_TOKEN_URI,
  };
}

export class GoogleAccessTokenProvider {
  constructor(private readonly options: GoogleAccessTokenOptions) {}

  async token(): Promise<string> {
    const nowMs = this.options.clock.now().getTime();
    const cached = await this.options.cache.get<CachedToken>(this.options.cacheKey, 'json');
    if (cached !== null && cached.expiresAt > nowMs) {
      return cached.token;
    }
    const account = this.options.serviceAccount();
    const issuedAt = Math.floor(nowMs / 1000);
    const assertion = await new SignJWT({ scope: this.options.scope })
      .setProtectedHeader({ alg: 'RS256', typ: 'JWT' })
      .setIssuer(account.clientEmail)
      .setAudience(account.tokenUri)
      .setIssuedAt(issuedAt)
      .setExpirationTime(issuedAt + ASSERTION_TTL_SEC)
      .sign(await importPKCS8(account.privateKeyPem, 'RS256'));
    const res = await this.options.fetch(account.tokenUri, {
      method: 'POST',
      headers: { 'content-type': 'application/x-www-form-urlencoded' },
      body: new URLSearchParams({
        grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
        assertion,
      }).toString(),
    });
    const body: { access_token?: unknown } = res.ok ? await res.json() : {};
    if (typeof body.access_token !== 'string') {
      throw new Error(`Google token endpoint answered ${String(res.status)}`);
    }
    const entry: CachedToken = {
      token: body.access_token,
      expiresAt: nowMs + ACCESS_TOKEN_CACHE_TTL_SEC * 1000,
    };
    await this.options.cache.put(this.options.cacheKey, JSON.stringify(entry), {
      expirationTtl: ACCESS_TOKEN_CACHE_TTL_SEC,
    });
    return entry.token;
  }
}
