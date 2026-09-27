# S16 · Learn: deck browser ("Learn" tab)

| | |
|---|---|
| Route | `/learn` (tab 3 of 4) |
| Banner | ✅ `learn_library` (allowed) |
| Artboards | [`../Learn.dc.html`](../Learn.dc.html) |
| Frames | [`Learn.png`](../frames/Learn.png) (PNG @2x, from the artboards above) |
| Next | Card → S17 · "Spreads guide" → S18 · "About tarot & Taro" → S19 |

## Layout (top → bottom)
Scroll area padding 52 / `layout.gutter` / 0; gap `space.4`.
1. Title "Learn" serif 28 `type.headline`.
2. **Search** (01 §7.9: matches the localized name and keywords; the `searchEmpty` state exists): `TaroTextField` search like S14 (48, `color.bg.sunken`, `radius.md`, leading icon, visually hidden label), placeholder "Search cards". **Resolved**: drawn on `Learn.dc.html` under the title. The grid now continues below the fold, so the link rows scroll under the banner slot on the 844 frame.
3. Section `SegmentedChoice` (group "Deck section"): Major Arcana / Wands / Cups / Swords / Pentacles. Container `color.bg.surface`, `radius.md`, padding 3; segments 42 visual / 48 hit, `type.caption`/13, selected `color.accent.subtle`. At +40% (de) the labels do not fit five across: the segment row scrolls horizontally. 01 §7.9 describes one grid grouped by section; the segments act as jump anchors into that grouped grid.
4. Grid: 3 columns, gap `space.3` (canvas 10); tiles 120 high, `color.bg.surfaceRaised`, `radius.card`, `color.card.frame` outline. Each tile (`TaroCardFace` thumb) shows the numeral (`type.numeral`), the art and the name (serif 12 → `type.caption`). Tablet: the column count grows to fit `layout.maxContentWidth` (5).
5. Link rows (gap `space.3`): "Spreads guide", "About tarot & Taro". Each is `color.bg.surface`, `radius.md`, min 52, icon + `type.label` + chevron.
6. `space.adGap` → `BannerSlot` 56 → `space.adGap` → tab bar (Learn active).

## Components
`TaroScaffold`, `TaroTextField`, `SegmentedChoice`, `TaroCardFace` (thumb), `SettingsTile` (link rows), `BannerSlot`, `TaroEmptyView`.

## States (01 §8.3)
| State | ★ | Source |
|---|---|---|
| `content` | ★ | **Designed**: `Learn.dc.html` (with the search field) |
| `searchEmpty` | | Derived: `TaroEmptyView` with the search illustration asset, "No cards match “…”" |

Learn is fully offline and has no gating (no loading or error state for content).

## Motion
Segment change: scroll to the section `motion.duration.slow`, `motion.easing.standard`; tile press overlay. Reduced: jump without animation.

## Semantics / reading order
Title (header) → search → segment group (selected state) → grid in reading order (each tile "The Fool, Major Arcana, 0, button"; section headings for each suit group) → Spreads guide → About → banner → tabs.

## RTL
The grid flows right to left; the segment order mirrors; the card art is never mirrored; Roman numerals stay LTR; chevrons mirror.

## Banner
Allowed: bottom slot only, with `space.adGap` from the link rows and tabs. It collapses on failure or `adsRemoved`.

---

**Conventions (same in every S-spec).** Canvas px = dp/sp. Spacing 2/4/8/12/16/20/24/32/40/48/56/64 = `space.1`…`space.12`; odd canvas values (6, 10, 14, 18, 28) snap to the nearest token. Radius: 4 `radius.xs`, 8 `radius.sm`, 10 `radius.card`, 12 `radius.md`, 16 `radius.lg`, 24 `radius.xl`, 28 `radius.sheet`, 999 `radius.full`. Type: serif 40 `type.display`; serif 28 `type.headline`; serif 20–24 `type.cardName`; serif 16–18 paragraphs `type.bodyReading`; sans 20/600 `type.title`; sans 17–18/600 `type.titleSmall`; sans 16 `type.body`; sans 14–15/500 `type.label`; sans 12–13 `type.caption`; numerals `type.numeral`. Nothing renders below 12 sp (canvas 9–11 px badges become `type.caption`). Side gutter `layout.gutter` (16; onboarding pages use `space.7` = 24). Tablet: the content column is `layout.maxContentWidth` (600) centred, long text is capped at `layout.readingMaxWidth`. Controls drawn at 40–44 px keep their look but get a ≥ `size.touchTarget.min` (48) hit area. Colours are tokens only (`color.*`, names in 01 §14.1). Every ★ state is a golden in light + dark at phone and tablet width (01 §8.3, RC24). *Derived* means that no artboard exists: Phase 16/17 builds the state from the designed states, the tokens and the shared state widgets (01 §8.2), and REVIEW.md checks it.
