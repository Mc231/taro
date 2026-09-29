import type { Context } from 'hono';
import type { Locale, Platform, Trust } from '../domain/types';
import type { InstallRow } from '../repos/InstallRepo';
import type { IdempotencyKeyRef } from '../repos/IdempotencyRepo';
import type { ErrorCode } from './errors';

/** Parsed `X-Taro-*` client headers (03 §2.1); absent or invalid values are undefined. */
export interface ClientInfo {
  readonly platform?: Platform;
  readonly appVersion?: string;
  readonly locale?: Locale;
}

/** Per-request values set by middleware. */
export interface AppVariables {
  requestId: string;
  client: ClientInfo;
  /** Set by the auth middleware (Phase 6.3) or a route's idempotency scope. */
  installId?: string;
  /** The authenticated `installs` row, loaded once by the auth middleware (03 §3.4). */
  install?: InstallRow;
  /**
   * Trust of this request after call attestation (`[attest]` routes, 03 §3.4):
   * the install's trust, or `low` when the request was downgraded.
   */
  requestTrust?: Trust;
  /** The running `[idem]` request's key, set by the idempotency middleware (erasure keeps it). */
  idempotency?: IdempotencyKeyRef;
  /** Error code of the response, for the request log line. */
  errorCode?: ErrorCode;
}

export interface AppEnv {
  Variables: AppVariables;
}

export type AppContext = Context<AppEnv>;
