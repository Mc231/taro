# S33 · Report reading (modal sheet)

| | |
|---|---|
| Route | modal sheet from S09 / S15 (AI readings only; CS7, RC72) |
| Banner | none |
| Artboards | [`../Report.dc.html`](../Report.dc.html) (`editing`, over a dimmed S09) |
| Frames | [`Report.png`](../frames/Report.png) (PNG @2x, from the artboards above) |
| Wire | `POST /v1/readings/{clientReadingId}/report`, `reason ∈ offensive \| harmful_advice \| sexual \| hateful \| other`, note ≤ 500 chars |

## Layout (top → bottom)
Scrim `color.bg.scrim`. Sheet: `color.bg.surfaceRaised`, top corners `radius.sheet`, padding `space.4` / `space.6` / `space.8` (+ safe area), gap `space.5`; it rises with the keyboard.
1. Drag handle 36 × 4.
2. Title serif 24 `type.cardName` `reportReadingTitle` "Report this reading"; body `type.label` "Tell us what felt wrong so we can look into it."
3. Fieldset "What's the problem?": 5 radio rows (min 48, `type.body`): Offensive, Harmful advice, Sexual content, Hateful, Something else (`other`). **No default** (**resolved**: the canvas pre-checked "Offensive"; `Report.dc.html` now has no reason selected). "Send report" is disabled (`color.bg.surface` fill, `color.text.tertiary` label, `aria-disabled`) until a reason is picked, with the hint "Choose a reason to send your report." (`type.caption`) under it, which avoids a biased default.
4. Details: label "Details (optional)"; `TaroTextField` 2 rows, `color.bg.sunken`, `radius.md`, placeholder "For example, which card or sentence", counter "0 / 500".
5. Disclosure panel (`color.bg.surface`, `radius.md`, info icon, `type.caption`): the ARB `reportReadingDisclosure` "Your question and this reading will be sent to Taro and kept for 90 days." (05 §3). **Resolved**: the canvas added "…so we can review them. Then they are deleted." and said "us"; `Report.dc.html` now shows the exact ARB text.
6. `TaroButton.primary` "Send report" (52; disabled until a reason is chosen) + the hint caption + `TaroButton.secondary` "Cancel" (52).

## Components
`TaroSheet`, radio rows, `TaroTextField` (counter), `TaroInlineNotice`, `TaroButton`, snackbar.

## States (01 §8.3)
| State | ★ | Source |
|---|---|---|
| `editing` | ★ | **Designed**: `Report.dc.html` (no reason selected, Send disabled) |
| `submitting` | | Derived: Send loading; the inputs are read-only |
| `submitted` | | Derived: the sheet closes; snackbar "Thanks. We'll review this reading."; the S09 overflow shows "Reported" |
| `failed` | | Derived: `TaroInlineNotice(error)` above Send + Retry; the inputs are kept |
| `offline` | | Derived: Send disabled + `TaroInlineNotice(network)` |
| `rateLimited` (10/day) | | Derived: Send disabled + "You've sent the most reports allowed for today." |
| `alreadyReported` | | No sheet: the S09/S15 menu item reads "Reported" (disabled) |

## Motion
As S10: sheet in `motion.duration.slow` decelerate, out `motion.duration.base` accelerate; reduced: fade only.

## Semantics / reading order
A modal dialog labelled by the title; focus on the title → body → the radio group "What's the problem?" → Details (+ counter at the limit) → disclosure → Send report (announces disabled until a reason is chosen) → Cancel. Results are announced through a live region.

## RTL
Mirrored; radios on the right; the counter uses locale numerals.

## Banner
None.

---

**Conventions (same in every S-spec).** Canvas px = dp/sp. Spacing 2/4/8/12/16/20/24/32/40/48/56/64 = `space.1`…`space.12`; odd canvas values (6, 10, 14, 18, 28) snap to the nearest token. Radius: 4 `radius.xs`, 8 `radius.sm`, 10 `radius.card`, 12 `radius.md`, 16 `radius.lg`, 24 `radius.xl`, 28 `radius.sheet`, 999 `radius.full`. Type: serif 40 `type.display`; serif 28 `type.headline`; serif 20–24 `type.cardName`; serif 16–18 paragraphs `type.bodyReading`; sans 20/600 `type.title`; sans 17–18/600 `type.titleSmall`; sans 16 `type.body`; sans 14–15/500 `type.label`; sans 12–13 `type.caption`; numerals `type.numeral`. Nothing renders below 12 sp (canvas 9–11 px badges become `type.caption`). Side gutter `layout.gutter` (16; onboarding pages use `space.7` = 24). Tablet: the content column is `layout.maxContentWidth` (600) centred, long text is capped at `layout.readingMaxWidth`. Controls drawn at 40–44 px keep their look but get a ≥ `size.touchTarget.min` (48) hit area. Colours are tokens only (`color.*`, names in 01 §14.1). Every ★ state is a golden in light + dark at phone and tablet width (01 §8.3, RC24). *Derived* means that no artboard exists: Phase 16/17 builds the state from the designed states, the tokens and the shared state widgets (01 §8.2), and REVIEW.md checks it.
