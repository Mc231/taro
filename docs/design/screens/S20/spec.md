# S20 · Settings ("Settings" tab)

| | |
|---|---|
| Route | `/settings` (tab 4 of 4) |
| Banner | none (S20 is not in `kBannerAllowList`) |
| Artboards | [`../Settings.dc.html`](../Settings.dc.html) |
| Frames | [`Settings.png`](../frames/Settings.png) (PNG @2x, from the artboards above) |
| Next | S11, S21, S22, S23, S24, S25, S26, S27, S28, S29, S04 (AI readings row) |

## Layout (top → bottom)
Scroll padding `space.11` / `layout.gutter` / `space.7`; section gap `space.7`. Tab bar at the bottom (Settings active), with no banner above it.
Each section: an h2 `type.caption` `color.text.tertiary` (padding 0 `space.2`) above a group (`color.bg.surface`, `radius.lg`) of `SettingsTile` rows (min 52; 60 with a subtitle; padding 0 `space.5`; `color.border.subtle` dividers). A value sits at the end in `type.label` `color.text.secondary`, followed by a chevron. Switches: a 44 × 26 track in a 60 × 48 hit area (on: `color.accent.primary`, knob `color.text.onAccent`; off: `color.bg.sunken`, knob `color.text.secondary`).
1. Title "Settings" serif 28.
2. **Readings**: the balance row (dot `color.card.frame`, "3 readings · 1 free today" / "Get more readings" → S11); "Restore purchases" (button row); "Remove Banner Ads" + the price → S11 (RC80 name; **resolved**, the canvas wrote "Remove banner ads").
3. **Experience**: Language (English) → S21; Daily reminder (8:00 PM) → S22; Reversed cards switch ("Cards can land upside down"); Haptics switch; Theme (System) → a `TaroSheet` with System / Light / Dark radios.
4. **Privacy & data**: AI readings (Allowed) → S23 AI section / S04; Privacy choices → S23; Export backup → S24; Import backup → S25; Delete all data → S26.
5. **Help**: Help & FAQ → S28; Support lines ("People you can talk to, wherever you are") → S27; "Move readings from another device" (subtitle "Get a transfer code to send to support"; shows the transfer code after a purchase re-check, 03 §6.6, RC84; min 60); Legal ("Terms, privacy, licences") → S29; "Rate Taro" (external-link glyph; opens the store review sheet). **Resolved**: both 01 §7.10 Help items are drawn on `Settings.dc.html`, and the Legal subtitle uses the canvas-wide British "licences". Contact support lives on S28, whose restore-purchases FAQ answer links to the transfer row.
6. **About**: "Taro 1.0.0 (12)" + "Support ID 3f9a1c07" with a "Copy ID" pill (44 → 48 hit); caption "Share the Support ID if you contact us. It doesn't identify you."

The groups differ from 01 §7.10 (Readings+Purchases → Readings; Appearance+Daily card → Experience). This is accepted as a layout choice; every item in 01 §7.10 must still appear somewhere (the usage analytics toggle and ad privacy choices are on S23).

## Components
`TaroScaffold` (tabs), `SettingsTile`, switch, `TaroSheet`, `TaroInlineNotice`, snackbar, `BalanceChip` data (row form).

## States (01 §8.3)
| State | ★ | Source |
|---|---|---|
| `content` | ★ | **Designed**: `Settings.dc.html` |
| `adsRemoved` | | Derived: the row reads "Banner ads removed ✓", with no price, not tappable |
| `restoreInProgress` | | Derived: a spinner at the end of the Restore row; the row disabled |
| `restoreSuccess(nothingFound)` | | Derived: snackbar "No purchases to restore. Reading packs are tied to this app installation and can't be restored." (04 §7) |
| `restoreSuccess(removeAdsRestored)` | | Derived: snackbar "Remove Banner Ads restored"; the row becomes `adsRemoved` |
| `restoreFailed` | | Derived: `TaroInlineNotice(error)` under the Readings group + Retry |

## Motion
Switch thumb `motion.duration.fast`; row press overlay; snackbar `motion.duration.base`. Reduced: instant switch.

## Semantics / reading order
Title (header) → each section heading (header) → rows in order. Switches are `role=switch` with their label and subtitle ("Reversed cards, Cards can land upside down, on"). Value rows read "Language, English, button". Copy ID reads "Copy Support ID 3f9a1c07". Restore results are announced politely.

## RTL
Values and chevrons mirror (the chevron points left); switch tracks mirror (on = knob on the left).

## Banner
None.

---

**Conventions (same in every S-spec).** Canvas px = dp/sp. Spacing 2/4/8/12/16/20/24/32/40/48/56/64 = `space.1`…`space.12`; odd canvas values (6, 10, 14, 18, 28) snap to the nearest token. Radius: 4 `radius.xs`, 8 `radius.sm`, 10 `radius.card`, 12 `radius.md`, 16 `radius.lg`, 24 `radius.xl`, 28 `radius.sheet`, 999 `radius.full`. Type: serif 40 `type.display`; serif 28 `type.headline`; serif 20–24 `type.cardName`; serif 16–18 paragraphs `type.bodyReading`; sans 20/600 `type.title`; sans 17–18/600 `type.titleSmall`; sans 16 `type.body`; sans 14–15/500 `type.label`; sans 12–13 `type.caption`; numerals `type.numeral`. Nothing renders below 12 sp (canvas 9–11 px badges become `type.caption`). Side gutter `layout.gutter` (16; onboarding pages use `space.7` = 24). Tablet: the content column is `layout.maxContentWidth` (600) centred, long text is capped at `layout.readingMaxWidth`. Controls drawn at 40–44 px keep their look but get a ≥ `size.touchTarget.min` (48) hit area. Colours are tokens only (`color.*`, names in 01 §14.1). Every ★ state is a golden in light + dark at phone and tablet width (01 §8.3, RC24). *Derived* means that no artboard exists: Phase 16/17 builds the state from the designed states, the tokens and the shared state widgets (01 §8.2), and REVIEW.md checks it.
