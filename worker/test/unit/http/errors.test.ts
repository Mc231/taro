import { createRoute, z } from '@hono/zod-openapi';
import { HTTPException } from 'hono/http-exception';
import { describe, expect, it } from 'vitest';
import {
  ApiError,
  ERROR_CODES,
  ERROR_TABLE,
  ErrorEnvelopeSchema,
  type ErrorCode,
} from '../../../src/http/errors';
import { errorOf, testApp } from '../../helpers/app';
import { createHarness } from '../../fakes/testDeps';

describe('error code table (03 §2.2, RC5)', () => {
  it('lists every code exactly once and gives each a spec', () => {
    expect(new Set(ERROR_CODES).size).toBe(ERROR_CODES.length);
    expect(Object.keys(ERROR_TABLE).sort()).toEqual([...ERROR_CODES].sort());
  });

  it.each<[ErrorCode, number, boolean]>([
    ['VALIDATION_FAILED', 400, false],
    ['IDEMPOTENCY_KEY_REQUIRED', 400, false],
    ['UNAUTHENTICATED', 401, false],
    ['TOKEN_EXPIRED', 401, false],
    ['ATTESTATION_REQUIRED', 401, false],
    ['INSUFFICIENT_CREDITS', 402, false],
    ['ATTESTATION_FAILED', 403, false],
    ['REWARDED_DISABLED', 403, false],
    ['AI_UNAVAILABLE_REGION', 403, false],
    ['NOT_FOUND', 404, false],
    ['REQUEST_IN_PROGRESS', 409, true],
    ['HOLD_CONFLICT', 409, false],
    ['PURCHASE_ALREADY_CLAIMED', 409, false],
    ['REWARDED_DAILY_CAP', 409, false],
    ['TIMEZONE_CHANGE_TOO_SOON', 409, false],
    ['READING_EXPIRED_REFUNDED', 410, false],
    ['AI_CONSENT_REQUIRED', 412, false],
    ['IDEMPOTENCY_KEY_REUSED', 422, false],
    ['PURCHASE_INVALID', 422, false],
    ['PRODUCT_UNKNOWN', 422, false],
    ['SPREAD_INVALID', 422, false],
    ['UPGRADE_REQUIRED', 426, false],
    ['RATE_LIMITED', 429, true],
    ['INTERNAL', 500, true],
    ['AI_UNAVAILABLE', 503, true],
    ['AI_BUDGET_EXHAUSTED', 503, true],
    ['READINGS_DISABLED', 503, true],
  ])('%s → %i, retryable %s', (code, status, retryable) => {
    expect(ERROR_TABLE[code].status).toBe(status);
    expect(ERROR_TABLE[code].retryable).toBe(retryable);
    expect(ERROR_TABLE[code].message.length).toBeGreaterThan(0);
  });
});

describe('error envelope', () => {
  function appThrowing(error: unknown) {
    const h = createHarness();
    const app = testApp(h, (a) => {
      a.get('/t/throw', () => {
        throw error;
      });
    });
    return { h, app };
  }

  it('renders an ApiError with details and Retry-After', async () => {
    const { app } = appThrowing(
      new ApiError('RATE_LIMITED', { details: { reason: 'burst' }, retryAfterSec: 60 }),
    );
    const res = await app.request('/t/throw', { headers: { 'X-Request-Id': 'req-abcdef12' } });

    expect(res.status).toBe(429);
    expect(res.headers.get('Retry-After')).toBe('60');
    expect(res.headers.get('X-Request-Id')).toBe('req-abcdef12');
    const body = ErrorEnvelopeSchema.parse(await res.json());
    expect(body).toEqual({
      error: {
        code: 'RATE_LIMITED',
        message: 'Too many requests.',
        requestId: 'req-abcdef12',
        retryable: true,
        retryAfterSec: 60,
        details: { reason: 'burst' },
      },
    });
  });

  it('omits details and sends retryAfterSec null by default', async () => {
    const { app } = appThrowing(new ApiError('AI_CONSENT_REQUIRED'));
    const res = await app.request('/t/throw');

    expect(res.status).toBe(412);
    expect(res.headers.get('Retry-After')).toBeNull();
    const error = await errorOf(res);
    expect(error.retryAfterSec).toBeNull();
    expect(error).not.toHaveProperty('details');
    expect(error.requestId).toBe(res.headers.get('X-Request-Id'));
  });

  it('maps the RC5 additions', async () => {
    const region = await appThrowing(new ApiError('AI_UNAVAILABLE_REGION')).app.request('/t/throw');
    expect(region.status).toBe(403);
    expect((await errorOf(region)).code).toBe('AI_UNAVAILABLE_REGION');
  });

  it.each([
    [400, 'VALIDATION_FAILED'],
    [401, 'UNAUTHENTICATED'],
    [404, 'NOT_FOUND'],
    [418, 'INTERNAL'],
  ] as const)('maps HTTPException %i to %s', async (status, code) => {
    const res = await appThrowing(new HTTPException(status)).app.request('/t/throw');
    expect((await errorOf(res)).code).toBe(code);
  });

  it('turns an unexpected error into 500 INTERNAL and logs only its name and message', async () => {
    const { app, h } = appThrowing(new TypeError('boom'));
    const res = await app.request('/t/throw');

    expect(res.status).toBe(500);
    expect((await errorOf(res)).code).toBe('INTERNAL');
    const [entry] = h.logger.find('unhandled_error');
    expect(entry?.level).toBe('error');
    expect(entry?.fields).toMatchObject({ error: 'TypeError', detail: 'boom' });
    expect(h.logger.find('request')[0]?.fields).toMatchObject({ status: 500, code: 'INTERNAL' });
  });

  it('answers zod validation failures with 400 VALIDATION_FAILED and details.issues', async () => {
    const h = createHarness();
    const app = testApp(h, (a) => {
      a.openapi(
        createRoute({
          method: 'post',
          path: '/t/validate',
          request: {
            body: {
              content: {
                'application/json': { schema: z.object({ timezone: z.string().min(3) }) },
              },
            },
          },
          responses: { 200: { description: 'ok' } },
        }),
        (c) => c.body(null, 200),
      );
    });
    const res = await app.request('/t/validate', {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({ timezone: 1 }),
    });

    expect(res.status).toBe(400);
    const error = await errorOf(res);
    expect(error.code).toBe('VALIDATION_FAILED');
    expect(error.details).toEqual({
      issues: [expect.objectContaining({ path: 'timezone', code: 'invalid_type' })],
    });

    const ok = await app.request('/t/validate', {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({ timezone: 'Europe/Berlin' }),
    });
    expect(ok.status).toBe(200);
  });
});
