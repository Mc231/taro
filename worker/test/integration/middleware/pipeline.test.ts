import { exports } from 'cloudflare:workers';
import { describe, expect, it } from 'vitest';
import { ApiError } from '../../../src/http/errors';
import { idempotency } from '../../../src/http/middleware/idempotency';
import { rateLimit } from '../../../src/http/middleware/rateLimit';
import { createHarness, uniqueId } from '../../fakes/testDeps';
import { APP_HEADERS, errorOf, testApp } from '../../helpers/app';

const INSTALL_SECRET = 'q8Zr3Xv1Wm7Kp2Ls9Nd4Tb6Hc0Yf5Jg1Ae8Ui3Oo7P'; // gitleaks:allow (test-only value)
const FAKE_TOKEN = 'eyJhbGciOiJFZERTQSIsImtpZCI6ImsxIn0.eyJzdWIiOiJ4In0.c2lnbmF0dXJl'; // gitleaks:allow (fake JWT)
const QUESTION = 'Will my sister forgive me for what I said at the wedding?';

/** A registration-shaped route through the full global stack plus [idem] and a burst limit. */
function registrationApp() {
  const h = createHarness();
  const app = testApp(h, (a) => {
    a.post(
      '/v1/t/installs',
      rateLimit(h.deps, 'ipPrefix'),
      idempotency(h.deps, {
        route: 'POST /v1/installs',
        scope: async (c) => (await c.req.json<{ installId: string }>()).installId,
      }),
      async (c) => {
        const body = await c.req.json<{
          installId: string;
          installSecret: string;
          question?: string;
        }>();
        c.set('installId', body.installId);
        if (body.question !== undefined) {
          throw new ApiError('SPREAD_INVALID', { details: { reason: 'disabled' } });
        }
        return c.json({ installToken: FAKE_TOKEN, trust: 'high' }, 201);
      },
    );
  });
  return { h, app };
}

function register(
  app: ReturnType<typeof registrationApp>['app'],
  body: Record<string, unknown>,
  key: string,
  extraHeaders: Record<string, string> = {},
) {
  return app.request('/v1/t/installs', {
    method: 'POST',
    headers: {
      ...APP_HEADERS,
      'content-type': 'application/json',
      'Idempotency-Key': key,
      'CF-Connecting-IP': '203.0.113.50',
      Authorization: `Bearer ${FAKE_TOKEN}`,
      ...extraHeaders,
    },
    body: JSON.stringify(body),
  });
}

describe('middleware pipeline', () => {
  it('never logs the install secret, full install ID, token, question or IP (BE13)', async () => {
    const { h, app } = registrationApp();
    const installId = uniqueId('i');
    const key = uniqueId('k');
    const body = { installId, installSecret: INSTALL_SECRET, attestation: { type: 'none' } };

    const created = await register(app, body, key);
    expect(created.status).toBe(201);
    const replay = await register(app, body, key);
    expect(replay.headers.get('Idempotent-Replayed')).toBe('true');
    const rejected = await register(app, { ...body, question: QUESTION }, uniqueId('k'));
    expect(rejected.status).toBe(422);
    const reused = await register(app, { ...body, installSecret: 'x' }, key);
    expect(reused.status).toBe(422);
    const failing = await register(app, body, uniqueId('k'), { Origin: 'https://evil.example' });
    expect(failing.status).toBe(403);

    expect(h.logger.find('request')).toHaveLength(5);
    expect(h.logger.find('request')[0]?.fields).toMatchObject({
      route: 'POST /v1/t/installs',
      status: 201,
      inst8: installId.slice(0, 8),
    });
    h.logger.expectNoSensitive(
      INSTALL_SECRET,
      installId,
      FAKE_TOKEN,
      QUESTION,
      '203.0.113.50',
      key,
    );
  });

  it('serves 426 before any route work through the Worker entrypoint', async () => {
    const res = await exports.default.fetch('http://localhost/v1/balance', {
      headers: { ...APP_HEADERS, 'X-Taro-App-Version': '0.9.0+1' },
    });

    expect(res.status).toBe(426);
    expect((await errorOf(res)).code).toBe('UPGRADE_REQUIRED');
    expect(res.headers.get('X-Request-Id')).not.toBeNull();
  });

  it('serves the CORS 403 through the Worker entrypoint', async () => {
    const res = await exports.default.fetch('http://localhost/v1/health', {
      headers: { Origin: 'https://evil.example' },
    });

    expect(res.status).toBe(403);
    expect(res.headers.get('Access-Control-Allow-Origin')).toBeNull();
  });

  it('adds X-Request-Id to replayed responses', async () => {
    const { app } = registrationApp();
    const body = { installId: uniqueId('i'), installSecret: INSTALL_SECRET };
    const key = uniqueId('k');
    await register(app, body, key);
    const replay = await register(app, body, key, { 'X-Request-Id': 'replay-request-01' });

    expect(replay.headers.get('X-Request-Id')).toBe('replay-request-01');
  });
});
