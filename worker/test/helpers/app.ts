import type { MiddlewareHandler } from 'hono';
import { buildApp, type App } from '../../src/app';
import type { AppEnv } from '../../src/http/context';
import type { ErrorEnvelope } from '../../src/http/errors';
import type { TestHarness } from '../fakes/testDeps';

export const APP_HEADERS = {
  'X-Taro-Platform': 'ios',
  'X-Taro-App-Version': '1.2.0+14',
  'X-Taro-Locale': 'de',
} as const;

/** Stand-in for the Phase 6.3 auth middleware: trusts `X-Test-Install`. */
export const testAuth: MiddlewareHandler<AppEnv> = async (c, next) => {
  const id = c.req.header('X-Test-Install');
  if (id !== undefined) {
    c.set('installId', id);
  }
  await next();
};

/** `buildApp` with the token routes behind the `testAuth` shim (until 6.3's auth lands). */
export function authedApp(h: TestHarness): App {
  return buildApp(h.deps, { auth: testAuth });
}

/** `buildApp(deps)` plus test-only routes registered by `extend`. */
export function testApp(h: TestHarness, extend?: (app: App) => void): App {
  const app = buildApp(h.deps);
  extend?.(app);
  return app;
}

export async function errorOf(res: Response): Promise<ErrorEnvelope['error']> {
  return (await res.json<ErrorEnvelope>()).error;
}
