# S10 · Out-of-readings sheet

| | |
|---|---|
| Route | modal bottom sheet (over S07, or over S05 from the balance chip) |
| Banner | none (no banner in a sheet; the underlying screen's banner hides while it is open) |
| Artboards | [`../OutOfReadings.dc.html`](../OutOfReadings.dc.html) |
| Frames | [`OutOfReadings.png`](../frames/OutOfReadings.png) (PNG @2x, from the artboards above) |
| Next | Rewarded row → S12 · "Get more readings" → S11 · "Not now" / swipe down / back → close (question kept) |

## Layout (top → bottom)
Scrim `color.bg.scrim` (`opacity.scrim`) over the dimmed S07. Sheet: `color.bg.surfaceRaised`, top corners `radius.sheet`, padding `space.4` / `space.6` / 36 (+ safe area), gap `space.6`.
1. Drag handle 36 × 4, `color.border.strong`.
2. Title serif 24 `type.cardName` "You've used today's free reading"; body `type.body` `color.text.secondary` "Your question and spread are saved."
3. **Free path (must be visible, 04 §11):** a `CountdownText` line with a clock icon, `type.body`/500 `color.text.primary`: "Next free reading in 3 h 12 min (at 00:00)" (01 §7.1 wording + the reset time from 04 §11), computed from server time. **Resolved**: drawn on `OutOfReadings.dc.html` (it replaced the static "arrives at midnight").
4. Option rows, gap `space.3` (canvas 10): each `color.bg.surface`, `radius.lg`, padding `space.4` / `space.5`; an icon tile 40 (`radius.md`, `color.accent.subtle`); the title `type.body`/500 and meta `type.caption`.
   - Rewarded → S12: shown only when `free.remaining == 0` (RC34). **Its label says it is an ad** (04 §9.1): "Watch an ad for 1 reading", meta "Optional · 3 left today". **Resolved**: the canvas "Watch a short video / Earn 1 reading" was reworded (the same wording as the S11 row, from 04 §9.1), and the row now links to `Rewarded.dc.html`.
   - "Get more readings", meta "From $1.99 for 3 · readings don't expire" (store-localized price).
5. "Until then:" + two outlined pill links (44 visual / 48 hit) to the daily card (S13) and Learn (S16) (01 F3). **Resolved**: drawn on `OutOfReadings.dc.html`.
6. `TaroButton.secondary` "Not now", full width, 52 (neutral copy, no confirmshaming).
7. Footer (04 §11 Legal): Terms · Privacy links (44 → 48 hit) + `disclaimerShort` "For entertainment and self-reflection. Not professional advice." in `type.caption`. 04 §11 says 05 owns this text; 05 §3's paywall string is `disclaimerShort`, so it replaces 04's paraphrase "Readings are for entertainment and self-reflection.". **Resolved**: drawn on `OutOfReadings.dc.html`.

## Components
`TaroSheet`, `CountdownText`, option row (`SettingsTile` variant with an icon tile), `TaroButton`, `SkeletonBlock`, `TaroInlineNotice`.

## States (01 §8.3)
| State | ★ | Source |
|---|---|---|
| `content`: rewarded available + packs loaded | ★ | **Designed**: `OutOfReadings.dc.html` (countdown, ad label, daily card / Learn links and legal footer all drawn) |
| rewarded cooling down | | Derived: the row is disabled (`opacity.disabled`), meta "Another ad reward is available in 4 min" |
| rewarded capped today | | Derived: disabled, "You've used today's ad rewards" |
| rewarded disabled by config | | Derived: the row is hidden (nothing to wait for) |
| rewarded failed to load | | Derived: disabled for 60 s, "No ads available right now" |
| packs loading | | Derived: the meta line is a `SkeletonBlock` |
| store unavailable / `purchasesBlocked` | | Derived: the pack row is hidden or disabled with a neutral line; the free path + rewarded stay |
| `lowTrustLimited` copy | | Derived: title "Free readings aren't available on this device right now" |
| always | | "Next free reading in …" is shown in every combination |

## Motion
Sheet in: slide + fade `motion.duration.slow`, `motion.easing.decelerate`; out: `motion.duration.base`, `motion.easing.accelerate`; scrim fade `motion.duration.base`. Reduced: fade only (200 ms). The countdown updates once a minute, with no ticking animation.

## Semantics / reading order
Dialog labelled "Out of readings"; focus starts on the title → body → countdown → option rows (a disabled row announces its reason) → daily card / Learn links → Not now → legal links → disclaimer. Back and swipe-down close it immediately.

## RTL
Icon tiles on the right; text right-aligned; the countdown uses locale numerals.

## Banner
None. Opening S10 never follows a revealed reading (the gate runs before the draw, MO13).

---

**Conventions (same in every S-spec).** Canvas px = dp/sp. Spacing 2/4/8/12/16/20/24/32/40/48/56/64 = `space.1`…`space.12`; odd canvas values (6, 10, 14, 18, 28) snap to the nearest token. Radius: 4 `radius.xs`, 8 `radius.sm`, 10 `radius.card`, 12 `radius.md`, 16 `radius.lg`, 24 `radius.xl`, 28 `radius.sheet`, 999 `radius.full`. Type: serif 40 `type.display`; serif 28 `type.headline`; serif 20–24 `type.cardName`; serif 16–18 paragraphs `type.bodyReading`; sans 20/600 `type.title`; sans 17–18/600 `type.titleSmall`; sans 16 `type.body`; sans 14–15/500 `type.label`; sans 12–13 `type.caption`; numerals `type.numeral`. Nothing renders below 12 sp (canvas 9–11 px badges become `type.caption`). Side gutter `layout.gutter` (16; onboarding pages use `space.7` = 24). Tablet: the content column is `layout.maxContentWidth` (600) centred, long text is capped at `layout.readingMaxWidth`. Controls drawn at 40–44 px keep their look but get a ≥ `size.touchTarget.min` (48) hit area. Colours are tokens only (`color.*`, names in 01 §14.1). Every ★ state is a golden in light + dark at phone and tablet width (01 §8.3, RC24). *Derived* means that no artboard exists: Phase 16/17 builds the state from the designed states, the tokens and the shared state widgets (01 §8.2), and REVIEW.md checks it.
