# S02 · Onboarding: Welcome

| | |
|---|---|
| Route | `/onboarding/welcome` |
| Banner | none |
| Artboards | [`../Main.dc.html`](../Main.dc.html) (canvas title "S02 Welcome") |
| Frames | [`Main.png`](../frames/Main.png) (PNG @2x, from the artboards above) |
| Next | "Get started" → S03 |

## Layout (top → bottom)
Padding `space.12` top, `space.7` sides, `space.9` bottom; column gap `space.8`.
1. Hero, 220 high: two `TaroCardBack` (96 × 166, `radius.card`) fanned behind one `TaroCardFace` (The Star, numeral XVII in `type.numeral`, name in serif 12 → `type.caption`). Decorative.
2. Headline "A quiet place to reflect with tarot": serif 40 → `type.display`, `color.text.primary`.
3. Lead: sans 16 `type.body`, `color.text.secondary` ("Draw a spread, read a thoughtful interpretation, and keep what you notice in a private journal.").
4. Three feature rows, gap `space.4` (canvas 14), icon `size.icon.md` in `color.accent.primary` + `type.body`: "One free AI reading every day", "A free daily card, even offline", "Your journal stays on this phone".
5. Flexible spacer.
6. `TaroButton.primary` "Get started", full width, 52 high, `radius.md`.
7. Step indicator "Step 1 of 3": three dots 6 × 6, the active one 20 × 6 in `color.accent.primary`, the others `color.border.strong`; gap `space.3`.

01 §7.12 allows up to 3 swipeable pages (*Reflect*, *Learn*, *Journal*). The canvas folds all three into this one page; v1 ships one page. If more pages are added later, they reuse this template, and the step indicator stays the onboarding step (1 of 3), not the page index.

## Components
`TaroScaffold` (no app bar), `TaroCardBack`, `TaroCardFace`, `TaroButton`, step indicator (new small component, add to `components.md`).

## States (01 §8.3)
| State | ★ | Source |
|---|---|---|
| `content` | ★ | **Designed**: `Main.dc.html` |

## Motion
Hero cards deal in once on first paint: stagger `motion.ritual.dealStagger`, each `motion.duration.slow`, `motion.easing.emphasized`. Page → S03: shared-axis push `motion.duration.base`. Reduced motion: hero static, push becomes a fade.

## Semantics / reading order
Hero excluded from semantics. Order: headline (header) → lead → the three features as a list → "Get started" → "Step 1 of 3" (one label; the dots are excluded).

## RTL
Mirrored column alignment; feature icons sit at the start (right). The hero fan mirrors its positions, but the Star face is not mirrored. The step indicator fills from the right.

## Text scale
At 200% the page scrolls. The hero shrinks to a single card so "Get started" stays reachable without clipping.

## Banner
None. Onboarding never shows ads or prices (04 §11).

---

**Conventions (same in every S-spec).** Canvas px = dp/sp. Spacing 2/4/8/12/16/20/24/32/40/48/56/64 = `space.1`…`space.12`; odd canvas values (6, 10, 14, 18, 28) snap to the nearest token. Radius: 4 `radius.xs`, 8 `radius.sm`, 10 `radius.card`, 12 `radius.md`, 16 `radius.lg`, 24 `radius.xl`, 28 `radius.sheet`, 999 `radius.full`. Type: serif 40 `type.display`; serif 28 `type.headline`; serif 20–24 `type.cardName`; serif 16–18 paragraphs `type.bodyReading`; sans 20/600 `type.title`; sans 17–18/600 `type.titleSmall`; sans 16 `type.body`; sans 14–15/500 `type.label`; sans 12–13 `type.caption`; numerals `type.numeral`. Nothing renders below 12 sp (canvas 9–11 px badges become `type.caption`). Side gutter `layout.gutter` (16; onboarding pages use `space.7` = 24). Tablet: the content column is `layout.maxContentWidth` (600) centred, long text is capped at `layout.readingMaxWidth`. Controls drawn at 40–44 px keep their look but get a ≥ `size.touchTarget.min` (48) hit area. Colours are tokens only (`color.*`, names in 01 §14.1). Every ★ state is a golden in light + dark at phone and tablet width (01 §8.3, RC24). *Derived* means that no artboard exists: Phase 16/17 builds the state from the designed states, the tokens and the shared state widgets (01 §8.2), and REVIEW.md checks it.
