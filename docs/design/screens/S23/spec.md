# S23 · Privacy choices

| | |
|---|---|
| Route | `/settings/privacy` |
| Banner | none |
| Artboards | [`../PrivacyChoices.dc.html`](../PrivacyChoices.dc.html) (iOS, UMP required, AI allowed) |
| Frames | [`PrivacyChoices.png`](../frames/PrivacyChoices.png) (PNG @2x, from the artboards above) |
| Next | Withdraw/Allow AI → S04 · "Review ad choices" → the UMP privacy options form (SDK) · Tracking → iOS Settings · "Read the privacy policy" → S29 privacy |

## Layout (top → bottom)
Padding `space.10` / `layout.gutter` / `space.7`; gap `space.6`.
1. Back; title "Privacy choices" serif 28; body "Taro works fully whatever you choose here."
2. **AI readings** (h2 caption): a status row (min 68, `color.bg.surface`, `radius.lg`): a status dot (`color.status.success`) **plus the text** "Allowed", subtitle "Your question and cards go to Claude by Anthropic to write readings."; an outlined pill "Withdraw" (44 → 48 hit). When declined: "Not allowed" (dot `color.text.tertiary`) + an "Allow" pill → S04.
3. **Ads**: a group with "Ad personalisation" + subtitle "Managed by Google's consent form. Ads never appear inside a reading." + a full-width `TaroButton.secondary` "Review ad choices"; the Tracking row (iOS only) "Not allowed · change in iOS Settings" → opens iOS Settings.
4. **Improving Taro**: one "Usage analytics" switch ("Which screens get used, and crash reports. Never your questions or readings."). **Resolved**: the separate "Crash reports" switch was removed from `PrivacyChoices.dc.html`. 01 §7.10 lists only the usage analytics toggle, and 02 §13 binds Crashlytics collection to that toggle (`setCrashlyticsCollectionEnabled`), so one switch controls both; 05 §5 still discloses crash data.
5. Flexible spacer; link "Read the privacy policy".

## Components
`SettingsTile` (status, switch), `TaroButton`, `TaroDialog` (withdraw confirmation).

## States (01 §8.3)
| State | ★ | Source |
|---|---|---|
| `content`: UMP required, iOS | | **Designed** |
| UMP not required | | Derived: the "Ad personalisation" block is hidden (`privacyOptionsRequirementStatus != required`) |
| Android | | Derived: no Tracking row |
| AI declined | | Derived: see step 2 |
| withdraw AI | | Derived: `TaroDialog` "Stop AI readings? You can still use classic readings, the daily card, Learn and your journal." [Stop AI readings] [Cancel] (equal weight) |

## Motion
Switches `motion.duration.fast`; reduced: instant.

## Semantics / reading order
Back → title → body → "AI readings" (header) → "Allowed. Your question and cards go to Claude by Anthropic…" → Withdraw → "Ads" (header) → Ad personalisation + Review ad choices → Tracking → "Improving Taro" (header) → the usage analytics switch → privacy policy link.

## RTL
Mirrored; the dot sits at the start of the status text.

## Banner
None.

---

**Conventions (same in every S-spec).** Canvas px = dp/sp. Spacing 2/4/8/12/16/20/24/32/40/48/56/64 = `space.1`…`space.12`; odd canvas values (6, 10, 14, 18, 28) snap to the nearest token. Radius: 4 `radius.xs`, 8 `radius.sm`, 10 `radius.card`, 12 `radius.md`, 16 `radius.lg`, 24 `radius.xl`, 28 `radius.sheet`, 999 `radius.full`. Type: serif 40 `type.display`; serif 28 `type.headline`; serif 20–24 `type.cardName`; serif 16–18 paragraphs `type.bodyReading`; sans 20/600 `type.title`; sans 17–18/600 `type.titleSmall`; sans 16 `type.body`; sans 14–15/500 `type.label`; sans 12–13 `type.caption`; numerals `type.numeral`. Nothing renders below 12 sp (canvas 9–11 px badges become `type.caption`). Side gutter `layout.gutter` (16; onboarding pages use `space.7` = 24). Tablet: the content column is `layout.maxContentWidth` (600) centred, long text is capped at `layout.readingMaxWidth`. Controls drawn at 40–44 px keep their look but get a ≥ `size.touchTarget.min` (48) hit area. Colours are tokens only (`color.*`, names in 01 §14.1). Every ★ state is a golden in light + dark at phone and tablet width (01 §8.3, RC24). *Derived* means that no artboard exists: Phase 16/17 builds the state from the designed states, the tokens and the shared state widgets (01 §8.2), and REVIEW.md checks it.
