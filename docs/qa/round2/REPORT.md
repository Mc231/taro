# E2E test report, round 2 (2026-10-04)

Code under test: HEAD 7e8641f / 82bfdfc (build 0.1.0+5 code). No app or Worker code changed and nothing was committed. Round 1: `../ANDROID_E2E_REPORT.md`. Visual detail: `visual.md`. Evidence paths are relative to `docs/qa/round2/`.

**Devices:**
- Android emulator-5554 for methods A and B.
- A second phone emulator (`taro-ci-pixel-api36`) and `Pixel_Tablet` for the screenshot tour, built from a scratch copy of the sources.
- iPhone 16e simulator for iOS.
- The iPad Pro 13 was not run.

**Environment problems (not app bugs):** several agents shared one adb server and one `apps/taro/build/` folder, which killed some first-pass runs. The host disk then filled to 100 %, which cut short B9c, the iOS exploratory pass and the iPad.

## Summary per area
| Area | Round 1 (+ re-test) | Round 2 | Status |
|---|---|---|---|
| A: 17 fake-backed flows, Android | 16/17, then 17/17 | 17/17. 5 failures from the shared environment on the first pass, all green on the first rerun (`logs/A_summary.txt`, `logs/rerun/summary.txt`) | pass |
| A: fake-backed flows, iOS | not run | 26 pass, 17 skip themselves, rc 0, 17m08s. First screen in 529 ms; S08 frame build 9.4 ms at the 90th percentile (debug build) (`ios/iphone16e_all.log`) | pass |
| B1–B7 on staging | pass (BUG-01 seen in B1) | pass, rc 0, 276 s, no stall on S04 (`B_logs/ALL.out.log`) | pass |
| B8 unverified device | pass | not run | blocked |
| B9 refusal state on staging (new) | — | Health (en, uk), gambling, chips, Rephrase and crisis as the first question pass. Crisis as the 4th question fails (R2-01). "Reflect without a question" and the paced rerun (B9c) were not finished | fail |
| C screenshot tour, 9 modes | BUG-03..20 fixed | 7/7 flows in every mode, 646 of 648 shots | pass, with visual findings |
| Refusal screen visuals | — | Both versions correct in every locale, dark mode, Arabic and tablet; only V2-02, V2-03 and V2-10 | pass |
| iOS exploratory on staging | not run | E0, E1, E2 (Ukrainian three-card reading, 15.1 s) and E4 pass. E3 and E5 partial because the test can't scroll sideways. E6 and E7 blocked by test limits (`ios/explore_iphone/`) | partial |
| iPad flows and ★ screenshots | not run | not run | blocked |
| Ad placement | can't check (fake ads draw no banner) | same; no ad overlaps a reading screen in any shot | manual |

## Round-1 fixes
No regressions. These fixes hold where they were made, but the same problem shows elsewhere:

| Round-1 bug | Round 2 | Follow-up |
|---|---|---|
| BUG-05 Celtic Cross labels | No mid-word breaks, but the labels can't be read | V2-01 |
| BUG-06 Tap to reveal | Not clipped, but tiny | V2-12 |
| BUG-09 S26 field | Field still fixed; the list above it is cramped | V2-06 |
| BUG-10 tab fade | Fade on S29 only | V2-05 |
| BUG-18 ja orphan | Fixed on the S27 title only | V2-02 |

All other round-1 fixes still hold, including BUG-01 (B1) and BUG-07 (A on Android and iOS).

## New bugs (repro, evidence and suspected file)

**R2-01, major (safety)**
- **Repro:** on staging, ask 3 declined questions within about 60 s, then a self-harm question. The app shows "We couldn't create your reading / Try again" instead of S27. A gambling question in that position fails the same way.
- **Evidence:** `B_logs/B9.out.log`, `B_logs/B9b.out.log`. `daily_usage` shows `declined_count=3`, so the daily declined limit was not reached.
- **Suspected file:** `worker/src/services/ReadingService.ts:303`. `perMinuteGate` runs before `prefilter` (around line 548). The limit is 6 holds plus readings per minute (`worker/wrangler.toml`), and each declined question uses 2.
- **Fix direction:** run the crisis prefilter before the rate limits.

**V2-01, major**
- **Repro:** in the tour, Celtic Cross labels on S08 and S32 shrink to about 4 px or wrap, and in Arabic they run into each other.
- **Evidence:** `screenshots/*/S08_celtic_picked.png` and `screenshots/*/S32_celtic_top.png`. The tour uses the fake single-row layout, so check the real cross layout before fixing.
- **Suspected file:** the Celtic slot label fitting in `apps/taro/lib/features/reading/view/`, which has no minimum size.

