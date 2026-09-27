# S05 · Home ("Today" tab)

| | |
|---|---|
| Route | `/home` (tab 1 of 4) |
| Banner | ✅ `home` (allowed) |
| Artboards | [`../Today.dc.html`](../Today.dc.html) (dark, en) · [`../TodayLight.dc.html`](../TodayLight.dc.html) · [`../TodayAr.dc.html`](../TodayAr.dc.html) (ar, RTL) · [`../TodayTablet.dc.html`](../TodayTablet.dc.html) (iPad 13") · [`../TodayLargeText.dc.html`](../TodayLargeText.dc.html) (200% text) · [`../TodayFirstRun.dc.html`](../TodayFirstRun.dc.html) (`firstRun` coachmark) · [`../ScreenshotFrame.dc.html`](../ScreenshotFrame.dc.html) (store screenshot template; Phase 20) |
| Frames | [`Today.png`](../frames/Today.png) · [`TodayLight.png`](../frames/TodayLight.png) · [`TodayAr.png`](../frames/TodayAr.png) · [`TodayTablet.png`](../frames/TodayTablet.png) · [`TodayLargeText.png`](../frames/TodayLargeText.png) · [`TodayFirstRun.png`](../frames/TodayFirstRun.png) · [`ScreenshotFrame.png`](../frames/ScreenshotFrame.png) (PNG @2x, from the artboards above) |
| Links | Balance chip → S10 · "Reveal card" → S13 · "Start a reading" → S06 · Recent row → S15 (**resolved**: the Recent row in `Today`, `TodayLight`, `TodayTablet` and `TodayLargeText` now links to `JournalEntry.dc.html`, per the nav map in 01 §9.1; `TodayAr` still links to `ReadingAr.dc.html` because there is no ar S15 artboard, and code routes it to S15 like the others) |

## Layout (top → bottom)
Scroll area: padding `space.11` top, `layout.gutter` sides, `space.5` bottom; section gap `space.7`.
1. **Header row** (space-between, gap `space.4`): the date (`type.caption`, `color.text.tertiary`, `DateFormat` MMMMEEEEd per locale) above the greeting (serif 28 `type.headline`; morning/afternoon/evening from local time). `BalanceChip` sits at the end: `radius.full`, `color.accent.subtle`, 40 visual / 48 hit, 8 px dot in `color.card.frame`, `type.label` ("1 free reading").
2. **Daily card tile**: `color.bg.surface`, `radius.lg`, padding `space.5`, gap `space.5`. `TaroCardBack` 88 × 152 (`radius.card`, `elevation.2`), then a text column (gap `space.3`): the overline "YOUR DAILY CARD" (`type.caption`, `color.card.frame`, letter-spaced), the title serif 20 `type.cardName`, "Free, works offline, no AI." (`type.caption`/14, `color.text.secondary`) and the text button "Reveal card".
3. **Reading CTA card** (the whole card is tappable): `color.bg.surfaceRaised`, `radius.lg`, padding `space.6`, gap `space.4`. "Ask the cards a question" serif 22 `type.cardName`; body 15 `color.text.secondary`; `TaroButton.primary` "Start a reading" (48, `radius.md`, start-aligned).
4. **Recent**: "Recent" `type.titleSmall`; rows (gap `space.3`), each `color.bg.surface`, `radius.md`, padding `space.4`: up to 3 card thumbs 24 × 41 (`radius.xs`, 1.5 px `color.card.frame` border), then the title `type.label`/600 and meta `type.caption` ("Past · Present · Future · Yesterday").
5. `space.adGap` (16) → **`BannerSlot`** 56 high (adaptive anchored banner; 90 on tablet), `color.ad.container`, full width → `space.adGap` (16).
6. **Tab bar**: 64 + safe area, top border `color.border.subtle`, 4 items (icon `size.icon.md` + label 12/500 `type.caption`). Active `color.accent.primary`, inactive `color.text.tertiary`.

**Tablet** (`TodayTablet`): the same column, centred at `layout.maxContentWidth`, with 64 top padding; the banner and tab bar span the full width. No second column in v1.
**Light** (`TodayLight`): identical layout; only the tokens change.

## Components
`TaroScaffold` (tab shell), `BalanceChip`, `TaroCardBack`, `TaroCardFace` (drawn state), `TaroButton`, recent-reading row (`JournalRow`, shared with S14; add to `components.md`), `BannerSlot`, `TaroInlineNotice`, `TaroOfflineBanner`, `SkeletonBlock`, coachmark (**new**, not in 02 §14.3; add to `components.md` and the Phase 15 list).

## States (01 §8.3)
| State | ★ | Source |
|---|---|---|
| `loading` | | Derived: `SkeletonBlock`s in the shape of the chip, tile, CTA and two recent rows (`color.skeleton.*`) |
| `content`: free reading available | ★ | **Designed**: `Today` / `TodayLight` / `TodayAr` / `TodayTablet` |
| `content`: free used + credits | ★ | Derived: chip text "Free reading used · 3 readings", dot in `color.border.strong` (this chip variant is drawn in the background of `Rewarded.dc.html`) |
| `content`: zero readings | ★ | Derived: chip "Free reading used" + `CountdownText` "Next free in 5 h 12 min" (the real reset instant, not a fake timer) |
| `firstRun` (coachmark) | | **Designed**: `TodayFirstRun.dc.html`: a coachmark bubble (`color.bg.surfaceRaised`, `radius.md`, `elevation.3`) pointing at "Start a reading", dismissed on tap. There is no banner in first run (`ads.bannerMinCompletedReadings` = 1) |
| `balanceStale` | | Derived: the chip shows the last-known value + an offline glyph; `TaroOfflineBanner` at the top. On a first launch while offline, the note is "Connect to start AI readings" |
| `deviceUnverified` | | Derived: the chip is replaced by `TaroInlineNotice(warning)` "Readings unavailable on this device" + Retry |
| `dailyCardNotDrawn` | | **Designed** (the tile in `Today`) |
| `dailyCardDrawn` | | Derived: the tile shows `TaroCardFace` (card art, rotated 180° + a "Reversed" label if reversed), the card name as the title, and "Open" → S13 |
| `bannerLoaded` | | **Designed** (a placeholder "Banner ad" box; the real creative keeps its own "Ad" label) |
| `bannerFailed` | | Derived: the slot **and both `space.adGap` spacers** collapse to 0, with no empty box |
| `adsRemoved` | | Derived: same as `bannerFailed`, permanently |
| `updateAvailable` | | Derived: dismissible `TaroInlineNotice(info)` above the daily card tile ("A new version of Taro is available" + Update), at most once per version (RC73) |

## Motion
Chip `syncing`: shimmer between `color.skeleton.base` and `color.skeleton.highlight`, a `motion.duration.slow` loop. A balance change counts up over `motion.duration.base`. Tab switch: cross-fade `motion.duration.fast`. The coachmark fades in over `motion.duration.base`. Reduced motion: no shimmer (static skeleton), instant number swap, fades only.

## Semantics / reading order
Date + greeting (one header node) → balance chip ("1 free reading today, button, shows reading options"; a polite live region announces balance changes) → daily card tile as one node ("Your daily card, not revealed yet") + the "Reveal card" button → "Ask the cards a question" (header) + "Start a reading" → "Recent" (header) → each row ("A season of rebuilding, Past, Present, Future, yesterday") → banner (announced as an advertisement, after all content) → tab bar (selected state on Today).

## RTL (`TodayAr`)
The chip moves to the left; text is right-aligned. The date uses Arabic-Indic numerals per `intl` ("السبت، ٢٧ سبتمبر"). The card back is not mirrored. The tab order is mirrored (Today on the right). Thumbs in recent rows run right to left. The ad label follows the creative, not the app direction.

## Text scale ([`TodayLargeText`](../TodayLargeText.dc.html))
200% (Android) / AX5 (iOS): the chip wraps below the greeting; the daily card tile stacks the card above its text; the CTA button stretches to full width; nothing truncates. Golden required (Phase 14 REVIEW).

## Banner
Allowed here only as the bottom slot, below the scroll view and above the tab bar, in its own `color.ad.container`, with ≥ `space.adGap` (16 dp) to any tap target (RC18, RC59). Never over content. Hidden while S10/S12 are shown. Store screenshots (`ScreenshotFrame`) are captured in the `adsRemoved` state, because ads and prices are forbidden in screenshot frames (05).

---

**Conventions (same in every S-spec).** Canvas px = dp/sp. Spacing 2/4/8/12/16/20/24/32/40/48/56/64 = `space.1`…`space.12`; odd canvas values (6, 10, 14, 18, 28) snap to the nearest token. Radius: 4 `radius.xs`, 8 `radius.sm`, 10 `radius.card`, 12 `radius.md`, 16 `radius.lg`, 24 `radius.xl`, 28 `radius.sheet`, 999 `radius.full`. Type: serif 40 `type.display`; serif 28 `type.headline`; serif 20–24 `type.cardName`; serif 16–18 paragraphs `type.bodyReading`; sans 20/600 `type.title`; sans 17–18/600 `type.titleSmall`; sans 16 `type.body`; sans 14–15/500 `type.label`; sans 12–13 `type.caption`; numerals `type.numeral`. Nothing renders below 12 sp (canvas 9–11 px badges become `type.caption`). Side gutter `layout.gutter` (16; onboarding pages use `space.7` = 24). Tablet: the content column is `layout.maxContentWidth` (600) centred, long text is capped at `layout.readingMaxWidth`. Controls drawn at 40–44 px keep their look but get a ≥ `size.touchTarget.min` (48) hit area. Colours are tokens only (`color.*`, names in 01 §14.1). Every ★ state is a golden in light + dark at phone and tablet width (01 §8.3, RC24). *Derived* means that no artboard exists: Phase 16/17 builds the state from the designed states, the tokens and the shared state widgets (01 §8.2), and REVIEW.md checks it.
