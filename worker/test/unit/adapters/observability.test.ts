import { env } from 'cloudflare:workers';
import { describe, expect, it, vi } from 'vitest';
import { AnalyticsEngineMetrics } from '../../../src/adapters/cf/AnalyticsEngineMetrics';
import { consoleSink, JsonLogger } from '../../../src/adapters/cf/JsonLogger';
import { SystemClock } from '../../../src/adapters/cf/SystemClock';
import {
  ALERT_DEDUPE_SEC,
  alertDedupeKey,
  WebhookAlerter,
  type FetchFn,
} from '../../../src/adapters/cf/WebhookAlerter';
import { unimplementedPort } from '../../../src/adapters/unimplemented';
import { inst8, redactFields, REDACTED } from '../../../src/logging/redact';
import { CapturingAlerter } from '../../fakes/CapturingAlerter';
import { CapturingLogger } from '../../fakes/CapturingLogger';
import { FakeRateLimiter } from '../../fakes/FakeRateLimiter';
import { FixedClock } from '../../fakes/FixedClock';
import { InMemoryMetrics } from '../../fakes/InMemoryMetrics';

describe('redactFields (BE13)', () => {
  it('redacts sensitive keys and credential-shaped values, keeps the rest', () => {
    expect(
      redactFields({
        route: 'POST /v1/installs',
        installSecret: 'abc',
        installToken: 'abc',
        authorization: 'x',
        question: 'Will I…',
        reading: 'The Tower…',
        body: '{}',
        ip: '203.0.113.9',
        attestationObject: 'o2Nm…',
        deviceKey: 'k',
        note: 'eyJhbGciOiJFZERTQSJ9.eyJzdWIiOiIxIn0.sig',
        header: 'Bearer abc.def',
        promptVersion: 'v1',
        readingId: 'r1',
        status: 200,
        ok: true,
        missing: undefined,
        empty: null,
      }),
    ).toEqual({
      route: 'POST /v1/installs',
      installSecret: REDACTED,
      installToken: REDACTED,
      authorization: REDACTED,
      question: REDACTED,
      reading: REDACTED,
      body: REDACTED,
      ip: REDACTED,
      attestationObject: REDACTED,
      deviceKey: REDACTED,
      note: REDACTED,
      header: REDACTED,
      promptVersion: 'v1',
      readingId: 'r1',
      status: 200,
      ok: true,
      empty: null,
    });
    expect(redactFields(undefined)).toEqual({});
  });

  it('reduces an install ID to inst8', () => {
    expect(inst8('3f1c2b1e-9a8b-4c7d-8e6f-5a4b3c2d1e0f')).toBe('3f1c2b1e');
    expect(inst8(undefined)).toBeUndefined();
  });
});

describe('JsonLogger', () => {
  it('writes one redacted JSON line per event at or above the minimum level', () => {
    const lines: string[] = [];
    const logger = new JsonLogger(new FixedClock('2026-09-26T10:00:00.000Z'), (l) => lines.push(l));
    logger.log('debug', 'hidden');
    logger.log('info', 'request', { status: 200, installSecret: 'nope' });
    logger.log('error', 'boom');

    expect(lines.map((l) => JSON.parse(l) as unknown)).toEqual([
      {
        ts: '2026-09-26T10:00:00.000Z',
        level: 'info',
        event: 'request',
        status: 200,
        installSecret: REDACTED,
      },
      { ts: '2026-09-26T10:00:00.000Z', level: 'error', event: 'boom' },
    ]);
  });

  it('honours a custom minimum level', () => {
    const lines: string[] = [];
    new JsonLogger(new FixedClock(), (l) => lines.push(l), 'debug').log('debug', 'shown');
    expect(lines).toHaveLength(1);
  });

  it('consoleSink writes to console.log (Workers Logs)', () => {
    const spy = vi.spyOn(console, 'log').mockImplementation(() => undefined);
    consoleSink('{"event":"x"}');
    expect(spy).toHaveBeenCalledWith('{"event":"x"}');
    spy.mockRestore();
  });
});

describe('SystemClock', () => {
  it('returns a real Date', () => {
    expect(new SystemClock().now()).toBeInstanceOf(Date);
  });
});

