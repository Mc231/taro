import { ecdsaRawToDer } from '../../src/crypto/der';
import { toBase64Url, utf8 } from '../../src/crypto/encoding';

/**
 * AdMob SSV callbacks signed with a P-256 key generated in the test (06 §7):
 * the query up to `&signature=` is signed (ECDSA-SHA256, DER, URL-safe
 * base64), then `signature` and `key_id` are appended, as AdMob does.
 */
export interface SsvSigner {
  readonly keyId: number;
  readonly spki: Uint8Array;
  sign(content: string): Promise<string>;
}

export async function newSsvSigner(keyId: number): Promise<SsvSigner> {
  const pair = (await crypto.subtle.generateKey({ name: 'ECDSA', namedCurve: 'P-256' }, true, [
    'sign',
    'verify',
  ])) as CryptoKeyPair;
  const spki = new Uint8Array(
    (await crypto.subtle.exportKey('spki', pair.publicKey)) as ArrayBuffer,
  );
  return {
    keyId,
    spki,
    async sign(content) {
      const raw = new Uint8Array(
        await crypto.subtle.sign(
          { name: 'ECDSA', hash: 'SHA-256' },
          pair.privateKey,
          new Uint8Array(utf8(content)),
        ),
      );
      return toBase64Url(ecdsaRawToDer(raw));
    },
  };
}

export interface SsvParams {
  readonly ad_network?: string | undefined;
  readonly ad_unit?: string | undefined;
  readonly custom_data?: string | undefined;
  readonly reward_amount?: string | undefined;
  readonly reward_item?: string | undefined;
  readonly timestamp?: string | undefined;
  readonly transaction_id?: string | undefined;
  readonly user_id?: string | undefined;
}

/** AdMob's parameter order; absent values are left out. */
const ORDER = [
  'ad_network',
  'ad_unit',
  'custom_data',
  'reward_amount',
  'reward_item',
  'timestamp',
  'transaction_id',
  'user_id',
] as const;

export function ssvContent(params: SsvParams): string {
  return ORDER.filter((key) => params[key] !== undefined)
    .map((key) => `${key}=${encodeURIComponent(params[key] ?? '')}`)
    .join('&');
}

/** `/v1/ads/admob/ssv?{content}&signature=…&key_id=…` signed by `signer`. */
export async function signedSsvPath(signer: SsvSigner, params: SsvParams): Promise<string> {
  const content = ssvContent(params);
  const signature = await signer.sign(content);
  return `/v1/ads/admob/ssv?${content}&signature=${signature}&key_id=${String(signer.keyId)}`;
}
