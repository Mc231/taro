import type { Logger } from '../../ports/Logger';
import type { MetricCount, MetricCountQuery, MetricPoint, Metrics } from '../../ports/Metrics';

/** `fetch` as the SQL API client uses it (injected for tests). */
export type SqlFetch = (input: string, init: RequestInit) => Promise<Response>;

/**
 * Read access to the Analytics Engine SQL API (03 §14.1): the account ID and
 * an API token with *Account Analytics: Read* (`ANALYTICS_ACCOUNT_ID`,
 * `ANALYTICS_API_TOKEN`, GLOSSARY §13).
 */
export interface MetricsSqlAccess {
  readonly accountId: string;
  readonly token: string;
  readonly fetch: SqlFetch;
  readonly logger: Logger;
}

export const METRICS_DATASET = 'taro_api_events';

const EVENT_NAME = /^[a-z0-9_]+$/;
const MAX_WINDOW_MINUTES = 7 * 24 * 60;

/** The SQL of `counts(query)`; event names are checked against `[a-z0-9_]+`. */
export function countsSql(query: MetricCountQuery): string {
  const events = query.events.filter((event) => EVENT_NAME.test(event));
  if (events.length === 0) {
    throw new RangeError('counts: no events');
  }
  const minutes = Math.min(MAX_WINDOW_MINUTES, Math.max(1, Math.floor(query.windowMinutes)));
  return (
    `SELECT blob1 AS event, blob7 AS code, SUM(_sample_interval) AS n FROM ${METRICS_DATASET} ` +
    `WHERE blob1 IN (${events.map((e) => `'${e}'`).join(', ')}) ` +
    `AND timestamp > NOW() - INTERVAL '${String(minutes)}' MINUTE GROUP BY event, code`
  );
}

/**
 * `Metrics` over the Analytics Engine dataset `taro_api_events` (03 §14.1).
 * Column order is fixed; `scripts/metrics.ts` queries by position. Without
 * `sql` access `counts` returns null (the alert rules are then skipped).
 */
export class AnalyticsEngineMetrics implements Metrics {
  constructor(
    private readonly dataset: AnalyticsEngineDataset,
    private readonly sql?: MetricsSqlAccess,
  ) {}

  write(point: MetricPoint): void {
    this.dataset.writeDataPoint({
      blobs: [
        point.event,
        point.platform ?? '',
        point.locale ?? '',
        point.model ?? '',
        point.promptVersion ?? '',
        point.chargeSource ?? '',
        point.code ?? '',
      ],
      doubles: [
        point.costMicroUsd ?? 0,
        point.latencyMs ?? 0,
        point.inputTokens ?? 0,
        point.outputTokens ?? 0,
        point.credits ?? 0,
      ],
      indexes: [point.event],
    });
  }

  async counts(query: MetricCountQuery): Promise<readonly MetricCount[] | null> {
    const sql = this.sql;
    if (sql === undefined) {
      return null;
    }
    try {
      const res = await sql.fetch(
        `https://api.cloudflare.com/client/v4/accounts/${sql.accountId}/analytics_engine/sql`,
        {
          method: 'POST',
          headers: { authorization: `Bearer ${sql.token}` },
          body: countsSql(query),
        },
      );
      if (!res.ok) {
        sql.logger.log('error', 'metrics_query_failed', { status: res.status });
        return null;
      }
      return parseCounts(await res.json());
    } catch (err) {
      sql.logger.log('error', 'metrics_query_failed', {
        error: err instanceof Error ? err.name : 'unknown',
      });
      return null;
    }
  }
}

/** `data` rows of the SQL API JSON response → counts (numbers may arrive as strings). */
export function parseCounts(body: unknown): MetricCount[] {
  const data = (body as { data?: unknown } | null)?.data;
  if (!Array.isArray(data)) {
    throw new TypeError('Analytics Engine response has no data array');
  }
  return data.map((row: unknown) => {
    const r = row as Record<string, unknown>;
    return {
      event: String(r['event']) as MetricCount['event'],
      code: typeof r['code'] === 'string' ? r['code'] : '',
      count: Number(r['n']) || 0,
    };
  });
}
