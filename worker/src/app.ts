import { OpenAPIHono } from '@hono/zod-openapi';
import type { MiddlewareHandler } from 'hono';
import type { Deps } from './deps';
import type { AppEnv } from './http/context';
import { errorHandler, notFoundHandler, validationHook } from './http/errors';
import { appVersionGate } from './http/middleware/appVersionGate';
import { auth } from './http/middleware/auth';
import { clientHeaders } from './http/middleware/clientHeaders';
import { dateHeader } from './http/middleware/dateHeader';
import { logging } from './http/middleware/logging';
import { noCors } from './http/middleware/noCors';
import { requestId } from './http/middleware/requestId';
import { registerAttestRoutes } from './routes/attest';
import { registerBalanceRoutes } from './routes/balance';
import { registerConfigRoutes } from './routes/config';
import { registerHealthRoutes } from './routes/health';
import { registerInstallRoutes } from './routes/installs';
import { registerInstallMeRoutes } from './routes/installsMe';
import { registerPurchaseRoutes } from './routes/purchases';
import { registerReadingReportRoutes } from './routes/readingReports';
import { registerReadingRoutes } from './routes/readings';
import { registerAdmobSsvRoute } from './routes/admobSsv';
import { registerRewardRoutes } from './routes/rewards';
import { registerWebhookRoutes } from './routes/webhooks';

export type App = OpenAPIHono<AppEnv>;

export interface BuildAppOptions {
  /**
   * Install-token middleware of the token routes (sets `c.var.installId`);
   * defaults to `auth(deps)`. Route tests may pass a shim that trusts a
   * test header instead of minting tokens.
   */
  readonly auth?: MiddlewareHandler<AppEnv>;
}

/** Routes the app-version gate never blocks (the client needs them to learn the minimum). */
export const VERSION_GATE_EXEMPT = ['/v1/health', '/v1/config'] as const;

/**
 * Composition root (03 §1, RC38). Tests call `buildApp(fakeDeps)` and drive
 * it with `app.request()`; production uses `buildApp(makeProdDeps(env))`.
 *
 * Global middleware order: `Date` and request ID (outermost, so every
 * response carries them) → request log → no-CORS → client headers → app-version gate. Route
 * groups add auth, attestation, idempotency and rate limits per 03 §2.1.
 */
export function buildApp(deps: Deps, options: BuildAppOptions = {}): App {
  const app = new OpenAPIHono<AppEnv>({ defaultHook: validationHook });
  app.use('*', dateHeader(deps.clock));
  app.use('*', requestId(deps.ids));
  app.use('*', logging(deps.clock, deps.logger, deps.metrics));
  app.use('*', noCors());
  app.use('*', clientHeaders());
  app.use('/v1/*', appVersionGate(deps.config, { exemptPaths: VERSION_GATE_EXEMPT }));
  app.onError(errorHandler(deps.logger));
  app.notFound(notFoundHandler);
  registerHealthRoutes(app, deps);
  registerConfigRoutes(app, deps);
  // Identity & attestation (Sprint 6.3): challenge, registration, token refresh.
  registerAttestRoutes(app, deps);
  registerInstallRoutes(app, deps);
  const tokenAuth = options.auth ?? auth(deps);
  registerBalanceRoutes(app, deps, tokenAuth);
  registerInstallMeRoutes(app, deps, tokenAuth);
  // Purchases (Sprint 7.2).
  registerPurchaseRoutes(app, deps, tokenAuth);
  // Rewarded ads (Sprint 7.4): reward intents and the AdMob SSV callback.
  registerRewardRoutes(app, deps, tokenAuth);
  // AI readings (Sprint 8.3): pre-draw hold, reading, status, ack.
  registerReadingRoutes(app, deps, tokenAuth);
  // Reading reports (Sprint 8.5, CS7/RC22).
  registerReadingReportRoutes(app, deps, tokenAuth);
  registerAdmobSsvRoute(app, deps);
  // Store webhooks (Sprint 7.3): App Store Server Notifications, Play RTDN.
  registerWebhookRoutes(app, deps);
  return app;
}
