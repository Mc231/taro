# Android end-to-end test report

- **Date:** 2026-10-04
- **Device:** emulator-5554 (Pixel_9a AVD, Android 16, sdk_gphone64_arm64, Google Play services)
- **Plan:** [ANDROID_E2E_PLAN.md](ANDROID_E2E_PLAN.md) (135 cases: 53 P0, 60 P1, 22 P2)
- **Runs:**
  - A, the 17 fake-backed flows: [android_runs/A_flows.md](android_runs/A_flows.md)
  - B, new tests against the real staging Worker: [android_runs/B_staging.md](android_runs/B_staging.md)
  - C, the screenshot tour in 6 modes × 68 shots: [android_runs/C_visual.md](android_runs/C_visual.md)
- **Scope:** testing only. No app or Worker code changed and nothing committed. The new test code is in `apps/taro/integration_test/qa/`.

## Summary

| # | Area | Cases | Pass | Fail | Blocked | Manual (M only) | Notes |
|---|---|---|---|---|---|---|---|
| 1 | First launch, onboarding, consent, UMP | 15 | 8 | 2 | 1 | 4 | ONB-01 and ONB-04 fail: BUG-01 (S04 stuck) and BUG-07 (A flow red). ONB-02: Welcome pages 2–3 weren't captured. UMP-01 to UMP-03 need EEA. |
| 2 | Today (Home), daily card | 15 | 14 | 0 | 0 | 1 | DAY-09 passed only on the 4th run because the emulator was shared. DAY-06 needs the OS notification dialog. |
| 3 | Reading flow | 28 | 17 | 8 | 0 | 3 | RD-02..07 and RD-14: draw-screen visuals (BUG-05, BUG-06, BUG-08). RD-21: footer scroll (BUG-07). Staging `three_ppf`/ar/de readings were blocked by the daily free-reading limit. |
| 4 | Classic reading, consent re-entry | 6 | 6 | 0 | 0 | 0 | |
| 5 | Monetisation | 19 | 14 | 2 | 1 | 2 | PAY-02 and PAY-03: "0 readings" (BUG-02). BAN-01: the fake ads draw no banner. Real purchases need the Play sandbox (M). |
| 6 | Journal | 8 | 8 | 0 | 0 | 0 | Thumbnails are blank in the fake build (fake artefact, not a bug). |
| 7 | Learn | 6 | 4 | 0 | 1 | 1 | LRN-05: the fake About article is empty, so it needs a recheck on a real build. |
| 8 | Settings, data, help, legal | 18 | 11 | 3 | 1 | 3 | SET-01: de/ja overflow, and only 5 of 12 locales were toured. SET-02: RTL punctuation. HLP-04: Legal tabs are clipped. HLP-01: the fake FAQ is empty. |
| 9 | Deep links | 8 | 0 | 0 | 0 | 8 | All manual (adb or a real device). |
| 10 | Platform, resilience, accessibility | 12 | 7 | 1 | 2 | 2 | PLT-05 at 200 % text fails (BUG-03, BUG-04). Not run: the tablet tour (PLT-09) and cold-start perf (PLT-12). |
| | **Total** | **135** | **89** | **16** | **6** | **24** | |

How the columns are counted:
- **Pass** means the automated part (A, B or C) passed. 24 of these cases also have an M step, which is still open; see the checklist below.
- **Fail** means any defect against the case's expected result, including cosmetic ones.
- **Blocked** means the case could not run in this environment.
- **Manual** means the case is M only, or its automated part was not possible.

A-flow results: 16 of 17 pass. `first_launch_free_reading_test` fails on every run (BUG-07). Three flows were flaky only because of the environment: hold_lost and kill_switch hit `INSTALL_FAILED_INSUFFICIENT_STORAGE` with the 218 MB APK, and timezone_change ran while another agent was using the same emulator and `build/` folder.

B results on staging:
- **Passed:** B1 (with BUG-01), B2 (paywall shown before the draw; the rewarded ad gives `grantDelayed` as expected), B7 (offline banner, export, delete all, import) and B8 (unverified device).
- **Passed only in an earlier run:** B3 (rephrase and crisis) and the B4 single reading, which completed in 7.7 s.
- **Blocked:** B4 to B6 in the final run. The device had used its one free AI reading for the day (RC53). The Google sample ad never sends the reward callback (SSV) to staging. Granting credits with `ledger-adjust` needs Cloudflare credentials, which were not available to this run.

