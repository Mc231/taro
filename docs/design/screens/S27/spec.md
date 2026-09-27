# S27 · Crisis resources (support lines)

| | |
|---|---|
| Route | `/help/crisis` |
| Banner | none. Calm: no ads, no upsell, no balance chip, no reading CTA (01 §7.5) |
| Artboards | [`../Crisis.dc.html`](../Crisis.dc.html) (UK example) |
| Frames | [`Crisis.png`](../frames/Crisis.png) (PNG @2x, from the artboards above) |
| Entry | declined `self_harm` / `harm_to_others` (S08/S07, resources from the Worker by `cf.country`); S28, S20, S19, S29 (resources from the bundled asset by device region; works offline) |

## Layout (top → bottom)
Padding `space.10` / `layout.gutter` / `space.7`; gap 14 → `space.4`.
1. Top bar: Back (from a declined reading → S05).
2. Title serif 28 `type.headline` + body `type.body`. **Copy is ARB `crisisTitle` / `crisisBody` (05 §3):** "You're not alone" / "If you are thinking about harming yourself, please reach out now. Talking to someone can help." **Resolved**: `Crisis.dc.html` now uses both strings verbatim (it read "You don't have to go through this alone" + other body copy). Changing them means changing 05 §3 first.
3. Emergency card (`color.bg.surface`, `radius.lg`, padding `space.4` / `space.5`): "If you're in immediate danger, call 999" + `TaroButton` "Call 999" in `color.accent.secondary` (the only `accent.secondary` CTA in the app, 48). The number comes from the country entry.
4. Section caption "Support in the United Kingdom" (country name localized).
5. Resource rows (gap `space.3`, `color.bg.surfaceRaised`, `radius.lg`, padding `space.4` / `space.4` / `space.4` / `space.5`): the name `type.body`/600; the contact line `type.label` "116 123 · free, 24/7"; the description `type.caption`; an action button at the end (`color.accent.primary`, 48): "Call" (`tel:`), "Text" (`sms:`) or "Open" (`url`), with an icon. At most 3 entries from the Worker, always including the international entry. The UK example shows Samaritans, Shout and the international entry; the former third UK row (NHS 111) was dropped to respect this limit.
6. The international row, always last: name "Find a helpline in another country", contact line "findahelpline.com", description "Free, confidential support lines worldwide", "Open" button (external-link icon, `url`). **Resolved**: drawn on `Crisis.dc.html`.
7. Text button "Show resources for another country" → a country picker `TaroSheet`.
8. Footer caption "Last checked Sep 2026" (from `verifiedAt`).

## Components
Resource row (**new**: `CrisisResourceRow`), `TaroButton`, `TaroSheet` (country picker).

## States (01 §8.3)
| State | ★ | Source |
|---|---|---|
| `content` (country-aware, offline OK) | ★ | **Designed**: `Crisis.dc.html` |
| another country chosen | | Derived: the same list for the selected country |
| no entry for the region | | Derived: the international entry + the local emergency number line only |

## Motion
Push only; no decorative motion. Reduced: fade.

## Semantics / reading order
Focus lands on the title → body → the emergency line + "Call 999" → the section heading (header) → each resource (one node: "Samaritans, 116 123, free, 24/7, talk to someone about anything") + its action ("Call Samaritans on 116 123") → Find a helpline in another country ("Open findahelpline.com") → another country → last checked.

## RTL
Mirrored; phone numbers and SMS codes are bidi-isolated LTR; the call icon is not mirrored.

## Banner
None.

---

**Conventions (same in every S-spec).** Canvas px = dp/sp. Spacing 2/4/8/12/16/20/24/32/40/48/56/64 = `space.1`…`space.12`; odd canvas values (6, 10, 14, 18, 28) snap to the nearest token. Radius: 4 `radius.xs`, 8 `radius.sm`, 10 `radius.card`, 12 `radius.md`, 16 `radius.lg`, 24 `radius.xl`, 28 `radius.sheet`, 999 `radius.full`. Type: serif 40 `type.display`; serif 28 `type.headline`; serif 20–24 `type.cardName`; serif 16–18 paragraphs `type.bodyReading`; sans 20/600 `type.title`; sans 17–18/600 `type.titleSmall`; sans 16 `type.body`; sans 14–15/500 `type.label`; sans 12–13 `type.caption`; numerals `type.numeral`. Nothing renders below 12 sp (canvas 9–11 px badges become `type.caption`). Side gutter `layout.gutter` (16; onboarding pages use `space.7` = 24). Tablet: the content column is `layout.maxContentWidth` (600) centred, long text is capped at `layout.readingMaxWidth`. Controls drawn at 40–44 px keep their look but get a ≥ `size.touchTarget.min` (48) hit area. Colours are tokens only (`color.*`, names in 01 §14.1). Every ★ state is a golden in light + dark at phone and tablet width (01 §8.3, RC24). *Derived* means that no artboard exists: Phase 16/17 builds the state from the designed states, the tokens and the shared state widgets (01 §8.2), and REVIEW.md checks it.
