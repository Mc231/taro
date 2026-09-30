import { createRoute, z, type OpenAPIHono } from '@hono/zod-openapi';
import type { MiddlewareHandler } from 'hono';
import type { Deps } from '../deps';
import { LOCALES, REFUSAL_CATEGORIES } from '../domain/types';
import type { AppContext, AppEnv } from '../http/context';
import { ApiError, ErrorEnvelopeSchema } from '../http/errors';
import { IDEMPOTENCY_KEY_HEADER } from '../http/middleware/idempotency';
import { clientNetwork } from '../http/middleware/rateLimit';
import { flagHeaders, routeGuards } from '../http/routeGuards';
import {
  AI_CONSENT_HEADER,
  GENERIC_REFUSAL,
  ReadingService,
  type ReadingRequestContext,
} from '../services/ReadingService';
import {
  balanceFor,
  BalanceDtoSchema,
  errorResponses,
  requireInstall,
  tokenRouteGuards,
} from './balance';

const errorJson = { 'application/json': { schema: ErrorEnvelopeSchema } } as const;

const uuid = z.uuid().openapi({ example: '0c6e7a52-3d1f-4b8e-9c2a-5e6f7a8b9c0d' });
const isoInstant = z.string().openapi({ format: 'date-time', example: '2026-09-26T09:25:02Z' });
const CHARGE_SOURCES = ['free', 'bonus', 'paid'] as const;
const READING_STATUSES = [
  'held',
  'generating',
  'completed',
  'declined',
  'failed',
  'no_credit',
  'expired_hold',
  'expired_refunded',
] as const;
/** Upper bound of the raw question before normalisation; the grapheme limit is `ai.questionMaxChars`. */
const QUESTION_MAX_RAW = 4000;

export const SpreadRefSchema = z
  .object({
    id: z.string().min(1).max(32).openapi({ example: 'three_ppf' }),
    version: z.int().min(1).openapi({ example: 1 }),
  })
  .openapi('SpreadRef');

export const HoldRequestSchema = z
  .object({ clientReadingId: uuid, spread: SpreadRefSchema, locale: z.enum(LOCALES) })
  .openapi('HoldRequest');

export const HoldSchema = z
  .object({
    clientReadingId: uuid,
    chargeSource: z.enum(CHARGE_SOURCES),
    expiresAt: isoInstant,
    balance: BalanceDtoSchema,
  })
  .openapi('Hold');

const DrawnCardSchema = z.object({
  positionId: z.string().min(1).max(32).openapi({ example: 'past' }),
  cardId: z.string().min(1).max(32).openapi({ example: 'major_16' }),
  reversed: z.boolean(),
});

export const ReadingRequestSchema = z
  .object({
    clientReadingId: uuid,
    spread: SpreadRefSchema,
    cards: z.array(DrawnCardSchema).min(1).max(10),
    question: z.string().max(QUESTION_MAX_RAW).optional(),
    locale: z.enum(LOCALES),
    drawnAt: z.iso.datetime().openapi({ example: '2026-09-26T09:10:02Z' }),
  })
  .openapi('ReadingRequest');

export const ReadingWireSchema = z
  .object({
    title: z.string(),
    overview: z.string(),
    cards: z.array(
      z.object({
        positionId: z.string(),
        cardId: z.string(),
        reversed: z.boolean(),
        interpretation: z.string(),
      }),
    ),
    synthesis: z.string(),
    reflectionPrompts: z.array(z.string()),
  })
  .openapi('ReadingWire');

export const CrisisResourceSchema = z
  .object({
    name: z.string(),
    phone: z.string().optional(),
    sms: z.string().optional(),
    url: z.string().optional(),
    hours: z.string().optional(),
    languages: z.array(z.string()),
    verifiedAt: z.string().nullable(),
  })
  .openapi('CrisisResource');

export const SafetySchema = z
  .object({
    category: z.enum([...REFUSAL_CATEGORIES, GENERIC_REFUSAL.category]),
    messageKey: z.string().openapi({ example: 'safetyDeclinedSelfHarm' }),
    crisisResources: z.array(CrisisResourceSchema),
    canRephrase: z.boolean(),
  })
  .openapi('Safety');

