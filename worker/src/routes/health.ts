import { createRoute, z, type OpenAPIHono } from '@hono/zod-openapi';
import type { Deps } from '../deps';
import type { AppEnv } from '../http/context';
import { PUBLIC_ROUTE_DOC } from '../http/routeGuards';

export const HealthResponseSchema = z
  .object({
    status: z.literal('ok'),
    workerVersion: z.string(),
    environment: z.enum(['dev', 'staging', 'prod']),
  })
  .openapi('HealthResponse');

export type HealthResponse = z.infer<typeof HealthResponseSchema>;

const healthRoute = createRoute({
  method: 'get',
  path: '/v1/health',
  tags: ['health'],
  ...PUBLIC_ROUTE_DOC,
  summary: 'Liveness and version (public smoke check, 03 §14.2)',
  responses: {
    200: {
      description: 'Worker is up',
      content: { 'application/json': { schema: HealthResponseSchema } },
    },
  },
});

/** `GET /v1/health` → `{ status, workerVersion, environment }`. */
export function registerHealthRoutes(app: OpenAPIHono<AppEnv>, deps: Deps): void {
  app.openapi(healthRoute, (c) =>
    c.json(
      {
        status: 'ok',
        workerVersion: deps.workerVersion,
        environment: deps.environment,
      } satisfies HealthResponse,
      200,
    ),
  );
}
