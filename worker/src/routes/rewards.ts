import { createRoute, z, type OpenAPIHono } from '@hono/zod-openapi';
import type { MiddlewareHandler } from 'hono';
import type { Deps } from '../deps';
import type { AppEnv } from '../http/context';
import { ErrorEnvelopeSchema } from '../http/errors';
import { clientNetwork } from '../http/middleware/rateLimit';
import { flagHeaders } from '../http/routeGuards';
import { RewardService } from '../services/RewardService';
import {
  authenticatedId,
  balanceFor,
  BalanceDtoSchema,
  errorResponses,
  requireInstall,
  tokenRouteGuards,
} from './balance';

const errorJson = { 'application/json': { schema: ErrorEnvelopeSchema } } as const;

export const RewardIntentRequestSchema = z
  .object({
    adUnitId: z
      .string()
      .min(1)
      .max(128)
      .openapi({ example: 'ca-app-pub-3940256099942544/1712485313' }),
  })
  .openapi('RewardIntentRequest');

/** `customData == userId == intentId` (RC56): the install ID never goes to Google. */
export const RewardIntentSchema = z
  .object({
    intentId: z.string().openapi({ example: 'q8ZpYf1bQ0a3xT9mK2nR7w' }),
    customData: z.string(),
    userId: z.string(),
    amount: z.int(),
    expiresAt: z.string().openapi({ format: 'date-time', example: '2026-09-26T10:15:00Z' }),
  })
  .openapi('RewardIntent');

export const RewardIntentStatusSchema = z
  .object({
    status: z.enum(['issued', 'granted', 'cancelled', 'expired', 'rejected']),
    amount: z.int(),
    balance: BalanceDtoSchema.optional(),
  })
  .openapi('RewardIntentStatus');

const IntentParamsSchema = z.object({
  intentId: z
    .string()
    .min(1)
    .max(64)
    .openapi({ param: { name: 'intentId', in: 'path' }, example: 'q8ZpYf1bQ0a3xT9mK2nR7w' }),
});

/**
 * Reward intents (03 §7.1, §7.3; RC56, RC57): `POST /v1/rewards/intents`
 * **[idem] [attest]**, `GET /v1/rewards/intents/{intentId}` and
 * `POST /v1/rewards/intents/{intentId}/cancel` (auth). The grant itself only
 * happens through `GET /v1/ads/admob/ssv` (BE14).
 */
export function registerRewardRoutes(
  app: OpenAPIHono<AppEnv>,
  deps: Deps,
  auth: MiddlewareHandler<AppEnv>,
): void {
  const service = new RewardService(deps);

  const createIntent = createRoute({
    method: 'post',
    path: '/v1/rewards/intents',
    tags: ['rewards'],
    summary: 'Open a reward intent before showing a rewarded ad (03 §7.1)',
    ...tokenRouteGuards(deps, auth, ['idem', 'attest']),
    request: {
      headers: flagHeaders(['idem', 'attest']),
      body: {
        required: true,
        content: { 'application/json': { schema: RewardIntentRequestSchema } },
      },
    },
    responses: {
      201: {
        description: 'Intent issued; pass `intentId` as SSV `userId` and `customData`',
        content: { 'application/json': { schema: RewardIntentSchema } },
      },
      400: { description: 'Unknown ad unit or missing Idempotency-Key', content: errorJson },
      403: { description: 'REWARDED_DISABLED or ATTESTATION_FAILED', content: errorJson },
      409: {
        description:
          'REWARDED_DAILY_CAP (details.reason cap|cooldown, details.availableAt) or REQUEST_IN_PROGRESS',
        content: errorJson,
      },
      ...errorResponses,
    },
  });
  app.openapi(createIntent, async (c) => {
    const install = await requireInstall(deps, c);
    const { adUnitId } = c.req.valid('json');
    const intent = await service.createIntent({
      install,
      adUnitId,
      trust: c.get('requestTrust') ?? install.trust,
      network: clientNetwork(c),
    });
    return c.json(intent, 201);
  });

  const getIntent = createRoute({
    method: 'get',
    path: '/v1/rewards/intents/{intentId}',
    tags: ['rewards'],
    summary: 'Poll a reward intent; `balance` is included once granted (03 §7.3)',
    ...tokenRouteGuards(deps, auth),
    request: { params: IntentParamsSchema },
    responses: {
      200: {
        description: 'Intent status',
        content: { 'application/json': { schema: RewardIntentStatusSchema } },
      },
      404: { description: 'No such intent for this install', content: errorJson },
      ...errorResponses,
    },
  });
  app.openapi(getIntent, async (c) => {
    const installId = authenticatedId(c);
    const status = await service.status(installId, c.req.valid('param').intentId);
    if (status.status !== 'granted') {
      return c.json(status, 200);
    }
    return c.json({ ...status, balance: await balanceFor(deps, c, installId) }, 200);
  });

  const cancelIntent = createRoute({
    method: 'post',
    path: '/v1/rewards/intents/{intentId}/cancel',
    tags: ['rewards'],
    summary: 'Cancel an open reward intent after a load failure or early dismissal (03 §7.3)',
    ...tokenRouteGuards(deps, auth),
    request: { params: IntentParamsSchema },
    responses: {
      204: { description: 'Cancelled (or already settled)' },
      404: { description: 'No such intent for this install', content: errorJson },
      ...errorResponses,
    },
  });
  app.openapi(cancelIntent, async (c) => {
    await service.cancel(authenticatedId(c), c.req.valid('param').intentId);
    return c.body(null, 204);
  });
}
