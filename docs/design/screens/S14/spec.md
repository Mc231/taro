# S14 · Journal list ("Journal" tab)

| | |
|---|---|
| Route | `/journal` (tab 2 of 4) |
| Banner | ✅ `journal_list` (allowed) |
| Artboards | [`../Journal.dc.html`](../Journal.dc.html) (`content`, dark, en) · [`../JournalEmpty.dc.html`](../JournalEmpty.dc.html) (`empty`) · [`../JournalAr.dc.html`](../JournalAr.dc.html) (ar RTL; the S14 ar golden, 01 §14.5) |
| Frames | [`Journal.png`](../frames/Journal.png) · [`JournalEmpty.png`](../frames/JournalEmpty.png) · [`JournalAr.png`](../frames/JournalAr.png) (PNG @2x, from the artboards above) |
| Next | Row → S15 · "Finish reading" → S08 `awaitingReading` · Patterns item → S17 · empty "Start a reading" → S06 |

## Layout (top → bottom)
Scroll area padding 52 / `layout.gutter` / 0; gap `space.4`.
1. Title "Journal" serif 28 `type.headline`.
2. Search: `TaroTextField` (search), 48, `color.bg.sunken`, `radius.md`, leading icon, placeholder "Search questions and notes" (visually hidden label).
3. Filter chips (horizontal scroll, gap `space.3`): All / Readings / Daily cards / Favourites (toggle buttons, 40 visual / 48 hit, `radius.full`; the selected one has `color.accent.subtle` + a `color.accent.primary` border). The spread-type and "contains card X" filters (01 §7.8) are not drawn (**still open**, not part of this fix pass). Derive a trailing "Filter" chip that opens a `TaroSheet`.
4. **Patterns card** (only with ≥ 5 entries): `color.bg.surface`, `radius.lg`, padding `space.4` / 14. "Patterns · last 30 days" `type.label`/600 + count caption; "Most drawn: *The Star*, 5 times" (link → S17); a suit-balance stacked bar 8 high (`color.chart.suit.*`, 2 px gaps); a legend (swatch + "Major 9"…, `type.caption` 12) so colour is not the only signal; the footnote "Patterns in your draws, not predictions." A 30/90-day `SegmentedChoice`, the major/minor and reversed ratios are not drawn (**still open**, derived in code); derive them in the same card.
5. Grouped list: section headers `type.caption` `color.text.tertiary`. **01 §7.8 groups by month.** **Resolved**: `Journal` and `JournalAr` now use month headers ("September 2026", "August 2026"; the two older sample rows moved to August). Rows (gap `space.2`): `color.bg.surface`, `radius.md`, padding `space.3` / `space.4`, min 52: a thumbs box 66 wide (1–3 thumbs 20 × 34, `radius.xs`); the title `type.label`/600 (question, else card or spread name); meta `type.caption` ("Past · Present · Future · Fri 26 Sep"); trailing favourite/note glyphs. Pending row: face-down thumbs (`color.card.back`), meta "Pending · …", trailing `TaroButton` chip "Finish reading" (`color.accent.subtle`, 44 → 48 hit). Classic row: a "Classic" `Badge`.
6. `space.adGap` → `BannerSlot` 56 → `space.adGap` → tab bar (Journal active).

## Components
`TaroScaffold` (tabs), `TaroTextField`, filter chips (`SegmentedChoice` / chip), Patterns card (**new**: `PatternsCard` + suit bar; add to `components.md`), `JournalRow` (shared with S05), `Badge`, `BannerSlot`, `TaroEmptyView`, `TaroErrorView`, `SkeletonBlock`, snackbar (Undo).

## States (01 §8.3)
| State | ★ | Source |
|---|---|---|
| `loading` | | Derived: title + search + 5 row `SkeletonBlock`s |
| `empty` | ★ | **Designed**: `JournalEmpty.dc.html`: `TaroEmptyView` with the Journal illustration asset, "Your readings will live here" + "Start a reading". Patterns and filters are hidden |
| `content` | ★ | **Designed**: `Journal.dc.html`; ar: `JournalAr.dc.html` |
| `filteredEmpty` | | Derived: `TaroEmptyView` (no illustration) "Nothing matches this filter" + "Clear filter" |
| `searchEmpty` | | Derived: `TaroEmptyView` with the search illustration asset, "No entries match “…”" |
| `storageError` | | Derived: `TaroErrorView(storage)` |
| delete via swipe/menu | | Derived: confirm `TaroDialog` → the row is removed + an Undo snackbar for 5 s (placed above the banner, keeping `space.adGap`) |

## Motion
Row press overlay; filter change cross-fades the list (`motion.duration.fast`); the swipe-to-delete reveal follows the finger; the Undo snackbar in/out `motion.duration.base`. Reduced: fades only.

## Semantics / reading order
Title (header) → search → filter toggles (with their pressed state) → Patterns card as one summary node, with the bar label "Suit balance: Major Arcana 9, Wands 4, Cups 7, Swords 3, Pentacles 5" (the legend is excluded) → section headers (header) → rows ("A season of rebuilding, Past, Present, Future, Friday 26 September, favourite, has note"; "Finish reading" is a separate focus stop) → banner → tabs.

## RTL (`JournalAr`)
The search icon moves to the right; thumbs run right to left; the suit bar fills from the right; row chevrons mirror; dates use `intl` ar.

## Banner
Allowed: bottom slot only, own `color.ad.container`, ≥ `space.adGap` from rows, chips and snackbar. It collapses with its gaps on failure or `adsRemoved`, and is hidden until `ads.bannerMinCompletedReadings` AI readings are completed.

---

**Conventions (same in every S-spec).** Canvas px = dp/sp. Spacing 2/4/8/12/16/20/24/32/40/48/56/64 = `space.1`…`space.12`; odd canvas values (6, 10, 14, 18, 28) snap to the nearest token. Radius: 4 `radius.xs`, 8 `radius.sm`, 10 `radius.card`, 12 `radius.md`, 16 `radius.lg`, 24 `radius.xl`, 28 `radius.sheet`, 999 `radius.full`. Type: serif 40 `type.display`; serif 28 `type.headline`; serif 20–24 `type.cardName`; serif 16–18 paragraphs `type.bodyReading`; sans 20/600 `type.title`; sans 17–18/600 `type.titleSmall`; sans 16 `type.body`; sans 14–15/500 `type.label`; sans 12–13 `type.caption`; numerals `type.numeral`. Nothing renders below 12 sp (canvas 9–11 px badges become `type.caption`). Side gutter `layout.gutter` (16; onboarding pages use `space.7` = 24). Tablet: the content column is `layout.maxContentWidth` (600) centred, long text is capped at `layout.readingMaxWidth`. Controls drawn at 40–44 px keep their look but get a ≥ `size.touchTarget.min` (48) hit area. Colours are tokens only (`color.*`, names in 01 §14.1). Every ★ state is a golden in light + dark at phone and tablet width (01 §8.3, RC24). *Derived* means that no artboard exists: Phase 16/17 builds the state from the designed states, the tokens and the shared state widgets (01 §8.2), and REVIEW.md checks it.
