/**
 * Google purchases whose server-side acknowledgement failed after the grant
 * (03 §6.3 step 4, BE8, RC10): `pendingAck` markers in `CACHE_KV`
 * (`ack:pending:{purchaseId}`, GLOSSARY §6.1), read by the hourly
 * acknowledgement-retry cron. The marker holds no token: the cron loads the
 * `purchases` row. It expires after 3 days, when Google refunds an
 * unacknowledged purchase anyway (which then arrives as a voided purchase).
 */
export const PENDING_ACK_PREFIX = 'ack:pending:';
export const PENDING_ACK_TTL_SEC = 3 * 24 * 3600;

export interface PendingAck {
  readonly purchaseId: string;
  readonly markedAt: string;
}

export class PendingAckRepo {
  constructor(private readonly kv: KVNamespace) {}

  async mark(purchaseId: string, markedAt: string): Promise<void> {
    await this.kv.put(`${PENDING_ACK_PREFIX}${purchaseId}`, JSON.stringify({ markedAt }), {
      expirationTtl: PENDING_ACK_TTL_SEC,
    });
  }

  async clear(purchaseId: string): Promise<void> {
    await this.kv.delete(`${PENDING_ACK_PREFIX}${purchaseId}`);
  }

  /** Up to `limit` markers (KV listing is eventually consistent; the cron is idempotent). */
  async list(limit = 100): Promise<PendingAck[]> {
    const { keys } = await this.kv.list({ prefix: PENDING_ACK_PREFIX, limit });
    const out: PendingAck[] = [];
    for (const key of keys) {
      const value = await this.kv.get<{ markedAt?: unknown }>(key.name, 'json');
      out.push({
        purchaseId: key.name.slice(PENDING_ACK_PREFIX.length),
        markedAt: typeof value?.markedAt === 'string' ? value.markedAt : '',
      });
    }
    return out;
  }
}
