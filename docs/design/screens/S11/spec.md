# S11 · Store / paywall

| | |
|---|---|
| Route | `/store` |
| Banner | none |
| Artboards | [`../Store.dc.html`](../Store.dc.html) (`content`) · [`../StoreLoading.dc.html`](../StoreLoading.dc.html) (`loading`) |
| Frames | [`Store.png`](../frames/Store.png) · [`StoreLoading.png`](../frames/StoreLoading.png) (PNG @2x, from the artboards above) |
| Entry | S10 "Get more readings", the Home balance chip, Settings (S20); never during onboarding |

## Layout (top → bottom)
Padding `space.10` / `layout.gutter` / `space.7`; gap `space.5` (tightened from 20 to fit the rewarded row and the two footer lines at 844).
1. Top bar: Close `TaroIconButton` (X, works immediately, no delay) at the start; `BalanceChip` ("0 readings") at the end.
2. Title "More readings" serif 28 `type.headline`; body `type.label` `color.text.secondary`: "One reading is one spread of any size. Readings don't expire, and your free daily reading continues."
3. Pack rows, gap `space.4`: each `color.bg.surface`, `radius.lg`, padding `space.5` / 18. At the start: the title `type.titleSmall` "10 readings" + per-reading price `type.caption` ("$0.50 per reading"); an optional `Badge` "Best value" (`color.accent.subtle`, `type.caption`) + a 1.5 px `color.accent.primary` outline on that row. At the end: a buy `TaroButton.primary` showing the store price (44 visual / 48 hit, `radius.md`). Each pack is its own button; there is no preselection and no "Continue" button.
4. Rewarded row (the S11 rewarded entry point, RC34) → S12: icon tile + "Watch an ad for 1 reading" (04 §9.1) + meta "Optional · 3 left today"; same rules and disabled reasons as S10, shown only when `free.remaining == 0`. **Resolved**: drawn on `Store.dc.html` under the packs.
5. (The divider between packs and Remove Banner Ads was dropped; the section gap separates them.)
6. The Remove Banner Ads row: title **"Remove Banner Ads"** (RC80 display name; **resolved** on the canvas, which wrote "Remove banner ads"), body "One-time purchase. Optional reward videos stay available.", outlined price button.
7. Flexible spacer.
8. Footer links (44 → 48 hit): Restore purchases · Terms · Privacy.
9. Under the links, centred `type.caption` (12) `color.text.tertiary`: the consumable disclosure "Readings don't expire and are kept for this app installation. They can't be restored with Restore Purchases." (04 §11, verbatim), then `disclaimerShort` "For entertainment and self-reflection. Not professional advice." (05 §3, paywall footer). **Resolved**: both drawn on `Store.dc.html`.

**Best value (resolved):** the canvas had "Best value" on the 10-pack ($0.50/reading), but the 30-pack is cheaper ($0.33). `Store.dc.html` now puts the badge on the 30-pack. The badge goes only on the pack with the lowest **computed** per-reading price, and only when `store.showBestValueBadge` is true (04 §11, MO18); code computes it from `ProductDetails`, never from position.

## Components
`TaroAppBar`, `BalanceChip`, pack row (**new**: `PackRow`; add to `components.md`), `Badge`, `TaroButton` (loading), `SkeletonBlock`, `TaroErrorView`, `TaroInlineNotice`, toast/snackbar.

## States (01 §8.3, 04 §11)
| State | ★ | Source |
|---|---|---|
| `loading` | ★ | **Designed**: `StoreLoading.dc.html` (3 pack-row `SkeletonBlock`s + a Remove Banner Ads skeleton; the header, close, footer links, disclosure and `disclaimerShort` render immediately) |
| `content` | ★ | **Designed**: `Store.dc.html` (badge on the 30-pack, rewarded row, disclosure and disclaimer drawn) |
| `storeUnavailable` | | Derived: `TaroErrorView` "Purchases aren't available on this device" + Retry; the free path and restore stay |
| `purchasing(productId)` | | Derived: a spinner on that buy button; the other buttons stay enabled |
| `pending` | | Derived: under that pack, `TaroInlineNotice(info)` "Waiting for approval" |
| `verifying` | | Derived: `TaroInlineNotice` with a progress indicator "Confirming your purchase…"; close still works |
| `success` | | Derived: the balance chip counts up + toast "+10 readings"; when opened from S10, it returns to S07 with Begin enabled (no auto-start) |
| `failed(kind)` | | Derived: inline error under the pack + Retry |
| `cancelled` | | No UI (silent return) |
| `verificationDelayed` | | Derived: `TaroInlineNotice(warning)` "Your purchase is safe. We'll add your readings when you're back online." |
| `removeAdsOwned` | | Derived: the row shows "Banner ads removed ✓", no button |
| rewarded offer | | **Designed** (available): the rewarded row on `Store.dc.html`; cooling-down / capped / no-fill variants derived from S10 |
| `purchasesBlocked(blocked \| refundDebt)` / `storeDisabled` | | Derived: the pack buttons are hidden; a neutral line + support contact; free, rewarded and restore stay |

## Motion
Balance count-up `motion.duration.base`; button spinner; toast in/out `motion.duration.base`. Reduced: instant value, fades. No timers, pulses or attention-seeking motion on packs (05 §9.5).

## Semantics / reading order
Close → balance → title → body → each pack as one button ("10 readings for 4.99 US dollars, 50 cents per reading, best value") → rewarded → Remove Banner Ads → Restore / Terms / Privacy → disclosure + disclaimer. Purchase results are announced through a live region.

## RTL
Price buttons on the left; prices come from the store as localized strings (never reformatted).

## Banner
None.

---

**Conventions (same in every S-spec).** Canvas px = dp/sp. Spacing 2/4/8/12/16/20/24/32/40/48/56/64 = `space.1`…`space.12`; odd canvas values (6, 10, 14, 18, 28) snap to the nearest token. Radius: 4 `radius.xs`, 8 `radius.sm`, 10 `radius.card`, 12 `radius.md`, 16 `radius.lg`, 24 `radius.xl`, 28 `radius.sheet`, 999 `radius.full`. Type: serif 40 `type.display`; serif 28 `type.headline`; serif 20–24 `type.cardName`; serif 16–18 paragraphs `type.bodyReading`; sans 20/600 `type.title`; sans 17–18/600 `type.titleSmall`; sans 16 `type.body`; sans 14–15/500 `type.label`; sans 12–13 `type.caption`; numerals `type.numeral`. Nothing renders below 12 sp (canvas 9–11 px badges become `type.caption`). Side gutter `layout.gutter` (16; onboarding pages use `space.7` = 24). Tablet: the content column is `layout.maxContentWidth` (600) centred, long text is capped at `layout.readingMaxWidth`. Controls drawn at 40–44 px keep their look but get a ≥ `size.touchTarget.min` (48) hit area. Colours are tokens only (`color.*`, names in 01 §14.1). Every ★ state is a golden in light + dark at phone and tablet width (01 §8.3, RC24). *Derived* means that no artboard exists: Phase 16/17 builds the state from the designed states, the tokens and the shared state widgets (01 §8.2), and REVIEW.md checks it.
