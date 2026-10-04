# S08 · Draw ritual (shuffle → pick → reveal → awaiting)

| | |
|---|---|
| Route | `/reading/draw` (also used by the Classic flow F8, which has no commit and no awaiting) |
| Banner | none |
| Artboards | [`../Draw.dc.html`](../Draw.dc.html) (`picking`) · [`../DrawShuffle.dc.html`](../DrawShuffle.dc.html) (`shuffling`) · [`../DrawReveal.dc.html`](../DrawReveal.dc.html) (`revealing`) · [`../DrawAwaiting.dc.html`](../DrawAwaiting.dc.html) (`awaitingReading`, keywords view) · [`../DrawAr.dc.html`](../DrawAr.dc.html) (ar RTL) |
| Frames | [`Draw.png`](../frames/Draw.png) · [`DrawShuffle.png`](../frames/DrawShuffle.png) · [`DrawReveal.png`](../frames/DrawReveal.png) · [`DrawAwaiting.png`](../frames/DrawAwaiting.png) · [`DrawAr.png`](../frames/DrawAr.png) (PNG @2x, from the artboards above) |
| Next | Reading arrives → S09 (AI) / after the last reveal → S32 (Classic) · crisis → S27 · hold lost → S10 |

## Layout (top → bottom), `picking` (Draw.dc.html)
Padding `space.10` / `layout.gutter` / `space.8`; gap `space.7`.
1. Top bar: Close `TaroIconButton` (X) at the start; progress `type.label` `color.text.secondary` at the end ("2 of 3 picked", a polite live region).
2. Title serif 24 `type.cardName` ("Pick one more card" / "Pick 3 cards"), subtitle `type.label` `color.text.secondary` "Take your time. Tap a card that draws you."
3. `SpreadCanvas`: the slots at normalized layout coordinates (01 §10.2), scaled to the content width. For 3 cards: 96 × 166 slots, `radius.card`, gap `space.4`, position labels `type.label` below. A picked slot shows `TaroCardBack`; an empty slot is a dashed `color.border.strong` outline with its order number. 5- and 10-card spreads use `size.card.sm` and the diagram geometry (Celtic Cross `challenge` rotated 90°).
4. Flexible spacer.
5. Deck fan, 170 high: 78 `TaroCardBack`s in a horizontally scrollable arc (the canvas shows 7). The focused card is lifted with `color.card.glow`.
6. Buttons row, gap `space.4`: `TaroButton.secondary` "Draw for me" + `TaroButton.primary` "Pick this card" (it picks the focused or centred card; this is the button alternative for switch and keyboard users). Tapping a card in the fan picks it directly.

