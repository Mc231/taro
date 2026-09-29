import { utf8 } from '../../crypto/encoding';
import type { AesGcmSealed, BytesLike, Crypto } from '../../ports/Crypto';

const IV_BYTES = 12;

function bytes(data: BytesLike): Uint8Array<ArrayBuffer> {
  return (typeof data === 'string' ? utf8(data) : new Uint8Array(data)) as Uint8Array<ArrayBuffer>;
}

/** `Crypto` over the Workers WebCrypto API. */
export class WebCrypto implements Crypto {
  randomBytes(length: number): Uint8Array {
    return crypto.getRandomValues(new Uint8Array(length));
  }

  async sha256(data: BytesLike): Promise<Uint8Array> {
    return new Uint8Array(await crypto.subtle.digest('SHA-256', bytes(data)));
  }

  async sha1(data: BytesLike): Promise<Uint8Array> {
    return new Uint8Array(await crypto.subtle.digest('SHA-1', bytes(data)));
  }

  async hmacSha256(key: BytesLike, data: BytesLike): Promise<Uint8Array> {
    const cryptoKey = await crypto.subtle.importKey(
      'raw',
      bytes(key),
      { name: 'HMAC', hash: 'SHA-256' },
      false,
      ['sign'],
    );
    return new Uint8Array(await crypto.subtle.sign('HMAC', cryptoKey, bytes(data)));
  }

  async aesGcmEncrypt(
    key: Uint8Array,
    plaintext: Uint8Array,
    aad: Uint8Array,
  ): Promise<AesGcmSealed> {
    const iv = this.randomBytes(IV_BYTES);
    const cryptoKey = await importAesKey(key, 'encrypt');
    const ciphertext = await crypto.subtle.encrypt(
      { name: 'AES-GCM', iv: bytes(iv), additionalData: bytes(aad) },
      cryptoKey,
      bytes(plaintext),
    );
    return { iv, ciphertext: new Uint8Array(ciphertext) };
  }

  async aesGcmDecrypt(key: Uint8Array, sealed: AesGcmSealed, aad: Uint8Array): Promise<Uint8Array> {
    const cryptoKey = await importAesKey(key, 'decrypt');
    const plaintext = await crypto.subtle.decrypt(
      { name: 'AES-GCM', iv: bytes(sealed.iv), additionalData: bytes(aad) },
      cryptoKey,
      bytes(sealed.ciphertext),
    );
    return new Uint8Array(plaintext);
  }

  timingSafeEqual(a: Uint8Array, b: Uint8Array): boolean {
    if (a.length !== b.length) {
      return false;
    }
    let diff = 0;
    for (let i = 0; i < a.length; i++) {
      diff |= (a[i] ?? 0) ^ (b[i] ?? 0);
    }
    return diff === 0;
  }
}

function importAesKey(key: Uint8Array, usage: 'encrypt' | 'decrypt'): Promise<CryptoKey> {
  return crypto.subtle.importKey('raw', bytes(key), { name: 'AES-GCM' }, false, [usage]);
}
