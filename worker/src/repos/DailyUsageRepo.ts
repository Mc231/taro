/**
 * `daily_usage` (03 §4, §5.2, §5.3). One row per install and local date,
 * created lazily on first use. `free_limit` snapshots `readings.freeDaily`
 * and only ever rises within a day, so `CHECK (free_used <= free_limit)`
 * always holds.
 */
export interface DailyUsageRow {
  readonly installId: string;
  readonly localDate: string;
  readonly freeLimit: number;
  readonly freeUsed: number;
  readonly rewardedGranted: number;
  readonly readingsTotal: number;
  readonly declinedCount: number;
}

interface RawUsage {
  install_id: string;
  local_date: string;
  free_limit: number;
  free_used: number;
  rewarded_granted: number;
  readings_total: number;
  declined_count: number;
}

export interface UsageDay {
  readonly installId: string;
  readonly localDate: string;
}

export class DailyUsageRepo {
  constructor(private readonly db: D1Database) {}

  async find(day: UsageDay): Promise<DailyUsageRow | null> {
    const raw = await this.findStmt(day).first<RawUsage>();
    return raw === null ? null : toUsage(raw);
  }

  /** `find` as a batch statement; map the row with `DailyUsageRepo.parse`. */
  findStmt(day: UsageDay): D1PreparedStatement {
    return this.db
      .prepare(`SELECT * FROM daily_usage WHERE install_id = ?1 AND local_date = ?2`)
      .bind(day.installId, day.localDate);
  }

  static parse(raw: unknown): DailyUsageRow {
    return toUsage(raw as RawUsage);
  }

  /**
   * Creates today's row with the `free_limit` snapshot, or raises an existing
   * snapshot to `freeLimit` (increases apply immediately, decreases wait for
   * tomorrow, 03 §5.2).
   */
  ensureStmt(day: UsageDay, freeLimit: number): D1PreparedStatement {
    return this.db
      .prepare(
        `INSERT INTO daily_usage (install_id, local_date, free_limit) VALUES (?1, ?2, ?3)
         ON CONFLICT (install_id, local_date) DO UPDATE SET
           free_limit = MAX(free_limit, excluded.free_limit)`,
      )
      .bind(day.installId, day.localDate, freeLimit);
  }

  /**
   * Takes one free reading (03 §5.3 step 1): applies only while
   * `free_used < MAX(free_limit, current)`; `changes == 0` means no free
   * reading is left today.
   */
  takeFreeStmt(day: UsageDay, currentFreeDaily: number): D1PreparedStatement {
    return this.db
      .prepare(
        `INSERT INTO daily_usage (install_id, local_date, free_limit, free_used, readings_total)
         VALUES (?1, ?2, ?3, 1, 1)
         ON CONFLICT (install_id, local_date) DO UPDATE SET
           free_limit = MAX(free_limit, excluded.free_limit),
           free_used = free_used + 1,
           readings_total = readings_total + 1
         WHERE free_used < MAX(free_limit, excluded.free_limit)`,
      )
      .bind(day.installId, day.localDate, currentFreeDaily);
  }

  /** Gives a free reading back on the date the hold was taken (never "today", 03 §5.3 step 3). */
  refundFreeStmt(day: UsageDay): D1PreparedStatement {
    return this.db
      .prepare(
        `UPDATE daily_usage SET free_used = free_used - 1, readings_total = readings_total - 1
          WHERE install_id = ?1 AND local_date = ?2 AND free_used > 0`,
      )
      .bind(day.installId, day.localDate);
  }

  /** `readings_total + 1` for a bonus or paid hold (the free path counts itself). */
  countReadingStmt(day: UsageDay, freeLimit: number): D1PreparedStatement {
    return this.db
      .prepare(
        `INSERT INTO daily_usage (install_id, local_date, free_limit, readings_total)
         VALUES (?1, ?2, ?3, 1)
         ON CONFLICT (install_id, local_date) DO UPDATE SET readings_total = readings_total + 1`,
      )
      .bind(day.installId, day.localDate, freeLimit);
  }

  /** `rewarded_granted + 1` (a grant, not credits; 03 §7). */
  rewardedGrantStmt(day: UsageDay, freeLimit: number): D1PreparedStatement {
    return this.db
      .prepare(
        `INSERT INTO daily_usage (install_id, local_date, free_limit, rewarded_granted)
         VALUES (?1, ?2, ?3, 1)
         ON CONFLICT (install_id, local_date) DO UPDATE SET rewarded_granted = rewarded_granted + 1`,
      )
      .bind(day.installId, day.localDate, freeLimit);
  }

  /** `declined_count + 1` (safety refusals, `safety.maxDeclinedPerDay`). */
  declinedStmt(day: UsageDay): D1PreparedStatement {
    return this.db
      .prepare(
        `UPDATE daily_usage SET declined_count = declined_count + 1
          WHERE install_id = ?1 AND local_date = ?2`,
      )
      .bind(day.installId, day.localDate);
  }

  /** Erasure: every row except today's (03 §3.6, RC37). */
  erasePastStmt(installId: string, today: string): D1PreparedStatement {
    return this.db
      .prepare(`DELETE FROM daily_usage WHERE install_id = ?1 AND local_date <> ?2`)
      .bind(installId, today);
  }

  /** Retention (90 days, 03 §13): rows before `cutoffDate`, at most `limit`. */
  async purgeBefore(cutoffDate: string, limit = 500): Promise<number> {
    const result = await this.db
      .prepare(
        `DELETE FROM daily_usage WHERE rowid IN
           (SELECT rowid FROM daily_usage WHERE local_date < ?1 LIMIT ?2)`,
      )
      .bind(cutoffDate, limit)
      .run();
    return result.meta.changes;
  }
}

function toUsage(raw: RawUsage): DailyUsageRow {
  return {
    installId: raw.install_id,
    localDate: raw.local_date,
    freeLimit: raw.free_limit,
    freeUsed: raw.free_used,
    rewardedGranted: raw.rewarded_granted,
    readingsTotal: raw.readings_total,
    declinedCount: raw.declined_count,
  };
}
