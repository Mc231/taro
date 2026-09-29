# Phase 20: Store Listings, ASO & Screenshots

**Status:** ⬜ Not Started
**Depends on:** Phase 9 (asa gaps), Phase 10 (store records), Phase 18 (final art + locales), Phase 19 (legal URLs, privacy answers)

---

## Overview

This phase completes the store footprint from the single source of truth `apps/taro/store/aso.yaml` (CS9):
- 12-locale names, subtitles, keywords, descriptions and promo text, built with the Blocks method;
- IAP localizations;
- age rating via `asa` (13+);
- review information and notes;
- territory availability;
- Play listings;
- the manual console forms (App Privacy, Data Safety, IARC, target audience);
- automated screenshots captured from the real app in all 12 locales.

Nothing is submitted for review yet; that happens in Phase 22.

**Output of this phase:**
- `apps/taro/store/aso.yaml` complete (05 §8.1 structure, RC3 product IDs, RC36 Firebase project, iPhone + iPad screenshot sets per RC24). `asa validate` and `check_store_copy.py` are green.
- `docs/aso/{keywords.md, screenshots.md, promo-text.md, ASO_TRACKER.md}` in the Blocks format.
- `apps/taro/integration_test/screenshots/` driver + `test/fixtures/store_readings/{locale}.json` + `build/screenshots/{ios,android}/{locale}/` (not committed; uploaded).
- Every store console field filled in both stores (manual steps M6 and M8 done), and IAPs "Ready to Submit" with review screenshots.

---

## Specs referenced

`05_COMPLIANCE_STORE_ASO.md` CS1–CS5, CS9, CS11–CS13, CS16, CS17, §5.1–§5.2 (entered in the consoles), §6, §7, §8.1, §8.3 (M5, M6, M8, M10), §8.4, §9.1–§9.6. `04_MONETIZATION.md` §4 (store metadata strings), MO17, MO18. `01_PRODUCT.md` §4.1 (differentiation), §6.1 (every advertised feature ships). `06_QUALITY_TESTING_CI.md` §6.2 (`check_store_copy.py`, `check_l10n.py` store limits), §12 Store checklist. `00_DECISIONS.md` RC3, RC23, RC24.

---

## Sprint 20.1: `aso.yaml` & copy

**Tasks:**
- [ ] Complete `apps/taro/store/aso.yaml`, starting from 05 §8.1 with the reconciled values:
  - IAP IDs `readings_3/10/30` + `remove_ads` (RC3), with display names "3 Readings", "10 Readings", "30 Readings" and "Remove Banner Ads" (RC80, ≤ 30 chars per locale) and the 04 §4 descriptions in all 12 locales; the EN description keeps the free daily card (no AI) separate from "one free AI reading every day" (05 §8.1, RC64);
  - `age_rating` from 05 §6.1 with `override: THIRTEEN_PLUS`;
  - `capabilities: [IN_APP_PURCHASE, APP_ATTEST]`;
  - `availability.excluded_territories` (CS16 fixed list + the union of the supported-countries snapshots of every routable AI provider, v1 Anthropic and OpenAI; RC97);
  - `firebase.project_id: taro-prod` (RC36);
  - `admob:` real IDs;
  - `terms_url`;
  - the review notes from 05 §7, updated with the RC20 Classic reading and the RC3 pack sizes; every quoted button label matches `app_en.arb` (`review_notes_labels_exist`, RC79).
- [ ] Localizations ×12 from the 05 §9.3 table (name, subtitle, keywords), plus promo text and the description (05 §8.1 EN). Every feature paragraph must match a shipped v1 feature (01 §6.1). The conditional keywords `love` and `yes,no` are **kept only if** matching spreads ship (`relationship` ships; there is no yes/no spread in v1, so `yes,no` and its translations are replaced from the rotation pool). The disclaimer sentence from `required_sentences.yaml` sits in the first 3 lines of each description.
- [ ] Play variants: `google_play.localizations` (title, short, full) ×12, with no Apple or iOS mentions.
- [ ] `store/whats_new/{locale}.txt` for 1.0.0.
- [ ] `check_store_copy.py`, `check_pack_sizes.py`, `check_iap_ids.py`, `check_l10n.py` (store limits) and `asa validate` are green. A native speaker reviews the store copy for each locale *(MANUAL)*.
- [ ] `docs/aso/keywords.md` (table + rationale per locale), `promo-text.md`, and `ASO_TRACKER.md` with the dated initial row.

