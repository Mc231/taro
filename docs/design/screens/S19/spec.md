# S19 · Learn: About tarot & Taro

| | |
|---|---|
| Route | `/learn/about` |
| Banner | none |
| Artboards | [`../AboutTaro.dc.html`](../AboutTaro.dc.html) |
| Frames | [`AboutTaro.png`](../frames/AboutTaro.png) (PNG @2x, from the artboards above) |
| Next | "Support and crisis lines" → S27 |

## Layout (top → bottom)
Padding `space.10` / `layout.gutter` / `space.7`; gap 18 → `space.5`. Tablet: text capped at `layout.readingMaxWidth`.
1. Top bar: Back; centred caption "Learn".
2. Title "About tarot & Taro" serif 28 `type.headline`.
3. Sections (gap `space.3` inside), each an h2 `type.titleSmall` + paragraph serif 17 `type.bodyReading`: "Where tarot comes from", "How Taro reads", "The deck" (a panel with a `TaroCardBack` thumb 34 × 58 + `type.caption`/14 text; the artist credit is a placeholder until D15), "What Taro isn't".
4. Link row "Support and crisis lines" (`color.bg.surface`, `radius.md`, min 52, heart icon + chevron).
5. Footer caption: `disclaimerShort` "For entertainment and self-reflection. Not professional advice." (**resolved**: `AboutTaro.dc.html` now uses it instead of the placeholder "Taro is for reflection and entertainment.").

The text comes from the authored article `packages/taro_content/source/{locale}/articles/*.md` (01 §11). The canvas copy is sample text of the right length.

## Components
`ReadingTextView` (article mode), `TaroCardBack`, `SettingsTile`, `DisclaimerFooter`.

## States (01 §8.3)
| State | ★ | Source |
|---|---|---|
| `content` | | **Designed**: `AboutTaro.dc.html` |

## Motion
Push only (`motion.duration.base`; reduced: fade).

## Semantics / reading order
Back → "Learn" → title (header) → each section heading (header) + paragraph → support lines link → disclaimer.

## RTL
Mirrored; the card thumb sits at the start.

## Banner
None.

---

**Conventions (same in every S-spec).** Canvas px = dp/sp. Spacing 2/4/8/12/16/20/24/32/40/48/56/64 = `space.1`…`space.12`; odd canvas values (6, 10, 14, 18, 28) snap to the nearest token. Radius: 4 `radius.xs`, 8 `radius.sm`, 10 `radius.card`, 12 `radius.md`, 16 `radius.lg`, 24 `radius.xl`, 28 `radius.sheet`, 999 `radius.full`. Type: serif 40 `type.display`; serif 28 `type.headline`; serif 20–24 `type.cardName`; serif 16–18 paragraphs `type.bodyReading`; sans 20/600 `type.title`; sans 17–18/600 `type.titleSmall`; sans 16 `type.body`; sans 14–15/500 `type.label`; sans 12–13 `type.caption`; numerals `type.numeral`. Nothing renders below 12 sp (canvas 9–11 px badges become `type.caption`). Side gutter `layout.gutter` (16; onboarding pages use `space.7` = 24). Tablet: the content column is `layout.maxContentWidth` (600) centred, long text is capped at `layout.readingMaxWidth`. Controls drawn at 40–44 px keep their look but get a ≥ `size.touchTarget.min` (48) hit area. Colours are tokens only (`color.*`, names in 01 §14.1). Every ★ state is a golden in light + dark at phone and tablet width (01 §8.3, RC24). *Derived* means that no artboard exists: Phase 16/17 builds the state from the designed states, the tokens and the shared state widgets (01 §8.2), and REVIEW.md checks it.
