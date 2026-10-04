# E2E test report, round 3 (2026-10-04)

Code under test: HEAD abb3035 (TestFlight build 0.1.0+6 code). The staging and prod Workers run the crisis-before-rate-limit fix (R2-01). No app or Worker code changed and nothing was committed. Detail is in `android.md` and `ios.md`. Earlier rounds: `../ANDROID_E2E_REPORT.md` (round 1) and `../round2/REPORT.md` (round 2 and its re-test). Evidence paths are relative to `docs/qa/round3/`. `screenshots/` is gitignored.

**Devices** (one at a time):
- Android emulator `Pixel_9a` (A, B, phone tour) and `Pixel_Tablet` (tablet tour).
- iPhone 16e simulator (A, perf, exploratory on staging) and iPad Pro 13 simulator (tour).

**Verdict:** 0 blockers, 0 major, 0 regressions. Both round-2 majors that were in scope are verified fixed: R2-01 on staging and iOS-R2-01 on iPhone. There are 3 new minor findings and 1 nit. One finding is still open from round 2 and needs the owner (iOS-R3-01 = iOS-R2-02).

## Summary per area
| Area | Round 1 | Round 2 | Round 3 | Status |
|---|---|---|---|---|
| A: 17 fake-backed flows, Android | 16/17, then 17/17 | 17/17 (after reruns caused by the shared environment) | 17/17. `kill_switch` and `os_restore` failed first because adb dropped, then passed on rerun (`logs/A/`) | pass |
| A: fake-backed flows, iOS | not run | 26 pass / 17 self-skip | 22/22 flow tests (`ios/A_iphone16e_flows.log`) | pass |
| iOS perf | — | first screen 529 ms | first screen 502 ms, S08 p90 14.3 ms (debug). Passed only after a simulator reboot: an old "Open in Taro Beta?" prompt covered the app, an environment issue (`ios/A_perf_after_reboot.log`) | pass |
| B1–B7 on staging, `QA_GRANT=1` | pass (BUG-01) | pass | 7/7, no bugs (`B_logs/ALL.out.log`) | pass |
| B8 unverified device | pass | not run | pass (`B_logs/B8.out.log`) | pass |
| B9 refusal state on staging | — | fail (R2-01 crisis as the 4th question) | pass. Crisis shows S27 as the 1st, 4th and 6th question in one burst. Health (en, uk), gambling, chips, Rephrase and Reflect pass; Reflect costs 1 credit (`B_logs/B9.out.log`) | pass |
| C tour, Android phone (en light/dark, ar, de, ja, uk, en text 2.0) | BUG-03..20 | 646/648 shots | 504 shots, all flows pass. The only failed shot is `en_text200/S11_store_balance_chip`, a known tour limit (`logs/tour_summary.txt`) | pass |
| C tour, Android tablet (en light, ar) | — | run | 144 shots, all flows pass | pass |
| C tour, iPad Pro 13 (en light, ar) | not run | not run | 72 + 72 shots, 0 failed (`ios/C_*`) | pass (new) |
| iOS exploratory on staging | not run | partial (E3, E5 partial; E6, E7 blocked) | E0–E6 pass. E7 export is blocked by the test (the system share sheet can't be dismissed); export and import are covered by A `export_import_test` | mostly pass |
| iOS deep-link native hand-off | — | blocked | the scheme is registered (the "Open in Taro Beta?" prompt appears), but the host can't tap Open. The router was tested directly | manual |
| Ad placement | manual | manual | no ad over reading content in any shot (fake ads draw no banner) | manual |

## Fixes from rounds 1–2
**Regressions: none.** Every round-1 bug (BUG-01..20) and round-2 bug was re-checked shot by shot.

| Item | Round 3 |
|---|---|
| R2-01 crisis hidden by the per-minute limit | **verified on staging** (1st, 4th and 6th question in one burst) |
| R2-02 rate-limit copy | not hit (no 429 in the run) |
| R2-03 "Last checked January 1970" | fixed: the tour shows "September 2026", and staging S27 has no 1970 line |
| iOS-R2-01 Home "unavailable" on first launch | **verified fixed on iPhone**: 3 fresh installs, polled every 100 ms, `E0 flashes: []`. Android B1 is also clean |
| iOS-R2-02 consent form language | **still open** as iOS-R3-01 (owner, AdMob console) |
| V2-01 Celtic labels | numbers and a 10-position legend in every mode, Android tablet and iPad |
| V2-02..V2-12 | all hold (see `android.md` §Re-check) |
| V2-09 tablet app bar | holds on Android tablet and on iPad (en, ar) for every ★ screen |
| Platform transitions and back (7e8641f) | swipe back from a reading opened from the draw lands on Home. S15 → S09 → Done or swipe → S15, and a swipe from S15 → S14 |

**Cosmetic items carried from the round-2 re-test:**
- **RT-02 (still open, cosmetic):** the uk three-card S08 row has no "Відкрити" hint at phone width (`screenshots/uk/S08_picked.png`). The gold outline still guides the user.
- **RT-03 (still open, cosmetic, tour fake layout only):** card 2 has no number on the fake single-row Celtic layout (`S08_celtic_picked`, `S32_celtic_top`) on Android and iPad. The legend lists it. The real cross layout is covered by `qa_round2_layout_test.dart`.

## New bugs
**R3-02, minor (store review, rule 19 / RC39): "Drive" in Apple-facing text**
- **Platforms:** iOS and Android.
- **Repro:** Settings → Export (S24). The caption reads "Opens the share sheet: Files, Drive, email and more." The same string is used on iOS, so the iOS app names a Google product. In uk it reads "Диск".
- **Evidence:** `screenshots/*/S24_export.png`.
- **Suspected file:** `apps/taro/lib/l10n/arb/app_*.arb` (`exportButtonCaption`, all 12 locales), used in `apps/taro/lib/features/backup/view/export_screen.dart:84`.
- **Fix:** a neutral caption ("Files, email and more"), or a variant per platform. Also consider adding "Drive" for iOS to `tools/store_copy/banned_phrases.yaml`.
- Listed first because the top priority is store review.

**R3-01, minor (copy, uk): the pick title says "more" before any card is picked**
- **Platforms:** iOS and Android.
- **Repro:** with the app in uk, start a three-card reading and reach the S08 pick step with 0 cards picked. The title is "Виберіть ще 3 карти" ("Pick 3 **more** cards"); en says "Pick 3 cards".
- **Evidence:** `screenshots/uk/S08_pick.png`.
- **Suspected file:** `apps/taro/lib/l10n/arb/app_uk.arb:321` (`drawPickTitle`). "ще" fits only the remaining-count case. Check the other locales' plural forms in the same change.

**R3-03, minor (UX): Reflect without a question asks to shuffle and draw again**
- **Platforms:** Android seen on staging; same code on iOS.
- **Repro:** on staging, ask a health question to get the refusal, then tap "Reflect on the cards without a question". S08 shows "Shuffle the deck" and "I'm ready — draw", though the declined cards are already preset. The refusal copy says the cards are kept, so this suggests new cards.
- **Evidence:** `B_logs/B9.out.log` (the line "reflect S08:").
- **Suspected file:** `apps/taro/lib/features/reading/controller/question_controller.dart:480` (`reflectWithoutQuestion` → `begin()`). The draw screen could skip the shuffle and pick steps when cards are preset.
- **Not verified:** whether the S09 cards equal the declined cards. Check this manually, because a mismatch would make this major.

**iOS-R3-02, nit (copy): wrong not-found text for a daily-card date**
- **Platforms:** iOS seen; the code is shared.
- **Repro:** open `taro://journal/2020-01-01` (a date with no entry). The screen says "This reading isn't on this device anymore", which talks about a reading, not a daily card.
- **Evidence:** `screenshots/ios/explore_iphone_run3/flutter_shots/E6_deeplink_journal_missing*`.
- **Suspected file:** the `readingNotFound` string in the ARBs and the journal-date route's not-found view. It is reachable only through a hand-made link.

**iOS-R3-01, minor (open since round 2 as iOS-R2-02, owner action): consent form in English**
- **Repro:** fresh install with the device in uk. After S04, the UMP form ("Our app wants to stay free for you") shows in English. The order (UMP after S04) is correct per RC18.
- **Evidence:** `screenshots/ios/explore_iphone_run2/shots/*`, `screenshots/ios/explore_iphone/shots/FAIL_E6.png`.
- **Fix:** the AdMob console → Privacy & messaging languages, as listed in `docs/STORE_SUBMISSION.md`. No code change.

**Not bugs:**
- The fake S19 title "about", the S28 `support@example.com`, and S10 "Prices unavailable" on the emulator. These come from the fakes or the emulator, as in round 2.
- In ar, the tour types the English question in the Celtic flow. This is test data.
- The iOS perf hang was caused by a leftover system prompt on the simulator.

## Test-only changes (not committed)
- **`apps/taro/integration_test/qa/staging_e2e_test.dart`, B9:**
  - **The test was wrong and is fixed:** after Reflect, it now waits for S08 and draws before expecting S09, per 01 §7.5.
  - **Extensions:** crisis is asked as the 4th and 6th question, and the test waits 65 s before Reflect when `QA_PACE_S` < 60.
- **`apps/taro/integration_test/qa/ios_explore_test.dart`:**
  - new steps for the en reading, the S09 swipe back and the journal round trip;
  - a watcher for the "unavailable" text;
  - a `QA_ONLY` step filter;
  - sideways scrolling in the tap helper;
  - screenshots of the Flutter layer;
  - deep links sent to the router as a fallback.
  - One mistake in the test run itself was fixed: run 1 did the en reading after the switch to uk, so its E1a/E1b failures were false.
- **`apps/taro/integration_test/qa/run_ios_explore.sh`:** passes `QA_ONLY`, copies the Flutter-layer screenshots out of the app, and presses Return on the "Open in" prompt.
- **`.gitignore`:** `docs/qa/round3/screenshots/`.

**Clean-up:**
- `flutter clean` ran; 81–83 GB free. Simulators are shut down, `Podfile.lock` is restored, and the emulator is back to `Pixel_9a`.
- **Staging use:**
  - Android: B runs with `QA_GRANT=1`.
  - iOS: 3 free and 2 bonus readings, with +4 bonus granted to support IDs `6cad159a` and `817997d8`.

## Manual checklist

**iPhone, TestFlight build 6**
- [ ] Fresh install: the consent form is in the device language (needs the AdMob languages first), then the neutral pre-prompt, then ATT (iOS-R3-01, RC18/19/59).
- [ ] Home never says "unavailable" on first launch (iOS-R2-01; fixed on the simulator, confirm on a device).
- [ ] Free single and three-card readings end to end; the disclaimer and S09 footer are reachable.
- [ ] Refusal:
  - health and gambling questions get the refusal card;
  - the chips, Rephrase and Reflect work;
  - after Reflect, S09 shows **the same cards** as the declined draw (R3-03);
  - the balance changes only for Reflect.
- [ ] Self-harm question → S27 as the 1st and after several quick questions; the "Last checked" line; the country name; tap-to-call.
- [ ] Tap a real `taro://learn/card/major_00` link (from Notes or Safari) → Open → S17. This is the native hand-off the simulator couldn't do.
- [ ] Journal export through the share sheet (save to Files) and import back. The caption wording is R3-02.
- [ ] Sandbox purchases: packs, remove_ads, restore. The balance changes only after the Worker grant.
- [ ] Rewarded ad never shows on its own; no banner over a reading.
- [ ] Swipe back from S09 (→ Home) and from S15 → S09 (→ S15) on a device.
- [ ] Largest Dynamic Type on S07, S08, S09, S26.
- [ ] uk: the pick title (R3-01) and no English strings.
- [ ] iPad, if available: centred layout and the Celtic legend.
- [ ] No Android or Google wording anywhere, including "Drive" on S24 (R3-02).

**Android, Play internal testing**
- [ ] ONB-04: fresh install ×5 on the release build. ONB-08: first launch offline, then the store shows real pack counts.
- [ ] Play sandbox: readings_3, readings_10, readings_30, remove_ads, restore, a pending purchase, and no double grant after killing the app mid-purchase.
- [ ] Self-harm question → S27 as the 1st and after quick questions, on the prod Worker.
- [ ] After a refusal, Reflect keeps the declined cards (R3-03).
- [ ] Real banners respect `space.adGap`; the rewarded grant arrives (SSV); UMP in an EEA locale (UMP-01..03).
- [ ] Deep links: `adb shell am start -W -a android.intent.action.VIEW -d "taro://learn/card/major_00" com.vshyrochuk.taro`.
- [ ] Export through the share sheet (Drive or Files) and import back.
- [ ] Largest font and display size: S02, S07 refusal, S08, S14/S16, S26. The back gesture works on every reading screen.
- [ ] uk pick title (R3-01); Celtic labels readable in en, de, ar and uk.
- [ ] No Apple or iOS wording anywhere.

**Owner actions before submission:** set the AdMob consent languages (iOS-R3-01), and decide on fixes for R3-02 (store-review risk), R3-01 and R3-03.

## Counts
- **New this round:** blocker 0, major 0, minor 3 (R3-01, R3-02, R3-03), nit 1 (iOS-R3-02).
- **Carried over and still open:** minor 1 (iOS-R3-01 = iOS-R2-02, owner config), cosmetic 2 (RT-02, RT-03).
- **Regressions:** 0. Round-2 majors in scope: R2-01 and iOS-R2-01 verified fixed.
