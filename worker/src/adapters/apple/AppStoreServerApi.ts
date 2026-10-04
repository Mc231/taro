import { importPKCS8, SignJWT } from 'jose';
import type { Clock } from '../../ports/Clock';
import type {
  AppleConsumptionInfo,
  AppleNotification,
  AppleNotificationResult,
  AppleTransaction,
  AppleTransactionResult,
  AppStoreServerApi,
  StoreLookupFailure,
} from '../../ports/StoreApis';
import type { AppleJwsVerifier } from './AppleJwsVerifier';

/**
 * App Store Server API (03 §6.2, 05 §1 2.1) with an ES256 JWT built from the
 * `APPLE_ASC_*` In-App Purchase key: header `{alg: ES256, kid, typ: JWT}`,
 * claims `{iss, iat, exp, aud: "appstoreconnect-v1", bid}`.
 *
 * `GET /inApps/v1/transactions/{transactionId}` goes to production first and
 * to sandbox when production answers `4040010` (TransactionIdNotFound) or
 * `401`: that is how App Review's and TestFlight's sandbox purchases reach a
 * production Worker, and production answers `401` to every request for an
 * app that has no version live on the App Store yet (the sandbox host accepts
 * the same JWT). A sandbox `401` too means the credentials are wrong.
 * The returned `signedTransactionInfo` is verified by `AppleJwsVerifier`
 * (x5c → pinned Apple Root CA G3, OIDs, ES256).
 *
 * Never throws: missing secrets, network errors, 401/429/5xx are
 * `unavailable` with a log-safe `detail` (the client keeps the transaction
 * and retries); an unknown
 * transaction is `not_found`; a payload that fails verification is `invalid`.
 */
export interface AppStoreCredentials {
  readonly issuerId: string;
  readonly keyId: string;
  /** PKCS#8 PEM of the `.p8` In-App Purchase key. */
  readonly privateKeyPem: string;
  /** `bid` claim: the app's bundle ID. */
  readonly bundleId: string;
}

export interface AppleAppStoreServerApiOptions {
  readonly fetch: typeof fetch;
  readonly clock: Clock;
  /** Resolved on first use; throws when the secrets are not set. */
  readonly credentials: () => AppStoreCredentials;
  readonly jws: AppleJwsVerifier;
}

export const APP_STORE_PRODUCTION_URL = 'https://api.storekit.itunes.apple.com';
export const APP_STORE_SANDBOX_URL = 'https://api.storekit-sandbox.itunes.apple.com';
/** `TransactionIdNotFoundError`: retry against sandbox. */
export const TRANSACTION_ID_NOT_FOUND = 4040010;
export const APP_STORE_JWT_TTL_SEC = 20 * 60;
const AUDIENCE = 'appstoreconnect-v1';
const TRANSACTION_ID = /^\d{1,40}$/;

function unavailableBecause(detail: string): StoreLookupFailure {
  return { ok: false, reason: 'unavailable', detail };
}
type Host = 'production' | 'sandbox';
/** Production answers that send the lookup on to sandbox. */
interface TrySandbox {
  readonly trySandbox: true;
  readonly detail: string;
}
const notFound: StoreLookupFailure = { ok: false, reason: 'not_found' };
const invalid: StoreLookupFailure = { ok: false, reason: 'invalid' };

function stringOrNull(value: unknown): string | null {
  return typeof value === 'string' && value !== '' ? value : null;
}

function numberOrNull(value: unknown): number | null {
  return typeof value === 'number' && Number.isFinite(value) ? value : null;
}

/** Maps a verified JWS payload to an `AppleTransaction`; null when a required field is missing. */
export function toAppleTransaction(payload: Record<string, unknown>): AppleTransaction | null {
  const transactionId = stringOrNull(payload['transactionId']);
  const bundleId = stringOrNull(payload['bundleId']);
  const productId = stringOrNull(payload['productId']);
  const type = stringOrNull(payload['type']);
  const environment = stringOrNull(payload['environment']);
  if (
    transactionId === null ||
    bundleId === null ||
    productId === null ||
    type === null ||
    environment === null
  ) {
    return null;
  }
  const quantity = numberOrNull(payload['quantity']);
  return {
    transactionId,
    originalTransactionId: stringOrNull(payload['originalTransactionId']),
    bundleId,
    productId,
    type,
    environment,
    appAccountToken: stringOrNull(payload['appAccountToken'])?.toLowerCase() ?? null,
    purchaseDate: numberOrNull(payload['purchaseDate']),
    revocationDate: numberOrNull(payload['revocationDate']),
    quantity: quantity !== null && quantity >= 1 ? Math.floor(quantity) : 1,
  };
}

/** Maps a verified ASSN v2 payload; null when `notificationType` or `notificationUUID` is missing. */
export function toAppleNotification(payload: Record<string, unknown>): AppleNotification | null {
  const notificationType = stringOrNull(payload['notificationType']);
  const notificationUUID = stringOrNull(payload['notificationUUID']);
  if (notificationType === null || notificationUUID === null) {
    return null;
  }
  const raw = payload['data'];
  const data =
    raw !== null && typeof raw === 'object' && !Array.isArray(raw)
      ? (raw as Record<string, unknown>)
      : {};
  return {
    notificationType,
    subtype: stringOrNull(payload['subtype']),
    notificationUUID,
    bundleId: stringOrNull(data['bundleId']),
    environment: stringOrNull(data['environment']),
    signedTransactionInfo: stringOrNull(data['signedTransactionInfo']),
    consumptionRequestReason: stringOrNull(data['consumptionRequestReason']),
  };
}

