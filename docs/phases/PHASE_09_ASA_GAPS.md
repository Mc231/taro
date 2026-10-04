# Phase 9: `asa` CLI Gap Fixes (app-store-automation)

**Status:** ✅ Complete (2026-10-03). The asa commits (`e1cf4f7`, fixes `480488b`, `7bce62f`, `0feca31`) are local in `~/pet/app-store-automation` and not pushed yet. ASC rejects the `APP_ATTEST` capability via the API, so App Attest is ticked by hand in the developer portal (asa `0feca31`, README).
**Depends on:** Phase 1 (CS decisions confirmed)
**Parallel with:** Phases 2–8. It must be done **before** Phase 10 Sprint 10.3, which bootstraps App Store Connect with `asa`.
**Repo:** `/Users/volodymyrshyrochuk/pet/app-store-automation`. This is a separate repo with its own commit, following that repo's conventions. The taro reference repos stay read-only for spec work; this phase is the planned, explicit change to `asa`.

---

## Overview

`asa` was built for the quiz fleet. Used as-is for Taro it would:
- file a **false age-rating declaration** (`advertising: false` is hard-coded);
- create a Game Center capability;
- fall back to the Games/Trivia category;
- push English-only IAP text;
- publish a privacy page that says "suitable for all ages" and omits AI and server processing.

This phase fixes ASA-1 to ASA-10 from 05 §8.2, with tests, and keeps the quiz apps' behaviour unchanged by default.

**Output of this phase:**
- `asa` release with ASA-1 to ASA-7, ASA-9 and ASA-10 implemented and tested. ASA-8 (iOS subscriptions) is logged as backlog.
- `asa validate -c apps/taro/store/aso.yaml` passes for Taro's draft yaml, and taro CI can call it.
- A regression run shows the quiz-app configs are unaffected (`asa validate` + dry-runs on 2 quiz configs).

---

## Specs referenced

`05_COMPLIANCE_STORE_ASO.md` CS1, CS4, CS9, CS10, CS16, §6.1, §8.1, §8.2 (ASA-1 to ASA-10), §8.4. `00_DECISIONS.md` RC92. `../CONTEXT.md` §5 (asa gaps). `06_QUALITY_TESTING_CI.md` §6.2 (store field limits).

---

## Sprint 9.1: Config model & validation (ASA-6)

**Tasks:**
- [x] `src/app_automation/models/app_config.py`: extend `AppConfig` with `app_review_information`, `localizations` (per-locale name, subtitle, keywords, promotional_text, description, whats_new), `age_rating`, `app_store.capabilities`, `app_store.secondary_category`, `app_store.availability.excluded_territories`, `terms_url`, `iap_products[].localizations`, and `google_play.localizations`. Existing fields keep their defaults. _Evidence: asa `models/app_config.py` (`AppReviewInformation`, `LocaleListing`, `AgeRating`, `Capability`, `Availability`, `WebConfig`, `IAPLocalization`, `PlayListingLocalization`)._
- [x] Add a `asa validate -c <yaml>` command in `src/app_automation/cli.py` / `commands/ios.py`. It enforces the 05 §8.1 localization rules: name/subtitle ≤ 30, keywords ≤ 100 with no spaces and no duplicates of the name/subtitle, promo ≤ 170, description ≤ 4000, Play short ≤ 80, review notes ≤ 4000, IAP name ≤ 30 and description ≤ 45, and all 12 locales present when `localizations` is declared. It exits non-zero with a table of failures. _Evidence: asa `validation.py`, `cli.py` `validate` (`--locales`, `--no-aso-rules`)._
- [x] Tests: `tests/test_models.py` gets new fields plus a backward-compatibility load of an existing quiz config. `tests/test_cli.py` checks `validate` pass and fail cases (an over-length subtitle, spaces in keywords). _Evidence: asa `tests/test_models.py::TestStoreExtensions`, `tests/test_cli.py::TestValidateCommand`, `tests/test_validation.py`, fixture `tests/fixtures/taro_aso.yaml`._

---

## Sprint 9.2: Category, capabilities, age rating (ASA-1, ASA-2, ASA-3)

