import type { AdmobKeyProvider } from '../../src/ports/StoreApis';

/**
 * AdMob SSV verifier keys for tests (03 §15.3): SPKI bytes of P-256 keys
 * generated in the test (`test/helpers/admobSsv.ts`), keyed by `key_id`.
 */
export class FakeAdmobKeyProvider implements AdmobKeyProvider {
  readonly requested: number[] = [];
  private readonly keys = new Map<number, Uint8Array>();
  /** When set, `getKey` rejects (a gstatic outage). */
  failWith: Error | undefined;

  set(keyId: number, spki: Uint8Array): this {
    this.keys.set(keyId, spki);
    return this;
  }

  getKey(keyId: number): Promise<Uint8Array | null> {
    this.requested.push(keyId);
    if (this.failWith !== undefined) {
      return Promise.reject(this.failWith);
    }
    return Promise.resolve(this.keys.get(keyId) ?? null);
  }
}
