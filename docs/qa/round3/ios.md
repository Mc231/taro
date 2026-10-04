# QA round 3: iOS

Date: 2026-10-04. Code at HEAD `abb3035` (TestFlight 0.1.0+6). One simulator at a time, all shut down at the end:

- iPhone 16e, iOS 26.2 (`71126966…`)
- iPad Pro 13-inch (M5) (`DAB71298…`)

Staging Worker with the debug attestation define (`run_ios_explore.sh`); the token was never printed. Logs are in `ios/`. Screenshots are in `screenshots/ios/` (gitignored).

**Verdict:** no blockers and no major bugs. iOS-R2-01 is fixed. The new platform transitions and back behaviour work. One minor new finding (iOS-R3-01) and one copy nit (iOS-R3-02).

## Results

| Area | Result | Evidence |
|---|---|---|
| (1) A: fake-backed flows, iPhone 16e | **22/22 flow tests pass** (17 files under `integration_test/flows/`) | `ios/A_iphone16e_flows.log` |
| (1) perf baselines | pass after a simulator reboot. Cold start: bootstrap 254 ms, first frame 499 ms, first screen 502 ms. S08 build p90 14.3 ms (debug) | `ios/A_perf_after_reboot.log` |
| (2) iPad Pro 13 tour, `en_light` | 72 shots, 0 `_FAILED`, rc 0 | `ios/C_en_light_ipad13_en_light.log`, `screenshots/ios/ipad13_en_light/` |
| (2) iPad Pro 13 tour, `ar` | 72 shots, 0 `_FAILED`, rc 0 | `ios/C_ar_ipad13_ar.log`, `screenshots/ios/ipad13_ar/` |
| (3) iOS exploratory on staging (run 3: fresh install after a simulator reboot) | E0–E6 pass. E7 is blocked by the test (see below) | `ios/E_explore_iphone_run3.out.log`, `screenshots/ios/explore_iphone_run3/flutter_shots/` |

**Perf environment issues, not app bugs.** In the first two A runs, `cold_start_test` hung and `draw_screen_perf_test` timed out waiting for `FrameTiming`. The cause was an "Open in Taro Beta?" system prompt left over from an earlier `simctl openurl` on the long-booted simulator: it covered the app (`screenshots/ios/A_cold_start_hang.png`). After a reboot, both tests passed (`ios/A_perf_after_reboot.log`). The first full run is kept as `ios/A_iphone16e_run1_hung_cold_start.log`.

## (2) iPad checks

- **V2-09 (tablet alignment) holds** on S05, S06, S07, S08, S09, S10 (sheet), S11, S13, S14, S15, S16, S17, S18 and S32, in both en and ar. Content sits in a centred column and the bottom bar spans the full width. ar mirrors correctly.
- **Celtic legend:**
  - `S08_celtic_picked` and `S32_celtic_top` show the 10-position legend (1 Present … 10 Outcome) in en and ar.
  - `S18_spread_celtic` shows the numbered diagram and the 10 descriptions.
  - RT-03 is still there (cosmetic): card 2, which crosses card 1, has no number under the S32 row.
- **Test-data nit (not an app bug):** in `ar`, the Celtic flow still types the English question ("What should I focus on this week?") in `S08_celtic_picked` and `S32_celtic_top`.

## (3) Exploratory on staging

