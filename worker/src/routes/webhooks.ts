import { createRoute, z, type OpenAPIHono } from '@hono/zod-openapi';
import type { MiddlewareHandler } from 'hono';
import type { Deps } from '../deps';
import type { AppEnv } from '../http/context';
import { WebhookService } from '../services/WebhookService';
import { SIGNATURE_ROUTE_DOC } from './admobSsv';

/** ASSN v2 body (03 §6.4). */
export const AppStoreNotificationSchema = z
  .object({
    signedPayload: z
      .string()
      .min(1)
      .max(100_000)
      .openapi({ description: 'JWS (x5c → Apple Root CA G3) of `responseBodyV2DecodedPayload`' }),
  })
  .openapi('AppStoreNotification');

/** Pub/Sub push body (03 §6.4). */
export const PubsubPushSchema = z
  .object({
    message: z.object({
      messageId: z.string().min(1).max(200),
      data: z
        .string()
        .max(100_000)
        .optional()
        .openapi({ description: 'base64 JSON of the RTDN `DeveloperNotification`' }),
      publishTime: z.string().optional(),
      attributes: z.record(z.string(), z.string()).optional(),
    }),
    subscription: z.string().optional(),
  })
  .openapi('PubsubPush');

/**
 * Store webhooks (03 §6.4, RC4). Called by Apple and Google, not the app: no
 * install token or `X-Taro-*` headers. Responses carry no body.
 *
 * - `POST /v1/webhooks/appstore`: `200` once the JWS verifies (including
 *   duplicates and ignored types), `400` only for a bad signature, `500` when
 *   handling failed (Apple retries).
 * - `POST /v1/webhooks/googleplay`: the Pub/Sub OIDC token is checked before
 *   the body is read (`401` otherwise); `204` once handled, `500` on a
 *   failure (Pub/Sub retries).
 */
export function registerWebhookRoutes(app: OpenAPIHono<AppEnv>, deps: Deps): void {
  const service = new WebhookService(deps);

  const appStore = createRoute({
    method: 'post',
    path: '/v1/webhooks/appstore',
    tags: ['webhooks'],
    summary: 'App Store Server Notifications v2 (03 §6.4)',
    ...SIGNATURE_ROUTE_DOC,
    request: {
      body: {
        required: true,
        content: { 'application/json': { schema: AppStoreNotificationSchema } },
      },
    },
    responses: {
      200: { description: 'Verified: handled, duplicate or ignored' },
      400: { description: 'Invalid body or signature' },
      500: { description: 'Handling failed; Apple retries' },
    },
  });
  app.openapi(appStore, async (c) => {
    const { signedPayload } = c.req.valid('json');
    const result = await service.handleAppStore(signedPayload);
    return c.body(null, result === 'accepted' ? 200 : 400);
  });

  const pubsubAuth: MiddlewareHandler<AppEnv> = async (c, next) => {
    if (await service.authorizePlayPush(c.req.header('Authorization'))) {
      await next();
      return undefined;
    }
    return c.body(null, 401);
  };
  const googlePlay = createRoute({
    method: 'post',
    path: '/v1/webhooks/googleplay',
    tags: ['webhooks'],
    summary: 'Google Play RTDN via Pub/Sub push (03 §6.4)',
    ...SIGNATURE_ROUTE_DOC,
    middleware: [pubsubAuth] as const,
    request: {
      body: {
        required: true,
        content: { 'application/json': { schema: PubsubPushSchema } },
      },
    },
    responses: {
      204: { description: 'Handled, duplicate or ignored' },
      400: { description: 'Invalid body' },
      401: { description: 'Missing or invalid Pub/Sub OIDC token' },
      500: { description: 'Handling failed; Pub/Sub retries' },
    },
  });
  app.openapi(googlePlay, async (c) => {
    const { message } = c.req.valid('json');
    await service.handlePlay(message);
    return c.body(null, 204);
  });
}