**iOS-R2-01, major (needs confirming)**
- **Repro:** fresh install on the iOS staging flavor. Home says "Readings unavailable on this device" while the balance shows 1 free reading; the next screen is correct.
- **Evidence:** `ios/explore_iphone/shots/E0_home_en.png`, then `E1_home_uk.png`.
- **Suspected file:** `apps/taro/lib/features/home/controller/home_controller.dart`; possibly related to 81a974f and 6a6f0be.
- **Why it matters:** this could be the first screen a store reviewer sees.

**R2-02, minor**
- **Repro:** hit the per-minute limit (as in R2-01). The app shows the generic failure with "Try again".
- **Suspected file:** the failure mapping in `apps/taro/lib/features/reading/controller/`, where rate limits get no copy of their own.

**R2-03, minor (release gate)**
- **Repro:** open S27. It shows "Last checked January 1970".
- **Cause (confirmed in code):** every entry in `crisis_resources.json` has `verifiedAt: null`. `asset_crisis_resources_repository.dart:54` maps that to the epoch date, and `crisis_resources_screen.dart:128-183` displays it.
- **Fix:** hide the line for unverified entries, or finish verifying the hotlines (Phase 18.4) before release.

**iOS-R2-02, minor**
- **Repro:** fresh install with the app in Ukrainian. The ad-consent message stays in English.
- **Evidence:** `ios/explore_iphone/shots/`.
- **Suspected cause:** the AdMob console language settings, not app code. Also check the wording against RC59.

**V2-03, minor**
- **Repro:** the first refusal frame in de, ja or 200 % text. The pinned buttons cut through a line of text with no fade; it scrolls fine.
- **Evidence:** `screenshots/{de,ja,en_text200}/S07_refusal_*.png`.
- **Suspected file:** `features/reading/view/question_screen.dart`.

**V2-04, minor**
- **Repro:** at 200 % text, rows with a trailing button squeeze their text into a narrow column.
- **Evidence:** `screenshots/en_text200/`.
- **Suspected file:** the shared row component in `taro_ui`.

**V2-05, minor**
- **Repro:** at 200 % text, the S14 and S16 chip rows are clipped at the edge with no fade.
- **Evidence:** `screenshots/en_text200/S14_*.png` and `S16_learn.png`.

**V2-06, minor**
- **Repro:** at 200 % text, S26 shows almost none of its list.
- **Evidence:** `screenshots/en_text200/S26_delete.png`.

**V2-07, minor**
- **Repro:** S27 says "Support in US" instead of the country name.
- **Suspected file:** `crisis_resources_screen.dart:159`, which passes the country code.

**V2-10, minor (copy decision)**
- **Repro:** the Ukrainian refusal copy uses "Таро" (tarot) in one version and "Taro" (the app) in the other.
- **Evidence:** `screenshots/uk/S07_refusal_*.png`.
- **File:** `app_uk.arb`.

**Cosmetic**
- **V2-02:** Japanese orphans on about 7 screens (`screenshots/ja/`). A general fix would be better than more one-off patches.
- **V2-08:** in Arabic, S27 shows "Lifeline 988" (`screenshots/ar/S27_crisis.png`); the text direction needs isolating.
- **V2-09:** on the tablet, the balance chip and "Add note" sit at the far edge (`screenshots/tablet_*`).
- **V2-11:** the Ukrainian S08/S09 position labels almost touch (`screenshots/uk/S08_picked.png`).
- **V2-12:** "Tap to reveal" is tiny in de, ja and uk.

**Not bugs:** the iOS "slide to type" keyboard tip, and the two screens the tour can't reach at 200 % text.

## Test-only changes (not committed)
- **`staging_e2e_test.dart`:** new case B9, waiting `QA_PACE_S` seconds between questions.
- **`screenshot_tour_test.dart`:**
  - added a `uk` mode;
  - added a refusal flow that captures both versions;
  - made the typed question match the locale. This fixes a test bug: every non-English mode typed the German question.
- **New `ios_explore_test.dart` and `run_ios_explore.sh`.**
- **`.gitignore`:** added `docs/qa/round2/screenshots/`.
- **Still to fix in `ios_explore_test.dart`:**
  - make the tap helper scroll sideways (`ensureVisible`);
  - start the export without waiting for the share sheet, and make it the last step;
  - send the deep link from inside the test as well.

