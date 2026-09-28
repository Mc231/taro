# Taro

Taro is a reflective tarot journal with AI readings for iOS and Android (iPhone, iPad, Android phones and tablets), built with Flutter. Bundle ID: `com.vshyrochuk.taro`.

- One free AI reading per day. Extra readings come from consumable IAP packs or optional rewarded ads. "Remove Banner Ads" is the one non-consumable.
- Readings are framed as reflection, not prediction. Restricted questions (health, legal, financial, self-harm, …) are declined at no cost. Self-harm questions show crisis resources.
- There are no accounts. The install is anonymous, and the journal can be exported and imported as a backup file.
- A Cloudflare Worker holds the Anthropic key and is the source of truth for credits, allowance, grants and remote config. The client never computes a balance.
- 12 locales at launch: `en, ar, de, es, fr, it, ja, ko, nl, pt, tr, uk` (Arabic is RTL).

The project follows a specs-first process. Six specs define the product and the implementation phases execute them. See [docs/specs/README.md](docs/specs/README.md).

## Repository layout

```
taro/
├── pubspec.yaml            # pub workspace root + melos 8 scripts
├── analysis_options.yaml   # very_good_analysis + strict modes, shared by every package
├── apps/taro/              # the Flutter app (flavors dev, staging, prod)
│   ├── lib/
│   │   ├── data/           # drift databases, secure storage, Worker client, repositories, content repos
│   │   ├── services/       # IAP, ads, consent, analytics, crash, notifications, attestation adapters
│   │   ├── l10n/           # ARB bundle (arb/) and generated localizations (generated/)
│   │   └── features/ …     # screens and controllers; app_state/, common/, routing/, di/, bootstrap/
│   ├── l10n.yaml           # gen-l10n config
│   ├── assets/deck/        # generated deck, spreads, meanings (12 locales), crisis resources
│   ├── content/source/     # authored content YAML (input of `tools/content build`)
│   └── test/helpers/       # pumpTaro, pumpTaroWidget, TaroFakes
├── packages/
│   ├── taro_core/          # pure Dart: domain, ports, use cases (port fakes + contract suites in test/)
│   ├── taro_ui/            # design tokens, theme, components (golden comparator in test/helpers/)
│   └── taro_attestation/   # own plugin: App Attest / Play Integrity (Swift + Kotlin)
├── worker/                 # Cloudflare Worker (TypeScript, Hono, D1, KV)
├── tools/                  # Python repo checks (pytest), tools/dart_tools, generators
└── docs/
    ├── specs/              # 00_DECISIONS, GLOSSARY, 01–06 specs
    ├── phases/             # PHASE_01 … PHASE_23 implementation plan
    ├── design/             # Claude Design handoff: taro.tokens.json, screens, assets
    ├── runbooks/           # release, incident, rollback, secret rotation, …
    └── ARCHITECTURE.md     # living architecture doc
```

Three packages plus the app (00_DECISIONS RC95). Dependency rules between the packages and between the app's folders (`features/` → `data/`/`services/` only through `taro_core` ports, `data/` never imports `features/` or `services/`, …) are in [02_ARCHITECTURE.md §2.1](docs/specs/02_ARCHITECTURE.md). The import-graph check `tools/check_architecture.dart` enforces them from Phase 3.

## Setup

Toolchain pins (06 QA14): Flutter **3.44.8** (root `pubspec.yaml` `environment.flutter`), Dart SDK `^3.9.0`, Node **22** (`worker/.nvmrc`), Python **3.12** (`tools/`).

```bash
# Flutter workspace
dart pub global activate melos     # melos 8 (also a root dev_dependency)
melos bootstrap

# Worker
cd worker && npm ci && cd ..

# Python tools (a venv under tools/.venv, gitignored)
cd tools
python3.12 -m venv .venv           # any Python >= 3.12 works locally; CI uses 3.12
.venv/bin/pip install -e '.[dev]'
cd ..

# Git hooks (commit-msg + pre-push), available from Phase 3
melos run hooks:install
```

