/**
 * Store and ad-network ports (03 §6, §7). The production adapters live in
 * `adapters/apple/` and `adapters/google/`; tests use `FakeAppStoreServerApi`
 * and `FakePlayDeveloperApi` (03 §15.3), or the real adapters over a stubbed
 * `fetch` with keys and CAs generated in the test (06 §7).
 */
export interface StoreLookupFailure {
  readonly ok: false;
  /**
   * `not_found`: the store does not know the transaction/token; `invalid`: the
   * answer failed verification (JWS signature, chain, OIDs); `unavailable`:
   * network, auth or a 5xx (the client retries).
   */
  readonly reason: 'not_found' | 'invalid' | 'unavailable';
}

/** The verified `JWSTransactionDecodedPayload` fields the Worker uses (03 §6.2). */
export interface AppleTransaction {
  readonly transactionId: string;
  readonly originalTransactionId: string | null;
  readonly bundleId: string;
  readonly productId: string;
  /** `Consumable`, `Non-Consumable`, `Auto-Renewable Subscription`, … */
  readonly type: string;
  /** `Production`, `Sandbox`, `Xcode` or `LocalTesting`. */
  readonly environment: string;
  /** StoreKit `appAccountToken` (lower-case UUID), when the client set one. */
  readonly appAccountToken: string | null;
  readonly purchaseDate: number | null;
  readonly revocationDate: number | null;
  readonly quantity: number;
}

export type AppleTransactionResult =
  { readonly ok: true; readonly transaction: AppleTransaction } | StoreLookupFailure;

/**
 * The verified ASSN v2 `responseBodyV2DecodedPayload` fields the Worker uses
 * (03 §6.4). `signedTransactionInfo` is still a JWS: the caller verifies it
 * with `verifySignedTransaction` (the inner JWS).
 */
export interface AppleNotification {
  readonly notificationType: string;
  readonly subtype: string | null;
  readonly notificationUUID: string;
  /** `data.bundleId`; null for notifications without `data` (e.g. `summary`). */
  readonly bundleId: string | null;
  /** `data.environment`: `Production` or `Sandbox`. */
  readonly environment: string | null;
  readonly signedTransactionInfo: string | null;
  /** `data.consumptionRequestReason` of a `CONSUMPTION_REQUEST`. */
  readonly consumptionRequestReason: string | null;
}

export type AppleNotificationResult =
  | { readonly ok: true; readonly notification: AppleNotification }
  | { readonly ok: false; readonly reason: 'invalid' };

/**
 * `ConsumptionRequest` body of `PUT /inApps/v1/transactions/consumption/{id}`
 * (03 §6.4, BE Q4): only what the Worker knows (delivery and consumption).
 */
export interface AppleConsumptionInfo {
  /** 0 undeclared, 1 not consumed, 2 partially consumed, 3 fully consumed. */
  readonly consumptionStatus: 0 | 1 | 2 | 3;
  /** 0 delivered and working properly. */
  readonly deliveryStatus: 0;
  readonly appAccountToken: string;
}

/** App Store Server API (In-App Purchase key) and local JWS verification. */
export interface AppStoreServerApi {
  /**
   * `GET /inApps/v1/transactions/{transactionId}` (production, then sandbox on
   * `4040010`), with the returned `signedTransactionInfo` verified against the
   * pinned Apple Root CA G3.
   */
  getTransaction(transactionId: string): Promise<AppleTransactionResult>;
  /** Verifies a client-supplied `signedTransaction` JWS locally (same chain rules). */
  verifySignedTransaction(jws: string): Promise<AppleTransactionResult>;
  /** Verifies an ASSN v2 `signedPayload` (same chain rules) and decodes its fields. */
  verifyNotification(signedPayload: string): Promise<AppleNotificationResult>;
  /**
   * `PUT /inApps/v1/transactions/consumption/{transactionId}` against the
   * notification's environment; false on any failure (never throws).
   */
  sendConsumptionInfo(
    transactionId: string,
    environment: 'production' | 'sandbox',
    info: AppleConsumptionInfo,
  ): Promise<boolean>;
}

/** Identifies one Play in-app product purchase. */
export interface PlayPurchaseRef {
  readonly packageName: string;
  readonly productId: string;
  readonly purchaseToken: string;
}

/** `purchases.products` resource fields the Worker uses (03 §6.3). */
export interface PlayProductPurchase {
  /** 0 purchased, 1 cancelled, 2 pending. */
  readonly purchaseState: number;
  /** 0 not yet consumed, 1 consumed. */
  readonly consumptionState: number;
  /** 0 not yet acknowledged, 1 acknowledged. */
  readonly acknowledgementState: number;
  readonly orderId: string | null;
  readonly purchaseTimeMillis: number | null;
  /** 0 test (license tester), 1 promo, 2 rewarded; null for a real purchase. */
  readonly purchaseType: number | null;
  readonly obfuscatedExternalAccountId: string | null;
  readonly quantity: number;
}

/** One `purchases.voidedpurchases` entry (03 §6.4 backstop). */
export interface PlayVoidedPurchase {
  readonly purchaseToken: string;
  readonly orderId: string | null;
  readonly voidedTimeMillis: number | null;
  readonly voidedSource: number | null;
  readonly voidedReason: number | null;
}

/** Google Play Developer API (purchases.products, acknowledge, voided purchases). */
export interface PlayDeveloperApi {
  getProductPurchase(
    ref: PlayPurchaseRef,
  ): Promise<{ readonly ok: true; readonly purchase: PlayProductPurchase } | StoreLookupFailure>;
  /** `…/tokens/{token}:acknowledge`; false on any failure (the caller records `pendingAck`). */
  acknowledge(ref: PlayPurchaseRef): Promise<boolean>;
  /** One page of `purchases.voidedpurchases.list` (`type=0`, in-app products). */
  listVoidedPurchases(input: {
    readonly packageName: string;
    readonly startTimeMillis: number;
    readonly endTimeMillis?: number;
    readonly pageToken?: string;
  }): Promise<
    | {
        readonly ok: true;
        readonly purchases: readonly PlayVoidedPurchase[];
        readonly nextPageToken: string | null;
      }
    | StoreLookupFailure
  >;
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
