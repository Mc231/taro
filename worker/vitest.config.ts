import { cloudflareTest } from '@cloudflare/vitest-pool-workers';
import { defineConfig } from 'vitest/config';

// 06 §5.2 / 03 BE17. Tests run inside workerd with miniflare bindings from the
// `dev` env of wrangler.toml. Istanbul is required (V8 coverage does not work
// in workerd). Exclusions mirror 06 §5.3 (generated code, tests, *.d.ts).
export default defineConfig({
  plugins: [
    cloudflareTest({
      wrangler: { configPath: './wrangler.toml', environment: 'dev' },
    }),
  ],
  test: {
    include: ['test/**/*.test.ts'],
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
