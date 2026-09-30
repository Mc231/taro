import { describe, expect, it } from 'vitest';
import { createHarness } from '../../fakes/testDeps';
import { APP_HEADERS, testApp, testAuth } from '../../helpers/app';

const INSTALL_ID = '3f1c2b1e-9a8b-4c7d-8e6f-5a4b3c2d1e0f';

describe('logging middleware (03 §14.1)', () => {
  it('writes one line with the 03 §14.1 fields and inst8 only', async () => {
    const h = createHarness();
    const app = testApp(h, (a) => {
      a.use('/t/*', testAuth);
      a.get('/t/items/:id', (c) => {
        h.clock.advance({ ms: 42 });
        return c.text('ok');
      });
    });
    const res = await app.request('/t/items/secret-path-param', {
      headers: { ...APP_HEADERS, 'X-Test-Install': INSTALL_ID },
    });
    expect(res.status).toBe(200);

    const lines = h.logger.find('request');
    expect(lines).toHaveLength(1);
    expect(lines[0]).toEqual({
      level: 'info',
      event: 'request',
      fields: {
        requestId: res.headers.get('X-Request-Id'),
        route: 'GET /t/items/:id',
        status: 200,
        latencyMs: 42,
        inst8: '3f1c2b1e',
        plat: 'ios',
        appVer: '1.2.0+14',
        code: undefined,
      },
    });
    h.logger.expectNoSensitive(INSTALL_ID, 'secret-path-param');
    // One `http_response` point per response for the AlertService 5xx rate.
    expect(h.metrics.responses).toEqual([{ event: 'http_response', code: '200', latencyMs: 42 }]);
    expect(h.metrics.points).toEqual([]);
  });

  it('logs 5xx at error level with the error code', async () => {
    const h = createHarness();
    const app = testApp(h, (a) =>
      a.get('/t/fail', () => {
        throw new Error('db down');
      }),
    );
    await app.request('/t/fail');

    expect(h.logger.find('request')[0]).toMatchObject({
      level: 'error',
      fields: { status: 500, code: 'INTERNAL', inst8: undefined, plat: undefined },
    });
  });

  it('logs requests that never reach clientHeaders (CORS 403)', async () => {
    const h = createHarness();
    await testApp(h).request('/v1/health', { headers: { Origin: 'https://x.example' } });

    expect(h.logger.find('request')[0]?.fields).toMatchObject({ status: 403, plat: undefined });
  });
});
