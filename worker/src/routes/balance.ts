import { createRoute, z, type OpenAPIHono } from '@hono/zod-openapi';
import type { MiddlewareHandler } from 'hono';
import type { Deps } from '../deps';
import type { BalanceDto } from '../domain/allowance';
import type { AppContext, AppEnv } from '../http/context';
import { ApiError, ErrorEnvelopeSchema } from '../http/errors';
import { clientNetwork } from '../http/middleware/rateLimit';
import { routeGuards, type RouteFlag } from '../http/routeGuards';
import { InstallRepo, type InstallRow } from '../repos/InstallRepo';
import { BalanceService } from '../services/BalanceService';

const isoInstant = z.string().openapi({ format: 'date-time', example: '2026-09-26T22:00:00Z' });

/** `BalanceDto` (03 §5.1; RC6, RC64, RC66, RC67, RC74). */
export const BalanceDtoSchema = z
  .object({
    free: z.object({
      limit: z.int(),
      used: z.int(),
      remaining: z.int(),
      localDate: z.string().openapi({ format: 'date', example: '2026-09-26' }),
      resetsAt: isoInstant,
      timezone: z.string().openapi({ example: 'Europe/Berlin' }),
      paused: z.boolean(),
    }),
    bonus: z.int(),
    paid: z.int(),
    canRead: z.boolean(),
    canReadReason: z.enum(['noCredits', 'dailyLimit', 'lowTrustCap', 'readingsPaused']).nullable(),
    nextSource: z.enum(['free', 'bonus', 'paid']).nullable(),
    rewarded: z.object({
      enabled: z.boolean(),
      amount: z.int(),
      dailyCap: z.int(),
      grantedToday: z.int(),
      available: z.boolean(),
      cooldownEndsAt: isoInstant.nullable(),
    }),
    paidBlocked: z.boolean(),
    purchasesAllowed: z.boolean(),
    purchasesBlockedReason: z.enum(['blocked', 'refundDebt', 'storeDisabled']).nullable(),
    ledgerVersion: z.int(),
    serverTime: isoInstant,
  })
  .openapi('BalanceDto');

/** The wire schema and the domain type must agree (a compile-time check). */
export type BalanceDtoWire = z.infer<typeof BalanceDtoSchema>;
export const BALANCE_DTO_SHAPE_MATCHES: BalanceDtoWire extends BalanceDto
  ? BalanceDto extends BalanceDtoWire
    ? true
    : never
  : never = true;

export const errorResponses = {
  401: {
    description: 'Missing or invalid install token',
    content: { 'application/json': { schema: ErrorEnvelopeSchema } },
  },
  429: {
    description: 'Rate limited',
    content: { 'application/json': { schema: ErrorEnvelopeSchema } },
  },
} as const;

/**
 * Guards of a token route (03 §2.1): the auth middleware (sets
 * `c.var.installId`), the required `X-Taro-*` headers, the burst limiter per
 * install, plus the route's `[idem]` / `[attest]` flags.
 */
export function tokenRouteGuards(
  deps: Deps,
  auth: MiddlewareHandler<AppEnv>,
  flags: readonly RouteFlag[] = [],
): ReturnType<typeof routeGuards> {
  return routeGuards(deps, { auth: 'token', rateLimit: 'install', flags }, auth);
}

/** `c.var.installId` (set by auth), or `401 UNAUTHENTICATED`. */
export function authenticatedId(c: AppContext): string {
  const installId = c.get('installId');
  if (installId === undefined) {
    throw new ApiError('UNAUTHENTICATED');
  }
  return installId;
}

/** The install row auth loaded (or a fresh read), or `401 UNAUTHENTICATED` (unknown or `deleted`). */
export async function requireInstall(deps: Deps, c: AppContext): Promise<InstallRow> {
  const install = c.get('install') ?? (await new InstallRepo(deps.db).findById(authenticatedId(c)));
  if (install === null || install.status === 'deleted') {
    throw new ApiError('UNAUTHENTICATED');
  }
  return install;
}

/** `BalanceService.read` for the request's install and client, or `401`. */
export async function balanceFor(
  deps: Deps,
  c: AppContext,
  installId: string,
): Promise<BalanceDto> {
  const balance = await new BalanceService(deps).read(installId, {
    appVersion: c.get('client').appVersion,
    network: clientNetwork(c),
  });
  if (balance === null) {
    throw new ApiError('UNAUTHENTICATED');
  }
  return balance;
}

/** `GET /v1/balance` (auth, 03 §5.1): read-only, also the resume sync path (RC46). */
export function registerBalanceRoutes(
  app: OpenAPIHono<AppEnv>,
  deps: Deps,
  auth: MiddlewareHandler<AppEnv>,
): void {
  const route = createRoute({
    method: 'get',
    path: '/v1/balance',
    tags: ['balance'],
    summary: 'Balance, free allowance and rewarded status (03 §5.1)',
    ...tokenRouteGuards(deps, auth),
    responses: {
      200: {
        description: 'Current balance',
        content: { 'application/json': { schema: BalanceDtoSchema } },
      },
      ...errorResponses,
    },
  });
  app.openapi(route, async (c) => {
    return c.json(await balanceFor(deps, c, authenticatedId(c)), 200);
  });
}
