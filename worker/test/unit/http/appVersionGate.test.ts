import { describe, expect, it } from 'vitest';
import { createHarness } from '../../fakes/testDeps';
import { APP_HEADERS, errorOf, testApp } from '../../helpers/app';

function gatedApp(overrides: Parameters<ReturnType<typeof createHarness>['config']['set']>[0]) {
  const h = createHarness();
  h.config.set(overrides);
  const app = testApp(h, (a) => {
    a.get('/v1/t/gated', (c) => c.text('ok'));
    a.get('/v1/config', (c) => c.text('config'));
    a.get('/other', (c) => c.text('ungated'));
  });
  return { h, app };
}

describe('appVersionGate (426 UPGRADE_REQUIRED)', () => {
  it('lets a version at the minimum through', async () => {
    const { app } = gatedApp({ 'app.minVersion.ios': '1.2.0' });
    const res = await app.request('/v1/t/gated', { headers: APP_HEADERS });
    expect(res.status).toBe(200);
  });

  it('rejects a version below app.minVersion.{platform}', async () => {
    const { app, h } = gatedApp({ 'app.minVersion.ios': '1.3.0' });
    const res = await app.request('/v1/t/gated', { headers: APP_HEADERS });

    expect(res.status).toBe(426);
    const error = await errorOf(res);
    expect(error.code).toBe('UPGRADE_REQUIRED');
    expect(error.retryable).toBe(false);
    expect(h.logger.find('request')[0]?.fields).toMatchObject({
      status: 426,
      code: 'UPGRADE_REQUIRED',
      plat: 'ios',
      appVer: '1.2.0+14',
    });
  });

  it('uses the minimum of the request platform', async () => {
    const { app } = gatedApp({ 'app.minVersion.ios': '9.0.0', 'app.minVersion.android': '1.0.0' });
    const android = await app.request('/v1/t/gated', {
      headers: { ...APP_HEADERS, 'X-Taro-Platform': 'android' },
    });
    expect(android.status).toBe(200);
  });

  it('compares build numbers only when the minimum has one', async () => {
    const { app } = gatedApp({ 'app.minVersion.ios': '1.2.0+15' });
    expect((await app.request('/v1/t/gated', { headers: APP_HEADERS })).status).toBe(426);
  });

  it('never gates /v1/config, /v1/health or non-/v1 paths', async () => {
    const { app } = gatedApp({ 'app.minVersion.ios': '99.0.0' });
    expect((await app.request('/v1/config', { headers: APP_HEADERS })).status).toBe(200);
    expect((await app.request('/v1/health', { headers: APP_HEADERS })).status).toBe(200);
    expect((await app.request('/other', { headers: APP_HEADERS })).status).toBe(200);
  });

  it('skips requests without platform/version headers (webhooks, SSV)', async () => {
    const { app, h } = gatedApp({ 'app.minVersion.ios': '99.0.0' });
    expect((await app.request('/v1/t/gated')).status).toBe(200);
    expect(h.config.reads).toBe(0);
  });

  it('ignores an unparsable minimum instead of locking everyone out', async () => {
    const { app } = gatedApp({ 'app.minVersion.ios': 'garbage' });
    expect((await app.request('/v1/t/gated', { headers: APP_HEADERS })).status).toBe(200);
  });
});
