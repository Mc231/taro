# S15 · Journal entry detail + note editor

| | |
|---|---|
| Route | `/journal/:id` (deep link `taro://journal/{id}`) |
| Banner | none |
| Artboards | [`../JournalEntry.dc.html`](../JournalEntry.dc.html) (an AI reading entry with a note) |
| Frames | [`JournalEntry.png`](../frames/JournalEntry.png) (PNG @2x, from the artboards above) |
| Next | "Full reading" → the full renderer (S09 styles; S32 for `classic`) · More → Report (S33, AI entries only) · Delete → confirm → pop + Undo |

## Layout (top → bottom)
Padding `space.10` / `layout.gutter` / `space.7`; gap `space.4` (canvas 14).
1. Top bar: Back at the start; at the end, the Favourite toggle `TaroIconButton` (pressed state) + the text action **Share** + a More `TaroIconButton` (overflow: "Report this reading", AI entries only). **Resolved** on `JournalEntry.dc.html`: "Export" is now "Share" (01 §7.4 has no per-entry export), and the More button (→ S33) is drawn.
2. Meta `type.caption` `color.text.tertiary`: "Friday, 26 September 2026 · 21:40 · Past · Present · Future".
3. Mini spread: `TaroCardFace` 68 × 116 (`size.card.sm`), labels `type.caption` 12; reversed = rotation + badge.
4. Question in quotes `type.caption`; title serif 24 `type.cardName`; summary serif 18 `type.bodyReading`.
5. The `aiLabel` "AI-generated" `Badge` in the header (next to the question) and the footer row `disclaimerShort` ("For entertainment and self-reflection. Not professional advice.", ARB) with the "Full reading" link at the end. **Resolved** on `JournalEntry.dc.html` (rule: header badge `aiLabel` + footer `disclaimerShort`, 05 §3). 01 §7.8 says the entry detail *is* the full reading. The canvas shows a condensed view plus a link; either is fine if the link expands in place and the disclaimer stays visible.
6. Note: label `type.caption` "Your note"; `TaroTextField` multiline, serif 17 `type.bodyReading`, `color.bg.sunken`, `radius.md`, padding `space.4` / 14, ≤ 5,000 chars; the autosave caption "Saved on this device".
7. Flexible spacer.
8. "Delete entry" `TaroButton.tertiary` in `color.status.error` text.

Daily-card entries use the same page with one card, the short meaning and the reflection question instead of the AI text.

## Components
`ReadingTextView`, `TaroCardFace`, `Badge`, `DisclaimerFooter`, `TaroTextField`, `TaroIconButton`, `TaroButton`, `TaroDialog`, snackbar.

## States (01 §8.3)
| State | ★ | Source |
|---|---|---|
| `content` | | **Designed**: `JournalEntry.dc.html` |
| `pending` | | Derived: the cards face-down; `TaroInlineNotice(info)` "This reading isn't finished yet"; `TaroButton.primary` "Finish reading" → S08 `awaitingReading` |
| `failed` | | Derived: `TaroInlineNotice(error)` "We couldn't create this reading. You weren't charged." + "Try again" (same cards) |
| `deleted` | | Derived: confirm `TaroDialog` ("Delete this entry?" [Delete] [Cancel]) → pop to S14 + an Undo snackbar for 5 s |
| classic entry | | Derived: the "Classic reading" `Badge` instead of the AI label; no Report |

## Motion
Push `motion.duration.base`; the autosave caption fades in over `motion.duration.fast`. Reduced: fades.

## Semantics / reading order
Back → Favourite (toggle, "favourite, on") → Share → More → date/meta → cards ("Three of Cups, position: Past"…) → question → title (header) → summary → AI label + disclaimer → Full reading → "Your note" field (announces "Saved on this device" politely) → Delete entry.

## RTL
Mirrored bar and card row; the note field direction follows its content.

## Banner
None (04 §8 excludes the journal entry).

---

**Conventions (same in every S-spec).** Canvas px = dp/sp. Spacing 2/4/8/12/16/20/24/32/40/48/56/64 = `space.1`…`space.12`; odd canvas values (6, 10, 14, 18, 28) snap to the nearest token. Radius: 4 `radius.xs`, 8 `radius.sm`, 10 `radius.card`, 12 `radius.md`, 16 `radius.lg`, 24 `radius.xl`, 28 `radius.sheet`, 999 `radius.full`. Type: serif 40 `type.display`; serif 28 `type.headline`; serif 20–24 `type.cardName`; serif 16–18 paragraphs `type.bodyReading`; sans 20/600 `type.title`; sans 17–18/600 `type.titleSmall`; sans 16 `type.body`; sans 14–15/500 `type.label`; sans 12–13 `type.caption`; numerals `type.numeral`. Nothing renders below 12 sp (canvas 9–11 px badges become `type.caption`). Side gutter `layout.gutter` (16; onboarding pages use `space.7` = 24). Tablet: the content column is `layout.maxContentWidth` (600) centred, long text is capped at `layout.readingMaxWidth`. Controls drawn at 40–44 px keep their look but get a ≥ `size.touchTarget.min` (48) hit area. Colours are tokens only (`color.*`, names in 01 §14.1). Every ★ state is a golden in light + dark at phone and tablet width (01 §8.3, RC24). *Derived* means that no artboard exists: Phase 16/17 builds the state from the designed states, the tokens and the shared state widgets (01 §8.2), and REVIEW.md checks it.
