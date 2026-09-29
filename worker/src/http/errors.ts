import { z, type OpenAPIHonoOptions } from '@hono/zod-openapi';
import type { Context, ErrorHandler, NotFoundHandler } from 'hono';
import { HTTPException } from 'hono/http-exception';
import type { ContentfulStatusCode } from 'hono/utils/http-status';
import type { Logger } from '../ports/Logger';
import type { AppEnv } from './context';

/**
 * The error envelope and code table (03 §2.2, BE16, RC5; GLOSSARY §5).
 * `tools/check_glossary.py` compares every quoted UPPER_SNAKE string in this
 * file with GLOSSARY §5, so no other such literal may appear here.
 * `PURCHASE_PENDING` is a `202` status body, not an error, and is not listed.
 */
export const ERROR_CODES = [
  'VALIDATION_FAILED',
  'IDEMPOTENCY_KEY_REQUIRED',
  'UNAUTHENTICATED',
  'TOKEN_EXPIRED',
  'ATTESTATION_REQUIRED',
  'INSUFFICIENT_CREDITS',
  'ATTESTATION_FAILED',
  'REWARDED_DISABLED',
  'AI_UNAVAILABLE_REGION',
  'NOT_FOUND',
  'REQUEST_IN_PROGRESS',
  'HOLD_CONFLICT',
  'PURCHASE_ALREADY_CLAIMED',
  'REWARDED_DAILY_CAP',
  'TIMEZONE_CHANGE_TOO_SOON',
  'READING_EXPIRED_REFUNDED',
  'AI_CONSENT_REQUIRED',
  'IDEMPOTENCY_KEY_REUSED',
  'PURCHASE_INVALID',
  'PRODUCT_UNKNOWN',
  'SPREAD_INVALID',
  'UPGRADE_REQUIRED',
  'RATE_LIMITED',
  'INTERNAL',
  'AI_UNAVAILABLE',
  'AI_BUDGET_EXHAUSTED',
  'READINGS_DISABLED',
] as const;

export type ErrorCode = (typeof ERROR_CODES)[number];

export interface ErrorSpec {
  readonly status: ContentfulStatusCode;
  readonly retryable: boolean;
  /** Developer-facing only; the client localises by `code` and never shows it. */
  readonly message: string;
}

export const ERROR_TABLE: Readonly<Record<ErrorCode, ErrorSpec>> = {
  VALIDATION_FAILED: { status: 400, retryable: false, message: 'Request validation failed.' },
  IDEMPOTENCY_KEY_REQUIRED: {
    status: 400,
    retryable: false,
    message: 'Idempotency-Key header is required.',
  },
  UNAUTHENTICATED: { status: 401, retryable: false, message: 'Missing or invalid install token.' },
  TOKEN_EXPIRED: { status: 401, retryable: false, message: 'Install token expired.' },
  ATTESTATION_REQUIRED: {
    status: 401,
    retryable: false,
    message: 'A valid attestation header is required.',
  },
  INSUFFICIENT_CREDITS: {
    status: 402,
    retryable: false,
    message: 'No free, bonus or paid readings available.',
  },
  ATTESTATION_FAILED: { status: 403, retryable: false, message: 'Attestation failed.' },
  REWARDED_DISABLED: { status: 403, retryable: false, message: 'Rewarded ads are disabled.' },
  AI_UNAVAILABLE_REGION: {
    status: 403,
    retryable: false,
    message: 'AI readings are not available in this region.',
  },
  NOT_FOUND: { status: 404, retryable: false, message: 'Not found.' },
  REQUEST_IN_PROGRESS: {
    status: 409,
    retryable: true,
    message: 'A request with this idempotency key is still in progress.',
  },
  HOLD_CONFLICT: { status: 409, retryable: false, message: 'The reading hold cannot be re-taken.' },
  PURCHASE_ALREADY_CLAIMED: {
    status: 409,
    retryable: false,
    message: 'Transaction was granted to another install.',
  },
  REWARDED_DAILY_CAP: {
    status: 409,
    retryable: false,
    message: 'Rewarded readings are capped or cooling down.',
  },
  TIMEZONE_CHANGE_TOO_SOON: {
    status: 409,
    retryable: false,
    message: 'Timezone was changed too recently.',
  },
  READING_EXPIRED_REFUNDED: {
    status: 410,
    retryable: false,
    message: 'The reading expired undelivered and was refunded.',
  },
  AI_CONSENT_REQUIRED: {
    status: 412,
    retryable: false,
    message: 'AI consent is missing or outdated.',
  },
  IDEMPOTENCY_KEY_REUSED: {
    status: 422,
    retryable: false,
    message: 'Idempotency-Key was reused with a different request.',
  },
  PURCHASE_INVALID: { status: 422, retryable: false, message: 'Purchase could not be verified.' },
  PRODUCT_UNKNOWN: { status: 422, retryable: false, message: 'Unknown product.' },
  SPREAD_INVALID: { status: 422, retryable: false, message: 'Invalid spread or cards.' },
  UPGRADE_REQUIRED: { status: 426, retryable: false, message: 'App version is too old.' },
  RATE_LIMITED: { status: 429, retryable: true, message: 'Too many requests.' },
  INTERNAL: { status: 500, retryable: true, message: 'Internal error.' },
  AI_UNAVAILABLE: { status: 503, retryable: true, message: 'AI provider unavailable.' },
  AI_BUDGET_EXHAUSTED: { status: 503, retryable: true, message: 'AI readings are paused.' },
  READINGS_DISABLED: { status: 503, retryable: true, message: 'Readings are disabled.' },
};

