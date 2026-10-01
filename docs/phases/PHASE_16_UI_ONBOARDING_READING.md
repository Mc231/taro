# Phase 16: UI — Onboarding, Today, Daily Card & Reading Flow

**Status:** ✅ Complete (2026-10-01) — manual screen-reader pass pending
**Depends on:** Phase 15, Phase 13 (controllers), Phase 8 (staging API for manual checks)

---

## Overview

This phase replaces the skeleton screens of the core experience with the designed UI:
- the launch screen;
- onboarding and the AI consent screen;
- Home (Today) and the daily card;
- the spread picker and question input;
- the draw ritual (shuffle, pick, reveal, awaiting reading);
- the reading result, the Classic reading, refusal and crisis screens, and the readings-paused state.

Controllers already exist and are tested (Phase 13). This phase only adds views, animations, semantics and goldens. It ends with the regenerated golden set for these screens.

**Output of this phase:**
- Designed views for S01–S09, S13, S27, S31, S32 (Classic reading) and S33 (Report sheet), in `apps/taro/lib/features/{onboarding,consent,home,daily_card,reading,help}/view/`.
- Goldens for every ★ state of these screens in the 06 §3 matrix; ★ states also at `kTabletIpad13` and `kTabletAndroid` (06 §3, RC24), with content constrained to `layout.maxContentWidth`.
- The native splash via `flutter_native_splash`, and the app icon (iOS + Android adaptive) from `docs/design/assets/`.

---

## Specs referenced

`01_PRODUCT.md` PR1, PR4–PR10, PR12, PR17, PR19, §7.1–§7.7, §7.12, §8 (S01–S09, S13, S27, S31), §9.2–§9.3, §9.7–§9.8, §12, §13, §16. `05_COMPLIANCE_STORE_ASO.md` CS3, CS6–CS8, §3, §4.1. `04_MONETIZATION.md` MO11, MO13. `02_ARCHITECTURE.md` §9.3, §14.3, §17. `06_QUALITY_TESTING_CI.md` §2.5, §3, §3.1, §3.2. `00_DECISIONS.md` RC18–RC22, RC27, RC31, RC44, RC47, RC48, RC50, RC51, RC64, RC71–RC74.

---

## Sprint 16.1: Launch, onboarding, consent

**Tasks:**
- [x] `flutter_native_splash` config + app icons (`flutter_launcher_icons`, with the Android adaptive layers) from `docs/design/assets/`. *(`apps/taro/flutter_native_splash.yaml`, `apps/taro/flutter_launcher_icons.yaml`, `apps/taro/assets/native/`)*
- [x] S01 `LaunchView` (bootstrapping, fatal `storageError` with "Contact support"). *(`LaunchScreen`; `StorageErrorApp` = `TaroErrorView(storage)` + Try again (02 §6.2) + support address; `onboarding_design_test.dart` "S01 storageError", `bootstrap_test.dart`)*
- [x] S02 `WelcomePager` (up to 3 pages, skippable to S03). S03 `DisclaimerView` (must tap "I understand"; copy keys `disclaimerOnboarding*` per 05 §3). *(v1 ships one page per S02 spec; `WelcomeLayout` + `WelcomeHero`, `DisclaimerLayout` + `DisclaimerNotice`; `onboarding_design_test.dart`, `onboarding_views_test.dart`)*
- [x] S04 `AiConsentView`, in the onboarding and re-entry variants: *(`AiConsentLayout`; copy names only OpenAI since 2026-10-01 with `ai.consentVersion` 2; re-entry footnote `aiConsentReentryFootnote` → Back → S07 Classic offer; `onboarding_design_test.dart` "S04", `onboarding_views_test.dart`)*
  - it names every AI provider in `ai.disclosedProviders` (v1 Anthropic and OpenAI, RC97), lists what is sent and what is not, and links the privacy policy (05 §3 `aiConsentBody`);
  - equal-weight **Allow AI readings** / **Not now**, with no pre-checked boxes (CS6).
  - The re-entry variant from the gate explains "AI readings need your permission" and also offers a **Classic reading** (RC20).
