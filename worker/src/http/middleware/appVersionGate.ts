import type { MiddlewareHandler } from 'hono';
import { compareAppVersions, parseAppVersion } from '../../domain/appVersion';
import type { ConfigStore } from '../../ports/ConfigStore';
import type { AppEnv } from '../context';
import { ApiError } from '../errors';

export interface AppVersionGateOptions {
  /** Paths never gated (`GET /v1/health`, `GET /v1/config`: the client needs the config to learn the minimum). */
  readonly exemptPaths?: readonly string[];
}

/**
 * `426 UPGRADE_REQUIRED` when `X-Taro-App-Version` is below
 * `app.minVersion.{platform}` (03 §2.2, §8.2). Requests without a parsed
 * platform and version (webhooks, SSV, smoke checks) pass; app routes reject
 * those earlier through `clientHeaders({ required: true })`.
 */
export function appVersionGate(
  config: ConfigStore,
  options: AppVersionGateOptions = {},
): MiddlewareHandler<AppEnv> {
  const exempt = new Set(options.exemptPaths ?? []);
  return async (c, next) => {
    const { platform, appVersion } = c.get('client');
    if (exempt.has(c.req.path) || platform === undefined || appVersion === undefined) {
      await next();
      return;
    }
    const snapshot = await config.snapshot();
    const minimum = parseAppVersion(snapshot[`app.minVersion.${platform}`]);
    const current = parseAppVersion(appVersion);
    if (
      minimum !== undefined &&
      current !== undefined &&
      compareAppVersions(current, minimum) < 0
    ) {
      throw new ApiError('UPGRADE_REQUIRED');
    }
    await next();
  };
}