export const ReadingResponseSchema = z
  .object({
    readingId: z.string(),
    status: z.enum(['completed', 'declined']),
    chargeSource: z.enum([...CHARGE_SOURCES, 'none']),
    promptVersion: z.string().optional(),
    reading: ReadingWireSchema.optional(),
    safety: SafetySchema.optional(),
    balance: BalanceDtoSchema,
  })
  .openapi('ReadingResponse');

export const ReadingStateSchema = z
  .object({
    status: z.enum(READING_STATUSES),
    attempt: z.int(),
    chargeSource: z.enum([...CHARGE_SOURCES, 'none']).optional(),
    promptVersion: z.string().optional(),
    reading: ReadingWireSchema.optional(),
    safety: SafetySchema.optional(),
    balance: BalanceDtoSchema,
  })
  .openapi('ReadingState');

const ParamsSchema = z.object({
  clientReadingId: z
    .string()
    .min(1)
    .max(64)
    .openapi({
      param: { name: 'clientReadingId', in: 'path' },
      example: '0c6e7a52-3d1f-4b8e-9c2a-5e6f7a8b9c0d',
    }),
});

const readingHeaders = flagHeaders(['idem', 'attest']).extend({
  [AI_CONSENT_HEADER.toLowerCase()]: z.string().optional().openapi({
    description: 'AI consent version the user accepted (RC28); below `ai.consentVersion` → 412.',
    example: '1',
  }),
});

/** `request.cf.country`: used for the region gate and crisis resources, never stored. */
export function cfCountry(c: AppContext): string | null {
  const cf = (c.req.raw as { cf?: { country?: unknown } }).cf;
  return typeof cf?.country === 'string' && cf.country !== '' ? cf.country : null;
}

async function context(deps: Deps, c: AppContext): Promise<ReadingRequestContext> {
  const install = await requireInstall(deps, c);
  return {
    install,
    balance: () => balanceFor(deps, c, install.id),
    consent: c.req.header(AI_CONSENT_HEADER),
    country: cfCountry(c),
    network: clientNetwork(c),
    appVersion: c.get('client').appVersion,
  };
}

/** `Idempotency-Key == clientReadingId` on holds and readings (RC42). */
function requireKeyMatches(c: AppContext, clientReadingId: string): void {
  if (
    c.req.header(IDEMPOTENCY_KEY_HEADER)?.trim().toLowerCase() !== clientReadingId.toLowerCase()
  ) {
    throw new ApiError('VALIDATION_FAILED', {
      details: {
        issues: [
          {
            path: IDEMPOTENCY_KEY_HEADER,
            code: 'custom',
            message: 'must equal clientReadingId (RC42)',
          },
        ],
      },
    });
  }
}

const readingErrors = {
  400: { description: 'VALIDATION_FAILED or IDEMPOTENCY_KEY_REQUIRED', content: errorJson },
  403: { description: 'AI_UNAVAILABLE_REGION or ATTESTATION_FAILED', content: errorJson },
  409: { description: 'REQUEST_IN_PROGRESS or HOLD_CONFLICT', content: errorJson },
  412: { description: 'AI_CONSENT_REQUIRED (details.requiredVersion)', content: errorJson },
  422: {
    description: 'SPREAD_INVALID (details.reason) or IDEMPOTENCY_KEY_REUSED',
    content: errorJson,
  },
  503: {
    description: 'READINGS_DISABLED, AI_BUDGET_EXHAUSTED (details.tier) or AI_UNAVAILABLE',
    content: errorJson,
  },
  ...errorResponses,
} as const;

/**
 * AI reading routes (03 §9.0, §9.1; RC42, RC49–RC51):
 * `POST /v1/readings/holds` and `POST /v1/readings` **[idem] [attest]**
 * (`Idempotency-Key == clientReadingId`), `GET /v1/readings/{clientReadingId}`
 * and `POST /v1/readings/{clientReadingId}/ack` (auth). The report route is
 * `routes/readingReports.ts`.
 */
