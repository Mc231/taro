# S31 · Readings paused (`readingsPaused`, inline state of S07)

| | |
|---|---|
| Route | none: an inline state of S07 `/reading/question` (analytics screen `S31`) |
| Banner | none. Never a paywall: no prices, no rewarded offer, never S10 (RC47) |
| Artboards | [`../ReadingsPaused.dc.html`](../ReadingsPaused.dc.html) |
| Frames | [`ReadingsPaused.png`](../frames/ReadingsPaused.png) (PNG @2x, from the artboards above) |
| Triggers | `503 READINGS_DISABLED` / `AI_BUDGET_EXHAUSTED` from the hold, or `canReadReason == readingsPaused`; copy variant `freePaused` from `402 INSUFFICIENT_CREDITS` with `details.reason = freePaused`, shown only to users with no other readings (RC64) |
| Next | "Try a classic reading" → S08 (Classic ritual) → S32 · "Back to Today" → S05 |

## Layout (top → bottom)
S07's frame (padding `space.10` / `layout.gutter` / `space.5`; gap `space.5`, tightened to fit the links at 844) without the balance chip:
1. Back; spread overline "Past · Present · Future"; title "What would you like to reflect on?".
2. The question field (3 rows), keeping the user's text (read-only while paused).
3. Status card (`role=status`, `color.bg.surface`, `radius.lg`, padding `space.5` / `space.6`, gap `space.4`): an icon tile 40 (`color.accent.subtle`, `radius.md`, a pause/moon glyph) + h2 serif 20 `type.cardName` "Readings are resting for a moment" + body `type.label` `color.text.secondary` "This is on our side, and nothing has been used from your balance. Your question is kept here for later. Your journal, daily card and Learn still work as usual."; then a row of outlined pill links (44 → 48 hit, `color.accent.primary` text): Daily card → S13, Learn → S16, Journal → S14.
4. Flexible spacer.
5. `TaroButton.primary` "Try a classic reading" (52) + caption "Uses the card meanings for each position. Free, no AI, works offline."; `TaroButton.secondary` "Back to Today".

**Copy (resolved):** 05 §3 has no string for this state, so 01 §8.3 is the source: the title is now "Readings are resting for a moment" (the canvas said "AI readings are paused for now"), and the `freePaused` variant is "Free readings are resting until tomorrow". The daily card / Learn **links** that 01 lists are drawn as pills in the card (plus Journal).

## Components
Status card (**new**: `StatusCard`, reused for `refused`, `dailyLimitReached` and `aiUnavailableRegion` on S07), `TaroTextField` (read-only), `TaroButton`.

## States
| State | ★ | Source |
|---|---|---|
| `readingsPaused` | | **Designed**: `ReadingsPaused.dc.html` |
| `freePaused` copy variant | | Derived: same card, the title "Free readings are resting until tomorrow" |
| `aiUnavailableRegion` (Classic offer) | | Derived: same card, the title "AI readings aren't available in your region", same Classic CTA |

## Motion
The card fades in over `motion.duration.base` in place of Begin; reduced: instant.

## Semantics / reading order
Back → spread + title → question field → status card (polite live region: title + body) → Daily card / Learn / Journal links → Try a classic reading → caption → Back to Today.

## RTL
Mirrored; the icon tile sits at the start.

## Banner
None.

---

**Conventions (same in every S-spec).** Canvas px = dp/sp. Spacing 2/4/8/12/16/20/24/32/40/48/56/64 = `space.1`…`space.12`; odd canvas values (6, 10, 14, 18, 28) snap to the nearest token. Radius: 4 `radius.xs`, 8 `radius.sm`, 10 `radius.card`, 12 `radius.md`, 16 `radius.lg`, 24 `radius.xl`, 28 `radius.sheet`, 999 `radius.full`. Type: serif 40 `type.display`; serif 28 `type.headline`; serif 20–24 `type.cardName`; serif 16–18 paragraphs `type.bodyReading`; sans 20/600 `type.title`; sans 17–18/600 `type.titleSmall`; sans 16 `type.body`; sans 14–15/500 `type.label`; sans 12–13 `type.caption`; numerals `type.numeral`. Nothing renders below 12 sp (canvas 9–11 px badges become `type.caption`). Side gutter `layout.gutter` (16; onboarding pages use `space.7` = 24). Tablet: the content column is `layout.maxContentWidth` (600) centred, long text is capped at `layout.readingMaxWidth`. Controls drawn at 40–44 px keep their look but get a ≥ `size.touchTarget.min` (48) hit area. Colours are tokens only (`color.*`, names in 01 §14.1). Every ★ state is a golden in light + dark at phone and tablet width (01 §8.3, RC24). *Derived* means that no artboard exists: Phase 16/17 builds the state from the designed states, the tokens and the shared state widgets (01 §8.2), and REVIEW.md checks it.