**Tasks:**
- [x] **ASA-1:** add `LIFESTYLE`, `REFERENCE` and `HEALTH_AND_FITNESS` to `AppCategory`. `bootstrap-app` fails loudly on an unknown category instead of silently using `GAMES_TRIVIA`. `secondary_category` is passed to `set_app_info` (`clients/app_store_connect.py`). Tests cover the unknown category → error, and a request body that contains Lifestyle + Entertainment. Evidence: `src/app_automation/store_settings.py` (`resolve_categories`), `clients/app_store_connect.py` (`set_app_info(secondary_category=)`), `tests/test_store_settings.py::TestCategories`, `TestBootstrapApp::test_unknown_category_fails_before_any_api_call`, `::test_taro_config`.
- [x] **ASA-2:** read `app_store.capabilities` in `bootstrap-app` and `create-bundle-id`. The default stays `[GAME_CENTER, IN_APP_PURCHASE]` for quiz apps. Add `APP_ATTEST`. Never call `enable_game_center` when `GAME_CENTER` is absent. Tests assert the capability calls for the taro-like and quiz-like configs. Evidence: `store_settings.resolve_capabilities`, `commands/ios.py` (`bootstrap-app`, `create-bundle-id --config`), `cli.py` `setup`; `tests/test_store_settings.py::TestCapabilities`, `TestBootstrapApp::test_taro_config` / `::test_quiz_config_keeps_default_capabilities`, `TestCreateBundleId`.
- [x] **ASA-3:** `set-age-rating --from-config` maps every `age_rating` field, including `advertising` (no longer hard-coded `false`), and the override (`ageRatingOverrideV2 = THIRTEEN_PLUS` if the API exposes it; otherwise print the manual step M8). Keep the `quiz-game` preset and add a `tarot` preset equal to 05 §6.1. `--dry-run` prints the PATCH body. Tests snapshot the PATCH body for the `tarot` preset and the from-config path. Evidence: `store_settings.age_rating_attributes` + `AGE_RATING_PRESETS`, `client.set_age_rating_attributes` (override retry → M8), `set-age-rating --from-config/--preset tarot/--dry-run`; `tests/test_store_settings.py::TestAgeRatingMapping::test_tarot_preset_snapshot`, `TestSetAgeRatingCommand::test_dry_run_from_config_prints_body`, `TestAgeRatingClient`.

---

## Sprint 9.3: Localized IAPs & Play listings (ASA-4, ASA-5)

**Tasks:**
- [x] **ASA-4:** `localize-all-iaps` pushes each `iap_products[].localizations[locale]` (name + description) for all 12 locales, mapping `pt` → `pt-BR` and `ar` → `ar-SA` per the existing asa locale map. Tests use a mocked ASC client and assert 12 localization calls per product. Evidence: `app-store-automation/tests/test_store_localizations.py::test_localize_all_iaps_pushes_12_locales_per_product`, `::test_localize_all_iaps_quiz_config_unchanged`; map in `src/app_automation/locales.py`.
- [x] **ASA-5:** `asa android push-localizations -c`: per-locale Play listing (title, short, full) from `google_play.localizations`. `setup-iap` creates per-locale product listings. Tests use a mocked `clients/google_play.py` edits session and assert that the edit is committed once. Evidence: `app-store-automation/tests/test_store_localizations.py::test_push_localizations_pushes_12_listings_in_one_commit`, `::test_setup_iap_sends_localized_listings`, `::test_batch_create_one_time_products_payload_has_12_listings`.
- [x] Document the known Android IAP price bug (the price is not set via API) in the README "Known issues", with the manual step. It stays manual (Phase 10.4). Evidence: `app-store-automation/README.md` "Known issues".

---

## Sprint 9.4: Web pages, `.well-known` & territories (ASA-7, ASA-9, ASA-10)

**Tasks:**
- [x] **ASA-7:** `asa web generate` supports app-supplied content: `web/privacy.{locale}.md`, `web/terms.{locale}.md`, `web/support.{locale}.md`, `web/index.{locale}.md` for 12 locales via `?hl=`, each with a version and effective date. The built-in template is used only when no custom files exist. The "suitable for all ages" and Game Center wording is removed from the default template, or made conditional on config (`web/generator.py`). Tests render the taro fixture pages and check there are no forbidden phrases. Evidence: asa `web/custom_content.py`, `web/generator.py` (`game_center`/`all_ages`/`content_dir`), `asa web generate --content-dir` / `web.content_dir`; `tests/test_web_custom_content.py` (`test_renders_taro_pages_per_locale`, `test_no_forbidden_phrases_in_taro_site`, `test_quiz_default_template_unchanged`).
- [x] **ASA-10** (RC92): `asa web deploy` serves `web/.well-known/apple-app-site-association` (no extension) and `web/.well-known/assetlinks.json` verbatim with `Content-Type: application/json` and no redirect. Test: a deployed-fixture check (or a hosting-config unit test) asserts path, status and content type. If the hosting cannot set headers, record the fallback: a Worker route `taro.vshyrochuk.com/.well-known/*` with vitest tests. Evidence: Firebase Hosting `firebase.json` headers + `verify_hosting` preflight in `asa web deploy`, `asa web check-well-known`; `test_well_known_copied_verbatim_and_served_as_json`, `test_verify_hosting_reports_problems`, `test_check_live_well_known`. No Worker fallback needed.
- [x] **ASA-9:** apply `availability.excluded_territories` to the **app** (not only IAPs) via the ASC availability API. If the endpoint is unavailable, print the manual step and exit 0 with a warning. Tests use a mocked client. Evidence: `clients/app_availability.py`, `asa ios set-app-availability -c`; `tests/test_app_availability.py` (`test_cli_api_unavailable_prints_manual_step_and_exits_0`).
- [x] **ASA-8:** add a README backlog entry for iOS subscriptions (wrong endpoint, no group creation). No code, since Taro v1 has no subscriptions (CS5, MO3). Evidence: asa README §Backlog.

---

## Sprint 9.5: Release & regression