export function registerReadingRoutes(
  app: OpenAPIHono<AppEnv>,
  deps: Deps,
  auth: MiddlewareHandler<AppEnv>,
): void {
  const service = new ReadingService(deps);

  const holdRoute = createRoute({
    method: 'post',
    path: '/v1/readings/holds',
    tags: ['readings'],
    summary: 'Pre-draw hold: reserve one reading before the shuffle (03 §9.0, RC50)',
    // A retry must renew the live hold (fresh `expiresAt`), so nothing is replayed.
    ...routeGuards(
      deps,
      {
        auth: 'token',
        rateLimit: 'install',
        flags: ['idem', 'attest'],
        idempotency: { storeResponses: false },
      },
      auth,
    ),
    request: {
      headers: readingHeaders,
      body: { required: true, content: { 'application/json': { schema: HoldRequestSchema } } },
    },
    responses: {
      201: {
        description: 'Held (or a live hold renewed)',
        content: { 'application/json': { schema: HoldSchema } },
      },
      402: {
        description: 'INSUFFICIENT_CREDITS (details.reason, details.freeResetsAt)',
        content: errorJson,
      },
      ...readingErrors,
    },
  });
  app.openapi(holdRoute, async (c) => {
    const body = c.req.valid('json');
    requireKeyMatches(c, body.clientReadingId);
    return c.json(await service.hold(await context(deps, c), body), 201);
  });

  const createReading = createRoute({
    method: 'post',
    path: '/v1/readings',
    tags: ['readings'],
    summary: 'Generate the AI reading of a drawn spread (03 §9.1)',
    ...tokenRouteGuards(deps, auth, ['idem', 'attest']),
    request: {
      headers: readingHeaders,
      body: { required: true, content: { 'application/json': { schema: ReadingRequestSchema } } },
    },
    responses: {
      200: {
        description: 'Completed, or declined (never charged)',
        content: { 'application/json': { schema: ReadingResponseSchema } },
      },
      402: { description: 'INSUFFICIENT_CREDITS (a new row without a hold)', content: errorJson },
      410: {
        description: 'READING_EXPIRED_REFUNDED (details.balance)',
        content: errorJson,
      },
      ...readingErrors,
    },
  });
  app.openapi(createReading, async (c) => {
    const body = c.req.valid('json');
    requireKeyMatches(c, body.clientReadingId);
    return c.json(await service.create(await context(deps, c), body), 200);
  });

  const getReading = createRoute({
    method: 'get',
    path: '/v1/readings/{clientReadingId}',
    tags: ['readings'],
    summary: 'Reading status and, until acknowledged, its text (03 §9.1, RC51)',
    ...tokenRouteGuards(deps, auth),
    request: { params: ParamsSchema },
    responses: {
      200: {
        description: 'Status',
        content: { 'application/json': { schema: ReadingStateSchema } },
      },
      404: { description: 'No reading with this clientReadingId', content: errorJson },
      410: {
        description: 'READING_EXPIRED_REFUNDED: never delivered, refunded once',
        content: errorJson,
      },
      ...errorResponses,
    },
  });
  app.openapi(getReading, async (c) => {
    const { clientReadingId } = c.req.valid('param');
    return c.json(await service.status(await context(deps, c), clientReadingId), 200);
  });

  const ackReading = createRoute({
    method: 'post',
    path: '/v1/readings/{clientReadingId}/ack',
    tags: ['readings'],
    summary: 'Acknowledge delivery; the stored reading text is deleted (03 §9.1, RC51)',
    ...tokenRouteGuards(deps, auth),
    request: { params: ParamsSchema },
    responses: {
      204: { description: 'Acknowledged (also when already acknowledged)' },
      404: { description: 'No reading with this clientReadingId', content: errorJson },
      ...errorResponses,
    },
  });
  app.openapi(ackReading, async (c) => {
    const install = await requireInstall(deps, c);
    await service.ack(install.id, c.req.valid('param').clientReadingId);
    return c.body(null, 204);
  });
}
