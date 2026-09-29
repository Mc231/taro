import { blobToBytes } from '../crypto/encoding';

/**
 * `reading_reports` (03 §4, §9.7; RC22, CS7): the one user-initiated
 * exception to "text is never stored". `payload_enc` is
 * AES-256-GCM({question?, reading, note?}) with `REPORT_ENC_KEY`, sealed by
 * the caller; this repo never sees plaintext. Kept 90 days.
 */
export type ReportReason = 'offensive' | 'harmful_advice' | 'sexual' | 'hateful' | 'other';

export interface NewReport {
  readonly id: string;
  readonly installId: string;
  readonly clientReadingId: string;
  readonly readingId: string | null;
  readonly localDate: string;
  readonly reason: ReportReason;
  readonly locale: string;
  readonly promptVersion: string | null;
  readonly model: string | null;
  readonly payloadEnc: Uint8Array;
  readonly createdAt: string;
  readonly expiresAt: string;
}

export type ReportRow = NewReport;

interface RawReport {
  id: string;
  install_id: string;
  client_reading_id: string;
  reading_id: string | null;
  local_date: string;
  reason: ReportReason;
  locale: string;
  prompt_version: string | null;
  model: string | null;
  payload_enc: unknown;
  created_at: string;
  expires_at: string;
}

export class ReportRepo {
  constructor(private readonly db: D1Database) {}

  /** Stores a report; false when this reading was already reported (one per reading). */
  async insert(input: NewReport): Promise<boolean> {
    const result = await this.db
      .prepare(
        `INSERT INTO reading_reports
           (id, install_id, client_reading_id, reading_id, local_date, reason, locale,
            prompt_version, model, payload_enc, created_at, expires_at)
         VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9, ?10, ?11, ?12)
         ON CONFLICT (install_id, client_reading_id) DO NOTHING`,
      )
      .bind(
        input.id,
        input.installId,
        input.clientReadingId,
        input.readingId,
        input.localDate,
        input.reason,
        input.locale,
        input.promptVersion,
        input.model,
        input.payloadEnc,
        input.createdAt,
        input.expiresAt,
      )
      .run();
    return result.meta.changes === 1;
  }

  async findByReading(installId: string, clientReadingId: string): Promise<ReportRow | null> {
    const raw = await this.db
      .prepare(`SELECT * FROM reading_reports WHERE install_id = ?1 AND client_reading_id = ?2`)
      .bind(installId, clientReadingId)
      .first<RawReport>();
    return raw === null ? null : toReport(raw);
  }

  /** Reports filed on one local day (limit 10 per install per day, 03 §9.7). */
  async countForDay(installId: string, localDate: string): Promise<number> {
    const row = await this.db
      .prepare(
        `SELECT COUNT(*) AS n FROM reading_reports WHERE install_id = ?1 AND local_date = ?2`,
      )
      .bind(installId, localDate)
      .first<{ n: number }>();
    return row?.n ?? 0;
  }

  /** Reports created in `[fromIso, toIso)`, oldest first (owner export script, 03 §9.7). */
  async listCreatedBetween(fromIso: string, toIso: string, limit = 500): Promise<ReportRow[]> {
    const { results } = await this.db
      .prepare(
        `SELECT * FROM reading_reports WHERE created_at >= ?1 AND created_at < ?2
          ORDER BY created_at LIMIT ?3`,
      )
      .bind(fromIso, toIso, limit)
      .all<RawReport>();
    return results.map(toReport);
  }

  /** Erasure (RC37); runs before `ReadingRepo.eraseStmt`. */
  eraseStmt(installId: string): D1PreparedStatement {
    return this.db.prepare(`DELETE FROM reading_reports WHERE install_id = ?1`).bind(installId);
  }

  /** Retention: rows past `expires_at` (daily cron, 03 §12, §13). */
  async purgeExpired(now: string, limit = 500): Promise<number> {
    const result = await this.db
      .prepare(
        `DELETE FROM reading_reports WHERE rowid IN
           (SELECT rowid FROM reading_reports WHERE expires_at <= ?1 LIMIT ?2)`,
      )
      .bind(now, limit)
      .run();
    return result.meta.changes;
  }
}

function toReport(raw: RawReport): ReportRow {
  return {
    id: raw.id,
    installId: raw.install_id,
    clientReadingId: raw.client_reading_id,
    readingId: raw.reading_id,
    localDate: raw.local_date,
    reason: raw.reason,
    locale: raw.locale,
    promptVersion: raw.prompt_version,
    model: raw.model,
    payloadEnc: blobToBytes(raw.payload_enc) ?? new Uint8Array(),
    createdAt: raw.created_at,
    expiresAt: raw.expires_at,
  };
}
