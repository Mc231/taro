# Testing in Taro

How to write and run tests in this repository. The rules live in [06_QUALITY_TESTING_CI.md](specs/06_QUALITY_TESTING_CI.md); this page covers the harness that implements them. When the two disagree, 06 wins. Fix this page in the same change.

## The gates

| Gate | Command | Blocks |
|---|---|---|
| Local, before a push | `tools/verify.sh --fast` (the `pre-push` hook, and `melos run check`) | the push |
| Local, before a phase commit | `tools/verify.sh` | the phase commit (06 §11.2) |
| CI | `.gitea/workflows/ci.yml` on every mirrored push | the phase and every deploy |
| Sonar | `sonarqube-main.yml` on `main` | nothing: it is advisory (QA11, RC88) |

`tools/verify.sh --fast` runs, in order:

1. format and analyze;
2. every repo check, found by glob (`tools/check_*.py`, `tools/*/check_*.py`, `tools/check_*.dart`, `tools/dart_tools/bin/check_*.dart`), so a new check needs no wiring;
3. gitleaks;
4. `test:fast` in the packages changed against `origin/main`. It skips the `golden` and `integration` tags.

The full `tools/verify.sh` replaces step 4 with the rest of CI, minus integration:

- worker lint, typecheck and prettier;
- `melos run test:coverage`: every unit, goldens included;
- `melos run coverage:check`: ≥ 90 % per unit and ≥ 70 % per file, no pragmas, no Sonar drift.

By default every step runs and a summary is printed at the end. `--fail-fast` stops at the first failure.

Install the hooks once per clone: `melos run hooks:install`. It sets `core.hooksPath=tools/githooks`, with two hooks:

- `commit-msg` runs `check_commit_msg.py` (conventional commits, no AI attribution);
- `pre-push` runs `verify.sh --fast`.

## Where tests live

| Kind | Location | Tag | Runs |
|---|---|---|---|
| Unit (pure Dart) | `packages/taro_core/test/src/**` (mirrors `lib/src/**`) | none | every push |
| Widget | `apps/taro/test/**`, `packages/taro_ui/test/src/**` | none | every push |
| Golden | `packages/taro_ui/test/golden/`, `apps/taro/test/golden/` | `golden` | every push, on the reference platform |
| Integration | `apps/taro/integration_test/{flows,perf,staging}/` + spikes; `apps/taro/patrol_test/` (native-dialog flows, when added) | none | `melos run test:integration`, integration.yml |
| Worker | `worker/test/{unit,integration}/**` | none | every push |
| Tools | `tools/tests/test_*.py` with fixture trees in `tools/tests/fixtures/<check>/{pass,fail_*}/` | none | every push |

Tags are declared in each package's `dart_test.yaml` (`golden`, `slow`, `l10n`, `integration`). A test file opts in with `@Tags(['golden'])` above `library;`.

## Determinism (QA9)

Production code never calls `DateTime.now()`, `Random()`, `Uuid().v4()`, `print` or `debugPrint` outside adapters; `check_forbidden_apis.py` fails the build if it does. Tests inject the ports instead:

| Concern | Port | In tests |
|---|---|---|
| Time | `Clock`, `TimezoneProvider` | `FakeClock(DateTime, tz)` with `advance`, `setTimeZone` |
| Card draws | `RandomSource` | `SeededRandomSource(seed)`, `ScriptedRandomSource([...])` |
| IDs | `IdGenerator` | `SequentialIdGenerator('id-')` |
| Timers | `Clock` + `fake_async` | `fakeAsync((fa) => fa.elapse(...))` |
| Locale | passed explicitly | `pumpTaroWidget(locale: ...)` |

Every day-boundary test names its timezone and runs over `kBoundaryZones` (06 §2.1). Anything clock-dependent also gets a resume-path test.

## Fakes, builders and contract suites (QA5, QA16)

