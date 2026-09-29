import { describe, expect, it } from 'vitest';
import {
  ADMOB_KEYS_CACHE_KEY,
  ADMOB_KEYS_CACHE_TTL_SEC,
  ADMOB_KEYS_URL,
  GstaticAdmobKeyProvider,
  parseVerifierKeys,
  REFETCH_MIN_INTERVAL_SEC,
} from '../../../../src/adapters/admob/AdmobKeyProvider';
import { AdmobSsvVerifier, rawQuery } from '../../../../src/adapters/admob/SsvVerifier';
import { toBase64 } from '../../../../src/crypto/encoding';
import { FakeAdmobKeyProvider } from '../../../fakes/FakeAdmobKeyProvider';
import { FixedClock } from '../../../fakes/FixedClock';
import { bindings } from '../../../fakes/testDeps';
import { newSsvSigner, ssvContent } from '../../../helpers/admobSsv';
import { json, StubFetch } from '../../../helpers/stubFetch';

/** Each test uses its own KV namespace key space by clearing the one cache key. */
async function freshCache(): Promise<KVNamespace> {
  await bindings.CACHE_KV.delete(ADMOB_KEYS_CACHE_KEY);
  return bindings.CACHE_KV;
}

function keysDocument(entries: Record<number, Uint8Array>) {
  return {
    keys: Object.entries(entries).map(([keyId, spki]) => ({
      keyId: Number(keyId),
      pem: `-----BEGIN PUBLIC KEY-----\n${toBase64(spki)}\n-----END PUBLIC KEY-----`,
      base64: toBase64(spki),
    })),
  };
}

describe('parseVerifierKeys', () => {
  it('reads base64 SPKI, falls back to the PEM body, and skips unusable entries', () => {
    expect(
      parseVerifierKeys({
        keys: [
          { keyId: 1, base64: 'QUJD' },
          { keyId: '2', pem: '-----BEGIN PUBLIC KEY-----\nREVG\n-----END PUBLIC KEY-----' },
          { keyId: 3 },
          { base64: 'R0hJ' },
          null,
        ],
      }),
    ).toEqual({ '1': 'QUJD', '2': 'REVG' });
  });

  it('rejects documents without keys', () => {
    expect(() => parseVerifierKeys({})).toThrow('no keys array');
    expect(() => parseVerifierKeys(null)).toThrow('no keys array');
    expect(() => parseVerifierKeys({ keys: [{ keyId: 1 }] })).toThrow('empty key set');
  });
});

describe('GstaticAdmobKeyProvider (03 §7.2)', () => {
  it('fetches gstatic once, caches the keys in CACHE_KV for 24 h and serves them from the cache', async () => {
    const signer = await newSsvSigner(3335741209);
    const stub = new StubFetch().reply(json(keysDocument({ 3335741209: signer.spki })));
    const clock = new FixedClock();
    const provider = new GstaticAdmobKeyProvider({
      fetch: stub.fetch,
      clock,
      cache: await freshCache(),
    });

    expect(await provider.getKey(3335741209)).toEqual(signer.spki);
    expect(await provider.getKey(3335741209)).toEqual(signer.spki);
    expect(stub.requests).toHaveLength(1);
    expect(stub.requests[0]?.url).toBe(ADMOB_KEYS_URL);

    // After 24 h the cached document is stale and is fetched again.
    clock.advance({ seconds: ADMOB_KEYS_CACHE_TTL_SEC });
    expect(await provider.getKey(3335741209)).toEqual(signer.spki);
    expect(stub.requests).toHaveLength(2);
  });

  it('refetches on an unknown key_id (rotation), at most once per minute', async () => {
    const old = await newSsvSigner(1);
    const rotated = await newSsvSigner(2);
    const stub = new StubFetch().reply(
      json(keysDocument({ 1: old.spki })),
      json(keysDocument({ 1: old.spki, 2: rotated.spki })),
    );
    const clock = new FixedClock();
    const provider = new GstaticAdmobKeyProvider({
      fetch: stub.fetch,
      clock,
      cache: await freshCache(),
      url: 'https://keys.test/verifier-keys.json',
    });

    expect(await provider.getKey(1)).toEqual(old.spki);
    // Unknown right after a fetch: no hammering of gstatic.
    expect(await provider.getKey(2)).toBeNull();
    expect(stub.requests).toHaveLength(1);

    clock.advance({ seconds: REFETCH_MIN_INTERVAL_SEC });
    expect(await provider.getKey(2)).toEqual(rotated.spki);
    expect(stub.requests).toHaveLength(2);
    expect(stub.requests[1]?.url).toBe('https://keys.test/verifier-keys.json');

    // Still unknown after a refetch → null.
    clock.advance({ seconds: REFETCH_MIN_INTERVAL_SEC });
    expect(await provider.getKey(99)).toBeNull();
  });

  it('rejects when gstatic fails, so the callback is retried later', async () => {
    const stub = new StubFetch().reply(new Response('down', { status: 503 }));
    const provider = new GstaticAdmobKeyProvider({
      fetch: stub.fetch,
      clock: new FixedClock(),
      cache: await freshCache(),
    });
    await expect(provider.getKey(1)).rejects.toThrow('HTTP 503');
  });
});

