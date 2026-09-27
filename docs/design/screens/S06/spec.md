# S06 · Spread picker

| | |
|---|---|
| Route | `/reading/spreads` |
| Banner | none |
| Artboards | [`../Spreads.dc.html`](../Spreads.dc.html); mini layout diagrams from [`../SpreadDiagrams.dc.html`](../SpreadDiagrams.dc.html) (6 diagrams, shared with S18) |
| Frames | [`Spreads.png`](../frames/Spreads.png) · [`SpreadDiagrams.png`](../frames/SpreadDiagrams.png) (PNG @2x, from the artboards above) |
| Next | Row → S07 `?spread=<spreadId>`; "How spreads work" → S18 |

## Layout (top → bottom)
Padding `space.10` / `layout.gutter` / `space.7`; gap `space.6`.
1. Top bar: Back `TaroIconButton` 48.
2. Title "Choose a spread" serif 28 `type.headline`; subtitle `type.label` in `color.text.secondary`: "Every spread uses one reading, whatever its size." (PR3, RC62: 1 credit per spread).
3. List, gap `space.4` (canvas 10): 6 rows in `spreads.json` order (`single`, `three_ppf`, `three_sao`, `relationship`, `two_paths`, `celtic_cross`). Each row: `color.bg.surface`, `radius.lg`, padding `space.4`/`space.5`; a mini diagram 64 × 44 (SpreadDiagrams asset, card outlines in `color.card.frame`); the name `type.titleSmall`; meta `type.caption` "3 cards · how a situation is moving".
4. Text link "How spreads work" (48 hit).

The canvas fills the `three_ppf` row with `color.accent.subtle`. Treat this as the **pressed** state, not a preselection: no row is highlighted by default.

## Components
`TaroAppBar`, spread row (**new**: `SpreadRow`, shared with S18's index), spread mini diagram (asset), `TaroButton.tertiary` (link).

## States (01 §8.3)
| State | ★ | Source |
|---|---|---|
| `content` | ★ | **Designed**: `Spreads.dc.html` |
| Spreads disabled by remote config | | Derived: the rows are simply omitted (no gaps, no "disabled" rows) |

## Motion
Push `motion.duration.base`; row press overlay `opacity.pressed`; reduced: fade.

## Semantics / reading order
Back → title (header) → subtitle → each row as one button ("Past, Present, Future. 3 cards. How a situation is moving"); the diagram is excluded → "How spreads work".

## RTL
Rows mirror. The diagrams mirror their x coordinates (01 §10.2, 01 §13), so `past` sits on the right; card outlines are not flipped.

## Banner
None (04 §8 explicitly excludes the spread picker).

---

**Conventions (same in every S-spec).** Canvas px = dp/sp. Spacing 2/4/8/12/16/20/24/32/40/48/56/64 = `space.1`…`space.12`; odd canvas values (6, 10, 14, 18, 28) snap to the nearest token. Radius: 4 `radius.xs`, 8 `radius.sm`, 10 `radius.card`, 12 `radius.md`, 16 `radius.lg`, 24 `radius.xl`, 28 `radius.sheet`, 999 `radius.full`. Type: serif 40 `type.display`; serif 28 `type.headline`; serif 20–24 `type.cardName`; serif 16–18 paragraphs `type.bodyReading`; sans 20/600 `type.title`; sans 17–18/600 `type.titleSmall`; sans 16 `type.body`; sans 14–15/500 `type.label`; sans 12–13 `type.caption`; numerals `type.numeral`. Nothing renders below 12 sp (canvas 9–11 px badges become `type.caption`). Side gutter `layout.gutter` (16; onboarding pages use `space.7` = 24). Tablet: the content column is `layout.maxContentWidth` (600) centred, long text is capped at `layout.readingMaxWidth`. Controls drawn at 40–44 px keep their look but get a ≥ `size.touchTarget.min` (48) hit area. Colours are tokens only (`color.*`, names in 01 §14.1). Every ★ state is a golden in light + dark at phone and tablet width (01 §8.3, RC24). *Derived* means that no artboard exists: Phase 16/17 builds the state from the designed states, the tokens and the shared state widgets (01 §8.2), and REVIEW.md checks it.
