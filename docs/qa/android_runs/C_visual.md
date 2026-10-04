# C: visual screenshot tour on Android

- **Date:** 2026-10-04
- **Device:** emulator-5554 (Pixel_9a AVD, Android 16, 1080×2424)
- **Build:** dev flavour, `TARO_ENV=test` (fake-backed, same harness as `integration_test/flows`)
- **Test:** `apps/taro/integration_test/qa/screenshot_tour_test.dart`, run once per mode with `--dart-define=QA_MODE=<mode>`
- **Screenshots:** `docs/qa/android_runs/screenshots/<mode>/<shot>.png`, 68 per mode, saved at half resolution (540×1212)
- **Logs:** `docs/qa/android_runs/logs/C_tour_<mode>.log` and `C_summary*.txt`

## Run status

| Mode | Result | Shots | Notes |
|---|---|---|---|
| en_light | 6/6 tests pass | 68 | |
| en_dark | 6/6 pass | 68 | |
| ar (RTL) | 6/6 pass | 68 | |
| de | 6/6 pass | 68 | |
| ja | 6/6 pass | 68 | |
| en_text200 (text scale 2.0) | 6/6 pass | 68 | `S11_store_balance_chip_FAILED.png`: at 200 % the Home BalanceChip was not hit-testable after `go(/home)`. This is a tour-step skip, not a confirmed bug. |

**Coverage.** All 33 screens S01–S33 were captured in every mode. The tour also captured these states:
- S05: coachmark, empty, with a reading
- S07: empty, filled, Celtic Cross, after decline
- S08: shuffle, shuffling, pick, picked, Celtic Cross picked
- S09: top, mid, footer, menu
- S10, S11 and S12 (rewarded, granted)
- S13: before and after reveal
- S04: re-entry
- S29: all three tabs
- S31 and S32 (3-card and Celtic Cross)

**Not covered:**
- **S01** is too short-lived to capture. `S01_launch.png` already shows S02.
- **Welcome pages 2 and 3** were not captured. S02 has no `PageView`; the dots are the onboarding stepper.
- **Banner ads** can't be checked in this harness. The fake ads service renders no banner, so ad overlap and `space.adGap` were not verified. That needs the staging build (B/M).

## Fake-environment artefacts (not app bugs; recheck on a real build)

The fake content repository and the fake Worker cause these:
- Card names show as "Card major_17" or "Card swords_04". Meanings read "The upright meaning of major_17", and keywords show as "r+", "w+", "g+".
- Readings are English placeholder text ("A turning point", "About swords_14 in past.") in every locale.
- **Card faces are blank everywhere:** S09, S13, S15, S16, S17, S32. The real art exists in `assets/deck/art/codex_v1` (81 files), but the fakes don't load it.
- The S19 title is "about" and the page has no body, because the fake article is empty. The real `assets/deck/en.json` has an `about` article.
- S28 shows no FAQ entries, because the fake FAQ is empty. The real `faq` article exists.
- Prices are fake "$2.99" strings, including in de, ar and ja. The real Play billing prices are localised.
- The welcome hero label reads "Card major_17", or "Card major_…" in ja.

## Findings

Severity: **P1** = visible defect a store reviewer or user would notice; **P2** = cosmetic or edge case.

