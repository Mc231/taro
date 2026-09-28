# Phase 3: Quality Gates & CI

**Status:** ✅ Complete (2026-09-28): `verify.sh` and Gitea CI (run 740) green, all 9 coverage units ≥ 90 %, FTS5 verified on the runner. Open owner item: create the SonarQube quality gate `Taro` in the UI (advisory, RC88; the stored token cannot administer gates).
**Depends on:** Phase 2

---

## Overview

This phase makes quality mechanical before any feature code exists, as 06 requires. It adds:
- the ≥ 90% per-unit coverage gate for Dart, TypeScript, Python and (per RC40) native code;
- the per-file 70% floor and the ban on coverage pragmas;
- every repo-specific check script with its pytest suite;
- the golden harness;
- the Gitea workflows;
- the commit hooks;
- SonarQube.

From the end of this phase on, every later phase is blocked by `tools/verify.sh` and the `ci` workflow.

**Output of this phase:**
- `tools/verify.sh` (full and `--fast`) reproduces PR CI locally.
- `.gitea/workflows/{ci,reusable-static,reusable-flutter-test,reusable-worker-test,reusable-tools-test,golden,integration,nightly,sonarqube-main}.yml` run green on the skeleton.
- `tools/*.py` checks exist, each with pytest fixtures and ≥ 90% coverage.
- `sonar-project.properties` is in place, and the Sonar quality gate `Taro` is configured.

---

## Specs referenced

`06_QUALITY_TESTING_CI.md` QA1–QA16, §1, §3, §5, §6, §8, §9, §10, §11. `02_ARCHITECTURE.md` AR2 (`check_architecture.dart`), §11 (`check_arb.dart`). `05_COMPLIANCE_STORE_ASO.md` CS3, §9.5, §Testing strategy (`check_store_copy.py`, `check_urls.py`, `check_pack_sizes.py`). `00_DECISIONS.md` RC16, RC39, RC40, RC95.

---

## Sprint 3.1: Coverage pipeline (QA1–QA4, RC16, RC40, RC95)

**Tasks:**
- [x] `tools/coverage_exclusions.txt`: exactly 06 §5.3 plus the RC16 additions (`*.freezed.dart`, `firebase_options_*.dart`, `apps/taro/lib/l10n/generated/**` (gen-l10n output, RC95), `apps/taro/lib/main_*.dart`), with a comment line per pattern explaining the reason.
- [x] `tools/dart_tools/bin/gen_coverage_all.dart`: writes `test/coverage_all_test.dart` importing every non-excluded `lib/**.dart` (QA4). Test it on `tools/dart_tools/test/fixtures/sample_pkg/`.
- [x] Melos `test:coverage` script. For each unit: generate the coverage-all file → `flutter test --coverage --exclude-tags=integration` → `lcov --remove … -o coverage/lcov.filtered.info`.
- [x] `tools/check_coverage.py` must:
  - discover units (`taro_core`, `taro_ui`, `taro_attestation`, `taro_attestation_ios`, `taro_attestation_android`, `apps/taro`, `worker`, `tools`; RC95);
  - fail on: a missing report, a missing file, unit < 90.0, file < 70.0, pragmas (`coverage:ignore-*`, `istanbul ignore`, `c8 ignore`, `pragma: no cover`), or Sonar exclusion drift (`--verify-sonar`);
  - write `coverage/merged/lcov.info` and `coverage/summary.md`;
  - support the flags `--unit`, `--json`, `--threshold` (test-only).
- [x] `tools/tests/test_check_coverage.py` with synthetic lcov/json-summary fixtures covering each failure mode (06 §Testing strategy).
- [x] Native coverage (RC40):
  - `tools/ci/native_coverage_ios.sh` (`xcodebuild test -enableCodeCoverage YES` on `taro_attestation/example/ios`, `xcrun xccov view --report --json` → converted to lcov by `tools/xccov_to_lcov.py`);
  - `tools/ci/native_coverage_android.sh` (Gradle JaCoCo on `taro_attestation/android` → `jacoco.xml` → lcov via `tools/jacoco_to_lcov.py`);
  - both converters tested with pytest.