- **Fakes first.** Every `taro_core` port has a hand-written, Riverpod-free `FakeX` in `packages/taro_core/test/fakes/` with in-memory state and hooks (`failNextSync(...)`, `emitPending(...)`). mocktail is only for "was never called" style checks; never mock value types or Flutter classes. There is no mockito codegen.
- **Builders** in `packages/taro_core/test/fakes/builders/` return valid objects with fixed defaults (`aReading().withSpread('three_ppf').build()`). Builders never read the clock or RNG.
- **Contract suites** in `packages/taro_core/test/contracts/` (`runBalanceRepositoryContract`, …) run against the fake in `taro_core` and against the real adapter in `apps/taro/test/data/` and `apps/taro/test/services/`. This is what keeps the fakes honest.
- **API contract fixtures:** the Worker tests export JSON to `worker/test/contract/fixtures/`. `melos run contract:sync` mirrors them into `apps/taro/test/contract/fixtures/`, and `check_contract_fixtures.py` fails CI on drift (QA15).
- App tests may import `packages/taro_core/test/{fakes,contracts}/**` and `packages/taro_ui/test/helpers/**` by relative path. That is the only cross-package test import `check_architecture.dart` allows. Nothing under `lib/` may import test support.

## Worker contract fixtures in the app (QA15, Phase 11)

- **Source and sync:** the Worker's contract tests write `worker/test/contract/fixtures/**/*.{request,response}.json`. `melos run contract:sync` mirrors them into `apps/taro/test/contract/fixtures/` (never edit the copies), and `tools/check_contract_fixtures.py` fails when the two trees differ.
- **The test:** `apps/taro/test/contract/contract_fixtures_test.dart` creates one test per fixture file. A `*.response.json` is decoded through the matching DTO and domain mapper and validated against `worker/openapi/openapi.json` (`test/contract/support/openapi_schema.dart`, a small validator for the OpenAPI subset the Worker uses). A `*.request.json` is re-encoded from domain inputs, must equal the fixture exactly and must pass a strict schema check (no extra fields). A fixture with no decoder or encoder fails on purpose, so a new Worker fixture cannot go unchecked.
- **Adding a route:** add the fixture on the Worker side, run `contract:sync`, then add its entry to the decoder/encoder tables in `contract_fixtures_test.dart`.
- **Pending (Phase 8):** the reading routes (`POST /v1/readings/holds`, `POST /v1/readings`, `GET /v1/readings/{id}`, ack, report) have no fixtures yet. Until Phase 8 exports them, the client calls are tested against `ScriptedHttpAdapter` (`test/data/api/`) and the in-memory fake Worker (`test/data/repositories/support/fake_worker_server.dart`) built from 03 §9.
- **Known gap:** the Worker's `VerifyPurchaseRequest` schema has no `transferToken` (RC84, 02 §6.3); the client already sends it, and the test `the transferToken field of 02 §6.3 is not in the Worker schema yet` pins the gap; it fails once the Worker declares the field and is then flipped.

## drift databases and migrations (02 §6.1)

- DAO tests run on `NativeDatabase.memory()` (`apps/taro/test/data/db/`); file behaviour (WAL, `shareAcrossIsolates`, backup exclusion, the RC75 restore simulation) runs on `DatabaseLocation` over a temp directory.
- Schemas are SQL in `lib/data/db/{journal/journal.drift,device/device.drift}`. After a schema change: `cd apps/taro && dart run build_runner build`, then `dart run drift_dev make-migrations` (dumps `db/schema/<db>/drift_schema_v<n>.json`) and `dart run drift_dev schema generate db/schema/<db>/ test/data/db/migrations/<db>/generated/`. Commit the dumps and helpers.
- `test/data/db/migrations/schema_test.dart` proves the code creates exactly the dumped schema (`SchemaVerifier.migrateAndValidate` from `startAt(n)`, `validateDatabaseSchema`) and that rows written at a version read back. A version bump (`schemaVersion` n+1) adds a `MigrationStrategy.onUpgrade` step and, per database, a `migrateAndValidate` test from **every** older version plus a data-integrity test (`schemaAt(old)` → insert through `rawDatabase` → open the app database → `migrateAndValidate(db, n+1)` → read back).
- `drift` is pinned to `drift_dev`'s version (2.34.0): the drift_dev 2.34.0 CLI and `SchemaVerifier` do not compile against drift 2.34.4.

