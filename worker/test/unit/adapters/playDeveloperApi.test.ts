import { describe, expect, it } from 'vitest';
import {
  ANDROID_PUBLISHER_BASE_URL,
  GooglePlayDeveloperApi,
  toProductPurchase,
} from '../../../src/adapters/google/PlayDeveloperApi';
import { json, networkError, StubFetch } from '../../helpers/stubFetch';

/** Play Developer API adapter (03 §6.3, §6.4): stubbed fetch, no network (06 §7). */
const REF = {
  packageName: 'com.vshyrochuk.taro',
  productId: 'com.vshyrochuk.taro.readings_10',
  purchaseToken: 'tok/en+1',
};
const TOKEN_URL = `${ANDROID_PUBLISHER_BASE_URL}/com.vshyrochuk.taro/purchases/products/com.vshyrochuk.taro.readings_10/tokens/tok%2Fen%2B1`;

function api(stub: StubFetch, token: () => Promise<string> = () => Promise.resolve('oauth-1')) {
  return new GooglePlayDeveloperApi({ fetch: stub.fetch, accessToken: token });
}

describe('GooglePlayDeveloperApi.getProductPurchase', () => {
  it('GETs the product purchase with the OAuth token and maps the resource', async () => {
    const stub = new StubFetch().reply(
      json({
        kind: 'androidpublisher#productPurchase',
        purchaseTimeMillis: '1790409540000',
        purchaseState: 0,
        consumptionState: 0,
        acknowledgementState: 1,
        orderId: 'GPA.1234-5678-9012-34567',
        purchaseType: 0,
        obfuscatedExternalAccountId: 'acct',
        quantity: 2,
        regionCode: 'DE',
      }),
    );
    expect(await api(stub).getProductPurchase(REF)).toEqual({
      ok: true,
      purchase: {
        purchaseState: 0,
        consumptionState: 0,
        acknowledgementState: 1,
        orderId: 'GPA.1234-5678-9012-34567',
        purchaseTimeMillis: 1_790_409_540_000,
        purchaseType: 0,
        obfuscatedExternalAccountId: 'acct',
        quantity: 2,
      },
    });
    expect(stub.requests[0]?.url).toBe(TOKEN_URL);
    expect(stub.requests[0]?.method).toBe('GET');
    expect(stub.requests[0]?.headers.get('authorization')).toBe('Bearer oauth-1');
  });

  it('maps 400/404/410 to not_found and outages to unavailable', async () => {
    for (const status of [400, 404, 410]) {
      const stub = new StubFetch().reply(json({ error: {} }, status));
      expect(await api(stub).getProductPurchase(REF)).toEqual({ ok: false, reason: 'not_found' });
    }
    for (const reply of [json({}, 401), json({}, 503), new Response('[]', { status: 200 })]) {
      const stub = new StubFetch().reply(reply);
      expect(await api(stub).getProductPurchase(REF)).toEqual({
        ok: false,
        reason: 'unavailable',
      });
    }
    const offline = new StubFetch().reply(networkError);
    expect(await api(offline).getProductPurchase(REF)).toEqual({
      ok: false,
      reason: 'unavailable',
    });
    const noToken = new StubFetch();
    expect(
      await api(noToken, () => Promise.reject(new Error('no service account'))).getProductPurchase(
        REF,
      ),
    ).toEqual({ ok: false, reason: 'unavailable' });
    expect(noToken.requests).toHaveLength(0);
  });
});

describe('toProductPurchase', () => {
  it('defaults missing states and quantity', () => {
    expect(toProductPurchase({})).toEqual({
      purchaseState: -1,
      consumptionState: 0,
      acknowledgementState: 0,
      orderId: null,
      purchaseTimeMillis: null,
      purchaseType: null,
      obfuscatedExternalAccountId: null,
      quantity: 1,
    });
    expect(toProductPurchase({ purchaseState: 'x', quantity: 0, orderId: '' })).toMatchObject({
      purchaseState: -1,
      quantity: 1,
      orderId: null,
    });
  });
});

