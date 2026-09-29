import { describe, expect, it, vi } from 'vitest';
import type { App } from '../../../src/app';
import { fromUtf8 } from '../../../src/crypto/encoding';
import {
  ANON_SCOPE,
  deleteIdempotentBody,
  idempotency,
  isTerminalStatus,
} from '../../../src/http/middleware/idempotency';
import { IdempotencyRepo } from '../../../src/repos/IdempotencyRepo';
import {
  bindings,
  createHarness,
  TEST_IDEMPOTENCY_KEYRING,
  uniqueId,
  type HarnessOptions,
  type TestHarness,
} from '../../fakes/testDeps';
import { errorOf, testApp, testAuth } from '../../helpers/app';

interface Script {
  status: number;
  gate?: Promise<void> | undefined;
  throws?: boolean;
}

interface Fixture {
  h: TestHarness;
  app: App;
  calls: { a: number; b: number; reg: number };
  script: Script;
  send: (input: {
    key?: string;
    install?: string;
    path?: string;
    body?: string;
    headers?: Record<string, string>;
  }) => Promise<Response>;
}

/**
 * Test routes behind the real middleware stack. Bodies carry the call number
 * (`#n`), so a replay is provably the stored bytes and not a re-run.
 */
function setup(options: HarnessOptions = {}): Fixture {
  const h = createHarness(options);
  const calls = { a: 0, b: 0, reg: 0 };
  const script: Script = { status: 200 };
  const respond = async (n: number): Promise<Response> => {
    if (script.gate !== undefined) {
      await script.gate;
    }
    if (script.throws === true) {
      throw new Error('handler crashed');
    }
    const empty = script.status === 204;
    return new Response(empty ? null : `{"ok": true,  "ü": "✨", "n": ${String(n)}}`, {
      status: script.status,
      headers: { 'content-type': 'application/json; charset=utf-8', 'x-extra': 'dropped' },
    });
  };
  const app = testApp(h, (a) => {
    a.use('/v1/t/*', testAuth);
    a.post('/v1/t/a', idempotency(h.deps), () => respond(++calls.a));
    a.post('/v1/t/b', idempotency(h.deps), () => respond(++calls.b));
    a.post(
      '/v1/t/register',
      idempotency(h.deps, {
        route: 'POST /v1/installs',
        scope: async (c) => (await c.req.json<{ installId?: string }>()).installId,
      }),
      () => respond(++calls.reg),
    );
  });
  const send: Fixture['send'] = async ({
    key,
    install,
    path = '/v1/t/a',
    body = '{"x":1}',
    headers,
  }) =>
    app.request(path, {
      method: 'POST',
      headers: {
        'content-type': 'application/json',
        ...(key === undefined ? {} : { 'Idempotency-Key': key }),
        ...(install === undefined ? {} : { 'X-Test-Install': install }),
        ...headers,
      },
      body,
    });
  return { h, app, calls, script, send };
}

async function rows(key: string) {
  const { results } = await bindings.DB.prepare('SELECT * FROM idempotency_keys WHERE key = ?')
    .bind(key)
    .all<{
      install_id: string;
      route: string;
      state: string;
      request_hash: string;
      response_status: number | null;
      response_body_enc: ArrayBuffer | null;
      created_at: string;
      expires_at: string;
    }>();
  return results;
}

describe('idempotency middleware: key header', () => {
  it('requires Idempotency-Key (400 IDEMPOTENCY_KEY_REQUIRED) before running the handler', async () => {
    const f = setup();
    const res = await f.send({ install: uniqueId() });

    expect(res.status).toBe(400);
    expect((await errorOf(res)).code).toBe('IDEMPOTENCY_KEY_REQUIRED');
    expect(f.calls.a).toBe(0);
  });

  it('rejects a key that is not a UUID with 400 VALIDATION_FAILED', async () => {
    const f = setup();
    const res = await f.send({ install: uniqueId(), key: 'not-a-uuid' });

    expect(res.status).toBe(400);
    expect((await errorOf(res)).code).toBe('VALIDATION_FAILED');
    expect(f.calls.a).toBe(0);
  });
});

