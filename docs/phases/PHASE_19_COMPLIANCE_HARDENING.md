# Phase 19: Compliance, Privacy, Accessibility & Performance Hardening

**Status:** ⬜ Not Started
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
- [ ] Copy 05 §1 and §2 into `docs/compliance/APPLE_MATRIX.md` and `PLAY_MATRIX.md`, adding an **Evidence** column. For every row, link the automated test (e.g. `apps/taro/test/widget/reading/disclaimer_footer_every_state_test.dart`, the `worker/test/integration/readings.consent.test.ts` 412 case, the `reading.no_banner` layout test, the "Apple sandbox fallback" Worker test) or record a manual check with date and build number.
- [ ] Add the missing tests found while filling the matrices. Expected additions:
  - a 1.1.6 test that no ARB string or deck text contains certainty phrases (via `check_store_copy.py` over ARB and content);
  - a 3.2.2 test that the free reading path never shows an ad;
  - a 5.1.1(iv) integration test for each decline path (AI → Classic reading; ATT denied; UMP denied);
  - a 5.1.2(i) integration test that no `POST /v1/readings` request leaves the device before consent (fake Worker request log);
  - a 2.3.10 test (via `check_store_copy.py`) that no Apple copy mentions Android;
  - a 2.1 test (via `check_store_copy.py` rule `review_notes_labels_exist`) that every button label quoted in the review notes exists in `app_en.arb` (RC79).
- [ ] Differentiation evidence (4.3(b), PR2): `docs/compliance/DIFFERENTIATION.md` maps each item in 01 §4.1 to the shipped screen and a screenshot. It feeds the review notes in Phase 20.

---

## Sprint 19.2: Privacy artefacts (5.1.1, 5.1.2, Play Data Safety)

**Tasks:**
- [ ] `PrivacyInfo.xcprivacy` (05 §1 technical declarations): `NSPrivacyTracking = true`, tracking domains inherited from the Google Mobile Ads SDK manifest, `NSPrivacyCollectedDataTypes` mirroring 05 §5.1, and required-reason APIs as used. Verify the Xcode privacy report of the archive against the manifest *(MANUAL, archive in Xcode Organizer)*; attach the report to the phase notes.
- [ ] `NSUserTrackingUsageDescription` in 12 `InfoPlist.strings` (native-reviewed in Phase 18.2). The Android `AD_ID` permission is present (05 §2 Ads).
- [ ] **Manifest checks** (automated, in `tools/check_manifests.py` over the release `Info.plist` and the merged `AndroidManifest.xml`): the four `GOOGLE_ANALYTICS_DEFAULT_ALLOW_*` / `google_analytics_default_allow_*` defaults are `false` (RC68); no `SCHEDULE_EXACT_ALARM` / `USE_EXACT_ALARM`; `POST_NOTIFICATIONS` declared but requested only from the reminder offer; the boot-completed reschedule receiver is present; `data_extraction_rules.xml` excludes the secure-storage prefs and `taro_device.db` (RC75); `SKIncludeConsumableInAppPurchaseHistory = YES` (RC84).
- [ ] `docs/compliance/PRIVACY_LABELS.md`: final answers for the App Store label and Play Data Safety. Cross-check each row against:
  - 03 §13 (the Worker data inventory, as amended by RC22 and RC37);
  - Firebase Analytics and Crashlytics (AR19);
  - AdMob;
  - the report flow storing text for 90 days (RC22).
  - Record the owner's sign-off.
