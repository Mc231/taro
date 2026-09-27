# S18 · Learn: spreads guide + spread detail

| | |
|---|---|
| Route | `/learn/spreads` (index) and `/learn/spreads/:spreadId` (detail) |
| Banner | none |
| Artboards | [`../SpreadsGuide.dc.html`](../SpreadsGuide.dc.html) (detail: Celtic Cross, "6 of 6"); diagrams from [`../SpreadDiagrams.dc.html`](../SpreadDiagrams.dc.html) (all 6 spreads; shared with S06) |
| Frames | [`SpreadsGuide.png`](../frames/SpreadsGuide.png) · [`SpreadDiagrams.png`](../frames/SpreadDiagrams.png) (PNG @2x, from the artboards above) |
| Next | "Start this spread" → S07 `?spread=<id>` (through the normal reading flow and gate) |

## Layout (top → bottom), detail
Padding `space.10` / `layout.gutter` / `space.7`; gap `space.5`.
1. Top bar: Back; centred caption "Spreads guide · 6 of 6" (paging between the 6 spreads by swipe, plus prev/next buttons as the accessible alternative).
2. Name serif 28 `type.headline`; meta `type.caption` "10 cards · a full picture · uses one reading".
3. Layout diagram (SpreadDiagrams asset), full content width (358 × 272 on the canvas): numbered slots 34 × 58 (`radius.xs`, `color.bg.surfaceRaised`, `color.card.frame` border, the number in `type.caption`); Celtic Cross slot 2 lies sideways across slot 1 (`color.card.back`); group captions "The cross" / "The staff" `type.caption`.
4. Positions `ol` in `color.bg.surface`, `radius.md`, padding `space.2` / 14. Rows min 38 visual (these are not tap targets), a number bubble 24 (`radius.full`, outline), the name `type.caption`/14 600 + " · " + the description (`spread_{id}_pos_{pos}_desc`). Outcome/future wording: "where things may be heading if nothing changes" (01 §10.3).
5. "When to use it" `type.titleSmall` + `type.label` paragraph.
6. Flexible spacer.
7. `TaroButton.primary` full width: "Start this spread" (01 §7.9 copy; **resolved**: `SpreadsGuide.dc.html` now says "Start this spread").

**Index** (`/learn/spreads`): not drawn. Derive it from S06's `SpreadRow` list (mini diagram + name + meta), with rows opening the detail. There is no "uses one reading" pressure copy beyond the meta line.

## Components
`TaroAppBar`, spread diagram (asset / `SpreadCanvas` in outline mode), numbered list row, `SpreadRow`, `TaroButton`.

## States (01 §8.3)
| State | ★ | Source |
|---|---|---|
| `content`: detail | | **Designed**: `SpreadsGuide.dc.html` |
| `content`: index | | Derived from S06 rows |
| spread disabled by remote config | | Derived: the detail stays readable (Learn is ungated); the "Start this spread" button is hidden |

## Motion
Page swipe between spreads `motion.duration.base`; reduced: fade.

## Semantics / reading order
Back → "Spreads guide, 6 of 6" → name (header) → meta → the diagram as one image with a long description (canvas: "Celtic Cross layout: cards 1 to 6 form a cross, with card 2 laid sideways across card 1; cards 7 to 10 stand in a column to the right, from bottom to top.") → positions list ("1, Present, where you stand right now") → When to use it (header) + text → Start this spread.

## RTL
The diagram mirrors its x coordinates (the staff moves to the left; slot 2 keeps its 90° rotation); numbers are not mirrored; the list aligns right.

## Banner
None.

---

**Conventions (same in every S-spec).** Canvas px = dp/sp. Spacing 2/4/8/12/16/20/24/32/40/48/56/64 = `space.1`…`space.12`; odd canvas values (6, 10, 14, 18, 28) snap to the nearest token. Radius: 4 `radius.xs`, 8 `radius.sm`, 10 `radius.card`, 12 `radius.md`, 16 `radius.lg`, 24 `radius.xl`, 28 `radius.sheet`, 999 `radius.full`. Type: serif 40 `type.display`; serif 28 `type.headline`; serif 20–24 `type.cardName`; serif 16–18 paragraphs `type.bodyReading`; sans 20/600 `type.title`; sans 17–18/600 `type.titleSmall`; sans 16 `type.body`; sans 14–15/500 `type.label`; sans 12–13 `type.caption`; numerals `type.numeral`. Nothing renders below 12 sp (canvas 9–11 px badges become `type.caption`). Side gutter `layout.gutter` (16; onboarding pages use `space.7` = 24). Tablet: the content column is `layout.maxContentWidth` (600) centred, long text is capped at `layout.readingMaxWidth`. Controls drawn at 40–44 px keep their look but get a ≥ `size.touchTarget.min` (48) hit area. Colours are tokens only (`color.*`, names in 01 §14.1). Every ★ state is a golden in light + dark at phone and tablet width (01 §8.3, RC24). *Derived* means that no artboard exists: Phase 16/17 builds the state from the designed states, the tokens and the shared state widgets (01 §8.2), and REVIEW.md checks it.
