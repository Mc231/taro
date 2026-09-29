# Phase 22: Store Submission & Launch

**Status:** ⬜ Not Started
**Depends on:** Phase 21

---

## Overview

This phase submits 1.0.0 to both stores, handles review, releases gradually, and turns on post-launch measurement. It includes a prepared response plan for the two most likely rejections: 4.3(b) spam and 1.1.6 fortune telling. The response plan uses the PR11 widget as the escalation lever.

**Output of this phase:**
- Taro 1.0.0 live on the App Store (phased release) and Google Play (staged rollout 20% → 100%).
- The tag `app-v1.0.0+N`, and the `CHANGELOG` / `worker/CHANGELOG.md` released sections.
- Taro added to `portfolio-audit` (`~/.blocks-secrets/portfolio.json`), with the Day-0 snapshot requested.
- A launch monitoring log for the first 14 days in `docs/releases/1.0.0-launch.md`.

---

## Specs referenced

`05_COMPLIANCE_STORE_ASO.md` CS9, CS11, CS17, §7, §8.3 M8 and M10, §8.4, §9.7, Risks (4.3, 1.1.6, reviewer purchase). `01_PRODUCT.md` PR11, §18 risks. `06_QUALITY_TESTING_CI.md` §8 (deploy gates), §10.1 (tags), §12 Store checklist. `03_BACKEND_WORKER.md` §14.1 alerts, BE-R5. `04_MONETIZATION.md` §14 KPIs.

---

## Sprint 22.1: Pre-submission gate

**Tasks:**
- [ ] Run the 06 §12 "Store" checklist:
  - metadata pushed and re-read;
  - privacy labels and Data Safety match `PRIVACY_LABELS.md`;
  - Apple age rating 13+ and Play target audience 16–17 / 18+ answered as documented (RC93);
  - review notes current (05 §7 + Classic reading + sandbox note, CS11), pushed with `asa ios update-review-info`;
  - screenshots current; `check_store_copy.py` green.
- [ ] `eval:safety` passed with the exact production prompt version and model within the last 7 days (QA17).
- [ ] The production Worker is healthy: alerts quiet for 24 h; sandbox purchases accepted in prod within the caps (App Review, BE-R5, RC63); the low-trust bucket alert (`abuse.lowTrust.alertPerBucketPerDay`) is quiet and no per-prefix cap is hot, so a low-trust review device would still get its free reading (RC65, RC74). Review devices normally pass App Attest / Play Integrity.
- [ ] Owner go/no-go sign-off recorded in `docs/releases/1.0.0-launch.md`.

---

## Sprint 22.2: Submit *(MANUAL + workflows)*

**Tasks:**
- [ ] iOS: `deploy-ios.yml` lane `release` (submit for review with metadata from `store/`). Attach the 4 IAPs to the version (M10). Phased release **on**. Manual release after approval (the owner chooses the day).
- [ ] Android: `deploy-android.yml` track `production`, `release_status: draft`, then roll out at 20% from the console after the checks. Submit the IAPs as active.
- [ ] Tag `app-v1.0.0+N` on the submitted SHA (06 §10.1).
- [ ] Rejection response plan (05 Risks, 01 §18), prepared before submitting:
  - **4.3(b):** reply in the Resolution Center with a short video of the journal + spread-aware reading + Learn + the original deck, and the differentiation table (`docs/compliance/DIFFERENTIATION.md`). **Do not resubmit unchanged.** If it is rejected a second time, pull the PR11 home-screen widget forward (Phase 23 Sprint 23.1) and resubmit.
  - **1.1.6:** point to the framing on every surface, the refusal behaviour and the Lifestyle category, and adjust copy if the reviewer quotes a specific phrase (then add that phrase to `banned_phrases.yaml`).
  - **2.1 purchase failure:** check the Worker logs for the reviewer's sandbox transaction (the environment tag), fix, and resubmit with notes.
  - **5.1.2(i):** show the consent sheet naming the AI provider(s) in the final `ai.disclosedProviders` list (confirmed by the owner before submission; v1 default Anthropic and OpenAI, RC97), and the decline → Classic reading path.

---

## Sprint 22.3: Launch & monitoring

**Tasks:**
- [ ] On approval: release iOS (phased, 7 days) and ramp Android 20% → 50% → 100% over about 7 days, stopping on any alert.
- [ ] Days 0–14 monitoring log:
  - crash-free rate;
  - Worker 5xx and `reading_failed` rates;
  - AI spend vs budget;
  - verify success rate ≥ 99.5% and SSV lag p95 < 10 s (04 §14);
  - refusal and report rates per locale;
  - store reviews mentioning ads, paywall or accuracy.
  - Act on alerts via `INCIDENT.md`.
- [ ] Day 0: add taro (bundle ID, Apple ID, GA4 property) to `~/.blocks-secrets/portfolio.json`; run `portfolio.py snapshot request --app taro` (CS17, 05 §9.7).
- [ ] Update the AdMob apps with the live store links (M1). Verify `app-ads.txt` in the AdMob console.
- [ ] Release notes and What's New are archived. `docs/aso/ASO_TRACKER.md` gets a launch row.

---

## Done when

- [ ] 1.0.0 is live on both stores at 100% rollout, with no open P1 incident.
- [ ] The portfolio-audit Day-0 snapshot is requested, and the week-1 summary (`portfolio.py summary --app taro`) is recorded in the launch log.
- [ ] Coverage and CI are still green on `main`. The tags `app-v1.0.0+N` and `worker-v1.0.0` exist.
- [ ] Docs: the launch log, RELEASE runbook lessons learned, CHANGELOG.
- [ ] One commit: `chore(taro): Phase 22 — Submission & launch`.

## Next phase

Phase 23: Post-Launch v1.1 & ASO Iteration.
