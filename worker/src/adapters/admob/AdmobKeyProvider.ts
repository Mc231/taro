import type { Clock } from '../../ports/Clock';
import type { AdmobKeyProvider } from '../../ports/StoreApis';
import { fromBase64 } from '../../crypto/encoding';

/**
 * AdMob SSV verifier keys (03 §7.2, BE14) from
 * `https://www.gstatic.com/admob/reward/verifier-keys.json`, cached in
 * `CACHE_KV` for 24 h (GLOSSARY §6.1). An unknown `key_id` triggers one
 * refetch (Google rotates keys), at most once per `REFETCH_MIN_INTERVAL_SEC`
 * so forged callbacks with random key IDs cannot hammer gstatic. A failed
 * fetch rejects (the route answers 500 and AdMob retries later).
 */
export const ADMOB_KEYS_URL = 'https://www.gstatic.com/admob/reward/verifier-keys.json';
export const ADMOB_KEYS_CACHE_KEY = 'admob:verifier-keys';
export const ADMOB_KEYS_CACHE_TTL_SEC = 24 * 3600;
export const REFETCH_MIN_INTERVAL_SEC = 60;

export interface GstaticAdmobKeyProviderOptions {
  readonly fetch: typeof fetch;
  readonly clock: Clock;
  readonly cache: KVNamespace;
  readonly url?: string;
}

/** Cached form: key ID → SPKI (DER) as base64, plus the fetch time. */
interface CachedKeys {
  readonly fetchedAt: number;
  readonly keys: Readonly<Record<string, string>>;
}

/** Parses the gstatic document `{ keys: [{ keyId, pem, base64 }] }` into key ID → SPKI base64. */
export function parseVerifierKeys(document: unknown): Record<string, string> {
  const keys = (document as { keys?: unknown } | null)?.keys;
  if (!Array.isArray(keys)) {
    throw new Error('admob keys: no keys array');
  }
  const out: Record<string, string> = {};
  for (const entry of keys as unknown[]) {
    const { keyId, base64, pem } = (entry ?? {}) as Record<string, unknown>;
    const spki = typeof base64 === 'string' ? base64 : typeof pem === 'string' ? pemBody(pem) : '';
    if ((typeof keyId === 'number' || typeof keyId === 'string') && spki !== '') {
      out[String(keyId)] = spki;
    }
  }
  if (Object.keys(out).length === 0) {
    throw new Error('admob keys: empty key set');
  }
  return out;
}

function pemBody(pem: string): string {
  return pem.replace(/-----(BEGIN|END) PUBLIC KEY-----/g, '').replace(/\s+/g, '');
}

export class GstaticAdmobKeyProvider implements AdmobKeyProvider {
  constructor(private readonly options: GstaticAdmobKeyProviderOptions) {}

  async getKey(keyId: number): Promise<Uint8Array | null> {
    const id = String(keyId);
    const nowMs = this.options.clock.now().getTime();
    const cached = await this.options.cache.get<CachedKeys>(ADMOB_KEYS_CACHE_KEY, 'json');
    const fresh = cached !== null && nowMs - cached.fetchedAt < ADMOB_KEYS_CACHE_TTL_SEC * 1000;
    const hit = fresh ? cached.keys[id] : undefined;
    if (hit !== undefined) {
      return fromBase64(hit);
    }
    if (fresh && nowMs - cached.fetchedAt < REFETCH_MIN_INTERVAL_SEC * 1000) {
      return null;
    }
    const keys = await this.fetchKeys();
    await this.options.cache.put(
      ADMOB_KEYS_CACHE_KEY,
      JSON.stringify({ fetchedAt: nowMs, keys } satisfies CachedKeys),
      { expirationTtl: ADMOB_KEYS_CACHE_TTL_SEC },
    );
    const key = keys[id];
    return key === undefined ? null : fromBase64(key);
  }

  private async fetchKeys(): Promise<Record<string, string>> {
    const res = await this.options.fetch(this.options.url ?? ADMOB_KEYS_URL, {
      headers: { accept: 'application/json' },
    });
    if (!res.ok) {
      throw new Error(`admob keys: HTTP ${String(res.status)}`);
    }
    return parseVerifierKeys(await res.json());
  }
}
