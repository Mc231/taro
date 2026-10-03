# Phase 19: Compliance, Privacy, Accessibility & Performance Hardening

**Status:** 🟡 In progress — automated hardening done; live drills, legal pages, device passes pending
**Depends on:** Phases 16, 17, 18, 8
**Parallel with:** Phase 20 Sprints 20.1–20.2

---

## Overview

This phase is a systematic pass over every Apple and Google guideline row in 05 §1 and §2, turning each "Verify" column into a checked test or a recorded manual check. It also delivers:
- the privacy artefacts (`PrivacyInfo.xcprivacy`, privacy labels, Data Safety answers, privacy policy and terms content);
- the legal pages and deep-link verification files;
- an accessibility audit;
- the performance budgets;
- a security review.

The goal is a build a reviewer cannot fault on 1.1.6, 1.4.1, 2.1, 3.1.1, 4.3(b), 5.1.1 or 5.1.2(i), or on Play's Payments, Ads, AI-content and Data Safety policies.

**Output of this phase:**
- `docs/compliance/APPLE_MATRIX.md` and `PLAY_MATRIX.md`: 05 §1 and §2 with an evidence column (test name or manual check + date) for every row.
- `apps/taro/ios/Runner/PrivacyInfo.xcprivacy`, localized `NSUserTrackingUsageDescription` ×12, and the SKAdNetwork list verified.
- `web/privacy.{locale}.md`, `web/terms.{locale}.md`, `web/support.{locale}.md` ×12 (content from 05 §5.3–§5.4 and §9.6), deployed with `asa web` (ASA-7), plus `.well-known/apple-app-site-association` and `assetlinks.json` hosted on `taro.vshyrochuk.com`.
- `docs/compliance/PRIVACY_LABELS.md`: the App Store label (05 §5.1) and Play Data Safety (05 §5.2), diffed against the actual SDK behaviour.
- Performance and accessibility reports committed under `docs/compliance/`.

---

## Specs referenced

`05_COMPLIANCE_STORE_ASO.md` CS3–CS8, CS10, CS13–CS16, §1, §2, §3, §4, §5, §6.1–§6.3 (verification), §9.6, Testing strategy, Risks. `01_PRODUCT.md` PR1, PR2, PR12–PR14, PR18, §12, §16. `02_ARCHITECTURE.md` §8.2, §13, §16, §17. `03_BACKEND_WORKER.md` §13 (data inventory), BE13. `04_MONETIZATION.md` MO11, MO12, MO13, §10, §11. `06_QUALITY_TESTING_CI.md` §3.2, §12. `00_DECISIONS.md` RC19–RC23, RC29, RC37, RC53, RC63, RC68, RC69, RC79, RC84, RC86, RC92, RC93.

---

## Sprint 19.1: Guideline matrices with evidence

