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
    await this.db
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
      )
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
