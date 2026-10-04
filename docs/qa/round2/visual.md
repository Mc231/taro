# Round 2: Android screenshot tour (method C), visual review

Code under test: HEAD `82bfdfc` (0.1.0+5). Fake-backed tour `integration_test/qa/screenshot_tour_test.dart`, one mode per run.

- **Phone:** AVD `taro-ci-pixel-api36` (emulator-5558, 1080x2400 @420 dpi, Android 16).
- **Tablet:** AVD `Pixel_Tablet` (emulator-5556, 2560x1600 landscape).
- **Why not emulator-5554:** another agent was running A-flows and an iOS build on emulator-5554 and in `apps/taro/build/` at the same time. My first three attempts died with `VmServiceDisappearedException`. All runs here used a clean copy of the tracked sources in the session scratchpad (`taro_r2/`), so the two runs did not share a build folder.
- **Screenshots:** `docs/qa/round2/screenshots/<mode>/`, 72 per mode. That folder is now in `.gitignore`.
- **Logs:** `docs/qa/round2/logs/tour_<mode>.log`.

## Runs

| Mode | Result | Shots | Notes |
|---|---|---|---|
| en_light | 7/7 pass | 72 | |
| en_dark | 7/7 pass | 72 | |
| ar | 7/7 pass | 72 | The first attempt failed with gradle "No space left on device": the host disk had 1 GB free. A later attempt hung on `adb getprop` of the tablet emulator. The re-run was clean. |
| de | 7/7 pass | 72 | |
| ja | 7/7 pass | 72 | |
| uk | 7/7 pass | 72 | New mode. |
| en_text200 | 7/7 pass | 70 + 2 `_FAILED` | `QA_SKIP` S11_store_balance_chip (BalanceChip not hit-testable) and S12_rewarded (no element). At 200 % the rows are off-screen, so this is a tour limitation, not an app bug. |
| tablet en_light | 7/7 pass | 72 | PLT-09 (first tablet tour). |
| tablet ar | 7/7 pass | 72 | |

### Test-only changes (`apps/taro/integration_test/qa/screenshot_tour_test.dart`)

1. Added a `uk` mode.
2. The question is now in the tour's locale. Before, every non-en mode typed the German question, which also put German into ar and ja.
3. Added a flow, `refusal S07 (rephrase + refused)`, that captures the new refusal state:
   - `S07_refusal_rephrase(_end)`: the fake declines with gambling and `canRephrase: true`.
   - `S07_refusal_refused(_end)`: the fake declines with sexual_minors and `canRephrase: false`.

   Both are reached through a real draw → S08 → handoff.

`dart analyze` is clean. The tour has no app code changes.

## New visual findings

Severity: P1 = fix before release, P2 = should fix, P3 = polish.

**V2-01 (P2): Celtic Cross position labels on S08/S32 are illegible in every locale and on tablet.**
- Some labels wrap ("Recent Past", "Near Future", "Hopes and Fears") while their neighbours shrink to about 4 px ("Foundation", "Potential", "Environment", "Outcome").
- The same happens in de ("Jüngste Vergangenheit", "Hoffnungen und Ängste"), ja (最近の過去, 近い未来) and uk ("Недавнє минуле", "Найближче майбутнє").
- In ar the labels run into each other ("الإمكاناتالمستقبل").
- On the tablet the row is the same, with a lot of unused width.
- Evidence: `*/S08_celtic_picked.png`, `*/S32_celtic_top.png`, `tablet_*/S08_celtic_picked.png`.
- This is the BUG-05 follow-up from round 1 ("recheck on a real build"). The tour uses the fake spread's single-row layout. If the real cross layout also falls back to a row, it needs a minimum label size or abbreviations.

**V2-02 (P3): Japanese line breaks leave one- or two-character orphans on many screens.**
- BUG-18 was fixed only for the S27 title.
- Remaining instances:
  - S07 refusal title: "リーディングでき / ません"
  - S07 refusal reason: "予測できませ / ん。"
  - S08 subtitle: "めくってくださ / い。"
  - S02: "中だけ / に"
  - S11: "受け取 / る"
  - S27 helpline subtitle: "相談窓 / 口"
  - S26: "リーディン / グ"