describe('idempotency middleware: terminal outcomes are replayed (RC49)', () => {
  it('replays a 200 byte for byte with Idempotent-Replayed: true', async () => {
    const f = setup();
    const req = { install: uniqueId(), key: uniqueId('k') };
    const first = await f.send(req);
    const firstBytes = new Uint8Array(await first.arrayBuffer());
    const second = await f.send(req);
    const secondBytes = new Uint8Array(await second.arrayBuffer());

    expect(first.status).toBe(200);
    expect(first.headers.get('Idempotent-Replayed')).toBeNull();
    expect(second.status).toBe(200);
    expect(second.headers.get('Idempotent-Replayed')).toBe('true');
    expect(second.headers.get('content-type')).toBe('application/json; charset=utf-8');
    expect(second.headers.get('x-extra')).toBeNull();
    expect(second.headers.get('X-Request-Id')).not.toBe(first.headers.get('X-Request-Id'));
    expect(secondBytes).toEqual(firstBytes);
    expect(fromUtf8(secondBytes)).toBe('{"ok": true,  "ü": "✨", "n": 1}');
    expect(f.calls.a).toBe(1);
  });

  it('treats a body with reordered keys as the same request (canonical JSON)', async () => {
    const f = setup();
    const req = { install: uniqueId(), key: uniqueId('k') };
    await f.send({ ...req, body: '{"a":1,"b":{"c":2,"d":3}}' });
    const again = await f.send({ ...req, body: '{ "b": {"d":3, "c":2}, "a": 1 }' });

    expect(again.headers.get('Idempotent-Replayed')).toBe('true');
    expect(f.calls.a).toBe(1);
  });

  it.each([201, 204, 400, 422])('stores and replays %i', async (status) => {
    const f = setup();
    f.script.status = status;
    const req = { install: uniqueId(), key: uniqueId('k') };
    const first = await f.send(req);
    const firstText = await first.text();
    const second = await f.send(req);

    expect(second.status).toBe(status);
    expect(second.headers.get('Idempotent-Replayed')).toBe('true');
    expect(await second.text()).toBe(firstText);
    expect(f.calls.a).toBe(1);
    const [row] = await rows(req.key);
    expect(row).toMatchObject({ state: 'done', response_status: status });
  });

  it('stores only 2xx, 400 and 422 as terminal', () => {
    for (const status of [200, 201, 202, 204, 299, 400, 422]) {
      expect(isTerminalStatus(status), String(status)).toBe(true);
    }
    for (const status of [199, 300, 304, 401, 402, 403, 404, 409, 410, 412, 426, 429, 500, 503]) {
      expect(isTerminalStatus(status), String(status)).toBe(false);
    }
  });
});

describe('idempotency middleware: non-terminal outcomes delete the row (RC49)', () => {
  it.each([401, 402, 403, 404, 409, 410, 412, 426, 429, 500, 503])(
    '%i is not replayed: the retry runs the handler again',
    async (status) => {
      const f = setup();
      f.script.status = status;
      const req = { install: uniqueId(), key: uniqueId('k') };
      const first = await f.send(req);
      expect(first.status).toBe(status);
      expect(await rows(req.key)).toEqual([]);

      f.script.status = 200;
      const retry = await f.send(req);

      expect(retry.status).toBe(200);
      expect(retry.headers.get('Idempotent-Replayed')).toBeNull();
      expect(await retry.text()).toContain('"n": 2');
      expect(f.calls.a).toBe(2);
    },
  );

  it('a thrown handler error (500 INTERNAL) releases the key', async () => {
    const f = setup();
    f.script.throws = true;
    const req = { install: uniqueId(), key: uniqueId('k') };
    const failed = await f.send(req);
    expect(failed.status).toBe(500);
    expect((await errorOf(failed)).code).toBe('INTERNAL');

    f.script.throws = false;
    expect((await f.send(req)).status).toBe(200);
    expect(f.calls.a).toBe(2);
  });
});

