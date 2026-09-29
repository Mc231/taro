import { buildApp } from './app';
import { makeProdDeps } from './deps';
import type { Env } from './env';
import { runScheduled } from './scheduled';

/** Worker entrypoint: HTTP (`buildApp`) and the 03 §12 cron triggers (`runScheduled`). */
export default {
  fetch(request, env, ctx) {
    return buildApp(makeProdDeps(env)).fetch(request, env, ctx);
  },
  scheduled(controller, env, ctx) {
    ctx.waitUntil(runScheduled(makeProdDeps(env), controller.cron));
  },
} satisfies ExportedHandler<Env>;
