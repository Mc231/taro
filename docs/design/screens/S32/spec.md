# S32 · Classic reading result

| | |
|---|---|
| Route | `/reading/:id?mode=classic` |
| Banner | none |
| Artboards | [`../ClassicReading.dc.html`](../ClassicReading.dc.html) (dark, LTR). Light and RTL follow the S09 variants [`../ReadingLight.dc.html`](../ReadingLight.dc.html) / [`../ReadingAr.dc.html`](../ReadingAr.dc.html); [`../ReadingLargeText.dc.html`](../ReadingLargeText.dc.html) (200% text) also covers this renderer |
| Frames | [`ClassicReading.png`](../frames/ClassicReading.png) · [`ReadingLight.png`](../frames/ReadingLight.png) · [`ReadingAr.png`](../frames/ReadingAr.png) · [`ReadingLargeText.png`](../frames/ReadingLargeText.png) (PNG @2x, from the artboards above) |
| Entry | F8: S04 "Not now", `aiUnavailableRegion`, `readingsPaused` (S31) → S08 Classic ritual → here. Free, offline, no Worker call, saved as `status: classic` |

## Layout (top → bottom)
Padding `space.10` / `layout.gutter` / `space.7`; gap `space.5`.
1. Top bar: Back to Today (X) at the start; "Add note" at the end. **No More/Report menu**: Classic readings cannot be reported (no AI text).
2. Mini spread: `TaroCardFace` 76 × 130 (`size.card.sm`), labels `type.caption`; a reversed card is rotated 180° + the `color.card.reversedBadge` "Reversed" label.
3. Label block: the "Classic reading" `Badge` pill (`color.accent.subtle`, `radius.full`, 28, book icon), used **instead of** the AI label, as the page heading; caption "Built from the meaning of each card in its position. No AI, free and works offline."
4. Per position (gap 14): a heading `type.titleSmall`/18 with a suit dot "Present · Two of Swords, reversed"; the position description + keywords `type.caption` `color.text.tertiary` ("Where you are now · a stalemate easing", from `spread_{id}_pos_{pos}_desc`); the authored text serif 17 `type.bodyReading` (`shortUpright`/`shortReversed` + `meaningUpright`/`meaningReversed`, 01 §9.9). No summary, no synthesis, no AI reflection prompts.
5. "Try an AI reading" `TaroButton.secondary`, **only when the gate would allow one** (derived).
6. `DisclaimerFooter` with `disclaimerShort` ("For entertainment and self-reflection. Not professional advice."); the "Classic reading" label sits in the header instead of the AI badge. **Resolved**: `ClassicReading.dc.html` now uses the ARB string.

## Components
`ReadingTextView`, `TaroCardFace`, `SpreadCanvas` (mini), `Badge`, `DisclaimerFooter`, `TaroButton`.

## States (01 §8.3)
| State | ★ | Source |
|---|---|---|
| `content` LTR dark | ★ | **Designed**: `ClassicReading.dc.html` |
| `content` LTR light | ★ | Derived: light tokens (as `ReadingLight`) |
| `content` RTL dark/light | ★ | Derived: mirrored as `ReadingAr` (the card faces stay LTR inside) |
| `loadingFromStorage` | | Derived: `SkeletonBlock`s; the disclaimer is visible |
| with "Try an AI reading" | | Derived: the button appears after the last position |

## Motion
From S08: sections stagger `motion.ritual.readingReveal`; `haptic.ready` is not used (nothing is awaited). Reduced: all at once.

## Semantics / reading order
Back → Add note → cards ("Ace of Wands, position: Past"; "Two of Swords, reversed, position: Present") → "Classic reading" (header) → caption → each position heading (header) + description + text → Try an AI reading → disclaimer.

## RTL
As S09: the card row mirrors, the card art is not mirrored, the headings and the suit dot sit at the start.

## Banner
None (04 §8 lists Classic reading S32 as ❌).

---

**Conventions (same in every S-spec).** Canvas px = dp/sp. Spacing 2/4/8/12/16/20/24/32/40/48/56/64 = `space.1`…`space.12`; odd canvas values (6, 10, 14, 18, 28) snap to the nearest token. Radius: 4 `radius.xs`, 8 `radius.sm`, 10 `radius.card`, 12 `radius.md`, 16 `radius.lg`, 24 `radius.xl`, 28 `radius.sheet`, 999 `radius.full`. Type: serif 40 `type.display`; serif 28 `type.headline`; serif 20–24 `type.cardName`; serif 16–18 paragraphs `type.bodyReading`; sans 20/600 `type.title`; sans 17–18/600 `type.titleSmall`; sans 16 `type.body`; sans 14–15/500 `type.label`; sans 12–13 `type.caption`; numerals `type.numeral`. Nothing renders below 12 sp (canvas 9–11 px badges become `type.caption`). Side gutter `layout.gutter` (16; onboarding pages use `space.7` = 24). Tablet: the content column is `layout.maxContentWidth` (600) centred, long text is capped at `layout.readingMaxWidth`. Controls drawn at 40–44 px keep their look but get a ≥ `size.touchTarget.min` (48) hit area. Colours are tokens only (`color.*`, names in 01 §14.1). Every ★ state is a golden in light + dark at phone and tablet width (01 §8.3, RC24). *Derived* means that no artboard exists: Phase 16/17 builds the state from the designed states, the tokens and the shared state widgets (01 §8.2), and REVIEW.md checks it.
