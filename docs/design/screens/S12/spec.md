# S12 · Rewarded flow overlay

| | |
|---|---|
| Route | modal (over S10/S11 and the screen under them) |
| Banner | none (rewarded ad format only; the underlying banner is hidden while the modal is shown) |
| Artboards | [`../Rewarded.dc.html`](../Rewarded.dc.html) (`granting`, over a dimmed Today with the "Free reading used" chip) · [`../RewardedGranted.dc.html`](../RewardedGranted.dc.html) (`granted`) |
| Frames | [`Rewarded.png`](../frames/Rewarded.png) · [`RewardedGranted.png`](../frames/RewardedGranted.png) (PNG @2x, from the artboards above) |
| Next | `granted` → closes S10 → back to S07 with Begin enabled (the user taps Begin; no auto-start) |

## Layout
Scrim `color.bg.scrim`. A centred `TaroDialog`: `color.bg.surfaceRaised`, `radius.xl`, padding `space.8` / `space.7` / `space.6`, gap `space.6`, width = content − 2 × `space.7`.
1. Progress: an indeterminate ring 88 × 88 (`color.accent.primary` on `color.border.subtle`) with a small `TaroCardBack` 32 × 52 in the centre.
2. Title serif 24 `type.cardName` "Adding your reading…"; body `type.body` `color.text.secondary` "This usually takes a few seconds."
3. Caption `type.caption`: "If you close this, your reading will still be added."
4. `TaroButton.secondary` "Cancel" (it closes the overlay only; the grant still lands via SSV and sync).

Banners are hidden while any modal is shown (04 §8). **Resolved**: the banner container under the scrim was removed from `Rewarded` and `RewardedGranted`.

## Components
`TaroDialog`, progress ring (`TaroLoadingView` variant), `TaroCardBack`, `TaroButton`, snackbar.

## States (01 §8.3)
| State | ★ | Source |
|---|---|---|
| `loadingAd` (≤ `rewarded.loadTimeoutSec`, 10 s) | | Derived: the same dialog, title "Loading a short ad…", Cancel |
| `noFill` | | Derived: the dialog closes; S10 shows "No ads available right now" and the row is disabled for 60 s |
| `showing` | | AdMob SDK full-screen UI (not designed, not customised) |
| `granting` (poll every 1.5 s up to 20 s) | | **Designed**: `Rewarded.dc.html` |
| `granted` | ★ | **Designed**: `RewardedGranted.dc.html` (the ring becomes a check in `color.status.success`, the title "Reading added", the body "+1 reading", `TaroButton.primary` "Continue" → S07) |
| `grantDelayed` | | Derived: the dialog closes; a non-blocking snackbar "Your reading will appear shortly"; re-synced on resume |
| `dismissedEarly` | | Derived: the dialog closes with a neutral snackbar "The ad closed early, so no reading was added." (no blame); the intent is cancelled |

## Motion
Dialog in: fade + scale 0.96 → 1, `motion.duration.base`, `motion.easing.decelerate`. Ring spins continuously; check pop `motion.duration.fast`. Reduced motion: a static ring with the text only; the check appears without scaling.

## Semantics / reading order
A modal dialog labelled by the title; the progress bar is labelled "Adding your reading" → body → caption → Cancel. A polite live region announces "Reading added" (or the delayed/early messages).

## RTL
Centred content; nothing directional apart from the text.

## Banner
None.

---

**Conventions (same in every S-spec).** Canvas px = dp/sp. Spacing 2/4/8/12/16/20/24/32/40/48/56/64 = `space.1`…`space.12`; odd canvas values (6, 10, 14, 18, 28) snap to the nearest token. Radius: 4 `radius.xs`, 8 `radius.sm`, 10 `radius.card`, 12 `radius.md`, 16 `radius.lg`, 24 `radius.xl`, 28 `radius.sheet`, 999 `radius.full`. Type: serif 40 `type.display`; serif 28 `type.headline`; serif 20–24 `type.cardName`; serif 16–18 paragraphs `type.bodyReading`; sans 20/600 `type.title`; sans 17–18/600 `type.titleSmall`; sans 16 `type.body`; sans 14–15/500 `type.label`; sans 12–13 `type.caption`; numerals `type.numeral`. Nothing renders below 12 sp (canvas 9–11 px badges become `type.caption`). Side gutter `layout.gutter` (16; onboarding pages use `space.7` = 24). Tablet: the content column is `layout.maxContentWidth` (600) centred, long text is capped at `layout.readingMaxWidth`. Controls drawn at 40–44 px keep their look but get a ≥ `size.touchTarget.min` (48) hit area. Colours are tokens only (`color.*`, names in 01 §14.1). Every ★ state is a golden in light + dark at phone and tablet width (01 §8.3, RC24). *Derived* means that no artboard exists: Phase 16/17 builds the state from the designed states, the tokens and the shared state widgets (01 §8.2), and REVIEW.md checks it.
