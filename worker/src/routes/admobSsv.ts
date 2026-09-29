import { createRoute, z, type OpenAPIHono } from '@hono/zod-openapi';
import { rawQuery } from '../adapters/admob/SsvVerifier';
import type { Deps } from '../deps';
import type { AppEnv } from '../http/context';
import { RewardService } from '../services/RewardService';

/** OpenAPI fields of a route authenticated by the caller's signature (AdMob, Apple, Google). */
export const SIGNATURE_ROUTE_DOC = {
  security: [] as Record<string, string[]>[],
  'x-taro-auth': 'signature' as const,
  'x-taro-flags': [] as ('idem' | 'attest')[],
};

const SsvQuerySchema = z.object({
  ad_network: z.string().optional(),
  ad_unit: z.string().optional(),
  custom_data: z.string().optional().openapi({ description: 'The reward `intentId` (RC56)' }),
  key_id: z.string().optional(),
  reward_amount: z
    .string()
    .optional()
    .openapi({ description: 'Ignored: the intent snapshot wins' }),
  reward_item: z.string().optional(),
  timestamp: z.string().optional(),
  transaction_id: z.string().optional(),
  user_id: z.string().optional().openapi({ description: 'Must equal `custom_data` (RC56)' }),
  signature: z.string().optional(),
});

/**
 * `GET /v1/ads/admob/ssv` (03 §7.2, BE14, RC4). Called by AdMob, not the
 * app: no install token or `X-Taro-*` headers; the ECDSA signature over the
 * raw query is the authentication. `403` only for a bad signature; every
 * other outcome is `200` so AdMob stops retrying.
 */
export function registerAdmobSsvRoute(app: OpenAPIHono<AppEnv>, deps: Deps): void {
  const service = new RewardService(deps);
  const route = createRoute({
    method: 'get',
    path: '/v1/ads/admob/ssv',
    tags: ['rewards'],
    summary: 'AdMob server-side verification callback (03 §7.2)',
    ...SIGNATURE_ROUTE_DOC,
    request: { query: SsvQuerySchema },
    responses: {
      200: { description: 'Accepted: granted, duplicate, or rejected without a grant' },
      403: { description: 'Invalid or unverifiable signature' },
    },
  });
  app.openapi(route, async (c) => {
    const outcome = await service.handleSsv(rawQuery(c.req.url));
    return c.body(null, outcome.kind === 'forbidden' ? 403 : 200);
  });
}
