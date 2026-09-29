/**
 * `device_daily_usage` (03 §3.7, §4; BE19, RC53). Android only: the free and
 * rewarded counters per `device_key_hash` and local date, shared by every
 * install ID of the same device.
 */
export interface DeviceUsageRow {
  readonly deviceKeyHash: string;
  readonly localDate: string;
  readonly freeUsed: number;
  readonly rewardedGranted: number;
}

interface RawDeviceUsage {
  device_key_hash: string;
  local_date: string;
  free_used: number;
  rewarded_granted: number;
}

export interface DeviceDay {
  readonly deviceKeyHash: string;
  readonly localDate: string;
}

export class DeviceUsageRepo {
  constructor(private readonly db: D1Database) {}

  async find(day: DeviceDay): Promise<DeviceUsageRow | null> {
    const raw = await this.findStmt(day).first<RawDeviceUsage>();
    return raw === null ? null : DeviceUsageRepo.parse(raw);
  }

  /** `find` as a batch statement; map the row with `DeviceUsageRepo.parse`. */
  findStmt(day: DeviceDay): D1PreparedStatement {
    return this.db
      .prepare(`SELECT * FROM device_daily_usage WHERE device_key_hash = ?1 AND local_date = ?2`)
      .bind(day.deviceKeyHash, day.localDate);
  }

  static parse(value: unknown): DeviceUsageRow {
    const raw = value as RawDeviceUsage;
    return {
      deviceKeyHash: raw.device_key_hash,
      localDate: raw.local_date,
      freeUsed: raw.free_used,
      rewardedGranted: raw.rewarded_granted,
    };
  }

  /** One free reading for the device, guarded by `free_used < limit` (03 §5.3 step 1). */
  takeFreeStmt(day: DeviceDay, limit: number): D1PreparedStatement {
    return this.db
      .prepare(
        `INSERT INTO device_daily_usage (device_key_hash, local_date, free_used)
         SELECT ?1, ?2, 1 WHERE ?3 >= 1
         ON CONFLICT (device_key_hash, local_date) DO UPDATE SET free_used = free_used + 1
         WHERE free_used < ?3`,
      )
      .bind(day.deviceKeyHash, day.localDate, limit);
  }

  refundFreeStmt(day: DeviceDay): D1PreparedStatement {
    return this.db
      .prepare(
        `UPDATE device_daily_usage SET free_used = free_used - 1
          WHERE device_key_hash = ?1 AND local_date = ?2 AND free_used > 0`,
      )
      .bind(day.deviceKeyHash, day.localDate);
  }

  rewardedGrantStmt(day: DeviceDay): D1PreparedStatement {
    return this.db
      .prepare(
        `INSERT INTO device_daily_usage (device_key_hash, local_date, rewarded_granted)
         VALUES (?1, ?2, 1)
         ON CONFLICT (device_key_hash, local_date) DO UPDATE SET
           rewarded_granted = rewarded_granted + 1`,
      )
      .bind(day.deviceKeyHash, day.localDate);
  }

  /** Erasure: the device's rows older than today (03 §3.6, GLOSSARY §6). */
  erasePastStmt(deviceKeyHash: string, today: string): D1PreparedStatement {
    return this.db
      .prepare(`DELETE FROM device_daily_usage WHERE device_key_hash = ?1 AND local_date < ?2`)
      .bind(deviceKeyHash, today);
  }

  /** Retention (90 days, 03 §13). */
  async purgeBefore(cutoffDate: string, limit = 500): Promise<number> {
    const result = await this.db
      .prepare(
        `DELETE FROM device_daily_usage WHERE rowid IN
           (SELECT rowid FROM device_daily_usage WHERE local_date < ?1 LIMIT ?2)`,
      )
      .bind(cutoffDate, limit)
      .run();
    return result.meta.changes;
  }
}
