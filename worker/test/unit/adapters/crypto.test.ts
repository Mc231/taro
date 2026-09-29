import { describe, expect, it } from 'vitest';
import { CryptoIdGenerator } from '../../../src/adapters/cf/CryptoIdGenerator';
import { WebCrypto } from '../../../src/adapters/cf/WebCrypto';
import {
  blobToBytes,
  concatBytes,
  fromBase64,
  fromUtf8,
  toBase64,
  toBase64Url,
  toHex,
  utf8,
} from '../../../src/crypto/encoding';
import { lazy, parseHmacKey, parseKeyring, SecretConfigError } from '../../../src/crypto/keyring';
import type { Crypto } from '../../../src/ports/Crypto';
import { FixedClock } from '../../fakes/FixedClock';

const crypto = new WebCrypto();
const KEY32 = toBase64Url(new Uint8Array(32).fill(7));

describe('encoding', () => {
  it('round-trips utf8, base64 and base64url', () => {
    const bytes = utf8('Привіт ✨');
    expect(fromUtf8(bytes)).toBe('Привіт ✨');
    expect(fromBase64(toBase64(bytes))).toEqual(bytes);
    expect(fromBase64(toBase64Url(bytes))).toEqual(bytes);
    expect(toBase64Url(new Uint8Array([251, 255]))).toBe('-_8');
    expect(toHex(new Uint8Array([0, 15, 255]))).toBe('000fff');
    expect(concatBytes(new Uint8Array([1]), new Uint8Array([2, 3]))).toEqual(
      new Uint8Array([1, 2, 3]),
    );
  });

  it('normalises D1 BLOB values', () => {
    const bytes = new Uint8Array([1, 2, 3]);
    expect(blobToBytes(bytes)).toBe(bytes);
    expect(blobToBytes(bytes.buffer)).toEqual(bytes);
    expect(blobToBytes(new DataView(bytes.buffer))).toEqual(bytes);
    expect(blobToBytes([1, 2, 3])).toEqual(bytes);
    expect(blobToBytes(null)).toBeNull();
    expect(blobToBytes(['x'])).toBeNull();
  });
});

describe('WebCrypto', () => {
  it('hashes and MACs with known vectors', async () => {
    expect(toHex(await crypto.sha256('abc'))).toBe(
      'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad',
    );
    // RFC 4231 test case 2.
    expect(toHex(await crypto.hmacSha256('Jefe', 'what do ya want for nothing?'))).toBe(
      '5bdcc146bf60754e6a042426089575c75a003f089d2739839dec58b964ec3843',
    );
    expect(await crypto.sha256(utf8('abc'))).toEqual(await crypto.sha256('abc'));
  });

  it('seals and opens AES-256-GCM with the right key and AAD only', async () => {
    const key = fromBase64(KEY32);
    const aad = utf8('inst‖POST /v1/x‖key');
    const sealed = await crypto.aesGcmEncrypt(key, utf8('secret body'), aad);

    expect(sealed.iv).toHaveLength(12);
    expect(fromUtf8(sealed.ciphertext)).not.toContain('secret body');
    expect(fromUtf8(await crypto.aesGcmDecrypt(key, sealed, aad))).toBe('secret body');
    await expect(crypto.aesGcmDecrypt(key, sealed, utf8('other'))).rejects.toThrow();
    await expect(crypto.aesGcmDecrypt(new Uint8Array(32).fill(8), sealed, aad)).rejects.toThrow();
  });

  it('compares in constant time', () => {
    expect(crypto.timingSafeEqual(utf8('abc'), utf8('abc'))).toBe(true);
    expect(crypto.timingSafeEqual(utf8('abc'), utf8('abd'))).toBe(false);
    expect(crypto.timingSafeEqual(utf8('abc'), utf8('ab'))).toBe(false);
  });

  it('returns fresh random bytes', () => {
    expect(crypto.randomBytes(16)).toHaveLength(16);
    expect(crypto.randomBytes(16)).not.toEqual(crypto.randomBytes(16));
  });
});

describe('CryptoIdGenerator', () => {
  class AllOnes extends WebCrypto {
    override randomBytes(length: number): Uint8Array {
      return new Uint8Array(length).fill(0xff);
    }
  }
  const fixedRandom: Crypto = new AllOnes();

  it('formats UUID v4', () => {
    const ids = new CryptoIdGenerator(crypto, new FixedClock());
    expect(ids.uuid()).toMatch(
      /^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/,
    );
    expect(new CryptoIdGenerator(fixedRandom, new FixedClock()).uuid()).toBe(
      'ffffffff-ffff-4fff-bfff-ffffffffffff',
    );
  });

  it('formats time-ordered UUID v7 from the clock', () => {
    const clock = new FixedClock('2026-09-26T10:00:00.000Z');
    const ids = new CryptoIdGenerator(fixedRandom, clock);
    const first = ids.uuidV7();
    clock.advance({ ms: 1 });
    const second = ids.uuidV7();

    expect(first).toMatch(/^[0-9a-f]{8}-[0-9a-f]{4}-7[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/);
    expect(first.replace(/-/g, '').slice(0, 12)).toBe(
      new Date('2026-09-26T10:00:00.000Z').getTime().toString(16).padStart(12, '0'),
    );
    expect(second > first).toBe(true);
  });

  it('makes opaque base64url IDs', () => {
    const ids = new CryptoIdGenerator(crypto, new FixedClock());
    expect(ids.opaque()).toMatch(/^[A-Za-z0-9_-]{22}$/);
    expect(ids.opaque(32)).toMatch(/^[A-Za-z0-9_-]{43}$/);
  });
});

describe('keyring secrets', () => {
  it('parses kid:key entries, current first, and looks keys up by kid', () => {
    const other = toBase64Url(new Uint8Array(32).fill(9));
    const ring = parseKeyring(` k2:${KEY32} , k1:${other}`, 'IDEMPOTENCY_ENC_KEY');
    expect(ring.current.kid).toBe('k2');
    expect(ring.get('k1')?.key).toEqual(new Uint8Array(32).fill(9));
    expect(ring.get('k9')).toBeUndefined();
  });

  it('accepts a bare key as kid k0', () => {
    expect(parseKeyring(KEY32, 'X').current.kid).toBe('k0');
  });

  it.each([
    [undefined, 'is not set'],
    ['  ', 'is not set'],
    [`bad kid!:${KEY32}`, 'invalid or duplicate kid'],
    [`k1:${KEY32},k1:${KEY32}`, 'invalid or duplicate kid'],
    ['k1:@@@', 'is not base64'],
    ['k1:AAAA', 'must be 32 bytes'],
    [`k1:${KEY32},`, 'must be 32 bytes'],
  ])('rejects %j', (raw, message) => {
    expect(() => parseKeyring(raw, 'IDEMPOTENCY_ENC_KEY')).toThrow(SecretConfigError);
    expect(() => parseKeyring(raw, 'IDEMPOTENCY_ENC_KEY')).toThrow(message);
  });

  it('parses HMAC keys of at least 16 characters', () => {
    expect(parseHmacKey('0123456789abcdef', 'IP_HASH_KEY')).toHaveLength(16);
    expect(() => parseHmacKey('short', 'IP_HASH_KEY')).toThrow('IP_HASH_KEY');
    expect(() => parseHmacKey(undefined, 'IP_HASH_KEY')).toThrow('IP_HASH_KEY');
  });

  it('memoises lazily', () => {
    let calls = 0;
    const get = lazy(() => ++calls);
    expect(calls).toBe(0);
    expect(get()).toBe(1);
    expect(get()).toBe(1);
  });
});
