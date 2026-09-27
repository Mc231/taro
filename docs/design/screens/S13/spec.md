# S13 · Daily card

| | |
|---|---|
| Route | `/daily` (deep link `taro://daily`) |
| Banner | none |
| Artboards | [`../DailyCard.dc.html`](../DailyCard.dc.html) (`drawn`, The Star upright) · [`../DailyCardNotDrawn.dc.html`](../DailyCardNotDrawn.dc.html) (`notDrawn`) |
| Frames | [`DailyCard.png`](../frames/DailyCard.png) · [`DailyCardNotDrawn.png`](../frames/DailyCardNotDrawn.png) (PNG @2x, from the artboards above) |
| Next | "Reflect deeper with AI" → S07 (`single`, card preset; the gate applies; 1 reading) · "Add a note" → inline editor |
| Sample content | [`../../samples/cards_en.md`](../../samples/cards_en.md) (The Star) |

## Layout (top → bottom)
Padding `space.10` / `layout.gutter` / `space.7`; gap `space.5`.
1. Top bar: Back at the start; centred the overline "YOUR DAILY CARD" (`type.caption`, `color.card.frame`) over the date (`type.caption`, `color.text.tertiary`); a 48 spacer at the end.
2. Card: `TaroCardFace` 132 × 226 (between `size.card.md` and `lg`), `radius.md`, `elevation.3`, centred. Reversed: art rotated 180° + `color.card.reversedBadge` label.
3. Meta `type.caption` `color.text.secondary` "Major Arcana · XVII · Upright" (orientation as text), then the name serif 28 `type.headline`.
4. Keyword chips (3), 32 visual, `radius.full`, `color.accent.subtle`, `type.label`/14.
5. Short meaning (`shortUpright` / `shortReversed`, ≤ 160 chars): serif 18 `type.bodyReading`.
6. Reflection question (authored, one of 3): serif 16 `type.bodyReading` in `color.text.secondary`.
7. Flexible spacer.
8. Actions, gap `space.4`: `TaroButton.primary` "Reflect deeper with AI" (52); `TaroButton.secondary` "Add a note" (48); caption "Your daily card is free, works offline and uses no AI. Reflecting deeper starts a single-card reading and uses one reading."

## Components
`TaroCardFace`, `TaroCardBack`, `TaroCardFlip`, keyword chip, `TaroButton`, `TaroTextField` (note), reminder offer card (`TaroInlineNotice` with two actions).

## States (01 §8.3)
| State | ★ | Source |
|---|---|---|
| `notDrawn` | ★ | **Designed**: `DailyCardNotDrawn.dc.html` (the same layout with `TaroCardBack` in the card slot; the name, keywords and texts hidden; the title "One card to sit with today"; `TaroButton.primary` "Reveal card"; the caption "Free, works offline, no AI.") |
| `revealing` | | Derived: `TaroCardFlip` in place, then the texts fade in |
| `drawn` | ★ | **Designed**: `DailyCard.dc.html` |
| `noteEditing` | | Derived: an inline note field like S15 (`color.bg.sunken`, serif 17, autosave caption "Saved on this device") replaces "Add a note" |
| `reminderOffer` (once, after the first reveal) | | Derived: a `color.bg.surface` `radius.lg` card under the actions: "Would you like a gentle daily reminder?" [Yes, remind me] [No thanks] (equal weight); the OS permission prompt only after Yes |
| 200% text | | Derived (01 §12 lists S13 for the 200% layout; there is no LargeText artboard): the card shrinks to `size.card.md`, everything else stacks |

## Motion
Reveal: `motion.ritual.flip` (600 ms) + `haptic.flip`; the texts fade in with a `motion.ritual.readingReveal` stagger. Reduced: a 200 ms cross-fade, texts at once.

## Semantics / reading order
Back → "Your daily card, Saturday 27 September" → card image ("The Star, upright"; face-down: "Card back, double-tap to reveal") → meta → name (header) → "Keywords: Hope, Renewal, Quiet faith" → short meaning → reflection question → Reflect deeper with AI → Add a note → caption. "Card revealed: The Star" is announced after the flip.

## RTL
Mirrored alignment; keyword chips wrap from the right; the card art is never mirrored; Roman numerals stay LTR.

## Banner
None.

---

**Conventions (same in every S-spec).** Canvas px = dp/sp. Spacing 2/4/8/12/16/20/24/32/40/48/56/64 = `space.1`…`space.12`; odd canvas values (6, 10, 14, 18, 28) snap to the nearest token. Radius: 4 `radius.xs`, 8 `radius.sm`, 10 `radius.card`, 12 `radius.md`, 16 `radius.lg`, 24 `radius.xl`, 28 `radius.sheet`, 999 `radius.full`. Type: serif 40 `type.display`; serif 28 `type.headline`; serif 20–24 `type.cardName`; serif 16–18 paragraphs `type.bodyReading`; sans 20/600 `type.title`; sans 17–18/600 `type.titleSmall`; sans 16 `type.body`; sans 14–15/500 `type.label`; sans 12–13 `type.caption`; numerals `type.numeral`. Nothing renders below 12 sp (canvas 9–11 px badges become `type.caption`). Side gutter `layout.gutter` (16; onboarding pages use `space.7` = 24). Tablet: the content column is `layout.maxContentWidth` (600) centred, long text is capped at `layout.readingMaxWidth`. Controls drawn at 40–44 px keep their look but get a ≥ `size.touchTarget.min` (48) hit area. Colours are tokens only (`color.*`, names in 01 §14.1). Every ★ state is a golden in light + dark at phone and tablet width (01 §8.3, RC24). *Derived* means that no artboard exists: Phase 16/17 builds the state from the designed states, the tokens and the shared state widgets (01 §8.2), and REVIEW.md checks it.
