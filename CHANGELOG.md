# Changelog

All notable changes to the Taro app (`apps/taro`) and its packages (`packages/*`) are documented in this file. Worker changes are in [worker/CHANGELOG.md](worker/CHANGELOG.md).

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html). App versions are `X.Y.Z+B`; the build number `B` is monotonic across both stores (06 §10.1).

## [Unreleased]

### Added

- Phase 3: golden harness in `packages/taro_ui/test/helpers/golden/`. It has `TaroGoldenComparator` (0.1 %), bundled Noto Sans, Arabic, JP and KR test fonts (OFL), the golden sizes and `goldenMatrix`, and a sample phone and iPad 13" golden. `pumpTaroWidget` now takes locale, theme mode, text scale and size.
- Phase 3: `tools/verify.sh [--fast]`, the git hooks (`melos run hooks:install`), `golden:update` guarded to the reference platform, and `contract:sync`. Also `test:integration`, `tools/bump_version.sh`, `tools/bump_worker_version.sh`, `tools/phase_state.py`, `sonar-project.properties` and `docs/TESTING.md`.
- Phase 2, repository bootstrap: a pub workspace with melos 8 and shared `analysis_options.yaml` (very_good_analysis, strict modes). Compiling skeletons of `taro_core`, `taro_content`, `taro_data`, `taro_services`, `taro_attestation`, `taro_l10n`, `taro_ui` and `taro_testing`, each with a smoke test.
- Phase 2: `apps/taro` with `dev`, `staging` and `prod` flavors, `config/<flavor>.json` and a placeholder screen.
- Phase 2: `tools/` Python project (Python 3.12, pytest, pytest-cov, ruamel.yaml, jsonschema) with the `taro_tools` helper package, and the `tools/dart_tools` Dart package.
- Phase 2: `README.md`, `CLAUDE.md`, this changelog, `.gitignore`, the `docs/ARCHITECTURE.md` stub and empty `docs/runbooks/`.
- Phase 14, Claude Design handoff: the approved design system and `docs/design/taro.tokens.json` (DTCG, light and dark), screen designs S01–S33 with ★ state, RTL, iPad and 200 % text variants, card back and app icon masters, and the design review.
- Phase 1, spec reconciliation: `docs/specs/00_DECISIONS.md` (RC1–RC94), `docs/specs/GLOSSARY.md`, specs 01–06 at v1.1 with no conflicts, and the owner decisions (model, hosts, prices, territories, universal form factor, Play account type, support mailbox).
- The project context, v1 specs and the 23-phase implementation plan.