## Bugs

Severity:
- **Blocker:** stops a core flow or fails store review.
- **Major:** a visible defect on a key or ★ screen, or a red release gate.
- **Minor:** limited impact or a workaround exists.
- **Cosmetic:** looks wrong, nothing else.

Screenshot paths are relative to `docs/qa/android_runs/screenshots/`. Suspected causes come from reading the code and are not confirmed unless stated.

### Blocker

**BUG-01: Onboarding sometimes stays on AI consent (S04) after "Allow AI readings".**
- **Area / case:** 1, ONB-01 and ONB-04.
- **How often:** 3 of 6 fresh installs on the real staging build.
- **State when stuck:** the route is `/consent/ai`, but `onboardingStep=done` and `ai=granted` are already saved. The screen does not move on, even after 60 s.
- **Repro:**
  1. Fresh install of the staging build.
  2. Go through Welcome and the disclaimer.
  3. Tap "Allow AI readings".
  4. Repeat a few times; about half the runs stay on S04.
- **Evidence:** `docs/qa/android_runs/B_logs/ALL.log` and `B1_fresh.log`; B_staging.md §Bugs.
- **Suspected cause:**
  1. `apps/taro/lib/features/onboarding/view/ai_consent_screen.dart` calls `context.go(home)` as soon as the state becomes `granted`.
  2. This happens before `OnboardingCompletion.run` (`features/onboarding/controller/ai_consent_controller.dart`) saves `onboardingStep=ump`.
  3. `apps/taro/lib/routing/guards.dart` then redirects back to `/consent/ai`.
  4. Once the step is `ump` or `done`, the guard never sends `/consent/ai` on to Home. It only redirects launch, welcome and disclaimer.
- **Why the fake flows miss it:** the fake consent store writes synchronously.
- **Still to do:** confirm by hand on a release build (M, ONB-04).

### Major

**BUG-02: The store shows "0 readings" for every pack, and S10 shows "From $2.99 for 0".**
- **Area / case:** 5, PAY-02 and PAY-03.
- **Who sees it:** anyone whose `GET /v1/config` hasn't succeeded yet, for example offline on first launch or after a config fetch failure. Misleading pricing is a store-review risk.
- **Repro:** open S10 or S11 before the remote config has loaded (fake build, or staging in airplane mode on first launch).
- **Evidence:** `en_dark/S11_store.png`, `en_dark/S10_out_of_readings.png`, `de/S11_store.png`, `ar/S11_store.png`, `ja/S10_out_of_readings.png`.
- **Suspected cause:** `apps/taro/lib/features/paywall/controller/paywall_catalog.dart:217` uses `credits: pack.credits ?? 0`, because the compiled default config has no credits. The pack should be hidden, or shown without a count, until credits are known.

**BUG-03: The draw screen (S08, ★) overlaps itself at 200 % text.**
- **Area / case:** 10, PLT-05 (also RD-14).
- **What overlaps:**
  - The third slot is hidden behind the card fan.
  - The question text runs under "Reveal all".
  - The Celtic Cross position rows run into "Reveal all".
- **Repro:** set system font size to maximum (textScaler 2.0), start a reading and reach the pick step.
- **Evidence:** `en_text200/S08_pick.png`, `en_text200/S08_picked.png`, `en_text200/S08_celtic_picked.png`.
- **Suspected cause:** fixed-height layout in `apps/taro/lib/features/reading/view/draw_panes.dart` and `draw_screen.dart`. This breaks coding rule 16 (200 % text without clipping).

**BUG-04: Welcome (S02) is cut off at 200 % text.**
- **Area / case:** 1 and 10, PLT-05.
- **What's wrong:** "Get started" covers the headline, and the three feature bullets are not visible. The page neither scrolls nor shrinks.
- **Repro:** set the maximum font size, then fresh install.
- **Evidence:** `en_text200/S02_welcome_1.png`, `en_text200/S01_launch.png`.
- **Suspected cause:** a non-scrollable layout in `apps/taro/lib/features/onboarding/view/welcome_screen.dart`.