describe('AnalyticsEngineMetrics', () => {
  it('writes blobs, doubles and the event index in the fixed column order', () => {
    const points: AnalyticsEngineDataPoint[] = [];
    const metrics = new AnalyticsEngineMetrics({ writeDataPoint: (p) => points.push(p ?? {}) });
    metrics.write({ event: 'rate_limited', platform: 'ios', code: 'burst' });
    metrics.write({
      event: 'reading_completed',
      platform: 'android',
      locale: 'de',
      model: 'claude-opus-5',
      promptVersion: 'v1',
      chargeSource: 'paid',
      code: 'none',
      costMicroUsd: 12,
      latencyMs: 3400,
      inputTokens: 100,
      outputTokens: 200,
      credits: 1,
    });

    expect(points).toEqual([
      {
        blobs: ['rate_limited', 'ios', '', '', '', '', 'burst'],
        doubles: [0, 0, 0, 0, 0],
        indexes: ['rate_limited'],
      },
      {
        blobs: ['reading_completed', 'android', 'de', 'claude-opus-5', 'v1', 'paid', 'none'],
        doubles: [12, 3400, 100, 200, 1],
        indexes: ['reading_completed'],
      },
    ]);
  });
});

describe('WebhookAlerter', () => {
  function recordingFetch(response: Response | Error) {
    const calls: { url: string; init: RequestInit }[] = [];
    const fetchFn: FetchFn = (url, init) => {
      calls.push({ url, init });
      return response instanceof Error ? Promise.reject(response) : Promise.resolve(response);
    };
    return { calls, fetchFn };
  }

  it('posts the alert as JSON and logs it', async () => {
    const logger = new CapturingLogger();
    const { calls, fetchFn } = recordingFetch(new Response('ok'));
    await new WebhookAlerter(fetchFn, 'https://hooks.example/abc', logger).send({
      kind: 'low_trust_bucket',
      message: '400/500',
      fields: { platform: 'ios', installSecret: 'never' },
    });

    expect(calls).toHaveLength(1);
    expect(calls[0]?.url).toBe('https://hooks.example/abc');
    expect(JSON.parse(calls[0]?.init.body as string)).toEqual({
      text: '[taro-api] low_trust_bucket: 400/500',
      fields: { platform: 'ios', installSecret: REDACTED },
    });
    expect(logger.find('alert')[0]?.fields).toEqual({
      kind: 'low_trust_bucket',
      message: '400/500',
    });
  });

  it('only logs without a URL', async () => {
    const logger = new CapturingLogger();
    const { calls, fetchFn } = recordingFetch(new Response('ok'));
    await new WebhookAlerter(fetchFn, undefined, logger).send({ kind: 'error_rate', message: 'x' });
    await new WebhookAlerter(fetchFn, '', logger).send({ kind: 'error_rate', message: 'x' });

    expect(calls).toHaveLength(0);
    expect(logger.find('alert')).toHaveLength(2);
  });

  it('never throws on a failed or rejected delivery', async () => {
    const logger = new CapturingLogger();
    await new WebhookAlerter(
      recordingFetch(new Response('no', { status: 500 })).fetchFn,
      'https://hooks.example',
      logger,
    ).send({ kind: 'budget_tier', message: 'x' });
    await new WebhookAlerter(
      recordingFetch(new TypeError('network')).fetchFn,
      'https://hooks.example',
      logger,
    ).send({ kind: 'budget_tier', message: 'x' });
    await new WebhookAlerter(
      // eslint-disable-next-line @typescript-eslint/prefer-promise-reject-errors -- non-Error rejection path
      () => Promise.reject('string'),
      'https://hooks.example',
      logger,
    ).send({ kind: 'budget_tier', message: 'x' });

    expect(logger.find('alert_failed').map((e) => e.fields)).toEqual([
      { kind: 'budget_tier', status: 500 },
      { kind: 'budget_tier', error: 'TypeError' },
      { kind: 'budget_tier', error: 'unknown' },
    ]);
  });
});

