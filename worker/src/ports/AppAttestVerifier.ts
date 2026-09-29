/**
 * Apple App Attest (03 §3.3, §3.4). The production adapter
 * (`adapters/apple/AppAttestVerifier.ts`) decodes CBOR, checks the x5c chain
 * to the pinned Apple root, nonce, rpIdHash, counter and aaguid; route tests
 * use `FakeAppAttestVerifier`.
 *
 * `invalid` is a hard failure (→ `403 ATTESTATION_FAILED`); `unavailable`
 * means the verdict could not be obtained (an outage) and degrades to low
 * trust (BE4).
 */
export type AttestFailureReason = 'invalid' | 'unavailable';

export interface AppAttestAttestationInput {
  /** base64 `keyId` from `DCAppAttestService.generateKey()` (SHA-256 of the public key). */
  readonly keyId: string;
  readonly attestationObject: Uint8Array;
  readonly clientDataHash: Uint8Array;
  readonly allowedAppIds: readonly string[];
}

export interface AttestRejected {
  readonly ok: false;
  readonly reason: AttestFailureReason;
  /** Short machine label of the failed check (for logs and metrics; never payload data). */
  readonly detail?: string;
}

export interface AppAttestAttested {
  readonly ok: true;
  /** Credential public key, SPKI DER. */
  readonly publicKey: Uint8Array;
  readonly counter: number;
  readonly env: 'production' | 'development';
}

export type AppAttestAttestationResult = AppAttestAttested | AttestRejected;

export interface AppAttestAssertionInput {
  readonly assertion: Uint8Array;
  readonly clientDataHash: Uint8Array;
  readonly publicKey: Uint8Array;
  readonly previousCounter: number;
  readonly allowedAppIds: readonly string[];
}

export interface AppAttestAsserted {
  readonly ok: true;
  readonly counter: number;
}

export type AppAttestAssertionResult = AppAttestAsserted | AttestRejected;

export interface AppAttestVerifier {
  verifyAttestation(input: AppAttestAttestationInput): Promise<AppAttestAttestationResult>;
  verifyAssertion(input: AppAttestAssertionInput): Promise<AppAttestAssertionResult>;
}
