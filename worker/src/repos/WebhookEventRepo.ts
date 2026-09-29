/** `webhook_events` (03 §4, §6.4, §7.2): dedupe for ASSN v2, RTDN and AdMob SSV. */
export type WebhookSource = 'apple' | 'google' | 'admob';
export type WebhookStatus = 'processed' | 'ignored' | 'failed';

export interface WebhookEvent {
  /** `notificationUUID` | Pub/Sub `messageId` | `ssv:{transaction_id}`. */
  readonly id: string;
  readonly source: WebhookSource;
  readonly type: string;
  readonly status: WebhookStatus;
  readonly receivedAt: string;
}

interface RawEvent {
  id: string;
  source: WebhookSource;
  type: string;
  status: WebhookStatus;
  received_at: string;
}

export class WebhookEventRepo {
  constructor(private readonly db: D1Database) {}

  /** Records an event; false when the ID was seen before (the delivery is a duplicate). */
  async record(event: WebhookEvent): Promise<boolean> {
    const result = await this.recordStmt(event).run();
    return result.meta.changes === 1;
  }

  recordStmt(event: WebhookEvent): D1PreparedStatement {
    return this.db
      .prepare(
        `INSERT INTO webhook_events (id, source, type, status, received_at)
         VALUES (?1, ?2, ?3, ?4, ?5) ON CONFLICT (id) DO NOTHING`,
      )
      .bind(event.id, event.source, event.type, event.status, event.receivedAt);
  }

  async find(id: string): Promise<WebhookEvent | null> {
    const raw = await this.db
      .prepare(`SELECT * FROM webhook_events WHERE id = ?1`)
      .bind(id)
      .first<RawEvent>();
    return raw === null
      ? null
      : {
          id: raw.id,
          source: raw.source,
          type: raw.type,
          status: raw.status,
          receivedAt: raw.received_at,
        };
  }

  /** A `failed` event may be retried by the sender; this lets the retry through. */
  async updateStatus(id: string, status: WebhookStatus): Promise<boolean> {
    const result = await this.db
      .prepare(`UPDATE webhook_events SET status = ?2 WHERE id = ?1`)
      .bind(id, status)
      .run();
    return result.meta.changes === 1;
  }
}
