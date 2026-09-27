# Claude Code Guide: Taro

Taro is a reflective tarot journal with AI readings (Flutter, iOS + Android, universal). It is a pub-workspace monorepo run with melos 8, plus a Cloudflare Worker and Python/Dart tools. Specs come first: code follows `docs/specs/`, and the work is ordered by `docs/phases/`.

## Before you change anything

- **Names:** `docs/specs/GLOSSARY.md` is the only source of spelling for IDs, endpoints, error codes, tables, config keys, routes, ports and events. A new name is added there first.
- **Decisions:** `docs/specs/00_DECISIONS.md` (RC rows) overrides every other spec. Ownership when specs disagree: product behaviour → 01, wire format / config keys / money logic → 03, prices / packs / ad rules → 04, store and legal copy / safety bar → 05, test and coverage rules → 06.
- **Specs:** `docs/specs/README.md` (index and reading order). `02_ARCHITECTURE.md` for client structure, `03_BACKEND_WORKER.md` for the Worker, `06_QUALITY_TESTING_CI.md` for gates.
- **Phases:** `docs/phases/README.md`. Work the current phase's sprint checkboxes and tick each one with evidence (test names or file paths).
- **Design:** `docs/design/README.md`. Tokens live in `docs/design/taro.tokens.json` (DTCG, names per 01 §14); the Claude Design canvas is the source of truth for screens.
- **Living docs:** `docs/ARCHITECTURE.md` (packages, dependency versions, build notes), `docs/runbooks/`.

## Project structure

```
taro/
├── pubspec.yaml / analysis_options.yaml   # workspace root, melos scripts, shared lints
├── apps/taro/                 # the app (00_DECISIONS RC95: 3 packages + app)
│   ├── lib/
│   │   ├── bootstrap/ di/ routing/ app_state/ common/ features/<f>/
│   │   ├── data/              # drift (taro_journal.db + taro_device.db), secure storage, WorkerClient, repositories; data/content/ = bundled-content repos
│   │   ├── services/          # SDK adapters: IAP, AdMob+UMP, ATT, Firebase, notifications, attestation, tz, files; services/presentation/ = BannerSlotView adapters
│   │   └── l10n/              # arb/ (12 locales) + generated/ (gen-l10n output, see apps/taro/l10n.yaml)
│   ├── assets/deck/           # generated content JSON (deck, spreads, crisis resources; only `tools/content build` writes it)
│   ├── content/source/        # authored content YAML (input of `tools/content build`; not bundled)
│   ├── test/helpers/          # pumpTaro, pumpTaroWidget, TaroFakes; test/contract/fixtures/ = Worker fixture copies
│   └── config/{dev,staging,prod}.json    # --dart-define-from-file; no secrets in the client
├── packages/
│   ├── taro_core/             # pure Dart: Result/Failure, freezed models, ports, use cases; test/fakes/ + test/contracts/ (Riverpod-free)
│   ├── taro_attestation/      # own plugin: App Attest / DeviceCheck (Swift), Play Integrity Standard (Kotlin)
│   └── taro_ui/               # tokens, TaroTokens ThemeExtension, components (no business logic); test/helpers/golden/
├── worker/                    # Cloudflare Worker (TypeScript, Hono, D1, KV); own CHANGELOG
├── tools/                     # Python 3.12 checks (pytest), tools/dart_tools, content + token generators
└── docs/                      # specs/, phases/, design/, runbooks/, ARCHITECTURE.md
```

Dependency rules (02 §2.1, RC95), enforced by the import-graph check `tools/check_architecture.dart`: `taro_core` depends on nothing Flutter or I/O; `taro_ui` and `taro_attestation` depend on no taro package; only `apps/taro` depends on Riverpod. Inside the app: `features/` never imports `data/`, `services/`, vendor SDKs or other features (they reach data and services through `taro_core` ports in `di/`); `data/` never imports `features/` or `services/`; `services/` never imports `data/` (only via core ports); `l10n/` imports no other folder. Cross-package `lib/src` imports are violations; only barrels are public.

## Commands

