import type { AlertKind } from '../ports/Alerter';
import type { MetricEvent } from '../ports/Metrics';
import { numberOrNull, sqlInt } from './d1';

/**
 * Analytics Engine queries for `scripts/metrics.ts` (03 §14.1, 04 §14;
 * Sprint 7.5). Dataset `taro_api_events`; columns by position as written by
 * `AnalyticsEngineMetrics`:
 *
 * | column | field | column | field |
 * |---|---|---|---|
 * | `blob1` / `index1` | event | `double1` | costMicroUsd |
 * | `blob2` | platform | `double2` | latencyMs |
 * | `blob3` | locale | `double3` | inputTokens |
 * | `blob4` | model | `double4` | outputTokens |
 * | `blob5` | promptVersion | `double5` | credits |
 * | `blob6` | chargeSource | | |
 * | `blob7` | code (sub-reason / outcome) | | |
 *
 * Counts are `SUM(_sample_interval)` (Analytics Engine samples at volume).
 * Derived metrics: verify error rate = `purchase_verify` with
 * `code = 'internal'` over all `purchase_verify`; `ssv_grant_lag_ms` =
 * quantiles of `reward_granted.latencyMs` (AdMob `timestamp` → grant);
 * `ssv_rejected{reason}` = `reward_rejected` by `code`.
 *
 * The same rules back the Phase 8 `AlertService` in the 15-minute cron; until
 * then the owner runs `metrics --query alerts`.
 */
export const DATASET = 'taro_api_events';
export const SQL_API = (accountId: string): string =>
  `https://api.cloudflare.com/client/v4/accounts/${accountId}/analytics_engine/sql`;

function since(minutes: number): string {
  return `timestamp > NOW() - INTERVAL '${sqlInt(minutes)}' MINUTE`;
}

function eventIn(events: readonly MetricEvent[]): string {
  return `blob1 IN (${events.map((e) => `'${e}'`).join(', ')})`;
}

export const QUERY_NAMES = ['events', 'verify', 'purchases', 'rewards', 'ssv-lag'] as const;
export type QueryName = (typeof QUERY_NAMES)[number];

export function isQueryName(value: string): value is QueryName {
  return (QUERY_NAMES as readonly string[]).includes(value);
}

/** The SQL of a named report over the last `minutes`. */
export function querySql(name: QueryName, minutes: number): string {
  const window = since(minutes);
  switch (name) {
    case 'events':
      return `SELECT blob1 AS event, SUM(_sample_interval) AS n FROM ${DATASET} WHERE ${window} GROUP BY event ORDER BY n DESC`;
    case 'verify':
      return `SELECT blob2 AS platform, blob7 AS outcome, SUM(_sample_interval) AS n, quantileExactWeighted(0.95)(double2, _sample_interval) AS p95_ms FROM ${DATASET} WHERE blob1 = 'purchase_verify' AND ${window} GROUP BY platform, outcome ORDER BY platform, outcome`;
    case 'purchases':
      return `SELECT blob1 AS event, blob2 AS platform, blob7 AS code, SUM(_sample_interval) AS n, SUM(double5 * _sample_interval) AS credits FROM ${DATASET} WHERE ${eventIn(['purchase_granted', 'purchase_revoked', 'sandbox_grant', 'blocked_purchase'])} AND ${window} GROUP BY event, platform, code ORDER BY event, platform, code`;
    case 'rewards':
      return `SELECT blob1 AS event, blob7 AS code, SUM(_sample_interval) AS n FROM ${DATASET} WHERE ${eventIn(['reward_issued', 'reward_granted', 'reward_rejected'])} AND ${window} GROUP BY event, code ORDER BY event, code`;
    case 'ssv-lag':
      return `SELECT SUM(_sample_interval) AS n, quantileExactWeighted(0.5)(double2, _sample_interval) AS p50_ms, quantileExactWeighted(0.95)(double2, _sample_interval) AS p95_ms FROM ${DATASET} WHERE blob1 = 'reward_granted' AND double2 > 0 AND ${window}`;
  }
}

export type Row = Readonly<Record<string, unknown>>;

/** `data` of an Analytics Engine SQL API JSON response. */
export function parseSqlResponse(body: unknown): Row[] {
  const data = (body as { data?: unknown } | null)?.data;
  if (!Array.isArray(data)) {
    throw new Error('Analytics Engine response has no data array');
  }
  return data as Row[];
}

