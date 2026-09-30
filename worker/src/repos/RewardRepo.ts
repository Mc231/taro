/**
 * `ad_rewards` (03 §4, §7; RC56, RC57): reward intents and their SSV grants.
 * A `cancelled` row's `expires_at` is its SSV grant deadline: the earlier of
 * the TTL and the 2-minute cancel grace (`domain/rewardRules`).
 */
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
  async cancel(id: string, installId: string, graceUntil?: string): Promise<boolean> {
    const result = await this.cancelStmt(id, installId, graceUntil).run();
    return result.meta.changes === 1;
  }

  /**
   * `cancel` as a batch gate; `graceUntil` lowers `expires_at` to the SSV
   * grant deadline (never raises it).
   */
  cancelStmt(id: string, installId: string, graceUntil?: string): D1PreparedStatement {
    return this.db
      .prepare(
        `UPDATE ad_rewards SET status = 'cancelled', expires_at = MIN(expires_at, COALESCE(?3, expires_at))
          WHERE id = ?1 AND install_id = ?2 AND status = 'issued'`,
      )
      .bind(id, installId, graceUntil ?? null);
  }

  /**
   * Issues an intent only while the cap and cooldown allow it (03 §7.1, RC57),
   * re-checked here so two racing requests cannot both take the last slot:
   * `rewarded_granted + 1 ≤ dailyCap` on the install's and, when given, the
   * device's row for `localDate`, and no grant after `cooldownFrom`.
   */
  issueGateStmt(
    input: NewReward & { readonly adUnit: string },
    limits: {
      readonly dailyCap: number;
      readonly cooldownFrom: string;
      readonly deviceKeyHash: string | null;
    },
  ): D1PreparedStatement {
    return this.db
      .prepare(
        `INSERT INTO ad_rewards (id, install_id, local_date, status, amount, ad_unit, issued_at, expires_at)
         SELECT ?1, ?2, ?3, 'issued', ?4, ?5, ?6, ?7
          WHERE COALESCE((SELECT rewarded_granted FROM daily_usage
                           WHERE install_id = ?2 AND local_date = ?3), 0) + 1 <= ?8
            AND COALESCE((SELECT rewarded_granted FROM device_daily_usage
                           WHERE device_key_hash = ?9 AND local_date = ?3), 0) + 1 <= ?8
            AND NOT EXISTS (SELECT 1 FROM ad_rewards
                             WHERE install_id = ?2 AND status = 'granted' AND granted_at > ?10)`,
      )
      .bind(
        input.id,
        input.installId,
        input.localDate,
        input.amount,
        input.adUnit,
        input.issuedAt,
        input.expiresAt,
        limits.dailyCap,
        limits.deviceKeyHash,
        limits.cooldownFrom,
      );
  }

  /**
   * After `issueGateStmt` in the same batch: cancels every other open intent
   * of the install (at most one open intent, RC57), each with its grace
   * deadline, only if the new intent exists. May change zero rows, so it is
   * guarded by that `EXISTS` rather than `PREV_APPLIED` and goes last.
   */
  cancelOthersAfterStmt(input: {
    readonly installId: string;
    readonly keepId: string;
    readonly graceUntil: string;
  }): D1PreparedStatement {
    return this.db
      .prepare(
        `UPDATE ad_rewards SET status = 'cancelled', expires_at = MIN(expires_at, ?3)
          WHERE install_id = ?1 AND status = 'issued' AND id <> ?2
            AND EXISTS (SELECT 1 FROM ad_rewards WHERE id = ?2)`,
      )
      .bind(input.installId, input.keepId, input.graceUntil);
  }

  /**
   * The SSV grant gate (03 §7.2 step 4, RC57): `issued` or `cancelled` (within
   * its grace deadline) and unexpired → `granted`. No cap or cooldown here.
   * `admob_txn_id` is UNIQUE, so a transaction reused on another intent
   * aborts the batch.
   */
  grantGateStmt(input: {
    readonly id: string;
    readonly admobTxnId: string;
    readonly adUnit: string;
    readonly now: string;
  }): D1PreparedStatement {
    return this.db
      .prepare(
        `UPDATE ad_rewards SET status = 'granted', admob_txn_id = ?2, ad_unit = ?3, granted_at = ?4
          WHERE id = ?1 AND status IN ('issued','cancelled') AND expires_at > ?4`,
      )
      .bind(input.id, input.admobTxnId, input.adUnit, input.now);
  }

  /** The intent that carries `admobTxnId`, if any (SSV dedupe). */
  async findByTxn(admobTxnId: string): Promise<RewardRow | null> {
    const raw = await this.db
      .prepare(`SELECT * FROM ad_rewards WHERE admob_txn_id = ?1`)
      .bind(admobTxnId)
      .first<RawReward>();
    return raw === null ? null : toReward(raw);
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

  /**
   * Expires issued intents past `expires_at` (15-minute cron, 03 §12), at most
   * `limit`, and bumps `state_version` of their installs in the same batch
   * (RC67). Both statements pick the same rows (lowest `rowid` first).
   */
  async expireDue(now: string, limit = 500): Promise<number> {
    const due = `SELECT rowid FROM ad_rewards WHERE status = 'issued' AND expires_at <= ?1
                  ORDER BY rowid LIMIT ?2`;
    const [, expired] = (await this.db.batch([
      this.db
        .prepare(
          `UPDATE installs SET state_version = state_version + 1 WHERE id IN
             (SELECT install_id FROM ad_rewards WHERE rowid IN (${due}))`,
        )
        .bind(now, limit),
      this.db
        .prepare(`UPDATE ad_rewards SET status = 'expired' WHERE rowid IN (${due})`)
        .bind(now, limit),
    ])) as [D1Result, D1Result];
    return expired.meta.changes;
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

  /** Retention (13 months, 03 §13): intents issued before `cutoff`, at most `limit`. */
  async purgeIssuedBefore(cutoff: string, limit = 500): Promise<number> {
    const result = await this.db
      .prepare(
        `DELETE FROM ad_rewards WHERE rowid IN
           (SELECT rowid FROM ad_rewards WHERE issued_at < ?1 LIMIT ?2)`,
      )
      .bind(cutoff, limit)
      .run();
    return result.meta.changes;
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
