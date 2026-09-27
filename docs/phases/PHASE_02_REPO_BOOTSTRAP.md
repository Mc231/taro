# Phase 2: Repository Bootstrap & Toolchain

**Status:** ✅ Complete (2026-09-27). Restructured to 3 packages + app per RC95. Carry-overs: FTS5 on the CI runner and placeholder melos scripts → Phase 3; `prodStaging` build → Phase 10.
**Depends on:** Phase 1
**Parallel with:** Phase 9

---

## Overview

This phase creates the empty-but-buildable monorepo: a pub workspace with melos 8, every package and app folder from 02 §2 as a compiling skeleton, the app with three flavors, the `worker/` TypeScript project, and the `tools/` Python and Dart projects. It also runs the two build-risk spikes that 02 flags for Phase 1/2: drift + `sqlite3` 3.x build hooks, and the Dart SDK `^3.9.0` constraint.

No product behaviour is written yet. Each skeleton ships with one real test, so the coverage gate in Phase 3 has something to measure from day one.

**Output of this phase:**
- `/Users/volodymyrshyrochuk/pet/taro` is a git repo with the 02 §2 layout, and `melos bootstrap` works.
- `apps/taro` runs as `dev`, `staging` and `prod` flavors on the iOS simulator and the Android emulator. Each shows a placeholder screen.
- `worker/` builds with `wrangler deploy --dry-run` and serves `GET /v1/health` locally.
- `README.md`, `CLAUDE.md`, `CHANGELOG.md`, `worker/CHANGELOG.md` and `.gitignore` are in place.

---

## Specs referenced

`02_ARCHITECTURE.md` AR1, AR2, AR17, §2, §15, §18, §19. `06_QUALITY_TESTING_CI.md` QA6, QA13, QA14, §6.1, §10, §13. `03_BACKEND_WORKER.md` §1, BE1. `00_DECISIONS.md` RC13–RC16, RC95.

---

## Sprint 2.1: Workspace & packages

**Tasks:**
- [ ] `git init`. Create the GitHub origin `git@github.com:Mc231/taro.git` (owner `Mc231`) and the Gitea pull-mirror of it, as in `quiz_apps` *(MANUAL, owner)*. Protect the `main` branch (06 §8 rules). _Repo and GitHub origin done; the Gitea pull-mirror and branch protection are still for the owner (Phase 3 CI needs the mirror)._
- [x] Root `pubspec.yaml`:
  - `name: taro_workspace`, `publish_to: none`, `environment: sdk ^3.9.0`, `flutter: 3.44.8` (QA14 pin);
  - a `workspace:` list of all packages + `apps/taro` + `tools/dart_tools`;
  - `dev_dependencies: melos ^8.9.0`;
  - `melos:` scripts: `gen`, `test`, `test:fast`, `test:coverage`, `test:golden`, `golden:update`, `test:integration`, `analyze`, `format:check`, `check`, `contract:sync`, `hooks:install`, `coverage:check` (bodies filled in Phase 3).
- [x] Create package skeletons, each with `pubspec.yaml` (`resolution: workspace`, `publish_to: none`, `version: 0.0.0`), a barrel `lib/<pkg>.dart`, `lib/src/` and `test/` (three packages + the app; Reconciled by 00_DECISIONS.md RC95, which replaced the former `taro_content`, `taro_data`, `taro_services`, `taro_l10n` and `taro_testing` packages with app folders):
  - `packages/taro_core` (pure Dart; `test` package, not `flutter_test`; `test/fakes/` for port fakes)
  - `packages/taro_attestation` (Flutter **plugin**, `flutter create --template=plugin --platforms=ios,android --org com.vshyrochuk`)
  - `packages/taro_ui` (Flutter)
