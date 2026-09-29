import { describe, expect, it } from 'vitest';
import { openApiDocument } from '../../../src/admin/openapi';
import { buildApp } from '../../../src/app';
import { createHarness } from '../../fakes/testDeps';
import { APP_HEADERS, errorOf } from '../../helpers/app';
import { registerOk, uniqueIp } from '../../helpers/identity';

/**
 * Route wiring against the canonical table (03 §2.1, GLOSSARY §4, RC11): the
 * auth kind and the **[idem]** / **[attest]** flags of every route, both as
 * documented in the OpenAPI operation and as enforced by the middleware.
 * `[attest]` is on exactly E05, E09, E10 and E15 (RC11, RC50).
 */
type Auth = 'public' | 'token' | 'tokenMayBeExpired' | 'signature';
type Flag = 'idem' | 'attest';

const CANONICAL: Readonly<Record<string, { auth: Auth; flags: readonly Flag[] }>> = {
  'GET /v1/health': { auth: 'public', flags: [] },
  'GET /v1/config': { auth: 'public', flags: [] },
  'POST /v1/attest/challenge': { auth: 'public', flags: [] },
  'POST /v1/installs': { auth: 'public', flags: ['idem'] },
  'POST /v1/installs/token': { auth: 'tokenMayBeExpired', flags: ['attest'] },
  'PUT /v1/installs/me/timezone': { auth: 'token', flags: ['idem'] },
  'DELETE /v1/installs/me': { auth: 'token', flags: ['idem'] },
  'GET /v1/balance': { auth: 'token', flags: [] },
  'POST /v1/readings/holds': { auth: 'token', flags: ['idem', 'attest'] },
  'POST /v1/readings': { auth: 'token', flags: ['idem', 'attest'] },
  'GET /v1/readings/{clientReadingId}': { auth: 'token', flags: [] },
  'POST /v1/readings/{clientReadingId}/ack': { auth: 'token', flags: [] },
  'POST /v1/readings/{clientReadingId}/report': { auth: 'token', flags: ['idem'] },
  'POST /v1/purchases/verify': { auth: 'token', flags: ['idem'] },
  'POST /v1/rewards/intents': { auth: 'token', flags: ['idem', 'attest'] },
  'GET /v1/rewards/intents/{intentId}': { auth: 'token', flags: [] },
  'POST /v1/rewards/intents/{intentId}/cancel': { auth: 'token', flags: [] },
  'GET /v1/ads/admob/ssv': { auth: 'signature', flags: [] },
  'POST /v1/webhooks/appstore': { auth: 'signature', flags: [] },
  'POST /v1/webhooks/googleplay': { auth: 'signature', flags: [] },
};

interface Operation {
  readonly id: string;
  readonly method: string;
  readonly path: string;
  readonly auth: unknown;
  readonly flags: unknown;
  readonly security: unknown;
}

function operations(): Operation[] {
  const paths = openApiDocument()['paths'] as Record<
    string,
    Record<string, Record<string, unknown>>
  >;
  return Object.entries(paths).flatMap(([path, ops]) =>
    Object.entries(ops).map(([method, op]) => ({
      id: `${method.toUpperCase()} ${path}`,
      method: method.toUpperCase(),
      path,
      auth: op['x-taro-auth'],
      flags: op['x-taro-flags'],
      security: op['security'],
    })),
  );
}

describe('route wiring (03 §2.1, GLOSSARY §4, RC11)', () => {
  it('documents every implemented route with its canonical auth and flags', () => {
    const ops = operations();
    expect(ops.length).toBeGreaterThanOrEqual(8);
    for (const op of ops) {
      const canonical = CANONICAL[op.id];
      expect(canonical, op.id).toBeDefined();
      expect({ id: op.id, auth: op.auth, flags: op.flags }).toEqual({
        id: op.id,
        auth: canonical?.auth,
        flags: canonical?.flags,
      });
      expect(op.security).toEqual(op.auth === 'public' ? [] : [{ installToken: [] }]);
    }
  });

  it('enforces the documented flags and auth on every implemented route', async () => {
    const h = createHarness();
    const app = buildApp(h.deps);
    const { body } = await registerOk(app);
    const headers = {
      ...APP_HEADERS,
      'CF-Connecting-IP': uniqueIp(),
      Authorization: `Bearer ${body.installToken}`,
    };

    for (const op of operations()) {
      const flags = op.flags as Flag[];
      const noKey = await app.request(op.path, { method: op.method, headers });
      const code = noKey.status >= 400 ? (await errorOf(noKey)).code : undefined;
      if (flags.includes('idem')) {
        expect({ id: op.id, code }).toEqual({ id: op.id, code: 'IDEMPOTENCY_KEY_REQUIRED' });
      } else if (flags.includes('attest')) {
        expect({ id: op.id, code }).toEqual({ id: op.id, code: 'ATTESTATION_REQUIRED' });
      } else {
        expect({ id: op.id, code }).not.toEqual({ id: op.id, code: 'IDEMPOTENCY_KEY_REQUIRED' });
      }

      if (op.auth === 'token' || op.auth === 'tokenMayBeExpired') {
        const anonymous = await app.request(op.path, {
          method: op.method,
          headers: { ...APP_HEADERS, 'Idempotency-Key': '5b1f9f4e-6c3a-4d7e-9a0b-1c2d3e4f5a6b' }, // gitleaks:allow (test idempotency UUID)
        });
        expect({
          id: op.id,
          status: anonymous.status,
          code: (await errorOf(anonymous)).code,
        }).toEqual({ id: op.id, status: 401, code: 'UNAUTHENTICATED' });
      }
    }
  });
});