- [x] ATT neutral pre-prompt view (RC19, 04 §10: a single "Continue" leading to the system prompt, no incentive), shown by `ConsentOrchestrator` only when allowed. *(`AttPrePromptLayout`; `att_preprompt_view_test.dart`, `onboarding_design_test.dart` "ATT pre-prompt")*
- [x] Goldens: S02, S03, S04 `undecided`, and the ATT pre-prompt, in light/dark × en/ar; ★ states also at `kTabletIpad13` and `kTabletAndroid` (06 §3, RC24), with content constrained to `layout.maxContentWidth`. *(`apps/taro/test/golden/onboarding_golden_test.dart`, 46 PNGs; S02 also at 2.0×)*

---

## Sprint 16.2: Home & daily card

**Tasks:**
- [x] S05 `HomeView` (`apps/taro/lib/features/home/view/home_screen.dart`; `home_screen_test.dart`: header, zero-readings countdown, first-launch offline note, deviceUnverified, updateAvailable + Update, firstRun scrim/target, recent rows, 200 % text, balance announcement):
  - `BalanceChip` in every sync state (01 §7.1: "1 free today · 12 readings", stale glyph, "Readings unavailable on this device" + Retry);
  - daily-card tile (drawn or not), "Start a reading" CTA, recent readings, first-run coachmark, the dismissible `updateAvailable` notice (RC73);
  - `BannerSlot(home)` at the bottom above the tab bar (RC18);
  - live-region announcements for balance changes.
- [x] S13 `DailyCardView` (`apps/taro/lib/features/daily_card/view/daily_card_screen.dart`; `daily_card_screen_test.dart`: notDrawn, revealing, notDrawn → drawn flip + announcement, semantics, note, reminder offer):
  - tap-to-reveal flip (the `motion.ritual.flip` token; a crossfade in reduced motion);
  - name, orientation label, keywords, short meaning, reflection question, add-note;
  - "Reflect deeper with AI" → S07 with the card pre-set;
  - the reminder offer card shown once (01 §7.7; the OS permission prompt only after **Yes**).
- [x] Goldens (`apps/taro/test/golden/s05_home_golden_test.dart`, `s13_daily_card_golden_test.dart`; 74 PNGs): S05 `content` (free available, free used + credits, zero readings), S13 `notDrawn` and `drawn`. Text scale 2.0 goldens for S05 and S13 (01 §12). ★ states also at `kTabletIpad13` and `kTabletAndroid` (06 §3, RC24), with content constrained to `layout.maxContentWidth`.

---

## Sprint 16.3: Spread picker, question, draw ritual

**Tasks:**
- [x] S06 `SpreadPickerView`: 6 spreads with layout diagrams, card count and a "1 reading" cost label (PR3); spreads disabled by config are hidden. *(`spread_picker_screen.dart`; `spread_picker_screen_test.dart`)*
- [x] S07 `QuestionView`: *(`question_screen.dart`; `question_screen_test.dart`, `question_controller_test.dart` "refused(advice category): reflect reuses the declined cards")*
  - `TaroTextField` with a counter at 250 of 300 (RC45), 3–4 suggestion chips, inline guidance copy (05), and the email/phone warning;
  - **Begin** runs the gate, then the pre-draw hold (RC50), and shows every state visually: `checking` (gate + hold), `offline`, `consentRequired` → S04, `deviceUnverified`, `readingsPaused` (S31 inline: "Readings are resting", with links to the daily card, Learn and the Classic reading; RC47; `freePaused` copy variant, RC64), `aiUnavailableRegion` → Classic offer, `outOfReadings` → S10 (nothing drawn), `dailyLimitReached` (no paywall), `lowTrustLimited` → S10 with its copy (RC74), `rephrase` (hint + example rewordings), `refused(category)` card with "Reflect on the cards without a question", `rateLimited`.