export type ErrorDetails = Readonly<Record<string, unknown>>;

export interface ApiErrorOptions {
  readonly details?: ErrorDetails;
  readonly retryAfterSec?: number;
}

/** Thrown anywhere in a request; `app.onError` turns it into the envelope. */
export class ApiError extends Error {
  override readonly name = 'ApiError';

  constructor(
    readonly code: ErrorCode,
    readonly options: ApiErrorOptions = {},
  ) {
    super(code);
  }
}

export const ErrorEnvelopeSchema = z
  .object({
    error: z.object({
      code: z.enum(ERROR_CODES),
      message: z.string(),
      requestId: z.string(),
      retryable: z.boolean(),
      retryAfterSec: z.number().int().nullable(),
      details: z.record(z.string(), z.unknown()).optional(),
    }),
  })
  .openapi('ErrorEnvelope');

export type ErrorEnvelope = z.infer<typeof ErrorEnvelopeSchema>;

/** Builds the envelope response; sets `Retry-After` when `retryAfterSec` is given. */
export function errorResponse(
  c: Context<AppEnv>,
  code: ErrorCode,
  options: ApiErrorOptions = {},
): Response {
  const spec = ERROR_TABLE[code];
  c.set('errorCode', code);
  const body: ErrorEnvelope = {
    error: {
      code,
      message: spec.message,
      requestId: c.get('requestId'),
      retryable: spec.retryable,
      retryAfterSec: options.retryAfterSec ?? null,
      ...(options.details === undefined ? {} : { details: options.details }),
    },
  };
  if (options.retryAfterSec !== undefined) {
    c.header('Retry-After', String(options.retryAfterSec));
  }
  return c.json(body, spec.status);
}

function codeForHttpException(status: number): ErrorCode {
  switch (status) {
    case 400:
      return 'VALIDATION_FAILED';
    case 401:
      return 'UNAUTHENTICATED';
    case 404:
      return 'NOT_FOUND';
    default:
      return 'INTERNAL';
  }
}

/** `app.onError`: `ApiError` → its code; anything else → `500 INTERNAL`, logged without payloads. */
export function errorHandler(logger: Logger): ErrorHandler<AppEnv> {
  return (err, c) => {
    if (err instanceof ApiError) {
      return errorResponse(c, err.code, err.options);
    }
    if (err instanceof HTTPException) {
      return errorResponse(c, codeForHttpException(err.status));
    }
    logger.log('error', 'unhandled_error', {
      requestId: c.get('requestId'),
      error: err.name,
      detail: err.message.slice(0, 200),
    });
    return errorResponse(c, 'INTERNAL');
  };
}

export const notFoundHandler: NotFoundHandler<AppEnv> = (c) => errorResponse(c, 'NOT_FOUND');

/** zod-openapi `defaultHook`: schema failures → `400 VALIDATION_FAILED` with `details.issues[]`. */
export const validationHook: NonNullable<OpenAPIHonoOptions<AppEnv>['defaultHook']> = (
  result,
  c,
) => {
  if (!result.success) {
    const issues = result.error.issues.map((issue) => ({
      path: issue.path.map(String).join('.'),
      code: issue.code,
      message: issue.message,
    }));
    return errorResponse(c, 'VALIDATION_FAILED', { details: { issues } });
  }
  return undefined;
};