**BUG-05: Celtic Cross position labels break letter by letter in every locale.**
- **Area / case:** 3, RD-02..07.
- **Examples:** "Pres/ent", "Fou/ndat/ion", "Geg/enw/art", "最近の過/去".
- **Repro:** pick the Celtic Cross spread, then draw (S08) or open its classic result (S32).
- **Evidence:** `en_dark/S08_celtic_picked.png`, `en_dark/S32_celtic_top.png`, `de/S08_celtic_picked.png`, `ar/S08_celtic_picked.png`, `ja/S08_celtic_picked.png`.
- **Suspected cause:** label width tied to the tiny card width in `apps/taro/lib/features/reading/view/spread_slots.dart`.

**BUG-06: The "Tap to reveal" hint (`drawTapToReveal`) is clipped inside the first face-down card.**
- **Area / case:** 3, RD-14.
- **Examples:** "Tap to revea", "Aufdecken t", "ップしてめく".
- **Repro:** S08, after picking the cards, before any reveal.
- **Evidence:** `en_dark/S08_picked.png`, `de/S08_picked.png`, `ja/S08_picked.png`, `en_text200/S08_picked.png`.
- **Suspected cause:** single-line text in a fixed card box in `apps/taro/lib/features/reading/view/spread_slots.dart` / `draw_panes.dart`. It needs to wrap or scale down.

**BUG-07: The A flow `first_launch_free_reading_test` fails every time on the S09 disclaimer footer.**
- **Area / case:** 1 and 3, ONB-01 and RD-21. B4 hit the same failure on a real staging reading.
- **Error:** `WaitUntilVisibleTimeoutException` at `await app.$(DisclaimerFooter).scrollTo();` (line 55).
- **What the screenshot shows:** the footer is on screen ("For entertainment and self-reflection. Not professional advice." plus "Full disclaimer"; `en_light/S09_result_footer.png`). So this is very likely a test-side scroll problem: the footer is the last item of a long lazy list and the scroll gives up after 5 s.
- **Why it's still major:** the integration gate is red.
- **Repro:**
  ```
  cd apps/taro && flutter test integration_test/flows/first_launch_free_reading_test.dart --flavor dev --dart-define-from-file=config/dev.json --dart-define=TARO_ENV=test -d emulator-5554
  ```
- **Evidence:** `docs/qa/android_runs/logs/A_first_launch_free_reading.log` and its `_rerun*.log`.
- **Suspected cause:** `apps/taro/integration_test/flows/first_launch_free_reading_test.dart:55`. It may need an explicit `scrollable:` and more `maxScrolls` or a longer timeout. The app side to check is `reading_result_screen.dart:208-243` (footer inside `_content`).

### Minor

**BUG-08: German "Vergangenheit" breaks mid-word as "Vergangen / heit".**
- **Where:** under the 3-card slots and the result mini layout (S08, S09, S15).
- **Evidence:** `de/S08_pick.png`, `de/S08_picked.png`, `de/S09_result_top.png`.
- **Suspected cause:** `spread_slots.dart` (label width). It needs hyphenation or a smaller label size.

**BUG-09: The "Type DELETE to confirm" field on S26 sits below the fold, behind the pinned buttons.**
- **Where:** S26 in every locale. In ja the label is not visible at all.
- **Repro:** Settings → Delete all data.
- **Evidence:** `en_dark/S26_delete.png`, `ja/S26_delete.png`, `en_text200/S26_delete.png`.
- **Suspected cause:** layout order in `apps/taro/lib/features/settings/view/delete_data_screen.dart`.

**BUG-10: The Legal (S29) tab bar cuts off the outer tabs with no sign that it scrolls.**
- **Examples:** "Ope", "Privac", "Datenschutzer".
- **Repro:** Settings → Legal.
- **Evidence:** `en_dark/S29_legal_disclaimer.png`, `de/S29_legal_disclaimer.png`, `en_text200/S29_legal_terms.png`.
- **Suspected cause:** `apps/taro/lib/features/legal/view/legal_screen.dart`.

