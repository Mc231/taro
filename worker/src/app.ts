import { OpenAPIHono } from '@hono/zod-openapi';
import type { Deps } from './deps';
import { registerHealthRoutes } from './routes/health';

/**
 * Composition root (03 §1, RC38). Tests call `buildApp(fakeDeps)` and drive
 * it with `app.request()`; production uses `buildApp(makeProdDeps(env))`.
 */
export function buildApp(deps: Deps): OpenAPIHono {
  const app = new OpenAPIHono();
  registerHealthRoutes(app, deps);
  return app;
}