**Tasks:**
- [x] Copy 05 §1 and §2 into `docs/compliance/APPLE_MATRIX.md` and `PLAY_MATRIX.md`, adding an **Evidence** column. For every row, link the automated test (e.g. `apps/taro/test/widget/reading/disclaimer_footer_every_state_test.dart`, the `worker/test/integration/readings.consent.test.ts` 412 case, the `reading.no_banner` layout test, the "Apple sandbox fallback" Worker test) or record a manual check with date and build number. *(`docs/compliance/APPLE_MATRIX.md`, `PLAY_MATRIX.md`: spec columns verbatim + Evidence column on every row, technical declarations, manual-check log; store-console rows marked Phase 20/21/22; safety-suite eval rows (1.1.6, 1.4.1) marked **open** (paid eval deferred by the owner))*
- [x] Add the missing tests found while filling the matrices. Expected additions: *(1.1.6: rule `certainty_phrase` in `tools/store_copy/check_store_copy.py` (Worker certainty lexicon over ARB + deck source; exemptions `tools/store_copy/certainty_exemptions.yaml`), fixtures `fail_certainty_{arb,ja,content}`, `fail_malformed_certainty`; 3.2.2 + 5.1.1(iv) UMP denied + 5.1.2(i): `apps/taro/integration_test/flows/review_guidelines_test.dart` (AI declined / ATT denied stay in `consent_denied_test.dart`); 2.3.10 and 2.1 `review_notes_labels_exist` already in `check_store_copy.py`; extra: `disclaimer_every_state_test.dart` (every S09/S32 state), rule `no_subscriptions` (3.1.2, fixture `fail_subscription`))*
  - a 1.1.6 test that no ARB string or deck text contains certainty phrases (via `check_store_copy.py` over ARB and content);
  - a 3.2.2 test that the free reading path never shows an ad;
  - a 5.1.1(iv) integration test for each decline path (AI → Classic reading; ATT denied; UMP denied);
  - a 5.1.2(i) integration test that no `POST /v1/readings` request leaves the device before consent (fake Worker request log);
  - a 2.3.10 test (via `check_store_copy.py`) that no Apple copy mentions Android;
  - a 2.1 test (via `check_store_copy.py` rule `review_notes_labels_exist`) that every button label quoted in the review notes exists in `app_en.arb` (RC79).
- [x] Differentiation evidence (4.3(b), PR2): `docs/compliance/DIFFERENTIATION.md` maps each item in 01 §4.1 to the shipped screen and a screenshot. It feeds the review notes in Phase 20. *(`docs/compliance/DIFFERENTIATION.md`: 8 rows of 01 §4.1 → screen → golden PNG (stand-in for store screenshots until Phase 20) → test)*

---

## Sprint 19.2: Privacy artefacts (5.1.1, 5.1.2, Play Data Safety)

**Tasks:**
- [ ] `PrivacyInfo.xcprivacy` (05 §1 technical declarations): `NSPrivacyTracking = true`, tracking domains inherited from the Google Mobile Ads SDK manifest, `NSPrivacyCollectedDataTypes` mirroring 05 §5.1, and required-reason APIs as used. Verify the Xcode privacy report of the archive against the manifest *(MANUAL, archive in Xcode Organizer)*; attach the report to the phase notes. *(2026-10-02: `apps/taro/ios/Runner/PrivacyInfo.xcprivacy` written (tracking true, 9 data types per 05 §5.1, `CA92.1`, `C617.1`), in Runner resources, checked by `tools/check_manifests.py`. **Open (MANUAL):** Xcode privacy report of the release archive)*
- [x] `NSUserTrackingUsageDescription` in 12 `InfoPlist.strings` (native-reviewed in Phase 18.2). The Android `AD_ID` permission is present (05 §2 Ads). *(12 × `apps/taro/ios/Runner/<locale>.lproj/InfoPlist.strings` (new `en.lproj`), text = ARB; `AD_ID` + `POST_NOTIFICATIONS` confirmed in the merged prod release manifest (`./gradlew :app:processProdReleaseMainManifest`), enforced by `check_manifests.py`)*
- [x] **Manifest checks** (automated, in `tools/check_manifests.py` over the release `Info.plist` and the merged `AndroidManifest.xml`): the four `GOOGLE_ANALYTICS_DEFAULT_ALLOW_*` / `google_analytics_default_allow_*` defaults are `false` (RC68); no `SCHEDULE_EXACT_ALARM` / `USE_EXACT_ALARM`; `POST_NOTIFICATIONS` declared but requested only from the reminder offer; the boot-completed reschedule receiver is present; `data_extraction_rules.xml` excludes the secure-storage prefs and `taro_device.db` (RC75); `SKIncludeConsumableInAppPurchaseHistory = YES` (RC84). *(`tools/check_manifests.py` (+ notification-permission call sites, `--require-merged`); tests `tools/tests/test_check_manifests.py`, fixtures `tools/tests/fixtures/check_manifests/{pass,fail_ios,fail_android}`; green in `tools/verify.sh` 2026-10-02)*
- [ ] `docs/compliance/PRIVACY_LABELS.md`: final answers for the App Store label and Play Data Safety. Cross-check each row against: *(2026-10-02: written with the cross-checks; decision D1 (Other User Content linked = Yes?) and owner sign-off **pending (MANUAL)**)*
  - 03 §13 (the Worker data inventory, as amended by RC22 and RC37);
  - Firebase Analytics and Crashlytics (AR19);
  - AdMob;
  - the report flow storing text for 90 days (RC22).
  - Record the owner's sign-off.
