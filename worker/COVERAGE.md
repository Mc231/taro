# Worker coverage

Gate (03 BE17, 06 QA7, RC61): istanbul in workerd, **lines, statements and functions ≥ 90 %, branches ≥ 85 %** over the whole unit (`vitest.config.ts`, `perFile: false`), plus `tools/check_coverage.py --unit worker` (unit ≥ 90 % lines, every file ≥ 70 %, no file missing from the report, no coverage pragmas).

```bash
npm run test:coverage                              # writes coverage/{lcov.info,coverage-summary.json}
../tools/.venv/bin/python ../tools/check_coverage.py --unit worker
```

## Current (2026-09-29, end of Phase 6)

618 tests in 53 files. Statements 99.71 % (2109/2115), branches 95.17 % (1263/1327), functions 99.79 % (491/492), lines 99.71 % (2069/2075). Known uncovered: the default global-`fetch` wrapper in `scripts/smoke.ts` (needs real network), the D1 race-retry branch in `http/middleware/idempotency.ts`, the unreachable empty-keyring guard in `crypto/keyring.ts`, and defensive guards in `routes/installs.ts` (no install after auth), `services/InstallService.ts` ("install vanished") and `identityDeps.ts`.

## Included

`coverage.include` is `src/**/*.ts`, `scripts/**/*.ts` and `evals/lib/**/*.ts`. That covers the composition root (`app.ts`, `deps.ts`, `identityDeps.ts`, `index.ts`, `scheduled.ts`), route tables, adapters, NoOp/unimplemented ports and the owner CLIs: every `scripts/*.ts` is a thin `main(argv, deps)` tested through `main([...])` with stubbed file system, commands and fetch (RC61).

## Excluded (mirror of 06 §5.3 / `tools/coverage_exclusions.txt`)

| Pattern                                           | Why                                                                                       |
| ------------------------------------------------- | ----------------------------------------------------------------------------------------- |
| `worker/src/generated/**`                         | build-time bundles from `tools/content build` and the prompt/safety builders (RC25, RC26) |
| `**/*.d.ts`, `worker/worker-configuration.d.ts`   | type declarations, no executable lines                                                    |
| `worker/test/**`                                  | tests, fakes, helpers and contract fixtures                                               |
| `worker/evals/cases/**`, `worker/evals/safety/**` | eval case data (YAML/JSONL); `evals/lib/**` stays covered                                 |

Not part of the include globs, so not measured: `scripts/run.mjs` (the small Node launcher that bundles a script and hands it the real `fs`, `process.env` and a shell-less process runner; all logic lives in the covered `main` functions), `vitest.config.ts` and `eslint.config.js`.

Changing this list needs the 06 §5.3 table, `tools/coverage_exclusions.txt` and `sonar-project.properties` updated in the same change.
