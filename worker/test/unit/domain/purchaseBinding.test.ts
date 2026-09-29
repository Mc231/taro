import { describe, expect, it } from 'vitest';
import { WebCrypto } from '../../../src/adapters/cf/WebCrypto';
import { fromHex, toBase64Url, toHex, utf8 } from '../../../src/crypto/encoding';
import { resolveAllowedAppIds } from '../../../src/domain/appIds';
import {
  appleAccountToken,
  isUuid,
  PLAY_ACCOUNT_ID_LENGTH,
  playAccountId,
  uuidV5,
} from '../../../src/domain/purchaseBinding';

const crypto = new WebCrypto();
const DNS_NAMESPACE = '6ba7b810-9dad-11d1-80b4-00c04fd430c8';

describe('purchase binding (03 §3.3, RC9)', () => {
  it('computes RFC 9562 UUIDv5 (known vector)', async () => {
    expect(await uuidV5(crypto, DNS_NAMESPACE, 'www.example.com')).toBe(
      '2ed6657d-e927-568b-95e1-2665a8aea6a2',
    );
    expect(await uuidV5(crypto, DNS_NAMESPACE.toUpperCase(), 'www.example.com')).toBe(
      '2ed6657d-e927-568b-95e1-2665a8aea6a2',
    );
    await expect(uuidV5(crypto, 'not-a-uuid', 'x')).rejects.toThrow(/namespace/);
  });

  it('derives appleAccountToken and a 43-char playAccountId per install', async () => {
    const ns = '6f1c2b1e-9a4d-4c3b-8e2f-0a1b2c3d4e5f';
    const a = await appleAccountToken(crypto, ns, 'install-a');
    expect(isUuid(a)).toBe(true);
    expect(a[14]).toBe('5');
    expect(await appleAccountToken(crypto, ns, 'install-a')).toBe(a);
    expect(await appleAccountToken(crypto, ns, 'install-b')).not.toBe(a);

    const key = utf8('play-account-key-0123456789');
    const id = await playAccountId(crypto, key, 'install-a');
    expect(id).toHaveLength(PLAY_ACCOUNT_ID_LENGTH);
    expect(id).toBe(toBase64Url(await crypto.hmacSha256(key, 'install-a')).slice(0, 43));
  });

  it('decodes hex strictly', () => {
    expect(toHex(fromHex('00ff10'))).toBe('00ff10');
    expect(() => fromHex('abc')).toThrow(/hex/);
    expect(() => fromHex('zz')).toThrow(/hex/);
  });
});

describe('resolveAllowedAppIds (RC78)', () => {
  const ids = ['{TEAM}.com.vshyrochuk.taro', 'com.vshyrochuk.taro'];

  it('replaces {TEAM} with APPLE_TEAM_ID', () => {
    expect(resolveAllowedAppIds(ids, 'ABCDE12345')).toEqual([
      'ABCDE12345.com.vshyrochuk.taro',
      'com.vshyrochuk.taro',
    ]);
  });

  it('drops unresolved iOS entries when no team ID is configured', () => {
    expect(resolveAllowedAppIds(ids, undefined)).toEqual(['com.vshyrochuk.taro']);
  });
});
