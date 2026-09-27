# S29 · Legal (disclaimer / terms / privacy / licences)

| | |
|---|---|
| Route | `/legal/:doc` (`disclaimer` \| `terms` \| `privacy` \| `licenses`) |
| Banner | none |
| Artboards | [`../Legal.dc.html`](../Legal.dc.html) (the `disclaimer` tab) |
| Frames | [`Legal.png`](../frames/Legal.png) (PNG @2x, from the artboards above) |

## Layout (top → bottom)
Padding `space.10` / `layout.gutter` / 28; gap `space.5`.
1. Back; title "Legal" serif 28.
2. Tabs (`role=tablist`, gap `space.3`): Disclaimer / Terms of use / Privacy policy / Open-source licences. Pill tabs 44 → 48 hit, `radius.full`; the selected one has `color.accent.subtle` + a `color.accent.primary` border. At +40% the row scrolls horizontally. The tab maps to `:doc`.
3. Article panel (`color.bg.surface`, `radius.lg`, padding `space.6` / 18): h2 serif 22 `type.cardName` "Tarot for reflection" (= `disclaimerOnboardingTitle`); version caption "v1 · effective 1 October 2026"; paragraphs serif 16 `type.bodyReading` (first paragraph = `disclaimerOnboardingBody`, 05 §3), with an inline "a support line" link → S27. The text is capped at `layout.readingMaxWidth`.
4. Footer caption: "Terms and privacy policy are also at taro.vshyrochuk.com".

Terms and Privacy render the 05 URLs in an in-app webview/browser (01 §7.10). The licences page uses the Flutter license registry, styled with these tokens.
**Spelling (resolved):** the canvas is British English throughout ("Favourites", "personalisation", "licences"); the S20 row now reads "Terms, privacy, licences", matching this tab. The en ARB uses "licences" everywhere. The route segment `licenses` is a code identifier and stays as is. 01 §7.10 still writes "Open-source licenses"; the UI copy follows the canvas.

## Components
Tabs (`SegmentedChoice` in tab mode), `ReadingTextView` (article), in-app browser, license list.

## States (01 §8.3)
| State | ★ | Source |
|---|---|---|
| `content` (disclaimer) | | **Designed**: `Legal.dc.html` |
| terms / privacy | | Derived: the tab selected → webview with a `TaroLoadingView`; offline → `TaroErrorView(network)` + a link to open in the browser |
| licences | | Derived: a package list → a licence text page |

## Motion
Tab change cross-fades the panel over `motion.duration.fast`; reduced: instant.

## Semantics / reading order
Back → title → the tablist (selected tab announced) → the tab panel: heading (header) → version → paragraphs → support line link → footer.

## RTL
Tabs run from the right; the article is right-aligned; the URL is bidi-isolated.

## Banner
None.

---

**Conventions (same in every S-spec).** Canvas px = dp/sp. Spacing 2/4/8/12/16/20/24/32/40/48/56/64 = `space.1`…`space.12`; odd canvas values (6, 10, 14, 18, 28) snap to the nearest token. Radius: 4 `radius.xs`, 8 `radius.sm`, 10 `radius.card`, 12 `radius.md`, 16 `radius.lg`, 24 `radius.xl`, 28 `radius.sheet`, 999 `radius.full`. Type: serif 40 `type.display`; serif 28 `type.headline`; serif 20–24 `type.cardName`; serif 16–18 paragraphs `type.bodyReading`; sans 20/600 `type.title`; sans 17–18/600 `type.titleSmall`; sans 16 `type.body`; sans 14–15/500 `type.label`; sans 12–13 `type.caption`; numerals `type.numeral`. Nothing renders below 12 sp (canvas 9–11 px badges become `type.caption`). Side gutter `layout.gutter` (16; onboarding pages use `space.7` = 24). Tablet: the content column is `layout.maxContentWidth` (600) centred, long text is capped at `layout.readingMaxWidth`. Controls drawn at 40–44 px keep their look but get a ≥ `size.touchTarget.min` (48) hit area. Colours are tokens only (`color.*`, names in 01 §14.1). Every ★ state is a golden in light + dark at phone and tablet width (01 §8.3, RC24). *Derived* means that no artboard exists: Phase 16/17 builds the state from the designed states, the tokens and the shared state widgets (01 §8.2), and REVIEW.md checks it.
