# S28 · FAQ / Help

| | |
|---|---|
| Route | `/help` |
| Banner | none |
| Artboards | [`../Help.dc.html`](../Help.dc.html) |
| Frames | [`Help.png`](../frames/Help.png) (PNG @2x, from the artboards above) |
| Next | Support lines → S27 · Email support → mailto |

## Layout (top → bottom)
Padding `space.10` / `layout.gutter` / 28; gap `space.5`.
1. Back; title "Help & FAQ" serif 28.
2. Search: `TaroTextField` (search), 48, `color.bg.sunken`, `radius.md`, placeholder "Search help" (visually hidden label).
3. "Common questions" (h2 caption): an accordion in `color.bg.surface` `radius.lg`. Items are buttons (min 48, 56 when expanded; `type.body` question + a chevron that rotates) with `color.border.subtle` dividers; the answer `type.label` `color.text.secondary`, padding 0 `space.5` `space.4`. Items: free reading reset, how readings work, what Reversed means, is my journal private, restoring purchases (it must say reading packs are tied to this installation, 04 §7), why a question was declined. The canvas shows "How do I restore purchases?" expanded: "Restore purchases brings back Remove Banner Ads. Reading packs stay with this app installation. On a new phone, get a transfer code and support can move them for you." + a text link "Move readings from another device" (44 → 48 hit). The former "How do I contact support?" item was removed from the canvas: it repeated the Contact support card right below, and the 1040 frame had no room for the new link. The content is authored offline (`source/{locale}/articles`).
4. The "Support lines" row (min 64, heart icon, subtitle "People you can talk to, wherever you are") → S27.
5. "Contact support" (h2): a card with "Email" + the address (`supportEmail` from `FlavorConfig`), "Support ID" + "3f9a1c07" + a "Copy ID" pill, and `TaroButton.primary` "Email support" (mailto; the subject includes the Support ID; the body includes app version, OS and locale).
6. "Move readings from another device" (01 §7.10 Help, RC84): **resolved**. The row lives on S20 (where 01 §7.10 places it, next to "Rate Taro"); S28 links to the same flow from the restore-purchases FAQ answer (above), so it exists in one place. "Rate Taro" is only on S20, as in 01 §7.10.

## Components
`TaroTextField`, accordion item (**new**: `FaqItem`), `SettingsTile`, `TaroButton`.

## States (01 §8.3)
| State | ★ | Source |
|---|---|---|
| `content` | | **Designed**: `Help.dc.html` |
| search no results | | Derived: `TaroEmptyView` (search illustration) "No answers match “…”" + "Email support" |

## Motion
Accordion expand/collapse `motion.duration.base`, `motion.easing.standard`; the chevron rotates over `motion.duration.fast`. Reduced: instant.

## Semantics / reading order
Back → title → search → "Common questions" (header) → each question button (expanded/collapsed state) → its answer region when expanded (with "Move readings from another device") → Support lines → "Contact support" (header) → email → Support ID + Copy → Email support.

## RTL
Mirrored; the chevron stays a down/up chevron (not direction-bound); the email address and Support ID are bidi-isolated LTR.

## Banner
None.

---

**Conventions (same in every S-spec).** Canvas px = dp/sp. Spacing 2/4/8/12/16/20/24/32/40/48/56/64 = `space.1`…`space.12`; odd canvas values (6, 10, 14, 18, 28) snap to the nearest token. Radius: 4 `radius.xs`, 8 `radius.sm`, 10 `radius.card`, 12 `radius.md`, 16 `radius.lg`, 24 `radius.xl`, 28 `radius.sheet`, 999 `radius.full`. Type: serif 40 `type.display`; serif 28 `type.headline`; serif 20–24 `type.cardName`; serif 16–18 paragraphs `type.bodyReading`; sans 20/600 `type.title`; sans 17–18/600 `type.titleSmall`; sans 16 `type.body`; sans 14–15/500 `type.label`; sans 12–13 `type.caption`; numerals `type.numeral`. Nothing renders below 12 sp (canvas 9–11 px badges become `type.caption`). Side gutter `layout.gutter` (16; onboarding pages use `space.7` = 24). Tablet: the content column is `layout.maxContentWidth` (600) centred, long text is capped at `layout.readingMaxWidth`. Controls drawn at 40–44 px keep their look but get a ≥ `size.touchTarget.min` (48) hit area. Colours are tokens only (`color.*`, names in 01 §14.1). Every ★ state is a golden in light + dark at phone and tablet width (01 §8.3, RC24). *Derived* means that no artboard exists: Phase 16/17 builds the state from the designed states, the tokens and the shared state widgets (01 §8.2), and REVIEW.md checks it.
