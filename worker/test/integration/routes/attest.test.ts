import { describe, expect, it } from 'vitest';
import { CHALLENGE_LENGTH } from '../../../src/domain/challenge';
import { createHarness } from '../../fakes/testDeps';
import { APP_HEADERS, errorOf, testApp } from '../../helpers/app';

describe('POST /v1/attest/challenge (03 §3.2)', () => {
  it('returns a 5-minute challenge and the configured powBits', async () => {
    const h = createHarness();
    h.config.set({ 'abuse.lowTrust.powBits': 12 });
    const res = await testApp(h).request('/v1/attest/challenge', {
      method: 'POST',
      headers: APP_HEADERS,
    });
    expect(res.status).toBe(200);
    const body = await res.json<{ challenge: string; expiresAt: string; powBits: number }>();
    expect(body.challenge).toHaveLength(CHALLENGE_LENGTH);
    expect(body.expiresAt).toBe('2026-09-26T10:05:00.000Z');
    expect(body.powBits).toBe(12);
  });

  it('is rate-limited per IP prefix (RL_BURST ip:{hash})', async () => {
    const h = createHarness();
    h.burst.limitPerKey = 1;
    const app = testApp(h);
    const headers = { ...APP_HEADERS, 'CF-Connecting-IP': '203.0.113.7' };
    expect((await app.request('/v1/attest/challenge', { method: 'POST', headers })).status).toBe(
      200,
    );
    const res = await app.request('/v1/attest/challenge', {
      method: 'POST',
      headers: { ...headers, 'CF-Connecting-IP': '203.0.113.99' },
    });
    expect(res.status).toBe(429);
    expect(await errorOf(res)).toMatchObject({
      code: 'RATE_LIMITED',
      details: { reason: 'burst' },
    });
    expect(h.burst.keys[0]).toMatch(/^ip:/);
  });

  it('requires the X-Taro-* client headers', async () => {
    const res = await testApp(createHarness()).request('/v1/attest/challenge', { method: 'POST' });
    expect(res.status).toBe(400);
    expect((await errorOf(res)).code).toBe('VALIDATION_FAILED');
  });

  it('fails with 500 INTERNAL when CHALLENGE_KEY is missing', async () => {
    const h = createHarness();
    const app = testApp(h, undefined);
    const broken = testApp(
      createHarness({
        overrides: {
          keys: {
            ...h.deps.keys,
            challenge: () => {
              throw new Error('CHALLENGE_KEY is not set');
            },
          },
        },
      }),
    );
    expect(
      (await app.request('/v1/attest/challenge', { method: 'POST', headers: APP_HEADERS })).status,
    ).toBe(200);
    const res = await broken.request('/v1/attest/challenge', {
      method: 'POST',
      headers: APP_HEADERS,
    });
    expect(res.status).toBe(500);
  });
});
