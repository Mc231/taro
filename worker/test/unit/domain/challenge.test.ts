import { describe, expect, it } from 'vitest';
import { WebCrypto } from '../../../src/adapters/cf/WebCrypto';
import { fromBase64, toBase64Url, toHex, utf8 } from '../../../src/crypto/encoding';
import {
  callClientDataHash,
  CHALLENGE_LENGTH,
  CHALLENGE_TTL_SEC,
  issueChallenge,
  leadingZeroBits,
  openChallenge,
  registrationClientDataHash,
  registrationRequestHash,
  verifyProofOfWork,
} from '../../../src/domain/challenge';
import { solvePow } from '../../helpers/identity';

const crypto = new WebCrypto();
const KEY = utf8('test-challenge-key-0123456789abcdef');
const NOW = new Date('2026-09-26T10:00:00.000Z');

describe('challenge codec (03 §3.2)', () => {
  it('issues a 54-char base64url challenge that opens until it expires', async () => {
    const { challenge, expiresAt } = await issueChallenge(crypto, KEY, NOW);
    expect(challenge).toHaveLength(CHALLENGE_LENGTH);
    expect(challenge).toMatch(/^[A-Za-z0-9_-]+$/);
    expect(expiresAt.toISOString()).toBe('2026-09-26T10:05:00.000Z');

    const opened = await openChallenge(crypto, KEY, challenge, NOW);
    expect(opened).toEqual({
      ok: true,
      nonce: toBase64Url(fromBase64(challenge).subarray(0, 16)),
      expiresAt,
    });
    const justBefore = new Date(NOW.getTime() + CHALLENGE_TTL_SEC * 1000 - 1);
    expect((await openChallenge(crypto, KEY, challenge, justBefore)).ok).toBe(true);
    expect(await openChallenge(crypto, KEY, challenge, expiresAt)).toEqual({
      ok: false,
      reason: 'expired',
    });
  });

  it('rejects malformed challenges and forged MACs', async () => {
    const { challenge } = await issueChallenge(crypto, KEY, NOW);
    expect(await openChallenge(crypto, KEY, challenge.slice(1), NOW)).toEqual({
      ok: false,
      reason: 'malformed',
    });
    expect(await openChallenge(crypto, KEY, `${challenge.slice(0, -1)}!`, NOW)).toEqual({
      ok: false,
      reason: 'malformed',
    });
    // Same nonce, later expiry, stale MAC.
    const bytes = fromBase64(challenge);
    bytes[23] = (bytes[23] ?? 0) ^ 1;
    expect(await openChallenge(crypto, KEY, toBase64Url(bytes), NOW)).toEqual({
      ok: false,
      reason: 'bad_mac',
    });
    expect(await openChallenge(crypto, utf8('another-key-0123456789'), challenge, NOW)).toEqual({
      ok: false,
      reason: 'bad_mac',
    });
  });

  it('issues a different nonce every time', async () => {
    const a = await issueChallenge(crypto, KEY, NOW);
    const b = await issueChallenge(crypto, KEY, NOW);
    expect(a.challenge).not.toBe(b.challenge);
  });
});

describe('proof-of-work (03 §2.4, RC65)', () => {
  it('counts leading zero bits', () => {
    expect(leadingZeroBits(Uint8Array.of(0x80))).toBe(0);
    expect(leadingZeroBits(Uint8Array.of(0x01))).toBe(7);
    expect(leadingZeroBits(Uint8Array.of(0x00, 0x0f))).toBe(12);
    expect(leadingZeroBits(Uint8Array.of(0x00, 0x00))).toBe(16);
    expect(leadingZeroBits(new Uint8Array())).toBe(0);
  });

  it('accepts a solved pow and rejects missing, empty, long or unsolved ones', async () => {
    const pow = await solvePow('ch', 'inst', 8);
    const digest = await crypto.sha256(`chinst${pow}`);
    expect(leadingZeroBits(digest)).toBeGreaterThanOrEqual(8);
    const base = { challenge: 'ch', installId: 'inst', bits: 8 };
    expect(await verifyProofOfWork(crypto, { ...base, pow })).toBe(true);
    expect(await verifyProofOfWork(crypto, { ...base, pow: undefined })).toBe(false);
    expect(await verifyProofOfWork(crypto, { ...base, pow: '' })).toBe(false);
    expect(await verifyProofOfWork(crypto, { ...base, pow: 'x'.repeat(65) })).toBe(false);
    expect(await verifyProofOfWork(crypto, { ...base, installId: 'other', pow, bits: 30 })).toBe(
      false,
    );
  });
});

describe('attestation bindings (03 §3.1, §3.4, RC87)', () => {
  it('hashes the registration inputs as UTF-8 concatenations', async () => {
    expect(toHex(await registrationClientDataHash(crypto, 'c', 'i', 'd'))).toBe(
      toHex(await crypto.sha256('cid')),
    );
    expect(toHex(await registrationClientDataHash(crypto, 'c', 'i', undefined))).toBe(
      toHex(await crypto.sha256('ci')),
    );
    expect(await registrationRequestHash(crypto, 'c', 'i', 'k')).toBe(
      toBase64Url(await crypto.sha256('cik')),
    );
  });

  it('binds method, path, body digest and idempotency key per call', async () => {
    const body = utf8('{"a":1}');
    const hash = await callClientDataHash(crypto, {
      method: 'post',
      path: '/v1/readings',
      body,
      idempotencyKey: 'key',
    });
    const expected = await crypto.sha256(
      new Uint8Array([
        ...utf8('POST'),
        ...utf8('/v1/readings'),
        ...(await crypto.sha256(body)),
        ...utf8('key'),
      ]),
    );
    expect(hash).toEqual(expected);
    const noKey = await callClientDataHash(crypto, {
      method: 'POST',
      path: '/v1/readings',
      body,
      idempotencyKey: undefined,
    });
    expect(noKey).not.toEqual(hash);
  });
});
