# S30 · Update required (blocking)

| | |
|---|---|
| Route | `/update` (from S01 when `app.minVersion.{ios,android}` is not met) |
| Banner | none |
| Artboards | [`../UpdateRequired.dc.html`](../UpdateRequired.dc.html) |
| Frames | [`UpdateRequired.png`](../frames/UpdateRequired.png) (PNG @2x, from the artboards above) |

## Layout (top → bottom)
Padding 96 (`space.12` + safe area) / `space.7` / `space.9`; gap `space.8`.
1. Illustration 240 × 220 (decorative): a soft pill glow in `color.accent.subtle` behind three fanned `TaroCardBack`s.
2. Title "Please update Taro" serif 28; body `type.body` `color.text.secondary`: "This version of Taro can no longer get new readings. Update to keep drawing readings."
3. Reassurance panel (`color.bg.surface`, `radius.md`, padding `space.5`, shield icon): "**Your journal is safe.** It stays on this phone, and your readings balance and purchases stay too."
4. Flexible spacer.
5. `TaroButton.primary` "Update" (52) → store link; caption "Opens the App Store · You have Taro 1.0.0 (12)" (Android: "Opens Google Play").

Blocking: no back button, no tabs, no other action (store link only, 01 §8.3). Android system back leaves the app.

## Components
`TaroCardBack`, `TaroButton`, `TaroInlineNotice(info)` style panel.

## States (01 §8.3)
| State | ★ | Source |
|---|---|---|
| `content` | ★ | **Designed**: `UpdateRequired.dc.html` (iOS copy; the Android caption is derived) |

## Motion
None (static); a fade-in from S01 over `motion.duration.base`, instant when reduced.

## Semantics / reading order
Illustration excluded → title (header, initial focus) → body → reassurance → Update → caption.

## RTL
Mirrored text; the illustration fan mirrors its positions only.

## Banner
None.

---

**Conventions (same in every S-spec).** Canvas px = dp/sp. Spacing 2/4/8/12/16/20/24/32/40/48/56/64 = `space.1`…`space.12`; odd canvas values (6, 10, 14, 18, 28) snap to the nearest token. Radius: 4 `radius.xs`, 8 `radius.sm`, 10 `radius.card`, 12 `radius.md`, 16 `radius.lg`, 24 `radius.xl`, 28 `radius.sheet`, 999 `radius.full`. Type: serif 40 `type.display`; serif 28 `type.headline`; serif 20–24 `type.cardName`; serif 16–18 paragraphs `type.bodyReading`; sans 20/600 `type.title`; sans 17–18/600 `type.titleSmall`; sans 16 `type.body`; sans 14–15/500 `type.label`; sans 12–13 `type.caption`; numerals `type.numeral`. Nothing renders below 12 sp (canvas 9–11 px badges become `type.caption`). Side gutter `layout.gutter` (16; onboarding pages use `space.7` = 24). Tablet: the content column is `layout.maxContentWidth` (600) centred, long text is capped at `layout.readingMaxWidth`. Controls drawn at 40–44 px keep their look but get a ≥ `size.touchTarget.min` (48) hit area. Colours are tokens only (`color.*`, names in 01 §14.1). Every ★ state is a golden in light + dark at phone and tablet width (01 §8.3, RC24). *Derived* means that no artboard exists: Phase 16/17 builds the state from the designed states, the tokens and the shared state widgets (01 §8.2), and REVIEW.md checks it.
