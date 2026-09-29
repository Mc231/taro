import { exportJWK, generateKeyPair } from 'jose';
import { toBase64Url, toHex } from '../crypto/encoding';
import type { Environment } from '../env';
import type { Crypto } from '../ports/Crypto';

/**
 * Worker secret generation for `scripts/gen-keys.ts` (Phase 6 Sprint 6.0,
 * 03 §11). Output formats match the parsers in `src/crypto/keyring.ts` and
 * `Ed25519TokenSigner`:
 *
 * - `TOKEN_SIGNING_KEYS`: JWKS `{"keys":[…]}` of Ed25519 private JWKs, the
 *   first one signs;
 * - `IDEMPOTENCY_ENC_KEY`: `kid:base64url(32 bytes)[,kid:…]`, current first;
 * - HMAC keys (`CHALLENGE_KEY`, `IP_HASH_KEY`, `PLAY_ACCOUNT_KEY`,
 *   `DEVICE_KEY_SECRET`, `TRANSFER_TOKEN_KEY`): base64url of 32 random bytes;
 * - `APPLE_ACCOUNT_NS`: a random UUID v4 (never rotated: it derives every
 *   `appAccountToken`, RC9);
 * - `DEBUG_ATTESTATION_TOKEN`: dev/staging only (BE20, RC86), never for prod.
 *
 * Store-issued secrets (`APPLE_*`, `GOOGLE_*`), `ANTHROPIC_API_KEY` and
 * `ALERT_WEBHOOK_URL` come from their consoles, not from here.
 */
export const GENERATED_SECRETS = [
  'TOKEN_SIGNING_KEYS',
  'CHALLENGE_KEY',
  'IDEMPOTENCY_ENC_KEY',
  'IP_HASH_KEY',
  'PLAY_ACCOUNT_KEY',
  'APPLE_ACCOUNT_NS',
  'DEVICE_KEY_SECRET',
  'TRANSFER_TOKEN_KEY',
  'DEBUG_ATTESTATION_TOKEN',
] as const;

export type GeneratedSecret = (typeof GENERATED_SECRETS)[number];

/** Secrets that must never be generated for (or set on) prod (RC86). */
export const NON_PROD_ONLY: readonly GeneratedSecret[] = ['DEBUG_ATTESTATION_TOKEN'];

/** Secrets whose value is a keyring and can be rotated by prepending a new key (03 §11). */
export const ROTATABLE: readonly GeneratedSecret[] = ['TOKEN_SIGNING_KEYS', 'IDEMPOTENCY_ENC_KEY'];

const KEY_BYTES = 32;

export function isGeneratedSecret(name: string): name is GeneratedSecret {
  return (GENERATED_SECRETS as readonly string[]).includes(name);
}

/** Key ID from the generation date: `k20260929`. */
export function kidFor(now: Date): string {
  return `k${now.toISOString().slice(0, 10).replaceAll('-', '')}`;
}

/** Random UUID v4 (RFC 9562 §5.4) from the Crypto port. */
export function uuidV4(crypto: Crypto): string {
  const b = crypto.randomBytes(16);
  b[6] = ((b[6] ?? 0) & 0x0f) | 0x40;
  b[8] = ((b[8] ?? 0) & 0x3f) | 0x80;
  const hex = toHex(b);
  return `${hex.slice(0, 8)}-${hex.slice(8, 12)}-${hex.slice(12, 16)}-${hex.slice(16, 20)}-${hex.slice(20)}`;
}

export interface Ed25519Jwk {
  readonly kty: 'OKP';
  readonly crv: 'Ed25519';
  readonly kid: string;
  readonly x: string;
  readonly d: string;
}

/** The private JWK fields `TOKEN_SIGNING_KEYS` needs from an exported key. */
export function toEd25519Jwk(kid: string, jwk: { x?: unknown; d?: unknown }): Ed25519Jwk {
  if (typeof jwk.x !== 'string' || typeof jwk.d !== 'string') {
    throw new Error('Ed25519 export did not return x and d');
  }
  return { kty: 'OKP', crv: 'Ed25519', kid, x: jwk.x, d: jwk.d };
}

