/**
 * `ledger` (03 §4, §5.3; BE5, RC7, RC49). Append-only: the
 * `ledger_no_update` / `ledger_no_delete` triggers reject every change, and
 * `UNIQUE (reason, ref_type, ref_id, bucket)` makes each movement idempotent.
 * Balances are `SUM(delta)` per bucket over the `ledger_install` index; there
 * is no cache table.
 */
export type LedgerBucket = 'paid' | 'bonus';

export type LedgerReason =
  | 'purchase'
  | 'purchase_reversal_regrant'
  | 'refund_revoke'
  | 'ad_reward'
  | 'promo'
  | 'admin_adjust'
  | 'reading_hold'
  | 'reading_refund'
  | 'reading_undelivered';

export type LedgerRefType = 'purchase' | 'ad_reward' | 'reading' | 'admin';

export interface LedgerEntryInput {
  readonly installId: string;
  readonly bucket: LedgerBucket;
  readonly delta: number;
  readonly reason: LedgerReason;
  readonly refType: LedgerRefType;
  readonly refId: string;
  /** Admin adjustments only; never user content. */
  readonly note?: string | null;
  readonly createdAt: string;
}

export interface LedgerEntry extends Required<LedgerEntryInput> {
  readonly id: number;
}

export interface Balances {
  readonly paid: number;
  readonly bonus: number;
}

interface RawEntry {
  id: number;
  install_id: string;
  bucket: LedgerBucket;
  delta: number;
  reason: LedgerReason;
  ref_type: LedgerRefType;
  ref_id: string;
  note: string | null;
  created_at: string;
}

/** `ref_id` of a reading hold or refund: one per `(reading, attempt)` (RC49). */
export function readingRef(readingId: string, attempt: number): string {
  return `${readingId}#${String(attempt)}`;
}

export class LedgerRepo {
  constructor(private readonly db: D1Database) {}

  /** `paid` and `bonus` as ledger SUMs (`paid` may be negative after a refund clawback, 03 §6.5). */
  async balances(installId: string): Promise<Balances> {
    const { results } = await this.balancesStmt(installId).all();
    return LedgerRepo.parseBalances(results);
  }

  /** `balances` as a batch statement; fold its rows with `LedgerRepo.parseBalances`. */
  balancesStmt(installId: string): D1PreparedStatement {
    return this.db
      .prepare(
        `SELECT bucket, COALESCE(SUM(delta), 0) AS total FROM ledger
          WHERE install_id = ?1 GROUP BY bucket`,
      )
      .bind(installId);
  }

  static parseBalances(rows: readonly unknown[]): Balances {
    const balances = { paid: 0, bonus: 0 };
    for (const row of rows as readonly { bucket: LedgerBucket; total: number }[]) {
      balances[row.bucket] = row.total;
    }
    return balances;
  }

  /** Inserts an entry; false when the same `(reason, ref_type, ref_id, bucket)` already exists. */
  async append(entry: LedgerEntryInput): Promise<boolean> {
    const result = await this.appendStmt(entry).run();
    return result.meta.changes === 1;
  }

  /** `append` as a statement for a D1 batch (`ON CONFLICT DO NOTHING`). */
  appendStmt(entry: LedgerEntryInput): D1PreparedStatement {
    return this.db
      .prepare(
        `INSERT INTO ledger (install_id, bucket, delta, reason, ref_type, ref_id, note, created_at)
         VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8)
         ON CONFLICT (reason, ref_type, ref_id, bucket) DO NOTHING`,
      )
      .bind(
        entry.installId,
        entry.bucket,
        entry.delta,
        entry.reason,
        entry.refType,
        entry.refId,
        entry.note ?? null,
        entry.createdAt,
      );
  }

  /**
   * The guarded `-1` of a reading hold (03 §5.3 step 2): inserts only while
   * the bucket's SUM is at least 1, so the balance can never go negative by a
   * hold. `changes == 0` means "try the next bucket".
   */
  holdStmt(input: {
    readonly installId: string;
    readonly bucket: LedgerBucket;
    readonly readingId: string;
    readonly attempt: number;
    readonly now: string;
  }): D1PreparedStatement {
    return this.db
      .prepare(
        `INSERT INTO ledger (install_id, bucket, delta, reason, ref_type, ref_id, created_at)
         SELECT ?1, ?2, -1, 'reading_hold', 'reading', ?3, ?4
          WHERE (SELECT COALESCE(SUM(delta), 0) FROM ledger
                  WHERE install_id = ?1 AND bucket = ?2) >= 1
         ON CONFLICT (reason, ref_type, ref_id, bucket) DO NOTHING`,
      )
      .bind(input.installId, input.bucket, readingRef(input.readingId, input.attempt), input.now);
  }

  /** Entries of one install, oldest first (admin scripts, tests). */
  async entries(installId: string, limit = 500): Promise<LedgerEntry[]> {
    const { results } = await this.db
      .prepare(`SELECT * FROM ledger WHERE install_id = ?1 ORDER BY id LIMIT ?2`)
      .bind(installId, limit)
      .all<RawEntry>();
    return results.map((raw) => ({
      id: raw.id,
      installId: raw.install_id,
      bucket: raw.bucket,
      delta: raw.delta,
      reason: raw.reason,
      refType: raw.ref_type,
      refId: raw.ref_id,
      note: raw.note,
      createdAt: raw.created_at,
    }));
  }
}