**BUG-11: In Arabic, an LTR question puts its punctuation on the wrong side.**
- **Example:** "?What should I focus on this week".
- **Where:** S07, S08, S09 in ar, after typing an English question.
- **Evidence:** `ar/S07_question_filled.png`, `ar/S09_result_top.png`.
- **Suspected cause:** the question text gets no bidi isolate or detected `TextDirection`, in `question_screen.dart`, `draw_panes.dart` and `reading_result_screen.dart`.

**BUG-12: At 200 % text, the S17 and S18 header text overflows into the prev/next arrows.**
- **Example:** "Major Arcana · 18 [of 22 cut]".
- **Evidence:** `en_text200/S17_card.png`, `en_text200/S18_spread_celtic.png`.
- **Suspected cause:** `apps/taro/lib/features/learn/view/learn_top_bar.dart`.

**BUG-13: At 200 % text, the S05 first-run coachmark covers the screen and points at a card below the fold.**
- **Evidence:** `en_text200/S05_home_first_run_coachmark.png`.
- **Suspected cause:** `packages/taro_ui/lib/src/components/feedback/taro_coachmark.dart` and `features/home/view/home_screen.dart`.

**BUG-14: At 200 % text, the S30 "Your journal is safe" panel looks clipped behind the pinned Update button.**
- It can be reached by scrolling.
- **Evidence:** `en_text200/S30_update_required.png`.
- **Suspected cause:** `apps/taro/lib/features/update/view/update_required_screen.dart`.

**BUG-15: With an empty search, the FAQ (S28) shows "No answers match “”".**
- An empty search should list all entries.
- **Note:** the fake FAQ is empty, so recheck with real content.
- **Evidence:** `en_dark/S28_help.png`, `de/S28_help.png`, `ar/S28_help.png`.
- **Suspected cause:** `apps/taro/lib/features/help/view/faq_screen.dart` shows `helpSearchEmpty` even when the query is empty.

**BUG-16 (test infra): `TARO_STAGING_SMOKE=1` makes the staging smoke test skip every case silently.**
- `bool.fromEnvironment` treats only `true` as true.
- **Evidence:** B_staging.md FINDING-2.
- **Suspected cause:** `apps/taro/integration_test/staging/smoke_test.dart` and the docs that pass `=1`. The fix is to use `=true` or compare the string with `'1'`.

### Cosmetic

**BUG-17: At 200 % text, the S27 URL breaks as "findahelpline.c / om".**
- **Evidence:** `en_text200/S27_crisis.png`.
- **Suspected cause:** `features/help/view/crisis_resources_screen.dart`.

**BUG-18: In ja, the S27 title leaves a one-character orphan ("…ありませ / ん").**
- **Evidence:** `ja/S27_crisis.png`.
- **Suspected cause:** `crisis_resources_screen.dart` (line breaking).

**BUG-19: In ja, the S11 balance chip wraps onto 2 lines and crowds the close button.**
- **Evidence:** `ja/S11_store_balance_chip.png`, `ja/S12_rewarded.png`.
- **Suspected cause:** `features/paywall/view/paywall_parts.dart`.

**BUG-20: On S16, The Fool shows "○" as its numeral.**
- This may be intended, so it needs a decision.
- **Evidence:** `en_dark/S16_learn.png`.
- **Suspected cause:** `features/learn/view/deck_browser_screen.dart` / `learn_labels.dart`.

### Not bugs, recorded

- **Plan correction (RC53).** Reinstalling or `pm clear` does not give a new free reading on Android, because the device-day counter is shared by every install on the device. The plan's "Reset" row is wrong.
- **No rewarded grant on staging.** The sample rewarded ad sends no reward callback (SSV) to staging, so the result is `grantDelayed`, which is the expected outcome.
- **Fake-build artefacts:**
  - blank card faces
  - "Card major_17" names
  - empty About and FAQ
  - fake "$2.99" prices

  These need a recheck on a real build; see C_visual.md.
- **Test environment:**
  - The 218 MB debug APK fills the emulator's storage. Run `pm trim-caches` first.
  - Only one agent at a time may use emulator-5554 and `apps/taro/build/`.
  - The patrol CLI isn't installed, so the runs used `flutter test`.

