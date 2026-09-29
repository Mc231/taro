import { fromBase64, fromUtf8, utf8 } from '../../crypto/encoding';
import type { Clock } from '../../ports/Clock';
import { APPLE_ROOT_CA_G3_PEM } from './appleRootG3';
import { X509Certificate } from './x509';

/**
 * Verification of App Store JWS values (03 §6.2 step 2, §6.4): a
 * `signedTransactionInfo` from the App Store Server API, a client-supplied
 * StoreKit 2 `signedTransaction`, or an ASSN v2 `signedPayload`.
 *
 * Rules (Apple's "App Store Server Library" verifier, without online OCSP):
 * 1. compact JWS with `alg: "ES256"` and an `x5c` header of at least
 *    `[leaf, intermediate]`; a third entry, when present, must be the pinned
 *    root itself;
 * 2. leaf ← intermediate ← the pinned Apple Root CA G3, each signature valid
 *    and each certificate valid now;
 * 3. the leaf carries the Mac App Store receipt-signing OID
 *    `1.2.840.113635.100.6.11.1` and the intermediate the Apple WWDR OID
 *    `1.2.840.113635.100.6.2.1`;
 * 4. the ES256 signature over `header.payload` verifies with the leaf key.
 *
 * Any failure returns null; the caller maps it to `invalid`.
 */
export const APPLE_LEAF_OID = '1.2.840.113635.100.6.11.1';
export const APPLE_INTERMEDIATE_OID = '1.2.840.113635.100.6.2.1';

export interface AppleJwsOptions {
  readonly clock: Clock;
  /** PEM of the trust anchor; tests inject a generated root (06 §7). */
  readonly rootCertificatePem?: string;
}

const ECDSA_P256 = { name: 'ECDSA', namedCurve: 'P-256' } as const;

function equalBytes(a: Uint8Array, b: Uint8Array): boolean {
  return a.length === b.length && a.every((byte, i) => byte === b[i]);
}

function parseJsonObject(segment: string): Record<string, unknown> | null {
  const value: unknown = JSON.parse(fromUtf8(fromBase64(segment)));
  return value !== null && typeof value === 'object' && !Array.isArray(value)
    ? (value as Record<string, unknown>)
    : null;
}

export class AppleJwsVerifier {
  private readonly root: X509Certificate;

  constructor(private readonly options: AppleJwsOptions) {
    this.root = new X509Certificate(options.rootCertificatePem ?? APPLE_ROOT_CA_G3_PEM);
  }

  /** The decoded payload of a valid JWS, or null. */
  async verify(jws: string): Promise<Record<string, unknown> | null> {
    try {
      const parts = jws.split('.');
      const [headerPart, payloadPart, signaturePart] = parts;
      if (
        parts.length !== 3 ||
        headerPart === undefined ||
        payloadPart === undefined ||
        signaturePart === undefined
      ) {
        return null;
      }
      const header = parseJsonObject(headerPart);
      const x5c = header?.['x5c'];
      if (header?.['alg'] !== 'ES256' || !Array.isArray(x5c) || x5c.length < 2) {
        return null;
      }
      const certs = x5c.map((entry) => {
        if (typeof entry !== 'string') {
          throw new TypeError('x5c entry');
        }
        return new X509Certificate(fromBase64(entry));
      });
      const [leaf, intermediate, anchor] = certs as [
        X509Certificate,
        X509Certificate,
        X509Certificate | undefined,
      ];
      if (
        anchor !== undefined &&
        !equalBytes(new Uint8Array(anchor.rawData), new Uint8Array(this.root.rawData))
      ) {
        return null;
      }
      if (!(await this.chainValid(leaf, intermediate))) {
        return null;
      }
      const key = await crypto.subtle.importKey(
        'spki',
        new Uint8Array(leaf.publicKey.rawData),
        ECDSA_P256,
        false,
        ['verify'],
      );
      const signed = await crypto.subtle.verify(
        { name: 'ECDSA', hash: 'SHA-256' },
        key,
        new Uint8Array(fromBase64(signaturePart)),
        new Uint8Array(utf8(`${headerPart}.${payloadPart}`)),
      );
      return signed ? parseJsonObject(payloadPart) : null;
    } catch {
      return null;
    }
  }

  private async chainValid(leaf: X509Certificate, intermediate: X509Certificate): Promise<boolean> {
    const date = this.options.clock.now();
    return (
      leaf.issuer === intermediate.subject &&
      intermediate.issuer === this.root.subject &&
      leaf.getExtension(APPLE_LEAF_OID) !== null &&
      intermediate.getExtension(APPLE_INTERMEDIATE_OID) !== null &&
      (await leaf.verify({ date, publicKey: intermediate.publicKey })) &&
      (await intermediate.verify({ date, publicKey: this.root.publicKey })) &&
      (await this.root.verify({ date }))
    );
  }
}