## To finish
1. `QA_GRANT=1 OUT=docs/qa/round2/B_logs apps/taro/integration_test/qa/run_staging_e2e.sh B9c '^B9 '`
2. Run B8 (unverified device).
3. iPad Pro 13: run the flows and the ★ screenshots.
4. Rerun iOS E3, E5, E6 and E7 after the test fixes.
5. Give each agent its own device and its own build folder, and keep at least 20 GB free.

## Manual checklist

**iPhone, TestFlight build 5**
- [ ] Fresh install ×3: Home never says "unavailable" when a free reading is available (iOS-R2-01).
- [ ] The consent message is in the device language, followed by the neutral pre-prompt and then ATT (iOS-R2-02, RC18/19/59).
- [ ] Single and three-card free readings work end to end; the disclaimer and S09 footer are reachable.
- [ ] Refusal: health and gambling questions get the refusal card; chips, Rephrase and "Reflect without a question" work; the balance doesn't change.
- [ ] A self-harm question shows S27 both as the first question and after 3–4 quick questions (R2-01). On S27, check the "Last checked" line (R2-03), the country name (V2-07) and that tap-to-call works.
- [ ] Celtic Cross labels are readable on the real layout (V2-01).
- [ ] Sandbox purchases: packs, remove_ads and restore. The balance changes only after the Worker grant.
- [ ] Rewarded ad never shows on its own; banners never sit over a reading.
- [ ] Deep link `taro://learn/card/major_00` opens the card.
- [ ] Journal export and import work.
- [ ] Swipe back works; the largest Dynamic Type works on S07, S08, S09 and S26.
- [ ] iPad: centred layout and V2-09.
- [ ] No Android or Google wording anywhere.

**Android, Play internal testing**
- [ ] ONB-04: fresh install ×5 on the release build.
- [ ] ONB-08: first launch offline; the store shows real pack counts.
- [ ] Play sandbox: readings_3, readings_10, readings_30, remove_ads, restore, a pending purchase, and no double grant after killing the app mid-purchase.
- [ ] R2-01: crisis after quick questions shows S27. R2-03: the "Last checked" line.
- [ ] Celtic Cross labels readable on the real layout in en, de, ar and uk (V2-01).
- [ ] Real banners respect `space.adGap`; rewarded grant works; UMP in an EEA locale (UMP-01..03).
- [ ] Deep links via `adb shell am start -W -a android.intent.action.VIEW -d "<uri>" com.vshyrochuk.taro`.
- [ ] Largest font and display size: S02, S07 refusal, S08, S14/S16 (V2-05), S26 (V2-06).
- [ ] The back gesture works on every reading screen.
- [ ] No Apple or iOS wording anywhere.

## Counts
Blocker 0, major 3, minor 9, cosmetic 5 (17 total). Round-1 regressions: 0.

## Re-test after fixes (2026-10-04)

Nothing committed or deployed. Disk had 34 GB free, so I ran `flutter clean` in `apps/taro` (removed `build/`, 9.3 GB, and again after the device runs). DerivedData held only 1.3 MB, so I left it. Evidence is under `retest/`; screenshots are gitignored.

**Gates:** full `tools/verify.sh` (format, analyze, every check, `test:coverage` with goldens, worker vitest, tools pytest, native) and coverage ≥ 90 % for every unit. The first run failed on one bug that the fixes introduced, now fixed:
- **RT-01:** the V2-02 word joiners were also added to the ja `nsUserTrackingUsageDescription`, so it no longer matched `ios/Runner/ja.lproj/InfoPlist.strings` (`check_manifests`, `test_check_manifests::test_real_repository_passes`). Now `check_ja_linebreak` keeps native `ns…` keys free of joiners, and the ARB value is restored. Tests: `test_native_strings_carry_no_joiners` and `test_real_repository_ja_att_string_matches_info_plist`, both of which failed first.

**Device (Android emulator-5554, one run at a time):**
- **B1** fresh onboarding on staging: pass (`retest/B_logs/B1.out.log`). S05 shows the used free reading and its countdown, with no "unavailable" text.
- **B9 on staging with `QA_PACE_S=0`** (`retest/B_logs/B9_fast.out.log`):
  - All of these pass, with no change to the balance: crisis as the first question, health en and uk, chips, Rephrase, gambling, and crisis as the 5th question within about 30 s.
  - The 6th question in that minute stopped at the hold with S07 "Please wait a moment and try again". That is the expected hold limit; staging still runs the old Worker.
  - "Reflect without a question" therefore wasn't reached.
  - The Cloudflare limiter is approximate, so on the old staging Worker this run did not reproduce R2-01.
