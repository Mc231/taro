# S17 · Learn: card detail

| | |
|---|---|
| Route | `/learn/card/:cardId` (deep link `taro://learn/card/{cardId}`) |
| Banner | none |
| Artboards | [`../CardDetail.dc.html`](../CardDetail.dc.html) (Three of Cups) |
| Frames | [`CardDetail.png`](../frames/CardDetail.png) (PNG @2x, from the artboards above) |
| Next | "In your journal: drawn N times" → S14 filtered by card · prev/next card · art tap → `zoomed` |
| Sample content | [`../../samples/cards_en.md`](../../samples/cards_en.md) (5 cards at authored length) |

## Layout (top → bottom)
Padding `space.10` / `layout.gutter` / `space.7`; gap `space.5`.
1. Top bar: Back at the start; centred the position caption `type.caption` "Cups · 3 of 14". Previous/next card navigation: prev/next `TaroIconButton`s at the end ("Previous card: Two of Cups" / "Next card: Four of Cups"; a horizontal swipe as well, with the buttons as the accessible alternative). **Resolved**: drawn on `CardDetail.dc.html`.
2. Hero row, gap `space.5`: `TaroCardFace` 112 × 192 (`radius.md`, tap → `zoomed`); the column (gap `space.3`): the name serif 28 `type.headline`; facts `type.caption`/14 `color.text.secondary`: "Minor Arcana · Cups" (with the suit glyph, never colour alone), "Element: Water", "Number: Three" (majors add the astrology correspondence); keyword chips 28 visual, `color.accent.subtle`, `type.caption`.
3. **Upright / Reversed toggle** (01 §7.9): a `SegmentedChoice` "Upright | Reversed" (group "Card orientation", 42 visual / 48 hit, selected `color.accent.subtle`) above the meaning. In code, the toggle switches the keywords, the meaning and the aspects. **Resolved**: `CardDetail.dc.html` shows the toggle with Upright selected and only the upright meaning (the stacked "Reversed meaning" section was removed).
4. The meaning: heading `type.titleSmall` + the paragraph serif 17 `type.bodyReading` (`meaningUpright` 120–220 words / `meaningReversed` 100–200; see the samples, which are much longer than the canvas placeholder).
5. Aspects panel: `color.bg.surface`, `radius.md`, padding `space.4` / 14; three rows (label `type.caption` `color.text.tertiary` + text `type.caption`/14). The labels are **"Relationships", "Work & purpose", "Personal growth"** (01 §7.9). **Resolved**: the canvas had "Love / Work" in a 44 px column; it now uses the 01 labels, stacked above the text (`type.caption`/600 `color.text.tertiary`), which also fits de and +40%.
6. Reflection questions (3, ≤ 120 chars each): heading "Questions to reflect on" `type.titleSmall` + a list (serif 16 `type.bodyReading`, `color.text.secondary`, a 2 px `color.accent.subtle` start rule). **Resolved**: drawn on `CardDetail.dc.html` with the three authored Three of Cups questions from `samples/cards_en.md`.
7. Journal link row: "In your journal: drawn 4 times" (01 copy; **resolved**, the canvas said "Your history"), icon + chevron, min 52. With N = 0: "Not in your journal yet", not tappable.

## Components
`TaroCardFace`, `SegmentedChoice`, keyword chip, `SettingsTile`, `TaroIconButton`, full-screen image viewer (zoom).

## States (01 §8.3)
| State | ★ | Source |
|---|---|---|
| `upright` | ★ | **Designed**: `CardDetail.dc.html` (toggle, aspect labels, reflection questions and prev/next all drawn) |
| `reversed` | | Derived: the toggle is on Reversed; the reversed keywords, meaning and aspects; the hero art is rotated 180° with a "Reversed" label |
| `zoomed` | | Derived: full-screen art on `color.bg.scrim` (opaque), pinch-zoom, Close X; the art is never mirrored |

## Motion
Toggle: cross-fade the text `motion.duration.base`; the hero rotates 180° over `motion.duration.slow` (reduced: cross-fade). Zoom: a shared-element transition `motion.duration.slow` (reduced: fade).

## Semantics / reading order
Back → "Cups, card 3 of 14" → prev/next → card image ("Three of Cups card art") → name (header) → facts → keywords → toggle ("Upright, selected") → meaning heading + text → aspects (each "Relationships: …") → reflection questions → journal link.

## RTL
Mirrored; the card art and Roman numerals are not mirrored; prev/next chevrons mirror (next points left).

## Banner
None (04 §8 excludes card detail).

---

**Conventions (same in every S-spec).** Canvas px = dp/sp. Spacing 2/4/8/12/16/20/24/32/40/48/56/64 = `space.1`…`space.12`; odd canvas values (6, 10, 14, 18, 28) snap to the nearest token. Radius: 4 `radius.xs`, 8 `radius.sm`, 10 `radius.card`, 12 `radius.md`, 16 `radius.lg`, 24 `radius.xl`, 28 `radius.sheet`, 999 `radius.full`. Type: serif 40 `type.display`; serif 28 `type.headline`; serif 20–24 `type.cardName`; serif 16–18 paragraphs `type.bodyReading`; sans 20/600 `type.title`; sans 17–18/600 `type.titleSmall`; sans 16 `type.body`; sans 14–15/500 `type.label`; sans 12–13 `type.caption`; numerals `type.numeral`. Nothing renders below 12 sp (canvas 9–11 px badges become `type.caption`). Side gutter `layout.gutter` (16; onboarding pages use `space.7` = 24). Tablet: the content column is `layout.maxContentWidth` (600) centred, long text is capped at `layout.readingMaxWidth`. Controls drawn at 40–44 px keep their look but get a ≥ `size.touchTarget.min` (48) hit area. Colours are tokens only (`color.*`, names in 01 §14.1). Every ★ state is a golden in light + dark at phone and tablet width (01 §8.3, RC24). *Derived* means that no artboard exists: Phase 16/17 builds the state from the designed states, the tokens and the shared state widgets (01 §8.2), and REVIEW.md checks it.
