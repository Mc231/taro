# S03 · Onboarding: Disclaimer

| | |
|---|---|
| Route | `/onboarding/disclaimer` |
| Banner | none |
| Artboards | [`../Disclaimer.dc.html`](../Disclaimer.dc.html) |
| Frames | [`Disclaimer.png`](../frames/Disclaimer.png) (PNG @2x, from the artboards above) |
| Next | "I understand" → S04; "Read the full disclaimer" → S29 `/legal/disclaimer` |

## Layout (top → bottom)
Padding `space.12` / `space.7` / `space.9`; column gap `space.8` (canvas 28).
1. Title: serif 28 `type.headline`, `disclaimerOnboardingTitle` "Tarot for reflection".
2. Lead: serif 18 `type.bodyReading`, `disclaimerOnboardingBody` (exact 05 §3 string).
3. Three notice cards, gap `space.4`. Each is `color.bg.surface`, `radius.md`, padding `space.5`, with an icon (`size.icon.md`, `color.accent.primary`) and `type.body` text: AI-generated content ("Readings are written by AI and may be wrong or unexpected.", covering the 01 §7.12 step-2 requirement) / you decide ("You decide what a card means for you; Taro never tells you what to do.") / support lines under Help. The former "no advice" card was replaced because the lead now says it verbatim.
4. Flexible spacer.
5. `TaroButton.primary` "I understand", full width, 52.
6. Text link "Read the full disclaimer" (48 hit), `type.label`, `color.accent.primary`.
7. Step indicator "Step 2 of 3".

**Copy rule.** The title and body are compliance strings fixed by 05 §3: `disclaimerOnboardingTitle` ("Tarot for reflection") and `disclaimerOnboardingBody`. **Resolved**: `Disclaimer.dc.html` now shows both strings verbatim (it previously read "Before you begin" + a different lead). Code renders the ARB strings in this layout. Changing the wording means changing 05 §3 first. The three notice cards are extra copy (new ARB keys, owner review) and never replace `disclaimerOnboardingBody`.

## Components
`TaroButton`, notice card (`TaroInlineNotice(kind: info)` style), step indicator.

## States (01 §8.3)
| State | ★ | Source |
|---|---|---|
| `content` | ★ | **Designed**: `Disclaimer.dc.html` |
| `acknowledged` | | Derived: the button shows its loading state while the onboarding step is persisted, then S04 is pushed. There is no visual change beyond that |

## Motion
Push from S02 and to S04: `motion.duration.base`, `motion.easing.standard`; reduced: fade.

## Semantics / reading order
Title (header) → lead → the three notices as a list → "I understand" → "Read the full disclaimer" (link) → "Step 2 of 3". The user cannot skip past this page without it being on screen (05 §3). Back returns to S02.

## RTL
Icons at the start (right); text right-aligned; the step indicator mirrors.

## Banner
None.

---

**Conventions (same in every S-spec).** Canvas px = dp/sp. Spacing 2/4/8/12/16/20/24/32/40/48/56/64 = `space.1`…`space.12`; odd canvas values (6, 10, 14, 18, 28) snap to the nearest token. Radius: 4 `radius.xs`, 8 `radius.sm`, 10 `radius.card`, 12 `radius.md`, 16 `radius.lg`, 24 `radius.xl`, 28 `radius.sheet`, 999 `radius.full`. Type: serif 40 `type.display`; serif 28 `type.headline`; serif 20–24 `type.cardName`; serif 16–18 paragraphs `type.bodyReading`; sans 20/600 `type.title`; sans 17–18/600 `type.titleSmall`; sans 16 `type.body`; sans 14–15/500 `type.label`; sans 12–13 `type.caption`; numerals `type.numeral`. Nothing renders below 12 sp (canvas 9–11 px badges become `type.caption`). Side gutter `layout.gutter` (16; onboarding pages use `space.7` = 24). Tablet: the content column is `layout.maxContentWidth` (600) centred, long text is capped at `layout.readingMaxWidth`. Controls drawn at 40–44 px keep their look but get a ≥ `size.touchTarget.min` (48) hit area. Colours are tokens only (`color.*`, names in 01 §14.1). Every ★ state is a golden in light + dark at phone and tablet width (01 §8.3, RC24). *Derived* means that no artboard exists: Phase 16/17 builds the state from the designed states, the tokens and the shared state widgets (01 §8.2), and REVIEW.md checks it.