```bash
melos bootstrap                    # resolve workspace, then gen-l10n
melos run gen                      # all code generators
melos run analyze                  # flutter analyze --fatal-infos
melos run format:check             # dart format --set-exit-if-changed
melos run test                     # all Dart/Flutter tests
melos run test:coverage            # lcov per unit (taro_core, taro_ui, taro_attestation, apps/taro)
melos run test:golden              # goldens (reference: macOS CI runner, pinned Flutter)
melos run check                    # repo checks (Phase 3)
melos run coverage:check           # >= 90 % per unit, >= 70 % per file (Phase 3)
melos run contract:sync            # worker contract fixtures -> apps/taro/test/contract/fixtures/ (Phase 3)
melos run hooks:install            # commit-msg + pre-push hooks (Phase 3)

cd apps/taro && flutter run --flavor dev -t lib/main_dev.dart --dart-define-from-file=config/dev.json

cd worker && npm ci                # Node 22 (worker/.nvmrc)
cd worker && npm test              # vitest on workerd; npm run test:coverage for istanbul
cd worker && npm run lint && npm run typecheck && npm run format:check
cd worker && npx wrangler deploy --dry-run --env staging

cd tools && python3.12 -m venv .venv && .venv/bin/pip install -e '.[dev]'
cd tools && .venv/bin/pytest --cov # >= 90 % (fail_under in pyproject.toml)

tools/verify.sh [--fast]           # everything CI runs except integration (Phase 3)
```

Before a commit: format, analyze, tests and coverage for every unit you touched (`tools/verify.sh --fast` once it exists).

## Git rules (06 QA12, §10.3)

- **Author: Volodymyr Shyrochuk.** No AI attribution of any form: no `Co-Authored-By:` trailers naming an AI, no "Generated with", no "Claude Code", no 🤖, no `noreply@anthropic.com`. The `commit-msg` hook and CI reject them. Mentioning the AI reading *feature* in a message is fine.
- **Conventional commits:** `^(feat|fix|docs|test|refactor|perf|build|ci|chore|revert)(\(scope\))?!?: <subject ≤ 72>`. Scopes: `taro`, a package short name, `worker`, `tools`, `ci`, `l10n`, `deps`, `docs`, `golden`.
- **One commit per phase:** `feat(taro): Phase N — <phase title>` (`feat(worker): …` for Worker-only phases, `docs(taro): …` for docs-only phases). Commit only after the phase's Definition of Done (06 §11.2) holds. Follow-up fixes are separate `fix:` commits.
- Do not commit or push unless the owner asks. Never commit decrypted secrets (`.secrets/*.json`, `worker/.dev.vars`).
- Every behaviour change adds a line under `## [Unreleased]` in `CHANGELOG.md` (app and packages) or `worker/CHANGELOG.md` (Keep a Changelog 1.1.0, QA13).

## Coding rules

Merged from 02 §19 and 06 §13. Phases may add rules; they never weaken these.

### Architecture and boundaries
1. **Layering is law.** Respect 02 §2.1 and the in-app folder table; `tools/check_architecture.dart` must pass.
2. **Every external service is a port** in `taro_core` with a production adapter, a `NoOp…` and a `Fake…` (in `packages/taro_core/test/fakes/`), plus a shared contract suite run against the fake and, where possible, the real adapter. SDK imports appear only in adapter files (`tools/import_rules.yaml`).
3. **No throws across boundaries.** Repositories and use cases return `Result<T>`. `switch` on `Failure` exhaustively. No `catch (e) {}` without mapping and logging.
4. **Sealed classes expose a factory for every case** (`Failure.network()`, `ReadingStatus.completed()`); states are `@freezed sealed` unions.
5. **Determinism through ports.** Randomness only via `RandomSource`, IDs via `IdGenerator`, time via `Clock`, timezone via `TimezoneProvider`, logging via `Logger`. `DateTime.now()`, `Random()`, `Random.secure()`, `Uuid().v4()`, `print` and `debugPrint` are banned outside adapters (`check_forbidden_apis.py`, QA9). The Worker does the same through its deps object.
6. **Anything clock-dependent runs on launch AND resume** via `SyncCoordinator`, idempotently. Ask: "what re-runs this when the app has been open since yesterday?" Time-based behaviour has a resume-path test.