- [x] Worker: `npm run test:coverage` emits `worker/coverage/{lcov.info,coverage-summary.json}`, and the thresholds in `vitest.config.ts` match QA7 (90/90/90/85).
- [x] Tools: `pytest --cov=tools --cov-report=json --cov-report=xml --cov-fail-under=90`.

---

## Sprint 3.2: Repo checks (06 §6.2, 02 AR2, 05 §9.5)

Each script lives in `tools/` with `main(argv)`, pure functions, and `tools/tests/fixtures/<check>/{pass,fail_*}/` fixture trees.

**Tasks:**
- [x] `tools/check_architecture.dart` (in `tools/dart_tools`): the import-graph check. It enforces the 02 §2.1 package table (3 packages + app) and the `apps/taro/lib` folder table (`features/` ↛ `data/`, `services/`; `data/` ↛ `features/`, `services/`; `services/` ↛ `data/`; `l10n/` ↛ any folder; …), bans cross-package `lib/src` imports, allows `apps/taro/test/**` to import `packages/taro_core/test/{fakes,contracts}/**` and `packages/taro_ui/test/helpers/**` only, and flags non-directional layout APIs (02 §11). Test it on fixture trees. Reconciled by 00_DECISIONS.md RC95 (the folder rules replace the former package rules).
- [x] `tools/import_rules.yaml`: the SDK-import allowlist per adapter directory (RC/QA9). It is generated from the 02 §5 port table and consumed by `check_forbidden_apis.py`.
- [x] `tools/check_forbidden_apis.py`: bans `DateTime.now(`, `Random(`, `Random.secure(`, `Uuid().v4(`, `print(`, `debugPrint(`, SDK imports outside the allowlist, non-directional APIs, and test support (`test/fakes/`, `test/contracts/`, `test/helpers/`) imported from `lib/`. Raw `Color(0x`, `fontSize:` and `Duration(milliseconds:` are banned **only in UI code**: `packages/taro_ui/lib/**` (except `src/tokens/**` and `src/motion/**`), `apps/taro/lib/features/**/view/**` and `apps/taro/lib/common/**` (06 §6.2, RC90). Fixtures cover both scopes (a flagged widget file; an unflagged `apps/taro/lib/data/` retry backoff using `ApiTimeouts`).
- [x] `tools/check_l10n.py`: ARB key/placeholder/ICU parity across the 12 locales, `@key.description` required, untranslated allowlist, the user-facing literal heuristic, deck content completeness (once Phase 5 lands), and store field limits. `tools/dart_tools/bin/check_arb.dart` (02 §11) is folded into this script. Record the choice in `docs/ARCHITECTURE.md`.
- [x] `tools/check_iap_ids.py`: regex `^com\.vshyrochuk\.taro\.[a-z0-9_]+$`, and sets equal across `packages/taro_core/lib/src/monetization/taro_products.dart`, `worker/src/monetization/catalog.ts` and `apps/taro/store/aso.yaml`. Remove Ads must be the only non-consumable (RC3).
- [x] `tools/store_copy/check_store_copy.py` + `tools/store_copy/banned_phrases.yaml` (per-locale `global`/`apple_only`/`play_only`, seed list from 05 §9.5 and 06 §6.2, RC39) + `tools/store_copy/required_sentences.yaml`. Rules: banned phrases, the `description_has_disclaimer` rule, `apple_fields_no_android`, keyword rules, field limits, review notes ≤ 4000.
- [x] `tools/store_copy/check_pack_sizes.py` (05 Risks): the display-name counts in `aso.yaml` match the `catalog.ts` credits.
- [x] `tools/check_urls.py` (05 CS10): every URL in `aso.yaml` and the ARB files returns 200. It runs weekly in `nightly.yml` and has an `--offline` mode for PRs.
- [x] `tools/check_analytics_events.py`: the event classes in code match `docs/ANALYTICS_EVENTS.md` (01 §15, PR18). It also fails if any param type is `String` without an enum annotation.
- [x] `tools/check_contract_fixtures.py` (QA15, RC38).
- [x] `tools/check_remote_config.py`: the defaults JSON validates against the exported JSON Schema (`worker/config/remote_config.schema.json`, exported from zod), and every client-read key has a default.
- [x] `tools/check_commit_msg.py` (QA12): the conventional-commit regex, and a rejection of AI attribution markers.
- [x] `tools/check_migrations.py`: append-only, no gaps, and `DROP` statements need a contract-phase marker.
- [x] `tools/check_changelog.py`: `--version` for deploys and `--pr` for PRs.
- [x] `tools/check_glossary.py` (Phase 1 Sprint 1.2; 06 §6.2): fails when an ID in `docs/specs/GLOSSARY.md` (cards, spreads and positions, products, endpoints, error codes, config keys, screens) differs from the generator inputs and code constants that use it, and when a `failure*`/`safetyDeclined*` key listed there is missing from `app_en.arb` (RC94).
- [x] `tools/check_skadnetwork.py` (05 §1 technical declarations): the `Info.plist` `SKAdNetworkItems` match the pinned list `tools/skadnetwork_ids.txt`.
- [x] `tools/check_retention.py` (RC69): the retention periods in 03 §13 equal those in `web/privacy.en.md` §Retention and in the ARB `aiConsentBody`.
- [x] `tools/check_worker_env.py` (RC86): `worker/wrangler.toml` `[env.prod]` has no `ALLOW_DEBUG_ATTESTATION`, `AI_PROVIDER` or `DEBUG_ATTESTATION_TOKEN`.
- [x] `check_store_copy.py` rules added by the review pass: `review_notes_labels_exist` (RC79) and the Remove Banner Ads display-name length ≤ 30 in all 12 locales (RC80).
- [x] `.gitleaks.toml` and `gitleaks detect` in the static job and the pre-push hook.

