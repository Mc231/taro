import { createRoute, z, type OpenAPIHono } from '@hono/zod-openapi';
import type { MiddlewareHandler } from 'hono';
import { sealReport, type ReportPayload } from '../crypto/reportPayload';
import type { Deps } from '../deps';
import { localDate, nextResetUtc } from '../domain/dayBoundary';
import { reportExpiry } from '../domain/retention';
import { LOCALES } from '../domain/types';
import type { AppEnv } from '../http/context';
import { ApiError, ErrorEnvelopeSchema } from '../http/errors';
import { flagHeaders } from '../http/routeGuards';
import { ReadingRepo } from '../repos/ReadingRepo';
import { ReportRepo, type ReportReason } from '../repos/ReportRepo';
import { installTimezone } from '../services/BalanceService';
import { errorResponses, requireInstall, tokenRouteGuards } from './balance';

const errorJson = { 'application/json': { schema: ErrorEnvelopeSchema } } as const;

/** At most 10 reports per install per local day (03 §9.7) → `429 RATE_LIMITED reason=reportLimit`. */
export const REPORTS_PER_DAY = 10;
/** Upper bound of the serialised `reading` object (a Celtic Cross reading is well below it). */
export const REPORT_READING_MAX_BYTES = 32 * 1024;

const REASONS = ['offensive', 'harmful_advice', 'sexual', 'hateful', 'other'] as const;
const REPORTABLE = new Set(['completed', 'declined']);

export const ReadingReportRequestSchema = z
  .object({
    reason: z.enum(REASONS),
    note: z.string().max(500).optional(),
    question: z.string().max(1000).optional(),
    /** The §9.1 wire object the client stored; the Worker keeps no reading text (BE13). */
    reading: z
      .record(z.string(), z.unknown())
      .refine(
        (r) => new TextEncoder().encode(JSON.stringify(r)).length <= REPORT_READING_MAX_BYTES,
        {
          message: `reading exceeds ${String(REPORT_READING_MAX_BYTES)} bytes`,
        },
      )
      .openapi({ example: { title: '…', overview: '…', cards: [], synthesis: '…' } }),
    locale: z.enum(LOCALES),
  })
  .openapi('ReadingReportRequest');

export const ReadingReportSchema = z
  .object({
    reportId: z.string().openapi({ example: '0192f0c1-7a4e-7b3d-9c2a-5e6f7a8b9c0d' }),
    status: z.literal('received'),
  })
  .openapi('ReadingReport');

const ParamsSchema = z.object({
  clientReadingId: z
    .string()
    .min(1)
    .max(64)
    .openapi({
      param: { name: 'clientReadingId', in: 'path' },
      example: '6d2f1c9e-2b7a-4f6e-9a51-3c8d0e4b7a21',
    }),
});

/**
 * `POST /v1/readings/{clientReadingId}/report` **[idem]** (03 §9.7; CS7,
 * RC22, RC72): the one user-initiated exception to "text is never stored".
 * The reading must be a `completed` or `declined` row of this install; one
 * report per reading (a repeat returns the stored report); at most 10 per
 * install per local day. The body is AES-256-GCM sealed with
 * `REPORT_ENC_KEY` and kept 90 days; emits `reading_reported{reason}`.
 */
export function registerReadingReportRoutes(
  app: OpenAPIHono<AppEnv>,
  deps: Deps,
  auth: MiddlewareHandler<AppEnv>,
): void {
  const readings = new ReadingRepo(deps.db);
  const reports = new ReportRepo(deps.db);

  const route = createRoute({
    method: 'post',
    path: '/v1/readings/{clientReadingId}/report',
    tags: ['readings'],
    summary: 'Report an AI reading (S33); stored encrypted for 90 days (03 §9.7)',
    ...tokenRouteGuards(deps, auth, ['idem']),
    request: {
      params: ParamsSchema,
      headers: flagHeaders(['idem']),
      body: {
        required: true,
        content: { 'application/json': { schema: ReadingReportRequestSchema } },
      },
    },
    responses: {
      201: {
        description: 'Report received (also for a reading already reported)',
        content: { 'application/json': { schema: ReadingReportSchema } },
      },
      400: { description: 'Invalid body or missing Idempotency-Key', content: errorJson },
      404: {
        description: 'No completed or declined reading with this clientReadingId',
        content: errorJson,
      },
      ...errorResponses,
    },
  });

  app.openapi(route, async (c) => {
    const install = await requireInstall(deps, c);
    const { clientReadingId } = c.req.valid('param');
    const body = c.req.valid('json');
    const reading = await readings.findByClientId(install.id, clientReadingId);
    if (reading === null || !REPORTABLE.has(reading.status)) {
      throw new ApiError('NOT_FOUND');
    }
    const existing = await reports.findByReading(install.id, clientReadingId);
    if (existing !== null) {
      return c.json({ reportId: existing.id, status: 'received' as const }, 201);
    }
    const now = deps.clock.now();
    const timezone = installTimezone(install);
    const today = localDate(now, timezone);
    if ((await reports.countForDay(install.id, today)) >= REPORTS_PER_DAY) {
      const retryAfterSec = Math.max(
        1,
        Math.ceil((nextResetUtc(now, timezone).getTime() - now.getTime()) / 1000),
      );
      throw new ApiError('RATE_LIMITED', { details: { reason: 'reportLimit' }, retryAfterSec });
    }
    const payload: ReportPayload = {
      reading: body.reading,
      ...(body.question === undefined ? {} : { question: body.question }),
      ...(body.note === undefined ? {} : { note: body.note }),
    };
    const ref = { installId: install.id, clientReadingId };
    const id = deps.ids.uuidV7();
    const inserted = await reports.insert({
      id,
      installId: install.id,
      clientReadingId,
      readingId: reading.id,
      localDate: today,
      reason: body.reason satisfies ReportReason,
      locale: body.locale,
      promptVersion: reading.promptVersion,
      model: reading.model,
      payloadEnc: await sealReport(deps.crypto, deps.keys.report(), ref, payload),
      createdAt: now.toISOString(),
      expiresAt: reportExpiry(now),
    });
    if (!inserted) {
      // A concurrent submit with another key won the race; answer with its report.
      const winner = await reports.findByReading(install.id, clientReadingId);
      return c.json({ reportId: winner?.id ?? id, status: 'received' as const }, 201);
    }
    deps.metrics.write({
      event: 'reading_reported',
      code: body.reason,
      locale: body.locale,
      platform: install.platform,
      ...(reading.model === null ? {} : { model: reading.model }),
      ...(reading.promptVersion === null ? {} : { promptVersion: reading.promptVersion }),
    });
    return c.json({ reportId: id, status: 'received' as const }, 201);
  });
}