- Evidence: `ja/S07_refusal_rephrase.png`, `ja/S08_picked.png`, `ja/S02_welcome_1.png`, `ja/S11_store_balance_chip.png`, `ja/S27_crisis.png`, `ja/S26_delete.png`.
- A general fix (a BudouX-style phrase wrap or `⁠` joins in the ARB strings) would be better than more one-off patches.

**V2-03 (P3): On the first S07 refusal frame, the explainer line is cut through mid-line by the pinned buttons.**
- The explainer is "Reflecting without a question keeps the cards…". The content scrolls and the line is complete in `_end`, but there is no fade like the S29 tab bar has.
- The en and ar phone shots fit; de, ja and 200 % show the cut.
- Evidence: `de/S07_refusal_rephrase.png`, `ja/S07_refusal_rephrase.png`, `en_text200/S07_refusal_refused.png` (at 200 % the "Not charged" row is cut).

**V2-04 (P3): At 200 % text, a row with a trailing button squeezes its text into a narrow column.**
- S23 "Allowed" with "Withdraw".
- S11 "Remove Banner Ads" with "$3.99".
- At 200 % the button should drop under the text.
- Evidence: `en_text200/S23_privacy.png`, `en_text200/S11_store_end.png`.

**V2-05 (P3): At 200 % text, the S14 and S16 filter chip rows are clipped at the edge with no fade.**
- Visible as "Daily car…" and "C…". The BUG-10 fade was added only to S29.
- On S13 the pill "Free · works offline · no AI" wraps inside itself.
- Evidence: `en_text200/S14_journal.png`, `en_text200/S16_learn.png`, `en_text200/S13_daily.png`.

**V2-06 (P3): At 200 % text, S26 shows almost no list.**
- The pinned field and two buttons leave about one line of "What's erased". The uk phone shot at 100 % shows only a sliver of "Що залишиться".
- Nothing is hidden (the list scrolls), so this is a BUG-09 residual.
- Evidence: `en_text200/S26_delete.png`, `uk/S26_delete.png`.

**V2-07 (P3): S27 shows the raw ISO country code instead of a localised country name.**
- en "Support in US", de "Hilfe in deinem Land: US", uk "Підтримка: US", ja "USの相談窓口", ar "الدعم في US".
- `crisisSupportIn(country)` gets the code. A localised display name would read better.
- Evidence: `*/S27_crisis.png`.

**V2-08 (P3): In ar, "988 Lifeline" renders as "Lifeline 988" on S27.**
- This is bidi reordering of a Latin name that starts with a digit. It needs an LTR isolate (`⁦…⁩`) around resource names.
- Evidence: `ar/S27_crisis.png`, `tablet_ar/S27_crisis.png`.

**V2-09 (P3): On the tablet, S07 and the refusal screen place the balance chip at the far trailing edge of the screen.**
- The content is a centred column about 470 dp wide, and the S09 "Add note" action sits at the screen edge the same way.
- It reads as detached from the content, but it works.
- Evidence: `tablet_en_light/S07_refusal_rephrase.png`, `tablet_en_light/S31_paused.png`.

**V2-10 (P3): uk refusal copy uses "Таро" (tarot) in the reason and "Taro" (the app) in the refused variant.**
- The two words look identical in Cyrillic text, so a reader can't tell the app from the practice. It matches en's "Tarot"/"Taro" split.
- Copy owner to decide.
- Evidence: `uk/S07_refusal_rephrase.png` vs `uk/S07_refusal_refused.png`.

**V2-11 (P3): uk S08/S09 position labels "Минуле Теперішнє Майбутнє" almost touch.**
- There is no visible gap between the three labels.
- Evidence: `uk/S08_picked.png`, `uk/S09_result_top.png`.

**V2-12 (P3): The "Tap to reveal" badge text is very small outside en.**
- de and uk wrap to three lines at about 6 px.
- ja shrinks to about 3 px and is unreadable at half resolution.
- This is the known BUG-06 note, unchanged.
- Evidence: `ja/S08_picked.png`, `uk/S08_picked.png`.

### Not bugs (fake data or tour artefacts)

