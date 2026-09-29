import { describe, expect, it } from 'vitest';
import type { z } from '@hono/zod-openapi';
import { buildApp, type App } from '../../src/app';
import { toHex } from '../../src/crypto/encoding';
import { canonicalJson } from '../../src/http/canonicalJson';
import { ERROR_TABLE, ErrorEnvelopeSchema, type ErrorCode } from '../../src/http/errors';
import { IdempotencyRepo } from '../../src/repos/IdempotencyRepo';
import { ChallengeResponseSchema } from '../../src/routes/attest';
import { BalanceDtoSchema } from '../../src/routes/balance';
import { PublicConfigDtoSchema } from '../../src/routes/config';
import {
  InstallTokenResponseSchema,
  RegisterRequestSchema,
  RegistrationResponseSchema,
} from '../../src/routes/installs';
import { TimezoneRequestSchema } from '../../src/routes/installsMe';
import { SeededCrypto } from '../fakes/SeededCrypto';
import { createHarness, type TestHarness } from '../fakes/testDeps';
import { solvePow } from '../helpers/identity';

/**
 * Client–Worker contract fixtures (06 QA15, §7; 03 §15.2; RC38). Each test
 * drives the real app (fakes for attestation, deterministic clock, IDs and
 * randomness), validates the body against the route's zod schema, and
 * exports it to `test/contract/fixtures/<group>.<case>.json` as a file
 * snapshot:
 *
 * - `npm run contract:update` (vitest `-u`) rewrites the fixtures;
 * - a plain run fails when a response no longer matches its fixture (in CI a
 *   missing fixture fails too);
 * - `melos run contract:sync` copies them to `apps/taro/test/contract/fixtures/`
 *   and `tools/check_contract_fixtures.py` fails on drift.
 *
 * Every test uses fixed install IDs, idempotency keys, request IDs and IPs,
 * so the files are byte-stable. Groups: installs, balance, config, timezone,
 * errors (one file per `code`, named `errors.<code>.json`).
 */

const HEADERS = {
  'X-Taro-Platform': 'ios',
  'X-Taro-App-Version': '1.2.0+14',
  'X-Taro-Locale': 'de',
} as const;
const ANDROID = { ...HEADERS, 'X-Taro-Platform': 'android' } as const;

