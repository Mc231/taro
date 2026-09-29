import { createRoute, z, type OpenAPIHono } from '@hono/zod-openapi';
import { buildPublicConfigDto } from '../config/publicDto';
import { toPublicConfig, type RuntimeConfig } from '../config/schema';
import { parseAppVersion } from '../domain/appVersion';
import { isUuid } from '../domain/purchaseBinding';
import { LOCALES, PLATFORMS } from '../domain/types';
import type { Deps } from '../deps';
import type { AppContext, AppEnv } from '../http/context';
import { ApiError, ErrorEnvelopeSchema } from '../http/errors';
import { DEBUG_ATTESTATION_HEADER, isDebugAttestation } from '../http/middleware/attestation';
import { clientNetwork } from '../http/middleware/rateLimit';
import { flagHeaders, routeGuards } from '../http/routeGuards';
import { InstallService, type Registration } from '../services/InstallService';
import { BalanceDtoSchema, balanceFor } from './balance';
import { PublicConfigDtoSchema } from './config';

/**
 * Identity routes (03 §3.3, §3.4; GLOSSARY E04, E05):
 * - `POST /v1/installs` **[idem]** — public (attestation in the body), a fresh
 *   `Idempotency-Key` per registration attempt (RC55), scoped to the body's
 *   `installId`; rate-limited per IP prefix. `201` new / `200` existing.
 * - `POST /v1/installs/token` **[attest]** — install token, which may be
 *   expired but otherwise valid; returns a fresh 7-day token.
 *
 * `PUT /v1/installs/me/timezone` and `DELETE /v1/installs/me` live in
 * `installsMe.ts` (Sprint 6.4).
 */
const BASE64URL_32_BYTES = /^[A-Za-z0-9_-]{43}$/;

function isTimeZone(value: string): boolean {
  try {
    new Intl.DateTimeFormat('en-US', { timeZone: value });
    return true;
  } catch {
    return false;
  }
}

const challengeField = z.string().min(1).max(128);
const optionalAssertion = z.string().min(1).max(8192).optional().openapi({
  description:
    'iOS only: App Attest assertion by the previously stored key over the registration hash, proving ownership when the install secret was lost (03 §3.3, RC54).',
});

const AttestationSchema = z
  .discriminatedUnion('type', [
    z.object({
      type: z.literal('app_attest'),
      challenge: challengeField,
      keyId: z.string().min(1).max(128),
      attestationObject: z.string().min(1).max(32768),
      previousKeyAssertion: optionalAssertion,
    }),
    z.object({
      type: z.literal('play_integrity'),
      challenge: challengeField,
      integrityToken: z.string().min(1).max(32768),
    }),
    z.object({
      type: z.literal('none'),
      challenge: challengeField,
      reason: z.enum(['unsupported', 'error', 'timeout']),
      pow: z.string().min(1).max(64).optional(),
      previousKeyAssertion: optionalAssertion,
    }),
  ])
  .openapi('RegistrationAttestation');

export const RegisterRequestSchema = z
  .object({
    installId: z.uuid({ version: 'v4' }),
    installSecret: z.string().regex(BASE64URL_32_BYTES).openapi({
      description: '32 random bytes, base64url; sent only on this route (RC54).',
    }),
    platform: z.enum(PLATFORMS),
    appVersion: z.string().refine((v) => parseAppVersion(v) !== undefined, 'invalid app version'),
    locale: z.enum(LOCALES),
    timezone: z.string().min(1).max(64).refine(isTimeZone, 'unknown IANA timezone'),
    deviceCheckToken: z.string().min(1).max(8192).optional().openapi({
      description: 'iOS DeviceCheck token (03 §3.7).',
    }),
    deviceKey: z.string().regex(BASE64URL_32_BYTES).optional().openapi({
      description: 'Android: base64url(SHA256("taro-device-v1" ‖ ANDROID_ID)) (03 §3.7).',
    }),
    attestation: AttestationSchema,
  })
  .superRefine((body, ctx) => {
    const allowed = body.platform === 'ios' ? 'app_attest' : 'play_integrity';
    if (body.attestation.type !== 'none' && body.attestation.type !== allowed) {
      ctx.addIssue({
        code: 'custom',
        path: ['attestation', 'type'],
        message: `not available on ${body.platform}`,
      });
    }
    if (body.platform === 'android' && body.deviceKey === undefined) {
      ctx.addIssue({ code: 'custom', path: ['deviceKey'], message: 'required on android' });
    }
  })
  .openapi('RegisterRequest');

const PurchaseBindingSchema = z
  .object({
    appleAccountToken: z.string().optional(),
    playAccountId: z.string().optional(),
  })
  .openapi('PurchaseBinding');

const tokenFields = {
  installToken: z.string(),
  expiresAt: z.iso.datetime(),
  trust: z.enum(['high', 'low']),
};

