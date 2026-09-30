import { decode, encode } from 'cbor-x';
import { beforeAll, describe, expect, it } from 'vitest';
import {
  APPLE_APP_ATTESTATION_ROOT_CA_PEM,
  APPLE_APP_ATTESTATION_ROOT_CA_SHA256,
} from '../../../src/adapters/apple/appAttestRoot';
import {
  AppleAppAttestVerifier,
  certificateSha256,
  extractNonce,
  parseAuthData,
} from '../../../src/adapters/apple/AppAttestVerifier';
import { installReflectMetadataShim } from '../../../src/adapters/apple/reflectShim';
import { X509Certificate } from '../../../src/adapters/apple/x509';
import { WebCrypto } from '../../../src/adapters/cf/WebCrypto';
import { fromBase64, toBase64, utf8 } from '../../../src/crypto/encoding';
import { FixedClock } from '../../fakes/FixedClock';
import {
  createTestCa,
  makeAssertion,
  makeAttestation,
  nonceExtensionValue,
  TEST_APP_ID,
  type AttestationOptions,
  type TestCa,
} from '../../helpers/appAttest';
import fixture from '../../fixtures/app_attest/attestation.dev.json';

const crypto = new WebCrypto();
const clock = new FixedClock('2026-09-26T10:00:00.000Z');
const ALLOWED = [TEST_APP_ID, 'com.vshyrochuk.taro'];

let ca: TestCa;
let otherCa: TestCa;

beforeAll(async () => {
  ca = await createTestCa();
  otherCa = await createTestCa();
});

function verifier(options: { allowDevelopment?: boolean; root?: string } = {}) {
  return new AppleAppAttestVerifier({
    crypto,
    clock,
    allowDevelopment: options.allowDevelopment ?? false,
    rootCertificatePem: options.root ?? ca.rootPem,
  });
}

const clientDataHash = new Uint8Array(32).fill(9);

async function attest(
  options: Partial<AttestationOptions> = {},
  verifyWith: { allowDevelopment?: boolean; root?: string; keyId?: string; appIds?: string[] } = {},
) {
  const att = await makeAttestation({ ca, clientDataHash, ...options });
  const result = await verifier(verifyWith).verifyAttestation({
    keyId: verifyWith.keyId ?? att.keyId,
    attestationObject: att.attestationObject,
    clientDataHash,
    allowedAppIds: verifyWith.appIds ?? ALLOWED,
  });
  return { att, result };
}

describe('AppleAppAttestVerifier.verifyAttestation (03 §3.3)', () => {
  it('accepts a valid production attestation and returns the SPKI key, counter 0 and env', async () => {
    const { att, result } = await attest();
    expect(result).toEqual({
      ok: true,
      publicKey: att.publicKeySpki,
      counter: 0,
      env: 'production',
    });
  });

  it('accepts appattestdevelop only where development is allowed', async () => {
    expect((await attest({ aaguid: 'appattestdevelop' })).result).toEqual({
      ok: false,
      reason: 'invalid',
      detail: 'aaguid',
    });
    const { result } = await attest({ aaguid: 'appattestdevelop' }, { allowDevelopment: true });
    expect(result).toMatchObject({ ok: true, env: 'development' });
    expect((await attest({ aaguid: 'other' }, { allowDevelopment: true })).result).toMatchObject({
      detail: 'aaguid',
    });
  });

  it.each<[string, Partial<AttestationOptions>, string]>([
    ['a wrong fmt', { fmt: 'packed' }, 'fmt'],
    [
      'a nonce that does not bind authData ‖ clientDataHash',
      { nonce: new Uint8Array(32) },
      'nonce',
    ],
    ['no nonce extension', { omitNonceExtension: true }, 'nonce_ext'],
    ['a non-zero counter', { counter: 1 }, 'counter'],
    ['another app ID', { appId: 'OTHERTEAM1.com.example.app' }, 'rp_id'],
    [
      'a credential ID that is not the key ID',
      { credentialId: new Uint8Array(32) },
      'credential_id',
    ],
    ['an expired credential certificate', { notAfter: new Date('2026-01-02T00:00:00Z') }, 'chain'],
  ])('rejects %s', async (_label, options, detail) => {
    expect((await attest(options)).result).toEqual({ ok: false, reason: 'invalid', detail });
  });

  it('rejects a chain that does not lead to the pinned root', async () => {
    const { result } = await attest({}, { root: otherCa.rootPem });
    expect(result).toMatchObject({ ok: false, detail: 'chain' });
    // The real Apple root never signs test certificates.
    const apple = await attest({}, { root: APPLE_APP_ATTESTATION_ROOT_CA_PEM });
    expect(apple.result).toMatchObject({ ok: false, detail: 'chain' });
  });

  it('rejects a key ID that is not SHA-256 of the credential public key', async () => {
    const { result } = await attest({}, { keyId: toBase64(new Uint8Array(32).fill(1)) });
    expect(result).toMatchObject({ ok: false, detail: 'key_id' });
  });

  it('rejects when no allowed app ID matches (unresolved {TEAM} entries are dropped upstream)', async () => {
    const { result } = await attest({}, { appIds: ['com.vshyrochuk.taro'] });
    expect(result).toMatchObject({ ok: false, detail: 'rp_id' });
  });

  it('rejects malformed objects without throwing', async () => {
    const v = verifier();
    const input = { keyId: 'AA', clientDataHash, allowedAppIds: ALLOWED };
    for (const [object, detail] of [
      [Uint8Array.of(0x58, 0x10), 'malformed'],
      [encode(['array']), 'cbor'],
      [encode({ fmt: 'apple-appattest', attStmt: 'x', authData: new Uint8Array(1) }), 'att_stmt'],
      [encode({ fmt: 'apple-appattest', attStmt: { x5c: [] }, authData: 'x' }), 'auth_data'],
      [
        encode({ fmt: 'apple-appattest', attStmt: { x5c: ['x'] }, authData: new Uint8Array(1) }),
        'x5c',
      ],
    ] as const) {
      expect(
        await v.verifyAttestation({ ...input, attestationObject: object as Uint8Array }),
      ).toMatchObject({ ok: false, reason: 'invalid', detail });
    }
  });
});

