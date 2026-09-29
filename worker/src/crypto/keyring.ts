import { fromBase64 } from './encoding';

/**
 * A symmetric keyring secret such as `IDEMPOTENCY_ENC_KEY` (03 §11).
 *
 * Format: comma-separated `kid:base64url(32 bytes)` entries, current key
 * first, e.g. `k2:…,k1:…`. Rotation keeps the previous key for 7 days so no
 * stored replay body becomes unreadable. A bare base64 value (no `kid:`)
 * is a single key with kid `k0`.
 */
export interface KeyEntry {
  readonly kid: string;
  readonly key: Uint8Array;
}

export interface Keyring {
  readonly current: KeyEntry;
  get(kid: string): KeyEntry | undefined;
}

export class SecretConfigError extends Error {
  override readonly name = 'SecretConfigError';
}

const KID = /^[A-Za-z0-9_-]{1,32}$/;

export function parseKeyring(raw: string | undefined, secretName: string, keyBytes = 32): Keyring {
  if (raw === undefined || raw.trim() === '') {
    throw new SecretConfigError(`${secretName} is not set`);
  }
  const entries: KeyEntry[] = [];
  for (const part of raw.split(',')) {
    const trimmed = part.trim();
    const colon = trimmed.indexOf(':');
    const kid = colon < 0 ? 'k0' : trimmed.slice(0, colon);
    const encoded = colon < 0 ? trimmed : trimmed.slice(colon + 1);
    if (!KID.test(kid) || entries.some((e) => e.kid === kid)) {
      throw new SecretConfigError(`${secretName} has an invalid or duplicate kid`);
    }
    let key: Uint8Array;
    try {
      key = fromBase64(encoded);
    } catch {
      throw new SecretConfigError(`${secretName} key ${kid} is not base64`);
    }
    if (key.length !== keyBytes) {
      throw new SecretConfigError(`${secretName} key ${kid} must be ${String(keyBytes)} bytes`);
    }
    entries.push({ kid, key });
  }
  const current = entries.at(0);
  if (current === undefined) {
    throw new SecretConfigError(`${secretName} has no keys`);
  }
  return {
    current,
    get: (kid) => entries.find((e) => e.kid === kid),
  };
}

/** A single HMAC key secret (e.g. `IP_HASH_KEY`); any non-empty value of ≥ 16 bytes. */
export function parseHmacKey(raw: string | undefined, secretName: string): Uint8Array {
  if (raw === undefined || raw.trim().length < 16) {
    throw new SecretConfigError(`${secretName} is not set or shorter than 16 characters`);
  }
  return new TextEncoder().encode(raw.trim());
}

/** Memoises a secret parser; a missing secret throws on first use, not at startup. */
export function lazy<T>(factory: () => T): () => T {
  let cached: { value: T } | undefined;
  return () => {
    cached ??= { value: factory() };
    return cached.value;
  };
}

const UUID_SECRET = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

/** A UUID secret such as `APPLE_ACCOUNT_NS` (the UUIDv5 namespace), lower-cased. */
export function parseUuidSecret(raw: string | undefined, secretName: string): string {
  const value = raw?.trim() ?? '';
  if (!UUID_SECRET.test(value)) {
    throw new SecretConfigError(`${secretName} is not set or not a UUID`);
  }
  return value.toLowerCase();
}