export const RegistrationResponseSchema = z
  .object({
    ...tokenFields,
    purchaseBinding: PurchaseBindingSchema,
    balance: BalanceDtoSchema,
    config: PublicConfigDtoSchema,
  })
  .openapi('RegistrationResponse');

export const InstallTokenResponseSchema = z.object(tokenFields).openapi('InstallTokenResponse');

const errorContent = { content: { 'application/json': { schema: ErrorEnvelopeSchema } } } as const;

/** `POST /v1/installs` scopes its idempotency row to the body's `installId` (RC55). */
async function bodyInstallId(c: AppContext): Promise<string | undefined> {
  try {
    const body: { installId?: unknown } = await c.req.json();
    return typeof body.installId === 'string' && isUuid(body.installId)
      ? body.installId
      : undefined;
  } catch {
    return undefined;
  }
}

export function registerInstallRoutes(app: OpenAPIHono<AppEnv>, deps: Deps): void {
  const service = new InstallService(deps);

  const registerRoute = createRoute({
    method: 'post',
    path: '/v1/installs',
    tags: ['identity'],
    summary: 'Register or re-register an install with attestation (03 §3.3)',
    ...routeGuards(deps, {
      auth: 'public',
      rateLimit: 'ipPrefix',
      flags: ['idem'],
      idempotency: { scope: bodyInstallId },
    }),
    request: {
      headers: flagHeaders(['idem']),
      body: { required: true, content: { 'application/json': { schema: RegisterRequestSchema } } },
    },
    responses: {
      201: {
        description: 'New install registered',
        content: { 'application/json': { schema: RegistrationResponseSchema } },
      },
      200: {
        description: 'Existing install re-registered (ownership proven, old tokens revoked)',
        content: { 'application/json': { schema: RegistrationResponseSchema } },
      },
      400: { description: 'Validation failed or Idempotency-Key missing', ...errorContent },
      403: { description: 'ATTESTATION_FAILED', ...errorContent },
      409: { description: 'REQUEST_IN_PROGRESS', ...errorContent },
      422: { description: 'IDEMPOTENCY_KEY_REUSED', ...errorContent },
      429: { description: 'RATE_LIMITED (`burst` or `lowTrustCap`)', ...errorContent },
    },
  });

  app.openapi(registerRoute, async (c) => {
    const body = c.req.valid('json');
    if (c.get('client').platform !== body.platform) {
      throw new ApiError('VALIDATION_FAILED', {
        details: {
          issues: [{ path: 'platform', code: 'custom', message: 'differs from X-Taro-Platform' }],
        },
      });
    }
    const registration = await service.register(body, {
      network: clientNetwork(c),
      debugAttestation: isDebugAttestation(deps, c.req.header(DEBUG_ATTESTATION_HEADER)),
    });
    c.set('installId', registration.install.id);
    const config = await deps.config.snapshot();
    return c.json(
      {
        ...tokenJson(registration),
        purchaseBinding: registration.purchaseBinding,
        balance: await balanceFor(deps, c, registration.install.id),
        config: publicConfigJson(config),
      },
      registration.created ? 201 : 200,
    );
  });

  const tokenRoute = createRoute({
    method: 'post',
    path: '/v1/installs/token',
    tags: ['identity'],
    summary: 'Refresh the install token with a fresh attestation (03 §3.4)',
    ...routeGuards(deps, { auth: 'tokenMayBeExpired', rateLimit: 'install', flags: ['attest'] }),
    request: { headers: flagHeaders(['attest']) },
    responses: {
      200: {
        description: 'A fresh 7-day install token',
        content: { 'application/json': { schema: InstallTokenResponseSchema } },
      },
      401: { description: 'UNAUTHENTICATED or ATTESTATION_REQUIRED', ...errorContent },
      403: { description: 'ATTESTATION_FAILED', ...errorContent },
      429: { description: 'RATE_LIMITED', ...errorContent },
    },
  });

  app.openapi(tokenRoute, async (c) => {
    const install = c.get('install');
    if (install === undefined) {
      throw new ApiError('UNAUTHENTICATED');
    }
    return c.json(tokenJson(await service.refreshToken(install)), 200);
  });
}

/** The `GET /v1/config` document; its readonly pack list is plain JSON on the wire. */
function publicConfigJson(config: RuntimeConfig): z.infer<typeof PublicConfigDtoSchema> {
  const dto = buildPublicConfigDto(toPublicConfig(config));
  return { ...dto, 'store.packs': dto['store.packs'].map((pack) => ({ ...pack })) };
}

function tokenJson(token: Pick<Registration, 'installToken' | 'expiresAt' | 'trust'>) {
  return {
    installToken: token.installToken,
    expiresAt: token.expiresAt.toISOString(),
    trust: token.trust,
  };
}
