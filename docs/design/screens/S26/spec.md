# S26 · Delete all data

| | |
|---|---|
| Route | `/settings/delete` |
| Banner | none |
| Artboards | [`../DeleteData.dc.html`](../DeleteData.dc.html) |
| Frames | [`DeleteData.png`](../frames/DeleteData.png) (PNG @2x, from the artboards above) |

## Layout (top → bottom)
Padding `space.10` / `layout.gutter` / 28; gap `space.5`.
1. Back; title "Delete all data" serif 28; body `type.label`: "This can't be undone. If you might want your journal later, export a backup first." (an inline link → S24).
2. "What's erased" panel (`color.bg.surface`, `radius.lg`, padding `space.5`; minus icons): "Your journal: 128 readings and daily cards", "Your notes and favourites", "Settings and reminders on this phone", "Readings waiting on our server to be delivered".
3. "What's kept" panel (`color.accent.subtle`; check icons): "Your readings balance: 3 readings", "Your Remove Banner Ads purchase", caption "So you don't lose what you paid for." (RC37: "Your remaining readings and Remove Banner Ads are kept.").
4. Typed confirmation: label `type.caption` "Type DELETE to confirm" + `TaroTextField` (min 52, `color.bg.sunken`, `type.body`/17, no autocorrect). The word is localized (ARB) and compared case-insensitively.
5. Flexible spacer.
6. `TaroButton.destructive` "Delete all data" (`color.status.error`, `color.status.onError` text), enabled only when the word matches; `TaroButton.secondary` "Cancel".

**Two steps (RC37):** `confirm1` = the page as drawn with an empty field (the destructive button disabled); `confirm2` = the typed word matches and the button is enabled. The canvas shows the confirm2 frame. There is no extra dialog.

## Components
`ChecklistPanel` (shared with S24), `TaroTextField`, `TaroButton.destructive`, `TaroInlineNotice`.

## States (01 §8.3)
| State | ★ | Source |
|---|---|---|
| `confirm1` | | Derived from the artboard (empty field, the button disabled) |
| `confirm2` | | **Designed**: `DeleteData.dc.html` |
| `deleting` | | Derived: the destructive button loading, back disabled |
| `done` | | Derived: `TaroEmptyView`-style "Your data is deleted" + "Your remaining readings and Remove Banner Ads are kept." + "Done" → S05 |
| `partial` | | Derived: `done` + `TaroInlineNotice(warning)` "Deleted on this phone. We'll finish removing server data when you're back online." |

## Motion
None beyond the push; reduced: n/a.

## Semantics / reading order
Back → title → body (+ export link) → "What's erased" (header) + list → "What's kept" (header) + list + caption → the confirmation field (label "Type DELETE to confirm") → Delete all data (announces disabled until confirmed) → Cancel.

## RTL
Mirrored; the typed word follows the locale's ARB value.

## Banner
None.

---

**Conventions (same in every S-spec).** Canvas px = dp/sp. Spacing 2/4/8/12/16/20/24/32/40/48/56/64 = `space.1`…`space.12`; odd canvas values (6, 10, 14, 18, 28) snap to the nearest token. Radius: 4 `radius.xs`, 8 `radius.sm`, 10 `radius.card`, 12 `radius.md`, 16 `radius.lg`, 24 `radius.xl`, 28 `radius.sheet`, 999 `radius.full`. Type: serif 40 `type.display`; serif 28 `type.headline`; serif 20–24 `type.cardName`; serif 16–18 paragraphs `type.bodyReading`; sans 20/600 `type.title`; sans 17–18/600 `type.titleSmall`; sans 16 `type.body`; sans 14–15/500 `type.label`; sans 12–13 `type.caption`; numerals `type.numeral`. Nothing renders below 12 sp (canvas 9–11 px badges become `type.caption`). Side gutter `layout.gutter` (16; onboarding pages use `space.7` = 24). Tablet: the content column is `layout.maxContentWidth` (600) centred, long text is capped at `layout.readingMaxWidth`. Controls drawn at 40–44 px keep their look but get a ≥ `size.touchTarget.min` (48) hit area. Colours are tokens only (`color.*`, names in 01 §14.1). Every ★ state is a golden in light + dark at phone and tablet width (01 §8.3, RC24). *Derived* means that no artboard exists: Phase 16/17 builds the state from the designed states, the tokens and the shared state widgets (01 §8.2), and REVIEW.md checks it.
