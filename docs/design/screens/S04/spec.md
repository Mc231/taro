# S04 · AI consent (onboarding step 3 + re-entry)

| | |
|---|---|
| Route | `/consent/ai` |
| Banner | none |
| Artboards | [`../AiConsent.dc.html`](../AiConsent.dc.html); ATT neutral pre-prompt: [`../AttPrompt.dc.html`](../AttPrompt.dc.html) (onboarding step 5, specced below) |
| Frames | [`AiConsent.png`](../frames/AiConsent.png) · [`AttPrompt.png`](../frames/AttPrompt.png) (PNG @2x, from the artboards above) |
| Next | Onboarding: Allow / Not now → UMP form (if required) → ATT pre-prompt (iOS) → S05. Re-entry from S07: Allow → back to S07 with the gate re-run; Not now/Back → S07 with the Classic reading offer (F7, F8) |

## Layout (top → bottom)
Padding `space.12` / `space.7` / `space.9`; column gap `space.7`.
1. Icon tile 56 × 56, `radius.lg`, `color.accent.subtle`, sparkle icon `color.accent.primary`.
2. Title serif 28 `type.headline` `aiConsentTitle` "Your readings use AI", then the body `type.label` (15/22) in `color.text.secondary`: the full `aiConsentBody` string, verbatim, gap `space.4`.
3. (Removed.) The canvas had a facts group with three rows ("What is sent", "What is kept", "No account"). They repeated `aiConsentBody` in other words and did not fit next to the full string, so they were dropped; `aiConsentBody` is the only explanation on the sheet.
4. "Privacy policy" link (48 hit) → privacy URL (05).
5. Flexible spacer.
6. Buttons stacked, gap `space.3`, both full width, 52, `radius.md`: `aiConsentAccept` "Allow AI readings", `aiConsentDecline` "Not now".
7. Footnote `type.caption`, `color.text.tertiary`: "Without AI you still get the daily card, classic readings, Learn and the journal. Change this any time in Settings."

**Sign-off items (CS6, 05 §3), both resolved on `AiConsent.dc.html`:**
- *Equal visual weight.* **Resolved**: both buttons now use the same tonal style (`color.accent.subtle` fill + `color.border.strong` outline, 52, `radius.md`). Code uses the same `TaroButton` variant and size for both, in the same order in every locale.
- *Copy.* **Resolved**: the title is `aiConsentTitle` "Your readings use AI" and the body is the exact `aiConsentBody` string, which includes every required claim (name, email and advertising ID never sent; question not stored; reading kept encrypted at most 7 days; a reported reading kept 90 days; the AI service does not train on this data; readings are AI-generated and may be wrong or unexpected). **2026-10-06 (owner):** the copy names no AI vendor; it says the question goes to "our Taro servers" and "a third-party AI service", and that the privacy policy names the service (CS6; the policy names every provider in `ai.disclosedProviders`). "Privacy policy" is a `TaroButton.link` that opens `legal.privacyUrl?hl=` in the in-app browser, also during onboarding.

## Components
`TaroButton` ×2 (same variant), `TaroIconButton` (re-entry Back), `TaroScaffold`.

## States (01 §8.3)
| State | ★ | Source |
|---|---|---|
| `undecided` | ★ | **Designed**: `AiConsent.dc.html` |
| `granted` | | Derived: no own UI. `granted(version, timestamp)` is persisted and the flow continues (next onboarding step, or back to S07 where the gate re-runs) |
| `declined` | | Derived. From onboarding: continue to UMP. From the reading gate (re-entry variant): the same layout with a top-start Back `TaroIconButton`, the title "AI readings need your permission" and the buttons **Allow** / **Back** (equal weight). Back → S07, which then offers the Classic reading (S32) |

### ATT neutral pre-prompt (onboarding step 5, iOS): [`AttPrompt.dc.html`](../AttPrompt.dc.html)
Shown only when `ads.attPrepromptEnabled` (default true), after UMP resolves, and never when UMP returns `canRequestAds == false` (CS14, RC19). Same page template as this screen: an icon tile, a title, 2–3 lines of neutral copy (05 CS14), and **one** "Continue" button that triggers the system prompt. No incentive, no fake "Allow" button that mimics the system dialog, and no Skip that leads to a second pre-prompt. The UMP IDFA explainer is disabled, so this is the only pre-prompt. The UMP consent form (step 4) is the SDK UI and is not designed.

## Motion
Push `motion.duration.base`; reduced: fade. No animation draws attention to either button.

## Semantics / reading order
Icon excluded → title (header) → body (`aiConsentBody`) → Privacy policy (link) → Allow AI readings → Not now → footnote. Both buttons are plain buttons; no pre-checked boxes. On re-entry, focus starts on the title.

## RTL
Mirrored alignment; the Back chevron mirrors; the icon tile sits at the start.

## Banner
None (consent and the ATT pre-prompt are never ad surfaces).

---

**Conventions (same in every S-spec).** Canvas px = dp/sp. Spacing 2/4/8/12/16/20/24/32/40/48/56/64 = `space.1`…`space.12`; odd canvas values (6, 10, 14, 18, 28) snap to the nearest token. Radius: 4 `radius.xs`, 8 `radius.sm`, 10 `radius.card`, 12 `radius.md`, 16 `radius.lg`, 24 `radius.xl`, 28 `radius.sheet`, 999 `radius.full`. Type: serif 40 `type.display`; serif 28 `type.headline`; serif 20–24 `type.cardName`; serif 16–18 paragraphs `type.bodyReading`; sans 20/600 `type.title`; sans 17–18/600 `type.titleSmall`; sans 16 `type.body`; sans 14–15/500 `type.label`; sans 12–13 `type.caption`; numerals `type.numeral`. Nothing renders below 12 sp (canvas 9–11 px badges become `type.caption`). Side gutter `layout.gutter` (16; onboarding pages use `space.7` = 24). Tablet: the content column is `layout.maxContentWidth` (600) centred, long text is capped at `layout.readingMaxWidth`. Controls drawn at 40–44 px keep their look but get a ≥ `size.touchTarget.min` (48) hit area. Colours are tokens only (`color.*`, names in 01 §14.1). Every ★ state is a golden in light + dark at phone and tablet width (01 §8.3, RC24). *Derived* means that no artboard exists: Phase 16/17 builds the state from the designed states, the tokens and the shared state widgets (01 §8.2), and REVIEW.md checks it.
