# Phase 15: Design System Implementation (`taro_ui`)

**Status:** ✅ Complete (2026-09-30) — pending: the Sprint 15.3 manual visual review against the design frames (owner decisions on `ReadingTextView` question style, `TaroBadge` status outline, `SettingsTile` chevron), the design-owner font-name decisions ("Noto Serif Arabic", "IBM Plex Sans" reserved name), the phase commit.
**Depends on:** Phase 14
**Parallel with:** Phase 18 Sprint 18.1 (art import)

---

## Overview

This phase turns the Claude Design output into code:
- a token generator (DTCG JSON → Dart constants + `TaroTokens` ThemeExtension);
- light and dark `ThemeData`;
- motion accessors that honour reduced motion;
- bundled fonts per script;
- the full `taro_ui` component library, each component with semantics, ≥ 48 dp targets and goldens in light/dark × LTR/RTL.

The temporary stub tokens from Phase 13 are deleted.

**Output of this phase:**
- `tools/tokens/generate.dart` → `packages/taro_ui/lib/src/tokens/generated/taro_tokens.g.dart` (generated, excluded).
- `TaroTheme.light()` / `.dark()`, `TaroTokens`, `context.tokens`, `context.motion`, `TaroHaptics`.
- The components from `docs/design/components.md` (at least the 02 §14.3 list, renamed per 01 §8.2 where they overlap, e.g. `TaroLoadingView`).
- Component goldens under `packages/taro_ui/test/golden/goldens/`.

---

## Specs referenced

`02_ARCHITECTURE.md` AR16, §14 (reconciled), §17 (art decode), §19 rules 11–14. `01_PRODUCT.md` §8.2, §12, §13, §14. `06_QUALITY_TESTING_CI.md` QA8, §3, §3.2, §6.2 (`check_forbidden_apis.py` raw-value rules). `04_MONETIZATION.md` §8 (`space.adGap`). `00_DECISIONS.md` RC15, RC24.

---

## Sprint 15.1: Token pipeline

**Tasks:**
- [x] `tools/tokens/generate.dart`: reads `docs/design/taro.tokens.json` (DTCG `$value`/`$type`, light and dark modes, aliases resolved) → `taro_tokens.g.dart`, with `const` values grouped as `TaroColorTokens`, `TaroTypeTokens`, `TaroSpaceTokens`, `TaroRadiusTokens`, `TaroElevationTokens`, `TaroMotionTokens`, `TaroSizeTokens`, `TaroLayoutTokens` and `TaroOpacityTokens`. Deterministic output. Tests on fixture token files, including a missing-mode error and an alias cycle error. Evidence: `tools/tokens/generate.dart`, `tools/dart_tools/lib/src/tokens/{token_set,token_values,dart_emitter}.dart` → `packages/taro_ui/lib/src/tokens/generated/taro_tokens.g.dart`; `tools/dart_tools/test/tokens/` (fixtures incl. missing-mode and alias-cycle); `generate --check` in verify.sh and CI.
- [x] `taro_ui/lib/src/theme/taro_tokens_extension.dart`: `TaroTokens extends ThemeExtension<TaroTokens>` with `copyWith` and `lerp`. `taro_theme.dart` builds Material 3 `ThemeData` (`ColorScheme` mapped from the semantic tokens, text theme from the type roles) for light and dark. Evidence: `lib/src/theme/{taro_tokens_extension,taro_theme}.dart`; `test/src/theme/`. Note: type styles are `context.tokens.typography` (`ThemeExtension.type` is reserved).
- [x] `motion/taro_motion.dart`: `context.motion.*` returns the reduced-motion values when `MediaQuery.disableAnimations` or `UserSettings.reduceMotion` is set (01 §14.4). `a11y/taro_haptics.dart` implements the `haptic.pick/flip/ready` tokens, gated by the haptics setting. Evidence: `lib/src/motion/taro_motion.dart`, `lib/src/a11y/{taro_a11y_scope,taro_haptics}.dart`; the app feeds `UserSettings.reduceMotion` / `hapticsEnabled` through `TaroA11yScope` in `apps/taro/lib/app.dart` (`test/routing/router_test.dart` `script fonts, reduce motion and haptics reach taro_ui`).
- [x] Fonts: bundle the families named by the tokens (Latin, Cyrillic, Arabic, CJK, Hangul subsets) under `taro_ui/fonts/`. There is no runtime Google Fonts fetch (01 §13). Check the size budget against 02 §17 and record it in `docs/ARCHITECTURE.md`. Evidence: `packages/taro_ui/fonts/` (21 subset TTFs, OFL licences, `build_fonts.sh`), `registerTaroFontLicenses()` called from bootstrap; size budget (11.7 MB raw, ~6 MB compressed) in `docs/ARCHITECTURE.md` §Design system. Script-aware theme via `themeForScript` in the app.
- [x] Delete `stub_tokens.dart`. `check_forbidden_apis.py` now has zero exceptions outside `lib/src/tokens/` and `lib/src/motion/`. Evidence: never created (Phase 13 used the real kit); `check_forbidden_apis.py` OK with no exceptions outside `lib/src/tokens/` and `lib/src/motion/`.
- [x] `tools/tokens/validate_tokens.dart` (moved here from Phase 14.3, because Dart tooling exists only after Phases 2–3): every 01 §14 token name exists in both modes, `$extensions["taro.reducedMotion"]` exists on every `motion.*` token, `font.family.{role}.{script}` is complete, and the contrast pairs pass (same pairs as the Phase 14 Python check in `docs/design/REVIEW.md`). Runs in CI. Evidence: `tools/tokens/validate_tokens.dart` + `tools/dart_tools/lib/src/tokens/{contract,validator}.dart`; `tokens: validate_tokens` step in verify.sh / `reusable-static.yml`.
- [x] Test: every token name in the 01 §14 contract exists in both modes (02 §14.1), and every contrast pair passes via the `validate_tokens` logic reused in Dart. Evidence: `tools/dart_tools/test/tokens/` (contract in both modes, contrast pairs).