| Step | Result |
|---|---|
| **E0, iOS-R2-01** | **Fixed.** I ran 3 fresh installs (uninstall plus Keychain reset): run 1, run 2, and run 3 after a reboot. Each time I polled Home every 100 ms during onboarding, while waiting for the balance, and for 15 s after. The "unavailable" strings (`balanceUnavailable`, `errorDeviceUnverifiedTitle`, `questionDeviceUnverified`, en and uk) never appeared: `E0 flashes: []` in all 3 runs. Home shows the "1 free reading" chip and the first-run coachmark (`E0_home_en`). |
| **E1a reading (en)** | Three-card reading, completed in 13.8 s, `contentLocale` en (`E1a_result_en`) |
| **E1b, swipe back from S09** | The iOS edge swipe on S09, opened from the draw, lands on Home (S05), never back in S08. Home shows "Free reading used · Next free reading in 2 h 34 min" (`E1b_home_after_swipe`). |
| **E1c, S15 → S09 → back** | These all work: <ul><li>Journal → S15 → "Full reading" → S09</li><li>Close (Done) → back on S15</li><li>"Full reading" again, then edge swipe → back on S15</li><li>Edge swipe on S15 → S14</li></ul>Shots: `E1c_S15`, `E1c_S09_from_S15`, `E1c_S15_after_done`, `E1c_S15_after_swipe`, `E1c_S14_after_swipe`. |
| **E1, Ukrainian switch** | Settings → Language → uk, then back. The whole UI is in uk (`E1_settings_uk`, `E1_home_uk`). |
| **E2 reading (uk)** | Staging grant of +4 bonus (QA_GRANT), then a three-card reading in 14.0 s. `contentLocale` is uk, 3 cards, no Latin strings on S09. Done → Home (`E2_result_uk_top`, `E2_result_uk_bottom`). |
| **E3, journal search and filters (uk)** | pass. Round 2 had this as partial; the sideways-scroll fix in the test made it pass. |
| **E4, Learn, card detail, reversed, zoom, next** | pass |
| **E5, FAQ search and legal tabs (uk)** | pass. Round 2 had this as partial. |
| **E6, deep links** | <ul><li>`taro://learn/card/major_00` → `/learn/card/major_00`, S17 "Блазень" (`E6_deeplink_major_00`)</li><li>`major_99` → `/home`</li><li>`taro://journal/2020-01-01` → S15 "not on this device" with Back</li></ul>`xcrun simctl openurl` raised the iOS "¿Abrir en Taro Beta?" prompt (the simulator is set to Spanish), which shows the scheme is registered. The host can't accept it: osascript has no access to System Events and cliclick has no Accessibility permission. So the test then sends the same URL as the engine's `pushRouteInformation`. That covers the policy and the router, but not the native hand-off: tapping **Abrir** stays manual. |
| **E7, export / import** | Blocked by the test. `exportBackupProvider.call()` now opens the native share sheet itself ("JSON · 8 KB") and waits for it, and the host can't dismiss it (no Accessibility permission). Import and Export are covered by the A flow `export_import_test`, which passes. |

## Findings

**iOS-R3-01, minor (same as iOS-R2-02, still open, owner action):** the UMP consent form ("Our app wants to stay free for you / Continue") shows in English while the app and its question are in uk. It appeared after S04 on every fresh install, as RC18 requires (UMP after S04). The fix is the AdMob console languages listed in `STORE_SUBMISSION.md`. Evidence: `screenshots/ios/explore_iphone_run2/shots/*` and `screenshots/ios/explore_iphone/shots/FAIL_E6.png`.

**iOS-R3-02, nit:** `taro://journal/2020-01-01` is a daily-card date, but the not-found screen says "Цього тлумачення вже немає на цьому пристрої" ("This reading isn't on this device anymore", `readingNotFound`). It is reachable only through a hand-made link. Evidence: `E6_deeplink_journal_missing`.

**Android findings R3-01 and R3-02 also apply on iOS:**
- R3-01: the uk pick title.
- R3-02: "Drive" in the Export caption is visible on iOS.

I didn't re-shoot them here.

## Test changes (not committed, test-only)

- **`integration_test/qa/ios_explore_test.dart`:**
  - New E1a, E1b and E1c steps: an en reading, the S09 edge swipe → Home, and S15 → S09 → Done / swipe → S15 → swipe → S14.
  - An iOS-R2-01 flash watcher.
  - `QA_ONLY` step filter.
  - The tap helper now scrolls sideways (`ensureVisible`), which was the round-2 to-do.
  - In-app Flutter-layer screenshots, because the native screenshots were covered by the UMP form and the "Open in" prompt.
  - Deep links fall back to `pushRouteInformation` injection.
- **Test bug I introduced and fixed in this round:** run 1 ran E1a after the uk switch, so it expected en content in uk. That made the run-1 E1a/E1b failures false. I moved the steps before the language switch, and runs 2 and 3 pass.
- **`integration_test/qa/run_ios_explore.sh`:**
  - Passes `QA_ONLY`.
  - Pulls `tmp/qa_shots/explore` from the app container.
  - Tries Return on the "Open in" prompt, which needs Automation access.
- No app or Worker code changed. No commit.

## Clean-up

- All simulators are shut down.
- `apps/taro/ios/Podfile.lock` is restored (pod install had rewritten the CocoaPods version line).
- `flutter clean` ran in `apps/taro`; 83 GB free.
- Staging spend: 3 free readings (one per fresh install) and 2 bonus readings, with +4 bonus granted to support IDs `6cad159a` (run 1) and `817997d8` (run 3).

## Still manual

- Tap **Abrir** on a real `taro://` link (native hand-off).
- Export share sheet on a device.
- AdMob consent languages (iOS-R3-01).
