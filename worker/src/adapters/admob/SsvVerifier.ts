import { ecdsaDerToRaw } from '../../crypto/der';
import { fromBase64, utf8 } from '../../crypto/encoding';
import type { AdmobKeyProvider } from '../../ports/StoreApis';

/**
 * AdMob SSV callback signature (03 §7.2 step 1): ECDSA P-256 / SHA-256 over
 * the raw query string up to (excluding) `&signature=`. `signature`
 * (URL-safe base64 of a DER signature) and `key_id` are always the last two
 * parameters. The raw query is verified byte for byte, never re-encoded.
 */
export type SsvVerification =
  | { readonly ok: true; readonly params: Readonly<Record<string, string>> }
  | { readonly ok: false; readonly reason: 'malformed' | 'unknown_key' | 'signature' };

const SIGNATURE_MARKER = '&signature=';
const KEY_ID = /^\d{1,16}$/;
const ECDSA_P256 = { name: 'ECDSA', namedCurve: 'P-256' } as const;

/** The query string of `url` exactly as sent (no decoding). */
export function rawQuery(url: string): string {
  const start = url.indexOf('?');
  if (start < 0) {
    return '';
  }
  const hash = url.indexOf('#', start);
  return url.slice(start + 1, hash < 0 ? undefined : hash);
}

export class AdmobSsvVerifier {
  constructor(private readonly keys: AdmobKeyProvider) {}

  /** Rejects only when the key provider cannot fetch the keys (an outage). */
  async verify(query: string): Promise<SsvVerification> {
    const marker = query.indexOf(SIGNATURE_MARKER);
    if (marker < 0) {
      return { ok: false, reason: 'malformed' };
    }
    const signed = query.slice(0, marker);
    const tail = new URLSearchParams(query.slice(marker + 1));
    const keyId = tail.get('key_id') ?? '';
    const signature = decode(tail.get('signature') ?? '');
    if (!KEY_ID.test(keyId) || signature === null) {
      return { ok: false, reason: 'malformed' };
    }
    const spki = await this.keys.getKey(Number(keyId));
    if (spki === null) {
      return { ok: false, reason: 'unknown_key' };
    }
    if (!(await verifyEcdsa(spki, signature, utf8(signed)))) {
      return { ok: false, reason: 'signature' };
    }
    return { ok: true, params: Object.fromEntries(new URLSearchParams(signed)) };
  }
}

function decode(value: string): Uint8Array | null {
  if (value === '') {
    return null;
  }
  try {
    return fromBase64(value);
  } catch {
    return null;
  }
}

async function verifyEcdsa(
  spki: Uint8Array,
  derSignature: Uint8Array,
  data: Uint8Array,
): Promise<boolean> {
  try {
    const key = await crypto.subtle.importKey('spki', new Uint8Array(spki), ECDSA_P256, false, [
      'verify',
    ]);
    return await crypto.subtle.verify(
      { name: 'ECDSA', hash: 'SHA-256' },
      key,
      new Uint8Array(ecdsaDerToRaw(derSignature)),
      new Uint8Array(data),
    );
  } catch {
    return false;
  }
}
