# Accessibility and RTL audit (Phase 19.4)

Requirements: 01 §12 (accessibility, WCAG 2.2 AA baseline) and §13 (RTL and localization), with the motion tokens in 01 §14.4. This report has two parts. The automated part is in §1–§3; it runs in `flutter test` on every push. The screen-reader passes need real devices, so they are **MANUAL** and stay open in §4 until the owner runs them.

## 1. Maximum text size (automated)

File: `apps/taro/test/a11y/max_text_scale_test.dart`. Shared helpers are in `apps/taro/test/a11y/a11y_support.dart`.

- **Scales.** Android's maximum is 200 % (`kAndroidMaxTextScale`). The iOS maximum is AX5, `53 / 17` ≈ 312 % (`kIosAx5TextScale`).
- **Setup.** Each screen is built through `buildScreen`, with fakes, at `kPhoneSmall`. S09 uses the canvas sample (`three_ppf.json`), which is the longest committed reading.
- **How it checks.** `expectNoClippingWhileScrolling` scrolls every vertical page from top to bottom, one viewport at a time. At each stop it fails on any `FlutterError`, which catches overflow. It also fails on any `RenderParagraph.didExceedMaxLines`, which catches ellipsis or clipping, including a single word that is wider than its box.

| Screen | 200 % | AX5 (312 %) | Notes |
|---|---|---|---|
| S05 Home (`content`, recent reading) | pass | pass | fixed in this sprint, see §5 |
| S07 Question (`editing`) | pass | pass | the balance chip moves into the body above 1.5× |
| S09 Reading result (`content`) | pass | pass | the spread becomes a vertical list: one card per row, in slot order, all starting at the same edge |
| S10 Out of readings (`content`) | pass | pass | |
| S11 Store (`content`) | pass | pass | |
| S13 Daily card (`notDrawn` and `drawn`) | pass | pass | |

There is also a control test: at exactly 150 % the S09 spread stays one row. Reflow starts only above 1.5×, as `kSpreadReflowTextScale` sets.

## 2. Reduced motion (automated)

File: `apps/taro/test/a11y/reduced_motion_test.dart`.

- **What it measures.** The test harness turns on the system setting (`MediaQuery.disableAnimations`). `settleTime` then pumps 10 ms frames until no frame is scheduled, and every ritual must settle within 210 ms (200 ms plus one frame).
- **How state changes.** Each state change goes through a `ValueNotifier` inside one app instance. This way only the ritual animates, and the theme is not rebuilt.

| Ritual | Reduced-motion behaviour asserted |
|---|---|
| S08 shuffle | A cross-fade dip (the opacity part-way through), no sway translation, done in ≤ 200 ms; "I'm ready — draw" is enabled afterwards |
| S08 deal ("Draw for me") | The cards fade in place with no rise and no stagger (`dealStagger` = 0), ≤ 200 ms |
| S08 flip ("Reveal all") | A cross-fade with no rotation `Transform`, ≤ 200 ms; control: with motion on the flip rotates and takes longer |
| S13 daily reveal | The flip cross-fades, and the texts appear at once (`readingReveal` = 0); ≤ 200 ms in total |
| S09 reading reveal | Every section is fully opaque on the first frame |
| S12 rewarded (`loadingAd`, `granting`) | A still ring (`value` 0.75) and no scheduled frames; control: with motion on it spins |

The in-app reduce-motion setting (`DrawView.reducedMotion` / `TaroA11yScope`) is covered by `draw_ritual_test.dart` and `router_test.dart`.

## 3. Arabic walkthrough and Japanese reading (automated)

File: `apps/taro/test/a11y/rtl_cjk_walkthrough_test.dart`. It uses the real screens and the bundled deck text (`assets/deck/ar.json`, `ja.json`) loaded into `FakeContentRepository`.

| Check | Evidence |
|---|---|
| Mirroring | The `Directionality` is `rtl` on S05, S07 and S09. The S09 leading "Done" sits on the right (start). |
| Numerals | The S05 date equals `DateFormat.MMMMEEEEd('ar')`, so it follows the intl locale defaults, as 01 §13 requires. |
| Card names | The S09 face semantics carry the bundled Arabic card name. S13 reveals without clipping. |
| Spread x-mirroring | On S09 in `ar`, `past` sits to the right of `future`. The English control puts it on the left. |
| Art never mirrored | No ancestor `Transform` of any `TaroCardFace` has a negative x scale, and no card `Image` uses `matchTextDirection`. A reversed card is a 180° rotation, not a mirror. |
| Japanese reading | S09 with a reading written from the bundled `ja` meanings has no clipping at 1.0× and 2.0×, and the full overview text is on the page. |

The 12-locale smoke (`test/l10n/locale_smoke_test.dart`) adds coverage of every screen in every locale at 1.3×. Goldens cover `ar` and `ja` (06 §3).

## 4. Screen-reader passes (MANUAL, owner)

Run these on a physical iPhone (VoiceOver) and a physical Android phone (TalkBack), with a dev or staging build. Do every ★ screen in English and repeat in Arabic. For each finding, add a row to §5 together with the fix and its test.

