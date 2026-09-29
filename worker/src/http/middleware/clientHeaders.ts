import type { MiddlewareHandler } from 'hono';
import { parseAppVersion } from '../../domain/appVersion';
import { isLocale, isPlatform } from '../../domain/types';
import type { AppEnv, ClientInfo } from '../context';
import { ApiError } from '../errors';

export const PLATFORM_HEADER = 'X-Taro-Platform';
export const APP_VERSION_HEADER = 'X-Taro-App-Version';
export const LOCALE_HEADER = 'X-Taro-Locale';

export interface ClientHeadersOptions {
  /**
   * App routes require all three headers (03 §2.1) → `400 VALIDATION_FAILED`
   * when one is missing or malformed. Public routes, webhooks and the SSV
   * callback use the lenient mode, where invalid values are simply dropped.
   */
  readonly required?: boolean;
}

export function parseClientHeaders(headers: { get(name: string): string | null }): {
  client: ClientInfo;
  invalid: string[];
} {
  const invalid: string[] = [];
  const platform = headers.get(PLATFORM_HEADER)?.trim().toLowerCase();
  const version = headers.get(APP_VERSION_HEADER)?.trim();
  const locale = headers.get(LOCALE_HEADER)?.trim().toLowerCase();
  const client: { -readonly [K in keyof ClientInfo]: ClientInfo[K] } = {};
  if (isPlatform(platform)) {
    client.platform = platform;
  } else {
    invalid.push(PLATFORM_HEADER);
  }
  if (version !== undefined && parseAppVersion(version) !== undefined) {
    client.appVersion = version;
  } else {
    invalid.push(APP_VERSION_HEADER);
  }
  if (isLocale(locale)) {
    client.locale = locale;
  } else {
    invalid.push(LOCALE_HEADER);
  }
  return { client, invalid };
}

/** Parses `X-Taro-Platform`, `-App-Version` and `-Locale` into `c.var.client`. */
export function clientHeaders(options: ClientHeadersOptions = {}): MiddlewareHandler<AppEnv> {
  return async (c, next) => {
    const { client, invalid } = parseClientHeaders(c.req.raw.headers);
    if (options.required === true && invalid.length > 0) {
      throw new ApiError('VALIDATION_FAILED', {
        details: {
          issues: invalid.map((name) => ({
            path: name,
            code: 'invalid_header',
            message: 'missing or invalid',
          })),
        },
      });
    }
    c.set('client', client);
    await next();
  };
}
