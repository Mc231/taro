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
  | 'webhook_sig_failed'
  /** One per HTTP response, `code` = status (the 5xx rate of `AlertService`, 03 §14.1). */
  | 'http_response'
  /** Outage fallback taken (`code` = from, `model` = to `provider/model`; 03 §9.3, RC97). */
  | 'ai_outage_fallback'
  /** A tier's provider has no key (`code` = tier, `model` = routed `provider/model`; RC97). */
  | 'ai_provider_unavailable';

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

/** Sample-weighted count of one `(event, code)` pair in a query window. */
export interface MetricCount {
  readonly event: MetricEvent;
  /** `MetricPoint.code`, `''` when none was written. */
  readonly code: string;
  readonly count: number;
}

export interface MetricCountQuery {
  readonly events: readonly MetricEvent[];
  /** The window ends now and starts `windowMinutes` earlier. */
  readonly windowMinutes: number;
}

export interface Metrics {
  write(point: MetricPoint): void;
  /**
   * Read side (`AlertService`, 03 §14.1): counts per `(event, code)` over the
   * window. `null` when the query side is not configured (dev, or the
   * Analytics Engine SQL API credentials are missing). Never throws.
   */
  counts(query: MetricCountQuery): Promise<readonly MetricCount[] | null>;
}