---

## Sprint 15.2: Components

**Tasks:**
- [x] Components designed in Phase 14's second pass: `TaroCoachmark` (S05 first run; scrim never covers the banner), `TaroToast` (with Undo; S09, S11, S15), `ReadingRatingControl` (S09). Goldens light/dark + `ar`. Evidence: `lib/src/components/feedback/{taro_coachmark,taro_toast}.dart`, `lib/src/components/reading/reading_rating_control.dart`; goldens `test/golden/goldens/{taro_coachmark,taro_toast,reading_rating_control}/`.
- [x] Layout and structure: `TaroScaffold`, `TaroAppBar`, `TaroTabBar`, `TaroSheet`, `TaroDialog`, `SettingsTile`, `SegmentedChoice`, `TaroBadge`, `CountdownText` (server-time based; no fake timers). Evidence: `lib/src/components/layout/` (`taro_scaffold`, `taro_app_bar`, `taro_tab_bar`, `taro_sheet`, `taro_dialog`, `settings_tile`, `segmented_choice`, `taro_badge`, `countdown_text`); `test/src/components/layout_components_test.dart`, `countdown_text_test.dart`.
- [x] Inputs and actions: `TaroButton` (primary, secondary, tertiary, destructive, loading), `TaroIconButton`, `TaroTextField` (with a grapheme counter from 250), `TaroChip` (suggestion chips). Evidence: `lib/src/components/actions/taro_button.dart`, `lib/src/components/inputs/{taro_icon_button,taro_text_field,taro_chip}.dart`; `test/src/components/{taro_button,inputs,taro_text_field}_test.dart`.
- [x] Deck rendering: Evidence: `lib/src/components/deck/{taro_card_face,taro_card_back,taro_card_flip,spread_canvas,spread_layout,card_fan}.dart`; `test/src/components/deck/`, goldens `taro_card`, `taro_card_flip`, `spread_canvas`, `card_fan`.
  - `TaroCardFace` (an `ImageProvider` plus a semantics label like "Three of Cups, reversed, position: Past"; the reversed badge is text and rotation);
  - `TaroCardBack` ("Card back, position 2 of 3, double-tap to pick");
  - `TaroCardFlip`;
  - `SpreadCanvas` (normalized `x/y/rotationDeg` layout, RTL mirror `x → 1 - x`, art never mirrored, reflow to a vertical list above 1.5× text scale; 01 §12);
  - `CardFan` (horizontally scrollable arc of 78 backs, with a "Draw for me" alternative to the gesture).
