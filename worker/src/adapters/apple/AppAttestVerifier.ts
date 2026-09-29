import { decode } from 'cbor-x';
import { concatBytes, fromBase64, toHex, utf8 } from '../../crypto/encoding';
import { ecdsaDerToRaw, readTlv } from '../../crypto/der';
import type {
  AppAttestAssertionInput,
  AppAttestAssertionResult,
  AppAttestAttestationInput,
  AppAttestAttestationResult,
  AppAttestVerifier,
  AttestRejected,
} from '../../ports/AppAttestVerifier';
import type { Clock } from '../../ports/Clock';
import type { Crypto } from '../../ports/Crypto';
import { APPLE_APP_ATTESTATION_ROOT_CA_PEM } from './appAttestRoot';
import { X509Certificate } from './x509';

/**
 * Apple App Attest verification (03 §3.3, §3.4), following Apple's
 * "Validating apps that connect to your server":
 *
 * attestation — CBOR `{fmt: "apple-appattest", attStmt: {x5c, receipt}, authData}`:
 *  1. `x5c[0]` (credential cert) ← `x5c[1]` (intermediate) ← the pinned root, valid now;
 *  2. `nonce = SHA256(authData ‖ clientDataHash)` equals the credential cert
 *     extension `1.2.840.113635.100.8.2` (`SEQUENCE { [1] { OCTET STRING } }`);
 *  3. `SHA256(uncompressed public key) == keyId` and the credential ID equals `keyId`;
 *  4. `rpIdHash ∈ { SHA256(appId) : appId ∈ allowedAppIds }`, `counter == 0`;
 *  5. `aaguid` is `appattest` (production) or, only when development is
 *     allowed (dev/staging), `appattestdevelop`.
 *
 * assertion — CBOR `{signature, authenticatorData}`: ECDSA P-256 over
 * `SHA256(authenticatorData ‖ clientDataHash)` with the stored key,
 * `rpIdHash` allowed, and `counter > previousCounter`.
 *
 * Verification is local, so every failure is `invalid` (a hard failure).
 */
export interface AppleAppAttestOptions {
  readonly crypto: Crypto;
  readonly clock: Clock;
  /** `appattestdevelop` accepted (dev and staging only, 03 §3.3). */
  readonly allowDevelopment: boolean;
  /** PEM of the trust anchor; tests inject a generated root (06 §7). */
  readonly rootCertificatePem?: string;
}

const NONCE_EXTENSION_OID = '1.2.840.113635.100.8.2';
const FMT = 'apple-appattest';
const AAGUID_PRODUCTION = concatBytes(utf8('appattest'), new Uint8Array(7));
const AAGUID_DEVELOPMENT = utf8('appattestdevelop');
const FLAG_ATTESTED_CREDENTIAL_DATA = 0x40;
const ECDSA_P256 = { name: 'ECDSA', namedCurve: 'P-256' } as const;

interface AuthData {
  readonly rpIdHash: Uint8Array;
  readonly counter: number;
  readonly aaguid?: Uint8Array;
  readonly credentialId?: Uint8Array;
}

class Rejection extends Error {
  constructor(readonly detail: string) {
    super(detail);
  }
}

function reject(detail: string): never {
  throw new Rejection(detail);
}

function asBytes(value: unknown, label: string): Uint8Array {
  return value instanceof Uint8Array ? value : reject(label);
}

function asRecord(value: unknown, label: string): Record<string, unknown> {
  return value !== null && typeof value === 'object' && !Array.isArray(value)
    ? (value as Record<string, unknown>)
    : reject(label);
}

/** `authenticatorData` layout (WebAuthn §6.1). */
export function parseAuthData(bytes: Uint8Array): AuthData {
  if (bytes.length < 37) {
    reject('auth_data');
  }
  const view = new DataView(bytes.buffer, bytes.byteOffset, bytes.byteLength);
  const rpIdHash = bytes.subarray(0, 32);
  const flags = bytes[32] ?? 0;
  const counter = view.getUint32(33);
  if ((flags & FLAG_ATTESTED_CREDENTIAL_DATA) === 0) {
    return { rpIdHash, counter };
  }
  if (bytes.length < 55) {
    reject('auth_data');
  }
  const aaguid = bytes.subarray(37, 53);
  const idLength = view.getUint16(53);
  if (bytes.length < 55 + idLength) {
    reject('auth_data');
  }
  return { rpIdHash, counter, aaguid, credentialId: bytes.subarray(55, 55 + idLength) };
}

function equal(a: Uint8Array, b: Uint8Array): boolean {
  return a.length === b.length && a.every((byte, i) => byte === b[i]);
}

/** The 32-byte nonce inside the credential certificate extension. */
export function extractNonce(extensionValue: Uint8Array): Uint8Array {
  const seq = readTlv(extensionValue);
  const tagged = seq.tag === 0x30 ? readTlv(extensionValue, seq.start) : reject('nonce_ext');
  const octets = tagged.tag === 0xa1 ? readTlv(extensionValue, tagged.start) : reject('nonce_ext');
  return octets.tag === 0x04
    ? extensionValue.subarray(octets.start, octets.end)
    : reject('nonce_ext');
}

export class AppleAppAttestVerifier implements AppAttestVerifier {
  private readonly root: X509Certificate;