- [ ] `docs/compliance/PROCESSORS.md`: for each AI provider in `ai.disclosedProviders` (v1 Anthropic and OpenAI, plus the moderation vendor if `ai.moderation.provider` is set; RC97), Cloudflare and Google (Firebase, AdMob, Play), record the commercial terms and DPA version, API data-retention days, the training policy and zero-data-retention eligibility, each with the source URL and the date checked. The `aiConsentBody` and privacy-policy claims (e.g. "These AI providers do not use this data to train their models", which must hold for every named provider) are derived from this file and signed off by the owner *(MANUAL)*. *(2026-10-02: OpenAI (readings + moderation; launch is OpenAI-only, Anthropic not a processor), Cloudflare, Firebase, AdMob, Apple, Google Play with URLs and dates; three OpenAI rows (DPA, Business Terms, enterprise privacy: HTTP 403) to verify by hand; owner sign-off and DPA execution **pending (MANUAL)**)*
- [ ] Privacy policy and terms content ×12 locales (05 §5.3, §5.4): EN written first, then translated and native-reviewed for the legal-sensitive sections *(MANUAL)*. Each carries a version and an effective date. The AI section names every AI provider in `ai.disclosedProviders` (v1 Anthropic and OpenAI, RC97); the legal basis for AI readings is contract (RC93); "not directed at children under 16". Retention periods are those of 03 §13 (question not stored, reading text until delivered ≤ 7 days, reports 90 days, logs 7 days; RC69), enforced by `tools/check_retention.py`. *(`web/{privacy,terms}.<locale>.md` ×12: EN v1.0 effective 2026-10-02 + 11 machine translations marked `translation: machine`; `check_retention.py` green. **Pending:** `[OWNER: …]` placeholders, native legal review (MANUAL))*
- [ ] `asa web generate -c apps/taro/store/aso.yaml && asa web deploy` → `taro.vshyrochuk.com/{,privacy,terms,support}` in 12 locales. Host `/.well-known/apple-app-site-association` (app ID + `/app/*` paths) and `/.well-known/assetlinks.json` (the Play App Signing SHA-256) via ASA-10 (or the Worker-route fallback, RC92); `curl -I` shows 200 and `application/json`. Verify the Universal Links and App Links on devices *(MANUAL)*. *(`web/.well-known/apple-app-site-association` (`/app/*`, team M3FHKUJ7Z3) and `assetlinks.json` (SHA-256 placeholder) prepared; generate/deploy blocked on ASA-7/ASA-10; device link checks MANUAL)*
- [ ] Configure `legal.termsUrl`, `legal.privacyUrl` and `support.email` in the Worker config, and the flavor config URLs. `tools/check_urls.py` is green (online mode). *(keys and flavor URLs already set in `worker/config/remote_config.default.json` and `apps/taro/config/*.json`; offline `check_urls.py` green; online mode waits for the live pages)*
- [x] Territory availability (CS16, RC29): set `ai.blockedCountries` in the prod config. Store availability is applied in Phase 20 via ASA-9. *(`ai.blockedCountries` set (70 codes) in `worker/config/remote_config.default.json`, the single config for every env; documented in `docs/compliance/PROCESSORS.md`. Owner may reopen the Anthropic-only countries together with Phase 20 store availability)*