## Manual checklist (owner, on a real device and the Play internal-testing track)

Setup:
- Install a staging or prod build from Play internal testing on a real Android phone, with a licence-tester account.
- For UMP, use an EEA VPN or a test device registered for EEA debug geography.
- Tick each box and note the device, build and date.

### Onboarding and consent
- [ ] **ONB-04 / BUG-01** (P0): fresh install ×5 on a release build. "Allow AI readings" always reaches Home.
- [ ] **ONB-06** (P0): the S04 copy names what is sent, the providers and the retention periods, and links the privacy policy.
- [ ] **ONB-07** (P1): kill the app mid-onboarding. It resumes at S03, not S02.
- [ ] **ONB-08** (P0): first launch offline. Onboarding finishes, Home shows "Connect to start AI readings", and the daily card and Learn work. UMP is retried on the next launch. Also check BUG-02: no "0 readings" in the store.
- [ ] **UMP-01** (P0): in the EEA, the UMP form appears after S04 and the ads SDK starts only after it.
- [ ] **UMP-02** (P0): decline all. No personalised ads. Banners appear only if consent allows. Rewarded is offered only when a compliant request is possible.
- [ ] **UMP-03** (P0): the Settings privacy-options row reopens the form. The row is hidden outside the EEA.

### Home and daily card
- [ ] **HOME-03** (P1): offline, the stale chip shows the last value and the offline banner.
- [ ] **DAY-02** (P1): the same card shows all day, including after killing and reopening the app.
- [ ] **DAY-06** (P0): reminder offer, yes. The OS POST_NOTIFICATIONS dialog appears, a 09:00 reminder is scheduled, and the offer never shows again.
- [ ] **DAY-09** (P1): change the timezone in system settings. The day boundary and the reminder follow it.

### Reading
- [ ] **RD-15** (P1): with Remove animations on, there's no flying or flip animation and the ritual still completes.
- [ ] **RD-16** (P1): system back on S08 shows "Leave this reading?". Leaving keeps the reading pending in the Journal.
- [ ] **RD-21** (P0): the S09 footer is reachable at the end of a long real reading (BUG-07).
- [ ] **RD-24** (P1): Share opens the Android share sheet. Cancel returns cleanly.
- [ ] **RD-26** (P2): the Play in-app review request follows policy, and classic readings don't count.
- [ ] **RD-02..07, RD-27** (P0): one real `three_ppf` reading in ar and one in de, plus a report (staging B5/B6 were blocked).

### Monetisation (Play sandbox)
- [ ] **PAY-03** (P0): the store shows readings_3/10/30 with store-localised prices and real counts. "Best value" appears only if it's true. Nothing is pre-selected.
- [ ] **PAY-04** (P0): buying a pack goes verifying → success, and the balance goes up by the Worker grant. The purchase is consumed only after the grant.
- [ ] **PAY-05** (P1): cancelling a purchase returns silently.
- [ ] **PAY-06** (P1): a pending purchase (slow test card) shows "Waiting for approval", and the credits arrive later.
- [ ] **PAY-07** (P1): delayed verification shows "Your purchase is safe…" and retries on resume.
- [ ] **PAY-09** (P0): Remove Banner Ads hides banners on all 3 screens at once. Settings shows the ✓.
- [ ] **PAY-10** (P0): Restore brings back Remove Banner Ads, or shows "No purchases to restore". The copy explains that consumables aren't restored.
- [ ] **PAY-11** (P2): Move readings shows the transfer code with the Support ID.
- [ ] **RW-02** (P1): closing the rewarded ad early gives neutral copy and no reward.
- [ ] **BAN-01 / BAN-03** (P0/P1): real banners appear only on Home, the Journal list and the Learn deck, one per screen, with a ≥16 dp gap. The container collapses on no-fill. There are none on reading, paywall or settings screens.