describe('AppleAppAttestVerifier.verifyAssertion (03 §3.4)', () => {
  it('verifies the signature over SHA256(authenticatorData ‖ clientDataHash) and a rising counter', async () => {
    const { att } = await attest();
    const v = verifier();
    const assertion = await makeAssertion({
      privateKey: att.keys.privateKey,
      clientDataHash,
      counter: 5,
    });
    const input = {
      assertion,
      clientDataHash,
      publicKey: att.publicKeySpki,
      allowedAppIds: ALLOWED,
    };
    expect(await v.verifyAssertion({ ...input, previousCounter: 4 })).toEqual({
      ok: true,
      counter: 5,
    });
    expect(await v.verifyAssertion({ ...input, previousCounter: 5 })).toEqual({
      ok: false,
      reason: 'invalid',
      detail: 'counter',
    });
  });

  it('rejects another key, another hash, another app and malformed input', async () => {
    const { att } = await attest();
    const { att: other } = await attest();
    const v = verifier();
    const assertion = await makeAssertion({
      privateKey: att.keys.privateKey,
      clientDataHash,
      counter: 1,
    });
    const base = {
      assertion,
      clientDataHash,
      publicKey: att.publicKeySpki,
      previousCounter: 0,
      allowedAppIds: ALLOWED,
    };
    expect(await v.verifyAssertion({ ...base, publicKey: other.publicKeySpki })).toMatchObject({
      detail: 'signature',
    });
    expect(await v.verifyAssertion({ ...base, clientDataHash: new Uint8Array(32) })).toMatchObject({
      detail: 'signature',
    });
    const otherApp = await makeAssertion({
      privateKey: att.keys.privateKey,
      clientDataHash,
      counter: 1,
      appId: 'X.y.z',
    });
    expect(await v.verifyAssertion({ ...base, assertion: otherApp })).toMatchObject({
      detail: 'rp_id',
    });
    expect(await v.verifyAssertion({ ...base, assertion: encode({ signature: 1 }) })).toMatchObject(
      { detail: 'signature' },
    );
    expect(
      await v.verifyAssertion({ ...base, assertion: Uint8Array.of(0x58, 0x10) }),
    ).toMatchObject({ detail: 'malformed' });
  });
});