---

## Sprint 3.3: Golden & widget harness (QA8)

**Tasks:**
- [x] `packages/taro_ui/test/helpers/golden/taro_golden_comparator.dart` (0.1% tolerance), `load_taro_test_fonts.dart` (bundled Noto Sans, Noto Sans Arabic, Noto Sans JP, Noto Sans KR under `packages/taro_ui/test/helpers/golden/fonts/`), and `golden_matrix.dart` (`{light,dark} × {en,ar}` + optional `ja`, `de`, `textScale 2.0`; sizes per the next task).
- [x] `packages/taro_ui/test/helpers/golden/golden_sizes.dart`: sizes `kPhoneSmall` 375×667, `kPhoneLarge` 430×932, `kTabletIpad13` 1032×1376, `kTabletAndroid` 800×1280; `goldenMatrix` emits phone variants for every golden and tablet variants (en light, ar dark) for ★ screens (06 §3, RC24; universal apps, owner 2026-09-27).
- [x] `apps/taro/test/helpers/pump_taro_widget.dart`: `pumpTaroWidget(tester, child, {Locale, ThemeMode, textScale, Size})` for widgets without providers (it wraps them in `TaroLocalizations` and the token theme; `taro_ui` component tests use their own `MaterialApp` + `TaroTheme` wrapper in `taro_ui/test/helpers/`, since a package cannot import the app, RC95). It is **Riverpod-free** (02 §2.1, RC77); the app-level `pumpTaro` with `TaroFakes` overrides lands in `apps/taro/test/helpers/pump_app.dart` in Phase 13.1.
- [x] `melos run golden:update` refuses to run off the reference platform unless given `--force-local`.
- [x] A sample golden test in `packages/taro_ui/test/golden/sample_golden_test.dart`, to prove the pipeline works on the runner; it covers one phone and one tablet size (`kTabletIpad13`, RC24).

---

## Sprint 3.4: CI workflows (QA10, 06 §8)

**Tasks:**
- [x] `.gitea/workflows/reusable-static.yml`:
  - format check, `flutter analyze --fatal-infos`, all Sprint 3.2 checks, commit-message check over the PR range, gitleaks, `actionlint`, `shellcheck`;
  - worker `tsc --noEmit`, eslint, prettier, `wrangler deploy --dry-run` with a bundle-size check, and `npm audit --omit=dev --audit-level=high`.
