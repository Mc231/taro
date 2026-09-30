// The Reflect shim must load before @peculiar/x509 (see src/adapters/apple/x509.ts).
import '../../src/adapters/apple/reflectShim';
import * as x509 from '@peculiar/x509';
import { encode } from 'cbor-x';
import { ecdsaRawToDer } from '../../src/crypto/der';
import { concatBytes, toBase64, utf8 } from '../../src/crypto/encoding';

/**
 * App Attest test material generated in the test (06 §7, 03 §15.2): a root
 * CA and an intermediate (P-384, like Apple's), credential certificates with
 * the nonce extension, and attestation / assertion objects in Apple's CBOR
 * format. Nothing here is a real Apple key.
 */
export const NONCE_OID = '1.2.840.113635.100.8.2';
export const TEST_APP_ID = 'TEAMID1234.com.vshyrochuk.taro';
const P384 = { name: 'ECDSA', namedCurve: 'P-384', hash: 'SHA-384' } as const;
const P256 = { name: 'ECDSA', namedCurve: 'P-256' } as const;
const VALID_FROM = new Date('2026-01-01T00:00:00Z');
const VALID_TO = new Date('2046-01-01T00:00:00Z');

export interface TestCa {
  readonly rootPem: string;
  readonly intermediate: x509.X509Certificate;
  readonly intermediateKeys: CryptoKeyPair;
}

async function sha256(data: Uint8Array): Promise<Uint8Array> {
  return new Uint8Array(await crypto.subtle.digest('SHA-256', new Uint8Array(data)));
}

export async function createTestCa(): Promise<TestCa> {
  const rootKeys = (await crypto.subtle.generateKey(P384, true, [
    'sign',
    'verify',
  ])) as CryptoKeyPair;
  const root = await x509.X509CertificateGenerator.createSelfSigned({
    serialNumber: '01',
    name: 'CN=Test App Attestation Root CA, O=Taro Tests',
    notBefore: VALID_FROM,
    notAfter: VALID_TO,
    signingAlgorithm: P384,
    keys: rootKeys,
    extensions: [new x509.BasicConstraintsExtension(true, undefined, true)],
  });
  const intermediateKeys = (await crypto.subtle.generateKey(P384, true, [
    'sign',
    'verify',
  ])) as CryptoKeyPair;
  const intermediate = await x509.X509CertificateGenerator.create({
    serialNumber: '02',
    subject: 'CN=Test App Attestation CA 1, O=Taro Tests',
    issuer: root.subject,
    notBefore: VALID_FROM,
    notAfter: VALID_TO,
    signingAlgorithm: P384,
    publicKey: intermediateKeys.publicKey,
    signingKey: rootKeys.privateKey,
    extensions: [new x509.BasicConstraintsExtension(true, 0, true)],
  });
  return { rootPem: root.toString('pem'), intermediate, intermediateKeys };
}

/** `SEQUENCE { [1] EXPLICIT OCTET STRING nonce }` (32-byte nonce). */
export function nonceExtensionValue(nonce: Uint8Array): Uint8Array {
  return concatBytes(Uint8Array.of(0x30, 0x24, 0xa1, 0x22, 0x04, 0x20), nonce);
}

export interface AttestationOptions {
  readonly ca: TestCa;
  readonly clientDataHash: Uint8Array;
  readonly appId?: string;
  readonly aaguid?: 'appattest' | 'appattestdevelop' | 'other';
  readonly counter?: number;
  /** Replaces the nonce in the certificate extension. */
  readonly nonce?: Uint8Array;
  readonly omitNonceExtension?: boolean;
  /** Replaces the credential ID in authData. */
  readonly credentialId?: Uint8Array;
  readonly fmt?: string;
  readonly notAfter?: Date;
}

export interface TestAttestation {
  readonly keyId: string;
  readonly attestationObject: Uint8Array;
  readonly keys: CryptoKeyPair;
  readonly publicKeySpki: Uint8Array;
}

function aaguidBytes(kind: AttestationOptions['aaguid']): Uint8Array {
  if (kind === 'appattestdevelop') {
    return utf8('appattestdevelop');
  }
  if (kind === 'other') {
    return utf8('somethingelse!!!');
  }
  return concatBytes(utf8('appattest'), new Uint8Array(7));
}

function counterBytes(counter: number): Uint8Array {
  const out = new Uint8Array(4);
  new DataView(out.buffer).setUint32(0, counter);
  return out;
}

export async function makeAttestation(options: AttestationOptions): Promise<TestAttestation> {
  const keys = (await crypto.subtle.generateKey(P256, true, ['sign', 'verify'])) as CryptoKeyPair;
  const raw = new Uint8Array((await crypto.subtle.exportKey('raw', keys.publicKey)) as ArrayBuffer);
  const keyIdBytes = await sha256(raw);
  const credentialId = options.credentialId ?? keyIdBytes;
  const idLength = new Uint8Array(2);
  new DataView(idLength.buffer).setUint16(0, credentialId.length);
  const authData = concatBytes(
    await sha256(utf8(options.appId ?? TEST_APP_ID)),
    Uint8Array.of(0x41),
    counterBytes(options.counter ?? 0),
    aaguidBytes(options.aaguid),
    idLength,
    credentialId,
    encode(new Map([[1, 2]])),
  );
  const nonce = options.nonce ?? (await sha256(concatBytes(authData, options.clientDataHash)));
  const leaf = await x509.X509CertificateGenerator.create({
    serialNumber: '03',
    subject: `CN=${Array.from(keyIdBytes.subarray(0, 8), (b) => b.toString(16)).join('')}`,
    issuer: options.ca.intermediate.subject,
    notBefore: VALID_FROM,
    notAfter: options.notAfter ?? VALID_TO,
    signingAlgorithm: { name: 'ECDSA', hash: 'SHA-256' },
    publicKey: keys.publicKey,
    signingKey: options.ca.intermediateKeys.privateKey,
    extensions:
      options.omitNonceExtension === true
        ? []
        : [new x509.Extension(NONCE_OID, false, nonceExtensionValue(nonce))],
  });
  const attestationObject = encode({
    fmt: options.fmt ?? 'apple-appattest',
    attStmt: {
      x5c: [new Uint8Array(leaf.rawData), new Uint8Array(options.ca.intermediate.rawData)],
      receipt: utf8('test-receipt'),
    },
    authData,
  }) as Uint8Array;
  return {
    keyId: toBase64(keyIdBytes),
    attestationObject: new Uint8Array(attestationObject),
    keys,
    publicKeySpki: new Uint8Array(leaf.publicKey.rawData),
  };
}

export interface AssertionOptions {
  readonly privateKey: CryptoKey;
  readonly clientDataHash: Uint8Array;
  readonly counter: number;
  readonly appId?: string;
}

export async function makeAssertion(options: AssertionOptions): Promise<Uint8Array> {
  const authenticatorData = concatBytes(
    await sha256(utf8(options.appId ?? TEST_APP_ID)),
    Uint8Array.of(0x01),
    counterBytes(options.counter),
  );
  const nonce = await sha256(concatBytes(authenticatorData, options.clientDataHash));
  const raw = new Uint8Array(
    await crypto.subtle.sign({ name: 'ECDSA', hash: 'SHA-256' }, options.privateKey, nonce),
  );
  return new Uint8Array(encode({ signature: ecdsaRawToDer(raw), authenticatorData }) as Uint8Array);
}