describe('GooglePlayDeveloperApi.acknowledge', () => {
  it('POSTs :acknowledge and reports success', async () => {
    const stub = new StubFetch().reply(new Response(null, { status: 204 }));
    expect(await api(stub).acknowledge(REF)).toBe(true);
    expect(stub.requests[0]?.url).toBe(`${TOKEN_URL}:acknowledge`);
    expect(stub.requests[0]?.method).toBe('POST');
    expect(stub.requests[0]?.headers.get('content-type')).toBe('application/json');
    expect(stub.requests[0]?.body).toBe('{}');
  });

  it('reports failure on an error status, a network error or no token', async () => {
    expect(await api(new StubFetch().reply(json({}, 400))).acknowledge(REF)).toBe(false);
    expect(await api(new StubFetch().reply(json({}, 200))).acknowledge(REF)).toBe(true);
    expect(await api(new StubFetch().reply(networkError)).acknowledge(REF)).toBe(false);
    expect(await api(new StubFetch(), () => Promise.reject(new Error('x'))).acknowledge(REF)).toBe(
      false,
    );
  });
});

describe('GooglePlayDeveloperApi.listVoidedPurchases', () => {
  it('lists in-app voided purchases with paging parameters', async () => {
    const stub = new StubFetch().reply(
      json({
        tokenPagination: { nextPageToken: 'page-2' },
        voidedPurchases: [
          {
            kind: 'androidpublisher#voidedPurchase',
            purchaseToken: 'tok-a',
            voidedTimeMillis: '1790409540000',
            orderId: 'GPA.1',
            voidedSource: 1,
            voidedReason: 7,
          },
          { orderId: 'no-token' },
          'junk',
          null,
        ],
      }),
    );
    const result = await api(stub).listVoidedPurchases({
      packageName: 'com.vshyrochuk.taro',
      startTimeMillis: 1000,
      endTimeMillis: 2000,
      pageToken: 'page-1',
    });
    expect(result).toEqual({
      ok: true,
      purchases: [
        {
          purchaseToken: 'tok-a',
          orderId: 'GPA.1',
          voidedTimeMillis: 1_790_409_540_000,
          voidedSource: 1,
          voidedReason: 7,
        },
      ],
      nextPageToken: 'page-2',
    });
    const url = new URL(String(stub.requests[0]?.url));
    expect(`${url.origin}${url.pathname}`).toBe(
      `${ANDROID_PUBLISHER_BASE_URL}/com.vshyrochuk.taro/purchases/voidedpurchases`,
    );
    expect(Object.fromEntries(url.searchParams)).toEqual({
      type: '0',
      startTime: '1000',
      endTime: '2000',
      token: 'page-1',
    });
  });

  it('returns an empty last page and maps errors', async () => {
    const empty = new StubFetch().reply(json({}));
    expect(await api(empty).listVoidedPurchases({ packageName: 'p', startTimeMillis: 1 })).toEqual({
      ok: true,
      purchases: [],
      nextPageToken: null,
    });
    expect(Object.fromEntries(new URL(String(empty.requests[0]?.url)).searchParams)).toEqual({
      type: '0',
      startTime: '1',
    });
    const missing = new StubFetch().reply(json({}, 404));
    expect(
      await api(missing).listVoidedPurchases({ packageName: 'p', startTimeMillis: 1 }),
    ).toEqual({ ok: false, reason: 'not_found' });
    for (const reply of [json({}, 500), new Response('x', { status: 200 })]) {
      expect(
        await api(new StubFetch().reply(reply)).listVoidedPurchases({
          packageName: 'p',
          startTimeMillis: 1,
        }),
      ).toEqual({ ok: false, reason: 'unavailable' });
    }
    expect(
      await api(new StubFetch().reply(networkError)).listVoidedPurchases({
        packageName: 'p',
        startTimeMillis: 1,
      }),
    ).toEqual({ ok: false, reason: 'unavailable' });
  });
});
