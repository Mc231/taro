import { errors, importJWK, jwtVerify, SignJWT, type JWK, type JWTPayload } from 'jose';
import { SecretConfigError } from '../../crypto/keyring';
import { isPlatform } from '../../domain/types';
import type { InstallTokenClaims, TokenSigner, TokenVerifyResult } from '../../ports/TokenSigner';

/**
 * Install tokens (03 §3.4, BE3): EdDSA (Ed25519) JWTs via `jose`, header
 * `kid`, claims `sub`, `gen`, `trust`, `plat`, `iat`, `exp` (7 days),
 * `iss: "taro-api"`, `aud: "taro-app"`.
 *
 * `TOKEN_SIGNING_KEYS` is a JWKS `{"keys": [...]}` of Ed25519 private JWKs
 * (`kty: OKP`, `crv: Ed25519`, `x`, `d`, `kid`). The **first** key signs;
 * every listed key verifies, so rotation is "prepend the new key, deploy,
 * drop the old one after 7 days" (03 §11).
 *
 * `verify` distinguishes an expired but otherwise valid token (`expired:
 * true`), which `POST /v1/installs/token` accepts, from an invalid one.
 */
export const INSTALL_TOKEN_TTL_SEC = 7 * 24 * 3600;
export const TOKEN_ISSUER = 'taro-api';
export const TOKEN_AUDIENCE = 'taro-app';
const ALG = 'EdDSA';

interface SigningKeys {
  readonly currentKid: string;
  readonly privateKey: CryptoKey;
  readonly publicKeys: ReadonlyMap<string, CryptoKey>;
}

/** Parses and imports `TOKEN_SIGNING_KEYS`. Rejects with `SecretConfigError` when unusable. */
export async function importSigningKeys(raw: string | undefined): Promise<SigningKeys> {
  if (raw === undefined || raw.trim() === '') {
    throw new SecretConfigError('TOKEN_SIGNING_KEYS is not set');
  }
  let jwks: { keys?: unknown };
  try {
    jwks = JSON.parse(raw) as { keys?: unknown };
  } catch {
    throw new SecretConfigError('TOKEN_SIGNING_KEYS is not JSON');
  }
  const keys = Array.isArray(jwks.keys) ? (jwks.keys as JWK[]) : [];
  const publicKeys = new Map<string, CryptoKey>();
  let privateKey: CryptoKey | undefined;
  for (const jwk of keys) {
    const kid = jwk.kid;
    const { x } = jwk;
    if (
      jwk.kty !== 'OKP' ||
      jwk.crv !== 'Ed25519' ||
      typeof jwk.d !== 'string' ||
      typeof x !== 'string' ||
      !kid
    ) {
      throw new SecretConfigError(
        'TOKEN_SIGNING_KEYS entries must be Ed25519 private JWKs with kid',
      );
    }
    if (publicKeys.has(kid)) {
      throw new SecretConfigError('TOKEN_SIGNING_KEYS has a duplicate kid');
    }
    const publicJwk: JWK = { kty: 'OKP', crv: 'Ed25519', x, kid };
    publicKeys.set(kid, (await importJWK(publicJwk, ALG)) as CryptoKey);
    privateKey ??= (await importJWK(jwk, ALG)) as CryptoKey;
  }
  const currentKid = keys[0]?.kid;
  if (privateKey === undefined || currentKid === undefined) {
    throw new SecretConfigError('TOKEN_SIGNING_KEYS has no keys');
  }
  return { currentKid, privateKey, publicKeys };
}

function claimsOf(payload: JWTPayload): InstallTokenClaims | undefined {
  const { sub, gen, trust, plat } = payload as JWTPayload & Record<string, unknown>;
  if (
    typeof sub !== 'string' ||
    typeof gen !== 'number' ||
    !Number.isInteger(gen) ||
    (trust !== 'high' && trust !== 'low') ||
    !isPlatform(plat)
  ) {
    return undefined;
  }
  return { sub, gen, trust, plat };
}

export class Ed25519TokenSigner implements TokenSigner {
  private keys: Promise<SigningKeys> | undefined;

  /** `rawKeys` is read on first use, so a missing secret fails only token routes. */
  constructor(private readonly rawKeys: () => string | undefined) {}

  async sign(claims: InstallTokenClaims, now: Date): Promise<{ token: string; expiresAt: Date }> {
    const keys = await this.loadKeys();
    const iat = Math.floor(now.getTime() / 1000);
    const exp = iat + INSTALL_TOKEN_TTL_SEC;
    const token = await new SignJWT({ gen: claims.gen, trust: claims.trust, plat: claims.plat })
      .setProtectedHeader({ alg: ALG, kid: keys.currentKid, typ: 'JWT' })
      .setSubject(claims.sub)
      .setIssuer(TOKEN_ISSUER)
      .setAudience(TOKEN_AUDIENCE)
      .setIssuedAt(iat)
      .setExpirationTime(exp)
      .sign(keys.privateKey);
    return { token, expiresAt: new Date(exp * 1000) };
  }

  async verify(token: string, now: Date): Promise<TokenVerifyResult> {
    const keys = await this.loadKeys();
    let payload: JWTPayload;
    let expired = false;
    try {
      ({ payload } = await jwtVerify(
        token,
        (header) => {
          const key = header.kid === undefined ? undefined : keys.publicKeys.get(header.kid);
          if (key === undefined) {
            throw new Error('unknown kid');
          }
          return key;
        },
        {
          algorithms: [ALG],
          issuer: TOKEN_ISSUER,
          audience: TOKEN_AUDIENCE,
          currentDate: now,
          requiredClaims: ['sub', 'exp', 'iat'],
        },
      ));
    } catch (err) {
      if (!(err instanceof errors.JWTExpired)) {
        return { ok: false };
      }
      // Thrown only after the signature and the other claims were verified.
      payload = err.payload;
      expired = true;
    }
    const claims = claimsOf(payload);
    return claims === undefined ? { ok: false } : { ok: true, claims, expired };
  }

  private loadKeys(): Promise<SigningKeys> {
    this.keys ??= importSigningKeys(this.rawKeys()).catch((err: unknown) => {
      this.keys = undefined;
      throw err;
    });
    return this.keys;
  }
}
