# Taro — Phase 14 design review (Sprint 14.3)

| | |
|---|---|
| Date | 2026-09-27 |
| Reviewer | Independent design review (Claude), for owner sign-off |
| Design system artifact | https://claude.ai/artifact/C94hpvYCJKqrqYn5o8VnRb |
| Screens canvas artifact | https://claude.ai/artifact/1d29x21T1WhcFhFaeo3QxL |
| Sources reviewed | `docs/design/screens/*.dc.html` (58 artboards; titles and S-IDs from `canvas.json`), `screens/S01…S33/spec.md`, `components.md`, `BRIEF.md` §5, `taro.tokens.json`, `04_MONETIZATION.md` §8, §10, §11, `05_COMPLIANCE_STORE_ASO.md` §3, §6.1, §9.4, §9.5, CS6, CS13, CS14, `01_PRODUCT.md` §8.3, §12, §13, §14 |

**Method.** Every item was checked against the artboard HTML, not only the specs: a line-level regex search over all 58 `*.dc.html` files (banned words, prices, `--color-ad-container`, `dir=`, `scaleX`, `rotate(180deg)`, `min-height`); an exact-string comparison of the 05 §3 ARB strings against the artboard text; a scan of every interactive element (`a`, `button`, `input`, `label`, `role=…`) for its height; and a token script over `taro.tokens.json` (names, modes, reduced-motion extensions, WCAG contrast ratios). Evidence is given as `File.dc.html:line`.

**Result legend.** **PASS**: the artboard meets the rule. **PASS (derived in code)**: no artboard exists; the screen spec defines the state, and Phases 15–17 build it and prove it with goldens. **FAIL**: the artboard, token file or deliverable set breaks the rule. Every FAIL is listed again under *Open items* with where it gets fixed.

**Totals after fixes (2026-09-27): 82 PASS · 15 PASS (derived in code) · 0 FAIL** (97 items). The first pass had 8 FAILs (A36, C2, C6, C8, E4, F4, K5, K11); each row shows its fix. Also changed after review: the Crisis "Call 999" button uses the primary style, not vermilion.

---

## Checklist

### A. ★ states (01 §8.3) — designed or derived

