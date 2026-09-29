import { describe, expect, it } from 'vitest';
import { ApiError } from '../../../src/http/errors';
import { createHarness } from '../../fakes/testDeps';
import { APP_HEADERS, testApp } from '../../helpers/app';

/** 02 §6.3: every response carries `Date` from the server clock (the client's clock offset). */
describe('Date header', () => {
  it('is set from the server Clock on success, 304, 404, 426, CORS 403 and error responses', async () => {
    const h = createHarness();
    h.clock.set('2026-03-08T07:30:05.250Z');
    const expected = 'Sun, 08 Mar 2026 07:30:05 GMT';
    const app = testApp(h, (a) => {
      a.get('/v1/test/boom', () => {
        throw new ApiError('READINGS_DISABLED');
      });
      a.get('/v1/test/crash', () => {
        throw new Error('unexpected');
      });
    });

    const health = await app.request('/v1/health');
    const config = await app.request('/v1/config');
    const notModified = await app.request('/v1/config', {
      headers: { 'If-None-Match': config.headers.get('ETag') ?? '' },
    });
    const missing = await app.request('/v1/nope', { headers: APP_HEADERS });
    const upgrade = await app.request('/v1/nope', {
      headers: { ...APP_HEADERS, 'X-Taro-App-Version': '0.0.1+1' },
    });
    const cors = await app.request('/v1/health', { headers: { Origin: 'https://evil.example' } });
    const apiError = await app.request('/v1/test/boom', { headers: APP_HEADERS });
    const crash = await app.request('/v1/test/crash', { headers: APP_HEADERS });

    const statuses = [health, config, notModified, missing, upgrade, cors, apiError, crash].map(
      (r) => r.status,
    );
    expect(statuses).toEqual([200, 200, 304, 404, 426, 403, 503, 500]);
    for (const res of [health, config, notModified, missing, upgrade, cors, apiError, crash]) {
      expect(res.headers.get('Date'), String(res.status)).toBe(expected);
    }
  });

  it('follows the clock between requests', async () => {
    const h = createHarness();
    const app = testApp(h);
    h.clock.set('2026-09-26T23:59:59.000Z');
    expect((await app.request('/v1/health')).headers.get('Date')).toBe(
      'Sat, 26 Sep 2026 23:59:59 GMT',
    );
    h.clock.advance({ seconds: 1 });
    expect((await app.request('/v1/health')).headers.get('Date')).toBe(
      'Sun, 27 Sep 2026 00:00:00 GMT',
    );
  });
});