Setup:

- iOS: Settings → Accessibility → VoiceOver on. Android: Settings → Accessibility → TalkBack on.
- Also turn on Reduce Motion (iOS) or Remove animations (Android), and set the largest text size, for one extra pass of the draw.

Checklist (tick each row twice: **iOS** / **Android**):

| # | Screen / flow | What to verify | iOS | Android |
|---|---|---|---|---|
| 1 | S02–S03 onboarding | Logical focus order; the disclaimer is read in full; the buttons have labels | [ ] | [ ] |
| 2 | S04 AI consent | Both choices are equal-weight buttons, read with clear labels; the body is read in full | [ ] | [ ] |
| 3 | ATT pre-prompt (iOS only) | The single Continue is labelled; the system prompt follows | [ ] | n/a |
| 4 | S05 Home | The header date and greeting; the balance chip label; a "Balance updated" live announcement after a change; the daily tile and "Start a reading" are buttons; the recent rows are read as one node each | [ ] | [ ] |
| 5 | S06 Spread picker | Each spread is one button with its name and card count | [ ] | [ ] |
| 6 | S07 Question | The field label and hint; the suggestion chips; the Begin state (disabled reason read); the charge note | [ ] | [ ] |
| 7 | S08 complete draw by screen reader only | Shuffle button (the deck gesture is not focusable) → "Draw for me" → "Reveal all"; face-down cards read "Card back, position N of 3"; revealed cards read "name, upright/reversed, position: …"; "Reading ready" is announced | [ ] | [ ] |
| 8 | S08 leave dialog | Leave and Stay are equal-weight, and focus is trapped in the dialog | [ ] | [ ] |
| 9 | S09 Reading result | Section titles are headings (rotor / headings navigation); the AI label and the disclaimer are read; the thumbs have reason chips; Share and More are labelled | [ ] | [ ] |
| 10 | S10 Out of readings | Close is reachable first; the rewarded row says it is an ad; pack rows; "Not now"; Terms and Privacy | [ ] | [ ] |
| 11 | S11 Store | Each pack reads "N readings for $X, $Y per reading" (and "best value"); Restore; Close is always reachable | [ ] | [ ] |
| 12 | S12 Rewarded | The ring is labelled; Cancel; the granted state is announced | [ ] | [ ] |
| 13 | S13 Daily card | The card back reads "tap to reveal"; "Card revealed: …" is announced; the keywords and header semantics | [ ] | [ ] |
| 14 | S14 / S15 Journal | Each row is one node; swipe-to-delete has a "Delete" custom action; the entry note field is labelled | [ ] | [ ] |
| 15 | S16 / S17 Learn | Grid tiles read the card name; previous and next are labelled; the Upright / Reversed choice reads its state | [ ] | [ ] |
| 16 | S20 Settings and sub-screens | Switches read their state; the Support ID copy button; the language radio group | [ ] | [ ] |
| 17 | S27 Crisis resources | Call, Text and Open read the number or the service; numbers are read correctly in RTL | [ ] | [ ] |
| 18 | S30 Update required, S32 Classic, S33 Report | Labels and headings; the S33 radios start with nothing selected and the disabled Send reads its hint | [ ] | [ ] |
| 19 | Arabic pass of rows 4, 7, 9 and 13 | Swipe order runs right-to-left; card names are in Arabic; the spread reads in slot order | [ ] | [ ] |
| 20 | Max text + reduced motion draw | Rows 7 and 13 with the largest text size and reduced motion: no clipping, and only cross-fades | [ ] | [ ] |

Record for each pass: date, device, OS version, app build, and who ran it.

| Date | Device / OS | Build | Runner | Result |
|---|---|---|---|---|
| | | | | |

## 5. Findings and fixes

| # | Found by | Finding | Fix | Test |
|---|---|---|---|---|
| A1 | `max_text_scale_test` S05 at 200 % / AX5 | The `JournalEntryTile` title on the S05 Recent rows was clipped: the three thumbs and the indicators left the title too narrow, so "rebuilding" could not fit its box. Above 1.5× the title was also limited to 2 lines with an ellipsis. | Above 1.5× text the tile stacks the thumbs and indicators above the title, and the title has no line limit (`packages/taro_ui/lib/src/components/containers/journal_entry_tile.dart`) | `containers_test.dart` "large text: the leading and indicators sit above the full title…"; golden `journal_entry_tile/phone_small_light_en_x2` regenerated |
| A2 | `max_text_scale_test` S09 and S13 at 200 % / AX5 | The `TaroCardFace` "Reversed" badge was ellipsized ("Rev…") on the fixed-size card art | The badge scales down to fit (`FittedBox(scaleDown)`); it is unchanged at normal sizes (`taro_card_face.dart`) | `taro_card_test.dart` "large text: the reversed badge shrinks, never cut"; goldens `s09_reading_content` and `s32_classic_content` x2 regenerated |

Reduced motion and the Arabic and Japanese walkthroughs found no defects.
