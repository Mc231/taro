import { z } from '@hono/zod-openapi';
import type { MiddlewareHandler } from 'hono';
import type { Deps } from '../deps';
import type { AppEnv } from './context';
import { ATTESTATION_HEADER, attestation } from './middleware/attestation';
import { auth } from './middleware/auth';
import { clientHeaders } from './middleware/clientHeaders';
import {
  IDEMPOTENCY_KEY_HEADER,
  idempotency,
  type IdempotencyOptions,
} from './middleware/idempotency';
import { rateLimit } from './middleware/rateLimit';

/**
 * One place that turns a route's row of the 03 §2.1 / GLOSSARY §4 table
 * (auth, **[idem]**, **[attest]**) into its middleware chain, and records the
 * same row in the OpenAPI operation (`security`, `x-taro-auth`,
 * `x-taro-flags`). The wiring test compares those extensions with the
 * canonical table, so the documented flags and the running middleware cannot
 * drift apart (RC11: `[attest]` on exactly E05, E09, E10, E15).
 *
 * Chain order: auth (sets `c.var.installId`) → required `X-Taro-*` headers →
 * `RL_BURST` → call attestation → idempotency. Attestation runs before the
 * idempotency row is claimed, so a request that fails attestation never
 * occupies its key.
 */
export type RouteAuth = 'public' | 'token' | 'tokenMayBeExpired';

export type RouteFlag = 'idem' | 'attest';

export interface RouteGuardSpec {
  readonly auth: RouteAuth;
  /** `RL_BURST` key: `inst:{id}` for token routes, `ip:{prefix hash}` for public ones (03 §2.4). */
  readonly rateLimit: 'install' | 'ipPrefix';
  readonly flags?: readonly RouteFlag[];
  /** Options of the `[idem]` middleware (e.g. the body-scoped key of `POST /v1/installs`). */
  readonly idempotency?: IdempotencyOptions;
}

/** OpenAPI security scheme of the install token (03 §3.4). */
export const INSTALL_TOKEN_SCHEME = 'installToken';

export interface RouteGuards {
  readonly middleware: MiddlewareHandler<AppEnv>[];
  readonly security: Record<string, string[]>[];
  readonly 'x-taro-auth': RouteAuth;
  readonly 'x-taro-flags': RouteFlag[];
}

/**
 * The middleware and OpenAPI fields of an app route; spread the result into
 * `createRoute({...})`. `tokenAuth` replaces `auth(deps)` on `token` routes
 * (route tests pass a shim); `tokenMayBeExpired` always uses the real auth
 * with `allowExpired`.
 */
export function routeGuards(
  deps: Deps,
  spec: RouteGuardSpec,
  tokenAuth?: MiddlewareHandler<AppEnv>,
): RouteGuards {
  const flags = [...(spec.flags ?? [])];
  const middleware: MiddlewareHandler<AppEnv>[] = [];
  if (spec.auth === 'token') {
    middleware.push(tokenAuth ?? auth(deps));
  } else if (spec.auth === 'tokenMayBeExpired') {
    middleware.push(auth(deps, { allowExpired: true }));
  }
  middleware.push(clientHeaders({ required: true }), rateLimit(deps, spec.rateLimit));
  if (flags.includes('attest')) {
    middleware.push(attestation(deps));
  }
  if (flags.includes('idem')) {
    middleware.push(idempotency(deps, spec.idempotency));
  }
  return {
    middleware,
    security: spec.auth === 'public' ? [] : [{ [INSTALL_TOKEN_SCHEME]: [] }],
    'x-taro-auth': spec.auth,
    'x-taro-flags': flags,
  };
}

/** OpenAPI fields of a public route without guards (`GET /v1/health`, `GET /v1/config`). */
export const PUBLIC_ROUTE_DOC = {
  security: [] as Record<string, string[]>[],
  'x-taro-auth': 'public' as RouteAuth,
  'x-taro-flags': [] as RouteFlag[],
};

/**
 * Documents the flag headers of a route as optional request headers (the
 * middleware, not zod, enforces them, so a missing one gets the 03 §2.2 code
 * `IDEMPOTENCY_KEY_REQUIRED` / `ATTESTATION_REQUIRED` rather than a 400).
 */
export function flagHeaders(flags: readonly RouteFlag[]) {
  return z.object({
    ...(flags.includes('idem')
      ? {
          [IDEMPOTENCY_KEY_HEADER.toLowerCase()]: z.string().optional().openapi({
            format: 'uuid',
            description:
              '[idem]: required; a UUID per user action, reused only on retry (03 §2.3).',
          }),
        }
      : {}),
    ...(flags.includes('attest')
      ? {
          [ATTESTATION_HEADER.toLowerCase()]: z.string().optional().openapi({
            description: '[attest]: `aa1.<assertion>`, `pi1.<token>` or `none` (03 §3.4).',
          }),
        }
      : {}),
  });
}
