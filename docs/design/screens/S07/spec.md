# S07 · Question input + Begin

| | |
|---|---|
| Route | `/reading/question?spread=` |
| Banner | none |
| Artboards | [`../Question.dc.html`](../Question.dc.html) (`editing`); [`../QuestionRefused.dc.html`](../QuestionRefused.dc.html) (`refused(category)`); [`../ReadingsPaused.dc.html`](../ReadingsPaused.dc.html) (the S31 inline state, see [../S31/spec.md](../S31/spec.md)); S10 over this screen: [`../OutOfReadings.dc.html`](../OutOfReadings.dc.html) |
| Frames | [`Question.png`](../frames/Question.png) · [`QuestionRefused.png`](../frames/QuestionRefused.png) · [`ReadingsPaused.png`](../frames/ReadingsPaused.png) · [`OutOfReadings.png`](../frames/OutOfReadings.png) (PNG @2x, from the artboards above) |
| Next | Begin → pre-draw gate (RC44 order) → hold → S08; the failures route per the states below |

## Layout (top → bottom)
Padding `space.10` / `layout.gutter` / `space.8`; gap `space.6`.
1. Top bar: Back 48 at the start; `BalanceChip` at the end (36 visual, "1 free reading today"; text from `nextSource`).
2. Spread name overline `type.caption` `color.text.tertiary` ("Past · Present · Future"), then the title serif 28 `type.headline` "What would you like to reflect on?".
3. Field block (gap `space.3`): label `type.caption` "Your question (optional)"; `TaroTextField` multiline (4 rows), `color.bg.sunken`, `radius.md`, padding `space.4`/`space.5`, input serif 18 `type.bodyReading`, 1 px `color.border.subtle` (focus `color.border.focus`); grapheme counter `type.caption` at the end ("44 / 300"). **Code shows the counter only at ≥ 250 graphemes** (01 §7.2); the canvas shows it for illustration.
4. The inline guidance under the field (01 §7.2), `type.caption` `color.text.secondary`: "Open questions work best. Taro can't answer medical, legal, financial or pregnancy questions." (ARB, copy owned by 05; the field references it with `aria-describedby`). **Resolved**: drawn on `Question.dc.html` under the counter.
5. "Ideas" caption + 3–4 suggestion chips (outlined `color.border.strong`, `radius.full`, 40 visual / 48 hit, `type.label`); they wrap. A tap fills the field.
6. Flexible spacer.
7. `TaroButton.primary` "Begin", full width, 52. Below it the charge note `type.caption` `color.text.tertiary`: "Uses your free reading. Your question is sent to an AI service to write the reading and isn't stored." (provider-neutral, RC97) (the variant follows `nextSource`, e.g. "Uses 1 of your 3 readings").

With the keyboard open, the body scrolls, and Begin stays reachable above the keyboard inset.

## Components
`TaroAppBar`, `BalanceChip`, `TaroTextField` (grapheme counter), suggestion chip (`Badge`/chip variant), `TaroButton` (with loading), `TaroInlineNotice`, S31 status card (see S31).

## States (01 §8.3)
| State | ★ | Source |
|---|---|---|
| `editing` | ★ | **Designed**: `Question.dc.html` |
| `checking` (gate + hold) | | Derived: Begin in its loading state; field and chips read-only; Back still works |
| `offline` | | Derived: Begin disabled (`opacity.disabled`) + `TaroInlineNotice(network)` above it |
| `consentRequired` | | → S04 re-entry variant |
| `deviceUnverified` | | Derived: `TaroInlineNotice(warning)` "Readings unavailable on this device" + Retry; Begin disabled |
| `readingsPaused` (S31) | | **Designed**: `ReadingsPaused.dc.html`. The `freePaused` copy variant is derived |
| `aiUnavailableRegion` → Classic offer | | Derived from the S31 card: region copy + "Try a classic reading" |
| `outOfReadings` → S10 | | S10 sheet over this screen (**designed**), question kept |
| `dailyLimitReached` | | Derived: S31-style card "You've reached today's reading limit"; no paywall, no prices (RC74); links to the daily card, Learn and the Classic reading |
| `lowTrustLimited` | | → S10 with the copy "Free readings aren't available on this device right now" |
| `rephrase` (declined, `canRephrase: true`) | | Derived: `TaroInlineNotice(info)` under the field with the hint + 2 example rewordings as chips, the question kept, and "Reflect on the cards without a question" (same drawn cards) |
| `refused(category)` | ★ | **Designed**: `QuestionRefused.dc.html` (`health`; its per-category title/body are sample copy: the shipped text comes from `messageKey`, with 05 §3 `refusalGeneric` as the fallback). Other categories follow the same S31-style card: icon tile, serif 20 title "Taro can't help with this kind of question", `messageKey` body (03 §9.4 / GLOSSARY §5.2), advice categories add "a qualified professional can help with this"; `sexual_minors` shows the neutral message only, with no rewording hint; the crisis categories never land here (→ S27) |
| `rateLimited` (`burst`) | | Derived: notice "Please wait a moment and try again", Begin re-enabled after `Retry-After` |

## Motion
Notices fade/expand over `motion.duration.base`. Begin → S08: fade-through `motion.duration.slow`, `motion.easing.emphasized`. Reduced: fades ≤ 200 ms.

## Semantics / reading order
Back → balance chip → spread name + title (header) → field (label, hint = guidance text; the counter is announced only from 250) → "Ideas" → each chip ("Suggestion: What am I not seeing? Fills the question") → Begin → charge note. Every error or notice is announced through a polite live region and takes focus only when it blocks Begin.

## RTL
The chip moves to the left; the field uses `TextDirection` from the content (a mixed-script question stays readable); the counter follows locale numerals; chips wrap from the right.

## Banner
None.

---

**Conventions (same in every S-spec).** Canvas px = dp/sp. Spacing 2/4/8/12/16/20/24/32/40/48/56/64 = `space.1`…`space.12`; odd canvas values (6, 10, 14, 18, 28) snap to the nearest token. Radius: 4 `radius.xs`, 8 `radius.sm`, 10 `radius.card`, 12 `radius.md`, 16 `radius.lg`, 24 `radius.xl`, 28 `radius.sheet`, 999 `radius.full`. Type: serif 40 `type.display`; serif 28 `type.headline`; serif 20–24 `type.cardName`; serif 16–18 paragraphs `type.bodyReading`; sans 20/600 `type.title`; sans 17–18/600 `type.titleSmall`; sans 16 `type.body`; sans 14–15/500 `type.label`; sans 12–13 `type.caption`; numerals `type.numeral`. Nothing renders below 12 sp (canvas 9–11 px badges become `type.caption`). Side gutter `layout.gutter` (16; onboarding pages use `space.7` = 24). Tablet: the content column is `layout.maxContentWidth` (600) centred, long text is capped at `layout.readingMaxWidth`. Controls drawn at 40–44 px keep their look but get a ≥ `size.touchTarget.min` (48) hit area. Colours are tokens only (`color.*`, names in 01 §14.1). Every ★ state is a golden in light + dark at phone and tablet width (01 §8.3, RC24). *Derived* means that no artboard exists: Phase 16/17 builds the state from the designed states, the tokens and the shared state widgets (01 §8.2), and REVIEW.md checks it.