## Widget harness

- **`pumpTaroWidget(tester, child, {locale, theme, textScale, size})`**, in `apps/taro/test/helpers/pump_taro_widget.dart`, is for widgets without providers. It wraps the child in:
  - a `MaterialApp` with `TaroLocalizations`, which sets `Directionality` from the locale;
  - the Taro theme in `ThemeMode` `theme`;
  - a `TextScaler.linear(textScale)` with reduced motion.

  The surface is `size` logical pixels at a device pixel ratio of 1.0. The defaults are `en`, light, 1.0 and `kPhoneSmall`. It is Riverpod-free (RC77).
- **`pumpTaro(tester, {fakes, ...})`**, in `apps/taro/test/helpers/pump_app.dart` (Phase 13.1), adds `ProviderScope(overrides: fakes.toOverrides())` on top for screens.
- **`TaroFakes`** (same file) bundles every `taro_core` fake with defaults (registered install, default balance and config, onboarding done, online) sharing one `FakeClock` and `InMemoryJournal`; `toOverrides()` overrides every port provider, `container()` builds a disposed-at-teardown `ProviderContainer` with retry off. Fields are replaceable before use (`timezone`, `warmUp`, `attestationPort`, …).
- **`FakeTaroEnvironment`** and **`TestControlPort`** (`apps/taro/test/helpers/test_environment.dart`) boot the real `bootstrap()` over `TaroFakes` (in-memory drift DBs, no platform channel); the control port moves the `FakeClock`, the time zone and scripts the Worker fakes. The `TARO_ENV=test` integration flows boot through it (a lib-side `overrides_test.dart` would ship the fakes, so the test graph lives in `test/helpers/`).
- **`pumpTaroUiWidget(...)`**, in `packages/taro_ui/test/helpers/pump_taro_ui_widget.dart`, is the same wrapper for `taro_ui` components. The package cannot import the app, so it has no `TaroLocalizations` and the locale only sets the text direction.
- Every package's `test/flutter_test_config.dart` loads the bundled test fonts and installs `TaroGoldenComparator` before any test runs. Text in widget tests is therefore measured with real glyphs, not the square `FlutterTest` font.

## Goldens (QA8, 06 §3, RC24)

- Goldens use Flutter's `matchesGoldenFile` only. `TaroGoldenComparator` (`packages/taro_ui/test/helpers/golden/taro_golden_comparator.dart`) passes a diff of up to 0.1 % of pixels. Above that, it writes masked diffs to `test/golden/failures/` (gitignored), which CI uploads.
- **Fonts:** the bundled `taro_ui` fonts (`packages/taro_ui/fonts/`, Phase 15) are loaded under their `packages/taro_ui/<family>` names, so the token text styles render with the real Taro typefaces; the Flutter SDK's Material Icons font is loaded too. Noto Sans (Latin, Greek, Cyrillic), Noto Sans Arabic, Noto Sans JP and Noto Sans KR (regular, OFL 1.1, in `packages/taro_ui/test/helpers/golden/fonts/`; `NOTICE.md` has the sources) back Material's default families: Noto Sans is registered as `Roboto` and the Cupertino system families. `withTaroTestFonts(theme)` returns the theme unchanged since Phase 15. `pumpTaroUiWidget` builds the theme for the locale's script (`TaroScript.forLocale`).
- **Sizes** (`golden_sizes.dart`):
  - `kPhoneSmall` 375×667 and `kPhoneLarge` 430×932 for every golden;
  - `kTabletIpad13` 1032×1376 and `kTabletAndroid` 800×1280 for ★ screens.
