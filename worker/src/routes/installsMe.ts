import { createRoute, z, type OpenAPIHono } from '@hono/zod-openapi';
import type { MiddlewareHandler } from 'hono';
import type { Deps } from '../deps';
import { isValidTimeZone } from '../domain/dayBoundary';
import type { AppEnv } from '../http/context';
import { ErrorEnvelopeSchema } from '../http/errors';
import { flagHeaders } from '../http/routeGuards';
import { InstallService } from '../services/InstallService';
import {
  balanceFor,
  BalanceDtoSchema,
  errorResponses,
  requireInstall,
  tokenRouteGuards,
} from './balance';

export const TimezoneRequestSchema = z
  .object({
    timezone: z
      .string()
      .refine(isValidTimeZone, { message: 'not an IANA timezone' })
      .openapi({ example: 'America/New_York' }),
  })
  .openapi('TimezoneRequest');

const idempotencyHeaders = flagHeaders(['idem']);

const errorJson = { 'application/json': { schema: ErrorEnvelopeSchema } } as const;

/**
 * `PUT /v1/installs/me/timezone` **[idem]** (03 §3.5) and
 * `DELETE /v1/installs/me` **[idem]** (03 §3.6, RC37). Both need the install
 * token (`auth`); the idempotency scope is the authenticated install.
 */
export function registerInstallMeRoutes(
  app: OpenAPIHono<AppEnv>,
  deps: Deps,
  auth: MiddlewareHandler<AppEnv>,
): void {
  const service = new InstallService(deps);

  const timezoneRoute = createRoute({
    method: 'put',
    path: '/v1/installs/me/timezone',
    tags: ['installs'],
    summary: 'Change the install timezone (24 h cooldown) and return the balance (03 §3.5)',
    ...tokenRouteGuards(deps, auth, ['idem']),
    request: {
      headers: idempotencyHeaders,
      body: { required: true, content: { 'application/json': { schema: TimezoneRequestSchema } } },
    },
    responses: {
      200: {
        description: 'Timezone stored (or unchanged); the resulting balance',
        content: { 'application/json': { schema: BalanceDtoSchema } },
      },
      400: { description: 'Invalid timezone or missing Idempotency-Key', content: errorJson },
      409: {
        description: 'TIMEZONE_CHANGE_TOO_SOON (details.allowedAfter) or REQUEST_IN_PROGRESS',
        content: errorJson,
      },
      ...errorResponses,
    },
  });
  app.openapi(timezoneRoute, async (c) => {
    const install = await requireInstall(deps, c);
    const { timezone } = c.req.valid('json');
    await service.changeTimezone(install, timezone);
    return c.json(await balanceFor(deps, c, install.id), 200);
  });

  const eraseRoute = createRoute({
    method: 'delete',
    path: '/v1/installs/me',
    tags: ['installs'],
    summary: 'Erase personal usage data; keeps the install, ledger and purchases (03 §3.6)',
    ...tokenRouteGuards(deps, auth, ['idem']),
    request: { headers: idempotencyHeaders },
    responses: {
      204: { description: 'Erased' },
      400: { description: 'Missing Idempotency-Key', content: errorJson },
      409: { description: 'REQUEST_IN_PROGRESS', content: errorJson },
      ...errorResponses,
    },
  });
  app.openapi(eraseRoute, async (c) => {
    const install = await requireInstall(deps, c);
    await service.erase(install, c.get('idempotency'));
    return c.body(null, 204);
  });
}