- **R2-01 on the fixed Worker, local `wrangler dev`:**
  - On device, crisis as the first question goes to S27. The refusal cases can't run locally because the fake AI never refuses.
  - API burst of 7 self-harm questions back to back: #1–#6 are declined with crisis resources, #7 hits the hold limit (`retest/logs/R2-01_local_api.txt`). Before the fix, #4 failed.
- **Screenshot tour** of main, Celtic and refusal flows in en_light, ar, uk, ja and en_text200: 3/3 flows pass in every mode, 278 shots (`retest/screenshots/`, `retest/logs/tour_*.log`). I looked at S05, S08, S08/S32 Celtic, S07 refusal (both versions), S14, S16, S26 and S27 in every mode.

| Bug | Fix | Re-test | Status |
|---|---|---|---|
| R2-01 crisis hidden by the per-minute limit | Worker: L1 crisis check before `RL_READINGS`; a reading under a live hold is counted once | Worker integration tests (failed first); local Worker burst 6/6 crisis; staging run did not reproduce | **fixed, verified locally; pending staging deploy**. Limit: a 7th question in the same minute is still stopped at the hold (needs an API change) |
| R2-02 rate limit shows the generic failure | S08 shows "Please wait a moment" for a per-minute 429 | widget test; not reached on device | fixed (tests) |
| R2-03 "Last checked January 1970" | line hidden while any entry is unverified | widget and core tests (the tour fakes use verified dates) | fixed (tests); hotline verification is still Phase 18.4 |
| iOS-R2-01 Home "unavailable" on first launch | registration re-read on every sync change | controller tests; Android B1 clean; iOS not re-run (no simulator this round) | fixed (tests), **needs an iPhone check** |
| iOS-R2-02 consent message in English | owner steps in `STORE_SUBMISSION.md` (AdMob languages) | — | **open (owner, AdMob console)** |
| V2-01 Celtic labels | caption minimum, numbers plus legend | S08/S32 Celtic in en/ar/uk/ja/200 %: legend readable, no overlap | verified |
| V2-02 ja orphans | `check_ja_linebreak` | ja S05/S07/S08/S14/S26/S27: no single-character orphans | verified |
| V2-03 refusal text under the buttons | `TaroScaffold` bottom fade | S07 refusal uk/200 %: text fades above the buttons | verified |
| V2-04 200 % row squeeze | button under the text above 1.5× | S11/S23 not in this tour; golden and widget tests | fixed (tests) |
| V2-05 chip rows clipped | `TaroScrollRow` | S14/S16 at 200 % and in uk/ja: edge fade | verified |
| V2-06 S26 at 200 % | footer scrolls above 1.5× | S26 at 200 %: title, text and list visible | verified |
| V2-07 "Support in US" | `crisisCountryName` | S27: "Support: United States", "Підтримка: США", "アメリカ合衆国の相談窓口", Arabic name | verified |
| V2-08 ar "Lifeline 988" | bidi isolation | ar S27: "988 Lifeline" | verified |
| V2-09 tablet app bar | capped to the content column | tablet not run this round; golden tests | fixed (tests) |
| V2-10 uk "Таро" vs "Taro" | "Карти таро" | uk S07 refusal: "Карти таро не можуть…" | verified |
| V2-11 uk labels touch | gap of at least `space.3` | uk S08: labels separate | verified |
| V2-12 tiny "Tap to reveal" | hint at caption size, or left out | en/ar/ja hint readable on the first card; uk "Відкрити" is left out on the 3-card phone row | verified, see RT-02 |

**Leftovers seen in the shots (cosmetic, not fixed):**
- **RT-02:** in uk the first three-card S08 card shows no hint at phone width, because "Відкрити" doesn't fit. The gold outline and subtitle still guide the user.
- **RT-03:** on the tour's fake single-row Celtic layout, the crossed card (2) has no number under it ("1 _ 3"). The legend still lists it. The real cross layout is covered by `qa_round2_layout_test.dart`.

**Still to do:**
1. Deploy the Worker to staging, then run `QA_GRANT=1 QA_PACE_S=0 run_staging_e2e.sh B9 '^B9 ' fresh`.
2. iPhone fresh install ×3 for iOS-R2-01.
3. AdMob consent languages (iOS-R2-02).
4. Tablet and iPad pass for V2-09.
5. B8.

**Test-only change:** `run_staging_e2e.sh` passes `QA_PACE_S` through to the test.
