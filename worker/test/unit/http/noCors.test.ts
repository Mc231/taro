import { describe, expect, it } from 'vitest';
import { createHarness } from '../../fakes/testDeps';
import { testApp } from '../../helpers/app';

describe('noCors (03 §2.1: no CORS, browser Origin → 403)', () => {
  it('rejects a request carrying Origin with an empty 403 and no CORS headers', async () => {
    const h = createHarness();
    const res = await testApp(h).request('/v1/health', {
      headers: { Origin: 'https://evil.example' },
    });

    expect(res.status).toBe(403);
    expect(await res.text()).toBe('');
    expect(res.headers.get('Access-Control-Allow-Origin')).toBeNull();
    expect(res.headers.get('X-Request-Id')).not.toBeNull();
    expect(h.logger.find('request')[0]?.fields).toMatchObject({ status: 403 });
  });

  it('rejects a CORS preflight', async () => {
    const h = createHarness();
    const res = await testApp(h).request('/v1/balance', {
      method: 'OPTIONS',
      headers: { Origin: 'https://evil.example', 'Access-Control-Request-Method': 'GET' },
    });

    expect(res.status).toBe(403);
    expect(res.headers.get('Access-Control-Allow-Methods')).toBeNull();
  });

  it('passes requests without Origin (app, webhooks, SSV)', async () => {
    const h = createHarness();
    expect((await testApp(h).request('/v1/health')).status).toBe(200);
  });
});