### Money, credits and readings
7. **The Worker is the source of truth** for credits, allowance, rewarded grants and remote config. The client never computes a balance: it changes only by applying a Worker response. No optimistic decrement.
8. **Purchases are finished/consumed only after the Worker grant** is persisted; the outbox row is written before verification.
9. **IAP product IDs are fully qualified:** `com.vshyrochuk.taro.readings_3|readings_10|readings_30|remove_ads`. `IapCatalog.validate()` enforces it. Credit amounts never live in the client.
10. **Paywall before the draw.** Only `ReadingGate` decides (RC44 order). `CardDrawer.draw` runs only on `GateDecision.allowed` **and** after `POST /v1/readings/holds` succeeded; cards are revealed only while the hold is valid (RC50). Budget stops and kill switches are never shown as a paywall (RC47).
11. **No dark patterns:** the free reading is real, no fake urgency or timers (countdowns only from server `free.resetsAt`), no pre-checked purchase options, close buttons always visible, disclaimers on reading screens.
12. **Ads never overlay or sit inside reading content**, never interrupt a reading, never auto-show rewarded. Banners only on `kBannerAllowList` with `space.adGap` ≥ 16 dp. UMP before ads; neutral pre-prompt then ATT after UMP (RC18, RC19, RC59).

### UI, localization and accessibility
13. **All UI strings via ARB (`TaroLocalizations`)**, all 12 locales updated in the same change. No string literals in widgets except debug-only. Deck content is authored in `apps/taro/content/source/{locale}/` and built only by `tools/content build` (RC26).
14. **Directional layout only** (`EdgeInsetsDirectional`, `AlignmentDirectional`, `TextAlign.start`/`end`). Every new screen has LTR + RTL goldens; every ★ screen also has tablet-width goldens (RC24).
15. **Design tokens only** (names per 01 §14). No `Color(0x…)`, raw `Duration`, magic spacing, radii or `TextStyle(fontSize:)` in UI code (`taro_ui` outside tokens/motion, `features/**/view/**`, `common/**`). Non-UI durations (timeouts, backoff) come from named constants or config (RC90).
16. **Accessibility:** Semantics labels on every interactive element and card; ≥ 48 × 48 targets; text scales to 200 % without clipping (golden at textScaler 2.0 for key screens); respect reduced motion.
17. **Shared state widgets:** `TaroLoadingView`, `TaroEmptyView`, `TaroErrorView` (01 §8.2). Never a raw `CircularProgressIndicator` or ad-hoc error text.

### Analytics, copy and names
18. **Typed analytics only** (`AnalyticsEvent` subclasses), each documented in `docs/ANALYTICS_EVENTS.md`. Never log question, reading or journal text, the install ID or tokens.
19. **Apple-facing text never mentions Android or Google**, and vice versa. No banned claims (`tools/store_copy/banned_phrases.yaml`, RC39).
20. **Canonical names only** (GLOSSARY.md). New remote-config keys live in a 03 §8.2 namespace with a default and a schema entry (RC8).

### Tests and coverage
21. **Tests ship in the same change** as the code: unit for logic, widget for UI, golden if a key screen changed, contract fixture if an API shape changed, Worker integration test if a route changed. Every bug fix starts with a failing test.
22. **Coverage ≥ 90 % per unit** (`taro_core`, `taro_ui`, `taro_attestation` and its native units (RC40), `apps/taro`, `worker`, `tools`; RC95) and ≥ 70 % per file. **Coverage pragmas (`// coverage:ignore-*`, `# pragma: no cover`, `/* istanbul ignore */`) are banned** (RC16). Only generated files listed in `tools/coverage_exclusions.txt` (06 §5.3) are excluded; changing that list needs the spec table and `sonar-project.properties` updated in the same change.
23. **mocktail + hand-written fakes**; no mockito codegen. Goldens use `matchesGoldenFile` with `TaroGoldenComparator`. Integration tests use patrol.
24. **New dependencies** need a port if they touch an external service, a row in `docs/ARCHITECTURE.md` §Dependencies, and a license check.

## Python tools

`tools/` is a coverage unit (QA1). Scripts keep logic in importable functions; `main(argv)` is a thin argument parser tested through `main([...])`. Shared helpers live in `tools/taro_tools/`. Each check has fixture trees under `tools/tests/fixtures/<check>/{pass,fail_*}/`. The venv is `tools/.venv` (gitignored); CI uses Python 3.12.
