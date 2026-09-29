/** `ai_spend_daily` (03 §4, §10.1): model spend per UTC day for the budget tiers. */
export interface DailySpend {
  readonly dateUtc: string;
  readonly readings: number;
  readonly costMicroUsd: number;
}

export class SpendRepo {
  constructor(private readonly db: D1Database) {}

  /** One model call's cost (03 §10.1): `readings + 1`, `cost_micro_usd + cost`. */
  addStmt(dateUtc: string, costMicroUsd: number): D1PreparedStatement {
    return this.db
      .prepare(
        `INSERT INTO ai_spend_daily (date_utc, readings, cost_micro_usd) VALUES (?1, 1, ?2)
         ON CONFLICT (date_utc) DO UPDATE SET
           readings = readings + 1,
           cost_micro_usd = cost_micro_usd + excluded.cost_micro_usd`,
      )
      .bind(dateUtc, costMicroUsd);
  }

  async add(dateUtc: string, costMicroUsd: number): Promise<void> {
    await this.addStmt(dateUtc, costMicroUsd).run();
  }

  /** The day's totals (zero when nothing was spent). */
  async get(dateUtc: string): Promise<DailySpend> {
    const row = await this.db
      .prepare(`SELECT readings, cost_micro_usd FROM ai_spend_daily WHERE date_utc = ?1`)
      .bind(dateUtc)
      .first<{ readings: number; cost_micro_usd: number }>();
    return {
      dateUtc,
      readings: row?.readings ?? 0,
      costMicroUsd: row?.cost_micro_usd ?? 0,
    };
  }

  /**
   * Distinct installs with a reading or a balance sync in `[fromIso, toIso)`
   * (the `dau` of 03 §10.2). `last_seen_at` is overwritten on every sync, so
   * this counts installs last seen in the window plus installs with a
   * reading created in it.
   */
  async activeInstalls(fromIso: string, toIso: string): Promise<number> {
    const row = await this.db
      .prepare(
        `SELECT COUNT(*) AS n FROM (
           SELECT id FROM installs WHERE last_seen_at >= ?1 AND last_seen_at < ?2
           UNION
           SELECT install_id FROM readings WHERE created_at >= ?1 AND created_at < ?2)`,
      )
      .bind(fromIso, toIso)
      .first<{ n: number }>();
    return row?.n ?? 0;
  }
}