**Tasks:**
- [x] Run the full `asa` test suite. Run `asa validate` on two quiz configs (e.g. `configs/artquiz.yaml`) and on `apps/taro/store/aso.yaml` (the draft from 05 §8.1, copied into taro in Phase 20; use a fixture until then). _Evidence (2026-10-03): asa `.venv/bin/pytest --cov` 140 passed, 6 failed — the 6 are the stale `tests/test_cli.py::TestCLI::test_assets_*` (commands `assets prompts/app-icon/achievements/leaderboards/feature-graphic` no longer exist) and fail identically on a clean `git archive HEAD`; total coverage 12 % → 29 %; new modules `validation.py`, `store_settings.py`, `locales.py`, `web/custom_content.py`, `clients/app_availability.py`, `models/app_config.py` 100 %; ruff check clean and ruff format applied on the new modules. `asa validate --no-aso-rules`: `capitalquiz.yaml` passes; `artquiz.yaml` (8 keyword fields 104–131 > 100, 2 IAP descriptions > 45) and `flagsquiz.yaml` (es/pt keywords 114/118) report real pre-existing over-limit data, left for the owner. `apps/taro/store/aso.yaml` created now (not a fixture) and passes `asa validate` (ASO rules on) plus `check_store_copy.py`, `check_pack_sizes.py`, `check_iap_ids.py`, `check_l10n.py`, `check_urls.py --offline`._
- [x] Update `app-store-automation/README.md`: new commands, the `tarot` preset, capabilities, validate, and web custom content. _Evidence: README Features, "Validate a config", iOS (`create-bundle-id --config` + capability list, fixed `-c` example, `set-age-rating` presets / `--from-config` / `--dry-run`, `localize-all-iaps`, `set-app-availability`), Android (`push-localizations`, `setup-iap`), "Landing pages (web)", optional store blocks in "Configuration File Format", "Known issues", "Backlog"._
- [x] Commit in the asa repo: `feat(asa): taro support — lifestyle category, capabilities, age rating, localized IAPs/listings, validate, custom web pages, territories`. _Evidence: asa `e1cf4f7`; follow-ups found in Phase 10: `480488b` (sanitize bundle ID names; APP_ATTEST is entitlement-only), `7bce62f` (bundle ID lookup exact match), `0feca31` (docs: APP_ATTEST must be ticked in the developer portal). Local only, not pushed._
- [x] Add `asa validate` to taro's `reusable-static.yml` for PRs that touch `apps/taro/store/**` (via the path to the installed asa venv on the runner). _Evidence: `.gitea/workflows/reusable-static.yml` step "asa validate (apps/taro/store/aso.yaml)" (runs when the pushed range touches `apps/taro/store/**`; `vars.ASA_BIN`, default `~/pet/app-store-automation/.venv/bin/asa`; warning + skip when absent); `tools/verify.sh` `asa_validate` (`TARO_ASA`); `tools/tests/test_verify.py::test_asa_validate_runs_on_the_store_yaml`, `::test_asa_validate_is_skipped_without_yaml_or_cli`._

---

## Done when

- [x] ASA-1 to ASA-7, ASA-9 and ASA-10 pass their acceptance criteria (05 §8.2). The asa test suite is green, with coverage at or above the repo's existing level; new modules ≥ 90%. _Evidence: unit level, mocked clients (Sprints 9.1–9.4); every new test passes, the only failures are the 6 pre-existing `test_assets_*`; coverage 12 % → 29 %, new modules 100 %. The live-store halves of the criteria (ASC shows 13+, 12 Play listings, `curl -I` on `.well-known`) are checked when the commands run in Phases 10 and 20._
- [x] Quiz configs are unaffected (dry-run diffs are empty). _Evidence: `asa web generate` for `capitalquiz.yaml` and `flagsquiz.yaml` is byte-identical between HEAD (`git archive`) and the working tree (`diff -r` empty); `asa ios set-age-rating --preset quiz-game --dry-run` prints the old hard-coded body (`test_store_settings.py` asserts it); `test_quiz_config_keeps_default_capabilities`, `test_localize_all_iaps_quiz_config_unchanged`, `test_quiz_default_template_unchanged`; `set-app-availability` on a quiz config: "No availability block in config; nothing to do". Intended differences: `bootstrap-app` now also sends the category (GAMES / GAMES_TRIVIA), and `localize-all-iaps` exits non-zero when a push fails._
- [x] Docs: asa README, plus the command sequence in 05 §8.4 confirmed and copied into `docs/runbooks/STORE_SUBMISSION.md` in taro. _Evidence: `docs/runbooks/STORE_SUBMISSION.md` "asa command sequence (05 §8.4)" (every option checked against the asa CLI; `create-iap` is per product, `set-age-rating` needs `-b` unless `--dry-run`, Play IAP prices stay manual)._
- [x] One commit in each repo: asa (feature) and taro `ci(taro): Phase 9 — asa gap fixes integrated`. _Evidence: asa `e1cf4f7` (+ fixes `480488b`, `7bce62f`, `0feca31`, local, not pushed); taro `242d281`._

## Next phase

Phase 10: Accounts, Store Registration & Signing.