- [x] App folder skeletons (02 §2, §2.2): `apps/taro/lib/data/` (incl. `data/content/`), `apps/taro/lib/services/` (incl. `services/presentation/`), `apps/taro/lib/l10n/arb/` + `apps/taro/l10n.yaml` per 02 §11, `apps/taro/assets/deck/` (declared in the app's `flutter: assets:`), `apps/taro/content/source/`, `apps/taro/test/helpers/`.
- [x] Wire the dependency edges exactly as in 02 §2.1 (path/workspace deps only). Add each third-party dependency from 02 §18 to the pubspec that owns it (`app` rows go to `apps/taro`). `flutter pub outdated`: record the resolved versions in `docs/ARCHITECTURE.md` §Dependencies.
- [x] Root `analysis_options.yaml` per 06 §6.1 (very_good_analysis + strict modes). Each package `include:`s it. `apps/taro/analysis_options.yaml` turns off `public_member_api_docs`.
- [x] One smoke test per package, e.g. `packages/taro_core/test/src/taro_core_test.dart` asserting that the barrel exports compile. These are replaced by real tests in later phases.

---

## Sprint 2.2: App skeleton & flavors

**Tasks:**
- [x] `flutter create apps/taro --org com.vshyrochuk --project-name taro --platforms ios,android`.
- [x] iOS:
  - `Runner` target `IPHONEOS_DEPLOYMENT_TARGET = 16.0`, `TARGETED_DEVICE_FAMILY = 1,2` (universal, PR16/RC24), portrait on iPhone, all orientations on iPad;
  - schemes and xcconfigs `dev|staging|prod` with bundle IDs `com.vshyrochuk.taro.dev|.stg|` and display names "Taro Dev|Taro Beta|Taro" (02 §15);
  - `ITSAppUsesNonExemptEncryption = false` (05 §1 technical declarations).
- [x] Android:
  - `minSdk 24`, `productFlavors { dev, staging, prod }` with `applicationIdSuffix` `.dev` / `.stg`, portrait lock;
  - `android:allowBackup` + `data_extraction_rules.xml` / `full_backup_content.xml` **excluding** the secure-storage prefs file (02 §6.2; shared contract) and the device database `taro_device.db` (+ `-wal`/`-shm`) under both `<cloud-backup>` and `<device-transfer>` (02 §6.1, RC75);
  - `usesCleartextTraffic=false` except in the dev flavor (02 §16).
- [x] `apps/taro/config/{dev,staging,prod}.json` with the keys from 02 §15. AdMob fields hold **Google test IDs** in dev and staging (06 §8). Prod values are `TBD` until Phase 10.
- [x] Entrypoints `lib/main_dev.dart`, `main_staging.dart`, `main_prod.dart`, each calling `bootstrap(Flavor.x)`. `lib/bootstrap/bootstrap.dart` and `flavor_config.dart` read `String.fromEnvironment`, with a placeholder `TaroApp`.
- [x] Test `test/bootstrap/flavor_config_test.dart` (parses all three JSONs). Test `test/config/test_ad_ids_test.dart` asserts that dev and staging use Google test ad unit IDs (06 §8).
- [x] Spike: build the app with drift + `drift_flutter` + `sqlite3` 3.x build hooks on iOS and Android, both locally and on the CI runner image. **Also create an FTS5 virtual table and run a `MATCH` query** on the iOS simulator, the Android emulator and the CI runner (Phase 11.1 journal search depends on it, RC91). Record the result and any pins in `docs/ARCHITECTURE.md` §Build notes (02 risk "drift's move to sqlite3 3.x"). If FTS5 is unavailable anywhere, record the fallback: `LIKE` over an indexed lowercase `search_text` column.

---

## Sprint 2.3: Worker & tools skeletons

**Tasks:**
- [x] `worker/`:
  - `package.json` with the deps from 03 §1;
  - `.nvmrc` = 22 (QA14);
  - `tsconfig.json` (strict, `noUncheckedIndexedAccess`, `exactOptionalPropertyTypes`);
  - `wrangler.toml` with `dev`, `staging` and `prod` envs, a pinned `compatibility_date`, `nodejs_compat`, and **placeholder** binding IDs for `DB`, `CONFIG_KV`, `RL_KV`, `CACHE_KV`, `METRICS`, `RL_BURST` and `RL_READINGS`;
  - `src/index.ts`, `src/app.ts` (`buildApp(deps)`), `src/deps.ts` (`makeProdDeps(env)`) and `src/routes/health.ts` returning `{status, workerVersion, environment}` (03 §2.1, GLOSSARY).
- [x] `worker/vitest.config.ts` using `@cloudflare/vitest-pool-workers`, with the coverage config per 06 §5.2. Add `test/integration/routes/health.test.ts`.
- [x] `worker/eslint.config.js` (typescript-eslint `strictTypeChecked`, `no-console`) and `.prettierrc`.
- [x] `tools/`:
  - `pyproject.toml` (Python 3.12, pytest, pytest-cov, ruamel.yaml, jsonschema);
  - `tools/tests/`;
  - `tools/dart_tools/` Dart package (RC/QA §Testing strategy) with an empty `gen_coverage_all.dart` + test.

---

## Sprint 2.4: Repo docs & conventions

**Tasks:**
- [x] `README.md`: what Taro is, repo layout, setup (`melos bootstrap`, `npm ci` in `worker/`, `python -m venv`), commands table, links to specs and phases (06 §13).
- [x] `CLAUDE.md`: structure, commands, git rules (QA12: conventional commits, one per phase, authored by Volodymyr, no AI attribution), plus the merged **coding rules** from 02 §19 and 06 §13 (deduplicated, pragma ban per RC16).
- [x] `CHANGELOG.md` and `worker/CHANGELOG.md` in Keep a Changelog 1.1.0 format, with `## [Unreleased]` (QA13).
- [x] `.gitignore`: build outputs, `coverage/`, `test/coverage_all_test.dart`, `apps/taro/lib/l10n/generated/` (gen-l10n), `.dart_tool/`, `node_modules/`, `.wrangler/`, `worker/.dev.vars`, `.secrets/*.json` (decrypted).
- [x] `docs/ARCHITECTURE.md` stub (living doc per 06 §13) with the package diagram from 02 §1.
- [x] Create `docs/runbooks/` with empty headings: `RELEASE.md`, `INCIDENT.md`, `WORKER_ROLLBACK.md`, `SECRET_ROTATION.md`, `STORE_SUBMISSION.md`, `AI_SAFETY.md`, `DEPENDENCY_UPDATE.md`.

---

## Done when

- [x] `melos bootstrap && melos run analyze && melos run test` is green. `flutter run --flavor dev -t lib/main_dev.dart` works on the iOS simulator and the Android emulator.
- [x] `cd worker && npm ci && npx vitest run && npx wrangler deploy --dry-run --env staging` is green.
- [x] Each package and the worker report ≥ 90% line coverage of the skeleton code, measured manually with `flutter test --coverage` and `vitest --coverage`. The automated gate arrives in Phase 3.
- [x] Docs: README, CLAUDE.md, ARCHITECTURE stub and CHANGELOGs exist.
- [x] One commit: `feat(taro): Phase 2 — Repository bootstrap & toolchain`.

## Next phase

Phase 3: Quality Gates & CI.