describe('idempotency middleware: key reuse and scope', () => {
  it('same key with a different body → 422 IDEMPOTENCY_KEY_REUSED', async () => {
    const f = setup();
    const req = { install: uniqueId(), key: uniqueId('k') };
    await f.send({ ...req, body: '{"x":1}' });
    const reused = await f.send({ ...req, body: '{"x":2}' });

    expect(reused.status).toBe(422);
    expect((await errorOf(reused)).code).toBe('IDEMPOTENCY_KEY_REUSED');
    expect(f.calls.a).toBe(1);
  });

  it('the same key on two routes runs both handlers and replays each separately', async () => {
    const f = setup();
    const req = { install: uniqueId(), key: uniqueId('k') };
    const onA = await f.send({ ...req, path: '/v1/t/a' });
    const onB = await f.send({ ...req, path: '/v1/t/b' });
    expect(onA.headers.get('Idempotent-Replayed')).toBeNull();
    expect(onB.headers.get('Idempotent-Replayed')).toBeNull();

    const replayA = await f.send({ ...req, path: '/v1/t/a' });
    const replayB = await f.send({ ...req, path: '/v1/t/b' });
    expect(replayA.headers.get('Idempotent-Replayed')).toBe('true');
    expect(replayB.headers.get('Idempotent-Replayed')).toBe('true');
    expect(f.calls).toMatchObject({ a: 1, b: 1 });
    expect((await rows(req.key)).map((r) => r.route).sort()).toEqual([
      'POST /v1/t/a',
      'POST /v1/t/b',
    ]);
  });

  it('the same key for two installs does not collide', async () => {
    const f = setup();
    const key = uniqueId('k');
    await f.send({ install: uniqueId(), key });
    const other = await f.send({ install: uniqueId(), key, body: '{"x":2}' });

    expect(other.status).toBe(200);
    expect(other.headers.get('Idempotent-Replayed')).toBeNull();
    expect(f.calls.a).toBe(2);
  });

  it('uses a route scope from the body and a fixed route label (POST /v1/installs, RC55)', async () => {
    const f = setup();
    const key = uniqueId('k');
    const installId = uniqueId('i');
    await f.send({ path: '/v1/t/register', key, body: JSON.stringify({ installId }) });
    const replay = await f.send({
      path: '/v1/t/register',
      key,
      body: JSON.stringify({ installId }),
    });

    expect(replay.headers.get('Idempotent-Replayed')).toBe('true');
    expect(await rows(key)).toEqual([
      expect.objectContaining({ install_id: installId, route: 'POST /v1/installs' }),
    ]);
  });

  it('falls back to the anonymous scope without an install', async () => {
    const f = setup();
    const key = uniqueId('k');
    await f.send({ path: '/v1/t/register', key, body: '{}' });

    expect((await rows(key))[0]?.install_id).toBe(ANON_SCOPE);
  });
});