### Learn, settings, help
- [ ] **LRN-05** (P1): the About article shows the real text with the AI limits and the disclaimer.
- [ ] **LRN-06** (P1): Learn works fully in airplane mode.
- [ ] **HLP-01** (P1): the real FAQ content appears (check BUG-15).
- [ ] **SET-01** (P0): switch through all 12 languages (only 5 were toured). Look for overflow.
- [ ] **SET-04** (P2): the haptics toggle is respected, and so are reversals.
- [ ] **SET-05** (P1): the reminder fires at the set time and never reveals a card. Tapping it opens `taro://daily` (S13).
- [ ] **SET-06** (P1): with notifications denied, "Notifications are off" + Open settings opens the app's notification settings.
- [ ] **SET-08** (P1): export creates `taro-backup-YYYY-MM-DD.json` and opens the share sheet. It also works offline.
- [ ] **SET-09** (P1): import via the system file picker shows the preview counts. Merge combines the entries.
- [ ] **HLP-02** (P0): crisis resources match the device region and work offline. Phone and URL taps open the dialer and browser.
- [ ] **HLP-03** (P1): Contact support opens a mailto with the version, OS, locale and Support ID (matches About).
- [ ] **HLP-04** (P0): Terms and Privacy open `taro.vshyrochuk.com`. The licences page lists the packages.

### Deep links (adb: `adb shell am start -W -a android.intent.action.VIEW -d "<uri>" com.vshyrochuk.taro[.staging]`)
- [ ] **DL-01** (P1): `taro://daily` opens S13.
- [ ] **DL-02** (P1): `taro://reading/new?spread=celtic_cross` opens S07 with the Celtic Cross. An unknown spread falls back safely.
- [ ] **DL-03** (P2): `taro://journal/{id}` opens S15. An unknown id shows an empty or error state with no crash.
- [ ] **DL-04** (P2): `taro://learn/card/{id}` opens S17.
- [ ] **DL-05** (P2): `taro://store` opens S11.
- [ ] **DL-06** (P1): App Links. `adb shell pm get-app-links` shows the domain verified, and the link opens the app, not the browser.
- [ ] **DL-07** (P1): a link opened during onboarding is queued until Home.
- [ ] **DL-08** (P2): cold and warm starts both route correctly.

### Platform, resilience, accessibility
- [ ] **PLT-01** (P0): airplane mode. S07 shows offline with Begin disabled, and the classic reading works. Going back online resyncs.
- [ ] **PLT-02** (P0): after leaving the app in the background overnight, resume recomputes the balance, the daily card and the reminder.
- [ ] **PLT-03** (P1): with Developer options → "Don't keep activities", state is restored or the reading is safely pending. No credit is lost.
- [ ] **PLT-04** (P2): a reinstall gets a new install ID and the credits don't carry over (FAQ copy). The transfer flow is available.
- [ ] **PLT-05** (P0): at the largest font and display size, recheck BUG-03, BUG-04 and BUG-12 to BUG-14.
- [ ] **PLT-06** (P0): with TalkBack, every control and card has a label and the orientation is spoken. Targets are ≥48 dp and the focus order is logical.
- [ ] **PLT-07** (P1): system back:
  - On a tab other than Today, back goes to Today, then exits.
  - Sheets close.
  - S08 asks to confirm.
  - S09 goes to Home.
  - S30 can't be bypassed.
- [ ] **PLT-08** (P2): rotation causes no crash or state loss.
- [ ] **PLT-09** (P1): tablet layouts (tablet AVD or device) for S05–S11, S13, S14, S16, S20, S25, S27, S30 and S32.
- [ ] **PLT-12** (P2): release-build cold start is within the 06 budget (`integration_test/perf/cold_start_test.dart`).

## To finish the automated runs

1. Get readings for B4–B6 in one of two ways:
   - Grant staging bonus credits to the run's Support ID: `cd worker && npm run ledger-adjust -- --env staging --support-id <id> --bucket bonus --delta 4`. This needs Cloudflare credentials.
   - Or wait for the device's local day to roll over (21:00 UTC). B3 spends no reading, so each day covers B3 plus one of B4–B6.
2. Run `apps/taro/integration_test/qa/run_staging_e2e.sh ALL '^B[1-7] ' fresh`.
3. Re-run A `first_launch_free_reading_test` once BUG-07 is resolved.
4. Run the tablet tour (PLT-09) and `integration_test/perf/cold_start_test.dart` (PLT-12).

