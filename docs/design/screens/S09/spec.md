# S09 · Reading result (AI)

| | |
|---|---|
| Route | `/reading/:id` |
| Banner | none |
| Artboards | [`../Reading.dc.html`](../Reading.dc.html) (dark, en) · [`../ReadingLight.dc.html`](../ReadingLight.dc.html) · [`../ReadingAr.dc.html`](../ReadingAr.dc.html) (ar, RTL) · [`../ReadingLargeText.dc.html`](../ReadingLargeText.dc.html) (200% text) · [`../ReadingRated.dc.html`](../ReadingRated.dc.html) (`ratingGiven` + toast) · [`../ScreenshotFrame.dc.html`](../ScreenshotFrame.dc.html) (Phase 20 store frames) |
| Frames | [`Reading.png`](../frames/Reading.png) · [`ReadingLight.png`](../frames/ReadingLight.png) · [`ReadingAr.png`](../frames/ReadingAr.png) · [`ReadingLargeText.png`](../frames/ReadingLargeText.png) · [`ReadingRated.png`](../frames/ReadingRated.png) · [`ScreenshotFrame.png`](../frames/ScreenshotFrame.png) (PNG @2x, from the artboards above) |
| Next | Done → S05 (never back to S08) · Add note → note editor (S15 style) · More → Favourite / Share / Report (S33) |
| Sample content | [`../../samples/readings/`](../../samples/readings/) (`single`, `three_ppf`, `relationship`, `celtic_cross`) |

## Layout (top → bottom)
Padding `space.10` / `layout.gutter` / `space.7`; gap `space.6`; the text column is capped at `layout.readingMaxWidth`.
1. Top bar: Done `TaroIconButton` (X) at the start; at the end, the "Add note" text button + More `TaroIconButton` (overflow).
2. **Header** (01 §7.4): the spread name and date (`type.caption`, above the cards). **Still open on the canvas:** no Reading artboard draws this line yet (not part of this fix pass); code adds it as specified, then a mini spread of `TaroCardFace`s (84 × 145 on the canvas; `size.card.sm`–`md`, `radius.card`, gap `space.3`) with position labels (`type.caption`). A reversed card shows the art rotated 180° **and** the `color.card.reversedBadge` "Reversed" label (the canvas draws only the label; the badge text renders at ≥ 12 sp). 5 and 10 cards: a scaled `SpreadCanvas` using the diagram geometry.
3. Text block (`ReadingTextView`, selectable), gap `space.4`:
   - the question in quotes, `type.caption` `color.text.secondary`;
   - the title (`ReadingContent.title`), serif 28 `type.headline`;
   - **`aiLabel` "AI-generated" `Badge` next to or under the title.** Required by 05 §3 on every AI reading header. **Resolved**: every Reading artboard (`Reading`, `ReadingLight`, `ReadingAr`, `ReadingLargeText`, `ReadingRated`) now draws the badge;
   - the summary (`overview`), serif 18 `type.bodyReading`, line height ≥ 1.5;
   - one section per position: a heading `type.title` (20/600) with a 6 px suit dot (`color.suit.*`, decorative) "Present · The Star, reversed", then the interpretation in `type.bodyReading`. Sections are expandable (01 §7.4) and expanded by default.
4. Below the fold (not drawn; derived with the same styles): **Synthesis** heading + text; **Reflection prompts** (2–3, each a `type.bodyReading` line + a "Write about this" text button → note editor prefilled with the prompt as a heading); the action row: Favourite toggle, Share, 👍 / 👎 rating (48 hit each; 👎 reveals reason chips "Too generic", "Didn't match the cards", "Tone", "Other"; no free text).
5. `DisclaimerFooter`: `disclaimerShort` ("For entertainment and self-reflection. Not professional advice.") + a link to the full disclaimer (S29). **Resolved**: the footers on every Reading artboard now use `disclaimerShort`, and the AI label is the header badge (rule: header badge `aiLabel` "AI-generated" + footer `disclaimerShort`; 05 §3).

