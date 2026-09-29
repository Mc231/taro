import type {
  PlayDeveloperApi,
  PlayProductPurchase,
  PlayPurchaseRef,
  PlayVoidedPurchase,
  StoreLookupFailure,
} from '../../ports/StoreApis';

/**
 * Google Play Developer API v3 (03 §6.3, §6.4; BE8, RC10) with the service
 * account's OAuth token (scope `androidpublisher`, cached in `CACHE_KV` for
 * 50 min by `GoogleAccessTokenProvider`):
 *
 * - `purchases.products.get`:
 *   `GET …/applications/{pkg}/purchases/products/{productId}/tokens/{token}`;
 * - `purchases.products.acknowledge`: `POST …/tokens/{token}:acknowledge`;
 * - `purchases.voidedpurchases.list`:
 *   `GET …/applications/{pkg}/purchases/voidedpurchases?type=0&startTime=…`.
 *
 * Never throws: no token, network errors, 401/403/429/5xx are `unavailable`;
 * 400/404/410 (an unknown or malformed token) are `not_found`.
 */
export interface GooglePlayDeveloperOptions {
  readonly fetch: typeof fetch;
  readonly accessToken: () => Promise<string>;
}

export const ANDROID_PUBLISHER_BASE_URL =
  'https://androidpublisher.googleapis.com/androidpublisher/v3/applications';
export const ANDROID_PUBLISHER_SCOPE = 'https://www.googleapis.com/auth/androidpublisher';

const unavailable: StoreLookupFailure = { ok: false, reason: 'unavailable' };
const notFound: StoreLookupFailure = { ok: false, reason: 'not_found' };

function intOrNull(value: unknown): number | null {
  if (typeof value === 'number' && Number.isFinite(value)) {
    return value;
  }
  if (typeof value === 'string' && /^-?\d+$/.test(value)) {
    return Number(value);
  }
  return null;
}

function stringOrNull(value: unknown): string | null {
  return typeof value === 'string' && value !== '' ? value : null;
}

/** Maps a `ProductPurchase` resource; unknown or missing states stay out of range (-1). */
export function toProductPurchase(body: Record<string, unknown>): PlayProductPurchase {
  const quantity = intOrNull(body['quantity']);
  return {
    purchaseState: intOrNull(body['purchaseState']) ?? -1,
    consumptionState: intOrNull(body['consumptionState']) ?? 0,
    acknowledgementState: intOrNull(body['acknowledgementState']) ?? 0,
    orderId: stringOrNull(body['orderId']),
    purchaseTimeMillis: intOrNull(body['purchaseTimeMillis']),
    purchaseType: intOrNull(body['purchaseType']),
    obfuscatedExternalAccountId: stringOrNull(body['obfuscatedExternalAccountId']),
    quantity: quantity !== null && quantity >= 1 ? quantity : 1,
  };
}

function toVoided(entry: Record<string, unknown>): PlayVoidedPurchase | null {
  const purchaseToken = stringOrNull(entry['purchaseToken']);
  return purchaseToken === null
    ? null
    : {
        purchaseToken,
        orderId: stringOrNull(entry['orderId']),
        voidedTimeMillis: intOrNull(entry['voidedTimeMillis']),
        voidedSource: intOrNull(entry['voidedSource']),
        voidedReason: intOrNull(entry['voidedReason']),
      };
}

function productTokenUrl(ref: PlayPurchaseRef): string {
  return [
    ANDROID_PUBLISHER_BASE_URL,
    encodeURIComponent(ref.packageName),
    'purchases/products',
    encodeURIComponent(ref.productId),
    'tokens',
    encodeURIComponent(ref.purchaseToken),
  ].join('/');
}

async function jsonObject(res: Response): Promise<Record<string, unknown> | null> {
  try {
    const body: unknown = await res.json();
    return body !== null && typeof body === 'object' && !Array.isArray(body)
      ? (body as Record<string, unknown>)
      : null;
  } catch {
    return null;
  }
}

export class GooglePlayDeveloperApi implements PlayDeveloperApi {
  constructor(private readonly options: GooglePlayDeveloperOptions) {}

  async getProductPurchase(
    ref: PlayPurchaseRef,
  ): Promise<{ readonly ok: true; readonly purchase: PlayProductPurchase } | StoreLookupFailure> {
    const res = await this.call(productTokenUrl(ref), 'GET');
    if (res === null) {
      return unavailable;
    }
    if (res.status === 200) {
      const body = await jsonObject(res);
      return body === null ? unavailable : { ok: true, purchase: toProductPurchase(body) };
    }
    return isNotFound(res.status) ? notFound : unavailable;
  }

  async acknowledge(ref: PlayPurchaseRef): Promise<boolean> {
    const res = await this.call(`${productTokenUrl(ref)}:acknowledge`, 'POST', '{}');
    return res !== null && res.status >= 200 && res.status < 300;
  }

  async listVoidedPurchases(input: {
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
  > {
    const query = new URLSearchParams({ type: '0', startTime: String(input.startTimeMillis) });
    if (input.endTimeMillis !== undefined) {
      query.set('endTime', String(input.endTimeMillis));
    }
    if (input.pageToken !== undefined) {
      query.set('token', input.pageToken);
    }
    const url = `${ANDROID_PUBLISHER_BASE_URL}/${encodeURIComponent(input.packageName)}/purchases/voidedpurchases?${query.toString()}`;
    const res = await this.call(url, 'GET');
    const body = res?.status === 200 ? await jsonObject(res) : null;
    if (body === null) {
      return res !== null && isNotFound(res.status) ? notFound : unavailable;
    }
    const entries = Array.isArray(body['voidedPurchases'])
      ? (body['voidedPurchases'] as unknown[])
      : [];
    const pagination = body['tokenPagination'] as { nextPageToken?: unknown } | undefined;
    return {
      ok: true,
      purchases: entries
        .filter((e): e is Record<string, unknown> => e !== null && typeof e === 'object')
        .map(toVoided)
        .filter((e): e is PlayVoidedPurchase => e !== null),
      nextPageToken: stringOrNull(pagination?.nextPageToken),
    };
  }

  /** One authorised request; null when no token could be obtained or the network failed. */
  private async call(url: string, method: 'GET' | 'POST', body?: string): Promise<Response | null> {
    try {
      const token = await this.options.accessToken();
      return await this.options.fetch(url, {
        method,
        headers: {
          authorization: `Bearer ${token}`,
          ...(body === undefined ? {} : { 'content-type': 'application/json' }),
        },
        ...(body === undefined ? {} : { body }),
      });
    } catch {
      return null;
    }
  }
}

function isNotFound(status: number): boolean {
  return status === 400 || status === 404 || status === 410;
}
