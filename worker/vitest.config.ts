import path from 'node:path';
import { cloudflareTest, readD1Migrations } from '@cloudflare/vitest-pool-workers';
import { defineConfig } from 'vitest/config';

// 06 §5.2 / 03 BE17. Tests run inside workerd with miniflare bindings from the
// `dev` env of wrangler.toml. Istanbul is required (V8 coverage does not work
// in workerd). Exclusions mirror 06 §5.3 (generated code, tests, *.d.ts).
//
// Isolation (06 §7, pool-workers 0.22): `isolatedStorage` no longer exists;
// each test file gets its own storage, and `test/setup/apply_migrations.ts`
// applies `migrations/` to it from empty. Tests inside a file share D1/KV, so
// they use unique install IDs and idempotency keys (`uniqueId()`).
export default defineConfig({
  plugins: [
    cloudflareTest(async () => ({
      wrangler: { configPath: './wrangler.toml', environment: 'dev' },
      miniflare: {
        bindings: {
          TEST_MIGRATIONS: await readD1Migrations(path.join(import.meta.dirname, 'migrations')),
        },
      },
    })),
  ],
  test: {
    include: ['test/**/*.test.ts'],
    setupFiles: ['./test/setup/apply_migrations.ts'],
    coverage: {
      provider: 'istanbul',
      include: ['src/**/*.ts', 'scripts/**/*.ts', 'evals/lib/**/*.ts'],
      exclude: ['src/generated/**', 'test/**', '**/*.d.ts'],
      reporter: ['text', 'lcov', 'json-summary'],
      reportsDirectory: './coverage',
      thresholds: {
        lines: 90,
        statements: 90,
        functions: 90,
        branches: 85,
        perFile: false,
      },
    },
  },
});