`shuffling` (DrawShuffle): a stacked deck in the middle, the title "Shuffle the deck", a hold-or-tap "Shuffle" button (the button alternative to the hold gesture), then "Continue" once `motion.ritual.shuffle` has run at least once.
`revealing` (DrawReveal): the fan is gone; the slots grow to `size.card.md`. Tap each card in position order, or tap "Reveal all". Under each revealed card: its name (`type.cardName`), orientation text ("Reversed" + 180° art rotation + `color.card.reversedBadge`) and 3 keywords (`type.caption`).
**Preset cards** (the declined draw reused by "Reflect on the cards without a question", 01 §7.5, or the daily card's "Reflect deeper", 01 §7.6): the cards are already chosen, so S08 skips `shuffling` and `picking` and opens on `revealing` with those cards face-down (R3-03).
`awaitingReading` (DrawAwaiting): position titles + keywords per card as a list, with a calm progress line ("Writing your reading…"). No percentage and no fake progress.

## Components
`SpreadCanvas`, `TaroCardBack`, `TaroCardFace`, `TaroCardFlip`, `TaroButton`, `TaroIconButton`, `TaroDialog` (leave confirmation), `TaroErrorView`, deck fan (**new**: `DeckFan`; add to `components.md`).

## States (01 §8.3)
| State | ★ | Source |
|---|---|---|
| `shuffling` | ★ | **Designed**: `DrawShuffle.dc.html` |
| `picking` | ★ | **Designed**: `Draw.dc.html` |
| `revealing` | | **Designed**: `DrawReveal.dc.html` |
| `awaitingReading` (keywords view) | ★ | **Designed**: `DrawAwaiting.dc.html` |
| `slowReading` (20 s) | | Derived: add the line "This is taking a little longer than usual" under the progress text |
| `generationFailed` | | Derived: the cards stay face-up; `TaroErrorView`-style block "We couldn't create your reading. You haven't been charged." + [Try again] (primary) + [Save and finish later] (secondary) |
| `holdLost` | | Derived: the slots show the picked cards **face-down**, and S10 opens over them; after a grant the same draw is resubmitted |
| `timeoutPolling` (60 s) | | Derived: same visual as `slowReading`; the text becomes "Still checking…" |
| `deliveryExpired` (410) | | Derived: "We couldn't deliver this reading, so you weren't charged" + Try again with the same cards |
| `crisis` | | → S27 immediately (no reading shown) |
| `reducedMotion` variant | ★ | Derived: the same frames with the reduced-motion tokens (below); golden captured with `disableAnimations` |
| ar | | **Designed**: `DrawAr.dc.html` (the ar golden, 01 §14.5) |

Leaving: once any card is picked, Close/Back opens a `TaroDialog`: "Leave this reading? Your cards are saved and you can finish it from the Journal." [Leave] [Stay] (equal weight).

## Motion
Shuffle loop ≥ `motion.ritual.shuffle` (1200 ms; ceremonial, it never affects randomness). Pick: the card flies to its slot, `motion.duration.slow` + `motion.easing.emphasized`; auto-deal staggers by `motion.ritual.dealStagger`. Flip: `motion.ritual.flip` (600 ms). Handing off to S09: `motion.ritual.readingReveal`. Haptics when enabled: `haptic.pick` on pick, `haptic.flip` on flip, `haptic.ready` when the reading arrives. **Reduced motion:** shuffle and flip become 200 ms cross-fades; deal stagger 0; no fan parallax, glow pulse or particles.

## Semantics / reading order
Close → progress (live) → title → subtitle → slots in position order ("Card back, position 2 of 3, Present") → deck ("Deck, 76 cards", horizontal list; each card "Card back, double-tap to pick") → "Draw for me" → "Pick this card". Revealed cards read "Three of Cups, reversed, position: Past", followed by the keywords. The ritual can be finished with "Draw for me" + "Reveal all" alone. Live announcements: picks, "Reading ready", errors.

## RTL
Slot x coordinates mirror (`past` on the right); the fan scrolls from the right; card art is never mirrored, and the reversed rotation stays 180°. The Close X keeps its side at the start (right).

## Text scale
Above 1.5×, the slots and the revealed-card captions reflow into a vertical list (01 §12).

## Banner
None; no ad of any kind during the ritual.

---

**Conventions (same in every S-spec).** Canvas px = dp/sp. Spacing 2/4/8/12/16/20/24/32/40/48/56/64 = `space.1`…`space.12`; odd canvas values (6, 10, 14, 18, 28) snap to the nearest token. Radius: 4 `radius.xs`, 8 `radius.sm`, 10 `radius.card`, 12 `radius.md`, 16 `radius.lg`, 24 `radius.xl`, 28 `radius.sheet`, 999 `radius.full`. Type: serif 40 `type.display`; serif 28 `type.headline`; serif 20–24 `type.cardName`; serif 16–18 paragraphs `type.bodyReading`; sans 20/600 `type.title`; sans 17–18/600 `type.titleSmall`; sans 16 `type.body`; sans 14–15/500 `type.label`; sans 12–13 `type.caption`; numerals `type.numeral`. Nothing renders below 12 sp (canvas 9–11 px badges become `type.caption`). Side gutter `layout.gutter` (16; onboarding pages use `space.7` = 24). Tablet: the content column is `layout.maxContentWidth` (600) centred, long text is capped at `layout.readingMaxWidth`. Controls drawn at 40–44 px keep their look but get a ≥ `size.touchTarget.min` (48) hit area. Colours are tokens only (`color.*`, names in 01 §14.1). Every ★ state is a golden in light + dark at phone and tablet width (01 §8.3, RC24). *Derived* means that no artboard exists: Phase 16/17 builds the state from the designed states, the tokens and the shared state widgets (01 §8.2), and REVIEW.md checks it.