async function errorCode(res: Response): Promise<number | null> {
  try {
    const body: { errorCode?: unknown } = await res.json();
    return typeof body.errorCode === 'number' ? body.errorCode : null;
  } catch {
    return null;
  }
}

async function signedTransactionInfo(res: Response): Promise<string | null> {
  try {
    const body: { signedTransactionInfo?: unknown } = await res.json();
    return typeof body.signedTransactionInfo === 'string' ? body.signedTransactionInfo : null;
  } catch {
    return null;
  }
}

export class AppleAppStoreServerApi implements AppStoreServerApi {
  constructor(private readonly options: AppleAppStoreServerApiOptions) {}

  async getTransaction(transactionId: string): Promise<AppleTransactionResult> {
    if (!TRANSACTION_ID.test(transactionId)) {
      return notFound;
    }
    let authorization: string;
    try {
      authorization = `Bearer ${await this.jwt()}`;
    } catch {
      return unavailableBecause('credentials');
    }
    const production = await this.lookup('production', transactionId, authorization);
    if (!('trySandbox' in production)) {
      return production;
    }
    const sandbox = await this.lookup('sandbox', transactionId, authorization);
    if (!('trySandbox' in sandbox)) {
      return sandbox;
    }
    return production.detail === 'missing' && sandbox.detail === 'missing'
      ? notFound
      : unavailableBecause(`production_${production.detail}+sandbox_${sandbox.detail}`);
  }

  private async lookup(
    host: Host,
    transactionId: string,
    authorization: string,
  ): Promise<AppleTransactionResult | TrySandbox> {
    const base = host === 'production' ? APP_STORE_PRODUCTION_URL : APP_STORE_SANDBOX_URL;
    let res: Response;
    try {
      res = await this.options.fetch(`${base}/inApps/v1/transactions/${transactionId}`, {
        headers: { authorization },
      });
    } catch {
      return unavailableBecause(`${host}_network`);
    }
    if (res.status === 200) {
      const signed = await signedTransactionInfo(res);
      return signed === null ? invalid : this.verifySignedTransaction(signed);
    }
    if (res.status === 404 || res.status === 400) {
      return (await errorCode(res)) === TRANSACTION_ID_NOT_FOUND
        ? { trySandbox: true, detail: 'missing' }
        : notFound;
    }
    if (res.status === 401) {
      return { trySandbox: true, detail: 'http_401' };
    }
    return unavailableBecause(`${host}_http_${String(res.status)}`);
  }

  async verifySignedTransaction(jws: string): Promise<AppleTransactionResult> {
    const payload = await this.options.jws.verify(jws);
    const transaction = payload === null ? null : toAppleTransaction(payload);
    return transaction === null ? invalid : { ok: true, transaction };
  }

  async verifyNotification(signedPayload: string): Promise<AppleNotificationResult> {
    const payload = await this.options.jws.verify(signedPayload);
    const notification = payload === null ? null : toAppleNotification(payload);
    return notification === null ? { ok: false, reason: 'invalid' } : { ok: true, notification };
  }

  async sendConsumptionInfo(
    transactionId: string,
    environment: 'production' | 'sandbox',
    info: AppleConsumptionInfo,
  ): Promise<boolean> {
    if (!TRANSACTION_ID.test(transactionId)) {
      return false;
    }
    const base = environment === 'production' ? APP_STORE_PRODUCTION_URL : APP_STORE_SANDBOX_URL;
    try {
      const res = await this.options.fetch(
        `${base}/inApps/v1/transactions/consumption/${transactionId}`,
        {
          method: 'PUT',
          headers: {
            authorization: `Bearer ${await this.jwt()}`,
            'content-type': 'application/json',
          },
          body: JSON.stringify(consumptionRequest(info)),
        },
      );
      return res.status >= 200 && res.status < 300;
    } catch {
      return false;
    }
  }

  private async jwt(): Promise<string> {
    const { issuerId, keyId, privateKeyPem, bundleId } = this.options.credentials();
    const key = await importPKCS8(privateKeyPem, 'ES256');
    const issuedAt = Math.floor(this.options.clock.now().getTime() / 1000);
    return new SignJWT({ bid: bundleId })
      .setProtectedHeader({ alg: 'ES256', kid: keyId, typ: 'JWT' })
      .setIssuer(issuerId)
      .setIssuedAt(issuedAt)
      .setExpirationTime(issuedAt + APP_STORE_JWT_TTL_SEC)
      .setAudience(AUDIENCE)
      .sign(key);
  }
}

/**
 * The `ConsumptionRequest` body. Only delivery and consumption are declared;
 * every field the Worker does not know is sent as "undeclared" (0).
 * `customerConsented` is true because the flag is switched on only once the
 * privacy policy covers it (BE Q4).
 */
export function consumptionRequest(info: AppleConsumptionInfo): Record<string, unknown> {
  return {
    customerConsented: true,
    consumptionStatus: info.consumptionStatus,
    deliveryStatus: info.deliveryStatus,
    appAccountToken: info.appAccountToken,
    platform: 1,
    sampleContentProvided: false,
    accountTenure: 0,
    playTime: 0,
    lifetimeDollarsPurchased: 0,
    lifetimeDollarsRefunded: 0,
    userStatus: 0,
    refundPreference: 0,
  };
}