- **Matrix** (`golden_matrix.dart`). `goldenMatrix(name, builder, {keyScreen, extraLocales, largeText, phoneSizes, tabletSizes, pump})` registers one `golden`-tagged test per variant:
  - every phone size × {light, dark} × {en, ar};
  - `extraLocales` (`ja`, `de`) in light, for the text-heavy S09, S14 and S17;
  - `largeText`: en light at 2.0, for S05, S09 and S13;
  - with `keyScreen: true`, each tablet in en light and ar dark.

  Files go to `test/golden/goldens/<name>/<variant>.png` (for example `phone_small_dark_ar.png`). App goldens pass `pump: pumpTaroGolden` so screens get `TaroLocalizations`.
- **Reference platform:** macOS on Apple silicon (Darwin arm64) with the Flutter version pinned in the root `pubspec.yaml`. The CI runner is one, and so is any developer Mac of the same kind: both render identical PNGs with the pinned engine.
- **Updating goldens:** `melos run golden:update` checks the host and the Flutter version, then runs `flutter test --tags golden --update-goldens` in every package with `test/golden/`. Elsewhere it refuses unless you run `melos run golden:update -- --force-local` (or set `TARO_GOLDEN_FORCE_LOCAL=1`), and those files are never committed. The canonical path is `golden.yml` with `update: true`, which uploads the regenerated `goldens/**` as an artifact for a `test(golden): update goldens` commit.
- `packages/taro_ui/test/golden/sample_golden_test.dart` proves the pipeline. It covers `kPhoneSmall` and `kTabletIpad13`, LTR and RTL, light and dark, and all four scripts.

## Integration tests

`melos run test:integration` (`tools/run_integration.sh`) reads two variables:

- `TARO_INTEGRATION_PLATFORM` (`ios` or `android`);
- `TARO_DEVICE_ID` (simulator UDID or adb serial).

It runs `flutter test integration_test --flavor dev --dart-define-from-file=config/dev.json --dart-define=TARO_ENV=test` on that device (every file under `integration_test/`, one app build per file). A future `apps/taro/patrol_test/` (flows that drive the native UMP / ATT / StoreKit dialogs) takes precedence and runs with `patrol test`. CI pins its devices in `tools/ci/sim.env`.

| Folder | What | Needs |
|---|---|---|
| `integration_test/flows/` | the 14 fake-backed flows of 06 §4 / Phase 13.6 (F1–F8, rewarded, Remove Ads, daily reset, RTL, reinstall, OS restore, time zone) | `TARO_ENV=test` (a flow fails fast without it) |
| `integration_test/perf/` | `cold_start_test.dart` (the real `dev` composition root) and `draw_screen_perf_test.dart` (frame timings of the S08 ritual); both print `PERF <name> {json}` and fill `reportData` | the `dev` flavor |
| `integration_test/staging/smoke_test.dart` | the staging Worker: register, balance, one free reading | manual dispatch only: `--flavor staging --dart-define-from-file=config/staging.json --dart-define=TARO_STAGING_SMOKE=1 --dart-define=TARO_DEBUG_ATTESTATION_TOKEN=…` (skipped otherwise) |
| `integration_test/qa/` | the release QA suite: `staging_e2e_test.dart` (method B, staging Worker, `run_staging_e2e.sh`) and `screenshot_tour_test.dart` (method C, S01–S33 screenshots per mode); see [qa/README.md](qa/README.md) | skipped unless `TARO_STAGING_SMOKE` + token (B) or `QA_MODE` (C) is set |
| `integration_test/*_test.dart` | spikes (RC91 FTS5) | — |

**The flow harness** (`integration_test/support/flow_harness.dart`):

