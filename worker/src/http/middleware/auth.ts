import type { MiddlewareHandler } from 'hono';
import type { Deps } from '../../deps';
import { InstallRepo } from '../../repos/InstallRepo';
import type { AppEnv } from '../context';
import { ApiError } from '../errors';

/**
 * Install-token auth (03 §3.4, BE3). Verifies the EdDSA signature and
 * expiry, then loads the `installs` row (one D1 read, needed anyway) and
 * checks `status` and `gen == token_generation`:
 *
 * - missing/malformed `Authorization`, bad signature, unknown install,
 *   `status = 'deleted'`, a revoked generation or a platform mismatch →
 *   `401 UNAUTHENTICATED` (the client re-registers);
 * - an expired but otherwise valid token → `401 TOKEN_EXPIRED` (the client
 *   calls `POST /v1/installs/token`), unless `allowExpired` (that route).
 *
 * A `blocked` install stays authenticated: it keeps its free, bonus and
 * paid readings and only loses new purchases (03 §2.4, RC66).
 *
 * Sets `c.var.installId` and `c.var.install`.
 */
export interface AuthOptions {
  /** `POST /v1/installs/token` accepts an expired token (03 §3.4). */
  readonly allowExpired?: boolean;
}

const BEARER = /^Bearer\s+([A-Za-z0-9_\-.]+)$/i;

export function auth(deps: Deps, options: AuthOptions = {}): MiddlewareHandler<AppEnv> {
  const repo = new InstallRepo(deps.db);
  return async (c, next) => {
    const match = BEARER.exec(c.req.header('Authorization')?.trim() ?? '');
    const token = match?.[1];
    if (token === undefined) {
      throw new ApiError('UNAUTHENTICATED');
    }
    const verified = await deps.tokenSigner.verify(token, deps.clock.now());
    if (!verified.ok) {
      throw new ApiError('UNAUTHENTICATED');
    }
    if (verified.expired && options.allowExpired !== true) {
      throw new ApiError('TOKEN_EXPIRED');
    }
    const { claims } = verified;
    const install = await repo.findById(claims.sub);
    if (
      install === null ||
      install.status === 'deleted' ||
      install.tokenGeneration !== claims.gen ||
      install.platform !== claims.plat
    ) {
      throw new ApiError('UNAUTHENTICATED');
    }
    c.set('installId', install.id);
    c.set('install', install);
    await next();
  };
}
