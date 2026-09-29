import { fromBase64, fromUtf8, toBase64Url, utf8 } from '../crypto/encoding';
import type { Crypto } from '../ports/Crypto';

/**
 * Support `transferToken` (03 §6.6, RC84, RC85): proof that the caller's new
 * install re-submitted a transaction another install owns, from the same
 * store account. Returned in `409 PURCHASE_ALREADY_CLAIMED` as
 * `details.transferToken`, shown in the app as a "transfer code", and checked
 * by the owner-run `credits-transfer` script (Sprint 7.5).
 *
 * Format: `tt1.<base64url(JSON {p: purchaseId, n: newInstallId, e: exp})>.<base64url(HMAC)>`
 * with `HMAC-SHA256(TRANSFER_TOKEN_KEY, "tt1." ‖ payload)`. 7-day TTL;
 * single use is enforced by the script (idempotent per ticket).
 */
export const TRANSFER_TOKEN_PREFIX = 'tt1';
export const TRANSFER_TOKEN_TTL_SEC = 7 * 24 * 3600;

export interface TransferTokenClaims {
  readonly purchaseId: string;
  readonly newInstallId: string;
  /** Expiry, epoch seconds. */
  readonly expiresAt: number;
}

async function mac(crypto: Crypto, key: Uint8Array, payload: string): Promise<string> {
  return toBase64Url(await crypto.hmacSha256(key, `${TRANSFER_TOKEN_PREFIX}.${payload}`));
}

export async function createTransferToken(
  crypto: Crypto,
  key: Uint8Array,
  claims: TransferTokenClaims,
): Promise<string> {
  const payload = toBase64Url(
    utf8(JSON.stringify({ p: claims.purchaseId, n: claims.newInstallId, e: claims.expiresAt })),
  );
  return `${TRANSFER_TOKEN_PREFIX}.${payload}.${await mac(crypto, key, payload)}`;
}

/** The claims of a token with a valid MAC that has not expired at `now`, else null. */
export async function verifyTransferToken(
  crypto: Crypto,
  key: Uint8Array,
  token: string,
  now: Date,
): Promise<TransferTokenClaims | null> {
  const [prefix, payload, signature, ...rest] = token.split('.');
  if (
    prefix !== TRANSFER_TOKEN_PREFIX ||
    payload === undefined ||
    signature === undefined ||
    rest.length > 0
  ) {
    return null;
  }
  const expected = utf8(await mac(crypto, key, payload));
  if (!crypto.timingSafeEqual(expected, utf8(signature))) {
    return null;
  }
  try {
    const raw = JSON.parse(fromUtf8(fromBase64(payload))) as {
      p?: unknown;
      n?: unknown;
      e?: unknown;
    };
    if (typeof raw.p !== 'string' || typeof raw.n !== 'string' || typeof raw.e !== 'number') {
      return null;
    }
    return raw.e * 1000 > now.getTime()
      ? { purchaseId: raw.p, newInstallId: raw.n, expiresAt: raw.e }
      : null;
  } catch {
    return null;
  }
}