- [x] Reading: `ReadingTextView` (selectable, `type.bodyReading`, max width token), `ReadingSectionHeader` (`Semantics(header: true)`), `AiGeneratedLabel`. Evidence: `lib/src/components/reading/{reading_text_view,reading_section_header,ai_generated_label}.dart`; `test/src/components/reading_components_test.dart`.
- [x] State kit (restyled): `TaroLoadingView` (skeleton per screen), `TaroEmptyView(illustration, title, body, action)`, `TaroErrorView(kind, onRetry)`, `TaroOfflineBanner`, `TaroInlineNotice(kind)`, `SkeletonBlock`. Evidence: `lib/src/components/state/` (`taro_loading_view`, `skeleton_block`, `taro_shimmer`, `taro_empty_view`, `taro_error_view`, `taro_offline_banner`, `taro_inline_notice`); `test/golden/state_kit_golden_test.dart`.
- [x] Monetization visuals: `ProductOfferTile` (price, count, per-reading price, computed best-value badge; Semantics per 04 §11) and `BannerContainer` (fixed height, `color.ad.container`, `space.adGap` ≥ 16 dp separation, RC59). Evidence: `lib/src/components/monetization/{product_offer_tile,banner_container,balance_pill}.dart`; `test/src/components/monetization/`.
- [x] `PatternsChart` (suit balance bars using the `color.chart.suit.*` tokens; colour is never the only signal). Evidence: `lib/src/components/data/patterns_chart.dart`; `test/src/components/monetization/patterns_brand_test.dart`.
- [x] New from the Phase 14 designs (not in 02 §14.3; see `docs/design/components.md` § New components): Evidence: `lib/src/components/containers/`, `inputs/{taro_radio_tile,weekday_picker,taro_accordion,taro_tab_strip,step_indicator}.dart`, `deck/{spread_diagram,card_grid_tile}.dart`, `icons/{taro_icons,suit_glyph}.dart`, `monetization/balance_pill.dart`, `brand/taro_brand_mark.dart`; tests under `test/src/components/`. `WeekdayPicker` is built but unused (dropped for v1 in components.md).
  - containers and rows: `TaroSurfaceCard` (surface container, optionally tappable/highlighted), `TaroListTile` (leading/title/subtitle/trailing; selected; disabled-with-reason per 04 §9.1; trailing action for S27 hotline rows), `JournalEntryTile` (status Pending/Classic, note and favourite indicators, "Finish reading" action), `IconBulletList` (S02–S04, S24, S26), `SettingsSection` (titled group of `SettingsTile`s), `NotificationPreview` (S22, never shows the card);
  - inputs and navigation: `TaroRadioTile` (row and card styles; S21, S25, S33, theme sheet), `WeekdayPicker` (multi-select days, full day names in semantics, locale first weekday), `TaroAccordion` (FAQ, `Semantics(expanded:)`, no height animation under reduced motion), `TaroTabStrip` (scrollable `role=tab` strip for S29), `StepIndicator` ("Step 1 of 3");
  - deck: `SpreadDiagram` (static numbered layout from `PositionLayout`, small for S06 and large with legend for S18, RTL-mirrored x, one layout semantics label), `CardGridTile` (S16 deck cell), `SuitGlyph` + the custom `TaroIcons` set (suit and Major Arcana glyphs at the Material Symbols Rounded 1.5 px stroke);
  - brand and monetization visuals: `BalancePill` (stateless visual for the app-level `BalanceChip`: free / credits / zero / stale / unverified), `TaroBrandMark` (mark + wordmark for S01 and S30).
- [x] `AiGeneratedLabel` gets a `classic` variant ("Classic reading" + one-line explanation, S32). Evidence: `AiGeneratedLabel.classic` in `lib/src/components/reading/ai_generated_label.dart`; golden `ai_generated_label/`.
- [x] Every component ships with: Evidence: widget tests + `expectMeetsGuidelines` (`test/src/components/guidelines.dart`) per component; 190 goldens light/dark × en/ar at `kPhoneSmall`, `kTabletIpad13` for layout-level components, `_x2` for text-heavy ones.
  - a widget test (states, callbacks, semantics);
  - `meetsGuideline(androidTapTargetGuideline | iOSTapTargetGuideline | labeledTapTargetGuideline | textContrastGuideline)`;
  - goldens `{light,dark} × {en,ar}` at `kPhoneSmall`, plus `kTabletIpad13` for layout-level components (`TaroScaffold`, sheets, navigation) (RC24), plus `textScale 2.0` for the text-heavy components.

---

## Sprint 15.3: Golden baseline

**Tasks:**
- [ ] Generate the component goldens on the reference macOS runner via `golden.yml` `update: true` (QA8). Review the diffs against the `docs/design/screens/**` reference frames *(MANUAL visual check)*. *(Goldens generated 2026-09-30 on this Mac, which `golden_update.py` accepts as the reference platform (macOS arm64, Flutter 3.44.8): 190 PNGs, `melos run test:golden` green. Manual review pending; the open design differences are listed in `docs/ARCHITECTURE.md` §Design system.)*
- [x] `docs/design/components.md`: link each component to its golden file. Evidence: every component entry in `docs/design/components.md` has a **Golden:** link.

---

## Done when

- [x] `taro_ui` ≥ 90%; `tools/dart_tools` (token generator) ≥ 90%. Evidence (2026-09-30, `tools/verify.sh` full): taro_ui 99.97 % (65 files), dart_tools 99.30 % (token files 95.9–100 %).
- [x] `check_forbidden_apis.py` shows no raw colours, sizes or durations anywhere outside the token and motion folders. Evidence: `check_forbidden_apis.py` OK (verify.sh).
- [ ] Component goldens are committed from the reference runner. *(Generated on the reference platform; committed with the phase commit.)*
- [x] Docs: `docs/ARCHITECTURE.md` §Design system; the CLAUDE.md token rules confirmed. CHANGELOG updated. Evidence: `docs/ARCHITECTURE.md` §Design tokens / §Design system (component list, font budget, golden baseline, open design differences) and §Root widget wiring; CLAUDE.md rule 15 holds (tokens only; `TaroStrokes` names border widths); `CHANGELOG.md`.
- [ ] One commit: `feat(taro): Phase 15 — Design system implementation`.

## Next phase

Phase 16: UI — Onboarding, Today & Reading Flow.