- [x] `.gitea/workflows/reusable-flutter-test.yml` (`melos run test:coverage`, upload coverage + golden failures), `reusable-worker-test.yml`, `reusable-tools-test.yml`, and a `reusable-native-test.yml` for RC40.
- [x] `.gitea/workflows/ci.yml`: calls the reusable workflows, then a `coverage-gate` job running `check_coverage.py --verify-sonar` and posting `coverage/summary.md`. Superseded runs are cancelled by concurrency.
- [x] `.gitea/workflows/golden.yml`: `workflow_dispatch`, `update: bool`, commits `test(golden): update goldens`.
- [x] `.gitea/workflows/integration.yml`: iOS simulator on PRs; nightly adds the Android emulator. `tools/ci/sim.env` pins the device and OS.
- [x] `.gitea/workflows/nightly.yml`: integration on both platforms, `npm audit`, `dart pub outdated`, a full golden run, weekly `check_urls.py`, and a Monday `eval:safety` slot (wired in Phase 8).
- [x] Toolchain pins: `subosito/flutter-action` with `flutter-version-file: pubspec.yaml`, Node from `worker/.nvmrc`, Python 3.12.
- [x] Secrets bootstrap _(done 2026-09-28: bundle unlocked by `TARO_SECRETS`, Gitea secret `SECRETS_PASSPHRASE` set; tools/secrets-manager.sh + .secrets/README.md done; creating secrets.json.gpg and the Gitea secret is the owner's manual step)_: create `.secrets/secrets.json.gpg` for taro following the quiz_apps pattern, and the Gitea secret `SECRETS_PASSPHRASE` *(MANUAL)*. `tools/secrets-manager.sh` is ported (list, decrypt, encrypt).

---

## Sprint 3.5: SonarQube, hooks, versioning, phase state

**Tasks:**
- [x] `sonar-project.properties` _(file done, exclusions match; Sonar project + `Taro` gate creation is manual, see docs/phase3_notes/CI.md)_ (06 §9): projectKey `taro`, sources, tests, lcov paths for Dart, JS and Python, and `sonar.coverage.exclusions` = the Sprint 3.1 list. Create the Sonar project and the `Taro` quality gate *(MANUAL, Sonar UI)*. The gate is **advisory** (QA11, RC88): its status goes to the job summary and is never required by `ci` or the deploy workflows.
- [x] `.gitea/workflows/sonarqube-main.yml` on push to `main`.
- [x] `melos run hooks:install`: `commit-msg` → `check_commit_msg.py`; `pre-push` → `tools/verify.sh --fast`.
- [x] `tools/verify.sh` (full and `--fast`, 06 §6.4), tested via a pytest wrapper that stubs the commands.
- [x] `tools/bump_version.sh` and `tools/bump_worker_version.sh` (06 §10.1, Unreleased→dated, build number always +1, Sonar version), tested with bats or a pytest wrapper on temp copies.
- [x] `tools/phase_state.py`: reads the phase status from `docs/phases/PHASE_*.md` and prints a table. Port it from quiz_apps and cover it with pytest.
- [x] `docs/TESTING.md`: the harness, fakes, builders, goldens, contract suites and determinism rules (06 §13).

---

## Carried over from Phase 2

- [x] Run the RC91 FTS5 probe _(CI run 740, 2026-09-28: SQLite 3.53.4, FTS5 MATCH ok in memory and via driftDatabase; iOS simulator integration green)_ (`apps/taro/test/data/db/fts5_probe_test.dart`) on the CI runner image and record the SQLite version in `docs/ARCHITECTURE.md` §Dependencies and build notes.
- [x] Fill the placeholder melos scripts `check`, `contract:sync`, `hooks:install`, `coverage:check`, `test:integration`.

## Done when

- [x] `tools/verify.sh` is green locally _(✅ 2026-09-28)_, and the `ci` workflow _(✅ Gitea run 740, all 7 jobs green, 2026-09-28)_ is green on the Gitea runner for this phase's SHA.
- [x] `check_coverage.py` reports every unit ≥ 90% (skeleton code + tools ≥ 90%). A deliberately uncovered file in a scratch branch makes the gate fail (screenshot or log attached to the phase notes).
- [ ] The Sonar project and advisory gate `Taro` exist and report on `main` (not a blocking gate, RC88).
- [x] Docs updated: `docs/TESTING.md`, README commands table, and CLAUDE.md (hooks, verify).
- [x] One commit: `ci(taro): Phase 3 — Quality gates & CI`.

## Next phase

Phase 4: Core Domain & Test Kit. Worker phases 6–8 may start in parallel after Sprint 3.4.
