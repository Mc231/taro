# Phase 15: Design System Implementation (`taro_ui`)

**Status:** ⬜ Not Started
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
- [ ] `tools/tokens/generate.dart`: reads `docs/design/taro.tokens.json` (DTCG `$value`/`$type`, light and dark modes, aliases resolved) → `taro_tokens.g.dart`, with `const` values grouped as `TaroColorTokens`, `TaroTypeTokens`, `TaroSpaceTokens`, `TaroRadiusTokens`, `TaroElevationTokens`, `TaroMotionTokens`, `TaroSizeTokens`, `TaroLayoutTokens` and `TaroOpacityTokens`. Deterministic output. Tests on fixture token files, including a missing-mode error and an alias cycle error.
- [ ] `taro_ui/lib/src/theme/taro_tokens_extension.dart`: `TaroTokens extends ThemeExtension<TaroTokens>` with `copyWith` and `lerp`. `taro_theme.dart` builds Material 3 `ThemeData` (`ColorScheme` mapped from the semantic tokens, text theme from the type roles) for light and dark.
- [ ] `motion/taro_motion.dart`: `context.motion.*` returns the reduced-motion values when `MediaQuery.disableAnimations` or `UserSettings.reduceMotion` is set (01 §14.4). `a11y/taro_haptics.dart` implements the `haptic.pick/flip/ready` tokens, gated by the haptics setting.
- [ ] Fonts: bundle the families named by the tokens (Latin, Cyrillic, Arabic, CJK, Hangul subsets) under `taro_ui/fonts/`. There is no runtime Google Fonts fetch (01 §13). Check the size budget against 02 §17 and record it in `docs/ARCHITECTURE.md`.
- [ ] Delete `stub_tokens.dart`. `check_forbidden_apis.py` now has zero exceptions outside `lib/src/tokens/` and `lib/src/motion/`.
- [ ] `tools/tokens/validate_tokens.dart` (moved here from Phase 14.3, because Dart tooling exists only after Phases 2–3): every 01 §14 token name exists in both modes, `$extensions["taro.reducedMotion"]` exists on every `motion.*` token, `font.family.{role}.{script}` is complete, and the contrast pairs pass (same pairs as the Phase 14 Python check in `docs/design/REVIEW.md`). Runs in CI.
- [ ] Test: every token name in the 01 §14 contract exists in both modes (02 §14.1), and every contrast pair passes via the `validate_tokens` logic reused in Dart.

---

## Sprint 15.2: Components

**Tasks:**
- [ ] Components designed in Phase 14's second pass: `TaroCoachmark` (S05 first run; scrim never covers the banner), `TaroToast` (with Undo; S09, S11, S15), `ReadingRatingControl` (S09). Goldens light/dark + `ar`.
- [ ] Layout and structure: `TaroScaffold`, `TaroAppBar`, `TaroTabBar`, `TaroSheet`, `TaroDialog`, `SettingsTile`, `SegmentedChoice`, `TaroBadge`, `CountdownText` (server-time based; no fake timers).
- [ ] Inputs and actions: `TaroButton` (primary, secondary, tertiary, destructive, loading), `TaroIconButton`, `TaroTextField` (with a grapheme counter from 250), `TaroChip` (suggestion chips).
- [ ] Deck rendering:
  - `TaroCardFace` (an `ImageProvider` plus a semantics label like "Three of Cups, reversed, position: Past"; the reversed badge is text and rotation);
  - `TaroCardBack` ("Card back, position 2 of 3, double-tap to pick");
  - `TaroCardFlip`;
  - `SpreadCanvas` (normalized `x/y/rotationDeg` layout, RTL mirror `x → 1 - x`, art never mirrored, reflow to a vertical list above 1.5× text scale; 01 §12);
  - `CardFan` (horizontally scrollable arc of 78 backs, with a "Draw for me" alternative to the gesture).
