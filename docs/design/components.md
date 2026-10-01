# Taro — component inventory (`taro_ui` mapping)

Every component that appears in the approved design system (https://claude.ai/artifact/C94hpvYCJKqrqYn5o8VnRb, `components/*`) and on the screens canvas (https://claude.ai/artifact/1d29x21T1WhcFhFaeo3QxL, `docs/design/screens/*.dc.html`), mapped to its Flutter class name. Phase 15 implements from this file; Sprint 15.3 adds a link to each component's golden.

**Status legend**

| Status | Meaning |
|---|---|
| **02 §14.3** | Named in `02_ARCHITECTURE.md` §14.3 as a `taro_ui` component. |
| **02 §14.3 (app)** | Named in 02 §14.3 as an app-level stateful widget in `apps/taro/lib/common/` (built in Phase 13, styled in Phases 16–17); its stateless visual lives in `taro_ui`. |
| **Phase 15 (not in 02)** | Not in 02 §14.3, but already a Phase 15 Sprint 15.2 task. No new task needed. |
| **NEW → Phase 15** | Not in 02 §14.3 and not yet planned. Added to `docs/phases/PHASE_15_DESIGN_SYSTEM.md` Sprint 15.2 and listed in [§ New components](#new-components--phase-15). |

Token names use the 01 §14 dot form (`color.bg.surface`); the Claude Design CSS writes them with dashes (`--color-bg-surface`). Every component: Semantics, ≥ 48 × 48 dp targets, focus ring (2 px `color.border.focus`, 2 px offset), RTL via directional insets, goldens light/dark × `en`/`ar` (02 §14.3).

**Goldens (Sprint 15.3).** Each component below links its golden folder under `packages/taro_ui/test/golden/goldens/` and the test that renders it. File names are `<size>_<theme>_<locale>[_x2].png`: `phone_small_{light,dark}_{en,ar}` for every component, `phone_small_light_en_x2` (200 % text) for the text-heavy ones, `tablet_ipad13_{light_en,dark_ar}` for layout-level and navigation components (RC24). Generated on the reference platform (macOS arm64 + pinned Flutter) with `melos run golden:update`; `melos run test:golden` compares them. Several related components share one golden sheet (for example `TaroIconButton`, `TaroChip` and `StepIndicator` in `taro_icon_button_chip`). App screens (`apps/taro/test/golden/`, Phase 16) use the same `goldenMatrix` through `pumpAppGolden`; ★ states pass `keyScreen: true` (tablet widths) and `accessibility: true`, which also runs the 06 §3.2 guidelines (tap targets, labelled targets, text contrast) in `en` light and dark. A decorative gesture that duplicates a labelled button (the S08 shuffle deck) sets `excludeFromSemantics: true`.

Design-system names → class names: **Button** → `TaroButton`; **TarotCard** → `TaroCardFace` + `TaroCardBack` + `TaroCardFlip`; **BalanceChip** → `BalanceChip` (app) over `BalancePill`; **BannerSlot** → `BannerSlot` (app) over `BannerContainer`; **PackRow** → `ProductOfferTile`; **InlineNotice** → `TaroInlineNotice`. (`components/Cover` is the brand-book cover illustration, not a component.)

---

## 1. Structure and navigation

### `TaroScaffold` — 02 §14.3
- **Purpose:** page frame. Safe areas, `color.bg.canvas` background, `layout.gutter` side padding, content centred and capped at `layout.maxContentWidth` on tablets (RC24); optional bottom slot (banner, sticky CTA) outside the scroll view.
- **Tokens:** `color.bg.canvas`, `layout.gutter`, `layout.maxContentWidth`, `space.adGap`.
- **States:** phone / tablet (constrained); with or without tab bar; with or without bottom slot.
- **Screens:** every full screen S01–S09, S11, S13–S32 (S10 and S33 are sheets, S12 a dialog).
- **Golden:** [`taro_scaffold/`](../../packages/taro_ui/test/golden/goldens/taro_scaffold/) ([`state_kit_golden_test.dart`](../../packages/taro_ui/test/golden/state_kit_golden_test.dart)).

### `TaroAppBar` — 02 §14.3
- **Purpose:** top bar with a leading Back (chevron, mirrors in RTL) or Close (X), optional live status text, trailing actions; the screen title sits below it as a large serif title (`type.headline`), or in the bar for pushed detail screens.
- **Tokens:** `type.headline`, `type.title`, `color.text.primary`, `color.text.secondary`, `size.touchTarget.min`, `size.icon.md`.
- **States:** back / close; with title / large title below; with trailing actions (S09: Add note, Favourite, More; S15: Favourite, Export); scrolled (surface tint).
- **Screens:** S06, S07, S08 (Close + "2 of 3 picked" live region), S09, S11, S13, S15, S17, S18, S19, S21–S29, S31, S32.
- **Golden:** [`taro_app_bar/`](../../packages/taro_ui/test/golden/goldens/taro_app_bar/) ([`layout_components_golden_test.dart`](../../packages/taro_ui/test/golden/layout_components_golden_test.dart)).

### `TaroTabBar` — Phase 15 (not in 02)
- **Purpose:** the 4-tab bottom navigation: Today, Journal, Learn, Settings (RC17). Icon + label.
- **Tokens:** `color.bg.surface`, `color.accent.primary` (selected), `color.text.secondary`, `type.label`, `size.icon.md`, `size.touchTarget.min`, `color.border.subtle`.
- **States:** selected / unselected per tab; focus.
- **Screens:** S05, S14, S16, S20.
- **Golden:** [`taro_app_bar/`](../../packages/taro_ui/test/golden/goldens/taro_app_bar/) ([`layout_components_golden_test.dart`](../../packages/taro_ui/test/golden/layout_components_golden_test.dart)).

### `TaroSheet` — 02 §14.3
- **Purpose:** modal bottom sheet with a grabber, `radius.sheet` top corners, scrim; never contains a banner.
- **Tokens:** `color.bg.surfaceRaised`, `color.bg.scrim`, `radius.sheet`, `elevation.3`, `motion.duration.slow`, `motion.easing.decelerate`.
- **States:** opening, open, dragging, closing; reduced motion (fade).
- **Screens:** S10 (out of readings), S33 (report), S20 theme picker, S25 `confirmReplace`, S09 More menu.
- **Golden:** [`taro_sheet/`](../../packages/taro_ui/test/golden/goldens/taro_sheet/) ([`layout_components_golden_test.dart`](../../packages/taro_ui/test/golden/layout_components_golden_test.dart)).

### `TaroDialog` — 02 §14.3
- **Purpose:** centred modal dialog for blocking progress or confirmation.
- **Tokens:** `color.bg.surfaceRaised`, `color.bg.scrim`, `radius.xl`, `elevation.4`, `type.title`, `type.body`.
- **States:** progress (spinner + text + Cancel), confirm (two actions), destructive confirm.
- **Screens:** S12 (`loadingAd`, `granting` "Adding your reading…", `grantDelayed`, `granted`), S26 (`confirm2`), S15 delete confirm, S04 re-entry (`declined` from the reading flow).
- **Golden:** [`taro_dialog/`](../../packages/taro_ui/test/golden/goldens/taro_dialog/) ([`layout_components_golden_test.dart`](../../packages/taro_ui/test/golden/layout_components_golden_test.dart)); [`taro_dialog_progress/`](../../packages/taro_ui/test/golden/goldens/taro_dialog_progress/) ([`layout_components_golden_test.dart`](../../packages/taro_ui/test/golden/layout_components_golden_test.dart)).

### `SettingsTile` — 02 §14.3
- **Purpose:** one settings row: title, optional subtitle, trailing value + chevron, switch, or text action.
- **Tokens:** `color.bg.surface`, `type.titleSmall`/`type.body`, `type.caption`, `color.text.secondary`, `color.border.subtle` (divider), `color.accent.primary` (switch on), `size.touchTarget.min`.
- **States:** navigation, value, switch on/off, action (e.g. "Copy ID", "Withdraw", "Review ad choices"), destructive (Delete all data), disabled.
- **Screens:** S20, S22 (reminder switch, time, days), S23, S28 (support ID row).
- **Golden:** [`settings_section/`](../../packages/taro_ui/test/golden/goldens/settings_section/) ([`layout_components_golden_test.dart`](../../packages/taro_ui/test/golden/layout_components_golden_test.dart)).

### `SettingsSection` — **NEW → Phase 15**
- **Purpose:** a titled group of `SettingsTile`s on one `color.bg.surface` block ("Readings", "Experience", "Privacy & data", "Help", "About").
- **Tokens:** `type.label` / `type.caption` (header), `color.text.secondary`, `color.bg.surface`, `radius.lg`, `space.3`, `space.7`.
- **States:** default; header as `Semantics(header: true)`.
- **Screens:** S20, S23 ("AI readings", "Ads", "Improving Taro").
- **Golden:** [`settings_section/`](../../packages/taro_ui/test/golden/goldens/settings_section/) ([`layout_components_golden_test.dart`](../../packages/taro_ui/test/golden/layout_components_golden_test.dart)).

### `SegmentedChoice` — 02 §14.3
- **Purpose:** single choice among 2–4 short options.
- **Tokens:** `color.bg.sunken`, `color.accent.subtle` (selected), `color.text.primary`, `type.label`, `radius.full`, `size.touchTarget.min`.
- **States:** selected / unselected, disabled, focus.
- **Screens:** S20 theme (System / Light / Dark, in the theme sheet), S14 filter row (All / Readings / Daily cards / Favourites) when it fits; falls back to `TaroChip` filter style at large text scale.
- **Golden:** [`segmented_choice_badge_countdown/`](../../packages/taro_ui/test/golden/goldens/segmented_choice_badge_countdown/) ([`layout_components_golden_test.dart`](../../packages/taro_ui/test/golden/layout_components_golden_test.dart)).

### `TaroTabStrip` — **NEW → Phase 15**
- **Purpose:** horizontally scrollable document tabs with `role=tab` semantics (Disclaimer, Terms of use, Privacy policy, Open-source licences). Unlike `SegmentedChoice`, labels are long and scroll.
- **Tokens:** `type.label`, `color.text.primary`/`secondary`, `color.accent.primary` (indicator), `color.border.subtle`, `size.touchTarget.min`.
- **States:** selected / unselected, focus, overflow scroll; RTL order mirrored.
- **Screens:** S29.
- **Golden:** [`taro_tab_strip/`](../../packages/taro_ui/test/golden/goldens/taro_tab_strip/) ([`inputs_golden_test.dart`](../../packages/taro_ui/test/golden/inputs_golden_test.dart)).

### `StepIndicator` — **NEW → Phase 15**
- **Purpose:** onboarding progress dots, announced as "Step 1 of 3".
- **Tokens:** `color.accent.primary` (current), `color.border.strong` (others), `radius.full`, `space.2`.
- **States:** step n of m.
- **Screens:** S02, S03, S04 (onboarding).
- **Golden:** [`taro_icon_button_chip/`](../../packages/taro_ui/test/golden/goldens/taro_icon_button_chip/) ([`inputs_golden_test.dart`](../../packages/taro_ui/test/golden/inputs_golden_test.dart)).
- **Usage (Phase 16.1):** centred in the footer of the app's `OnboardingPage` template (`apps/taro/lib/common/onboarding_page.dart`: `space.12`/`space.7`/`space.9` padding, scrolling content, pinned footer, also used by the ATT pre-prompt with `OnboardingIconTile`); the step is the onboarding step, never a page index. Screen goldens: `apps/taro/test/golden/goldens/{s02_welcome_content,s03_disclaimer_content,s04_ai_consent_undecided,att_preprompt}/`.

### `TaroBrandMark` — **NEW → Phase 15**
- **Purpose:** the Taro mark (eight-point star in an ochre card frame) + wordmark in `type.display`. Matches the app icon and splash.
- **Tokens:** `color.card.back`, `color.card.frame`, `type.display`, `color.text.primary`.
- **States:** mark only / mark + wordmark; static (no animation under reduced motion).
- **Screens:** S01 launch (Flutter bootstrap continuation of the native splash), S30.
- **Golden:** [`taro_brand_mark/`](../../packages/taro_ui/test/golden/goldens/taro_brand_mark/) ([`monetization_golden_test.dart`](../../packages/taro_ui/test/golden/monetization_golden_test.dart)).

---

## 2. Actions and inputs

### `TaroButton` — 02 §14.3 (design system **Button**)
- **Purpose:** every action. One primary per screen. Label is a sentence-case verb.
- **Tokens:** primary `color.accent.primary` / `primaryPressed` + `color.text.onAccent`; secondary transparent + 1.5 px `color.border.strong` + `color.text.primary`; tertiary (design "Text") `color.accent.primary` label, no container; destructive `color.status.error` + `color.status.onError`; `radius.md`, `type.label`, min height 52 (≥ `size.touchTarget.min`), `opacity.disabled`, `opacity.pressed`.
- **States:** enabled, pressed, focus, disabled, loading (spinner, label kept for semantics).
- **Rules:** never vermilion or status colours for non-destructive buttons; "Not now" never smaller or fainter than the offer (CS6, 04 §11).
- **Screens:** S02 Get started; S03 I understand / Read the full disclaimer; S04 Allow AI readings / Not now; S05 Reveal card, Start a reading; S07 Begin; S08 Draw for me / Pick this card; S10 Not now; S11 Restore purchases, Terms, Privacy; S13 Reflect deeper with AI / Add a note; S15 Full reading / Delete entry; S18 Use this spread; S22 Change; S23 Withdraw / Review ad choices; S24 Export backup; S25 Choose another file / Import; S26 Delete all data (destructive) / Cancel; S27 Call 999; S28 Email support / Copy ID; S30 Update; S31 Try a classic reading / Back to Today; S33 Send report / Cancel; S12 Cancel.
- **Golden:** [`taro_button/`](../../packages/taro_ui/test/golden/goldens/taro_button/) ([`state_kit_golden_test.dart`](../../packages/taro_ui/test/golden/state_kit_golden_test.dart)).

### `TaroIconButton` — 02 §14.3
- **Purpose:** icon-only action with a required semantics label.
- **Tokens:** `size.icon.md`, `size.touchTarget.min`, `color.text.primary`, `opacity.pressed`, `color.accent.primary` (toggled on).
- **States:** default, pressed, toggled (Favourite), disabled, focus.
- **Screens:** Back / Close on all pushed screens; S09 and S15 Favourite, More, Export; S14 search clear.
- **Golden:** [`taro_icon_button_chip/`](../../packages/taro_ui/test/golden/goldens/taro_icon_button_chip/) ([`inputs_golden_test.dart`](../../packages/taro_ui/test/golden/inputs_golden_test.dart)).

### `TaroTextField` — 02 §14.3
- **Purpose:** text input: single-line, multi-line with grapheme counter, and a search style (leading search icon, clear button).
- **Tokens:** `color.bg.sunken`, `color.border.strong` (outline), `color.border.focus`, `radius.md`, `type.body`, `type.caption` (label, counter, helper), `color.text.tertiary` (placeholder), `color.status.error`.
- **States:** empty, filled, focused, counter visible (from 250 graphemes), over-limit, error, disabled, saved-status caption ("Saved on this device").
- **Screens:** S07 question (counter "44 / 300"), S31 (question kept, read-only), S13 and S15 note editor, S33 details (≤ 500), S14 search ("Search questions and notes"), S28 search help, S26 type-to-confirm ("Type DELETE").
- **Golden:** [`taro_text_field/`](../../packages/taro_ui/test/golden/goldens/taro_text_field/) ([`inputs_golden_test.dart`](../../packages/taro_ui/test/golden/inputs_golden_test.dart)).

### `TaroChip` — Phase 15 (not in 02)
- **Purpose:** compact pill. Variants: *suggestion* (tap inserts text), *filter* (toggle, selected state).
- **Tokens:** `color.bg.surface` / `color.accent.subtle` (selected), `color.border.subtle`, `type.label`, `radius.full`, `size.touchTarget.min`.
- **States:** default, selected, pressed, disabled, focus.
- **Screens:** S07 "Ideas" suggestion chips; S14 filters (All / Readings / Daily cards / Favourites); S16 suit filter (Major Arcana / Wands / Cups / Swords / Pentacles, with `SuitGlyph`).
- **Golden:** [`taro_icon_button_chip/`](../../packages/taro_ui/test/golden/goldens/taro_icon_button_chip/) ([`inputs_golden_test.dart`](../../packages/taro_ui/test/golden/inputs_golden_test.dart)).

### `TaroRadioTile` — **NEW → Phase 15**
- **Purpose:** single-choice option with a visible radio. Two styles: *row* (title, optional subtitle) and *card* (title + explanatory body on `color.bg.surface`, the "radio card").
- **Tokens:** `color.bg.surface`, `color.accent.subtle` + `color.accent.primary` ring (selected card), `color.border.strong` (radio), `type.titleSmall`, `type.body`, `color.text.secondary`, `radius.md`/`radius.lg`, `size.touchTarget.min`.
- **States:** selected / unselected, disabled, focus; `Semantics(inMutuallyExclusiveGroup)`.
- **Screens:** S21 language list (row, with "Use phone language" first), S25 Merge / Replace (card), S33 reason list (row), S20 theme sheet (row).
- **Golden:** [`taro_radio_tile/`](../../packages/taro_ui/test/golden/goldens/taro_radio_tile/) ([`inputs_golden_test.dart`](../../packages/taro_ui/test/golden/inputs_golden_test.dart)).

### `WeekdayPicker` — **dropped for v1**
- **Status:** removed from S22 (the reminder is daily only; 01 §7.7, backup schema v1 stores `{enabled, time}`). Kept here only in case a later spec adds reminder days.
- **Purpose:** multi-select row of seven day toggles (M T W T F S S), locale-ordered first weekday, each announcing the full day name ("Wednesday, selected").
- **Tokens:** `color.accent.primary` + `color.text.onAccent` (on), `color.bg.sunken` + `color.text.secondary` (off), `radius.full`, `type.label`, `size.touchTarget.min`.
- **States:** on / off per day, disabled (reminder off), focus; RTL order.
- **Screens:** S22.
- **Golden:** [`weekday_picker_accordion/`](../../packages/taro_ui/test/golden/goldens/weekday_picker_accordion/) ([`inputs_golden_test.dart`](../../packages/taro_ui/test/golden/inputs_golden_test.dart)).

### `TaroAccordion` — **NEW → Phase 15**
- **Purpose:** FAQ expandable item: question row with chevron, answer revealed below.
- **Tokens:** `color.bg.surface`, `color.border.subtle`, `type.titleSmall`, `type.body`, `color.text.secondary`, `radius.md`, `motion.duration.base`, `motion.easing.standard`, `size.touchTarget.min`.
- **States:** collapsed, expanded, focus; `Semantics(expanded:)`; reduced motion (no height animation).
- **Screens:** S28.
- **Golden:** [`weekday_picker_accordion/`](../../packages/taro_ui/test/golden/goldens/weekday_picker_accordion/) ([`inputs_golden_test.dart`](../../packages/taro_ui/test/golden/inputs_golden_test.dart)).

---

## 3. Containers and rows

### `TaroSurfaceCard` — **NEW → Phase 15**
- **Purpose:** generic content container on `color.bg.surface` (or `surfaceRaised` for the primary CTA card), optionally tappable as one semantic unit.
- **Tokens:** `color.bg.surface`, `color.bg.surfaceRaised`, `radius.lg`, `space.5`/`space.6`, `elevation.0`/`elevation.1`, `opacity.pressed`.
- **States:** static, tappable (pressed, focus), highlighted (`color.accent.subtle` fill + `color.accent.primary` inset ring).
- **Screens:** S05 daily-card teaser and "Ask the cards a question" card; S13 meaning block; S14 patterns card; S17 aspect rows (Relationships / Work & purpose / Personal growth); S22 notification preview frame; S24 file card; S25 file summary; S27 hotline group; S31 paused card.
- **Golden:** [`taro_surface_card_list_tile/`](../../packages/taro_ui/test/golden/goldens/taro_surface_card_list_tile/) ([`containers_golden_test.dart`](../../packages/taro_ui/test/golden/containers_golden_test.dart)).

### `TaroListTile` — **NEW → Phase 15**
- **Purpose:** a tappable row on a surface: leading visual (icon, spread diagram, card thumb), title, subtitle, trailing (chevron, action button, value). Includes a *disabled-with-reason* form (the reason is the subtitle, never hidden; 04 §9.1).
- **Tokens:** `color.bg.surface`, `color.accent.subtle` + inset `color.accent.primary` (selected), `type.titleSmall`, `type.caption`, `color.text.tertiary`, `radius.lg`, `space.4`/`space.5`, `size.touchTarget.min`.
- **States:** default, pressed, selected, disabled (with reason), focus.
- **Screens:** S06 spread options (leading `SpreadDiagram`, selected state); S10 and S11 "Watch an ad for 1 reading · Optional · 3 left today", S10 "Get more readings" (disabled states: cooling down, capped, no fill); S16 Spreads guide / About links; S17 "In your journal: drawn 4 times"; S19, S20, S28 "Support lines" link; S20 "Move readings from another device" and "Rate Taro"; S23 Tracking row; S27 hotline rows (trailing Call / Text button labelled "Call Samaritans on 116 123").
- **Golden:** [`taro_surface_card_list_tile/`](../../packages/taro_ui/test/golden/goldens/taro_surface_card_list_tile/) ([`containers_golden_test.dart`](../../packages/taro_ui/test/golden/containers_golden_test.dart)).

### `JournalEntryTile` — **NEW → Phase 15**
- **Purpose:** one journal row: title (question or card name), meta (spread · date, "Daily card · Today"), leading card thumb(s), status badge (Pending / Classic), note and favourite indicators, and the inline "Finish reading" action for pending entries.
- **Tokens:** `color.bg.surface`, `type.titleSmall`, `type.caption`, `color.text.tertiary`, `size.card.thumb`, `radius.lg`, `Badge` tokens, `size.icon.sm`.
- **States:** AI reading, Classic, daily card, pending (with action), failed, has note, favourite, pressed, focus; swipe/overflow delete with undo (S15 `deleted`).
- **Screens:** S14 list, S05 "Recent".
- **Golden:** [`journal_entry_tile/`](../../packages/taro_ui/test/golden/goldens/journal_entry_tile/) ([`containers_golden_test.dart`](../../packages/taro_ui/test/golden/containers_golden_test.dart)).

### `IconBulletList` — **NEW → Phase 15**
- **Purpose:** short vertical list of icon + title (+ optional body) statements used to explain value, rules or data handling.
- **Tokens:** `size.icon.md`, `color.card.frame` / `color.accent.primary` / `color.status.success` / `color.text.tertiary` (icon by intent), `type.titleSmall`, `type.body`, `color.text.secondary`, `space.4`.
- **States:** neutral, included (check), excluded (dash); icons decorative (`excludeSemantics`), text carries meaning.
- **Screens:** S02 value list, S03 disclaimer points, S24 Included / Not included, S26 What's erased / What's kept, S30 reassurance line.
- **Golden:** [`icon_bullet_list_notification/`](../../packages/taro_ui/test/golden/goldens/icon_bullet_list_notification/) ([`containers_golden_test.dart`](../../packages/taro_ui/test/golden/containers_golden_test.dart)).

### `NotificationPreview` — **NEW → Phase 15**
- **Purpose:** static mock of the daily reminder notification (app name, time, title, body) so the user sees exactly what will appear; never shows the card.
- **Tokens:** `color.bg.surfaceRaised`, `radius.lg`, `elevation.1`, `type.caption`, `type.titleSmall`, `type.body`, `color.text.secondary`.
- **States:** default; follows 12/24 h and locale.
- **Screens:** S22.
- **Golden:** [`icon_bullet_list_notification/`](../../packages/taro_ui/test/golden/goldens/icon_bullet_list_notification/) ([`containers_golden_test.dart`](../../packages/taro_ui/test/golden/containers_golden_test.dart)).

---

## 4. Deck rendering and the ritual

### `TaroCardFace` — 02 §14.3 (design system **TarotCard**, revealed)
- **Purpose:** a revealed card: art (`ImageProvider`), Roman numeral / rank in `type.numeral`, name in `type.cardName` (below or on the card), orientation; semantics "Three of Cups, reversed, position: Past".
- **Tokens:** `size.card.aspectRatio`, `size.card.thumb|sm|md|lg`, `radius.card`, `color.card.frame`, `color.card.glow`, `color.card.reversedBadge`, `radius.xs` (badge), `elevation.2`, `type.numeral`, `type.cardName`.
- **States:** upright; **reversed** (art rotated 180° + vermilion "Reversed" `Badge`, name and badge never rotated); highlighted (glow halo, just revealed); zoomed (S17 `zoomed`); art loading (skeleton). Art never mirrored in RTL.
- **Screens:** S02 (The Star hero), S08 revealing / awaitingReading, S09, S13, S15, S16 (via `CardGridTile`), S17, S32, S14/S05 thumbs.
- **Golden:** [`taro_card/`](../../packages/taro_ui/test/golden/goldens/taro_card/) ([`deck_golden_test.dart`](../../packages/taro_ui/test/golden/deck_golden_test.dart)).

### `TaroCardBack` — 02 §14.3 (design system **TarotCard**, face-down)
- **Purpose:** the face-down card, identical in both themes; semantics "Card back, position 2 of 3, double-tap to pick".
- **Tokens:** `color.card.back`, `color.card.frame` (ornament line), `radius.card`, `size.card.*`, `elevation.2`, `color.card.glow` (picked).
- **States:** idle, picked (glow + `elevation.3`), in flight, disabled.
- **Screens:** S05 daily-card teaser, S08, S13 `notDrawn`, S10 `holdLost` (picked cards stay face-down), `CardBack` artboard.
- **Golden:** [`taro_card/`](../../packages/taro_ui/test/golden/goldens/taro_card/) ([`deck_golden_test.dart`](../../packages/taro_ui/test/golden/deck_golden_test.dart)).

### `TaroCardFlip` — 02 §14.3
- **Purpose:** animates back → face.
- **Tokens:** `motion.ritual.flip`, `motion.ritual.dealStagger`, `motion.easing.emphasized`, `haptic.flip`.
- **States:** back, flipping, face; reduced motion → ≤ 200 ms crossfade.
- **Screens:** S08 `revealing`, S13 `revealing`.
- **Golden:** [`taro_card_flip/`](../../packages/taro_ui/test/golden/goldens/taro_card_flip/) ([`deck_golden_test.dart`](../../packages/taro_ui/test/golden/deck_golden_test.dart)).

### `CardFan` — Phase 15 (not in 02)
- **Purpose:** horizontally scrollable arc of the remaining backs ("Deck, 76 cards"), with the "Draw for me" button alternative.
- **Tokens:** `size.card.sm`, `color.card.back`, `color.card.frame`, `color.card.glow`, `elevation.2`/`elevation.3`, `motion.ritual.shuffle`, `motion.easing.emphasized`, `haptic.pick`.
- **States:** shuffling (hold-to-shuffle loop ≥ `motion.ritual.shuffle`), idle, card focused/picked, exhausted; reduced motion (static fan, crossfade).
- **Screens:** S08 `picking` (the `shuffling` state shows a stacked deck instead).
- **Usage (S08, Phase 16):** pass `focusedIndex` (default: the centre card) so "Pick this card" is always available, and pick directly in `onFocus` (a tap picks, 01 §8.3); wrap the fan in a `RepaintBoundary` (02 §17); pass null callbacks once every slot is filled.
- **Golden:** [`card_fan/`](../../packages/taro_ui/test/golden/goldens/card_fan/) ([`deck_golden_test.dart`](../../packages/taro_ui/test/golden/deck_golden_test.dart)).

### `SpreadCanvas` — 02 §14.3
- **Purpose:** lays out cards (or empty slots) from the normalized `PositionLayout`; each slot has its position label; RTL mirrors x (`x → 1 - x`), art never mirrored; reflows to a vertical list above 1.5× text scale. The empty slot is a dashed `color.border.strong` outline with the position number.
- **Tokens:** `size.card.sm|md`, `color.border.strong` (empty slot), `type.label` (position), `type.numeral`, `space.4`, `motion.ritual.dealStagger`.
- **States:** empty slots, partially picked ("2 of 3"), full, revealing, compact row (S09/S15 header strip), vertical list (large text); Celtic Cross crossing card rotated 90°.
- **Screens:** S08, S09, S15, S32; S13 (single).
- **Golden:** [`spread_canvas/`](../../packages/taro_ui/test/golden/goldens/spread_canvas/) ([`deck_golden_test.dart`](../../packages/taro_ui/test/golden/deck_golden_test.dart)).

### `SpreadDiagram` — **NEW → Phase 15**
- **Purpose:** static, non-interactive diagram of a spread's layout (outline cards, numbered positions), drawn from the same `PositionLayout` as `SpreadCanvas`. Small size in the spread picker; large numbered size with a position legend in the guide. One semantics label describes the layout ("Celtic Cross layout: cards 1 to 6 form a cross…").
- **Tokens:** `color.card.frame` (outlines), `color.text.tertiary` / `type.caption` (numbers), `radius.xs`, `size.card.aspectRatio`, `color.accent.primary` (selected).
- **States:** small / large; selected (in a selected `TaroListTile`); RTL mirrored x.
- **Screens:** S06 (all six spreads), S18 (spread detail, e.g. Celtic Cross). Also the source for the 6 spread-diagram assets.
- **Golden:** [`spread_diagram/`](../../packages/taro_ui/test/golden/goldens/spread_diagram/) ([`deck_golden_test.dart`](../../packages/taro_ui/test/golden/deck_golden_test.dart)).

### `CardGridTile` — **NEW → Phase 15**
- **Purpose:** a tappable deck-browser cell: card thumb, numeral/rank, name; semantics "The Magician, Major Arcana, card 2 of 22".
- **Tokens:** `size.card.sm`, `radius.card`, `type.numeral`, `type.label`, `color.text.primary`, `space.3`, `size.touchTarget.min`.
- **States:** default, pressed, focus; art loading.
- **Screens:** S16.
- **Golden:** [`card_grid_tile/`](../../packages/taro_ui/test/golden/goldens/card_grid_tile/) ([`deck_golden_test.dart`](../../packages/taro_ui/test/golden/deck_golden_test.dart)).

### `SuitGlyph` — **NEW → Phase 15**
- **Purpose:** the custom suit icons (wand, cup, sword, pentacle) and the Major Arcana star, drawn to the Material Symbols Rounded 1.5 px stroke; always paired with the suit name (colour never the only signal). Ships with the small custom `TaroIcons` set used alongside Material Symbols Rounded (weight 300).
- **Tokens:** `color.suit.major|wands|cups|swords|pentacles`, `size.icon.sm|md`.
- **States:** default; decorative (`excludeSemantics`) when next to its name.
- **Screens:** S14 patterns chart, S16 suit filter, S17 meta line ("Minor Arcana · Cups"), S09/S15/S32 card captions.
- **Golden:** [`suit_glyph/`](../../packages/taro_ui/test/golden/goldens/suit_glyph/) ([`deck_golden_test.dart`](../../packages/taro_ui/test/golden/deck_golden_test.dart)).

---

## 5. Reading

### `ReadingTextView` — 02 §14.3
- **Purpose:** long-form, selectable reading text capped at `layout.readingMaxWidth`; includes the quoted question and the reading title.
- **Tokens:** `type.bodyReading`, `type.headline` (title), `type.body` italic quote, `color.text.primary`, `color.text.secondary`, `layout.readingMaxWidth`, `motion.ritual.readingReveal`.
- **States:** revealing (section stagger; none under reduced motion), content, loading from storage (skeleton), 200% text scale (never truncates); a `ReadingTextSection(collapsible: true)` heading is a button (`Semantics(expanded:)`, ≥ 48 dp) that hides its body over `motion.duration.base` (at once under reduced motion), expanded by default.
- **Usage (Phase 16.4):** S09 passes the summary without a heading, one collapsible section per position and the synthesis; the reflection prompts and "Write about this" go in `footer`. S32 uses `AiGeneratedLabel.classic` as the source label, no title, and `subheading` = position description · short meaning. The mini spread above it is the app's `ReadingMiniSpread` (`SpreadCanvas` at `size.card.md`). The S09 rating row reuses `ReadingRatingControl` (the spec's `RatingBar`) + `TaroChip.filter` reasons; the S27 resource row is app-private (`_CrisisResourceRow` in `crisis_resources_screen.dart`).
- **Screens:** S09, S15 (excerpt), S32, S13 (authored meaning), S17 (upright / reversed meaning), S19, S29.
- **Golden:** [`reading_text_view/`](../../packages/taro_ui/test/golden/goldens/reading_text_view/) ([`reading_components_golden_test.dart`](../../packages/taro_ui/test/golden/reading_components_golden_test.dart)).

### `ReadingSectionHeader` — Phase 15 (not in 02)
- **Purpose:** section heading inside a reading ("Present · The Star, reversed", "Where you are now"), `Semantics(header: true)`, with the vermilion section marker.
- **Tokens:** `type.title` / `type.titleSmall`, `color.accent.secondary` (marker), `color.text.secondary` (sub-line).
- **States:** default.
- **Screens:** S09, S32, S17 ("Upright meaning", "Reversed meaning"), S18, S19.
- **Golden:** [`reading_rating_classic_label/`](../../packages/taro_ui/test/golden/goldens/reading_rating_classic_label/) ([`reading_components_golden_test.dart`](../../packages/taro_ui/test/golden/reading_components_golden_test.dart)).

### `AiGeneratedLabel` — Phase 15 (not in 02)
- **Purpose:** the reading-source label. *AI* variant: "AI-generated" in the reading header. *Classic* variant: "Classic reading" + one-line explanation ("Built from the meaning of each card in its position. No AI, free and works offline.").
- **Tokens:** `type.caption`, `color.text.tertiary`, `size.icon.sm`, `radius.full`/`radius.md`.
- **States:** ai, classic.
- **Screens:** S09, S15 (ai); S32 (classic).
- **Golden:** [`reading_text_view/`](../../packages/taro_ui/test/golden/goldens/reading_text_view/) ([`reading_components_golden_test.dart`](../../packages/taro_ui/test/golden/reading_components_golden_test.dart)); [`reading_rating_classic_label/`](../../packages/taro_ui/test/golden/goldens/reading_rating_classic_label/) ([`reading_components_golden_test.dart`](../../packages/taro_ui/test/golden/reading_components_golden_test.dart)).

### `DisclaimerFooter` — 02 §14.3 (app)
- **Purpose:** the `disclaimerShort` caption "For entertainment and self-reflection. Not professional advice." at the end of every reading state (05 §3). The source label is not part of it: AI readings carry the `aiLabel` "AI-generated" `SourceLabel`/`Badge` in the header, Classic readings the "Classic reading" label. Also in the S11 / S10 footer.
- **Tokens:** `type.caption`, `color.text.tertiary`, `space.7`.
- **States:** ai, classic; present in loading and error states too.
- **Screens:** S09, S15, S32, S10, S11, S19.
- **Golden:** none in `taro_ui` (app-level widget; covered by the Phase 16–17 reading-screen goldens in `apps/taro`).

### `Badge` — 02 §14.3 (Phase 15 writes it `TaroBadge`)
- **Purpose:** small non-interactive label. Variants: *reversed* (vermilion, on card faces), *best value* (S11), *status* (Pending, Classic, Reported), *keyword* (card keyword pills: "Hope", "Renewal", "Quiet faith"), *ad label* ("Ad").
- **Tokens:** `color.card.reversedBadge` + `color.text.onAccent`, `color.accent.subtle`, `color.bg.sunken`, `type.caption`/`type.label`, `radius.xs` (reversed) / `radius.full`.
- **States:** per variant.
- **Screens:** S08, S09, S15, S32 (reversed); S11 (best value); S14, S05 (Pending, Classic); S13, S17 (keywords); S05, S14, S16 (ad label inside `BannerContainer`).
- **Golden:** [`segmented_choice_badge_countdown/`](../../packages/taro_ui/test/golden/goldens/segmented_choice_badge_countdown/) ([`layout_components_golden_test.dart`](../../packages/taro_ui/test/golden/layout_components_golden_test.dart)); [`product_offer_tile/`](../../packages/taro_ui/test/golden/goldens/product_offer_tile/) ([`monetization_golden_test.dart`](../../packages/taro_ui/test/golden/monetization_golden_test.dart)).

### `CountdownText` — 02 §14.3
- **Purpose:** server-time-based relative time ("Your next free reading arrives at midnight", "in 5 h 12 min", "Available again in 4 min"). Never a fake timer.
- **Tokens:** `type.body`/`type.caption`, `color.text.secondary`.
- **States:** future time, reached (re-sync), unknown (offline copy).
- **Screens:** S10, S11, S07 `dailyLimitReached`, S31 `freePaused`.
- **Golden:** [`segmented_choice_badge_countdown/`](../../packages/taro_ui/test/golden/goldens/segmented_choice_badge_countdown/) ([`layout_components_golden_test.dart`](../../packages/taro_ui/test/golden/layout_components_golden_test.dart)).

---

## 6. Monetization

### `BalanceChip` — 02 §14.3 (app) over `BalancePill` — **NEW → Phase 15** (`BalancePill`)
- **Purpose:** the reading balance as a sentence ("1 free reading", "3 readings · 1 free today", "0 readings"), with an ochre dot; tapping opens S10 / S11. `BalanceChip` (app, Phase 13/16) owns the sync states; `BalancePill` is its stateless `taro_ui` visual.
- **Tokens:** `color.accent.subtle`, `color.text.primary`, `color.card.frame` (dot), `radius.full`, `type.label`, `size.touchTarget.min`.
- **States:** free available, credits, zero ("Free reading resets at midnight", never red or urgent), stale (offline glyph), device unverified ("Readings unavailable on this device" + Retry), updating (live-region announcement).
- **Screens:** S05, S07 ("1 free reading today"), S11 header ("0 readings"), S12 (Today behind the dialog: "Free reading used").
- **Golden:** [`balance_pill/`](../../packages/taro_ui/test/golden/goldens/balance_pill/) ([`monetization_golden_test.dart`](../../packages/taro_ui/test/golden/monetization_golden_test.dart)).

### `ProductOfferTile` — Phase 15 (not in 02) (design system **PackRow**)
- **Purpose:** one purchasable pack or Remove Banner Ads: title ("10 readings"), full localized store price as its own buy button, per-reading price, computed "Best value" badge; Semantics "10 readings for 4.99 US dollars, 50 cents per reading".
- **Tokens:** `color.bg.surface`, `radius.lg`, `elevation.1`, `type.titleSmall`, `type.label` (price), `type.caption` + `color.text.tertiary` (per reading), `color.accent.primary` (buy button), `Badge` best value.
- **States:** loading (skeleton), content, purchasing (this button spinner, others enabled), pending ("Waiting for approval"), owned (Remove ads: "Banner ads removed ✓"), hidden (`purchasesBlocked`, `store.enabled = false`). No pre-selection, no strikethrough, no timers.
- **Screens:** S11; S20 ("Remove Banner Ads $3.99" row reuses the price style).
- **Golden:** [`product_offer_tile/`](../../packages/taro_ui/test/golden/goldens/product_offer_tile/) ([`monetization_golden_test.dart`](../../packages/taro_ui/test/golden/monetization_golden_test.dart)).

### `BannerSlot` — 02 §14.3 (app) over `BannerContainer` — Phase 15 (not in 02)
- **Purpose:** `BannerContainer` is the fixed-height `color.ad.container` box with the "Ad" label, pinned above the tab bar, full width, ≥ `space.adGap` from any tap target; `BannerSlot` (app) fills it from AdMob only on `kBannerAllowList` screens.
- **Tokens:** `color.ad.container`, `radius.none`, `space.adGap`, `type.caption`, `color.text.tertiary`.
- **States:** reserved (loading), loaded, failed (collapses), ads removed (collapses), below `ads.bannerMinCompletedReadings` (absent).
- **Screens:** S05, S14, S16 only.
- **Golden:** [`banner_container/`](../../packages/taro_ui/test/golden/goldens/banner_container/) ([`monetization_golden_test.dart`](../../packages/taro_ui/test/golden/monetization_golden_test.dart)).

### `PatternsChart` — Phase 15 (not in 02)
- **Purpose:** suit-balance bars for the last 30 days, with counts and suit names (colour never the only signal), "Most drawn" line and the "Patterns in your draws, not predictions." caption; one semantics summary ("Suit balance: Major Arcana 9, Wands 4…").
- **Tokens:** `color.chart.suit.*`, `SuitGlyph`, `type.caption`, `type.titleSmall`, `color.bg.sunken` (track), `radius.full`.
- **States:** content, too few readings (empty copy), RTL (bars grow from the right).
- **Screens:** S14.
- **Golden:** [`patterns_chart/`](../../packages/taro_ui/test/golden/goldens/patterns_chart/) ([`monetization_golden_test.dart`](../../packages/taro_ui/test/golden/monetization_golden_test.dart)).

---

## 7. State kit (01 §8.2)

### `TaroLoadingView` — 02 §14.3
- **Purpose:** per-screen skeleton made of `SkeletonBlock`s; no infinite spinners.
- **Tokens:** `color.skeleton.base`, `color.skeleton.highlight`, `motion.duration.slow` (shimmer; static under reduced motion).
- **Screens:** S05 `loading`, S09/S32 `loadingFromStorage`, S11 `loading`★, S14 `loading`, S24 `preparing`, S25 `validating`.
- **Golden:** [`taro_loading_view/`](../../packages/taro_ui/test/golden/goldens/taro_loading_view/) ([`state_kit_golden_test.dart`](../../packages/taro_ui/test/golden/state_kit_golden_test.dart)).

### `SkeletonBlock` — 02 §14.3
- **Purpose:** one placeholder shape (text line, card, row).
- **Tokens:** `color.skeleton.base`, `color.skeleton.highlight`, `radius.sm` / `radius.card`.
- **Screens:** inside `TaroLoadingView`, `ProductOfferTile` loading, `TaroCardFace` art loading.
- **Golden:** [`taro_loading_view/`](../../packages/taro_ui/test/golden/goldens/taro_loading_view/) ([`state_kit_golden_test.dart`](../../packages/taro_ui/test/golden/state_kit_golden_test.dart)); [`product_offer_tile/`](../../packages/taro_ui/test/golden/goldens/product_offer_tile/) ([`monetization_golden_test.dart`](../../packages/taro_ui/test/golden/monetization_golden_test.dart)).

### `TaroEmptyView` — 02 §14.3
- **Purpose:** illustration, title, body, action. Also the full-screen blocking layout.
- **Tokens:** `type.headline`/`type.title`, `type.body`, `color.text.secondary`, `space.7`, empty-state illustrations (`docs/design/assets/empty/*`).
- **Screens:** S14 `empty`★ ("Your readings will live here" + Start a reading), S14 `filteredEmpty` / `searchEmpty`, S16 `searchEmpty`, S30 (update required: icon, title, body, reassurance, Update), S12 `granted`.
- **Golden:** [`taro_empty_view/`](../../packages/taro_ui/test/golden/goldens/taro_empty_view/) ([`state_kit_golden_test.dart`](../../packages/taro_ui/test/golden/state_kit_golden_test.dart)).

### `TaroErrorView` — 02 §14.3
- **Purpose:** error by `ErrorKind` (network, server, rateLimited, deviceUnverified, storage, invalidFile, unknown) with the allowed action.
- **Tokens:** `color.status.error` (icon), `type.title`, `type.body`, `color.text.secondary`, `TaroButton`.
- **Screens:** S01 `storageError`, S08 `generationFailed` / `deliveryExpired`, S11 `storeUnavailable` / `failed`, S14 `storageError`, S24 `failed`, S25 `invalid`★ / `failed`, S33 `failed`.
- **Golden:** [`taro_error_view/`](../../packages/taro_ui/test/golden/goldens/taro_error_view/) ([`state_kit_golden_test.dart`](../../packages/taro_ui/test/golden/state_kit_golden_test.dart)).

### `TaroOfflineBanner` — 02 §14.3
- **Purpose:** non-blocking top banner when offline.
- **Tokens:** `color.status.info` / `color.bg.surfaceRaised`, `type.label`, `size.icon.sm`.
- **Screens:** S05 `balanceStale`, S07 `offline`, S33 `offline`, any network screen.
- **Golden:** [`taro_inline_notice/`](../../packages/taro_ui/test/golden/goldens/taro_inline_notice/) ([`state_kit_golden_test.dart`](../../packages/taro_ui/test/golden/state_kit_golden_test.dart)); [`taro_scaffold/`](../../packages/taro_ui/test/golden/goldens/taro_scaffold/) ([`state_kit_golden_test.dart`](../../packages/taro_ui/test/golden/state_kit_golden_test.dart)).

### `TaroInlineNotice` — 02 §14.3 (design system **InlineNotice**)
- **Purpose:** in-screen notice: kind icon, one-sentence title, optional body, optional actions. A *prominent* layout (larger, centred icon, two actions) covers S31.
- **Tokens:** `color.bg.surface`, `radius.md`, `color.status.*` (icon), `type.titleSmall`, `type.body`, `color.text.secondary`.
- **States:** info, success, warning, error; dismissible (S05 `updateAvailable`); with action.
- **Screens:** S05 `updateAvailable`, `deviceUnverified`; S07 `offline`, `dailyLimitReached`, `rephrase`, `refused(category)`★ (refusal card), `rateLimited`; S08 `slowReading`; S24 "Backup saved…"; S25 "File checked. Everything looks right."; S31 "AI readings are paused for now"; S33 disclosure line; S21 "Past readings… keep their language"; S22 permission note / `permissionDenied`.
- **Golden:** [`taro_inline_notice/`](../../packages/taro_ui/test/golden/goldens/taro_inline_notice/) ([`state_kit_golden_test.dart`](../../packages/taro_ui/test/golden/state_kit_golden_test.dart)).

---

## New components → Phase 15

Not in 02 §14.3 and not yet in the Phase 15 task list; added to `docs/phases/PHASE_15_DESIGN_SYSTEM.md` Sprint 15.2:

| Class | Replaces / covers in the design | Screens |
|---|---|---|
| `TaroSurfaceCard` | generic surface container, tappable card | S05, S13, S14, S17, S22, S24, S25, S27, S31 |
| `TaroListTile` | surface row incl. selected and disabled-with-reason; hotline rows; S10 option rows | S06, S10, S16, S17, S19, S20, S23, S27, S28 |
| `JournalEntryTile` | journal row with status, note/favourite, Finish reading | S05, S14 |
| `IconBulletList` | icon + statement lists (value, rules, data handling) | S02, S03, S24, S26, S30 |
| `SettingsSection` | titled group of settings rows | S20, S23 |
| `TaroRadioTile` (row + card) | language list, import mode "radio card", report reasons, theme | S20, S21, S25, S33 |
| `WeekdayPicker` | reminder days (dropped for v1) | — |
| `TaroAccordion` | FAQ accordion | S28 |
| `TaroTabStrip` | legal document tabs | S29 |
| `StepIndicator` | onboarding step dots | S02–S04 |
| `NotificationPreview` | reminder preview | S22 |
| `SpreadDiagram` | spread layout diagrams (picker + guide) | S06, S18 |
| `CardGridTile` | deck browser cell | S16 |
| `SuitGlyph` (+ `TaroIcons`) | custom suit / Major Arcana glyphs | S09, S14, S15, S16, S17, S32 |
| `BalancePill` | stateless visual of the app-level `BalanceChip` | S05, S07, S11, S12 |
| `TaroBrandMark` | Taro mark + wordmark | S01, S30 |

Checked against 02 §14.3 and not new: `SegmentedChoice` (the design's segmented control), `TaroInlineNotice` (InlineNotice), `Badge` (keyword pills, best value, status), `BalanceChip` / `BannerSlot` / `DisclaimerFooter` (app-level in 02 §14.3). Already in Phase 15 but not in 02: `TaroTabBar`, `TaroChip`, `CardFan`, `ReadingSectionHeader`, `AiGeneratedLabel` (now with a Classic variant), `ProductOfferTile` (PackRow), `BannerContainer`, `PatternsChart`.

Designed after the first pass (2026-09-27), NEW → Phase 15:
- `TaroCoachmark` — single dismissible coachmark with scrim that never covers the banner container; S05 first run (`TodayFirstRun.dc.html`). Usage (Phase 16): S05 wraps its whole `TaroScaffold` in `TaroCoachmarkLayer` (the tab bar is outside, and S05 drops the banner in first run), keys the CTA card as the target and re-measures on scroll; taps inside the hole reach the target, and on tablets the bubble keeps `layout.maxContentWidth`. Golden: [`taro_coachmark/`](../../packages/taro_ui/test/golden/goldens/taro_coachmark/) ([`containers_golden_test.dart`](../../packages/taro_ui/test/golden/containers_golden_test.dart)).
- `TaroToast` — snackbar with optional Undo action; S09 rated (`ReadingRated.dc.html`), S11 `success`, S15 `deleted`. Golden: [`taro_toast/`](../../packages/taro_ui/test/golden/goldens/taro_toast/) ([`containers_golden_test.dart`](../../packages/taro_ui/test/golden/containers_golden_test.dart)).
- `ReadingRatingControl` — Helpful / Not helpful toggle buttons with aria-labels; S09 (`ReadingRated.dc.html`). Golden: [`reading_rating_classic_label/`](../../packages/taro_ui/test/golden/goldens/reading_rating_classic_label/) ([`reading_components_golden_test.dart`](../../packages/taro_ui/test/golden/reading_components_golden_test.dart)).
- ATT pre-prompt is a screen layout (`AttPrompt.dc.html`) built from `TaroScaffold` + `IconBulletList` + `TaroButton`; no new component.
