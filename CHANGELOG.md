# Changelog

All notable changes to the Taro app (`apps/taro`) and its packages (`packages/*`) are documented in this file. Worker changes are in [worker/CHANGELOG.md](worker/CHANGELOG.md).

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html). App versions are `X.Y.Z+B`; the build number `B` is monotonic across both stores (06 §10.1).

## [Unreleased]

### Added

- Phase 5, deck content (English drafts): `apps/taro/content/source/` with `deck.yaml`, `glossary.yaml` (12 locales), all 78 `en` cards, `en/spreads.yaml` (6 spreads), `en/articles/{about,faq}.md` and `crisis/crisis_resources.yaml` (every entry `verifiedAt: null`). All `en` text is an LLM draft (`reviewStatus: machine`) awaiting the owner edit pass. Docs: `docs/content/{STYLE_GUIDE,REVIEW_CHECKLIST,AUTHORING_LOG}.md` and the `docs/ART_PROVENANCE.md` stub.
- Phase 5, content repositories and generated assets: `apps/taro/assets/deck/` (`deck_meta.json` with per-file SHA-256, `en.json`, `spreads.json`, `crisis_resources.json`) and the Worker feeds in `worker/src/generated/`, built by `tools/content/build`. `apps/taro/lib/data/content/` adds `ContentManifest` (checksum check, `StorageFailure` on mismatch), `AssetDeckRepository`, `AssetSpreadRepository`, `AssetMeaningRepository` (per-locale parse in `Isolate.run`, cached), `AssetCrisisResourcesRepository` and `AssetContentRepository`, wired as the `ContentRepository` and `CrisisResourcesRepository` providers. `tools/content/placeholder_art` generates the 78 typographic placeholder cards and card back (lossless WebP, project-owned pixel font) into `assets/deck/art/placeholder/`. `tools/verify.sh` and `reusable-static.yml` run `validate`, `build --check`, `sync_check` and `placeholder_art --check`.
- Phase 5, content tooling: `tools/content/{validate,build,translate,sync_check}` (Dart in `tools/dart_tools`, JSON Schemas in `tools/content/schema/`). `validate` checks the deck source (bounds, glossary names, banned phrases, plain text, bidi, spreads, crisis directory) and reports missing or stale translations; `build` writes the deterministic app assets and Worker feeds; `translate` drafts machine translations with Claude; `sync_check` compares app assets with Worker feeds. `check_l10n.py` now requires the `en` deck and reports untranslated locales until Phase 18.
- Phase 4, core domain: `taro_core` with `Result`/`Failure` (27 subtypes), typed IDs and `ErrorKind`, the freezed domain models, the product catalogue and `ProductOffer`, and the pure logic (`CardDrawer`, `ReadingGate`, `ResetSchedule`, `ServerClockOffset`, backup validation, merge and JCS checksum, `BannerPolicy`, journal patterns, question precheck, daily card rules). Also 35 ports, 12 use cases and 74 typed analytics events (`docs/ANALYTICS_EVENTS.md`).
- Phase 4, test kit: a fake for every port and fluent builders in `packages/taro_core/test/fakes/`, and a `run<Port>Contract` suite per port in `test/contracts/`.
- Phase 4: the `failure*` and `safetyDeclined*` messages (GLOSSARY §5, §5.2) in all 12 locales, and `melos run gen:build` (build_runner).

- Phase 3: golden harness in `packages/taro_ui/test/helpers/golden/`. It has `TaroGoldenComparator` (0.1 %), bundled Noto Sans, Arabic, JP and KR test fonts (OFL), the golden sizes and `goldenMatrix`, and a sample phone and iPad 13" golden. `pumpTaroWidget` now takes locale, theme mode, text scale and size.
- Phase 3: `tools/verify.sh [--fast]`, the git hooks (`melos run hooks:install`), `golden:update` guarded to the reference platform, and `contract:sync`. Also `test:integration`, `tools/bump_version.sh`, `tools/bump_worker_version.sh`, `tools/phase_state.py`, `sonar-project.properties` and `docs/TESTING.md`.
- Phase 2, repository bootstrap: a pub workspace with melos 8 and shared `analysis_options.yaml` (very_good_analysis, strict modes). Compiling skeletons of `taro_core`, `taro_content`, `taro_data`, `taro_services`, `taro_attestation`, `taro_l10n`, `taro_ui` and `taro_testing`, each with a smoke test.
- Phase 2: `apps/taro` with `dev`, `staging` and `prod` flavors, `config/<flavor>.json` and a placeholder screen.
- Phase 2: `tools/` Python project (Python 3.12, pytest, pytest-cov, ruamel.yaml, jsonschema) with the `taro_tools` helper package, and the `tools/dart_tools` Dart package.
- Phase 2: `README.md`, `CLAUDE.md`, this changelog, `.gitignore`, the `docs/ARCHITECTURE.md` stub and empty `docs/runbooks/`.
- Phase 14, Claude Design handoff: the approved design system and `docs/design/taro.tokens.json` (DTCG, light and dark), screen designs S01–S33 with ★ state, RTL, iPad and 200 % text variants, card back and app icon masters, and the design review.
- Phase 1, spec reconciliation: `docs/specs/00_DECISIONS.md` (RC1–RC94), `docs/specs/GLOSSARY.md`, specs 01–06 at v1.1 with no conflicts, and the owner decisions (model, hosts, prices, territories, universal form factor, Play account type, support mailbox).
- The project context, v1 specs and the 23-phase implementation plan.

### Fixed

- `check_coverage.py` no longer reports Dart files holding only interfaces, plain enums or freezed declarations as missing (QA4). `check_glossary.py` reads enhanced `RefusalCategory` enums.
