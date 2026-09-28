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
| Integration | `apps/taro/integration_test/` (spikes), `apps/taro/patrol_test/` (flows, Phase 13) | none | `melos run test:integration`, integration.yml |
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

## Widget harness

- **`pumpTaroWidget(tester, child, {locale, theme, textScale, size})`**, in `apps/taro/test/helpers/pump_taro_widget.dart`, is for widgets without providers. It wraps the child in:
  - a `MaterialApp` with `TaroLocalizations`, which sets `Directionality` from the locale;
  - the Taro theme in `ThemeMode` `theme`;
  - a `TextScaler.linear(textScale)` with reduced motion.

  The surface is `size` logical pixels at a device pixel ratio of 1.0. The defaults are `en`, light, 1.0 and `kPhoneSmall`. It is Riverpod-free (RC77).
- **`pumpTaro(tester, {fakes, ...})`**, in `apps/taro/test/helpers/pump_app.dart` (Phase 13.1), adds `ProviderScope(overrides: fakes.toOverrides())` on top for screens.
- **`pumpTaroUiWidget(...)`**, in `packages/taro_ui/test/helpers/pump_taro_ui_widget.dart`, is the same wrapper for `taro_ui` components. The package cannot import the app, so it has no `TaroLocalizations` and the locale only sets the text direction.
- Every package's `test/flutter_test_config.dart` loads the bundled test fonts and installs `TaroGoldenComparator` before any test runs. Text in widget tests is therefore measured with real glyphs, not the square `FlutterTest` font.

## Goldens (QA8, 06 §3, RC24)

- Goldens use Flutter's `matchesGoldenFile` only. `TaroGoldenComparator` (`packages/taro_ui/test/helpers/golden/taro_golden_comparator.dart`) passes a diff of up to 0.1 % of pixels. Above that, it writes masked diffs to `test/golden/failures/` (gitignored), which CI uploads.
- **Fonts:** Noto Sans (Latin, Greek, Cyrillic), Noto Sans Arabic, Noto Sans JP and Noto Sans KR, regular weight, OFL 1.1. They live in `packages/taro_ui/test/helpers/golden/fonts/`; `NOTICE.md` there has the sources and the subset recipe. Noto Sans is also registered as `Roboto` and the Cupertino system families. `withTaroTestFonts(theme)` adds the Arabic, Japanese and Korean fallbacks.
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

It runs the `dev` flavor with `config/dev.json`. patrol flows in `apps/taro/patrol_test/` run with `patrol test`. Until they land in Phase 13, the `integration_test/` spikes run with `flutter test integration_test`. CI pins its devices in `tools/ci/sim.env`.

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
