import type { Platform, Trust } from '../domain/types';

/** Install token claims (03 §3.4): EdDSA JWT, `iss: taro-api`, `aud: taro-app`, 7-day TTL. */
export interface InstallTokenClaims {
  readonly sub: string;
  readonly gen: number;
  readonly trust: Trust;
  readonly plat: Platform;
}

export interface TokenVerified {
  readonly ok: true;
  readonly claims: InstallTokenClaims;
  readonly expired: boolean;
}

export interface TokenRejected {
  readonly ok: false;
}

export type TokenVerifyResult = TokenVerified | TokenRejected;

/** Ed25519 install-token signer with `kid` rotation (Phase 6.3 adapter over `jose`). */
export interface TokenSigner {
  sign(claims: InstallTokenClaims, now: Date): Promise<{ token: string; expiresAt: Date }>;
  verify(token: string, now: Date): Promise<TokenVerifyResult>;
}
