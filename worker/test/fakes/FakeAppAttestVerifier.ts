import type {
  AppAttestAssertionInput,
  AppAttestAssertionResult,
  AppAttestAttestationInput,
  AppAttestAttestationResult,
  AppAttestVerifier,
} from '../../src/ports/AppAttestVerifier';

/**
 * Scripted App Attest verdicts for route tests (03 §15.3). The real verifier
 * is adapter-tested with generated chains (Phase 6.3).
 */
export class FakeAppAttestVerifier implements AppAttestVerifier {
  readonly attestationCalls: AppAttestAttestationInput[] = [];
  readonly assertionCalls: AppAttestAssertionInput[] = [];
  private readonly attestationQueue: AppAttestAttestationResult[] = [];
  private readonly assertionQueue: AppAttestAssertionResult[] = [];

  attestationDefault: AppAttestAttestationResult = {
    ok: true,
    publicKey: new Uint8Array([1, 2, 3]),
    counter: 0,
    env: 'production',
  };

  /** Default: counter strictly above the previous one. */
  assertionDefault: ((input: AppAttestAssertionInput) => AppAttestAssertionResult) | undefined;

  enqueueAttestation(...results: AppAttestAttestationResult[]): this {
    this.attestationQueue.push(...results);
    return this;
  }

  enqueueAssertion(...results: AppAttestAssertionResult[]): this {
    this.assertionQueue.push(...results);
    return this;
  }

  verifyAttestation(input: AppAttestAttestationInput): Promise<AppAttestAttestationResult> {
    this.attestationCalls.push(input);
    return Promise.resolve(this.attestationQueue.shift() ?? this.attestationDefault);
  }

  verifyAssertion(input: AppAttestAssertionInput): Promise<AppAttestAssertionResult> {
    this.assertionCalls.push(input);
    const scripted = this.assertionQueue.shift();
    if (scripted !== undefined) {
      return Promise.resolve(scripted);
    }
    return Promise.resolve(
      this.assertionDefault?.(input) ?? { ok: true, counter: input.previousCounter + 1 },
    );
  }
}
