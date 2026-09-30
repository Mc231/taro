/**
 * `readings` (03 §4, §9; BE13, RC49–RC52): reading METADATA only, never the
 * question or the AI output. `hold_state` is the compare-and-set target of
 * every hold, refund and commit (RC52).
 */
export type ReadingStatus =
  | 'held'
  | 'generating'
  | 'completed'
  | 'declined'
  | 'failed'
  | 'no_credit'
  | 'expired_hold'
  | 'expired_refunded';
export type HoldSource = 'free' | 'bonus' | 'paid';
export type HoldState = 'none' | 'held' | 'consumed' | 'refunded';
export type ChargeSource = HoldSource | 'none';

export interface NewReading {
  readonly id: string;
  readonly installId: string;
  readonly clientReadingId: string;
  readonly spreadId: string;
  readonly cardCount: number;
  readonly hasQuestion: boolean;
  readonly locale: string;
  readonly localDate: string;
  readonly status: ReadingStatus;
  readonly chargeSource: ChargeSource;
  readonly holdExpiresAt?: string | null;
  readonly createdAt: string;
}

/** Model call metadata recorded when a reading ends (03 §9.1, §9.6). */
export interface ReadingResult {
  readonly status: ReadingStatus;
  readonly chargeSource?: ChargeSource;
  readonly safetyCategory?: string | null;
  readonly safetyLayer?: string | null;
  readonly promptVersion?: string | null;
  readonly model?: string | null;
  readonly inputTokens?: number | null;
  readonly cacheReadTokens?: number | null;
  readonly cacheWriteTokens?: number | null;
  readonly outputTokens?: number | null;
  readonly costMicroUsd?: number | null;
  readonly latencyMs?: number | null;
  readonly errorCode?: string | null;
  readonly completedAt?: string | null;
}

export interface ReadingRow extends Omit<NewReading, 'holdExpiresAt'> {
  readonly attempt: number;
  readonly holdSource: HoldSource | null;
  readonly holdState: HoldState;
  readonly holdLocalDate: string | null;
  readonly holdExpiresAt: string | null;
  readonly safetyCategory: string | null;
  readonly safetyLayer: string | null;
  readonly promptVersion: string | null;
  readonly model: string | null;
  readonly inputTokens: number | null;
  readonly cacheReadTokens: number | null;
  readonly cacheWriteTokens: number | null;
  readonly outputTokens: number | null;
  readonly costMicroUsd: number | null;
  readonly latencyMs: number | null;
  readonly errorCode: string | null;
  readonly completedAt: string | null;
  readonly ackedAt: string | null;
}

interface RawReading {
  id: string;
  install_id: string;
  client_reading_id: string;
  spread_id: string;
  card_count: number;
  has_question: number;
  locale: string;
  local_date: string;
  status: ReadingStatus;
  attempt: number;
  hold_source: HoldSource | null;
  hold_state: HoldState;
  hold_local_date: string | null;
  hold_expires_at: string | null;
  charge_source: ChargeSource;
  safety_category: string | null;
  safety_layer: string | null;
  prompt_version: string | null;
  model: string | null;
  input_tokens: number | null;
  cache_read_tokens: number | null;
  cache_write_tokens: number | null;
  output_tokens: number | null;
  cost_micro_usd: number | null;
  latency_ms: number | null;
  error_code: string | null;
  created_at: string;
  completed_at: string | null;
  acked_at: string | null;
}

/** The row a hold compare-and-set expects to find (RC52). */
export interface HoldExpectation {
  readonly id: string;
  readonly installId: string;
  readonly state: HoldState;
  readonly attempt: number;
}

/** What a hold gate writes when it applies. */
export interface HoldTarget {
  readonly attempt: number;
  readonly source: HoldSource;
  readonly localDate: string;
  readonly expiresAt: string;
  readonly status: ReadingStatus;
}

/** The balance condition of one hold gate (03 §5.3 steps 1–2). */
export type HoldCondition =
  | {
      readonly bucket: 'free';
      /** Today's allowance (`readings.freeDaily`, low-trust capped). */
      readonly current: number;
      /** Android: the device counter must also be below `current` (03 §3.7). */
      readonly deviceKeyHash: string | null;
    }
  | { readonly bucket: 'bonus' | 'paid' };

export class ReadingRepo {
  constructor(private readonly db: D1Database) {}

