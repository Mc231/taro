# Phase 3 notes: coverage pipeline (Sprint 3.1)

## What runs

| Step | Command | Output |
|---|---|---|
| All reports | `melos run test:coverage` (`tools/ci/test_coverage.sh`) | runs every unit, then exits non-zero if any failed |
| Dart unit | `tools/ci/dart_coverage.sh <pkg>` | `dart run tools/dart_tools/bin/gen_coverage_all.dart` → `flutter test --no-pub --coverage --exclude-tags=integration` → `lcov --remove` → `<pkg>/coverage/lcov.filtered.info` |
| Worker | `cd worker && npm run test:coverage` | `worker/coverage/{lcov.info,coverage-summary.json}` (thresholds 90/90/90/85 in `vitest.config.ts`, QA7) |
| Tools | `cd tools && .venv/bin/python -m pytest --cov=. --cov-report=json:coverage/coverage.json --cov-report=xml:coverage.xml --cov-fail-under=90` | `tools/coverage/coverage.json` (gate) and `tools/coverage.xml` (Sonar) |
| iOS native (RC40) | `tools/ci/native_coverage_ios.sh` | XCTest in `taro_attestation/example` → `xccov` report + archive JSON → `tools/xccov_to_lcov.py` → `packages/taro_attestation/coverage/ios/lcov.info` |
| Android native (RC40) | `tools/ci/native_coverage_android.sh` | `./gradlew :taro_attestation:jacocoTestReport` in `example/android` → `jacoco.xml` → `tools/jacoco_to_lcov.py` → `packages/taro_attestation/coverage/android/lcov.info` |
| Gate | `melos run coverage:check` (`check_coverage.py --verify-sonar`) | `coverage/merged/lcov.info`, `coverage/summary.md` |

`TARO_SKIP_NATIVE_COVERAGE=1 melos run test:coverage` skips the two native units; `check_coverage.py` then fails them for a missing report, as intended.

## Decisions and deviations

- **Units.** The eight units of Sprint 3.1 plus `dart_tools` (`tools/dart_tools`), because 06 Testing strategy calls it "a coverage unit like the others". Remove it from `discover_units` if that is not wanted.
- **Generator path.** 06 §5.1 says `dart run tools/gen_coverage_all.dart`; the generator lives at `tools/dart_tools/bin/gen_coverage_all.dart` (Sprint 3.1 path). It runs as a script file, so a package does not need to depend on `taro_dart_tools`.
- **Generated test.** `test/coverage_all_test.dart` (git-ignored) is written already `dart format`ted and in `directives_ordering` order; it carries only `// ignore_for_file: unused_import`, so `melos run analyze` and `format:check` stay green when it exists. Part files are not imported (their library is).
- **lcov patterns.** Flutter writes package-relative `SF:` paths (`lib/...`), while `tools/coverage_exclusions.txt` is repo-relative. `gen_coverage_all.dart --lcov-patterns` prints the unit-relative patterns for `lcov --remove`. lcov `*` also crosses `/`, so its filtering is a superset. `check_coverage.py` re-applies the exact globs anyway, so if lcov over-removes a file, the gate reports it as a missing file. `--ignore-errors unused` is passed only on lcov ≥ 2 (lcov 1.15 does not know it).
- **Glob rules** (same in Dart and Python): `**/` = zero or more segments, a trailing `**` = everything below, `*`/`?` stay inside one segment.
- **Files with no executable code.** The Dart VM leaves directive-only barrels out of lcov, and istanbul does the same for type-only TypeScript modules (for example `worker/src/env.ts`). Such files do not count as QA4 misses. `has_executable_code()` uses a small heuristic: Dart statements are only `library/import/export/part`; TypeScript statements are only `import`, re-exports, `type`, `interface` or `declare`. Any other file absent from its report fails.
- **Python empties.** coverage.py `skip_empty` drops docstring-only modules, so the tools unit does not require them in the report.
- **Pragmas** are matched only inside comments (`//`, `/*`, `*`, `#`), in every non-excluded source of every unit (tests are excluded by §5.3). `check_coverage.py` builds its own pattern literals from pieces, so it does not flag itself.
- **Worker branches.** The checker also fails the Worker below 85 % branches (from `coverage-summary.json`), which mirrors QA7.
- **Paths from CI artifacts.** An absolute `SF:` path outside the repo root is re-anchored on the unit directory (for example `/runner/work/taro/worker/src/a.ts` becomes `worker/src/a.ts`).
- **`--verify-sonar`** reads `sonar-project.properties` (Java properties, `\` continuations). When the file is absent the checker adds a note, not a failure (Sprint 3.2 creates the file). When the key is missing or the lists differ, the checker fails. `coverage:check` always passes `--verify-sonar`.
- **`--threshold`** lowers only the unit threshold, for tests; the per-file 70 % floor is fixed.

## Native units (RC40)

- iOS: the example targeted iOS 13, but the plugin podspec needs 16.0, so `pod install` failed. `example/ios/Podfile` (`platform :ios, '16.0'`) and the Runner `IPHONEOS_DEPLOYMENT_TARGET` are now 16.0, the same as `apps/taro`. Added `RunnerTests.testUnknownMethodIsNotImplemented`. `register(with:)` is covered by the hosted Runner launch.
- Android: `enableUnitTestCoverage = true` on the debug build type, plus a `jacocoTestReport` alias for AGP's `createDebugUnitTestCoverageReport`. Added Kotlin tests for `notImplemented` and attach/detach (Mockito, already a test dependency).
- Numbers on 2026-09-28 (template plugin code only): iOS 13/13 lines (100 %), Android 10/10 lines (100 %).

## Other fixes made for the gate

- `apps/taro/test/services/presentation/banner_slot_view_test.dart` now builds a non-const `BannerSlotView()`. A const instance is built at compile time, so the constructor line was never hit at runtime and the 2-line file sat at 50 % (< 70 % QA2).

## Done-when evidence: an uncovered file fails the gate

Adding `packages/taro_core/lib/src/scratch_untested.dart` (untested, 4 lines), then running `tools/ci/dart_coverage.sh packages/taro_core` and `check_coverage.py --unit taro_core`, gave exit 1:

```
| taro_core | 2 | 5 | 1 | 20.00 % | FAIL (2) |
- **taro_core**: unit line coverage 20.00 % < 90.0 % (QA1)
- **taro_core**: file packages/taro_core/lib/src/scratch_untested.dart 0.00 % < 70.0 % (QA2)
```

With the file removed, the same command exits 0. The file only shows up at 0 % because `coverage_all_test.dart` imports it (QA4).