## Re-test 2026-10-04

After the BUG-01..BUG-20 fixes (uncommitted working tree, including the in-progress S07 refusal state). Same device: emulator-5554 (Pixel_9a AVD, Android 16). Logs: `docs/qa/android_runs/retest_logs/`; screenshots: `docs/qa/android_runs/screenshots_retest/<mode>/` (68 per mode). How to run each method: [README.md](README.md).

### Runs

| Method | Result |
|---|---|
| A, all 17 fake-backed flows | **17/17 pass** (`retest_logs/A_summary.txt`), including `first_launch_free_reading_test` (BUG-07) and the earlier environment-flaky hold_lost, kill_switch and timezone_change. |
| B, staging Worker | **B1–B8 all pass.** Final runs: `B/ALL` (B2, B3, B4, B7 pass; B1 reached Home but failed on a test-teardown race, fixed below), `B2/R2` and `B4/` (B1 ×3 fresh, B8 pass), `B3/R3` (B5, B6, B7 pass). B3–B6 ran because `run_staging_e2e.sh` now grants 4 staging bonus credits to the run's Support ID (`QA_GRANT=1`, `ledger-adjust`, ticket `qa-e2e-<supportId>`), which removes the RC53 one-reading-per-device-day blocker. B4 single reading 25.7 s, B5 ar `three_ppf` 15.9 s + report, B6 de `three_ppf` 12.7 s; refusal (B3) 4.6 s with "Not charged". |
| C, screenshot tour | **en_text200, de, ja, ar, en_dark: 6/6 tests each, 68 shots each.** One step skip as before: `en_text200/S11_store_balance_chip_FAILED` (the tour taps the Home chip, which at 200 % is not hit-testable after `go(/home)`; S11 itself is captured as `S11_store`). |

Test fixes made on the way (QA code only, no app change):
- `staging_e2e_test.dart`: `onboard()` waits for `onboardingStep=done`, so a case no longer ends while UMP/ATT still write (an `UnmountedRefException` on container dispose in B1); `switchLanguage` and `onboard()` start from whatever language the previous case left (B6/B7 cascaded after B5); the B5 RTL chip check asserts the chip's `Directionality` instead of its x position (with credits the chip moves into the body at the start side, which is correct); `ensureReading()` asks the host for a grant.
- `screenshot_tour_test.dart` only runs with `QA_MODE` set, and `run_staging_e2e.sh` no longer dies on an empty `EXTRA` array under `set -u` (macOS bash 3.2).
- Environment: twice, `flutter test` hung after installing the APK (app on its native splash, VM service never attached). Restarting the adb server cleared it; the reruns passed.

### Bug status