  /** Inserts a reading; false when `(install_id, client_reading_id)` already exists. */
  async insert(input: NewReading): Promise<boolean> {
    const result = await this.db
      .prepare(
        `INSERT INTO readings
           (id, install_id, client_reading_id, spread_id, card_count, has_question, locale,
            local_date, status, charge_source, hold_expires_at, created_at)
         VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9, ?10, ?11, ?12)
         ON CONFLICT (install_id, client_reading_id) DO NOTHING`,
      )
      .bind(
        input.id,
        input.installId,
        input.clientReadingId,
        input.spreadId,
        input.cardCount,
        input.hasQuestion ? 1 : 0,
        input.locale,
        input.localDate,
        input.status,
        input.chargeSource,
        input.holdExpiresAt ?? null,
        input.createdAt,
      )
      .run();
    return result.meta.changes === 1;
  }

  async findById(id: string): Promise<ReadingRow | null> {
    return this.first('id = ?1', [id]);
  }

  async findByClientId(installId: string, clientReadingId: string): Promise<ReadingRow | null> {
    return this.first('install_id = ?1 AND client_reading_id = ?2', [installId, clientReadingId]);
  }

  /**
   * Takes the hold for `attempt` (03 §5.3): only from `none` or `refunded`.
   * `holdLocalDate` is the free-hold date refunds must use.
   */
  holdStmt(input: {
    readonly id: string;
    readonly attempt: number;
    readonly source: HoldSource;
    readonly holdLocalDate: string | null;
    readonly holdExpiresAt: string;
  }): D1PreparedStatement {
    return this.db
      .prepare(
        `UPDATE readings SET hold_state = 'held', hold_source = ?3, hold_local_date = ?4,
                hold_expires_at = ?5, attempt = ?2, status = 'held', charge_source = ?3
          WHERE id = ?1 AND hold_state IN ('none', 'refunded')`,
      )
      .bind(input.id, input.attempt, input.source, input.holdLocalDate, input.holdExpiresAt);
  }

  /**
   * The gate of a hold batch (03 §5.3, `batchGuard`): `expected → held` for
   * `target.attempt`, only while the bucket still has a reading. For free,
   * `free_used < MAX(free_limit, current)` on today's `daily_usage` row (and
   * `device_daily_usage.free_used < current` on Android); for bonus/paid,
   * `SUM(ledger.delta) >= 1`. The conditions are read inside the same
   * serialised batch, so two holds can never both take the last reading.
   */
  holdGateStmt(
    expected: HoldExpectation,
    target: HoldTarget,
    condition: HoldCondition,
  ): D1PreparedStatement {
    let guard: string;
    const params: (string | number)[] = [];
    if (condition.bucket === 'free') {
      params.push(condition.current);
      guard = `COALESCE((SELECT free_used FROM daily_usage
                          WHERE install_id = ?2 AND local_date = ?6), 0)
               < MAX(COALESCE((SELECT free_limit FROM daily_usage
                                WHERE install_id = ?2 AND local_date = ?6), 0), ?10)`;
      if (condition.deviceKeyHash !== null) {
        params.push(condition.deviceKeyHash);
        guard += ` AND COALESCE((SELECT free_used FROM device_daily_usage
                                  WHERE device_key_hash = ?11 AND local_date = ?6), 0) < ?10`;
      }
    } else {
      guard = `(SELECT COALESCE(SUM(delta), 0) FROM ledger
                 WHERE install_id = ?2 AND bucket = ?5) >= 1`;
    }
    return this.db
      .prepare(
        `UPDATE readings SET hold_state = 'held', hold_source = ?5, hold_local_date = ?6,
                hold_expires_at = ?7, attempt = ?8, status = ?9, charge_source = ?5
          WHERE id = ?1 AND install_id = ?2 AND hold_state = ?3 AND attempt = ?4
            AND ${guard}`,
      )
      .bind(
        expected.id,
        expected.installId,
        expected.state,
        expected.attempt,
        target.source,
        target.localDate,
        target.expiresAt,
        target.attempt,
        target.status,
        ...params,
      );
  }

  /** After a failed hold batch: `no_credit`, only if the row is still as the gate expected. */
  noCreditStmt(expected: HoldExpectation): D1PreparedStatement {
    return this.db
      .prepare(
        `UPDATE readings SET status = 'no_credit'
          WHERE id = ?1 AND install_id = ?2 AND hold_state = ?3 AND attempt = ?4`,
      )
      .bind(expected.id, expected.installId, expected.state, expected.attempt);
  }