- `taroFlow(description, body)` registers a patrol test (`patrolWidgetTest` from `patrol_finders`, generous waits, best-effort settling because the loading kit animates forever). It asserts `TARO_ENV=test`.
- `FlowApp.launch($, {fakes})` boots the real `bootstrap()` over `FakeTaroEnvironment` (`TaroFakes`, in-memory drift DBs, nothing on a platform channel), mounts the app and returns the running app: `fakes`, `control` (`TestControlPort`: clock, time zone, Worker scripting), `container`, and the `orchestrator`. Analytics follow the production path (RC68): the fakes' `FakeAnalyticsService` is the sink behind `AnalyticsConsentTap` + `ConsentAwareAnalytics`, released by the orchestrator's `whenResolved` (`TaroFakes.analyticsPort` / `orchestratorPort`).
- `flowFakes({consent})` = `TaroFakes` with a session and, by default, an onboarded install with AI consent granted and ATT already answered (`authorized`, so the neutral pre-prompt stays away); `onboardedConsent(aiGranted:)`. A flow that sets `fakes.tracking` to `notDetermined` sees the pre-prompt after UMP and taps its Continue (`consent_denied_test`).
- Steps: `waitForScreen(ScreenId)` (every screen is keyed by its S-ID; on timeout the failure lists the texts on screen), `tapText`, `tapButton` (the `TaroButton` with that label, not a coachmark or notice with the same words), `tapFinder`, `enterQuestion`, `waitUntil(condition)`, `backgroundAndResume(whileAway:)` (paused → the clock moves → resumed; nothing pumps while paused, since a paused binding draws no frames), `shutdown()` (a process death; a flow can then `launch` again with fakes that share, e.g., the store or the secure store), and the reading steps `openQuestion`, `begin`, `drawAndRevealAll`. Progress is logged as `FLOW:` lines.
- Scripting notes: queue Worker failures with `fakes.readings.failNext(failure, on: 'hold' | 'submit')` after launch, not `failNextWorkerCall` (the launch sync's ack flush would take it); a resume within `balance.resumeSyncThrottleSec` of the last sync is skipped, so move the clock in `whileAway`; a `holdTtl` under 120 s makes the reveal renew the hold (RC50); a scripted server balance keeps its `syncedAt`, so bump `ledgerVersion` and `syncedAt` when the gate needs a fresh one.
- Iterating on the host is quicker than on a simulator: `flutter test integration_test/flows/<flow>_test.dart --dart-define=TARO_ENV=test -d flutter-tester`.

**Devices:** PR runs on the iOS simulator; nightly adds the Android emulator (06 §4). Performance numbers from a simulator are debug-mode baselines only (see `docs/ARCHITECTURE.md` §Performance baseline); budgets are enforced on devices in profile mode in Phase 19.

## Python tools

Each tool keeps its logic in importable functions, and `main(argv)` is a thin parser, tested through `main([...])`. Shell scripts are tested through pytest wrappers that stub external commands or work on temp copies:

- `test_verify.py`;
- `test_bump_version.py`;
- `test_githooks.py`;
- `test_run_integration.py`.

Run the suite with `cd tools && .venv/bin/pytest --cov`. Coverage must be ≥ 90 %, and pragmas are banned (RC16).

## Versioning helpers

- `tools/bump_version.sh [patch|minor|major] [--version X.Y.Z+B] [--dry-run]` bumps `apps/taro/pubspec.yaml`. The build number always goes up by 1. It also turns `## [Unreleased]` in `CHANGELOG.md` into `## [X.Y.Z] - <today>` and updates `sonar.projectVersion`. It fails on an empty `Unreleased`.
- `tools/bump_worker_version.sh` does the same for `worker/package.json` (and the lockfile) and `worker/CHANGELOG.md`.
- `tools/phase_state.py` prints the status of every phase from the `**Status:**` lines and checkboxes in `docs/phases/PHASE_*.md`. It supports `--json`, `--status` and `--phase`.
