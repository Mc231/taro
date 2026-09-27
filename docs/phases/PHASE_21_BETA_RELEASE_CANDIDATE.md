# Phase 21: Beta Testing & Release Candidate

**Status:** ⬜ Not Started
**Depends on:** Phases 19, 20

---

## Overview

This phase puts the production-shaped build in front of real users: TestFlight external testing and a Play closed test. The Play account is **personal** (owner, 2026-09-27), so the closed test needs ≥ 12 opted-in testers for 14 continuous days before production access (CS M5). Recruit testers early (start during Phase 20).

During the beta, the phase:
- runs the full 06 §12 real-device release checklist on both platforms;
- drills the incident and rollback runbooks;
- collects cost, latency and refusal data, so the owner can confirm the model and free-reading decision (BE Q1) and the pricing before launch;
- fixes the issues found.

**Output of this phase:**
- A release candidate `1.0.0+N` built by `deploy-ios.yml` / `deploy-android.yml` from a green SHA, pointing at the **production** Worker (deployed here at 10% → 100%).
- `docs/runbooks/RELEASE.md` checklist fully ticked for the RC, with evidence.
- A beta report (`docs/releases/1.0.0-beta-report.md`): crash-free rate, reading latency p50/p95 per spread, AI cost per reading and per DAU, refusal rate by category and locale, report rate, `reading_failed` rate, paywall → purchase and rewarded completion, and tester feedback.
- Owner decisions re-confirmed: BE Q1 (model for free readings), `readings.freeDaily`, pack prices, and the budgets.

---

## Specs referenced

`06_QUALITY_TESTING_CI.md` QA11, QA13, QA17, §8 (deploy workflows), §10, §12 (release checklist), §13 (runbooks). `03_BACKEND_WORKER.md` BE15, BE18, §10, §14, Q1, BE-R1, BE-R2, BE-R4. `04_MONETIZATION.md` §14 KPIs, §15 (manual release checklist), §16. `05_COMPLIANCE_STORE_ASO.md` §8.3 M5, §9.7 targets. `01_PRODUCT.md` §15 funnels, §16 NFRs.

---

## Sprint 21.1: Production Worker

**Tasks:**
- [ ] Review the production remote config: `readings.freeDaily` = 1, `rewarded.*` defaults, `store.packs` order, `ai.model.free/paid`, `ai.effort`, `ai.promptVersion`, the budgets, `ai.blockedCountries`, `app.minVersion`, `legal.*`, and `rewarded.allowedAdUnitIds` (prod units). Push with `scripts/config-push.ts --env prod`.
- [ ] Tag `worker-v1.0.0` → `worker-deploy.yml` (production): migrations → versions upload → 10% → smoke → 100% after 30 min with no alerts (BE18). Alerts are wired to `ALERT_WEBHOOK_URL` and tested with a synthetic alert.
- [ ] Load sanity check on staging (k6 or a scripted burst): readings and balance at the expected launch concurrency; D1 write latency recorded (BE-R1). Rate-limit bindings are verified.
- [ ] Confirm the Play Integrity quota increase status (BE-R4) *(MANUAL)*.

---

## Sprint 21.2: Beta distribution *(MANUAL + workflows)*

**Tasks:**
- [ ] `tools/bump_version.sh` → `1.0.0+N`; CHANGELOG `[1.0.0]` dated. `deploy-ios.yml` lane `beta` → TestFlight external group (Beta App Review).
- [ ] Internal testers use `prodStaging` builds against the staging Worker (RC78). The external beta build below talks to the production Worker, where sandbox grants are capped (RC63). **No public TestFlight link.**
- [ ] `deploy-android.yml` track `closed` → a closed test with ≥ 12 opted-in testers for ≥ 14 consecutive days if the account rule applies (CS M5). Recruit the testers across the target locales (at least `ar`, `de`, `ja`, `uk`).
- [ ] A beta feedback channel (email/form) and a tester guide covering: the reviewer path, a sandbox purchase, the rewarded ad, export/import, and a request to report odd AI readings.

---

## Sprint 21.3: Real-device release checklist (06 §12, 04 §15)