  /** The refund gate: `held → refunded` for exactly this attempt and bucket (RC52). */
  refundGateStmt(
    id: string,
    attempt: number,
    source: HoldSource,
    status: ReadingStatus,
  ): D1PreparedStatement {
    return this.db
      .prepare(
        `UPDATE readings SET hold_state = 'refunded', status = ?4
          WHERE id = ?1 AND hold_state = 'held' AND attempt = ?2 AND hold_source = ?3`,
      )
      .bind(id, attempt, source, status);
  }

  /**
   * `held → consumed`, `completed` for exactly this attempt (03 §5.3 step 4).
   * Also the state-guarded consume after a commit's re-hold: the row can only
   * be `held` at the new attempt if that re-hold applied.
   */
  consumeGateStmt(id: string, attempt: number, completedAt: string): D1PreparedStatement {
    return this.db
      .prepare(
        `UPDATE readings SET hold_state = 'consumed', status = 'completed', completed_at = ?3
          WHERE id = ?1 AND hold_state = 'held' AND attempt = ?2`,
      )
      .bind(id, attempt, completedAt);
  }

  /**
   * A commit whose re-hold found no credit: the reading is delivered anyway
   * (`commit_after_refund`, a free reading for the user, 03 §5.3 step 4).
   */
  completeUnchargedStmt(id: string, attempt: number, completedAt: string): D1PreparedStatement {
    return this.db
      .prepare(
        `UPDATE readings SET status = 'completed', charge_source = 'none', completed_at = ?3
          WHERE id = ?1 AND hold_state = 'refunded' AND attempt = ?2`,
      )
      .bind(id, attempt, completedAt);
  }

  /** Renews a live hold's TTL (03 §9.0); not a balance change. */
  async extendHold(id: string, attempt: number, expiresAt: string): Promise<boolean> {
    const result = await this.db
      .prepare(
        `UPDATE readings SET hold_expires_at = ?3
          WHERE id = ?1 AND hold_state = 'held' AND attempt = ?2`,
      )
      .bind(id, attempt, expiresAt)
      .run();
    return result.meta.changes === 1;
  }

  /** `findById` as a batch statement; map the row with `ReadingRepo.parse`. */
  findByIdStmt(id: string): D1PreparedStatement {
    return this.db.prepare(`SELECT * FROM readings WHERE id = ?1`).bind(id);
  }

  static parse(raw: unknown): ReadingRow {
    return toReading(raw as RawReading);
  }

  /** `held → refunded` (CAS). Only when this changed a row may the refund itself run (RC52). */
  refundStmt(id: string, status: ReadingStatus): D1PreparedStatement {
    return this.db
      .prepare(
        `UPDATE readings SET hold_state = 'refunded', status = ?2
          WHERE id = ?1 AND hold_state = 'held'`,
      )
      .bind(id, status);
  }

  /** `held → consumed`, status `completed` (commit, 03 §5.3 step 4). */
  consumeStmt(id: string, completedAt: string): D1PreparedStatement {
    return this.db
      .prepare(
        `UPDATE readings SET hold_state = 'consumed', status = 'completed', completed_at = ?2
          WHERE id = ?1 AND hold_state = 'held'`,
      )
      .bind(id, completedAt);
  }

  /** Status change guarded by the expected current statuses; false if it had moved on. */
  async transition(
    id: string,
    from: readonly ReadingStatus[],
    to: ReadingStatus,
  ): Promise<boolean> {
    const placeholders = from.map((_, i) => `?${String(i + 3)}`).join(', ');
    const result = await this.db
      .prepare(`UPDATE readings SET status = ?2 WHERE id = ?1 AND status IN (${placeholders})`)
      .bind(id, to, ...from)
      .run();
    return result.meta.changes === 1;
  }

  /** Records model metadata (tokens, cost, safety) when a reading ends. */
  async recordResult(id: string, result: ReadingResult): Promise<void> {
    await this.recordResultStmt(id, result).run();
  }