## Components
`ReadingTextView`, `TaroCardFace`, `SpreadCanvas` (mini), `Badge` (AI label), `DisclaimerFooter`, `TaroIconButton`, `TaroButton.tertiary`, rating control + reason chips (**new**: `RatingBar`; add to `components.md`), overflow menu, `SkeletonBlock`.

## States (01 §8.3)
| State | ★ | Source |
|---|---|---|
| `content` LTR dark | ★ | **Designed**: `Reading.dc.html` |
| `content` LTR light | ★ | **Designed**: `ReadingLight.dc.html` |
| `content` RTL (ar) dark | ★ | **Designed**: `ReadingAr.dc.html` |
| `content` RTL light | ★ | Derived: `ReadingAr` layout with light tokens |
| `ratingGiven` | | **Designed**: `ReadingRated.dc.html` (the selected thumb filled `color.accent.primary`, the reason chips inline after 👎, the "Thanks for the feedback" toast) |
| `sharing` | | Derived: OS share sheet with a rendered share image (cards + title + summary excerpt + `disclaimerShort` footer, 05 §3) |
| `loadingFromStorage` | | Derived: `SkeletonBlock`s for the title and paragraphs; the cards render first; `DisclaimerFooter` is visible even while loading |
| reported (`alreadyReported`) | | Derived: the overflow shows "Reported" (disabled); S33 does not reopen |
| 200% text | | **Designed**: `ReadingLargeText.dc.html`; the cards reflow to a vertical list above 1.5× |

## Motion
Arrival from S08: sections enter with a `motion.ritual.readingReveal` (500 ms) stagger, a fade + 8 dp rise, `motion.easing.decelerate`; `haptic.ready`. Section expand/collapse `motion.duration.base`. Reduced motion: everything appears at once, no rise.

## Semantics / reading order
Done → Add note → More → mini spread (each card "Three of Cups, position: Past" / "The Star, reversed, position: Present") → question → title (header) → "AI-generated" → summary → each position heading (header) + text → Synthesis (header) → prompts + "Write about this" → Favourite, Share, rating → disclaimer + link. A polite live region announces "Reading ready" on arrival. Headings use `Semantics(header: true)` (01 §12).

## RTL (`ReadingAr`)
The card row mirrors (Past on the right). Inside each card, the art, numerals and frame stay LTR (`dir=ltr` on the face), while the card name and the "مقلوبة" badge are RTL. Quotes use «». The suit dot sits at the start (right). Section headings read "الحاضر · النجمة، مقلوبة". The reading text keeps its `contentLocale`: an old English reading under the ar UI stays LTR inside the RTL chrome, with a small language label.

## Banner
None. A banner never sits inside `ReadingTextView`, over the spread, or on any reading screen (RC18).

---

**Conventions (same in every S-spec).** Canvas px = dp/sp. Spacing 2/4/8/12/16/20/24/32/40/48/56/64 = `space.1`…`space.12`; odd canvas values (6, 10, 14, 18, 28) snap to the nearest token. Radius: 4 `radius.xs`, 8 `radius.sm`, 10 `radius.card`, 12 `radius.md`, 16 `radius.lg`, 24 `radius.xl`, 28 `radius.sheet`, 999 `radius.full`. Type: serif 40 `type.display`; serif 28 `type.headline`; serif 20–24 `type.cardName`; serif 16–18 paragraphs `type.bodyReading`; sans 20/600 `type.title`; sans 17–18/600 `type.titleSmall`; sans 16 `type.body`; sans 14–15/500 `type.label`; sans 12–13 `type.caption`; numerals `type.numeral`. Nothing renders below 12 sp (canvas 9–11 px badges become `type.caption`). Side gutter `layout.gutter` (16; onboarding pages use `space.7` = 24). Tablet: the content column is `layout.maxContentWidth` (600) centred, long text is capped at `layout.readingMaxWidth`. Controls drawn at 40–44 px keep their look but get a ≥ `size.touchTarget.min` (48) hit area. Colours are tokens only (`color.*`, names in 01 §14.1). Every ★ state is a golden in light + dark at phone and tablet width (01 §8.3, RC24). *Derived* means that no artboard exists: Phase 16/17 builds the state from the designed states, the tokens and the shared state widgets (01 §8.2), and REVIEW.md checks it.
