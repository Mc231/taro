import { SAFETY_POLICY } from '../domain/safetyPolicy';
import type { RefusalCategory } from '../domain/types';

/**
 * Read-only aggregates for the owner's Telegram stats bot
 * (`POST /v1/admin/telegram`, 03 §14.3). Every query is a `SELECT` over a
 * UTC-day window `[fromIso, toIso)` grouped by UTC day (`YYYY-MM-DD`, the
 * first 10 characters of the ISO timestamps); nothing here returns an
 * install ID, a question, a reading or any other per-user value.
 */
export interface DayStats {
  readonly day: string;
  readonly completed: number;
  readonly declined: number;
  readonly failed: number;
  /** Readings whose hold was refunded (`hold_state = 'refunded'`). */
  readonly refunded: number;
  /** Declined readings in a category that shows crisis resources (`self_harm`, `harm_to_others`). */
  readonly crisis: number;
  /** Sum of `readings.cost_micro_usd` over completed readings with a cost. */
  readonly completedCostMicroUsd: number;
  readonly costedCompleted: number;
  /** `ai_spend_daily.cost_micro_usd` (all model calls of the day). */
  readonly spendMicroUsd: number;
  readonly newInstalls: number;
  /** Installs last seen or with a reading created that day (the budget `dau` definition). */
  readonly active: number;
  /** Production, non-test purchases granted that day, per product ID. */
  readonly purchases: Readonly<Record<string, number>>;
  /** Sandbox or test purchases granted that day. */
  readonly sandboxPurchases: number;
  /** Production, non-test purchases revoked (refunded) that day. */
  readonly refunds: number;
  /** Rewarded ads granted that day. */
  readonly rewarded: number;
}

/** Refusal categories whose decline carries crisis resources (03 §9.4). */
export const CRISIS_CATEGORIES: readonly RefusalCategory[] = (
  Object.keys(SAFETY_POLICY) as RefusalCategory[]
).filter((category) => SAFETY_POLICY[category].crisisResources);

const CRISIS_SQL = CRISIS_CATEGORIES.map((category) => `'${category}'`).join(',');

interface DayCount {
  readonly day: string;
  readonly n: number;
}

interface ReadingAgg {
  readonly day: string;
  readonly completed: number;
  readonly declined: number;
  readonly failed: number;
  readonly refunded: number;
  readonly crisis: number;
  readonly cost: number | null;
  readonly costed: number;
}

interface PurchaseAgg {
  readonly day: string;
  readonly product_id: string;
  readonly sandbox: number;
  readonly n: number;
}

export function emptyDayStats(day: string): DayStats {
  return {
    day,
    completed: 0,
    declined: 0,
    failed: 0,
    refunded: 0,
    crisis: 0,
    completedCostMicroUsd: 0,
    costedCompleted: 0,
    spendMicroUsd: 0,
    newInstalls: 0,
    active: 0,
    purchases: {},
    sandboxPurchases: 0,
    refunds: 0,
    rewarded: 0,
  };
}

const DAY_MS = 86_400_000;

/** The UTC days `[firstDay, firstDay + count)` as `YYYY-MM-DD`. */
export function utcDays(firstDay: string, count: number): string[] {
  const start = Date.parse(`${firstDay}T00:00:00.000Z`);
  return Array.from({ length: count }, (_, i) =>
    new Date(start + i * DAY_MS).toISOString().slice(0, 10),
  );
}

export class StatsRepo {
  constructor(private readonly db: D1Database) {}