  /** `recordResult` as a batch statement (the commit batch, 03 §9.1 step 6). */
  recordResultStmt(id: string, result: ReadingResult): D1PreparedStatement {
    return this.db
      .prepare(
        `UPDATE readings SET status = ?2, charge_source = COALESCE(?3, charge_source),
                safety_category = ?4, safety_layer = ?5, prompt_version = ?6, model = ?7,
                input_tokens = ?8, cache_read_tokens = ?9, cache_write_tokens = ?10,
                output_tokens = ?11, cost_micro_usd = ?12, latency_ms = ?13, error_code = ?14,
                completed_at = COALESCE(?15, completed_at)
          WHERE id = ?1`,
      )
      .bind(
        id,
        result.status,
        result.chargeSource ?? null,
        result.safetyCategory ?? null,
        result.safetyLayer ?? null,
        result.promptVersion ?? null,
        result.model ?? null,
        result.inputTokens ?? null,
        result.cacheReadTokens ?? null,
        result.cacheWriteTokens ?? null,
        result.outputTokens ?? null,
        result.costMicroUsd ?? null,
        result.latencyMs ?? null,
        result.errorCode ?? null,
        result.completedAt ?? null,
      );
  }

  /**
   * The request metadata of a reading once its cards arrive (03 §9.1): the
   * pre-draw hold only knew the spread and locale. Never the question (BE13).
   */
  async describe(
    id: string,
    request: {
      readonly spreadId: string;
      readonly cardCount: number;
      readonly hasQuestion: boolean;
      readonly locale: string;
    },
  ): Promise<void> {
    await this.db
      .prepare(
        `UPDATE readings SET spread_id = ?2, card_count = ?3, has_question = ?4, locale = ?5
          WHERE id = ?1`,
      )
      .bind(id, request.spreadId, request.cardCount, request.hasQuestion ? 1 : 0, request.locale)
      .run();
  }

  /**
   * `held → generating` for exactly this attempt (03 §9.1 step 4).
   * `hold_expires_at` becomes the stale-run cutoff (`ai.deadlineMs + 60 s`),
   * which `refundStaleHolds` compares with (RC52).
   */
  async markGenerating(id: string, attempt: number, staleAt: string): Promise<boolean> {
    const result = await this.db
      .prepare(
        `UPDATE readings SET status = 'generating', hold_expires_at = ?3
          WHERE id = ?1 AND attempt = ?2 AND hold_state = 'held'
            AND status IN ('held', 'generating')`,
      )
      .bind(id, attempt, staleAt)
      .run();
    return result.meta.changes === 1;
  }

  /** Other readings of the install with a live pre-draw hold (at most one open hold, 03 §9.0). */
  async openHolds(installId: string, exceptId: string): Promise<ReadingRow[]> {
    const { results } = await this.db
      .prepare(
        `SELECT * FROM readings WHERE install_id = ?1 AND id <> ?2
            AND status = 'held' AND hold_state = 'held'`,
      )
      .bind(installId, exceptId)
      .all<RawReading>();
    return results.map(toReading);
  }

  /** `generating` rows past their stale cutoff (15-minute cron `refundStaleHolds`, RC52). */
  async staleGenerating(now: string, limit: number): Promise<ReadingRow[]> {
    const { results } = await this.db
      .prepare(
        `SELECT * FROM readings WHERE status = 'generating' AND hold_state = 'held'
            AND hold_expires_at <= ?1 ORDER BY hold_expires_at LIMIT ?2`,
      )
      .bind(now, limit)
      .all<RawReading>();
    return results.map(toReading);
  }

  /** Completed, never acknowledged, completed on or before `cutoff` (hourly cron, RC51). */
  async undelivered(cutoff: string, limit: number): Promise<ReadingRow[]> {
    const { results } = await this.db
      .prepare(
        `SELECT * FROM readings WHERE status = 'completed' AND acked_at IS NULL
            AND completed_at <= ?1 ORDER BY completed_at LIMIT ?2`,
      )
      .bind(cutoff, limit)
      .all<RawReading>();
    return results.map(toReading);
  }

  /**
   * The undelivered refund gate (RC51): `consumed → refunded`,
   * `completed → expired_refunded`, only while the reading is unacknowledged.
   */
  refundConsumedGateStmt(id: string, attempt: number, source: HoldSource): D1PreparedStatement {
    return this.db
      .prepare(
        `UPDATE readings SET hold_state = 'refunded', status = 'expired_refunded'
          WHERE id = ?1 AND hold_state = 'consumed' AND attempt = ?2 AND hold_source = ?3
            AND status = 'completed' AND acked_at IS NULL`,
      )
      .bind(id, attempt, source);
  }

