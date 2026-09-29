import { beforeAll, describe, expect, it } from 'vitest';
import { certificateSha256 } from '../../../src/adapters/apple/AppAttestVerifier';
import { AppleJwsVerifier } from '../../../src/adapters/apple/AppleJwsVerifier';
import {
  APPLE_ROOT_CA_G3_PEM,
  APPLE_ROOT_CA_G3_SHA256,
} from '../../../src/adapters/apple/appleRootG3';
import { X509Certificate } from '../../../src/adapters/apple/x509';
import { toBase64, toBase64Url, utf8 } from '../../../src/crypto/encoding';
import { FixedClock } from '../../fakes/FixedClock';
import {
  appleTransactionPayload,
  createAppleTestChain,
  signAppleJws,
  type AppleTestChain,
} from '../../helpers/apple_jws';

/** App Store JWS verification (03 §6.2 step 2) with a CA generated in the test (06 §7). */
describe('pinned Apple Root CA G3', () => {
  it('is the published certificate (fingerprint) and verifies its own signature', async () => {
    expect(await certificateSha256(APPLE_ROOT_CA_G3_PEM)).toBe(APPLE_ROOT_CA_G3_SHA256);
    const root = new X509Certificate(APPLE_ROOT_CA_G3_PEM);
    expect(root.subject).toContain('CN=Apple Root CA - G3');
    expect(await root.verify({ date: new Date('2026-09-26T10:00:00Z') })).toBe(true);
  });

  it('is the default trust anchor: a test-CA JWS is rejected without an injected root', async () => {
    const chain = await createAppleTestChain();
    const verifier = new AppleJwsVerifier({ clock: new FixedClock() });
    expect(await verifier.verify(await signAppleJws(chain, appleTransactionPayload()))).toBeNull();
  });
});

describe('AppleJwsVerifier', () => {
  let chain: AppleTestChain;
  let verifier: AppleJwsVerifier;

  beforeAll(async () => {
    chain = await createAppleTestChain();
    verifier = new AppleJwsVerifier({ clock: new FixedClock(), rootCertificatePem: chain.rootPem });
  });

  it('returns the payload of a valid JWS (x5c with and without the root)', async () => {
    const payload = appleTransactionPayload();
    expect(await verifier.verify(await signAppleJws(chain, payload))).toEqual(payload);
    expect(await verifier.verify(await signAppleJws(chain, payload, { omitRoot: true }))).toEqual(
      payload,
    );
  });

  it('rejects a bad signature, another key and a non-ES256 alg', async () => {
    const payload = appleTransactionPayload();
    expect(
      await verifier.verify(await signAppleJws(chain, payload, { tamperSignature: true })),
    ).toBeNull();
    const other = await createAppleTestChain({ name: 'Other' });
    expect(
      await verifier.verify(
        await signAppleJws(chain, payload, { signingKey: other.leafKeys.privateKey }),
      ),
    ).toBeNull();
    expect(await verifier.verify(await signAppleJws(chain, payload, { alg: 'ES384' }))).toBeNull();
  });

  it('rejects a chain to another root, or a third x5c entry that is not the pinned root', async () => {
    const other = await createAppleTestChain({ name: 'Rogue' });
    const payload = appleTransactionPayload();
    expect(await verifier.verify(await signAppleJws(other, payload))).toBeNull();
    const der = (c: { rawData: ArrayBuffer }) => toBase64(new Uint8Array(c.rawData));
    expect(
      await verifier.verify(
        await signAppleJws(chain, payload, {
          x5c: [der(chain.leaf), der(chain.intermediate), der(other.root)],
        }),
      ),
    ).toBeNull();
    // An intermediate signed by a different root with the same subject name.
    const twin = await createAppleTestChain();
    expect(
      await verifier.verify(
        await signAppleJws(twin, payload, {
          x5c: [der(twin.leaf), der(twin.intermediate)],
        }),
      ),
    ).toBeNull();
  });

  it('requires the Apple OIDs on the leaf and the intermediate', async () => {
    const payload = appleTransactionPayload();
    for (const options of [{ omitLeafOid: true }, { omitIntermediateOid: true }]) {
      const bad = await createAppleTestChain(options);
      const v = new AppleJwsVerifier({ clock: new FixedClock(), rootCertificatePem: bad.rootPem });
      expect(await v.verify(await signAppleJws(bad, payload)), JSON.stringify(options)).toBeNull();
    }
  });

  it('rejects an expired leaf', async () => {
    const expired = await createAppleTestChain({ leafNotAfter: new Date('2026-06-01T00:00:00Z') });
    const v = new AppleJwsVerifier({
      clock: new FixedClock('2026-09-26T10:00:00Z'),
      rootCertificatePem: expired.rootPem,
    });
    expect(await v.verify(await signAppleJws(expired, appleTransactionPayload()))).toBeNull();
  });

  it('rejects malformed input', async () => {
    const good = await signAppleJws(chain, appleTransactionPayload());
    const [header, body] = good.split('.');
    const b64 = (value: unknown) => toBase64Url(utf8(JSON.stringify(value)));
    for (const jws of [
      '',
      'a.b',
      `${good}.extra`,
      `${b64({ alg: 'ES256' })}.${String(body)}.sig`,
      `${b64({ alg: 'ES256', x5c: ['only-one'] })}.${String(body)}.sig`,
      `${b64({ alg: 'ES256', x5c: [1, 2] })}.${String(body)}.sig`,
      `${b64({ alg: 'ES256', x5c: ['not-der', 'not-der'] })}.${String(body)}.sig`,
      `${b64([1])}.${String(body)}.sig`,
      'bm90LWpzb24.e30.sig',
    ]) {
      expect(await verifier.verify(jws), jws.slice(0, 40)).toBeNull();
    }
    // A validly signed payload that is not a JSON object.
    expect(await verifier.verify(await signAppleJws(chain, [1, 2]))).toBeNull();
    expect(header).toBeDefined();
  });
});
