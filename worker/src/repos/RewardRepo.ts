/** `ad_rewards` (03 §4, §7; RC56, RC57): reward intents and their SSV grants. */
export type RewardStatus = 'issued' | 'granted' | 'cancelled' | 'expired' | 'rejected';

export interface NewReward {
  /** `intentId` (opaque, 128-bit random, base64url). */
  readonly id: string;
  readonly installId: string;
  readonly localDate: string;
  /** Snapshot of `rewarded.amount` at issue. */
  readonly amount: number;
  readonly adUnit?: string | null;
  readonly issuedAt: string;
  readonly expiresAt: string;
}

export interface RewardRow extends Omit<NewReward, 'adUnit'> {
  readonly status: RewardStatus;
  readonly adUnit: string | null;
  readonly admobTxnId: string | null;
  readonly rejectReason: string | null;
  readonly grantedAt: string | null;
}

interface RawReward {
  id: string;
  install_id: string;
  local_date: string;
  status: RewardStatus;
  amount: number;
  ad_unit: string | null;
  admob_txn_id: string | null;
  reject_reason: string | null;
  issued_at: string;
  expires_at: string;
  granted_at: string | null;
}

export class RewardRepo {
  constructor(private readonly db: D1Database) {}

  insertStmt(input: NewReward): D1PreparedStatement {
    return this.db
      .prepare(
        `INSERT INTO ad_rewards (id, install_id, local_date, status, amount, ad_unit, issued_at, expires_at)
         VALUES (?1, ?2, ?3, 'issued', ?4, ?5, ?6, ?7)`,
      )
      .bind(
        input.id,
        input.installId,
        input.localDate,
        input.amount,
        input.adUnit ?? null,
        input.issuedAt,
        input.expiresAt,
      );
  }

  async insert(input: NewReward): Promise<void> {
    await this.insertStmt(input).run();
  }

  async findById(id: string): Promise<RewardRow | null> {
    const raw = await this.db
      .prepare(`SELECT * FROM ad_rewards WHERE id = ?1`)
      .bind(id)
      .first<RawReward>();
    return raw === null ? null : toReward(raw);
  }

  /** `issued → granted` for an unexpired intent (CAS); `admob_txn_id` is UNIQUE. */
  grantStmt(input: {
    readonly id: string;
    readonly admobTxnId: string;
    readonly adUnit: string;
    readonly now: string;
  }): D1PreparedStatement {
    return this.db
      .prepare(
        `UPDATE ad_rewards SET status = 'granted', admob_txn_id = ?2, ad_unit = ?3, granted_at = ?4
          WHERE id = ?1 AND status = 'issued' AND expires_at > ?4`,
      )
      .bind(input.id, input.admobTxnId, input.adUnit, input.now);
  }

  /** `issued → cancelled` (client cancel, 03 §7.3). */
  async cancel(id: string, installId: string): Promise<boolean> {
    const result = await this.db
      .prepare(
        `UPDATE ad_rewards SET status = 'cancelled' WHERE id = ?1 AND install_id = ?2 AND status = 'issued'`,
      )
      .bind(id, installId)
      .run();
    return result.meta.changes === 1;
  }

  /** `issued → rejected` with a reason (SSV check failed). */
  async reject(id: string, reason: string): Promise<boolean> {
    const result = await this.db
      .prepare(
        `UPDATE ad_rewards SET status = 'rejected', reject_reason = ?2 WHERE id = ?1 AND status = 'issued'`,
      )
      .bind(id, reason)
      .run();
    return result.meta.changes === 1;
  }

  /** Expires issued intents past `expires_at` (15-minute cron, 03 §12). */
  async expireDue(now: string, limit = 500): Promise<number> {
    const result = await this.db
      .prepare(
        `UPDATE ad_rewards SET status = 'expired' WHERE rowid IN
           (SELECT rowid FROM ad_rewards WHERE status = 'issued' AND expires_at <= ?1 LIMIT ?2)`,
      )
      .bind(now, limit)
      .run();
    return result.meta.changes;
  }

  /** The latest grant time of an install (`rewarded.cooldownSec`, RC57). */
  async lastGrantedAt(installId: string): Promise<string | null> {
    const row = await this.lastGrantedAtStmt(installId).first<{ last: string | null }>();
    return row?.last ?? null;
  }

  /** `lastGrantedAt` as a batch statement: one row `{ last: string | null }`. */
  lastGrantedAtStmt(installId: string): D1PreparedStatement {
    return this.db
      .prepare(
        `SELECT MAX(granted_at) AS last FROM ad_rewards WHERE install_id = ?1 AND status = 'granted'`,
      )
      .bind(installId);
  }

  /** Erasure (RC37). */
  eraseStmt(installId: string): D1PreparedStatement {
    return this.db.prepare(`DELETE FROM ad_rewards WHERE install_id = ?1`).bind(installId);
  }
}

function toReward(raw: RawReward): RewardRow {
  return {
    id: raw.id,
    installId: raw.install_id,
    localDate: raw.local_date,
    status: raw.status,
    amount: raw.amount,
    adUnit: raw.ad_unit,
    admobTxnId: raw.admob_txn_id,
    rejectReason: raw.reject_reason,
    issuedAt: raw.issued_at,
    expiresAt: raw.expires_at,
    grantedAt: raw.granted_at,
  };
}