/** 32 bytes of `n`, base64url (43 chars): a stable install secret / device key. */
function bytes32(n: number): string {
  return btoa(String.fromCharCode(...new Uint8Array(32).fill(n)))
    .replace(/\+/g, '-')
    .replace(/\//g, '_')
    .replace(/=+$/, '');
}

async function exportFixture(name: string, value: unknown): Promise<void> {
  await expect(`${JSON.stringify(value, null, 2)}\n`).toMatchFileSnapshot(
    `./fixtures/${name}.json`,
  );
}

function parsed<S extends z.ZodType>(schema: S, value: unknown): z.infer<S> {
  const result = schema.safeParse(value);
  expect(result.success, JSON.stringify(result.error?.issues)).toBe(true);
  return value as z.infer<S>;
}

interface Fixture {
  readonly h: TestHarness;
  readonly app: App;
}

/**
 * A fresh app per test. `seed` must differ per test: challenge nonces come
 * from the seeded stream and `used_challenges` is shared by the whole file.
 */
function fixtureApp(seed: number): Fixture {
  const crypto = new SeededCrypto(seed);
  const h = createHarness({ overrides: { crypto } });
  return { h, app: buildApp(h.deps) };
}

async function json(res: Response): Promise<unknown> {
  return res.json();
}

async function challenge(app: App, headers: Record<string, string>): Promise<string> {
  const res = await app.request('/v1/attest/challenge', { method: 'POST', headers });
  expect(res.status).toBe(200);
  return parsed(ChallengeResponseSchema, await json(res)).challenge;
}

interface RegisterCase {
  readonly installId: string;
  readonly ip: string;
  readonly key: string;
  readonly platform?: 'ios' | 'android';
  readonly secret?: string;
  readonly attestation?: (challenge: string) => Promise<Record<string, unknown>>;
}

async function registerCase(
  app: App,
  input: RegisterCase,
): Promise<{ request: Record<string, unknown>; res: Response }> {
  const platform = input.platform ?? 'ios';
  const headers = { ...(platform === 'ios' ? HEADERS : ANDROID), 'CF-Connecting-IP': input.ip };
  const nonce = await challenge(app, headers);
  const request = {
    installId: input.installId,
    installSecret: input.secret ?? bytes32(7),
    platform,
    appVersion: '1.2.0+14',
    locale: 'de',
    timezone: 'Europe/Berlin',
    ...(platform === 'android' ? { deviceKey: bytes32(9) } : {}),
    attestation:
      (await input.attestation?.(nonce)) ??
      (platform === 'ios'
        ? { type: 'app_attest', challenge: nonce, keyId: 'a2V5LWlk', attestationObject: 'b2JqZWN0' }
        : { type: 'play_integrity', challenge: nonce, integrityToken: 'integrity.token' }),
  };
  parsed(RegisterRequestSchema, request);
  const res = await app.request('/v1/installs', {
    method: 'POST',
    headers: {
      ...headers,
      'content-type': 'application/json',
      'Idempotency-Key': input.key,
      'X-Request-Id': `req-${input.key.slice(0, 8)}`,
    },
    body: JSON.stringify(request),
  });
  return { request, res };
}

async function registered(
  app: App,
  input: RegisterCase,
): Promise<{ token: string; body: z.infer<typeof RegistrationResponseSchema> }> {
  const { res } = await registerCase(app, input);
  expect([200, 201]).toContain(res.status);
  const body = parsed(RegistrationResponseSchema, await json(res));
  return { token: body.installToken, body };
}

function authed(token: string, extra: Record<string, string> = {}): Record<string, string> {
  return { ...HEADERS, Authorization: `Bearer ${token}`, ...extra };
}

async function expectError(res: Response, code: ErrorCode): Promise<unknown> {
  expect(res.status).toBe(ERROR_TABLE[code].status);
  const body = parsed(ErrorEnvelopeSchema, await json(res));
  expect(body.error.code).toBe(code);
  return body;
}

describe('contract fixtures: installs', () => {
  it('exports the challenge and an iOS registration (201)', async () => {
    const { app } = fixtureApp(1);
    const headers = { ...HEADERS, 'CF-Connecting-IP': '198.51.100.1' };
    const res = await app.request('/v1/attest/challenge', { method: 'POST', headers });
    await exportFixture(
      'installs.challenge.response',
      parsed(ChallengeResponseSchema, await json(res)),
    );

    const { request, res: registration } = await registerCase(app, {
      installId: 'c0a80101-0000-4000-8000-000000000001',
      ip: '198.51.100.2',
      key: '0e0e0e0e-0000-4000-8000-000000000001',
    });
    expect(registration.status).toBe(201);
    await exportFixture('installs.register.request', request);
    await exportFixture(
      'installs.register.response',
      parsed(RegistrationResponseSchema, await json(registration)),
    );
  });

  it('exports an Android registration and an iOS re-registration (200)', async () => {
    const { app } = fixtureApp(2);
    const android = await registerCase(app, {
      installId: 'c0a80101-0000-4000-8000-000000000002',
      ip: '198.51.100.3',
      key: '0e0e0e0e-0000-4000-8000-000000000002',
      platform: 'android',
    });
    expect(android.res.status).toBe(201);
    await exportFixture('installs.register_android.request', android.request);
    await exportFixture(
      'installs.register_android.response',
      parsed(RegistrationResponseSchema, await json(android.res)),
    );

    const first = {
      installId: 'c0a80101-0000-4000-8000-000000000003',
      ip: '198.51.100.4',
      key: '0e0e0e0e-0000-4000-8000-000000000003',
    };
    await registered(app, first);
    const again = await registerCase(app, {
      ...first,
      key: '0e0e0e0e-0000-4000-8000-000000000004',
    });
    expect(again.res.status).toBe(200);
    await exportFixture(
      'installs.reregister.response',
      parsed(RegistrationResponseSchema, await json(again.res)),
    );
  });

  it('exports a token refresh', async () => {
    const { app } = fixtureApp(3);
    const { token } = await registered(app, {
      installId: 'c0a80101-0000-4000-8000-000000000005',
      ip: '198.51.100.5',
      key: '0e0e0e0e-0000-4000-8000-000000000005',
    });
    const res = await app.request('/v1/installs/token', {
      method: 'POST',
      headers: authed(token, { 'X-Taro-Attestation': 'aa1.YXNzZXJ0aW9u' }),
    });
    expect(res.status).toBe(200);
    await exportFixture(
      'installs.token.response',
      parsed(InstallTokenResponseSchema, await json(res)),
    );
  });
});

describe('contract fixtures: balance and config', () => {
  it('exports a high-trust and a low-trust balance', async () => {
    const { h, app } = fixtureApp(4);
    const { token } = await registered(app, {
      installId: 'c0a80101-0000-4000-8000-000000000006',
      ip: '198.51.100.6',
      key: '0e0e0e0e-0000-4000-8000-000000000006',
    });
    const res = await app.request('/v1/balance', { headers: authed(token) });
    expect(res.status).toBe(200);
    await exportFixture('balance.response', parsed(BalanceDtoSchema, await json(res)));

    h.config.set({ 'abuse.lowTrust.powBits': 4 });
    const installId = 'c0a80101-0000-4000-8000-000000000007';
    const low = await registered(app, {
      installId,
      ip: '198.51.100.7',
      key: '0e0e0e0e-0000-4000-8000-000000000007',
      attestation: async (nonce) => ({
        type: 'none',
        challenge: nonce,
        reason: 'unsupported',
        pow: await solvePow(nonce, installId, 4),
      }),
    });
    expect(low.body.trust).toBe('low');
    const lowRes = await app.request('/v1/balance', {
      headers: { ...authed(low.token), 'CF-Connecting-IP': '198.51.100.7' },
    });
    expect(lowRes.status).toBe(200);
    await exportFixture('balance.low_trust.response', parsed(BalanceDtoSchema, await json(lowRes)));
  });

  it('exports the public config document', async () => {
    const { app } = fixtureApp(5);
    const res = await app.request('/v1/config', { headers: HEADERS });
    expect(res.status).toBe(200);
    expect(res.headers.get('ETag')).toBe('"v1"');
    await exportFixture('config.response', parsed(PublicConfigDtoSchema, await json(res)));
  });
});

describe('contract fixtures: timezone', () => {
  it('exports the request and the resulting balance', async () => {
    const { app } = fixtureApp(6);
    const { token } = await registered(app, {
      installId: 'c0a80101-0000-4000-8000-000000000008',
      ip: '198.51.100.8',
      key: '0e0e0e0e-0000-4000-8000-000000000008',
    });
    const request = parsed(TimezoneRequestSchema, { timezone: 'America/New_York' });
    const res = await app.request('/v1/installs/me/timezone', {
      method: 'PUT',
      headers: authed(token, {
        'content-type': 'application/json',
        'Idempotency-Key': '0e0e0e0e-0000-4000-8000-000000000009',
      }),
      body: JSON.stringify(request),
    });
    expect(res.status).toBe(200);
    await exportFixture('timezone.request', request);
    await exportFixture('timezone.response', parsed(BalanceDtoSchema, await json(res)));
  });
});

describe('contract fixtures: errors (03 §2.2 envelope, GLOSSARY §5 codes)', () => {
  const rid = (code: string): Record<string, string> => ({ 'X-Request-Id': `req-${code}` });

  it('exports auth, validation and idempotency errors', async () => {
    const { h, app } = fixtureApp(7);
    const installId = 'c0a80101-0000-4000-8000-00000000000a';
    const { token } = await registered(app, {
      installId,
      ip: '198.51.100.10',
      key: '0e0e0e0e-0000-4000-8000-00000000000a',
    });
    const tz = (key: string | undefined, timezone: string, code: string) =>
      app.request('/v1/installs/me/timezone', {
        method: 'PUT',
        headers: authed(token, {
          'content-type': 'application/json',
          ...(key === undefined ? {} : { 'Idempotency-Key': key }),
          ...rid(code),
        }),
        body: JSON.stringify({ timezone }),
      });

    await exportFixture(
      'errors.unauthenticated',
      await expectError(
        await app.request('/v1/balance', { headers: { ...HEADERS, ...rid('unauthenticated') } }),
        'UNAUTHENTICATED',
      ),
    );
    await exportFixture(
      'errors.idempotency_key_required',
      await expectError(
        await tz(undefined, 'Asia/Tokyo', 'idem-required'),
        'IDEMPOTENCY_KEY_REQUIRED',
      ),
    );
    await exportFixture(
      'errors.validation_failed',
      await expectError(
        await tz('0e0e0e0e-0000-4000-8000-00000000000b', 'Mars/Olympus', 'validation'),
        'VALIDATION_FAILED',
      ),
    );
    await exportFixture(
      'errors.idempotency_key_reused',
      await expectError(
        await tz('0e0e0e0e-0000-4000-8000-00000000000b', 'Asia/Tokyo', 'key-reused'),
        'IDEMPOTENCY_KEY_REUSED',
      ),
    );
    await exportFixture(
      'errors.attestation_required',
      await expectError(
        await app.request('/v1/installs/token', {
          method: 'POST',
          headers: authed(token, rid('attestation-required')),
        }),
        'ATTESTATION_REQUIRED',
      ),
    );

    const erase = { method: 'DELETE', path: '/v1/installs/me' } as const;
    const key = '0e0e0e0e-0000-4000-8000-00000000000c';
    const now = h.clock.now();
    await new IdempotencyRepo(h.deps.db).insert({
      installId,
      route: `${erase.method} ${erase.path}`,
      key,
      requestHash: toHex(
        await h.deps.crypto.sha256(`${erase.method}\n${erase.path}\n${canonicalJson('')}`),
      ),
      createdAt: now.toISOString(),
      expiresAt: new Date(now.getTime() + 3_600_000).toISOString(),
    });
    await exportFixture(
      'errors.request_in_progress',
      await expectError(
        await app.request(erase.path, {
          method: erase.method,
          headers: authed(token, { 'Idempotency-Key': key, ...rid('in-progress') }),
        }),
        'REQUEST_IN_PROGRESS',
      ),
    );

    await exportFixture(
      'errors.timezone_change_too_soon',
      await (async () => {
        expect(
          (await tz('0e0e0e0e-0000-4000-8000-00000000000d', 'Asia/Tokyo', 'tz-1')).status,
        ).toBe(200);
        return expectError(
          await tz('0e0e0e0e-0000-4000-8000-00000000000e', 'Asia/Kolkata', 'tz-too-soon'),
          'TIMEZONE_CHANGE_TOO_SOON',
        );
      })(),
    );

    h.clock.advance({ days: 8 });
    await exportFixture(
      'errors.token_expired',
      await expectError(
        await app.request('/v1/balance', { headers: authed(token, rid('token-expired')) }),
        'TOKEN_EXPIRED',
      ),
    );
  });

  it('exports attestation, routing, gate, rate-limit and internal errors', async () => {
    const { h, app } = fixtureApp(8);
    const first = {
      installId: 'c0a80101-0000-4000-8000-00000000000f',
      ip: '198.51.100.11',
      key: '0e0e0e0e-0000-4000-8000-00000000000f',
    };
    const { request } = await registerCase(app, first);
    const replay = await app.request('/v1/installs', {
      method: 'POST',
      headers: {
        ...HEADERS,
        'CF-Connecting-IP': first.ip,
        'content-type': 'application/json',
        'Idempotency-Key': '0e0e0e0e-0000-4000-8000-000000000010',
        ...rid('attestation-failed'),
      },
      body: JSON.stringify({ ...request, installId: 'c0a80101-0000-4000-8000-000000000010' }),
    });
    await exportFixture(
      'errors.attestation_failed',
      await expectError(replay, 'ATTESTATION_FAILED'),
    );

    await exportFixture(
      'errors.not_found',
      await expectError(
        await app.request('/v1/nope', { headers: { ...HEADERS, ...rid('not-found') } }),
        'NOT_FOUND',
      ),
    );

    h.config.set({ 'app.minVersion.ios': '9.0.0' });
    await exportFixture(
      'errors.upgrade_required',
      await expectError(
        await app.request('/v1/attest/challenge', {
          method: 'POST',
          headers: { ...HEADERS, ...rid('upgrade') },
        }),
        'UPGRADE_REQUIRED',
      ),
    );
    h.config.set({ 'app.minVersion.ios': '1.0.0' });

    h.burst.limitPerKey = 0;
    await exportFixture(
      'errors.rate_limited',
      await expectError(
        await app.request('/v1/attest/challenge', {
          method: 'POST',
          headers: { ...HEADERS, 'CF-Connecting-IP': '198.51.100.12', ...rid('rate-limited') },
        }),
        'RATE_LIMITED',
      ),
    );
    h.burst.limitPerKey = Number.POSITIVE_INFINITY;

    const broken = createHarness({
      overrides: {
        crypto: new SeededCrypto(99),
        keys: {
          ...h.deps.keys,
          challenge: () => {
            throw new Error('CHALLENGE_KEY is not set');
          },
        },
      },
    });
    await exportFixture(
      'errors.internal',
      await expectError(
        await buildApp(broken.deps).request('/v1/attest/challenge', {
          method: 'POST',
          headers: { ...HEADERS, 'CF-Connecting-IP': '198.51.100.13', ...rid('internal') },
        }),
        'INTERNAL',
      ),
    );
    broken.logger.expectNoSensitive();
  });
});
