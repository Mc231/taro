import { buildApp } from './app';
import { makeProdDeps } from './deps';
import type { Env } from './env';

/** Worker entrypoint. `scheduled` (03 §12) is added with the cron jobs. */
export default {
  fetch(request, env, ctx) {
    return buildApp(makeProdDeps(env)).fetch(request, env, ctx);
  },
} satisfies ExportedHandler<Env>;
