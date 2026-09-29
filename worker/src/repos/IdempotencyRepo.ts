import { blobToBytes } from '../crypto/encoding';

/**
 * `idempotency_keys` (03 §2.3, §4; RC49). Every write is a compare-and-set
 * on `(state, created_at)` so a request that lost ownership (takeover after
 * 120 s) can never overwrite or delete the new owner's row.
 */
export type IdempotencyState = 'in_progress' | 'done';

export interface IdempotencyKeyRef {
  readonly installId: string;
  readonly route: string;
  readonly key: string;
}

export interface IdempotencyRow extends IdempotencyKeyRef {
  readonly requestHash: string;
  readonly state: IdempotencyState;
  readonly responseStatus: number | null;
  readonly responseBodyEnc: Uint8Array | null;
  readonly createdAt: string;
  readonly expiresAt: string;
}

interface RawRow {
  install_id: string;
  route: string;
  key: string;
  request_hash: string;
  state: IdempotencyState;
  response_status: number | null;
  response_body_enc: unknown;
  created_at: string;
  expires_at: string;
}

export interface ClaimInput extends IdempotencyKeyRef {
  readonly requestHash: string;
  readonly createdAt: string;
  readonly expiresAt: string;
}

const PK = 'install_id = ?1 AND route = ?2 AND key = ?3';

export class IdempotencyRepo {
  constructor(private readonly db: D1Database) {}

  /** Inserts an `in_progress` row; false when a row for the key already exists. */
  async insert(input: ClaimInput): Promise<boolean> {
    const result = await this.db
      .prepare(
        `INSERT INTO idempotency_keys
           (install_id, route, key, request_hash, state, created_at, expires_at)
         VALUES (?1, ?2, ?3, ?4, 'in_progress', ?5, ?6)
         ON CONFLICT (install_id, route, key) DO NOTHING`,
      )
      .bind(
        input.installId,
        input.route,
        input.key,
        input.requestHash,
        input.createdAt,
        input.expiresAt,
      )
      .run();
    return result.meta.changes === 1;
  }

  async find(ref: IdempotencyKeyRef): Promise<IdempotencyRow | null> {
    const row = await this.db
      .prepare(`SELECT * FROM idempotency_keys WHERE ${PK}`)
      .bind(ref.installId, ref.route, ref.key)
      .first<RawRow>();
    return row === null ? null : toRow(row);
  }

  /**
   * Replaces a stale `in_progress` row (crashed request) or an expired row
   * with a fresh `in_progress` claim; false if someone else changed it first.
   */
  async reclaim(previous: IdempotencyRow, fresh: ClaimInput): Promise<boolean> {
    const result = await this.db
      .prepare(
        `UPDATE idempotency_keys
            SET request_hash = ?4, state = 'in_progress', response_status = NULL,
                response_body_enc = NULL, created_at = ?5, expires_at = ?6
          WHERE ${PK} AND state = ?7 AND created_at = ?8`,
      )
      .bind(
        fresh.installId,
        fresh.route,
        fresh.key,
        fresh.requestHash,
        fresh.createdAt,
        fresh.expiresAt,
        previous.state,
        previous.createdAt,
      )
      .run();
    return result.meta.changes === 1;
  }

  /** Stores a terminal response on the caller's own `in_progress` row. */
  async complete(
    owner: ClaimInput,
    responseStatus: number,
    responseBodyEnc: Uint8Array,
  ): Promise<boolean> {
    const result = await this.db
      .prepare(
        `UPDATE idempotency_keys
            SET state = 'done', response_status = ?4, response_body_enc = ?5
          WHERE ${PK} AND state = 'in_progress' AND created_at = ?6`,
      )
      .bind(
        owner.installId,
        owner.route,
        owner.key,
        responseStatus,
        responseBodyEnc,
        owner.createdAt,
      )
      .run();
    return result.meta.changes === 1;
  }

  /** Deletes the caller's own `in_progress` row (non-terminal outcome, RC49). */
  async release(owner: ClaimInput): Promise<boolean> {
    const result = await this.db
      .prepare(
        `DELETE FROM idempotency_keys WHERE ${PK} AND state = 'in_progress' AND created_at = ?4`,
      )
      .bind(owner.installId, owner.route, owner.key, owner.createdAt)
      .run();
    return result.meta.changes === 1;
  }

  /** Drops a stored replay body, keeping the `done` row (reading ack, RC51). */
  async deleteBody(ref: IdempotencyKeyRef): Promise<boolean> {
    const result = await this.db
      .prepare(
        `UPDATE idempotency_keys SET response_body_enc = NULL
          WHERE ${PK} AND state = 'done' AND response_body_enc IS NOT NULL`,
      )
      .bind(ref.installId, ref.route, ref.key)
      .run();
    return result.meta.changes === 1;
  }

  /** Erasure: every row of the install (03 §3.6, RC37). */
  eraseStmt(installId: string): D1PreparedStatement {
    return this.db.prepare(`DELETE FROM idempotency_keys WHERE install_id = ?1`).bind(installId);
  }

  /**
   * Erasure from inside an `[idem]` request (`DELETE /v1/installs/me`): every
   * row of the install except the running request's own, so its `204` is
   * still stored for a network retry (03 §2.3, §3.6).
   */
  eraseExceptStmt(installId: string, keep: IdempotencyKeyRef): D1PreparedStatement {
    return this.db
      .prepare(
        `DELETE FROM idempotency_keys
          WHERE install_id = ?1 AND NOT (route = ?2 AND key = ?3)`,
      )
      .bind(installId, keep.route, keep.key);
  }

  /** Deletes up to `limit` rows past `expires_at` (hourly cron, 03 §12). Returns the count. */
  async purgeExpired(nowIso: string, limit = 500): Promise<number> {
    const result = await this.db
      .prepare(
        `DELETE FROM idempotency_keys WHERE rowid IN
           (SELECT rowid FROM idempotency_keys WHERE expires_at <= ?1 LIMIT ?2)`,
      )
      .bind(nowIso, limit)
      .run();
    return result.meta.changes;
  }
}

function toRow(raw: RawRow): IdempotencyRow {
  return {
    installId: raw.install_id,
    route: raw.route,
    key: raw.key,
    requestHash: raw.request_hash,
    state: raw.state,
    responseStatus: raw.response_status,
    responseBodyEnc: blobToBytes(raw.response_body_enc),
    createdAt: raw.created_at,
    expiresAt: raw.expires_at,
  };
}
