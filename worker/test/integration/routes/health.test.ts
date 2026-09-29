import { exports } from 'cloudflare:workers';
import { describe, expect, it } from 'vitest';
import { buildApp } from '../../../src/app';
import { HealthResponseSchema } from '../../../src/routes/health';
import { WORKER_VERSION } from '../../../src/version';
import { createHarness } from '../../fakes/testDeps';

function fakeDeps() {
  const h = createHarness();
  return { ...h.deps, environment: 'staging' as const, workerVersion: '9.9.9' };
}

describe('GET /v1/health', () => {
  it('returns status, workerVersion and environment from deps', async () => {
    const res = await buildApp(fakeDeps()).request('/v1/health');

    expect(res.status).toBe(200);
    expect(res.headers.get('content-type')).toContain('application/json');
    const body = HealthResponseSchema.parse(await res.json());
    expect(body).toEqual({
      status: 'ok',
      workerVersion: '9.9.9',
      environment: 'staging',
    });
  });

  it('is served by the Worker entrypoint with the dev env bindings', async () => {
    const res = await exports.default.fetch('http://localhost/v1/health');

    expect(res.status).toBe(200);
    expect(res.headers.get('X-Request-Id')).toMatch(/^[0-9a-f-]{36}$/);
    expect(await res.json()).toEqual({
      status: 'ok',
      workerVersion: WORKER_VERSION,
      environment: 'dev',
    });
  });

  it('answers unknown routes with the 404 envelope', async () => {
    const res = await buildApp(fakeDeps()).request('/v1/nope');

    expect(res.status).toBe(404);
    expect((await res.json<{ error: { code: string } }>()).error.code).toBe('NOT_FOUND');
  });
});