- [x] S08 `DrawRitualView`: *(`draw_screen.dart`, `draw_panes.dart`, `routing/back_behaviour.dart`; `draw_screen_test.dart`, `draw_ritual_test.dart`)*
  - **shuffling**: hold or tap Shuffle for at least `motion.ritual.shuffle`; the deck order was already generated when the screen opened (01 §7.3);
  - **picking**: `CardFan`; tapping a card flies it to its slot with `dealStagger`; "Draw for me"; `selectionClick` haptic;
  - **commit**: the pending reading is persisted; if the hold has < 120 s left it is renewed first (a renewal 402 → `holdLost`); the request is sent;
  - **revealing** (only after a valid hold, so no card is ever revealed before a paywall, RC50): tap to flip in position order, or "Reveal all"; `lightImpact` haptic; the name, orientation text label and 3 keywords are shown;
  - **awaitingReading**: position titles + keywords + calm progress text, then `slowReading` at 20 s (RC31);
  - **generationFailed**: "You haven't been charged" + Try again (same cards and `readingId`) + Finish later;
  - **holdLost** (rare 402/409 after the pick) → S10 with the cards kept face-down (RC48, RC50);
  - **deliveryExpired** → "We couldn't deliver this reading, so you weren't charged" + Try again with the same cards (RC51);
  - **crisis** → S27;
  - **back confirmation** after the first pick;
  - `mediumImpact` haptic when the reading arrives.
- [x] Screen-reader path: the whole draw can be completed with VoiceOver/TalkBack via "Draw for me" + "Reveal all". Semantics tests assert the card labels (01 §12). *(`draw_ritual_test.dart` "the whole ritual by buttons alone", "screen-reader labels: deck, slots, fan cards", "the next card is labelled for the screen reader")*
- [x] Performance: `RepaintBoundary` around `SpreadCanvas` and the fan, precache the spread art on S07, and decode art with `cacheWidth` (02 §17). *(`CardFan` in a `RepaintBoundary` in `PickPane`, `SpreadCanvas` has its own; `CardArt.precacheFaces` on S07 (preset card) and on S08 open; `CardArt.face(cacheWidth:)`)*
- [x] Goldens: S07 `editing` and `refused(category)`; S08 `shuffling`, `picking`, `awaitingReading`, and the reduced-motion variant; ★ states also at `kTabletIpad13` and `kTabletAndroid` (06 §3, RC24), with content constrained to `layout.maxContentWidth`. *(`apps/taro/test/golden/s06_s08_draw_golden_test.dart`, 86 PNGs incl. S06 `content`)*

---

## Sprint 16.4: Reading result, Classic reading, refusal & crisis

**Tasks:**
- [x] S09 `ReadingResultView`: *(`features/reading/view/reading_result_screen.dart` + `reading_mini_spread.dart`; `test/features/reading/view/reading_result_screen_test.dart`; S33 visuals in `report_reading_sheet.dart` + `report_reading_sheet_test.dart`; the S15 prefill of "Write about this" is open, see Phase 17)*
  - header (spread, date, question, mini spread), `AiGeneratedLabel`, Summary, expandable Positions (thumbnail, position name, orientation, text), Synthesis, Reflection prompts with "Write about this" → note editor pre-filled;
  - `DisclaimerFooter` in **every** state (05 §3);
  - actions: Favourite, Add note, Share (PR19, with the include-question toggle), 👍/👎 with reason chips (no free text);
  - overflow menu → **Report this reading** → S33 sheet (reason chips + optional note + `reportReadingDisclosure`; states `editing`, `submitting`, `submitted`, `failed`, `offline`, `rateLimited`, `alreadyReported`; CS7, RC22, RC72);
  - a section-stagger reveal (`motion.ritual.readingReveal`);
  - Back → Home;
  - **no banner** (RC18).
