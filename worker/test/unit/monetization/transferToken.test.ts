import { describe, expect, it } from 'vitest';
import { WebCrypto } from '../../../src/adapters/cf/WebCrypto';
import { toBase64Url, utf8 } from '../../../src/crypto/encoding';
import {
  createTransferToken,
  TRANSFER_TOKEN_TTL_SEC,
  verifyTransferToken,
} from '../../../src/monetization/transferToken';

/** Support `transferToken` (03 §6.6, RC84, RC85). */
const crypto = new WebCrypto();
const KEY = utf8('test-transfer-token-key-0123456789');
const NOW = new Date('2026-09-26T10:00:00Z');
const CLAIMS = {
  purchaseId: '00000000-0000-7000-8000-000000000001',
  newInstallId: '11111111-1111-4111-8111-111111111111',
  expiresAt: NOW.getTime() / 1000 + TRANSFER_TOKEN_TTL_SEC,
};

describe('transferToken', () => {
  it('round-trips the claims until it expires (7 days)', async () => {
    const token = await createTransferToken(crypto, KEY, CLAIMS);
    expect(token).toMatch(/^tt1\.[\w-]+\.[\w-]{43}$/);
    expect(await verifyTransferToken(crypto, KEY, token, NOW)).toEqual(CLAIMS);
    const expiry = new Date(CLAIMS.expiresAt * 1000);
    expect(await verifyTransferToken(crypto, KEY, token, expiry)).toBeNull();
  });

  it('rejects another key, tampering and malformed tokens', async () => {
    const token = await createTransferToken(crypto, KEY, CLAIMS);
    expect(
      await verifyTransferToken(crypto, utf8('another-key-0123456789abcdef'), token, NOW),
    ).toBeNull();
    const [prefix, , signature] = token.split('.');
    const forged = toBase64Url(utf8(JSON.stringify({ ...CLAIMS, p: 'other' })));
    expect(
      await verifyTransferToken(
        crypto,
        KEY,
        `${String(prefix)}.${forged}.${String(signature)}`,
        NOW,
      ),
    ).toBeNull();
    for (const bad of ['', 'tt1', 'tt2.a.b', `${token}.x`, 'tt1.a']) {
      expect(await verifyTransferToken(crypto, KEY, bad, NOW), bad).toBeNull();
    }
  });

  it('rejects a validly signed payload with the wrong shape', async () => {
    const sign = async (payload: string) =>
      `tt1.${payload}.${toBase64Url(await crypto.hmacSha256(KEY, `tt1.${payload}`))}`;
    for (const payload of [
      toBase64Url(utf8('not json')),
      toBase64Url(utf8(JSON.stringify({ p: 1, n: 'x', e: 1 }))),
      toBase64Url(utf8(JSON.stringify({ p: 'x', n: 2, e: 1 }))),
      toBase64Url(utf8(JSON.stringify({ p: 'x', n: 'y', e: 'soon' }))),
    ]) {
      expect(await verifyTransferToken(crypto, KEY, await sign(payload), NOW)).toBeNull();
    }
  });
});