---

## Sprint 19.3: AI safety & reviewer path (CS8, 1.4.1)

**Tasks:**
- [ ] Run `npm run eval:safety -- --env staging` with the **production** prompt version and model. It must pass the bars from Phase 8.6. Commit the report. *(paid evals deferred by the owner)*
- [ ] Reviewer-path dry run on a TestFlight build pointed at the staging Worker, following the draft review notes (05 §7) step by step. Include the three sample refusal prompts ("Am I pregnant?", "Should I buy Bitcoin?", "I want to hurt myself") in `en`, one RTL locale and one CJK locale *(MANUAL)*. *(draft notes `docs/compliance/REVIEW_NOTES.md` incl. refusal prompts en/ar/ja and the staging test-account plan; TestFlight run pending)*
- [ ] Report flow end to end: submit a report → the Worker stores it encrypted → `reading_reported` metric. Walk through the weekly triage in `AI_SAFETY.md` once. *(automated: `apps/taro/integration_test/flows/report_reading_test.dart` + `worker/test/integration/routes/readingReports.test.ts`; triage walk-through in `docs/runbooks/AI_SAFETY.md`. Live weekly triage run pending)*
- [x] Kill-switch drill on staging: `readings.enabled = false` → S31 `readingsPaused` + the Classic offer; the budget hard stop → no paywall is shown (RC47). *(automated: `apps/taro/integration_test/flows/kill_switch_test.dart` (3 cases); drill helper `tools/kill_switch_drill.py` (tests `tools/tests/test_kill_switch_drill.py`), drill log in `docs/runbooks/INCIDENT.md`. Live staging drill pending)* *(2026-10-02: both drills run and restored; log in `docs/runbooks/INCIDENT.md` §Drill log.)*

---

## Sprint 19.4: Accessibility & RTL audit (01 §12–§13)

**Tasks:**
- [ ] Manual VoiceOver (iOS) and TalkBack (Android) passes on every ★ screen, including the complete draw via "Draw for me" + "Reveal all". Findings → fixes + tests. Report in `docs/compliance/A11Y_AUDIT.md`. *(checklist + run log in `docs/compliance/A11Y_AUDIT.md` §4; device passes pending (MANUAL))*
- [x] Maximum Dynamic Type / font scale on S05, S07, S09, S10, S11 and S13: no clipping, and cards reflow above 1.5×. *(`apps/taro/test/a11y/max_text_scale_test.dart` (200 % and iOS AX5 ≈ 312 %, reflow above 1.5× with a 1.5× control); fixes in `journal_entry_tile.dart` and `taro_card_face.dart` with tests in `containers_test.dart` / `taro_card_test.dart`; `docs/compliance/A11Y_AUDIT.md` §5)*
- [x] Reduced motion on: every ritual animation becomes a ≤ 200 ms crossfade. *(`apps/taro/test/a11y/reduced_motion_test.dart` (shuffle, deal, flip, S13 reveal, S09 reveal, S12 ring settle ≤ 200 ms with no movement/rotation; motion-on controls))*
- [x] Arabic full walkthrough: mirroring, numerals, card names, and spread x-mirroring with card art never mirrored. Japanese reading without clipping. *(`apps/taro/test/a11y/rtl_cjk_walkthrough_test.dart` (ar: RTL, numerals, bundled card names, spread mirrored, art unmirrored; ja: bundled reading without clipping at 1.0× and 2.0×))*

---

## Sprint 19.5: Performance & security