/** A fresh extractable Ed25519 key pair as a private JWK. */
export async function generateEd25519Jwk(kid: string): Promise<Ed25519Jwk> {
  const { privateKey } = await generateKeyPair('EdDSA', { crv: 'Ed25519', extractable: true });
  return toEd25519Jwk(kid, await exportJWK(privateKey));
}

export interface GenerateOptions {
  readonly environment: Environment;
  readonly kid: string;
  /** Subset to generate; defaults to every secret allowed in `environment`. */
  readonly only?: readonly GeneratedSecret[];
  /**
   * Current values of the keyring secrets, for rotation: the new key is
   * prepended and the previous **current** key is kept as the second entry
   * (older ones are dropped, 03 §11).
   */
  readonly previous?: Partial<Record<GeneratedSecret, string>>;
  readonly crypto: Crypto;
  /** Injected for tests; defaults to `generateEd25519Jwk`. */
  readonly ed25519?: (kid: string) => Promise<Ed25519Jwk>;
}

export class GenKeysError extends Error {
  override readonly name = 'GenKeysError';
}

function previousJwk(raw: string | undefined): unknown[] {
  if (raw === undefined) {
    return [];
  }
  let parsed: unknown;
  try {
    parsed = JSON.parse(raw);
  } catch {
    throw new GenKeysError('previous TOKEN_SIGNING_KEYS is not JSON');
  }
  const keys = (parsed as { keys?: unknown }).keys;
  if (!Array.isArray(keys) || keys.length === 0) {
    throw new GenKeysError('previous TOKEN_SIGNING_KEYS has no keys');
  }
  return [keys[0]];
}

function previousRing(raw: string | undefined): string[] {
  const current = raw?.split(',')[0]?.trim();
  return current === undefined || current === '' ? [] : [current];
}

function kidOf(entry: unknown): unknown {
  return typeof entry === 'object' && entry !== null ? (entry as { kid?: unknown }).kid : entry;
}

/** Generates the requested secrets; the result maps secret name → value. */
export async function generateSecrets(
  options: GenerateOptions,
): Promise<Partial<Record<GeneratedSecret, string>>> {
  const { crypto, environment, kid } = options;
  const wanted = options.only ?? GENERATED_SECRETS;
  if (environment === 'prod') {
    const forbidden = wanted.filter((name) => NON_PROD_ONLY.includes(name));
    if (options.only !== undefined && forbidden.length > 0) {
      throw new GenKeysError(`${forbidden.join(', ')} must never be set in prod (RC86)`);
    }
  }
  const random = (): string => toBase64Url(crypto.randomBytes(KEY_BYTES));
  const out: Partial<Record<GeneratedSecret, string>> = {};
  for (const name of wanted) {
    if (environment === 'prod' && NON_PROD_ONLY.includes(name)) {
      continue;
    }
    switch (name) {
      case 'TOKEN_SIGNING_KEYS': {
        const fresh = await (options.ed25519 ?? generateEd25519Jwk)(kid);
        const kept = previousJwk(options.previous?.TOKEN_SIGNING_KEYS);
        if (kept.some((key) => kidOf(key) === kid)) {
          throw new GenKeysError(`kid ${kid} is already the current TOKEN_SIGNING_KEYS kid`);
        }
        out[name] = JSON.stringify({ keys: [fresh, ...kept] });
        break;
      }
      case 'IDEMPOTENCY_ENC_KEY': {
        const kept = previousRing(options.previous?.IDEMPOTENCY_ENC_KEY);
        if (kept.some((entry) => entry.startsWith(`${kid}:`))) {
          throw new GenKeysError(`kid ${kid} is already the current IDEMPOTENCY_ENC_KEY kid`);
        }
        out[name] = [`${kid}:${random()}`, ...kept].join(',');
        break;
      }
      case 'APPLE_ACCOUNT_NS':
        out[name] = uuidV4(crypto);
        break;
      default:
        out[name] = random();
    }
  }
  return out;
}
