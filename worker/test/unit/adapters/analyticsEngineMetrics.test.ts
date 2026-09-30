import { describe, expect, it } from 'vitest';
import {
  AnalyticsEngineMetrics,
  countsSql,
  parseCounts,
  type SqlFetch,
} from '../../../src/adapters/cf/AnalyticsEngineMetrics';
import { metricsSqlAccess } from '../../../src/deps';
import type { Env } from '../../../src/env';
import { CapturingLogger } from '../../fakes/CapturingLogger';

const dataset: AnalyticsEngineDataset = { writeDataPoint: () => undefined };

function withFetch(fetch: SqlFetch) {
  const logger = new CapturingLogger();
  const metrics = new AnalyticsEngineMetrics(dataset, {
    accountId: 'acc123',
    token: 'test-token',
    fetch,
    logger,
  });
  return { metrics, logger };
}

describe('AnalyticsEngineMetrics.counts (03 §14.1)', () => {
  it('builds a bounded, sample-weighted SQL query', () => {
    expect(countsSql({ events: ['http_response', 'reading_failed'], windowMinutes: 15 })).toBe(
      "SELECT blob1 AS event, blob7 AS code, SUM(_sample_interval) AS n FROM taro_api_events WHERE blob1 IN ('http_response', 'reading_failed') AND timestamp > NOW() - INTERVAL '15' MINUTE GROUP BY event, code",
    );
    expect(countsSql({ events: ['reading_failed'], windowMinutes: 0.2 })).toContain("'1' MINUTE");
    expect(countsSql({ events: ['reading_failed'], windowMinutes: 1e9 })).toContain(
      "'10080' MINUTE",
    );
    expect(() => countsSql({ events: [], windowMinutes: 15 })).toThrow(RangeError);
  });

  it('posts the SQL with the bearer token and parses the rows', async () => {
    const calls: { url: string; init: RequestInit }[] = [];
    const { metrics } = withFetch((url, init) => {
      calls.push({ url, init });
      return Promise.resolve(
        Response.json({
          data: [
            { event: 'http_response', code: '500', n: '4' },
            { event: 'reading_failed', code: null, n: 2 },
          ],
        }),
      );
    });
    const counts = await metrics.counts({ events: ['http_response'], windowMinutes: 15 });
    expect(counts).toEqual([
      { event: 'http_response', code: '500', count: 4 },
      { event: 'reading_failed', code: '', count: 2 },
    ]);
    expect(calls[0]?.url).toBe(
      'https://api.cloudflare.com/client/v4/accounts/acc123/analytics_engine/sql',
    );
    expect(calls[0]?.init.method).toBe('POST');
    expect(calls[0]?.init.headers).toEqual({ authorization: 'Bearer test-token' });
  });

  it('returns null (and logs) on an HTTP error, a network error or a malformed body', async () => {
    const failing = withFetch(() => Promise.resolve(new Response('no', { status: 403 })));
    expect(await failing.metrics.counts({ events: ['http_response'], windowMinutes: 15 })).toBe(
      null,
    );
    expect(failing.logger.find('metrics_query_failed').map((e) => e.fields)).toEqual([
      { status: 403 },
    ]);

    const offline = withFetch(() => Promise.reject(new TypeError('offline')));
    expect(await offline.metrics.counts({ events: ['http_response'], windowMinutes: 15 })).toBe(
      null,
    );
    expect(offline.logger.find('metrics_query_failed').map((e) => e.fields)).toEqual([
      { error: 'TypeError' },
    ]);

    // eslint-disable-next-line @typescript-eslint/prefer-promise-reject-errors -- non-Error rejection path
    const odd = withFetch(() => Promise.reject('x'));
    expect(await odd.metrics.counts({ events: ['http_response'], windowMinutes: 15 })).toBe(null);
    expect(odd.logger.find('metrics_query_failed').map((e) => e.fields)).toEqual([
      { error: 'unknown' },
    ]);

    const malformed = withFetch(() => Promise.resolve(Response.json({ rows: [] })));
    expect(await malformed.metrics.counts({ events: ['http_response'], windowMinutes: 15 })).toBe(
      null,
    );
  });

  it('returns null without SQL access', async () => {
    const metrics = new AnalyticsEngineMetrics(dataset);
    expect(await metrics.counts({ events: ['http_response'], windowMinutes: 15 })).toBe(null);
  });

  it('parseCounts treats a non-numeric n as 0 and rejects a body without data', () => {
    expect(parseCounts({ data: [{ event: 'reading_failed', code: 'x', n: 'NaN' }] })).toEqual([
      { event: 'reading_failed', code: 'x', count: 0 },
    ]);
    expect(() => parseCounts(null)).toThrow(TypeError);
  });

  it('metricsSqlAccess needs both ANALYTICS_ACCOUNT_ID and ANALYTICS_API_TOKEN', () => {
    const logger = new CapturingLogger();
    const base = {} as Env;
    expect(metricsSqlAccess(base, logger)).toBeUndefined();
    expect(metricsSqlAccess({ ...base, ANALYTICS_ACCOUNT_ID: 'acc' }, logger)).toBeUndefined();
    expect(metricsSqlAccess({ ...base, ANALYTICS_API_TOKEN: ' ' }, logger)).toBeUndefined();
    expect(
      metricsSqlAccess(
        { ...base, ANALYTICS_ACCOUNT_ID: ' acc ', ANALYTICS_API_TOKEN: 'tok' },
        logger,
      ),
    ).toMatchObject({ accountId: 'acc', token: 'tok', logger });
  });
});