**Tasks:**
- [ ] Performance (01 §16, 02 §17), measured on profile builds on mid-tier devices (Pixel 6a / iPhone 12) *(MANUAL device runs + automated timeline)*: *(`docs/compliance/PERF_REPORT.md`: simulator debug runs only (cold start first frame 661 ms; S08 raster p90 1.7 ms) — not budget evidence; profile runs on iPhone 12 / Pixel 6a pending (MANUAL))*
  - cold start to first frame ≤ 1.5 s and to interactive Home ≤ 2.0 s;
  - ritual animations p90 < 8 ms with no jank frames;
  - no DB queries on the UI isolate;
  - art decode sizes correct;
  - install size ≤ 60 MB (iOS) and ≤ 40 MB per ABI (Android).
  - Results go in `docs/compliance/PERF_REPORT.md`. Regressions are fixed before Phase 21.
- [ ] Reading latency from staging analytics: p50 ≤ 8 s and p95 ≤ 20 s for each spread size. If p95 > 20 s, revisit the model or effort config (BE10) or the length budgets. *(no samples yet; SQL over staging D1 `readings.latency_ms` in `PERF_REPORT.md`)* *(2026-10-02: single n=7, avg 12.3 s — above the 8 s p50 budget; see `docs/compliance/PERF_REPORT.md`. Open.)*
- [ ] Security review (the `/security-review` skill on the full diff since Phase 2, plus a manual review): *(`docs/compliance/SECURITY_REVIEW.md`: S1 request-size limit (`worker/src/http/middleware/requestSizeLimit.ts`), S2 `npm audit` overrides (0 advisories), S3 bounded backup import read — fixed with tests; `/security-review` over the full diff, re-registration and sandbox-cap spot checks and `pip-audit` pending)*
  - no secrets in the client (AR17); the Redactor covers every sensitive field;
  - install ID and tokens never appear in logs, analytics, crash keys, backups or ad requests (02 §16);
  - prod rejects the Worker debug bypass, and prod `wrangler.toml` has no test-only vars (`check_worker_env.py`, RC86);
  - there is no admin HTTP route; the credit-transfer script requires a valid `transferToken` (RC84);
  - re-registration of a known install ID without its secret fails (RC54); the install secret and device key never appear in logs, analytics or backups;
  - the CORS block works; webhook signature checks are in place;
  - `npm audit` and `dart pub outdated` are clean at high severity.
  - Findings → fixes with tests.

---

## Done when

- [ ] Every row in APPLE_MATRIX and PLAY_MATRIX has evidence. There are zero open rows except the store-console items that Phase 20 or 22 must do (M8, M10), which are marked explicitly.
- [x] Coverage ≥ 90% for every unit after the added tests. Goldens and integration flows are green. *(2026-10-02 `tools/verify.sh` (full) green: taro_core 100 %, taro_ui 99.97 %, taro_attestation 100 % (+ native iOS/Android 100 %), apps/taro 99.52 %, dart_tools 99.34 %, worker 99.67 %, tools 99.54 %; goldens 616 app + 194 taro_ui; integration flows 26 passed, 1 skipped (staging smoke) on the iPhone 16e simulator (iOS 26.2) via `tools/run_integration.sh`; `flutter build ios --simulator --flavor dev` green with `PrivacyInfo.xcprivacy` bundled)*
- [ ] The legal pages are live in 12 locales, and `check_urls.py` is green. Universal Links and App Links are verified on devices.
- [x] Docs: `docs/compliance/**`, the runbooks (`AI_SAFETY.md`, `INCIDENT.md` first full version with the kill switches), CHANGELOG. *(`docs/compliance/{APPLE_MATRIX,PLAY_MATRIX,DIFFERENTIATION,PRIVACY_LABELS,PROCESSORS,REVIEW_NOTES,A11Y_AUDIT,PERF_REPORT,SECURITY_REVIEW}.md`; `docs/runbooks/INCIDENT.md` (first full version, kill-switch table, drill log), `AI_SAFETY.md` triage walk-through; CHANGELOG lines in `CHANGELOG.md` and `worker/CHANGELOG.md`)*
- [ ] One commit: `feat(taro): Phase 19 — Compliance, accessibility & performance hardening`.

## Next phase

Phase 20: Store Listings, ASO & Screenshots.