- [ ] Reading: `ReadingTextView` (selectable, `type.bodyReading`, max width token), `ReadingSectionHeader` (`Semantics(header: true)`), `AiGeneratedLabel`.
- [ ] State kit (restyled): `TaroLoadingView` (skeleton per screen), `TaroEmptyView(illustration, title, body, action)`, `TaroErrorView(kind, onRetry)`, `TaroOfflineBanner`, `TaroInlineNotice(kind)`, `SkeletonBlock`.
- [ ] Monetization visuals: `ProductOfferTile` (price, count, per-reading price, computed best-value badge; Semantics per 04 §11) and `BannerContainer` (fixed height, `color.ad.container`, `space.adGap` ≥ 16 dp separation, RC59).
- [ ] `PatternsChart` (suit balance bars using the `color.chart.suit.*` tokens; colour is never the only signal).
- [ ] New from the Phase 14 designs (not in 02 §14.3; see `docs/design/components.md` § New components):
  - containers and rows: `TaroSurfaceCard` (surface container, optionally tappable/highlighted), `TaroListTile` (leading/title/subtitle/trailing; selected; disabled-with-reason per 04 §9.1; trailing action for S27 hotline rows), `JournalEntryTile` (status Pending/Classic, note and favourite indicators, "Finish reading" action), `IconBulletList` (S02–S04, S24, S26), `SettingsSection` (titled group of `SettingsTile`s), `NotificationPreview` (S22, never shows the card);
  - inputs and navigation: `TaroRadioTile` (row and card styles; S21, S25, S33, theme sheet), `WeekdayPicker` (multi-select days, full day names in semantics, locale first weekday), `TaroAccordion` (FAQ, `Semantics(expanded:)`, no height animation under reduced motion), `TaroTabStrip` (scrollable `role=tab` strip for S29), `StepIndicator` ("Step 1 of 3");
  - deck: `SpreadDiagram` (static numbered layout from `PositionLayout`, small for S06 and large with legend for S18, RTL-mirrored x, one layout semantics label), `CardGridTile` (S16 deck cell), `SuitGlyph` + the custom `TaroIcons` set (suit and Major Arcana glyphs at the Material Symbols Rounded 1.5 px stroke);
  - brand and monetization visuals: `BalancePill` (stateless visual for the app-level `BalanceChip`: free / credits / zero / stale / unverified), `TaroBrandMark` (mark + wordmark for S01 and S30).
- [ ] `AiGeneratedLabel` gets a `classic` variant ("Classic reading" + one-line explanation, S32).
- [ ] Every component ships with:
  - a widget test (states, callbacks, semantics);
  - `meetsGuideline(androidTapTargetGuideline | iOSTapTargetGuideline | labeledTapTargetGuideline | textContrastGuideline)`;
  - goldens `{light,dark} × {en,ar}` at `kPhoneSmall`, plus `kTabletIpad13` for layout-level components (`TaroScaffold`, sheets, navigation) (RC24), plus `textScale 2.0` for the text-heavy components.

---

## Sprint 15.3: Golden baseline

**Tasks:**
- [ ] Generate the component goldens on the reference macOS runner via `golden.yml` `update: true` (QA8). Review the diffs against the `docs/design/screens/**` reference frames *(MANUAL visual check)*.
- [ ] `docs/design/components.md`: link each component to its golden file.

---

## Done when

- [ ] `taro_ui` ≥ 90%; `tools/dart_tools` (token generator) ≥ 90%.
- [ ] `check_forbidden_apis.py` shows no raw colours, sizes or durations anywhere outside the token and motion folders.
- [ ] Component goldens are committed from the reference runner.
- [ ] Docs: `docs/ARCHITECTURE.md` §Design system; the CLAUDE.md token rules confirmed. CHANGELOG updated.
- [ ] One commit: `feat(taro): Phase 15 — Design system implementation`.

## Next phase

Phase 16: UI — Onboarding, Today & Reading Flow.