describe('idempotency middleware: in progress and takeover', () => {
  it('answers a concurrent duplicate with 409 REQUEST_IN_PROGRESS and Retry-After: 3', async () => {
    const f = setup();
    let release = (): void => undefined;
    f.script.gate = new Promise((resolve) => {
      release = resolve;
    });
    const req = { install: uniqueId(), key: uniqueId('k') };
    const running = f.send(req);
    await vi.waitFor(() => {
      expect(f.calls.a).toBe(1);
    });

    const duplicate = await f.send(req);
    expect(duplicate.status).toBe(409);
    expect(duplicate.headers.get('Retry-After')).toBe('3');
    const error = await errorOf(duplicate);
    expect(error).toMatchObject({ code: 'REQUEST_IN_PROGRESS', retryable: true, retryAfterSec: 3 });

    release();
    expect((await running).status).toBe(200);
    expect((await f.send(req)).headers.get('Idempotent-Replayed')).toBe('true');
    expect(f.calls.a).toBe(1);
  });

  it('takes over a crashed request after 120 s, and the late original cannot overwrite it', async () => {
    const f = setup();
    let releaseCrashed = (): void => undefined;
    f.script.gate = new Promise((resolve) => {
      releaseCrashed = resolve;
    });
    const req = { install: uniqueId(), key: uniqueId('k') };
    const crashed = f.send(req);
    await vi.waitFor(() => {
      expect(f.calls.a).toBe(1);
    });
    f.script.gate = undefined;

    f.h.clock.advance({ seconds: 119 });
    expect((await f.send(req)).status).toBe(409);

    f.h.clock.advance({ seconds: 1 });
    const takeover = await f.send(req);
    expect(takeover.status).toBe(200);
    expect(await takeover.text()).toContain('"n": 2');
    expect(f.h.logger.find('idempotency_takeover')).toHaveLength(1);

    releaseCrashed();
    expect((await crashed).status).toBe(200);
    expect(f.h.logger.find('idempotency_ownership_lost')).toHaveLength(1);

    const replay = await f.send(req);
    expect(replay.headers.get('Idempotent-Replayed')).toBe('true');
    expect(await replay.text()).toContain('"n": 2');
  });

  it('a late non-terminal original does not delete the new owner row', async () => {
    const f = setup();
    let releaseCrashed = (): void => undefined;
    f.script.gate = new Promise((resolve) => {
      releaseCrashed = resolve;
    });
    const req = { install: uniqueId(), key: uniqueId('k') };
    const crashed = f.send(req);
    await vi.waitFor(() => {
      expect(f.calls.a).toBe(1);
    });
    f.script.gate = undefined;
    f.h.clock.advance({ seconds: 121 });
    expect((await f.send(req)).status).toBe(200);

    f.script.status = 503;
    releaseCrashed();
    expect((await crashed).status).toBe(503);
    expect(f.h.logger.find('idempotency_ownership_lost')).toHaveLength(1);
    expect((await rows(req.key))[0]?.state).toBe('done');
  });

  it('a stale row with a different body is still a key reuse, not a takeover', async () => {
    const f = setup();
    const req = { install: uniqueId(), key: uniqueId('k') };
    const repo = new IdempotencyRepo(bindings.DB);
    await repo.insert({
      installId: req.install,
      route: 'POST /v1/t/a',
      key: req.key,
      requestHash: 'other',
      createdAt: '2026-09-26T09:00:00.000Z',
      expiresAt: '2026-10-03T09:00:00.000Z',
    });

    expect((await f.send(req)).status).toBe(422);
    expect(f.calls.a).toBe(0);
  });
});

