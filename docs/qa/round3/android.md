# E2E round 3, Android (2026-10-04)

Code under test: HEAD abb3035 (build 0.1.0+6 code). The staging Worker includes the fix that runs the crisis check before the rate limits. No app or Worker code was changed and nothing was committed.

**Devices:** one at a time: emulator-5554 as `Pixel_9a` (1080×2424), then `Pixel_Tablet` (2560×1600) for the tablet tour.

**Disk:** 80 GB free at the start, so no clean was needed before the runs. `flutter clean` ran in `apps/taro` at the end.

Evidence paths are relative to `docs/qa/round3/`. Screenshots are under `screenshots/<mode>/` and are gitignored.

## Summary
| Area | Result | Evidence |
|---|---|---|
| A: 17 fake-backed flows | **17/17 pass.** On the first pass, `kill_switch` and `os_restore` hit environment errors: "Failed to start Dart Development Service", and adb showed the device as unsupported for a moment. Both passed when rerun. | `logs/A/summary.txt`, `logs/A/rerun_*.log` |
| B1–B7 on staging, fresh install, `QA_GRANT=1` | **7/7 pass**, rc 0, 201 s, `BUGS []` for every case | `B_logs/ALL.out.log`, `ALL.host.log` |
| B8 unverified device | **pass**, rc 0, 56 s. S05 shows "Readings unavailable on this device / Try again"; Learn works | `B_logs/B8.out.log` |
| B9 refusal and crisis on staging, `QA_PACE_S=0` | **pass** on the second run, rc 0, 216 s, `BUGS []`. The first run failed at the last step because the test was wrong (see "Test-only changes") | `B_logs/B9.out.log`, `B_logs/B9_run1.out.log` |
| C screenshot tour on phone: en_light, en_dark, ar, de, ja, uk, en_text200 | **7/7 flows in every mode**, 504 shots, 1 `_FAILED` | `logs/tour_summary.txt`, `screenshots/<mode>/` |
| C screenshot tour on Pixel_Tablet: en_light, ar | **7/7 flows**, 144 shots, 0 `_FAILED` | `screenshots/tablet_*` |

The one `_FAILED` shot is `en_text200/S11_store_balance_chip`: the BalanceChip is not hit-testable at 200 % text. This is the same known tour limit as in round 2, not an app bug.

### B9 detail
All questions were asked in one burst with no pacing, in this order:
1. Crisis as the first question goes to S27 "You're not alone" with Lifeline Ukraine 7333 (the device timezone is Europe/Kiev).
2. Health (en) shows the refusal card: the reason, "Not charged", 3 chips and "Reflect".
3. Tapping a chip fills the field.
4. Health (uk) shows the refusal card. **Rephrase** keeps the question.
5. **Crisis as the 4th question goes to S27.**
6. Gambling shows the refusal card.
7. **Crisis as the 6th question goes to S27.** This is R2-01, now verified on staging.

The balance stayed at bonus 4 through all seven steps.

After a 65 s wait for the per-minute limit, the test asked health (uk) again and tapped **"Reflect on the cards without a question"**. The app went to S08 (shuffle, with the declined cards preset) and then to S09, which showed an AI reading 11.2 s after the tap. That reading cost 1 credit (bonus 4 → 3), which is expected for a real reading.

Draw-to-refusal took 3.8–4.7 s and draw-to-S27 took 1.5–2.7 s.

## Re-check of round-1 and round-2 fixes
| Item | Round 3 |
|---|---|
| R2-01 crisis hidden by the per-minute limit | **verified on staging**: S27 shows as the 1st, 4th and 6th question in one burst |
| R2-02 rate-limit copy | not hit (no 429 in the burst) |
| R2-03 "Last checked January 1970" | the tour fakes show "Last checked September 2026". Staging S27 shows no 1970 line |
| iOS-R2-01 Home "unavailable" | Android B1: S05 shows "Free reading used / Next free reading in 5 h 7 min" and no "unavailable" text. iOS not in scope |
| V2-01 Celtic labels | numbers plus a readable legend in every mode, including ar, uk and ja at 200 % and on the tablet |
| V2-02 ja orphans | none seen in ja |
| V2-03 refusal text under the buttons | fade above the pinned buttons in de, ja, uk and 200 % |
| V2-04 200 % rows | the "Copy ID" button and the toggle rows wrap correctly at 200 % |
| V2-05 chip rows | S14 and S16 rows fade at the edge (uk "Обране", 200 % "Daily car…") |
| V2-06 S26 at 200 % | title, text and list are visible |
| V2-07 country name | "Support: United States", "Підтримка: США", and the Arabic name |
| V2-08 ar "988 Lifeline" | correct on phone and tablet |
| V2-09 tablet app bar | the balance chip and "Add note" now sit in the content column (tablet S05, S07, S09, S11) |
| V2-10 uk "Карти таро" | correct |
| V2-11 uk labels touch | the labels are separate |
| V2-12 "Tap to reveal" | readable on the first card in en, de, ja, ar and on the tablet |
| BUG-01 to BUG-20 (round 1) | no regressions seen |
| **RT-02** uk 3-card hint | **still present (cosmetic):** uk `S08_picked` shows no "Відкрити" hint at phone width; the gold outline still guides |
| **RT-03** "1 _ 3" on the fake Celtic row | **still present (cosmetic, tour fake layout):** card 2 has no number in `S08_celtic_picked` and `S32_celtic_top` in every mode, but the legend lists it |

