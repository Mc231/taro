# Phase 9: `asa` CLI Gap Fixes (app-store-automation)

**Status:** ⬜ Not Started
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
- [ ] `src/app_automation/models/app_config.py`: extend `AppConfig` with `app_review_information`, `localizations` (per-locale name, subtitle, keywords, promotional_text, description, whats_new), `age_rating`, `app_store.capabilities`, `app_store.secondary_category`, `app_store.availability.excluded_territories`, `terms_url`, `iap_products[].localizations`, and `google_play.localizations`. Existing fields keep their defaults.
- [ ] Add a `asa validate -c <yaml>` command in `src/app_automation/cli.py` / `commands/ios.py`. It enforces the 05 §8.1 localization rules: name/subtitle ≤ 30, keywords ≤ 100 with no spaces and no duplicates of the name/subtitle, promo ≤ 170, description ≤ 4000, Play short ≤ 80, review notes ≤ 4000, IAP name ≤ 30 and description ≤ 45, and all 12 locales present when `localizations` is declared. It exits non-zero with a table of failures.
- [ ] Tests: `tests/test_models.py` gets new fields plus a backward-compatibility load of an existing quiz config. `tests/test_cli.py` checks `validate` pass and fail cases (an over-length subtitle, spaces in keywords).

---

## Sprint 9.2: Category, capabilities, age rating (ASA-1, ASA-2, ASA-3)

**Tasks:**
- [ ] **ASA-1:** add `LIFESTYLE`, `REFERENCE` and `HEALTH_AND_FITNESS` to `AppCategory`. `bootstrap-app` fails loudly on an unknown category instead of silently using `GAMES_TRIVIA`. `secondary_category` is passed to `set_app_info` (`clients/app_store_connect.py`). Tests cover the unknown category → error, and a request body that contains Lifestyle + Entertainment.
- [ ] **ASA-2:** read `app_store.capabilities` in `bootstrap-app` and `create-bundle-id`. The default stays `[GAME_CENTER, IN_APP_PURCHASE]` for quiz apps. Add `APP_ATTEST`. Never call `enable_game_center` when `GAME_CENTER` is absent. Tests assert the capability calls for the taro-like and quiz-like configs.
- [ ] **ASA-3:** `set-age-rating --from-config` maps every `age_rating` field, including `advertising` (no longer hard-coded `false`), and the override (`ageRatingOverrideV2 = THIRTEEN_PLUS` if the API exposes it; otherwise print the manual step M8). Keep the `quiz-game` preset and add a `tarot` preset equal to 05 §6.1. `--dry-run` prints the PATCH body. Tests snapshot the PATCH body for the `tarot` preset and the from-config path.

---

## Sprint 9.3: Localized IAPs & Play listings (ASA-4, ASA-5)

**Tasks:**
- [ ] **ASA-4:** `localize-all-iaps` pushes each `iap_products[].localizations[locale]` (name + description) for all 12 locales, mapping `pt` → `pt-BR` and `ar` → `ar-SA` per the existing asa locale map. Tests use a mocked ASC client and assert 12 localization calls per product.
- [ ] **ASA-5:** `asa android push-localizations -c`: per-locale Play listing (title, short, full) from `google_play.localizations`. `setup-iap` creates per-locale product listings. Tests use a mocked `clients/google_play.py` edits session and assert that the edit is committed once.
- [ ] Document the known Android IAP price bug (the price is not set via API) in the README "Known issues", with the manual step. It stays manual (Phase 10.4).

---

## Sprint 9.4: Web pages, `.well-known` & territories (ASA-7, ASA-9, ASA-10)

**Tasks:**
- [ ] **ASA-7:** `asa web generate` supports app-supplied content: `web/privacy.{locale}.md`, `web/terms.{locale}.md`, `web/support.{locale}.md`, `web/index.{locale}.md` for 12 locales via `?hl=`, each with a version and effective date. The built-in template is used only when no custom files exist. The "suitable for all ages" and Game Center wording is removed from the default template, or made conditional on config (`web/generator.py`). Tests render the taro fixture pages and check there are no forbidden phrases.
- [ ] **ASA-10** (RC92): `asa web deploy` serves `web/.well-known/apple-app-site-association` (no extension) and `web/.well-known/assetlinks.json` verbatim with `Content-Type: application/json` and no redirect. Test: a deployed-fixture check (or a hosting-config unit test) asserts path, status and content type. If the hosting cannot set headers, record the fallback: a Worker route `taro.vshyrochuk.com/.well-known/*` with vitest tests.
- [ ] **ASA-9:** apply `availability.excluded_territories` to the **app** (not only IAPs) via the ASC availability API. If the endpoint is unavailable, print the manual step and exit 0 with a warning. Tests use a mocked client.
- [ ] **ASA-8:** add a README backlog entry for iOS subscriptions (wrong endpoint, no group creation). No code, since Taro v1 has no subscriptions (CS5, MO3).

---

## Sprint 9.5: Release & regression

**Tasks:**
- [ ] Run the full `asa` test suite. Run `asa validate` on two quiz configs (e.g. `configs/artquiz.yaml`) and on `apps/taro/store/aso.yaml` (the draft from 05 §8.1, copied into taro in Phase 20; use a fixture until then).
- [ ] Update `app-store-automation/README.md`: new commands, the `tarot` preset, capabilities, validate, and web custom content.
- [ ] Commit in the asa repo: `feat(asa): taro support — lifestyle category, capabilities, age rating, localized IAPs/listings, validate, custom web pages, territories`.
- [ ] Add `asa validate` to taro's `reusable-static.yml` for PRs that touch `apps/taro/store/**` (via the path to the installed asa venv on the runner).

---

## Done when

- [ ] ASA-1 to ASA-7, ASA-9 and ASA-10 pass their acceptance criteria (05 §8.2). The asa test suite is green, with coverage at or above the repo's existing level; new modules ≥ 90%.
- [ ] Quiz configs are unaffected (dry-run diffs are empty).
- [ ] Docs: asa README, plus the command sequence in 05 §8.4 confirmed and copied into `docs/runbooks/STORE_SUBMISSION.md` in taro.
- [ ] One commit in each repo: asa (feature) and taro `ci(taro): Phase 9 — asa gap fixes integrated`.

## Next phase

Phase 10: Accounts, Store Registration & Signing.