## Commands

| Command | What it does |
|---|---|
| `melos bootstrap` | Resolve the workspace, link all packages, then run `gen:l10n` |
| `melos run gen` | Run every code generator (gen-l10n today; build_runner and tokens as they land) |
| `melos run analyze` | `flutter analyze --fatal-infos` in every package |
| `melos run format:check` | `dart format --set-exit-if-changed` |
| `melos run test` | All Dart/Flutter tests |
| `melos run test:fast` | Tests in changed packages only |
| `melos run test:coverage` | Tests with lcov per coverage unit (`taro_core`, `taro_ui`, `taro_attestation`, `apps/taro`) |
| `melos run coverage:check` | The ≥ 90% per-unit / 70% per-file gate (`tools/check_coverage.py`) |
| `melos run test:golden` / `golden:update` | Golden tests only / regenerate goldens; refuses off the reference platform (macOS arm64 + pinned Flutter) unless `-- --force-local` ([docs/TESTING.md](docs/TESTING.md)) |
| `melos run test:integration` | Device tests on a booted simulator/emulator (`TARO_INTEGRATION_PLATFORM`, `TARO_DEVICE_ID`; patrol from Phase 13) |
| `melos run check` | `tools/verify.sh --fast`: format, analyze, every repo check (architecture, forbidden APIs, l10n, IAP IDs, …), gitleaks, `test:fast` |
| `melos run contract:sync` | Mirror Worker contract fixtures into `apps/taro/test/contract/fixtures/` |
| `melos run hooks:install` | `commit-msg` (`check_commit_msg.py`) and `pre-push` (`tools/verify.sh --fast`) via `core.hooksPath=tools/githooks` |
| `cd apps/taro && flutter run --flavor dev -t lib/main_dev.dart --dart-define-from-file=config/dev.json` | Run the dev flavor |
| `cd worker && npm test` / `npm run test:coverage` | Worker tests (vitest on workerd) / with istanbul coverage |
| `cd worker && npm run lint && npm run typecheck && npm run format:check` | ESLint, `tsc --noEmit`, Prettier |
| `cd worker && npm run dev` | Local Worker, dev env (`GET /v1/health`) |
| `cd worker && npx wrangler deploy --dry-run --env staging` | Build the Worker bundle without deploying |
| `cd tools && .venv/bin/pytest --cov` | Python tools tests, ≥ 90% coverage |
| `tools/verify.sh [--fast]` | Everything CI runs except integration tests; `--fast` is the pre-push gate |
| `tools/bump_version.sh` / `tools/bump_worker_version.sh` | Release version bump + CHANGELOG `Unreleased` → dated section (06 §10.1) |
| `tools/phase_state.py` | Status table of every phase from `docs/phases/PHASE_*.md` |

How to write tests (harness, fakes, goldens, contract suites, determinism): [docs/TESTING.md](docs/TESTING.md).

## Documentation

- **Specs:** [docs/specs/README.md](docs/specs/README.md): product (01), architecture (02), Worker (03), monetization (04), compliance and ASO (05), quality, testing and CI (06).
- **Decisions and names:** [00_DECISIONS.md](docs/specs/00_DECISIONS.md) (RC decision log) and [GLOSSARY.md](docs/specs/GLOSSARY.md) (the only source of spelling for IDs, endpoints, keys and routes).
- **Phases:** [docs/phases/README.md](docs/phases/README.md): the ordered implementation plan and its status.
- **Design:** [docs/design/README.md](docs/design/README.md): Claude Design system, [`taro.tokens.json`](docs/design/taro.tokens.json), screens S01–S33.
- **Architecture (living):** [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).
- **Runbooks:** [docs/runbooks/](docs/runbooks/).
- **Changelogs:** [CHANGELOG.md](CHANGELOG.md) (app and packages), [worker/CHANGELOG.md](worker/CHANGELOG.md) (Worker).
- **Working in this repo (agents and humans):** [CLAUDE.md](CLAUDE.md).