  /** One `DayStats` per UTC day from `firstDay`, `count` days, in one D1 batch. */
  async days(firstDay: string, count: number): Promise<DayStats[]> {
    const days = utcDays(firstDay, count);
    const from = `${firstDay}T00:00:00.000Z`;
    const to = new Date(Date.parse(from) + count * DAY_MS).toISOString();
    const [readings, spend, installs, active, purchases, refunds, rewarded] = await this.db.batch([
      this.db
        .prepare(
          `SELECT substr(created_at, 1, 10) AS day,
                  SUM(status = 'completed') AS completed,
                  SUM(status = 'declined') AS declined,
                  SUM(status = 'failed') AS failed,
                  SUM(hold_state = 'refunded') AS refunded,
                  SUM(status = 'declined' AND safety_category IN (${CRISIS_SQL})) AS crisis,
                  SUM(CASE WHEN status = 'completed' THEN cost_micro_usd END) AS cost,
                  SUM(status = 'completed' AND cost_micro_usd IS NOT NULL) AS costed
           FROM readings WHERE created_at >= ?1 AND created_at < ?2 GROUP BY day`,
        )
        .bind(from, to),
      this.db
        .prepare(
          `SELECT date_utc AS day, cost_micro_usd AS n FROM ai_spend_daily
           WHERE date_utc >= ?1 AND date_utc < ?2`,
        )
        .bind(firstDay, to.slice(0, 10)),
      this.db
        .prepare(
          `SELECT substr(created_at, 1, 10) AS day, COUNT(*) AS n FROM installs
           WHERE created_at >= ?1 AND created_at < ?2 GROUP BY day`,
        )
        .bind(from, to),
      this.db
        .prepare(
          `SELECT day, COUNT(DISTINCT id) AS n FROM (
             SELECT substr(last_seen_at, 1, 10) AS day, id FROM installs
             WHERE last_seen_at >= ?1 AND last_seen_at < ?2
             UNION
             SELECT substr(created_at, 1, 10) AS day, install_id AS id FROM readings
             WHERE created_at >= ?1 AND created_at < ?2)
           GROUP BY day`,
        )
        .bind(from, to),
      this.db
        .prepare(
          `SELECT substr(granted_at, 1, 10) AS day, product_id,
                  (environment = 'sandbox' OR is_test = 1) AS sandbox, COUNT(*) AS n
           FROM purchases WHERE granted_at >= ?1 AND granted_at < ?2
           GROUP BY day, product_id, sandbox`,
        )
        .bind(from, to),
      this.db
        .prepare(
          `SELECT substr(revoked_at, 1, 10) AS day, COUNT(*) AS n FROM purchases
           WHERE revoked_at >= ?1 AND revoked_at < ?2
             AND environment = 'production' AND is_test = 0
           GROUP BY day`,
        )
        .bind(from, to),
      this.db
        .prepare(
          `SELECT substr(granted_at, 1, 10) AS day, COUNT(*) AS n FROM ad_rewards
           WHERE status = 'granted' AND granted_at >= ?1 AND granted_at < ?2 GROUP BY day`,
        )
        .bind(from, to),
    ]);
    const byDay = new Map<string, MutableDay>();
    const at = (day: string): MutableDay => {
      let s = byDay.get(day);
      if (s === undefined) {
        s = { ...emptyDayStats(day) };
        byDay.set(day, s);
      }
      return s;
    };
    for (const r of rows<ReadingAgg>(readings)) {
      const s = at(r.day);
      s.completed = r.completed;
      s.declined = r.declined;
      s.failed = r.failed;
      s.refunded = r.refunded;
      s.crisis = r.crisis;
      s.completedCostMicroUsd = r.cost ?? 0;
      s.costedCompleted = r.costed;
    }
    const counts = (result: D1Result | undefined, apply: (s: MutableDay, n: number) => void) => {
      for (const r of rows<DayCount>(result)) {
        apply(at(r.day), r.n);
      }
    };
    counts(spend, (s, n) => (s.spendMicroUsd = n));
    counts(installs, (s, n) => (s.newInstalls = n));
    counts(active, (s, n) => (s.active = n));
    counts(refunds, (s, n) => (s.refunds = n));
    counts(rewarded, (s, n) => (s.rewarded = n));
    for (const r of rows<PurchaseAgg>(purchases)) {
      const s = at(r.day);
      if (r.sandbox === 1) {
        s.sandboxPurchases += r.n;
      } else {
        s.purchases = { ...s.purchases, [r.product_id]: (s.purchases[r.product_id] ?? 0) + r.n };
      }
    }
    return days.map((day) => byDay.get(day) ?? emptyDayStats(day));
  }
}

type MutableDay = { -readonly [K in keyof DayStats]: DayStats[K] };

function rows<T>(result: D1Result | undefined): T[] {
  return (result?.results ?? []) as T[];
}