## New findings
**R3-01, minor (copy, uk)**
- **Repro:** in uk, open the S08 pick step with 0 cards picked. The title says "Виберіть ще 3 карти" ("Pick 3 **more** cards"); the en text is "Pick 3 cards".
- **Evidence:** `screenshots/uk/S08_pick.png`.
- **File:** `apps/taro/lib/l10n/arb/app_uk.arb:321` (`drawPickTitle`). "ще" is right only for the `one` case.

**R3-02, minor (store-review wording, RC39 / rule 19)**
- **Repro:** S24 Export shows "Opens the share sheet: Files, Drive, email and more."
- **Why it matters:** the same ARB string is used on iOS, so Apple-facing text names Google Drive. In uk it reads "Диск".
- **Evidence:** `screenshots/*/S24_export.png`.
- **File:** `apps/taro/lib/l10n/arb/app_*.arb` (`exportButtonCaption`), used in `features/backup/view/export_screen.dart:84`. Fix: a neutral caption, or a variant per platform.

**R3-03, minor (UX)**
- **Repro:** after a refusal, tap "Reflect on the cards without a question". S08 comes back with "Shuffle the deck" and "I'm ready — draw", although the declined cards are already preset.
- **Why it matters:** this can make the user think they will get new cards. The refusal copy says the cards are kept.
- **Evidence:** `B_logs/B9.out.log` (line "reflect S08:").
- **File:** `features/reading/controller/question_controller.dart:480` (`reflectWithoutQuestion` → `begin()`). The draw screen could skip the shuffle and pick steps for preset cards.
- Not verified: whether the S09 cards equal the declined cards.

**Not bugs** (artifacts of the fakes or the emulator):
- S19 title "about" in lower case: the fake article title. The real `assets/deck/en.json` article starts with "# About tarot and Taro".
- S28 `support@example.com`: the test-helper config. Staging and prod use the real address.
- S10 "Prices unavailable — retry" and `PRODUCT_UNAVAILABLE`: there is no Play billing on the emulator.
- B2 rewarded outcome is "Your reading will appear shortly" (`grantDelayed`): the sample ad sends no reward callback (SSV), as in round 1.
- In the B9 logs the health (uk) refusal text is in English because the app language is en.

**Look-through:** every shot was viewed as a contact sheet:
- all 72 shots in each of the 7 phone modes;
- the tablet en_light and ar shots.

There were no overlaps, no clipped controls without a fade, no text over the bottom navigation, and no ads over reading content. Dark mode keeps contrast on S07, S08, S09, S11 and S27.

## Test-only changes (not committed)
- **`apps/taro/integration_test/qa/staging_e2e_test.dart`, B9:**
  - **Crisis 4th and 6th:** crisis is now asked as the 4th and 6th question (after health uk, and after gambling), as the round-3 task required.
  - **Wait before Reflect:** the test waits 65 s before the Reflect step when `QA_PACE_S` < 60.
  - **Test bug fix:** after "Reflect without a question", the test now waits for S08 and draws, then expects S09. The old test expected S09 straight away. Per 01 §7.5 and `reflectWithoutQuestion`, Reflect runs Begin again with the cards preset, so the old test was wrong. It timed out in `B_logs/B9_run1.out.log`.
- **`.gitignore`:** `docs/qa/round3/screenshots/`.

## Counts
Blocker 0, major 0, minor 3 (R3-01..03), cosmetic 2 still open (RT-02, RT-03). Regressions: 0.