**Tasks** (tick each in `docs/runbooks/RELEASE.md` with device, OS and build):
- [ ] Fresh install: onboarding, disclaimer, AI consent before the first reading. Declining sends no request (verified in the Worker logs).
- [ ] UMP with debug geography EEA: the form appears before any ad request; consent → personalized ads, reject → NPA; the privacy options re-open the form. Outside the EEA there is no form.
- [ ] ATT (iOS): after UMP, only once. Deny → the app and ads still work.
- [ ] The free daily reading works; the second reading hits the paywall **before** the draw.
- [ ] Each pack purchased (iOS sandbox + Android license tester) grants the right credits **after** verification. Kill the app between payment and grant → relaunch grants once and finishes. Ask to Buy and the Play slow card: no credits until approved, then credited once.
- [ ] Remove Ads → banners disappear. Delete + reinstall → restore → banners stay gone. Rewarded offers remain optional.
- [ ] Rewarded ad (the prod unit on a registered test device): SSV reaches the prod Worker → +1 after the poll. Cap and cooldown work; closing early grants nothing.
- [ ] Reinstall on iOS keeps the install ID, credits and today's allowance. Reinstall on Android gives a new ID, **no second free reading today** (device key, RC53), and the behaviour per 04 §12.9. The support transfer is drilled end to end: "Move readings from another device" on the new install → transfer code → `worker/scripts/credits-transfer.ts` with a real sandbox order (RC84).
- [ ] Midnight rollover while backgrounded → a new free reading once. Timezone changed twice within 24 h → the second change is rejected.
- [ ] Refusal probes (health, pregnancy, gambling, self-harm) in en, ar and ja; crisis resources localized.
- [ ] Reading failure (airplane mode mid-request) → error state, no charge, retry with the same cards.
- [ ] Export on device A → import on device B (merge and replace). A tampered file with `credits` has no effect.
- [ ] Arabic and Japanese walkthroughs; VoiceOver and TalkBack; maximum text size; light and dark; offline launch.
- [ ] StoreKit Configuration file (`Taro.storekit`) local refund simulation → the Worker revoke path works via sandbox notifications; an indebted install shows `purchasesBlocked(refundDebt)` (RC66).
- [ ] **iPad:** the full reviewer path on a physical iPad (latest iPadOS) running the iPhone app in compatibility mode: onboarding, reading, sandbox purchase, restore, rewarded ad; safe areas and the StoreKit sheet render correctly (06 §12, PR16).
- [ ] Analytics consent: with UMP debug geography EEA, no Firebase event before the UMP decision (DebugView), none after "Do not consent" (RC68).

---

## Sprint 21.4: Runbook drills & data review

**Tasks:**
- [ ] Drill `WORKER_ROLLBACK.md` on staging (`wrangler rollback`, `versions deploy <old>@100%`, D1 Time Travel restore to a scratch DB) and `SECRET_ROTATION.md` (rotate `TOKEN_SIGNING_KEYS` with the old `kid` still accepted). Record the times taken (06 §13).
- [ ] Drill `INCIDENT.md`: kill switches `readings.enabled`, `rewarded.enabled`, `ads.enabled`, and a model fallback via config.
- [ ] After ≥ 7 beta days, write the beta report from `scripts/metrics.ts` (Worker) and Firebase (app). Compare against the 01 §15 funnels, the 04 §14 KPIs and the 05 §9.7 targets.
- [ ] Owner decision meeting: confirm or adjust `ai.model.free` (BE Q1), `readings.freeDaily`, the budgets and the pack prices. Record the result in `00_DECISIONS.md`. Any change goes through config (plus the store for prices), with no code.
- [ ] Fix the beta issues. Every bug fix starts with a failing test (02 Testing rules). Build a new RC if needed.

---

## Done when

- [ ] The RC build passes the whole 06 §12 checklist on both platforms. Crash-free sessions in the beta are ≥ 99.5% (01 §16). `reading_failed` < 2%.
- [ ] `ci` and the Sonar gate are green on the RC SHA; nightly integration on both platforms is green within 24 h; `eval:safety` passed on prod-equivalent config (06 §12).
- [ ] The Play closed-test requirement is met (if applicable).
- [ ] Docs: the beta report, RELEASE checklist evidence, CHANGELOG `[1.0.0]`.
- [ ] One commit: `chore(taro): Phase 21 — Beta & release candidate` (bug fixes are separate `fix:` commits).

## Next phase

Phase 22: Submission & Launch.
