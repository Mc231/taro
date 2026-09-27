# S01 · Launch / bootstrap

| | |
|---|---|
| Route | `/` (native splash → Flutter bootstrap) |
| Banner | none (not in `kBannerAllowList`) |
| Artboards | [`../Launch.dc.html`](../Launch.dc.html) (bootstrap frame); card mark from [`../CardBack.dc.html`](../CardBack.dc.html) |
| Frames | [`Launch.png`](../frames/Launch.png) · [`CardBack.png`](../frames/CardBack.png) (PNG @2x, from the artboards above) |
| Next | S30 if `app.minVersion` is not met → S02 if onboarding is incomplete → S05 |

## Layout (top → bottom)
Full-bleed `color.bg.canvas`, one centred column, `space.8` gap (canvas 28), bottom padding `space.9`:
1. Card mark: `TaroCardBack` 96 × 164 (`size.card.md` at `size.card.aspectRatio`), `radius.card`, `elevation.3`, ochre frame and star (`color.card.frame`).
2. Wordmark "Taro": serif 44 on the canvas → `type.display`.

The native splash (iOS LaunchScreen, Android 12 splash API) uses the same `color.bg.canvas` and the card mark only, so the hand-off to the Flutter frame does not jump. Light mode uses the light `bg.canvas`.

## Components
`TaroCardBack`, `TaroErrorView(kind: storage)`.

## States (01 §8.3)
| State | ★ | Source |
|---|---|---|
| `bootstrapping` | | **Designed**: `Launch.dc.html` |
| `storageError` (fatal, "Contact support" action) | | Derived: `TaroErrorView(storage)` centred on the same canvas; the only action is "Contact support" (mailto with app version, OS, locale, Support ID); no Retry loop |
| → `updateRequired` redirect | | Route to S30 (designed there) |
| → onboarding or home | | Route to S02 / S05 |

## Motion
Hand-off to the first route: cross-fade `motion.duration.base` with `motion.easing.standard`. Reduced motion: an instant swap. No looping animation on the splash.

## Semantics / reading order
The whole frame is one node labelled "Taro" (the canvas uses `role="img"`). Nothing else is announced while bootstrapping. In `storageError`, focus moves to the error title, then the body, then "Contact support".

## RTL
Symmetric; nothing to mirror. The card art is never mirrored.

## Banner
None. Ads SDK is not initialised before UMP (S04 flow).

---

**Conventions (same in every S-spec).** Canvas px = dp/sp. Spacing 2/4/8/12/16/20/24/32/40/48/56/64 = `space.1`…`space.12`; odd canvas values (6, 10, 14, 18, 28) snap to the nearest token. Radius: 4 `radius.xs`, 8 `radius.sm`, 10 `radius.card`, 12 `radius.md`, 16 `radius.lg`, 24 `radius.xl`, 28 `radius.sheet`, 999 `radius.full`. Type: serif 40 `type.display`; serif 28 `type.headline`; serif 20–24 `type.cardName`; serif 16–18 paragraphs `type.bodyReading`; sans 20/600 `type.title`; sans 17–18/600 `type.titleSmall`; sans 16 `type.body`; sans 14–15/500 `type.label`; sans 12–13 `type.caption`; numerals `type.numeral`. Nothing renders below 12 sp (canvas 9–11 px badges become `type.caption`). Side gutter `layout.gutter` (16; onboarding pages use `space.7` = 24). Tablet: the content column is `layout.maxContentWidth` (600) centred, long text is capped at `layout.readingMaxWidth`. Controls drawn at 40–44 px keep their look but get a ≥ `size.touchTarget.min` (48) hit area. Colours are tokens only (`color.*`, names in 01 §14.1). Every ★ state is a golden in light + dark at phone and tablet width (01 §8.3, RC24). *Derived* means that no artboard exists: Phase 16/17 builds the state from the designed states, the tokens and the shared state widgets (01 §8.2), and REVIEW.md checks it.
