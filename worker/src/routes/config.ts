import { createRoute, z, type OpenAPIHono } from '@hono/zod-openapi';
import { buildPublicConfigDto, configEtag, ifNoneMatchHits } from '../config/publicDto';
import { toPublicConfig } from '../config/schema';
import type { Deps } from '../deps';
import type { AppEnv } from '../http/context';
import { PUBLIC_ROUTE_DOC } from '../http/routeGuards';

/** Clients and intermediaries may reuse the document for 5 minutes (03 §8.1). */
export const CONFIG_CACHE_CONTROL = 'public, max-age=300';

/**
 * Wire shape of `PublicConfigDto`: flat dotted keys (GLOSSARY §8.1), which
 * the client's `RemoteConfig.fromJson` reads and clamps. Values are validated
 * by the config schema before they get here, so the OpenAPI schema documents
 * the shape only.
 */
export const PublicConfigDtoSchema = z
  .object({ version: z.int() })
  .catchall(z.unknown())
  .openapi('PublicConfigDto', {
    description:
      'Public remote config (03 §8.2). Keys are the GLOSSARY §8.1 names; store.packs[] carries the Worker-injected credits.',
  });

const configRoute = createRoute({
  method: 'get',
  path: '/v1/config',
  tags: ['config'],
  ...PUBLIC_ROUTE_DOC,
  summary: 'Public remote config with ETag (03 §8.1)',
  request: {
    headers: z.object({ 'if-none-match': z.string().optional() }),
  },
  responses: {
    200: {
      description: 'Active public config',
      headers: z.object({ ETag: z.string(), 'Cache-Control': z.string() }),
      content: { 'application/json': { schema: PublicConfigDtoSchema } },
    },
    304: {
      description: 'Unchanged since the ETag in If-None-Match',
      headers: z.object({ ETag: z.string(), 'Cache-Control': z.string() }),
    },
  },
});

/** `GET /v1/config` (public): `ETag: "v{version}"`, `Cache-Control: public, max-age=300`, 304 on match. */
export function registerConfigRoutes(app: OpenAPIHono<AppEnv>, deps: Deps): void {
  app.openapi(configRoute, async (c) => {
    const snapshot = await deps.config.snapshot();
    const etag = configEtag(snapshot.version);
    c.header('ETag', etag);
    c.header('Cache-Control', CONFIG_CACHE_CONTROL);
    if (ifNoneMatchHits(c.req.header('If-None-Match'), etag)) {
      return c.body(null, 304);
    }
    return c.json(buildPublicConfigDto(toPublicConfig(snapshot)), 200);
  });
}