describe('AdmobSsvVerifier (ECDSA-SHA256 over the query prefix)', () => {
  const params = {
    ad_network: '5450213213286189855',
    ad_unit: '1712485313',
    custom_data: 'intent-abc',
    reward_amount: '1',
    reward_item: 'Reward',
    timestamp: '1759000000000',
    transaction_id: 'txn-1',
    user_id: 'intent-abc',
  };

  async function setup() {
    const signer = await newSsvSigner(42);
    const keys = new FakeAdmobKeyProvider().set(42, signer.spki);
    const content = ssvContent(params);
    const signature = await signer.sign(content);
    return { signer, keys, verifier: new AdmobSsvVerifier(keys), content, signature };
  }

  it('accepts a valid signature and returns the decoded parameters', async () => {
    const { verifier, content, signature } = await setup();
    const result = await verifier.verify(`${content}&signature=${signature}&key_id=42`);
    expect(result).toEqual({ ok: true, params });
  });

  it('rejects a tampered query', async () => {
    const { verifier, content, signature } = await setup();
    const tampered = content.replace('reward_amount=1', 'reward_amount=9');
    expect(await verifier.verify(`${tampered}&signature=${signature}&key_id=42`)).toEqual({
      ok: false,
      reason: 'signature',
    });
  });

  it('rejects an unknown key_id and a signature by another key', async () => {
    const { verifier, content, signature } = await setup();
    expect(await verifier.verify(`${content}&signature=${signature}&key_id=7`)).toEqual({
      ok: false,
      reason: 'unknown_key',
    });
    const other = await newSsvSigner(42);
    const forged = await other.sign(content);
    expect(await verifier.verify(`${content}&signature=${forged}&key_id=42`)).toEqual({
      ok: false,
      reason: 'signature',
    });
  });

  it('rejects malformed queries', async () => {
    const { verifier, content, signature } = await setup();
    for (const query of [
      '',
      content,
      `${content}&signature=${signature}`,
      `${content}&signature=${signature}&key_id=abc`,
      `${content}&signature=&key_id=42`,
      `${content}&signature=%%%&key_id=42`,
    ]) {
      expect(await verifier.verify(query), query.slice(-30)).toEqual({
        ok: false,
        reason: 'malformed',
      });
    }
    // Decodable but not a DER signature.
    expect(await verifier.verify(`${content}&signature=AAAA&key_id=42`)).toEqual({
      ok: false,
      reason: 'signature',
    });
  });

  it('extracts the raw query without decoding it', () => {
    expect(rawQuery('https://api.test/v1/ads/admob/ssv?a=1%2B2&b=c#frag')).toBe('a=1%2B2&b=c');
    expect(rawQuery('https://api.test/v1/ads/admob/ssv?a=1')).toBe('a=1');
    expect(rawQuery('https://api.test/v1/ads/admob/ssv')).toBe('');
  });
});
