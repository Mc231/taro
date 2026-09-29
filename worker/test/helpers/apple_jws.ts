// The Reflect shim must load before @peculiar/x509 (see src/adapters/apple/x509.ts).
import '../../src/adapters/apple/reflectShim';
import * as x509 from '@peculiar/x509';
import { APPLE_INTERMEDIATE_OID, APPLE_LEAF_OID } from '../../src/adapters/apple/AppleJwsVerifier';
import { toBase64, toBase64Url, utf8 } from '../../src/crypto/encoding';

/**
 * App Store JWS test material generated in the test (06 §7, 04 §15): a root
 * CA (P-384, like Apple Root CA G3), an intermediate with the Apple WWDR OID
 * and a P-256 leaf with the receipt-signing OID, plus a signer for
 * `signedTransactionInfo` payloads. Nothing here is a real Apple key; the
 * Worker trusts this root only because tests inject its PEM.
 */
const P384 = { name: 'ECDSA', namedCurve: 'P-384', hash: 'SHA-384' } as const;
const P256 = { name: 'ECDSA', namedCurve: 'P-256' } as const;
const VALID_FROM = new Date('2026-01-01T00:00:00Z');
const VALID_TO = new Date('2046-01-01T00:00:00Z');
/** DER `NULL`, the value Apple uses for both marker extensions. */
const DER_NULL = Uint8Array.of(0x05, 0x00);

export interface AppleTestChain {
  readonly rootPem: string;
  readonly root: x509.X509Certificate;
  readonly intermediate: x509.X509Certificate;
  readonly leaf: x509.X509Certificate;
  readonly leafKeys: CryptoKeyPair;
}

export interface ChainOptions {
  /** Omit the leaf's `1.2.840.113635.100.6.11.1` extension. */
  readonly omitLeafOid?: boolean;
  /** Omit the intermediate's `1.2.840.113635.100.6.2.1` extension. */
  readonly omitIntermediateOid?: boolean;
  readonly leafNotAfter?: Date;
  readonly name?: string;
}

async function ecKeys(params: typeof P384 | typeof P256): Promise<CryptoKeyPair> {
  return (await crypto.subtle.generateKey(params, true, ['sign', 'verify'])) as CryptoKeyPair;
}

export async function createAppleTestChain(options: ChainOptions = {}): Promise<AppleTestChain> {
  const name = options.name ?? 'Test';
  const rootKeys = await ecKeys(P384);
  const root = await x509.X509CertificateGenerator.createSelfSigned({
    serialNumber: '01',
    name: `CN=${name} Apple Root CA - G3, O=Taro Tests`,
    notBefore: VALID_FROM,
    notAfter: VALID_TO,
    signingAlgorithm: P384,
    keys: rootKeys,
    extensions: [new x509.BasicConstraintsExtension(true, undefined, true)],
  });
  const intermediateKeys = await ecKeys(P384);
  const intermediate = await x509.X509CertificateGenerator.create({
    serialNumber: '02',
    subject: `CN=${name} Apple Worldwide Developer Relations CA - G6, O=Taro Tests`,
    issuer: root.subject,
    notBefore: VALID_FROM,
    notAfter: VALID_TO,
    signingAlgorithm: P384,
    publicKey: intermediateKeys.publicKey,
    signingKey: rootKeys.privateKey,
    extensions: [
      new x509.BasicConstraintsExtension(true, 0, true),
      ...(options.omitIntermediateOid === true
        ? []
        : [new x509.Extension(APPLE_INTERMEDIATE_OID, false, DER_NULL)]),
    ],
  });
  const leafKeys = await ecKeys(P256);
  const leaf = await x509.X509CertificateGenerator.create({
    serialNumber: '03',
    subject: `CN=${name} Prod ECC Mac App Store and iTunes Store Receipt Signing, O=Taro Tests`,
    issuer: intermediate.subject,
    notBefore: VALID_FROM,
    notAfter: options.leafNotAfter ?? VALID_TO,
    signingAlgorithm: P384,
    publicKey: leafKeys.publicKey,
    signingKey: intermediateKeys.privateKey,
    extensions:
      options.omitLeafOid === true ? [] : [new x509.Extension(APPLE_LEAF_OID, false, DER_NULL)],
  });
  return { rootPem: root.toString('pem'), root, intermediate, leaf, leafKeys };
}

export interface SignOptions {
  readonly alg?: string;
  /** Replaces the `x5c` header (base64 DER strings). */
  readonly x5c?: readonly unknown[];
  /** Leave the root out of `x5c` (two entries). */
  readonly omitRoot?: boolean;
  /** Flip a bit of the signature. */
  readonly tamperSignature?: boolean;
  /** Sign with this key instead of the leaf's. */
  readonly signingKey?: CryptoKey;
}

function der(cert: x509.X509Certificate): string {
  return toBase64(new Uint8Array(cert.rawData));
}

/** A compact JWS over `payload` in Apple's format (`alg: ES256`, `x5c` chain). */
export async function signAppleJws(
  chain: AppleTestChain,
  payload: unknown,
  options: SignOptions = {},
): Promise<string> {
  const x5c =
    options.x5c ??
    (options.omitRoot === true
      ? [der(chain.leaf), der(chain.intermediate)]
      : [der(chain.leaf), der(chain.intermediate), der(chain.root)]);
  const header = toBase64Url(utf8(JSON.stringify({ alg: options.alg ?? 'ES256', x5c })));
  const body = toBase64Url(utf8(JSON.stringify(payload)));
  const signature = new Uint8Array(
    await crypto.subtle.sign(
      { name: 'ECDSA', hash: 'SHA-256' },
      options.signingKey ?? chain.leafKeys.privateKey,
      new Uint8Array(utf8(`${header}.${body}`)),
    ),
  );
  if (options.tamperSignature === true) {
    signature[0] = (signature[0] ?? 0) ^ 0x01;
  }
  return `${header}.${body}.${toBase64Url(signature)}`;
}

/** A `JWSTransactionDecodedPayload` of a consumable, with overrides. */
export function appleTransactionPayload(
  overrides: Record<string, unknown> = {},
): Record<string, unknown> {
  return {
    transactionId: '2000000712345678',
    originalTransactionId: '2000000712345678',
    bundleId: 'com.vshyrochuk.taro',
    productId: 'com.vshyrochuk.taro.readings_3',
    type: 'Consumable',
    environment: 'Production',
    purchaseDate: Date.parse('2026-09-26T09:59:00Z'),
    signedDate: Date.parse('2026-09-26T10:00:00Z'),
    quantity: 1,
    inAppOwnershipType: 'PURCHASED',
    ...overrides,
  };
}