| # | Item | Result | Evidence |
|---|---|---|---|
| A1 | S02 `content`★ | PASS | `Main.dc.html` (canvas "S02 Welcome") |
| A2 | S03 `content`★ | PASS | `Disclaimer.dc.html` |
| A3 | S04 `undecided`★ | PASS | `AiConsent.dc.html` |
| A4 | S05 `content`★, free reading available | PASS | `Today`, `TodayLight`, `TodayAr`, `TodayTablet` |
| A5 | S05 `content`★, free used + credits / zero readings | PASS (derived in code) | S05 spec states table; the "Free reading used" chip is drawn in the background of `Rewarded.dc.html` |
| A6 | S06 `content`★ | PASS | `Spreads.dc.html` (the `three_ppf` fill is the pressed state, not a default selection, per S06 spec) |
| A7 | S07 `editing`★ | PASS | `Question.dc.html` |
| A8 | S07 `refused(category)`★ | PASS | `QuestionRefused.dc.html` (`health`) |
| A9 | S07 `refused`, the other 9 categories | PASS (derived in code) | S07 spec: same card, copy from `messageKey`, `refusalGeneric` fallback |
| A10 | S08 `shuffling`★ | PASS | `DrawShuffle.dc.html` |
| A11 | S08 `picking`★ | PASS | `Draw.dc.html`, `DrawAr.dc.html` |
| A12 | S08 `awaitingReading`★ | PASS | `DrawAwaiting.dc.html` |
| A13 | S08 `reducedMotion`★ | PASS (derived in code) | S08 spec: same frames with the reduced-motion tokens, golden with `disableAnimations` |
| A14 | S09 `content`★ LTR dark, LTR light, RTL dark | PASS | `Reading`, `ReadingLight`, `ReadingAr` |
| A15 | S09 `content`★ RTL light | PASS (derived in code) | S09 spec: `ReadingAr` layout + light tokens |
| A16 | S10 `content`★ (rewarded available + packs loaded) | PASS | `OutOfReadings.dc.html` |
| A17 | S10 other option combinations (cooling down, capped, disabled, no fill, packs loading, store unavailable, `lowTrustLimited`) | PASS (derived in code) | S10 spec states table |
| A18 | S11 `loading`★ and `content`★ | PASS | `StoreLoading.dc.html`, `Store.dc.html` |
| A19 | S12 `granted`★ | PASS | `RewardedGranted.dc.html` |
| A20 | S13 `notDrawn`★ and `drawn`★ | PASS | `DailyCardNotDrawn.dc.html`, `DailyCard.dc.html` |
| A21 | S14 `empty`★ and `content`★ | PASS | `JournalEmpty.dc.html`, `Journal.dc.html`, `JournalAr.dc.html` |
| A22 | S16 `content`★ | PASS | `Learn.dc.html` |
| A23 | S17 `upright`★ | PASS | `CardDetail.dc.html` |
| A24 | S20 `content`★ | PASS | `Settings.dc.html` |
| A25 | S25 `invalid`★ (`notTaro`) and `preview`★ | PASS | `ImportInvalid.dc.html`, `Import.dc.html` |
| A26 | S25 `invalid` (`newerVersion`, `corrupt`, `tooLarge`) | PASS (derived in code) | S25 spec: same layout, reason copy; one golden per reason |
| A27 | S27 `content`★ | PASS | `Crisis.dc.html` |
| A28 | S30 `content`★ | PASS | `UpdateRequired.dc.html` (Android caption derived) |
| A29 | S32 `content`★ LTR dark | PASS | `ClassicReading.dc.html` |
| A30 | S32 `content`★ LTR light, RTL dark, RTL light | PASS (derived in code) | S32 spec: as `ReadingLight` / `ReadingAr` |
| A31 | S33 `editing`★ | PASS | `Report.dc.html` (no reason pre-selected) |
| A32 | Light theme for every ★ state | PASS (derived in code) | Only 2 light artboards (`#EEF0F4` canvas in `TodayLight`, `ReadingLight`); every other ★ state is light by golden |
| A33 | Tablet width (iPad 13", Android tablet) for every ★ state | PASS (derived in code) | Only `TodayTablet.dc.html` (1032 × 1376, content capped at 600); the rest by golden |
| A34 | `ar` for S05, S08, S09, S14 | PASS | `TodayAr`, `DrawAr` (picking), `ReadingAr`, `JournalAr` |
| A35 | `ar` for the other ★ states of those screens (S08 `shuffling`/`awaitingReading`, S14 `empty`, S05 variants) | PASS (derived in code) | No artboard; RTL goldens |
| A36 | Phase 14 deliverables: PNG reference frames per ★ state and `docs/design/assets/` | **PASS (fixed 2026-09-27)** | Fixed: `assets/` (card back SVG+PNG, 6 spread SVGs, empty journal/search, splash mark, app icon 1024 PNG, Android foreground/background/monochrome) and 58 @2x frames in `screens/frames/` (named per board; mapping in `frames/README.md`, linked from every spec). Before: `screens/S01…S33/` contain only `spec.md` (no PNG); `docs/design/assets/` does not exist (no `card-back.svg`, `spreads/*.svg`, `empty/*.svg`, icon PNG + Android adaptive/monochrome layers, `splash-mark.svg`). Sources exist as boards (`CardBack`, `SpreadDiagrams`, `AppIcon`, `Launch`, the Journal illustration in `JournalEmpty:22–29`); the search empty-state illustration and Android icon layers are not designed |

### B. Banned patterns (05 §9.5, BRIEF §5)

| # | Item | Result | Evidence |
|---|---|---|---|
| B1 | No timers or "offer ends" other than the real free-reset countdown | PASS | The only countdown is `OutOfReadings:29` "Next free reading in 3 h 12 min (at 00:00)". No `setInterval`/`setTimeout` in any file; 0 hits for "only today", "last chance", "limited", "offer ends", "hurry", "act now", "ends in" (except the file-name hint `ImportInvalid:39`) |
| B2 | No pre-selected pack, no single "Continue" | PASS | `Store:30, 34, 38, 47`: each pack and Remove Banner Ads is its own buy button; no `checked`/`aria-selected` in `Store`, `StoreLoading`, `OutOfReadings` |
| B3 | No fake discounts or strikethrough prices | PASS | 0 hits for `line-through`, "was $"; "Most popular" absent |
| B4 | No fear, guilt or confirmshaming copy | PASS | Decline copy is "Not now" (`AiConsent:28`, `OutOfReadings:46`). "waiting" appears only in `DeleteData:33` (data list), `RewardedGranted:49` ("Your question is waiting for you", neutral; see Deviations) |
| B5 | No blurred or teased reading behind the paywall; paywall never after reveal | PASS | The only `blur` is a decorative glow, `UpdateRequired:20`. S10 sits over the question screen (`OutOfReadings:18–22`), before any card is drawn |
| B6 | No banned claims (accuracy, psychic, prediction, heal, spell) | PASS | "predict", "will happen", "heal" occur only in negations (`AboutTaro:42`, `Disclaimer:20`, `Legal:36–37`, `Journal:45`); "spell" only as the `spellcheck` attribute (`DeleteData:47`) |

### C. Paywall S10 / S11 (04 §11, BRIEF §5)

| # | Item | Result | Evidence |
|---|---|---|---|
| C1 | S11 visible close (X) | PASS | `Store:20`, `StoreLoading:20` (48 × 48, `aria-label="Close"`) |
| C2 | S10 visible close (X) | **PASS (fixed 2026-09-27)** | Fixed: 48×48 close button (aria-label "Close") in the S10 sheet header. Before: `OutOfReadings` has a drag handle (`:25`) and "Not now" (`:46`) but no X. 04 §11 and BRIEF §5 require a visible X on S10 and S11 |
| C3 | Restore purchases (S11, S20) | PASS | `Store:51`, `StoreLoading:49`, `Settings` "Restore purchases" row |
| C4 | Terms and Privacy links | PASS | `Store:52–53`, `StoreLoading:50–51`, `OutOfReadings:49–50` |
| C5 | Consumable (non-restorable) line on S11 | PASS | `Store:56`, `StoreLoading:54`, verbatim 04 §11 |
| C6 | Consumable (non-restorable) line on S10 | **PASS (fixed 2026-09-27)** | Fixed: exact consumable line added under "Get more readings" on S10. Before: Absent from `OutOfReadings`; only the meta "readings don't expire" (`:38`). BRIEF §5: "S10 and S11 always show … the consumable line" |
| C7 | Price clarity: store price as its own button, per-reading price, "Best value" only on the lowest per-reading price | PASS | $1.99/3 = $0.66, $4.99/10 = $0.50, $9.99/30 = $0.33 (`Store:29–38`); badge on the 30-pack (`Store:37`) |
| C8 | Store price is the most legible number on the row (BRIEF §5) | **PASS (fixed 2026-09-27)** | Fixed: prices 17 px / 600, titles 16 px / 600 on every row; "Best value" outline removed. Before: The price renders at 15 px / 500 (`Store:30, 34, 38`), smaller and lighter than the pack title "10 readings" at 17 px / 600 (`Store:33`) |
| C9 | Free path always visible | PASS | S10: countdown (`:29`), rewarded row (`:34`), Daily card / Learn pills (`:43–44`). S11: "your free daily reading continues" (`Store:25`) + rewarded row (`Store:41–44`); S11 draws no countdown (see Deviations) |
| C10 | Rewarded offer says it is an ad and is user-started | PASS | "Watch an ad for 1 reading · Optional · 3 left today" (`OutOfReadings:34`, `Store:43`) |
| C11 | No prices or store in onboarding; paused/limit states not styled as a paywall | PASS | `$` appears only in `Store`, `OutOfReadings`, `Settings`. `ReadingsPaused` has no price and no rewarded offer |

### D. Consent (CS6, CS14, 05 §3)

| # | Item | Result | Evidence |
|---|---|---|---|
| D1 | "Allow AI readings" and "Not now" have equal visual weight | PASS | `AiConsent:27–28`: identical style strings (full width, 52 min height, `radius` 12, `accent.subtle` fill + 1.5 px `border.strong` inset, 16/500) |
| D2 | Exact `aiConsentTitle` and `aiConsentBody` | PASS | `AiConsent:21–22`, script-compared verbatim with 05 §3. **Consent copy changed per RC97 (2026-09-29):** the body now names both providers ("Anthropic's Claude or OpenAI's GPT models") and says "These AI providers do not use this data to train their models"; `AiConsent.dc.html` was updated to the new exact string (re-compared verbatim). The same change made S07 (`Question`), S23 (`PrivacyChoices`) and `Legal` provider-neutral. The 05 wording is pending 05 review and the owner's final provider list (Phase 22) |
| D3 | "Not now" present; privacy link; free path stated | PASS | `AiConsent:28`, `:24`, `:29` ("Without AI you still get the daily card, classic readings, Learn and the journal…") |
| D4 | S04 re-entry `declined` variant (Allow / Back, equal weight) | PASS (derived in code) | S04 spec states table |
| D5 | ATT pre-prompt is neutral | PASS | `AttPrompt:18–32`: "Either answer is fine", no incentive, one "Continue" to the system prompt (04 §10, CS14); no banner |

### E. Banner placement (04 §8, RC18, RC59)

| # | Item | Result | Evidence |
|---|---|---|---|
| E1 | Banner container only on S05, S14, S16 | PASS | `var(--color-ad-container)` is used in markup only in `Today:47`, `TodayLight:47`, `TodayAr:47`, `TodayTablet:49`, `TodayLargeText:47`, `TodayFirstRun:48`, `Journal:79`, `JournalAr:79`, `JournalEmpty:41`, `Learn:50`. `Help`, `Language`, `Legal`, `PrivacyChoices`, `Rewarded`, `RewardedGranted`, `Settings`, `UpdateRequired` only declare the variable in `:root` |
| E2 | `space.adGap` 16 above and below, outside the scroll view, above the tab bar | PASS | In all 10 files, a `height: 16px` spacer on the line before and after the container, which sits after the scroll column and before `<nav>` |
| E3 | No banner in sheets, dialogs, readings, crisis, consent, store | PASS | None in `OutOfReadings`, `Report`, `Rewarded`, `RewardedGranted`, any Reading/Classic/Draw board, `Crisis`, `AiConsent`, `AttPrompt`, `Store` |
| E4 | No banner before the first completed AI reading (`ads.bannerMinCompletedReadings` = 1) | **PASS (fixed 2026-09-27)** | Fixed: banner container and its gaps removed from `TodayFirstRun` and `JournalEmpty`. Before: `TodayFirstRun:48` and `JournalEmpty:41` draw a banner in states where a new user has no completed reading. The S05 spec says "There is no banner in first run" |

### F. Disclaimers and source labels (05 §3, RC20)

| # | Item | Result | Evidence |
|---|---|---|---|
| F1 | AI readings carry the "AI-generated" header badge | PASS | `Reading:42`, `ReadingLight:42`, `ReadingAr:42` ("مُنشأ بالذكاء الاصطناعي"), `ReadingLargeText:42`, `JournalEntry:44`. `ReadingRated` is scrolled below the header (see Deviations) |
| F2 | AI readings end with `disclaimerShort` | PASS | `Reading:50`, `ReadingLight:50`, `ReadingAr:50` (ar), `ReadingLargeText:50`, `ReadingRated:41`, `JournalEntry:48` |
| F3 | Classic reading: `disclaimerShort`, "Classic reading" label, no AI badge, no Report | PASS | `ClassicReading:58`, `:38`; the string "AI-generated" and a More menu are absent from the file |
| F4 | Disclaimer on the reading's loading and error states | **PASS (fixed 2026-09-27)** | Fixed: `disclaimerShort` footer added to `DrawAwaiting`. Before: `DrawAwaiting.dc.html` (the awaiting/slow view of an AI reading, the only drawn in-progress state) has no `disclaimerShort`; S08 `generationFailed`/`deliveryExpired` are specced without it. S09/S32 `loadingFromStorage` are specced with it |
| F5 | Paywall footer `disclaimerShort` | PASS | `Store:57`, `StoreLoading:55`, `OutOfReadings:52` |
| F6 | "Report this reading" reachable from every AI reading | PASS | More button `Reading` (`aria-label="More"`), `JournalEntry` ("More options"); sheet `Report.dc.html` with the exact `reportReadingDisclosure` |

### G. 200% text (01 §12)

| # | Item | Result | Evidence |
|---|---|---|---|
| G1 | S05 at 200% | PASS | `TodayLargeText.dc.html` (390 × 1880): display 56, body 30; no `text-overflow`/`line-clamp`; tab labels capped at 18 |
| G2 | S09 at 200% | PASS | `ReadingLargeText.dc.html` (390 × 2300): cards reflow to a vertical list (`:26`), reading text 36/56. The AI badge stays at 12 px (`:42`); see Open items |
| G3 | S13 at 200% | PASS (derived in code) | No artboard; S13 spec: card shrinks to `size.card.md`, the rest stacks |
| G4 | S32 at 200% | PASS (derived in code) | Covered by `ReadingLargeText` per S32 spec |

### H. Touch targets (≥ 44 visual, ≥ 48 hit)

| # | Item | Result | Evidence |
|---|---|---|---|
| H1 | Icon buttons (Back, Close, Done, More) are 48 × 48 | PASS | e.g. `Store:20`, `ReadingRated:20–23`, `DailyCardNotDrawn:20` |
| H2 | Primary/secondary buttons ≥ 48 | PASS | All full-width buttons are `min-height: 52px` (`AiConsent:27–28`, `OutOfReadings:46`, `DrawAwaiting:51`) |
| H3 | Controls drawn below 48 get a ≥ 48 hit area | PASS (derived in code) | Nothing interactive is below 40. Drawn at 40: balance chip and "Reveal card" (`Today:22, 30` and variants), filter chips (`Journal:27–30`), idea chips (`Question:37–39`). At 42: segments (`Learn:27–31`), Upright/Reversed (`CardDetail:41–42`). At 44: buy buttons and footer links (`Store:30–53`), S10 pills and links (`OutOfReadings:43–50`), legal tabs (`Legal:25–28`), Copy ID (`Settings:68`, `Help:59`), "Finish reading" (`Journal:63`), "Got it" (`TodayFirstRun:44`), "Withdraw" (`PrivacyChoices:29`). Tab items are 44 in the artboard (64 bar − 20 safe-area pad). Radio inputs (20 × 20) sit inside ≥ 48 labels (`Report:34`, `Language:38`). S-spec convention: "Controls drawn at 40–44 px … get a ≥ 48 hit area" |

### I. RTL mirrors (01 §13)

| # | Item | Result | Evidence |
|---|---|---|---|
| I1 | `dir="rtl"` on the page and the frame | PASS | `DrawAr:2, 18`, `TodayAr:2, 18`, `JournalAr:2, 18`, `ReadingAr:2, 18` |
| I2 | Card art never mirrored | PASS | No `scaleX` on any card element; card faces and the fan are `dir="ltr"` (`ReadingAr:28, 32, 36`; `DrawAr:28, 29, 33`). `scaleX(-1)` only on directional glyphs (`TodayAr:51`, `JournalAr:23, 74, 83`) |
| I3 | Spread x mirrors (`past` on the right) | PASS | `DrawAr:27–30` and the `ReadingAr` card row are laid out inside the RTL container, so Past (الماضي) renders rightmost |
| I4 | Reversed = rotation + text label, also in `ar` | PASS | `ReadingAr:32` `rotate(180deg)` + "مقلوبة"; the same in `Reading`, `ReadingLight`, `ReadingLargeText`, `ClassicReading`, `DrawReveal`, `DrawAwaiting`, `JournalEntry` |
| I5 | Locale numerals and dates | PASS | `TodayAr` "السبت، ٢٧ سبتمبر", `DrawAr` "اخترت ٢ من ٣", `JournalAr` "٢٨ بطاقة" |

### J. Store screenshot frame (CS13, 05 §9.4)

| # | Item | Result | Evidence |
|---|---|---|---|
| J1 | No Death, Devil or Tower | PASS | 0 hits for `\b(Death\|Devil\|Tower)\b` across all 58 files; `ScreenshotFrame` holds a placeholder slot (`:25–30`) and card-back shapes |
| J2 | No prices, ads, paywall or countdown | PASS | `ScreenshotFrame:29` ("No ads, no prices, no paywall."); no `$`, no ad container |
| J3 | Caption obeys CS3 | PASS | `ScreenshotFrame:23` "A reading that looks at how your cards relate" |

### K. Tokens (`taro.tokens.json`, 01 §14)

| # | Item | Result | Evidence |
|---|---|---|---|
| K1 | Every 01 §14 name is present | PASS | 167 tokens; the 167-name contract list (incl. `layout.gutter\|maxContentWidth\|maxContentWidthWide\|readingMaxWidth` (RC99), `haptic.pick\|flip\|ready`, `font.family.{10 roles}.{latin\|cyrillic\|arabic\|cjk\|hangul}` = 50, `elevation.0–4.shadow\|overlay`, `color.status.on*`) has 0 missing and 0 extra |
| K2 | Every colour token has light and dark | PASS | 43/43 under `$extensions["taro.modes"]` |
| K3 | Reduced-motion values on every `motion.*` | PASS | 12/12 under `$extensions["taro.reducedMotion"]`, equal to 01 §14.4 (instant 0, fast 100, base 150, slow 200, shuffle 200, dealStagger 0, flip 200, readingReveal 0, easings linear) |
| K4 | Constraint values | PASS | `type.body` 16, `type.caption` 13, `type.bodyReading` 18/29 (1.61), `size.touchTarget.min` 48, `space.adGap` 16, `layout.gutter` 16, `layout.readingMaxWidth` 560, `layout.maxContentWidth` 600, `layout.maxContentWidthWide` 960 (RC99) |
| K5 | Every `type.*` role defines `letterSpacing` (01 §14.2) | **PASS (fixed 2026-09-27)** | Fixed: `letterSpacing` set on all 10 `type.*` roles (design system + `taro.tokens.json`). Before: 6 of 10 roles omit it: `body`, `bodyReading`, `cardName`, `headline`, `title`, `titleSmall` |
| K6 | `text.primary` and `text.secondary` ≥ 4.5 on canvas, surface, surfaceRaised, sunken | PASS | 16/16; lowest: light secondary on sunken 6.86 |
| K7 | `text.tertiary` ≥ 4.5 on canvas and surface | PASS | 4/4; lowest 5.11 (light canvas). Also ≥ 4.5 on surfaceRaised/sunken (lowest 4.66) |
| K8 | `border.focus` ≥ 3 on the four backgrounds | PASS | 8/8; lowest: light on sunken 3.22 |
| K9 | `status.on*` on `status.*` ≥ 4.5 | PASS | 8/8; lowest: light onSuccess 5.31 |
| K10 | `text.onAccent` on `accent.primary` ≥ 4.5; `border.strong` ≥ 3 (control outlines) | PASS | 8.61 / 8.40; `border.strong` 6/6 on canvas, surface, surfaceRaised, lowest 3.20 |
| K11 | Deck ochre used as text holds 4.5:1 in light | **PASS (fixed 2026-09-27)** | Fixed: ochre text uses `color.suit.major` (light `#855C00`: 5.2:1 canvas, 5.7:1 surface, 4.8:1 sunken); `card.frame` is lines only (brand book rule). `TodayLight`, `ReadingLight`, `SpreadDiagrams` updated. Before: `color.card.frame` light `#B8820F` is 2.95:1 on canvas and 3.20:1 on surface, yet it colours 13 px text: "YOUR DAILY CARD" (`Today:27`, `DailyCard:21`, `DailyCardNotDrawn:21`, their light goldens) and position numbers (`SpreadDiagrams`, `SpreadsGuide:43–52`). `TodayLight:27` patches it with raw `#9A6A00` (not a token), which is still 4.49:1 on surface |

Required contrast pairs computed: 44, all pass (K6–K10). For information: `border.focus` against `accent.primary` is 2.14 (light) and 1.33 (dark). This holds only because the focus ring has a 2 px offset (components.md), so it sits on the background. Keep the offset.

### L. Other BRIEF §5 hard rules

| # | Item | Result | Evidence |
|---|---|---|---|
| L1 | Crisis screen: calm, no ads, upsell, balance or reading CTA; exact `crisisTitle`/`crisisBody` | PASS | `Crisis.dc.html` text: title, body, "Call 999", 3 resource rows, another country, last checked; no chip, price or banner |
| L2 | Art symbolic, not gory or child-oriented (05 §6.1) | PASS (derived in code) | Boards use placeholder glyphs only; the app icon (`AppIcon:18–24`) and the card back are an eight-point star in an ochre frame. The final deck art is reviewed in Phase 18 |
| L3 | `components.md` maps every designed component to a `taro_ui` class; new ones listed for Phase 15 | PASS | 16 new classes listed; see Deviations for stale lines |

---

## Open items carried to Phases 15–17

**Derived states (no artboard; built from the specs and proven by goldens).**
- Light theme for every ★ state except S05 and S09 `content`; tablet width for every ★ state except S05 `content`.
- `ar`: S08 `shuffling` and `awaitingReading`, S14 `empty`, S09 and S32 RTL light, S32 RTL dark.
- S05 `content` "free used + credits" and "zero readings"; S08 `reducedMotion`; S07 `refused` for the 9 non-`health` categories; S10 option combinations; S25 `invalid` `newerVersion`, `corrupt`, `tooLarge`; S04 `declined` re-entry; S13 and S32 at 200%.
- All non-★ states marked *Derived* in the S-specs (loading, error, offline, snackbars).

**First-pass FAILs: all 8 fixed on 2026-09-27** (see each row). What still carries into code:
- **F4:** `DisclaimerFooter` must also appear on the S08 states that are derived in code (`slowReading`, `timeoutPolling`, `generationFailed`, `deliveryExpired`). *Phase 16.*
- **K5 / K11:** `tools/tokens/validate_tokens.dart` asserts `letterSpacing` on every role and the `color.suit.major` text pairs. *Phase 15.1.*
- **A36:** reference frames are named per artboard, not per `Sxx-state-mode-locale-device`, because one board can serve several screens; `frames/README.md` maps S-IDs to frames. Light/`ar`/tablet frames exist only for the designed representatives; the rest come from goldens.

**Docs drift:** fixed (`README.md` says 58 artboards; `components.md` lists `TaroCoachmark`, `TaroToast`, `ReadingRatingControl`).

**Consent copy changed per RC97 (2026-09-29, after sign-off review):** the AI layer is provider-agnostic, so `aiConsentBody` (05 §3) now names Anthropic and OpenAI (every provider in `ai.disclosedProviders`). The S04 artboard and the Claude Design copy carry the new exact string; S07, S23 and Legal no longer name a single provider (see D2). The final provider list is confirmed by the owner before submission (Phase 22); if it shrinks, the canvas copy is narrowed with 05 §3.

---

## Sign-off

The design is fit to build from. All first-pass FAILs are fixed in the designs, tokens and exports; the remaining items above are implemented and proven in Phases 15–17.

Owner sign-off: ☑ Volodymyr Shyrochuk — 2026-09-28 ("signed, design looks great")
