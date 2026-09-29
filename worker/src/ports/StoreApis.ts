/**
 * Store and ad-network ports (03 §6, §7). Shapes are the minimum the Phase 7
 * services need; the adapters and fakes (`FakeAppStoreServerApi`,
 * `FakePlayDeveloperApi`, `FakeAdmobKeyProvider`) arrive in Phase 7.
 */
export interface StoreLookupFailure {
  readonly ok: false;
  readonly reason: 'not_found' | 'unavailable';
}

/** App Store Server API (In-App Purchase key). */
export interface AppStoreServerApi {
  /** Returns the JWS `signedTransactionInfo` for a transaction ID. */
  getTransactionInfo(
    transactionId: string,
  ): Promise<{ readonly ok: true; readonly signedTransactionInfo: string } | StoreLookupFailure>;
}

/** Google Play Developer API (purchases.products, acknowledge, voided purchases). */
export interface PlayDeveloperApi {
  getProductPurchase(input: {
    readonly packageName: string;
    readonly productId: string;
    readonly purchaseToken: string;
  }): Promise<{ readonly ok: true; readonly purchase: unknown } | StoreLookupFailure>;
  acknowledge(input: {
    readonly packageName: string;
    readonly productId: string;
    readonly purchaseToken: string;
  }): Promise<boolean>;
}

/** AdMob SSV verifier keys (`keyId` → SPKI bytes), cached in `CACHE_KV`. */
export interface AdmobKeyProvider {
  getKey(keyId: number): Promise<Uint8Array | null>;
}

/** Pub/Sub push OIDC token verification for `POST /v1/webhooks/googleplay`. */
export interface GoogleOidcVerifier {
  verify(
    jwt: string,
    expected: { readonly audience: string; readonly email: string },
  ): Promise<boolean>;
}

/** Apple DeviceCheck two-bit API (03 §3.7, RC53). */
export interface DeviceCheckApi {
  queryBits(
    deviceToken: string,
  ): Promise<
    { readonly ok: true; readonly bit0: boolean; readonly bit1: boolean } | { readonly ok: false }
  >;
  updateBits(
    deviceToken: string,
    bits: { readonly bit0: boolean; readonly bit1: boolean },
  ): Promise<boolean>;
}
