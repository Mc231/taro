import { exports } from 'cloudflare:workers';
import { describe, expect, it } from 'vitest';
import { buildApp } from '../../../src/app';
import { DEFAULT_PUBLIC_CONFIG } from '../../../src/config/defaults';
import {
  buildPublicConfigDto,
  configEtag,
  ifNoneMatchHits,
  type PublicConfigDto,
} from '../../../src/config/publicDto';
import { CONFIG_KV_KEYS, PUBLIC_CONFIG_KEYS, SERVER_CONFIG_KEYS } from '../../../src/config/schema';
import { PACK_PRODUCT_IDS, PRODUCT_CATALOG } from '../../../src/monetization/catalog';
import { CONFIG_CACHE_CONTROL } from '../../../src/routes/config';
import { bindings, createHarness } from '../../fakes/testDeps';
import { APP_HEADERS } from '../../helpers/app';

function setup() {
  const h = createHarness();
  return { h, app: buildApp(h.deps) };
}

describe('GET /v1/config (03 §8.1)', () => {
  it('returns the public document with ETag and Cache-Control', async () => {
    const { app } = setup();
    const res = await app.request('/v1/config', { headers: APP_HEADERS });

    expect(res.status).toBe(200);
    expect(res.headers.get('ETag')).toBe(`"v${String(DEFAULT_PUBLIC_CONFIG.version)}"`);
    expect(res.headers.get('Cache-Control')).toBe(CONFIG_CACHE_CONTROL);
    const body = await res.json<PublicConfigDto>();
    expect(Object.keys(body).sort()).toEqual([...PUBLIC_CONFIG_KEYS].sort());
    expect(body['readings.freeDaily']).toBe(1);
  });

  it('never sends a server-only key', async () => {
    const { app } = setup();
    const body = await (await app.request('/v1/config')).json<Record<string, unknown>>();
    for (const key of SERVER_CONFIG_KEYS.filter((k) => k !== 'version')) {
      expect(body, key).not.toHaveProperty([key]);
    }
    expect(body).not.toHaveProperty(['serverVersion']);
  });

  it('injects pack credits from PRODUCT_CATALOG (RC3)', async () => {
    const { app } = setup();
    const body = await (await app.request('/v1/config')).json<PublicConfigDto>();
    expect(body['store.packs']).toEqual([
      { productId: 'com.vshyrochuk.taro.readings_3', enabled: true, sortOrder: 0, credits: 3 },
      { productId: 'com.vshyrochuk.taro.readings_10', enabled: true, sortOrder: 1, credits: 10 },
      { productId: 'com.vshyrochuk.taro.readings_30', enabled: true, sortOrder: 2, credits: 30 },
    ]);
  });

  it.each(['"v1"', 'W/"v1"', '"v0", "v1"', '*'])(
    'answers 304 for If-None-Match: %s',
    async (tag) => {
      const { app } = setup();
      const res = await app.request('/v1/config', { headers: { 'If-None-Match': tag } });
      expect(res.status).toBe(304);
      expect(await res.text()).toBe('');
      expect(res.headers.get('ETag')).toBe('"v1"');
      expect(res.headers.get('Cache-Control')).toBe(CONFIG_CACHE_CONTROL);
    },
  );

  it('answers 200 for a stale ETag and follows a new config version', async () => {
    const { app, h } = setup();
    h.config.set({ 'readings.enabled': false });
    const res = await app.request('/v1/config', { headers: { 'If-None-Match': '"v1"' } });
    expect(res.status).toBe(200);
    expect(res.headers.get('ETag')).toBe('"v2"');
    expect((await res.json<PublicConfigDto>())['readings.enabled']).toBe(false);
  });

  it('is exempt from the 426 gate (the client learns the minimum here)', async () => {
    const { app, h } = setup();
    h.config.set({ 'app.minVersion.ios': '99.0.0' });
    expect((await app.request('/v1/config', { headers: APP_HEADERS })).status).toBe(200);
  });

  it('is served by the Worker entrypoint from CONFIG_KV', async () => {
    await bindings.CONFIG_KV.put(
      CONFIG_KV_KEYS.public,
      JSON.stringify({ ...DEFAULT_PUBLIC_CONFIG, version: 41, 'rewarded.dailyCap': 5 }),
    );
    try {
      const res = await exports.default.fetch('http://localhost/v1/config');
      expect(res.status).toBe(200);
      expect(res.headers.get('ETag')).toBe('"v41"');
      expect((await res.json<PublicConfigDto>())['rewarded.dailyCap']).toBe(5);
    } finally {
      await bindings.CONFIG_KV.delete(CONFIG_KV_KEYS.public);
    }
  });
});

describe('public config helpers', () => {
  it('agrees with the catalog for every pack product (03 §6.1)', () => {
    const dto = buildPublicConfigDto({
      ...DEFAULT_PUBLIC_CONFIG,
      'store.packs': PACK_PRODUCT_IDS.map((productId, sortOrder) => ({
        productId,
        enabled: false,
        sortOrder,
      })),
    });
    for (const pack of dto['store.packs']) {
      expect(pack.credits).toBe(PRODUCT_CATALOG[pack.productId].credits);
    }
  });

  it('formats and matches ETags', () => {
    expect(configEtag(12)).toBe('"v12"');
    expect(ifNoneMatchHits(undefined, '"v1"')).toBe(false);
    expect(ifNoneMatchHits('"v2"', '"v1"')).toBe(false);
    expect(ifNoneMatchHits('"v11"', '"v1"')).toBe(false);
  });
});