- [ ] `docs/compliance/PROCESSORS.md`: for each AI provider in `ai.disclosedProviders` (v1 Anthropic and OpenAI, plus the moderation vendor if `ai.moderation.provider` is set; RC97), Cloudflare and Google (Firebase, AdMob, Play), record the commercial terms and DPA version, API data-retention days, the training policy and zero-data-retention eligibility, each with the source URL and the date checked. The `aiConsentBody` and privacy-policy claims (e.g. "These AI providers do not use this data to train their models", which must hold for every named provider) are derived from this file and signed off by the owner *(MANUAL)*.
- [ ] Privacy policy and terms content ×12 locales (05 §5.3, §5.4): EN written first, then translated and native-reviewed for the legal-sensitive sections *(MANUAL)*. Each carries a version and an effective date. The AI section names every AI provider in `ai.disclosedProviders` (v1 Anthropic and OpenAI, RC97); the legal basis for AI readings is contract (RC93); "not directed at children under 16". Retention periods are those of 03 §13 (question not stored, reading text until delivered ≤ 7 days, reports 90 days, logs 7 days; RC69), enforced by `tools/check_retention.py`.
- [ ] `asa web generate -c apps/taro/store/aso.yaml && asa web deploy` → `taro.vshyrochuk.com/{,privacy,terms,support}` in 12 locales. Host `/.well-known/apple-app-site-association` (app ID + `/app/*` paths) and `/.well-known/assetlinks.json` (the Play App Signing SHA-256) via ASA-10 (or the Worker-route fallback, RC92); `curl -I` shows 200 and `application/json`. Verify the Universal Links and App Links on devices *(MANUAL)*.
- [ ] Configure `legal.termsUrl`, `legal.privacyUrl` and `support.email` in the Worker config, and the flavor config URLs. `tools/check_urls.py` is green (online mode).
- [ ] Territory availability (CS16, RC29): set `ai.blockedCountries` in the prod config. Store availability is applied in Phase 20 via ASA-9.

---

## Sprint 19.3: AI safety & reviewer path (CS8, 1.4.1)

**Tasks:**
- [ ] Run `npm run eval:safety -- --env staging` with the **production** prompt version and model. It must pass the bars from Phase 8.6. Commit the report.
- [ ] Reviewer-path dry run on a TestFlight build pointed at the staging Worker, following the draft review notes (05 §7) step by step. Include the three sample refusal prompts ("Am I pregnant?", "Should I buy Bitcoin?", "I want to hurt myself") in `en`, one RTL locale and one CJK locale *(MANUAL)*.
- [ ] Report flow end to end: submit a report → the Worker stores it encrypted → `reading_reported` metric. Walk through the weekly triage in `AI_SAFETY.md` once.
- [ ] Kill-switch drill on staging: `readings.enabled = false` → S31 `readingsPaused` + the Classic offer; the budget hard stop → no paywall is shown (RC47).

---

## Sprint 19.4: Accessibility & RTL audit (01 §12–§13)

**Tasks:**
- [ ] Manual VoiceOver (iOS) and TalkBack (Android) passes on every ★ screen, including the complete draw via "Draw for me" + "Reveal all". Findings → fixes + tests. Report in `docs/compliance/A11Y_AUDIT.md`.
- [ ] Maximum Dynamic Type / font scale on S05, S07, S09, S10, S11 and S13: no clipping, and cards reflow above 1.5×.
- [ ] Reduced motion on: every ritual animation becomes a ≤ 200 ms crossfade.
- [ ] Arabic full walkthrough: mirroring, numerals, card names, and spread x-mirroring with card art never mirrored. Japanese reading without clipping.

---

## Sprint 19.5: Performance & security

**Tasks:**
- [ ] Performance (01 §16, 02 §17), measured on profile builds on mid-tier devices (Pixel 6a / iPhone 12) *(MANUAL device runs + automated timeline)*:
  - cold start to first frame ≤ 1.5 s and to interactive Home ≤ 2.0 s;
  - ritual animations p90 < 8 ms with no jank frames;
  - no DB queries on the UI isolate;
  - art decode sizes correct;
  - install size ≤ 60 MB (iOS) and ≤ 40 MB per ABI (Android).
  - Results go in `docs/compliance/PERF_REPORT.md`. Regressions are fixed before Phase 21.
- [ ] Reading latency from staging analytics: p50 ≤ 8 s and p95 ≤ 20 s for each spread size. If p95 > 20 s, revisit the model or effort config (BE10) or the length budgets.
- [ ] Security review (the `/security-review` skill on the full diff since Phase 2, plus a manual review):
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
- [ ] Coverage ≥ 90% for every unit after the added tests. Goldens and integration flows are green.
- [ ] The legal pages are live in 12 locales, and `check_urls.py` is green. Universal Links and App Links are verified on devices.
- [ ] Docs: `docs/compliance/**`, the runbooks (`AI_SAFETY.md`, `INCIDENT.md` first full version with the kill switches), CHANGELOG.
- [ ] One commit: `feat(taro): Phase 19 — Compliance, accessibility & performance hardening`.

## Next phase

Phase 20: Store Listings, ASO & Screenshots.
