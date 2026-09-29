import type { LogFields } from './Logger';

/** Alert kinds sent to `ALERT_WEBHOOK_URL` (03 §14.1, §2.4, §6.2, §10.2). */
export type AlertKind =
  | 'budget_tier'
  | 'sandbox_volume'
  | 'low_trust_bucket'
  | 'error_rate'
  | 'reading_failed_rate'
  | 'webhook_sig_failures'
  /** Purchase verify error rate > 2 % over 10 min (04 §12.3; `scripts/metrics.ts`). */
  | 'verify_error_rate'
  /** `ssv_rejected` spike (04 Risks; `scripts/metrics.ts`). */
  | 'ssv_rejected_spike'
  /** Grant to a blocked or indebted install; support may refund via the store (03 §6.5). */
  | 'blocked_purchase';

export interface Alert {
  readonly kind: AlertKind;
  readonly message: string;
  readonly fields?: LogFields;
  /**
   * Dedupe bucket; defaults to `kind`. At most one message per bucket per
   * hour is sent (03 §14.1). A kind with distinct severities (budget tiers)
   * passes e.g. `budget_tier:hard`, so a higher tier is never swallowed by a
   * lower one sent in the same hour.
   */
  readonly dedupeKey?: string;
}

/** Alert sink port. Never throws: delivery failures are logged by the adapter. */
export interface Alerter {
  send(alert: Alert): Promise<void>;
}
