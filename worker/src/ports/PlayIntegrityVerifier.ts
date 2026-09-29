import type { AttestRejected } from './AppAttestVerifier';

/**
 * Play Integrity, Standard API only (03 §3.3, §3.4, RC87). The production
 * adapter (Phase 6.3) calls `decodeIntegrityToken` and checks requestHash,
 * package, app recognition, device integrity and a 120 s age.
 */
export interface PlayIntegrityInput {
  readonly token: string;
  /** base64url(SHA-256(...)) the token must bind (03 §3.1, §3.4). */
  readonly expectedRequestHash: string;
  readonly allowedPackageNames: readonly string[];
}

export interface PlayIntegrityVerdict {
  readonly ok: true;
  readonly deviceVerdict: 'device' | 'basic' | 'none';
  readonly appRecognized: boolean;
  readonly packageName: string;
  readonly licensed?: boolean;
}

export type PlayIntegrityResult = PlayIntegrityVerdict | AttestRejected;

export interface PlayIntegrityVerifier {
  verify(input: PlayIntegrityInput): Promise<PlayIntegrityResult>;
}