  /** An uncharged completed reading (`commit_after_refund`) expires without a refund. */
  async expireUncharged(id: string): Promise<boolean> {
    const result = await this.db
      .prepare(
        `UPDATE readings SET status = 'expired_refunded'
          WHERE id = ?1 AND status = 'completed' AND hold_state <> 'consumed' AND acked_at IS NULL`,
      )
      .bind(id)
      .run();
    return result.meta.changes === 1;
  }

  /** `error_code` of a row a cron settled (`abandoned`), unless one is already set. */
  async setErrorCode(id: string, code: string): Promise<void> {
    await this.db
      .prepare(`UPDATE readings SET error_code = ?2 WHERE id = ?1 AND error_code IS NULL`)
      .bind(id, code)
      .run();
  }

  /** Delivery acknowledged (RC51); false when already acked or unknown. */
  async markAcked(installId: string, clientReadingId: string, now: string): Promise<boolean> {
    const result = await this.db
      .prepare(
        `UPDATE readings SET acked_at = ?3
          WHERE install_id = ?1 AND client_reading_id = ?2 AND acked_at IS NULL`,
      )
      .bind(installId, clientReadingId, now)
      .run();
    return result.meta.changes === 1;
  }

  /** Held readings whose pre-draw hold expired (15-minute cron, 03 §12). */
  async expiredHolds(now: string, limit = 500): Promise<ReadingRow[]> {
    const { results } = await this.db
      .prepare(
        `SELECT * FROM readings WHERE status = 'held' AND hold_state = 'held'
            AND hold_expires_at <= ?1 ORDER BY hold_expires_at LIMIT ?2`,
      )
      .bind(now, limit)
      .all<RawReading>();
    return results.map(toReading);
  }

  /** Erasure (RC37); run after `ReportRepo.eraseStmt` (reports reference readings). */
  eraseStmt(installId: string): D1PreparedStatement {
    return this.db.prepare(`DELETE FROM readings WHERE install_id = ?1`).bind(installId);
  }

  /**
   * Erasure from `DELETE /v1/installs/me` (RC37): every reading except one
   * whose hold is still `held`. That row is metadata only and is what the
   * stale-hold cron refunds from, so deleting it would lose a held credit
   * (03 §5.3 step 3). Run after `ReportRepo.eraseStmt`.
   */
  eraseSettledStmt(installId: string): D1PreparedStatement {
    return this.db
      .prepare(`DELETE FROM readings WHERE install_id = ?1 AND hold_state <> 'held'`)
      .bind(installId);
  }

  /** Retention (13 months, 03 §13); readings a live report still references are kept. */
  async purgeCreatedBefore(cutoff: string, limit = 500): Promise<number> {
    const result = await this.db
      .prepare(
        `DELETE FROM readings WHERE rowid IN
           (SELECT rowid FROM readings WHERE created_at < ?1
               AND id NOT IN (SELECT reading_id FROM reading_reports WHERE reading_id IS NOT NULL)
             LIMIT ?2)`,
      )
      .bind(cutoff, limit)
      .run();
    return result.meta.changes;
  }

  private async first(where: string, values: readonly string[]): Promise<ReadingRow | null> {
    const raw = await this.db
      .prepare(`SELECT * FROM readings WHERE ${where}`)
      .bind(...values)
      .first<RawReading>();
    return raw === null ? null : toReading(raw);
  }
}

function toReading(raw: RawReading): ReadingRow {
  return {
    id: raw.id,
    installId: raw.install_id,
    clientReadingId: raw.client_reading_id,
    spreadId: raw.spread_id,
    cardCount: raw.card_count,
    hasQuestion: raw.has_question === 1,
    locale: raw.locale,
    localDate: raw.local_date,
    status: raw.status,
    attempt: raw.attempt,
    holdSource: raw.hold_source,
    holdState: raw.hold_state,
    holdLocalDate: raw.hold_local_date,
    holdExpiresAt: raw.hold_expires_at,
    chargeSource: raw.charge_source,
    safetyCategory: raw.safety_category,
    safetyLayer: raw.safety_layer,
    promptVersion: raw.prompt_version,
    model: raw.model,
    inputTokens: raw.input_tokens,
    cacheReadTokens: raw.cache_read_tokens,
    cacheWriteTokens: raw.cache_write_tokens,
    outputTokens: raw.output_tokens,
    costMicroUsd: raw.cost_micro_usd,
    latencyMs: raw.latency_ms,
    errorCode: raw.error_code,
    createdAt: raw.created_at,
    completedAt: raw.completed_at,
    ackedAt: raw.acked_at,
  };
}