- These come from the fake deck and fake content:
  - "Card major_17" and the like.
  - The "about" article title.
  - English reading bodies in ar with LTR punctuation (".About swords_14 in past"); this is the known BUG-11 residual.
  - The English question on `ar/S08_celtic_picked` (the celtic flow types `kTestQuestion`).
- de "$2.99" next to "1,00 $": the fake store prices against localised per-reading text. The real Play prices are localised.
- S31 phone: the screen opens slightly scrolled, so the spread label touches the app bar.
- **Ads placement could not be checked.** The fake ads draw no banner (BAN-01), and the tour shows no ad slot. No ad overlaps a reading screen in any shot.

## The new S07 refusal screen

It renders correctly in all 9 runs: en light, en dark, ar, de, ja, uk, 200 %, tablet en and tablet ar.

- **Rephrase variant (gambling):** dice icon, "We can't read this question", the category reason, the "Your question" card with the green "Not charged. Your reading is still available." row, 3 suggestion chips, the explainer, "Rephrase my question" and "Reflect on the cards without a question".
- **Refused variant (sexual_minors):** info icon, the generic "Taro can't help with that.", no chips, only "Ask a different question".
- **Translations:** every string is translated in ar, de, ja and uk.
- **Dark mode:** contrast is good.
- **ar:** fully mirrored, with the chevron on the right and chips laid out RTL.
- **Tablet:** a centred column.
- **Issues:** only V2-02 (ja orphans), V2-03 (pinned-button cut on the first frame) and V2-10 (uk wording).

Evidence: `<mode>/S07_refusal_{rephrase,refused}{,_end}.png`.

## Round-1 fixes re-checked (BUG-03..BUG-20)

| Bug | Status | Evidence |
|---|---|---|
| BUG-03 S08 at 200 % | Still fixed | `en_text200/S08_pick.png`, `S08_picked.png`: no overlap. |
| BUG-04 S02 at 200 % | Still fixed | `en_text200/S02_welcome_1.png`: scrolls, headline clear. |
| BUG-05 Celtic labels | No mid-word breaks, but illegible | See V2-01. |
| BUG-06 Tap to reveal | Not clipped | It is tiny outside en (V2-12). |
| BUG-07 A-flow footer | Not covered by method C | |
| BUG-08 "Vergangenheit" | Still fixed | `de/S08_picked.png`, `de/S09_result_top.png`: one word, slightly smaller. |
| BUG-09 S26 field | Still fixed | The field sits above the buttons in every mode. The list area is cramped (V2-06). |
| BUG-10 S29 tabs | Still fixed | Fade in en, de, ja, uk and ar. The same pattern is missing on S14 and S16 at 200 % (V2-05). |
| BUG-11 RTL punctuation | Still fixed | `ar/S07_question_filled.png`, `ar/S07_refusal_*.png`, `ar/S08_picked.png`: "؟" at the end. |
| BUG-12 S17/S18 header at 200 % | Still fixed | `en_text200/S17_card.png`, `S18_spread_celtic.png`. |
| BUG-13 coachmark at 200 % | Still fixed | `en_text200/S05_home_first_run_coachmark.png`: points at "Start a reading". |
| BUG-14 S30 at 200 % | Still fixed | `en_text200/S30_update_required.png`. |
| BUG-15 FAQ empty search | Still fixed | `*/S28_help.png`: no "No answers match". |
| BUG-16 smoke gate | Not covered by method C | |
| BUG-17 S27 URL at 200 % | Still fixed | `en_text200/S27_crisis.png`: "findahelpline.com" on one line. |
| BUG-18 ja S27 orphan | Still fixed for the title | Orphans remain elsewhere (V2-02). |
| BUG-19 ja S11 chip | Still fixed | `ja/S11_store_balance_chip.png`: the chip is on its own line. uk wraps the chip to 2 lines in the body, which is acceptable. |
| BUG-20 The Fool numeral | Still fixed | `*/S16_learn.png`: "0". |

## Tablet (PLT-09)

Every screen lays out as a centred, readable column with no clipping or overflow, in both en and ar. The issues are V2-01 (Celtic labels) and V2-09 (chip and actions at the screen edge). Many screens leave a lot of empty space on the right in landscape. This is acceptable, but a design pass for two panes could use it.
