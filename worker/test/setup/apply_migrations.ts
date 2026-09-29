import { applyD1Migrations, type D1Migration } from 'cloudflare:test';
import { env } from 'cloudflare:workers';

// 06 §7: every test file starts from the migrations applied to an empty D1,
// which also proves they apply cleanly. `TEST_MIGRATIONS` is injected by
// vitest.config.ts (readD1Migrations). applyD1Migrations is idempotent.
const testEnv = env as unknown as { DB: D1Database; TEST_MIGRATIONS: D1Migration[] };

await applyD1Migrations(testEnv.DB, testEnv.TEST_MIGRATIONS);