| Bug | Status | Evidence |
|---|---|---|
| BUG-01 S04 stuck | **Fixed, verified** | 6 of 6 fresh staging onboardings reached Home with no S04 stall (`B/ALL` B1, `B2/R2` B1, `B3/R3` B5, `B4/B1_fresh1`, `B4/B1_fresh2`, `B4/B8`); `router_test.dart` "S04 from onboarding reaches Home". Manual ONB-04 on a release build still open. |
| BUG-02 "0 readings" | **Fixed, verified** (unit) | `store_controller_test.dart`, `out_of_readings_controller_test.dart`. The tour harness now carries Worker-style pack credits, so S10/S11 show 3/10/30 (`de/S11_store.png`, `de/S10_out_of_readings.png`); the no-config path is covered by tests only. ONB-08 offline first launch still manual. |
| BUG-03 S08 at 200 % | **Fixed, verified** | `en_text200/S08_pick.png`, `S08_picked.png`, `S08_celtic_picked.png`: slots, question and rows scroll above the fan and buttons, no overlap. |
| BUG-04 S02 at 200 % | **Fixed, verified** | `en_text200/S02_welcome_1.png`: the page scrolls, "Get started" no longer covers the headline. |
| BUG-05 Celtic Cross labels | **Fixed, verified** | No mid-word breaks in any mode. In the fake build the cross is laid out as a single row of 10, so long labels shrink to a very small size (`de/S08_celtic_picked.png`, `en_dark/S32_celtic_top.png`); the real cross layout is covered by `text_fit_test.dart`. Recheck on a real build (RD-02..07). |
| BUG-06 "Tap to reveal" clipped | **Fixed, verified** | Not clipped in en/de/ja/ar/200 %. Note: de wraps to three small lines and ja (no spaces, one "word") shrinks to about 60 % of the badge size (`ja/S08_picked.png`). Legible, but small. |
| BUG-07 A flow footer | **Fixed, verified** | `first_launch_free_reading_test` passes; on staging B4/B5/B6 reached the S09 footer of real readings (RD-21). |
| BUG-08 "Vergangen / heit" | **Fixed, verified** | `de/S08_pick.png`, `de/S08_picked.png`, `de/S09_result_top.png`: one word, slightly smaller. |
| BUG-09 S26 field below fold | **Fixed, verified** | `en_dark`, `ja`, `en_text200/S26_delete.png`: the field sits above Delete/Cancel. At 200 % the pinned block leaves little room for the scrolling list, but nothing is hidden. |
| BUG-10 S29 tabs | **Fixed, verified** | `de/S29_legal_disclaimer.png`, `en_text200/S29_legal_terms.png`: the clipped edge fades; ar fits without a fade. |
| BUG-11 RTL question punctuation | **Fixed, verified** | `ar/S07_question_filled.png`, `ar/S08_picked.png`, `ar/S09_result_top.png`: an LTR question keeps "?" at its end. Still open (low): LTR reading text in an RTL UI (fake English reading body in ar, e.g. ".An overview of the spread") gets no isolate; real readings come in the UI language (B5 `contentLocale: ar`). |
| BUG-12 S17/S18 header | **Fixed, verified** | `en_text200/S17_card.png`, `S18_spread_celtic.png`: two lines inside the bar, clear of the arrows. |
| BUG-13 S05 coachmark | **Fixed, verified** | `en_text200/S05_home_first_run_coachmark.png`: the bubble fits and points at "Start a reading". |
| BUG-14 S30 at 200 % | **Fixed, verified** | `en_text200/S30_update_required.png`: the "Your journal is safe" panel shows; Update scrolls after it. |
| BUG-15 FAQ empty search | **Fixed, verified** | `en_dark/S28_help.png` (no "No answers match “”"); real FAQ content still to check (HLP-01). |
| BUG-16 `TARO_STAGING_SMOKE=1` | **Fixed, verified** | `staging_gate_test.dart`; every B run here used `=1` and ran. |
| BUG-17 S27 URL at 200 % | **Fixed, verified** | `en_text200/S27_crisis.png`: "findahelpline.com" on one line, button under the text. |
| BUG-18 ja S27 orphan | **Fixed, verified** | `ja/S27_crisis.png`: breaks after あなたは. |
| BUG-19 ja S11 chip | **Fixed, verified** | `ja/S11_store_balance_chip.png`: the chip is on one line in the body under the close. |
| BUG-20 The Fool "○" | **Fixed, verified** | `en_dark/S16_learn.png`: "0". |

### Observations from the new screenshots (not regressions)

- S18 (`en_text200/S18_spread_celtic.png`): the step chips' numerals touch their borders at 200 %. Same as the first run (fake row layout).
- The fake Celtic Cross row layout makes position labels tiny (see BUG-05); a real-build check of RD-02..07 decides whether the real cross needs a minimum label size.

### Gates

- `flutter analyze --fatal-infos` clean on `apps/taro` including `integration_test/qa/`; `dart format` clean; `shellcheck` clean on `run_staging_e2e.sh`.
- `melos run test:golden`: taro 643 and taro_ui 194 pass. Full `apps/taro` tests: 2861 pass.
- `tools/verify.sh` (full): every step ok, coverage gate PASS (apps/taro 99.53 %, taro_ui 99.97 %).

### Still open

- The manual checklist above (M cases, Play sandbox, UMP in the EEA, TalkBack, deep links).
- PLT-09 tablet tour and PLT-12 cold-start perf were not run.
- `QA_GRANT=1` writes `admin_adjust` rows on staging; use it only on staging.