describe('idempotency middleware: storage, TTL and encryption', () => {
  it('keeps rows 7 days, then treats the key as new', async () => {
    const f = setup();
    const req = { install: uniqueId(), key: uniqueId('k') };
    await f.send(req);
    const [row] = await rows(req.key);
    expect(row?.expires_at).toBe('2026-10-03T10:00:00.000Z');

    f.h.clock.advance({ days: 6 });
    expect((await f.send(req)).headers.get('Idempotent-Replayed')).toBe('true');

    f.h.clock.advance({ days: 1 });
    const fresh = await f.send({ ...req, body: '{"x":"changed"}' });
    expect(fresh.status).toBe(200);
    expect(fresh.headers.get('Idempotent-Replayed')).toBeNull();
    expect(f.calls.a).toBe(2);
    expect((await rows(req.key))[0]?.expires_at).toBe('2026-10-10T10:00:00.000Z');
  });

  it('stores the body AES-256-GCM encrypted under the current kid', async () => {
    const f = setup();
    const req = { install: uniqueId(), key: uniqueId('k') };
    await f.send(req);
    const [row] = await rows(req.key);
    const blob = new Uint8Array(row?.response_body_enc ?? new ArrayBuffer(0));

    expect(row?.request_hash).toMatch(/^[0-9a-f]{64}$/);
    expect(blob[0]).toBe(1);
    expect(fromUtf8(blob.subarray(2, 2 + (blob[1] ?? 0)))).toBe('kt2');
    expect(fromUtf8(blob)).not.toContain('"ok"');
    expect(fromUtf8(blob)).not.toContain('✨');
  });

  it('replays a body sealed with the previous key after rotation', async () => {
    const original = setup();
    const req = { install: uniqueId(), key: uniqueId('k') };
    const first = await original.send(req);

    const newKey = 'kt3:AwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwM';
    const rotated = setup({ idempotencyKeyring: `${newKey},${TEST_IDEMPOTENCY_KEYRING}` });
    const replay = await rotated.send(req);
    expect(replay.headers.get('Idempotent-Replayed')).toBe('true');
    expect(await replay.text()).toBe(await first.text());
    expect(rotated.calls.a).toBe(0);
  });

  it('passes through (handler runs, nothing stored) when the body key was retired', async () => {
    const original = setup();
    const req = { install: uniqueId(), key: uniqueId('k') };
    await original.send(req);

    const retired = setup({
      idempotencyKeyring: 'kt3:AwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwM',
    });
    const res = await retired.send(req);
    expect(res.status).toBe(200);
    expect(res.headers.get('Idempotent-Replayed')).toBeNull();
    expect(retired.calls.a).toBe(1);
    expect(retired.h.logger.find('idempotency_body_unreadable')).toHaveLength(1);
    expect((await rows(req.key))[0]?.state).toBe('done');
  });

  it('binds the body to install‖route‖key (AAD): a moved blob does not decrypt', async () => {
    const f = setup();
    const install = uniqueId();
    const source = { install, key: uniqueId('k') };
    const target = { install, key: uniqueId('k') };
    await f.send(source);
    await f.send(target);
    await bindings.DB.prepare(
      `UPDATE idempotency_keys SET response_body_enc =
         (SELECT response_body_enc FROM idempotency_keys WHERE key = ?1) WHERE key = ?2`,
    )
      .bind(source.key, target.key)
      .run();

    const res = await f.send(target);
    expect(res.headers.get('Idempotent-Replayed')).toBeNull();
    expect(f.calls.a).toBe(3);
  });

  it('rejects a corrupt blob version as unreadable', async () => {
    const f = setup();
    const req = { install: uniqueId(), key: uniqueId('k') };
    await f.send(req);
    await bindings.DB.prepare('UPDATE idempotency_keys SET response_body_enc = ?1 WHERE key = ?2')
      .bind(new Uint8Array([9, 0]), req.key)
      .run();

    expect((await f.send(req)).headers.get('Idempotent-Replayed')).toBeNull();
    expect(f.h.logger.find('idempotency_body_unreadable')).toHaveLength(1);
  });

  it('deleteIdempotentBody drops the body (reading ack, RC51); later retries pass through', async () => {
    const f = setup();
    const req = { install: uniqueId(), key: uniqueId('k') };
    await f.send(req);
    const ref = { installId: req.install, route: 'POST /v1/t/a', key: req.key };

    expect(await deleteIdempotentBody(f.h.deps, ref)).toBe(true);
    expect(await deleteIdempotentBody(f.h.deps, ref)).toBe(false);
    expect((await rows(req.key))[0]).toMatchObject({ state: 'done', response_body_enc: null });

    const afterAck = await f.send(req);
    expect(afterAck.status).toBe(200);
    expect(afterAck.headers.get('Idempotent-Replayed')).toBeNull();
    expect(f.calls.a).toBe(2);
    expect((await rows(req.key))[0]?.response_body_enc).toBeNull();
  });

  it('fails with 500 before the handler runs when IDEMPOTENCY_ENC_KEY is missing', async () => {
    const f = setup({ idempotencyKeyring: '' });
    const req = { install: uniqueId(), key: uniqueId('k') };
    const res = await f.send(req);

    expect(res.status).toBe(500);
    expect(f.calls.a).toBe(0);
    expect(await rows(req.key)).toEqual([]);
  });
});

describe('IdempotencyRepo', () => {
  it('purges only expired rows, bounded by the limit', async () => {
    const repo = new IdempotencyRepo(bindings.DB);
    const install = uniqueId('p');
    for (const [key, expiresAt] of [
      ['e1', '2000-01-01T00:00:00.000Z'],
      ['e2', '2000-01-02T00:00:00.000Z'],
      ['live', '2999-01-01T00:00:00.000Z'],
    ] as const) {
      await repo.insert({
        installId: install,
        route: 'POST /v1/x',
        key,
        requestHash: 'h',
        createdAt: '2000-01-01T00:00:00.000Z',
        expiresAt,
      });
    }

    expect(await repo.purgeExpired('2026-01-01T00:00:00.000Z', 1)).toBe(1);
    expect(await repo.purgeExpired('2026-01-01T00:00:00.000Z')).toBe(1);
    expect(
      await repo.find({ installId: install, route: 'POST /v1/x', key: 'live' }),
    ).not.toBeNull();
    expect(await repo.find({ installId: install, route: 'POST /v1/x', key: 'e1' })).toBeNull();
  });
});