  constructor(private readonly options: AppleAppAttestOptions) {
    this.root = new X509Certificate(
      options.rootCertificatePem ?? APPLE_APP_ATTESTATION_ROOT_CA_PEM,
    );
  }

  async verifyAttestation(input: AppAttestAttestationInput): Promise<AppAttestAttestationResult> {
    try {
      const object = asRecord(decode(input.attestationObject), 'cbor');
      if (object['fmt'] !== FMT) {
        reject('fmt');
      }
      const statement = asRecord(object['attStmt'], 'att_stmt');
      const x5c = Array.isArray(statement['x5c']) ? (statement['x5c'] as unknown[]) : [];
      const [leafDer, intermediateDer] = x5c;
      const authDataBytes = asBytes(object['authData'], 'auth_data');
      const leaf = new X509Certificate(asBytes(leafDer, 'x5c'));
      const intermediate = new X509Certificate(asBytes(intermediateDer, 'x5c'));
      await this.verifyChain(leaf, intermediate);

      const expectedNonce = await this.options.crypto.sha256(
        concatBytes(authDataBytes, input.clientDataHash),
      );
      const extension = leaf.getExtension(NONCE_EXTENSION_OID) ?? reject('nonce_ext');
      if (!equal(extractNonce(new Uint8Array(extension.value)), expectedNonce)) {
        reject('nonce');
      }

      const spki = new Uint8Array(leaf.publicKey.rawData);
      const point = await rawPublicKey(spki);
      const keyId = fromBase64(input.keyId);
      if (!equal(await this.options.crypto.sha256(point), keyId)) {
        reject('key_id');
      }

      const authData = parseAuthData(authDataBytes);
      await this.checkRpId(authData.rpIdHash, input.allowedAppIds);
      if (authData.counter !== 0) {
        reject('counter');
      }
      const env = this.environmentOf(authData.aaguid ?? reject('aaguid'));
      if (!equal(authData.credentialId ?? reject('credential_id'), keyId)) {
        reject('credential_id');
      }
      return { ok: true, publicKey: spki, counter: 0, env };
    } catch (err) {
      return rejection(err);
    }
  }

  async verifyAssertion(input: AppAttestAssertionInput): Promise<AppAttestAssertionResult> {
    try {
      const object = asRecord(decode(input.assertion), 'cbor');
      const signature = asBytes(object['signature'], 'signature');
      const authDataBytes = asBytes(object['authenticatorData'], 'auth_data');
      const nonce = await this.options.crypto.sha256(
        concatBytes(authDataBytes, input.clientDataHash),
      );
      const key = await crypto.subtle.importKey(
        'spki',
        new Uint8Array(input.publicKey),
        ECDSA_P256,
        false,
        ['verify'],
      );
      const valid = await crypto.subtle.verify(
        { name: 'ECDSA', hash: 'SHA-256' },
        key,
        new Uint8Array(ecdsaDerToRaw(signature)),
        new Uint8Array(nonce),
      );
      if (!valid) {
        reject('signature');
      }
      const authData = parseAuthData(authDataBytes);
      await this.checkRpId(authData.rpIdHash, input.allowedAppIds);
      if (authData.counter <= input.previousCounter) {
        reject('counter');
      }
      return { ok: true, counter: authData.counter };
    } catch (err) {
      return rejection(err);
    }
  }

  private async verifyChain(leaf: X509Certificate, intermediate: X509Certificate): Promise<void> {
    const date = this.options.clock.now();
    const chainOk =
      leaf.issuer === intermediate.subject &&
      intermediate.issuer === this.root.subject &&
      (await leaf.verify({ date, publicKey: intermediate.publicKey })) &&
      (await intermediate.verify({ date, publicKey: this.root.publicKey })) &&
      (await this.root.verify({ date }));
    if (!chainOk) {
      reject('chain');
    }
  }

  private async checkRpId(rpIdHash: Uint8Array, allowedAppIds: readonly string[]): Promise<void> {
    const expected = await Promise.all(allowedAppIds.map((id) => this.options.crypto.sha256(id)));
    if (!expected.some((hash) => equal(hash, rpIdHash))) {
      reject('rp_id');
    }
  }

  private environmentOf(aaguid: Uint8Array): 'production' | 'development' {
    if (equal(aaguid, AAGUID_PRODUCTION)) {
      return 'production';
    }
    if (this.options.allowDevelopment && equal(aaguid, AAGUID_DEVELOPMENT)) {
      return 'development';
    }
    return reject('aaguid');
  }
}

/** Uncompressed EC point (65 bytes) of a P-256 SPKI; rejects any other key type. */
async function rawPublicKey(spki: Uint8Array): Promise<Uint8Array> {
  const key = await crypto.subtle.importKey('spki', new Uint8Array(spki), ECDSA_P256, true, [
    'verify',
  ]);
  return new Uint8Array((await crypto.subtle.exportKey('raw', key)) as ArrayBuffer);
}

function rejection(err: unknown): AttestRejected {
  return {
    ok: false,
    reason: 'invalid',
    detail: err instanceof Rejection ? err.detail : 'malformed',
  };
}

/** Hex SHA-256 thumbprint of a PEM certificate (tests pin the Apple root with it). */
export async function certificateSha256(pem: string): Promise<string> {
  return toHex(new Uint8Array(await new X509Certificate(pem).getThumbprint('SHA-256')));
}