describe('WebhookAlerter hourly dedupe (03 §14.1)', () => {
  const cache = (env as unknown as { CACHE_KV: KVNamespace }).CACHE_KV;

  function alerter(clock: FixedClock, logger = new CapturingLogger()) {
    const posts: string[] = [];
    const fetchFn: FetchFn = (_url, init) => {
      posts.push(init.body as string);
      return Promise.resolve(new Response('ok'));
    };
    return {
      posts,
      logger,
      alerter: new WebhookAlerter(fetchFn, 'https://hooks.example', logger, { cache, clock }),
    };
  }

  it('sends each bucket at most once per hour, keyed alert:last:{bucket}', async () => {
    const clock = new FixedClock('2026-09-26T10:00:00Z');
    const { posts, logger, alerter: a } = alerter(clock);
    await a.send({ kind: 'error_rate', message: 'first' });
    clock.advance({ minutes: 59 });
    await a.send({ kind: 'error_rate', message: 'suppressed' });
    await a.send({ kind: 'reading_failed_rate', message: 'other kind' });
    await a.send({ kind: 'budget_tier', message: 'soft', dedupeKey: 'budget_tier:soft' });
    await a.send({ kind: 'budget_tier', message: 'hard', dedupeKey: 'budget_tier:hard' });
    clock.advance({ minutes: 1 });
    await a.send({ kind: 'error_rate', message: 'an hour later' });

    expect(posts.map((p) => (JSON.parse(p) as { text: string }).text)).toEqual([
      '[taro-api] error_rate: first',
      '[taro-api] reading_failed_rate: other kind',
      '[taro-api] budget_tier: soft',
      '[taro-api] budget_tier: hard',
      '[taro-api] error_rate: an hour later',
    ]);
    expect(logger.find('alert_suppressed').map((e) => e.fields)).toEqual([
      { kind: 'error_rate', bucket: 'error_rate' },
    ]);
    expect(await cache.get(alertDedupeKey('error_rate'))).toBe('2026-09-26T11:00:00.000Z');
    expect(ALERT_DEDUPE_SEC).toBe(3600);
  });

  it('fails open when CACHE_KV is unavailable', async () => {
    const logger = new CapturingLogger();
    const posts: unknown[] = [];
    const broken = {
      get: () => Promise.reject(new TypeError('kv down')),
      put: () => Promise.reject(new Error('kv down')),
    } as unknown as KVNamespace;
    const a = new WebhookAlerter(
      (_url, init) => {
        posts.push(init.body);
        return Promise.resolve(new Response('ok'));
      },
      'https://hooks.example',
      logger,
      { cache: broken, clock: new FixedClock() },
    );
    await a.send({ kind: 'sandbox_volume', message: 'x' });
    const nonError = {
      // eslint-disable-next-line @typescript-eslint/prefer-promise-reject-errors -- non-Error rejection path
      get: () => Promise.reject('down'),
    } as unknown as KVNamespace;
    await new WebhookAlerter(() => Promise.resolve(new Response('ok')), undefined, logger, {
      cache: nonError,
      clock: new FixedClock(),
    }).send({ kind: 'sandbox_volume', message: 'y' });

    expect(posts).toHaveLength(1);
    expect(logger.find('alert_dedupe_failed').map((e) => e.fields)).toEqual([
      { bucket: 'sandbox_volume', error: 'TypeError' },
      { bucket: 'sandbox_volume', error: 'unknown' },
    ]);
  });
});

describe('unimplementedPort', () => {
  it('rejects every method with the port, method and phase', async () => {
    const port = unimplementedPort<{ doIt(): Promise<void> }>('Thing', 'Phase 9');
    await expect(port.doIt()).rejects.toThrow('Thing.doIt is not implemented until Phase 9');
  });

  it('is not a thenable and has no symbol members', () => {
    const port = unimplementedPort<Record<string | symbol, unknown>>('Thing', 'Phase 9');
    expect(port['then']).toBeUndefined();
    expect(port[Symbol.iterator]).toBeUndefined();
  });
});

describe('test fakes', () => {
  it('CapturingLogger.expectNoSensitive flags given values, JWTs and bearer tokens', () => {
    const logger = new CapturingLogger();
    logger.log('info', 'ok', { route: 'GET /v1/balance' });
    expect(() => {
      logger.expectNoSensitive('topsecret');
    }).not.toThrow();

    logger.log('info', 'bad', { note: 'contains topsecret here' });
    expect(() => {
      logger.expectNoSensitive('topsecret', '');
    }).toThrow('sensitive value');

    const jwt = new CapturingLogger();
    jwt.log('info', 'bad', { t: 'eyJhbGciOi.eyJzdWIiOi.sig' });
    expect(() => {
      jwt.expectNoSensitive();
    }).toThrow('eyJ');

    const bearer = new CapturingLogger();
    bearer.log('warn', 'bad', { h: 'Bearer abc' });
    expect(() => {
      bearer.expectNoSensitive();
    }).toThrow('bearer');
  });

  it('InMemoryMetrics, CapturingAlerter and FakeRateLimiter record calls', async () => {
    const metrics = new InMemoryMetrics();
    metrics.write({ event: 'rate_limited' });
    metrics.write({ event: 'attest_failed' });
    expect(metrics.events()).toEqual(['rate_limited', 'attest_failed']);
    expect(metrics.count('rate_limited')).toBe(1);

    const alerter = new CapturingAlerter();
    await alerter.send({ kind: 'error_rate', message: 'm' });
    expect(alerter.alerts).toHaveLength(1);

    const limiter = new FakeRateLimiter(1);
    expect(await limiter.limit({ key: 'a' })).toEqual({ success: true });
    expect(await limiter.limit({ key: 'a' })).toEqual({ success: false });
    expect(await limiter.limit({ key: 'b' })).toEqual({ success: true });
  });
});