| # | Sev | Screen / mode | Finding | Screenshot(s) |
|---|---|---|---|---|
| V1 | P1 | S10, S11 / all | **The store shows "0 readings" for every pack, and S10 says "From $2.99 for 0".** `StorePack.credits` is null in the compiled default config, and `paywall_catalog.dart:217` maps that with `pack.credits ?? 0`. Any user whose `GET /v1/config` hasn't succeeded yet (first launch offline, config fetch failure) sees "0 readings · $2.99". The pack should be hidden, or shown without a count, when credits are unknown. | `en_dark/S11_store.png`, `en_dark/S10_out_of_readings.png`, `de/S11_store.png`, `ar/S11_store.png`, `ja/S10_out_of_readings.png` |
| V2 | P1 | S08, S32 Celtic Cross / all locales | **Position labels under the 10-card mini layout break character by character:** "Pres/ent", "Fou/ndat/ion", "Hop/es and/Fear/s". In de: "Geg/enw/art". In ja: "最近の過/去". The cards themselves are tiny. A wider label area, a smaller label style or a two-row layout is needed. | `en_dark/S08_celtic_picked.png`, `en_dark/S32_celtic_top.png`, `de/S08_celtic_picked.png`, `de/S32_celtic_top.png`, `ar/S08_celtic_picked.png`, `ja/S08_celtic_picked.png` |
| V3 | P1 | S08, S09, S15 3-card / de | **"Vergangenheit" (Past) breaks mid-word as "Vergangen / heit"** under the 3-card slots and the result mini layout. | `de/S08_pick.png`, `de/S08_picked.png`, `de/S09_result_top.png` |
| V4 | P1 | S08 picked / en, de, ja, 200 % | **The "Tap to reveal" hint inside the first face-down card is clipped:** "Tap to revea", "Aufdecken t", "ップしてめく", and "to rev" at 200 %. | `en_dark/S08_picked.png`, `de/S08_picked.png`, `ja/S08_picked.png`, `en_text200/S08_picked.png`, `en_text200/S08_celtic_picked.png` |
| V5 | P1 | S08 / 200 % | **The draw screen overlaps itself at text scale 2.0:**<br>- **Pick:** the third slot is hidden behind the card fan.<br>- **Picked:** the question text runs under the "Reveal all" button.<br>- **Celtic Cross:** the list of position rows runs into "Reveal all".<br>S08 is a ★ screen, so this fails the 200 % rule (CLAUDE.md rule 16). | `en_text200/S08_pick.png`, `en_text200/S08_picked.png`, `en_text200/S08_celtic_picked.png` |
| V6 | P1 | S02 / 200 % | **The Welcome headline "A quiet place to reflect with tarot" is cut off by the "Get started" button.** The three feature bullets aren't visible at all; the page doesn't scroll or shrink. | `en_text200/S02_welcome_1.png`, `en_text200/S01_launch.png` |
| V7 | P2 | S28 / all | **With an empty search, the FAQ shows "No answers match “”"** (de: „“, ar: «»). An empty query should list all entries, or show a neutral empty state, not a no-match message with empty quotes. In this harness the fake FAQ is empty; recheck with real content. | `en_dark/S28_help.png`, `de/S28_help.png`, `ar/S28_help.png` |
| V8 | P2 | S26 / all, worse in ja and at 200 % | **The "Type DELETE to confirm" label and field sit below the fold**, half hidden behind the pinned Delete/Cancel buttons. The screen is a `ListView`, so it scrolls, but the required input isn't discoverable without scrolling. In ja the label isn't visible at all. | `en_dark/S26_delete.png`, `de/S26_delete.png`, `ja/S26_delete.png`, `en_text200/S26_delete.png` |
| V9 | P2 | S29 / all | **The Legal tab bar cuts off the outer tabs:** "Ope", "Open-source lice", "Datenschutzer", "aimer", "Privac". The bar scrolls, but there's no fade or indicator that it does. | `en_dark/S29_legal_disclaimer.png`, `en_dark/S29_legal_privacy.png`, `de/S29_legal_disclaimer.png`, `en_text200/S29_legal_terms.png` |
| V10 | P2 | S07, S08, S09 / ar | **An LTR question shown in RTL puts its punctuation on the wrong side:** "?What should I focus on this week", "«?Was soll ich heute beachten»". The field and quote should use the text's own direction (for example `TextDirection` from the content, or a bidi isolate). | `ar/S07_question_filled.png`, `ar/S07_after_decline.png`, `ar/S08_celtic_picked.png`, `ar/S09_result_top.png` |
| V11 | P2 | S17, S18 header / 200 % | **The centred header text overflows into the prev/next arrows:** "Major Arcana · 18 [of 22 cut]", "Spreads guide · 6 [of 6 cut]". | `en_text200/S17_card.png`, `en_text200/S18_spread_celtic.png` |
| V12 | P2 | S27 / 200 % | **The URL "findahelpline.com" breaks mid-word as "findahelpline.c / om".** | `en_text200/S27_crisis.png`, `en_text200/S27_crisis_end.png` |
| V13 | P2 | S27 / ja | **The title wraps with a one-character orphan:** "あなたはひとりではありませ / ん". | `ja/S27_crisis.png` |
| V14 | P2 | S11 / ja | **The balance chip "無料リーディング使用済み・リーディング1回" wraps onto two lines** in the app bar and crowds the close button. | `ja/S11_store_balance_chip.png`, `ja/S12_rewarded.png` |
| V15 | P2 | S05 coachmark / 200 % | **The first-run coachmark covers almost the whole screen.** The card it points to ("Ask the cards a question") is pushed below the fold behind the nav bar, so the arrow points at nothing visible. | `en_text200/S05_home_first_run_coachmark.png` |
| V16 | P2 | S30 / 200 % | **The "Your journal is safe" panel is cut off by the pinned Update button.** It is reachable by scrolling (`ListView`), but at first view it looks clipped. | `en_text200/S30_update_required.png` |
| V17 | P2 | S16 / all | **Card 0 (The Fool) shows "○" as its numeral.** Confirm this glyph is intended; the usual forms are "0" or none. | `en_dark/S16_learn.png`, `ar/S16_learn.png` |

## Checked with no defect found

- **RTL (ar):** these mirror correctly:
  - back chevrons point right
  - tab bar order is reversed
  - balance chip sits at the start
  - Celtic Cross numbering runs 10→1 in S18
  - S08 slot order runs right to left
  - 12-hour times are localised ("9:00 ص")
- **Dark mode:** no unreadable text found on S04, S07, S09, S10, S11, S13, S20, S26 or S27.
- **Disabled states:**
  - S07 Begin after decline
  - S26 Delete before the user types DELETE
  - S33 Send before a reason is chosen
- **Compliance copy is present on every reading screen:**
  - disclaimer footer: S08, S09, S10, S11, S32
  - "AI-generated" tag: S09, S15
  - "Classic reading" label: S32
  - S10 has no fake urgency: the countdown comes from the server reset ("Next free reading in 12 h 0 min (at 9:00 PM)") and the close button is always visible
- **S04 consent:** the two buttons have equal weight and nothing is pre-checked. The copy names OpenAI and the retention periods (7 days, 90 days).
- **Android-specific copy:** S30 says "Opens Google Play". Settings has no ATT row.
- **No untranslated UI strings in de, ar or ja.** The only English text in those modes comes from the fake content and fake readings listed above.

## Rerun

```bash
cd apps/taro
flutter test integration_test/qa/screenshot_tour_test.dart --flavor dev \
  --dart-define-from-file=config/dev.json --dart-define=TARO_ENV=test \
  --dart-define=QA_MODE=<en_light|en_dark|ar|de|ja|en_text200> -d emulator-5554
```

Shots are written to the app's `code_cache/qa_shots/<mode>/`. While the test runs, pull them with:

```bash
adb exec-out run-as com.vshyrochuk.taro.dev tar -cf - -C code_cache qa_shots | tar -xf -
```

The test waits 20 s before it finishes so the pull can complete; `flutter test` uninstalls the app at the end.