describe('App Attest helpers', () => {
  it('parses authenticator data with and without attested credential data', () => {
    const short = new Uint8Array(37);
    short[36] = 7;
    expect(parseAuthData(short)).toEqual({ rpIdHash: short.subarray(0, 32), counter: 7 });
    expect(() => parseAuthData(new Uint8Array(36))).toThrow('auth_data');
    const flagged = new Uint8Array(40);
    flagged[32] = 0x40;
    expect(() => parseAuthData(flagged)).toThrow('auth_data');
    const badLength = new Uint8Array(55);
    badLength[32] = 0x40;
    badLength[54] = 10;
    expect(() => parseAuthData(badLength)).toThrow('auth_data');
  });

  it('extracts the nonce and rejects other structures', () => {
    const nonce = new Uint8Array(32).fill(3);
    expect(extractNonce(nonceExtensionValue(nonce))).toEqual(nonce);
    expect(() => extractNonce(Uint8Array.of(0x31, 0x00))).toThrow('nonce_ext');
    expect(() => extractNonce(Uint8Array.of(0x30, 0x02, 0xa2, 0x00))).toThrow('nonce_ext');
    expect(() => extractNonce(Uint8Array.of(0x30, 0x04, 0xa1, 0x02, 0x05, 0x00))).toThrow(
      'nonce_ext',
    );
  });

  it('installs the Reflect metadata shim only where it is missing', () => {
    const target: Record<string, unknown> = {};
    expect(installReflectMetadataShim(target)).toBe(true);
    const reflect = target as {
      defineMetadata: (k: unknown, v: unknown, t: object) => void;
      getMetadata: (k: unknown, t: object) => unknown;
      getOwnMetadata: (k: unknown, t: object) => unknown;
    };
    class Base {
      readonly kind: string = 'base';
    }
    class Child extends Base {}
    reflect.defineMetadata('k', 1, Base.prototype);
    reflect.defineMetadata('k2', 2, Base.prototype);
    expect(reflect.getMetadata('k', Child.prototype)).toBe(1);
    expect(reflect.getOwnMetadata('k', Child.prototype)).toBeUndefined();
    expect(reflect.getMetadata('missing', Child.prototype)).toBeUndefined();
    expect(installReflectMetadataShim(target)).toBe(false);
  });
});

describe('pinned Apple App Attestation Root CA', () => {
  it('is the published certificate: fingerprint, subject, validity and self-signature', async () => {
    expect(await certificateSha256(APPLE_APP_ATTESTATION_ROOT_CA_PEM)).toBe(
      APPLE_APP_ATTESTATION_ROOT_CA_SHA256,
    );
    const root = new X509Certificate(APPLE_APP_ATTESTATION_ROOT_CA_PEM);
    expect(root.subject).toBe('CN=Apple App Attestation Root CA, O=Apple Inc., ST=California');
    expect(root.notBefore.toISOString()).toBe('2020-03-18T18:32:53.000Z');
    expect(root.notAfter.toISOString()).toBe('2045-03-15T00:00:00.000Z');
    expect(await root.verify({ date: clock.now() })).toBe(true);
  });

  it('is the default trust anchor', async () => {
    const v = new AppleAppAttestVerifier({ crypto, clock, allowDevelopment: false });
    const { att } = await attest();
    expect(
      await v.verifyAttestation({
        keyId: att.keyId,
        attestationObject: att.attestationObject,
        clientDataHash,
        allowedAppIds: ALLOWED,
      }),
    ).toMatchObject({ ok: false, detail: 'chain' });
  });
});

describe('real-format decode fixture (06 §7)', () => {
  it('decodes Apple’s attestation layout and verifies against the fixture root', async () => {
    const object = decode(fromBase64(fixture.attestationObject)) as {
      fmt: string;
      attStmt: { x5c: Uint8Array[]; receipt: Uint8Array };
      authData: Uint8Array;
    };
    expect(object.fmt).toBe('apple-appattest');
    expect(object.attStmt.x5c).toHaveLength(2);
    expect(object.attStmt.receipt.length).toBeGreaterThan(0);
    const authData = parseAuthData(object.authData);
    expect(authData.counter).toBe(0);
    expect(authData.aaguid).toEqual(utf8('appattestdevelop'));
    expect(authData.credentialId).toEqual(fromBase64(fixture.keyId));
    const leaf = new X509Certificate(object.attStmt.x5c[0] ?? new Uint8Array());
    expect(leaf.getExtension('1.2.840.113635.100.8.2')).not.toBeNull();

    const v = verifier({ allowDevelopment: true, root: fixture.rootPem });
    const clientData = fromBase64(fixture.clientDataHash);
    expect(
      await v.verifyAttestation({
        keyId: fixture.keyId,
        attestationObject: fromBase64(fixture.attestationObject),
        clientDataHash: clientData,
        allowedAppIds: [fixture.appId],
      }),
    ).toEqual({
      ok: true,
      publicKey: fromBase64(fixture.publicKeySpki),
      counter: 0,
      env: 'development',
    });
    expect(
      await v.verifyAssertion({
        assertion: fromBase64(fixture.assertion),
        clientDataHash: clientData,
        publicKey: fromBase64(fixture.publicKeySpki),
        previousCounter: 0,
        allowedAppIds: [fixture.appId],
      }),
    ).toEqual({ ok: true, counter: fixture.assertionCounter });
  });
});