- [x] S32 Classic reading view *(`features/reading/view/classic_reading_screen.dart`; `classic_reading_screen_test.dart`)* (RC20, RC71, flow F8): per position the card, orientation, short and long authored meaning and the position description; a "Classic reading" label instead of the AI label; the disclaimer; a "Try an AI reading" link only when the gate would allow it; no banner.
- [x] S27 `CrisisResourcesView` *(`features/help/view/crisis_resources_screen.dart`, `app_state/crisis_handoff.dart`, port `UrlLauncher` + `services/links/platform_url_launcher.dart`; `crisis_resources_screen_test.dart`, `help_controllers_test.dart`, `platform_url_launcher_test.dart`, `url_launcher_fake_test.dart`; the emergency-number card waits for an `emergency` field in the crisis data)*: calm copy (`crisisTitle`/`crisisBody`), up to 3 country-aware entries (the Worker response when reached from a reading; the device region when reached from Help), tap-to-call and link actions, the findahelpline.com fallback, works offline, and no ads or upsell.
- [x] Rate-app prompt wiring (after the 3rd 👍, not after a refusal; 01 §6.1). *(`ReadingResultController.rate` → `ReviewPrompter`; `reading_result_screen_test.dart` "the 3rd thumbs-up asks the review prompter", `in_app_review_prompter_test.dart`)*
- [x] Goldens: S09 `content` (LTR/RTL, light/dark, plus `de` and `ja` per 01 §17.1 and textScale 2.0), the refusal card, S27, S32 `content` and S33 `editing`; *(`test/golden/s09_s32_reading_golden_test.dart`, `s27_crisis_golden_test.dart`; the refusal card is `s07_question_refused_health` in `s06_s08_draw_golden_test.dart`)* ★ states also at `kTabletIpad13` and `kTabletAndroid` (06 §3, RC24), with content constrained to `layout.maxContentWidth`.

---

## Sprint 16.5: Golden regeneration & a11y pass

**Tasks:**
- [x] Regenerate every golden touched in this phase in one commit via `golden.yml` (`test(golden): update goldens`, 06 §3). *(regenerated once on the reference platform with `tools/golden_update.py` (macOS arm64 + pinned Flutter): apps/taro 264 golden tests, taro_ui 190; `melos run test:golden` green)*
- [x] Accessibility guideline tests on every ★ screen from this phase. *(`goldenMatrix(accessibility: true)` in `packages/taro_ui/test/helpers/golden/golden_matrix.dart`: Android/iOS tap target, labelled tap target and text contrast guidelines in `en` light + dark for all 19 ★ states (S02, S03, S04, S05 ×3, S06, S07 ×2, S08 ×4, S09, S13 ×2, S27, S32, S33), 38 tests `a11y_phone_small_*`; fixed the unlabelled S08 shuffle-deck gesture)*
- [ ] Manual VoiceOver and TalkBack pass on onboarding and the reading flow *(MANUAL; notes in the phase doc)*.
- [x] Re-run the 12-locale smoke test (06 §3.1) against the real views. *(`apps/taro/test/l10n/locale_smoke_test.dart` builds every S-ID through `screenBuilders`: 12/12 locales pass)*

---

## Done when

- [x] `apps/taro` ≥ 90% and `taro_ui` ≥ 90%. Goldens are committed from the reference runner. The integration flows (Phase 13) still pass with the real views. *(`tools/verify.sh` full: apps/taro 99.5 %, taro_ui 99.9 %, every file ≥ 70 %; goldens generated on this reference Mac; 15/15 flows in `integration_test/flows/` on the iOS 26.2 simulator (iPhone 16e) — `flow_harness.dart` now pins the system locale to `en` and marks the S05 first-run coachmark seen for pre-onboarded flows; `first_launch_free_reading_test` scrolls to the S09 footer; `flutter build ios --simulator --flavor dev` ok)*
- [x] Tablet-width goldens (`kTabletIpad13`, `kTabletAndroid`) for every ★ state of this phase are green (RC24). *(`keyScreen: true` on all 19 ★ states in `apps/taro/test/golden/*_golden_test.dart`; `melos run test:golden` green)*
- [x] Widget tests from 06 §2.5 pass on the real views: no `CardFace` before the gate allows, the footer is always present, no banner on reading screens, the consent buttons have equal weight. *(`draw_ritual_test.dart` (no `TaroCardFace` before reveal, footer on every state after the pick), `draw_screen_test.dart` / `reading_result_screen_test.dart` / `classic_reading_screen_test.dart` (`BannerSlot` findsNothing), `onboarding_views_test.dart` "undecided: equal-weight buttons, nothing pre-selected")*
- [x] Docs: `docs/design/components.md` usage notes; CHANGELOG. *(per-sprint notes plus the `goldenMatrix(accessibility:)` note; `CHANGELOG.md` Phase 16.1–16.5 lines; `STATE_INVENTORY.md` regenerated)*
- [ ] One commit: `feat(taro): Phase 16 — UI: onboarding, today & reading flow`.

## Next phase

Phase 17: UI — Monetization, Journal, Learn & Settings.
