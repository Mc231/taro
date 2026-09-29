import { createRoute, z, type OpenAPIHono } from '@hono/zod-openapi';
import type { MiddlewareHandler } from 'hono';
import type { Deps } from '../deps';
import type { AppEnv } from '../http/context';
import { ApiError, ErrorEnvelopeSchema } from '../http/errors';
import { clientNetwork } from '../http/middleware/rateLimit';
import { flagHeaders } from '../http/routeGuards';
import { PurchaseService } from '../services/PurchaseService';
import { BalanceDtoSchema, errorResponses, requireInstall, tokenRouteGuards } from './balance';

const productId = z.string().min(1).max(200).openapi({ example: 'com.vshyrochuk.taro.readings_3' });

/**
 * Optional support `transferToken` the "Move readings" flow sends when it
 * re-submits a transaction (02 §6.3, RC84). Accepted for the client contract;
 * the grant does not depend on it (the owner-run transfer script checks it,
 * 03 §6.6).
 */
const transferToken = z
  .string()
  .min(1)
  .max(1024)
  .optional()
  .openapi({ description: 'Support transfer code being re-submitted (RC84); informational' });

/** `POST /v1/purchases/verify` body (03 §6.2, §6.3; RC4): `platform` must equal `X-Taro-Platform`. */
export const VerifyPurchaseRequestSchema = z
  .discriminatedUnion('platform', [
    z.object({
      platform: z.literal('ios'),
      productId,
      transactionId: z.string().regex(/^\d{1,40}$/, 'expected a numeric transaction ID'),
      signedTransaction: z.string().min(1).max(20000).optional(),
      transferToken,
    }),
    z.object({
      platform: z.literal('android'),
      productId,
      purchaseToken: z.string().min(1).max(4096),
      orderId: z.string().min(1).max(200).optional(),
      transferToken,
    }),
  ])
  .openapi('VerifyPurchaseRequest');

/** `200` body (03 §6.2 step 5). */
export const VerifyPurchaseGrantedSchema = z
  .object({
    status: z.enum(['granted', 'already_granted']),
    purchaseId: z.string(),
    productId: z.string(),
    creditsGranted: z.int(),
    isFirstPurchase: z.boolean(),
    balance: BalanceDtoSchema,
  })
  .openapi('VerifyPurchaseGranted');

/** `202` body: Android pending purchase (03 §6.3). */
export const VerifyPurchasePendingSchema = z
  .object({ status: z.literal('pending') })
  .openapi('VerifyPurchasePending');

const errorJson = { 'application/json': { schema: ErrorEnvelopeSchema } } as const;

/**
 * `POST /v1/purchases/verify` **[idem]** (03 §6.2, §6.3; RC4, RC11): token
 * auth, no call attestation. Grants a verified consumable exactly once.
 */
export function registerPurchaseRoutes(
  app: OpenAPIHono<AppEnv>,
  deps: Deps,
  auth: MiddlewareHandler<AppEnv>,
): void {
  const service = new PurchaseService(deps);
  const route = createRoute({
    method: 'post',
    path: '/v1/purchases/verify',
    tags: ['purchases'],
    summary: 'Verify a store purchase and grant its credits (03 §6.2, §6.3)',
    ...tokenRouteGuards(deps, auth, ['idem']),
    request: {
      headers: flagHeaders(['idem']),
      body: {
        required: true,
        content: { 'application/json': { schema: VerifyPurchaseRequestSchema } },
      },
    },
    responses: {
      200: {
        description: 'Granted now, or an idempotent replay for this install (`already_granted`)',
        content: { 'application/json': { schema: VerifyPurchaseGrantedSchema } },
      },
      202: {
        description: 'Android pending purchase; nothing granted yet',
        content: { 'application/json': { schema: VerifyPurchasePendingSchema } },
      },
      400: { description: 'Invalid body or missing Idempotency-Key', content: errorJson },
      409: {
        description:
          'PURCHASE_ALREADY_CLAIMED (details.transferEligible, details.transferToken) or REQUEST_IN_PROGRESS',
        content: errorJson,
      },
      422: {
        description: 'PURCHASE_INVALID (details.reason, e.g. sandbox_cap) or PRODUCT_UNKNOWN',
        content: errorJson,
      },
      500: { description: 'Store unavailable; retry later', content: errorJson },
      ...errorResponses,
    },
  });
  app.openapi(route, async (c) => {
    const install = await requireInstall(deps, c);
    const body = c.req.valid('json');
    if (body.platform !== c.get('client').platform) {
      throw new ApiError('VALIDATION_FAILED', {
        details: {
          issues: [{ path: 'platform', code: 'custom', message: 'must equal X-Taro-Platform' }],
        },
      });
    }
    const result = await service.verify(install, body, {
      appVersion: c.get('client').appVersion,
      network: clientNetwork(c),
    });
    return result.status === 'pending' ? c.json(result, 202) : c.json(result, 200);
  });
}