/** Rows as aligned `key=value` lines (numbers rounded). */
export function formatRows(rows: readonly Row[]): string[] {
  if (rows.length === 0) {
    return ['(no rows)'];
  }
  return rows.map((row) =>
    Object.entries(row)
      .map(([key, value]) => {
        const n = numberOrNull(value);
        return `${key}=${n === null ? String(value) : String(Math.round(n * 100) / 100)}`;
      })
      .join('  '),
  );
}

/** Thresholds (03 §14.1, 04 §12.3, §14; RC63). */
export const ALERT_THRESHOLDS = {
  /** Verify error rate > 2 % over 10 minutes (04 §12.3), from at least 3 errors. */
  verifyErrorRatePct: 2,
  verifyWindowMinutes: 10,
  verifyMinErrors: 3,
  /** `ssv_rejected` spike: ≥ 10 rejections and > 20 % of signed callbacks in 15 minutes. */
  ssvRejectedMin: 10,
  ssvRejectedRatePct: 20,
  ssvWindowMinutes: 15,
  /** Sandbox volume: half of `purchases.sandboxGlobalCreditsPerDay` within 24 hours. */
  sandboxWindowMinutes: 24 * 60,
  /** Any grant to a blocked or indebted install in the last hour (03 §6.5). */
  blockedWindowMinutes: 60,
} as const;

export interface AlertRule {
  readonly kind: Extract<
    AlertKind,
    'verify_error_rate' | 'ssv_rejected_spike' | 'sandbox_volume' | 'blocked_purchase'
  >;
  readonly sql: string;
  evaluate(rows: readonly Row[]): string | null;
}

function first(rows: readonly Row[], key: string): number {
  return numberOrNull(rows[0]?.[key]) ?? 0;
}

/** Alert rules; `evaluate` returns the alert message on a breach, else null. */
export function alertRules(options: { readonly sandboxGlobalCreditsPerDay: number }): AlertRule[] {
  const t = ALERT_THRESHOLDS;
  return [
    {
      kind: 'verify_error_rate',
      sql: `SELECT SUM(_sample_interval) AS total, sumIf(_sample_interval, blob7 = 'internal') AS errors FROM ${DATASET} WHERE blob1 = 'purchase_verify' AND ${since(t.verifyWindowMinutes)}`,
      evaluate(rows) {
        const total = first(rows, 'total');
        const errors = first(rows, 'errors');
        const pct = total > 0 ? (errors * 100) / total : 0;
        return errors >= t.verifyMinErrors && pct > t.verifyErrorRatePct
          ? `verify error rate ${pct.toFixed(1)} % (${String(errors)}/${String(total)}) over ${String(t.verifyWindowMinutes)} min`
          : null;
      },
    },
    {
      kind: 'ssv_rejected_spike',
      sql: `SELECT sumIf(_sample_interval, blob1 = 'reward_rejected') AS rejected, sumIf(_sample_interval, blob1 = 'reward_granted') AS granted FROM ${DATASET} WHERE ${eventIn(['reward_rejected', 'reward_granted'])} AND ${since(t.ssvWindowMinutes)}`,
      evaluate(rows) {
        const rejected = first(rows, 'rejected');
        const total = rejected + first(rows, 'granted');
        const pct = total > 0 ? (rejected * 100) / total : 0;
        return rejected >= t.ssvRejectedMin && pct > t.ssvRejectedRatePct
          ? `ssv_rejected spike: ${String(rejected)} of ${String(total)} callbacks (${pct.toFixed(1)} %) in ${String(t.ssvWindowMinutes)} min`
          : null;
      },
    },
    {
      kind: 'sandbox_volume',
      sql: `SELECT SUM(double5 * _sample_interval) AS credits FROM ${DATASET} WHERE blob1 = 'sandbox_grant' AND ${since(t.sandboxWindowMinutes)}`,
      evaluate(rows) {
        const credits = first(rows, 'credits');
        return credits * 2 >= options.sandboxGlobalCreditsPerDay
          ? `sandbox/test grants: ${String(credits)} of ${String(options.sandboxGlobalCreditsPerDay)} credits in 24 h`
          : null;
      },
    },
    {
      kind: 'blocked_purchase',
      sql: `SELECT SUM(_sample_interval) AS n FROM ${DATASET} WHERE blob1 = 'blocked_purchase' AND ${since(t.blockedWindowMinutes)}`,
      evaluate(rows) {
        const n = first(rows, 'n');
        return n > 0
          ? `${String(n)} purchase(s) granted to blocked or indebted installs in the last hour; consider a store refund`
          : null;
      },
    },
  ];
}
