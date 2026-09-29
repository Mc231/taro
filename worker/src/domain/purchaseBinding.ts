import { concatBytes, fromHex, toBase64Url, toHex, utf8 } from '../crypto/encoding';
import type { Crypto } from '../ports/Crypto';

/**
 * Purchase-to-install binding returned at registration (03 §3.3, §6.1; RC9):
 * - iOS `appleAccountToken = UUIDv5(APPLE_ACCOUNT_NS, installId)`, sent by the
 *   client as StoreKit `appAccountToken`;
 * - Android `playAccountId = base64url(HMAC(PLAY_ACCOUNT_KEY, installId))[0..43]`,
 *   sent as Play `obfuscatedAccountId` (stored as `installs.play_account_hash`).
 */
const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
export const PLAY_ACCOUNT_ID_LENGTH = 43;

export function isUuid(text: string): boolean {
  return UUID.test(text);
}

/** Name-based UUID v5 (RFC 9562 §5.5) of `name` (UTF-8) in `namespace`. */
export async function uuidV5(crypto: Crypto, namespace: string, name: string): Promise<string> {
  if (!isUuid(namespace)) {
    throw new Error('UUIDv5 namespace must be a UUID');
  }
  const digest = await crypto.sha1(concatBytes(fromHex(namespace.replace(/-/g, '')), utf8(name)));
  const bytes = digest.slice(0, 16);
  bytes[6] = ((bytes[6] ?? 0) & 0x0f) | 0x50;
  bytes[8] = ((bytes[8] ?? 0) & 0x3f) | 0x80;
  const hex = toHex(bytes);
  return `${hex.slice(0, 8)}-${hex.slice(8, 12)}-${hex.slice(12, 16)}-${hex.slice(16, 20)}-${hex.slice(20)}`;
}

export function appleAccountToken(
  crypto: Crypto,
  namespace: string,
  installId: string,
): Promise<string> {
  return uuidV5(crypto, namespace, installId);
}

export async function playAccountId(
  crypto: Crypto,
  key: Uint8Array,
  installId: string,
): Promise<string> {
  return toBase64Url(await crypto.hmacSha256(key, installId)).slice(0, PLAY_ACCOUNT_ID_LENGTH);
}
