/** Analytics Engine port, dataset `taro_api_events` (03 §14.1). */
export type MetricEvent =
  | 'reading_completed'
  | 'reading_declined'
  | 'reading_failed'
  | 'purchase_granted'
  /** Every `POST /v1/purchases/verify` outcome (`code`), for the verify error rate (04 §14). */
  | 'purchase_verify'
  | 'purchase_revoked'
  | 'reward_issued'
  | 'reward_granted'
  | 'reward_rejected'
  | 'reading_reported'
  | 'install_registered'
  | 'attest_failed'
  | 'rate_limited'
  | 'budget_block'
  | 'hold_abandoned'
  | 'reading_undelivered_refund'
  | 'blocked_purchase'
  | 'sandbox_grant'
  | 'binding_mismatch'
  | 'devicecheck_error'
  | 'webhook_sig_failed';

export interface MetricPoint {
  readonly event: MetricEvent;
  readonly platform?: string;
  readonly locale?: string;
  readonly model?: string;
  readonly promptVersion?: string;
  readonly chargeSource?: string;
  /** Safety category or error code / sub-reason. */
  readonly code?: string;
  readonly costMicroUsd?: number;
  readonly latencyMs?: number;
  readonly inputTokens?: number;
  readonly outputTokens?: number;
  readonly credits?: number;
}

export interface Metrics {
  write(point: MetricPoint): void;
}