---

## Sprint 20.2: Screenshots (CS13, 05 §9.4)

**Tasks:**
- [ ] `apps/taro/integration_test/screenshots/screenshots_test.dart` drives the real app with fake ports: a fixed seed draw, a fixed AI reading per locale from `test/fixtures/store_readings/{locale}.json` (taken from real staging outputs and reviewed), Remove Ads owned (no banners), and the light theme for frames 1–3. It produces the 7 frames from 05 §9.4 in order.
- [ ] Forbidden-content check (automated where possible): no ads, prices, paywall or countdowns; no Death, Devil or Tower in frames 1–3 (assert on the card IDs in the fixture draw).
- [ ] Sizes: iPhone 6.9" 1320×2868, iPad 13" 2064×2752 (universal, RC24), Play phone ≥ 1080×1920, Play 7" and 10" tablet sets (Android tablets supported, RC24; 05 §9.4), and the Play feature graphic 1024×500 (from the design template).
- [ ] Captions from `store_screenshots.translations` (12 locales, lint-checked). Frame composition uses the Phase 14 template; port quiz_apps `take_screenshots.sh` / `upload_store_assets.sh` as `tools/screenshots/*.sh` with a pytest wrapper, or use `asa ios upload-screenshots` directly.
- [ ] `docs/aso/screenshots.md`: the frame list, captions and source fixtures.

---

## Sprint 20.3: Push metadata (05 §8.4)

**Tasks:**
- [ ] `asa ios push-localizations -c apps/taro/store/aso.yaml`, `asa ios localize-all-iaps`, `asa ios update-review-info --platform ios` (CS11), `asa ios set-age-rating --from-config` (ASA-3), `asa ios upload-screenshots`, and territory availability (ASA-9).
- [ ] `asa android push-localizations -c …` (ASA-5), `asa android setup-iap` (per-locale product listings), `asa android upload-screenshots` (phone, and the 7" and 10" tablet types, RC24), `asa android upload-feature-graphic`.
- [ ] Re-read the ASC and Play listings after pushing, because ASC can hold stale text (06 §12) *(MANUAL)*.

---

## Sprint 20.4: Console forms *(MANUAL, M6, M8, M10)*

**Tasks:**
- [ ] App Store Connect:
  - App Privacy (05 §5.1, from `PRIVACY_LABELS.md`);
  - age-rating override 13+ if ASA-3 could not set it;
  - content rights ("no third-party content");
  - the license agreement = Apple standard EULA with the terms link in the description;
  - review contact (phone from `~/pet/secure/taro/review_contact`).
- [ ] IAPs: attach a review screenshot of the store screen to each product; status "Ready to Submit". They will be attached to the 1.0 version at submission (M10).
- [ ] Play Console (M6):
  - store settings (Lifestyle, contact email and website);
  - IARC questionnaire (05 §6.2, "All Other App Types", digital purchases yes);
  - target audience 13–15, 16–17 and 18+, "not designed for children";
  - ads declaration yes; app access (all features, no login; shortened review notes);
  - Data Safety (05 §5.2); health and financial declarations "none"; Advertising ID declaration.
- [ ] Record each step with its date in `docs/runbooks/STORE_SUBMISSION.md`.

---

## Done when

- [ ] `asa validate`, `check_store_copy.py`, `check_pack_sizes.py`, `check_iap_ids.py` and `check_urls.py` are green. Coverage of `tools` stays ≥ 90% with any new screenshot tooling.
- [ ] Both store listings are complete in 12 locales with screenshots. The IAPs are ready. Every console form is filled.
- [ ] Docs: `docs/aso/**`, STORE_SUBMISSION runbook, CHANGELOG.
- [ ] One commit: `feat(taro): Phase 20 — Store listings, ASO & screenshots`.

## Next phase

Phase 21: Beta & Release Candidate.
