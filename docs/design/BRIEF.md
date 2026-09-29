# Taro — Claude Design brief (Phase 14, Sprint 14.1)

This is the handoff brief given to Claude Design (D16). It packages the product spec into one document: what Taro is, the platform constraints, the design-token contract, the screen and state list, the hard rules and the expected deliverables. The spec files stay the source of truth; every section below names the section it comes from.

**Sources:** `docs/specs/01_PRODUCT.md` PR1, PR2, PR13, PR16, PR17, §4, §4.1, §5, §8, §12, §13, §14 · `02_ARCHITECTURE.md` §14 · `04_MONETIZATION.md` §8, §11 · `05_COMPLIANCE_STORE_ASO.md` CS3, CS6, CS13, §3, §6.1, §9.5 · `00_DECISIONS.md` RC15, RC17, RC18, RC20, RC24, RC59.

---

## 0. Design direction (chosen) and links

**Direction: printed tarot on an ink ground.** The interface should feel like a quiet desk at night with a real deck on it: the flat, saturated inks of historical printed decks (Marseille-style woodcut colouring) on a calm indigo-black ground, generous serif reading text, and nothing that hurries the user.

| Role | Colour | Tokens | Light / dark |
|---|---|---|---|
| Ground ("ink") | deep indigo-black (dark), cool paper-grey (light) | `color.bg.canvas`, `color.bg.surface`, `color.bg.surfaceRaised`, `color.bg.sunken` | `#EEF0F4` / `#0F1120` (canvas) |
| **Ultramarine**: the only call-to-action colour (Begin, Draw, Buy, links, selection) | printed blue | `color.accent.primary`, `primaryPressed`, `subtle` | `#2E3FAE` / `#9AA8FF` |
| **Vermilion**: emphasis inside content (reading section markers, the Reversed badge); never a button, never an error | printed red | `color.accent.secondary`, `color.card.reversedBadge` | `#B63A25` / `#F3957A` |
| **Ochre**: belongs to the deck (card frame, glow, Major Arcana) and the focus ring | printed yellow-gold | `color.card.frame`, `color.card.glow`, `color.suit.major`, `color.border.focus` | frame `#B8820F` / `#D4A63A`; focus `#A87508` / `#F2C14E` |
| Card back | ultramarine field + ochre ornament, **identical in both themes** | `color.card.back` | `#23308F` |

Approved Claude Design artifacts (owner sign-off 2026-09-27):

- **Design system (brand book, tokens, component previews):** https://claude.ai/artifact/C94hpvYCJKqrqYn5o8VnRb
- **Screens canvas (S01–S33 + variants, app icon, card back):** https://claude.ai/artifact/1d29x21T1WhcFhFaeo3QxL

Repo snapshots: `docs/design/taro.tokens.json` (DTCG export of the approved tokens), `docs/design/screens/*.dc.html` + `docs/design/screens/canvas.json` (canvas sources and board layout; the canvas is the source of truth). Component mapping: `docs/design/components.md`.

---

## 1. Product

### 1.1 Positioning (PR1, 01 §4)

- **What Taro is:** a reflective tarot journal. A self-reflection tool that uses tarot imagery as prompts. It **never predicts the future**.
- **Vision:** a calm, beautiful daily ritual that helps people pause, look at a situation from new angles and write down what they notice.
- **Positioning:** for people who use tarot for reflection rather than prediction, Taro pairs an original deck with thoughtful, spread-aware AI interpretations and a private journal. Unlike generic tarot apps, it explains *why* cards relate to each other, teaches the deck, and keeps insights private on the device.
- **Framing everywhere (CS3):** "for entertainment and self-reflection". No accuracy, guarantee, psychic, prediction, healing or spell language in any UI string or caption (05 §9.5 list).

### 1.2 Tone of voice (01 §4, brand book)

- Warm, grounded, non-mystifying. Speak to the user as "you"; Taro never says "I". Offer, don't predict: "This card may point to…", "You might consider…".
- Never fear ("danger ahead"), certainty ("will happen"), urgency ("act now", "only today") or guilt ("the cards are waiting"). This holds for paywall and rewarded-ad copy too.
- Sentence case everywhere, including buttons. Card names keep their proper names ("The Star", "Three of Cups"). No emoji in UI copy.
- Every notice says what happened and what to do next. No apologies, no blame.

### 1.3 Personas (01 §5)

| ID | Persona | Needs | Design implication |
|---|---|---|---|
| P-A | **Maya, 27, reflective journaler.** Weekly tarot as a journaling prompt; sceptical of "psychic" claims. | Privacy, a place to write, beautiful cards | Journal and notes are first-class; "stays on this phone" is visible; reflection prompts in every reading |
| P-B | **Daniel, 34, curious beginner.** Wants to learn what the cards mean. | Learning without overwhelm | Keywords on reveal, Learn mode, spread guide, upright-only option |
| P-C | **Leyla, 41, daily ritualist** (`ar`/`tr`). Opens the app with morning coffee. | A quick daily moment, her language, RTL done right | Daily card on Today, gentle reminder, full RTL mirroring |
| P-D | **Kenji, 22, occasional deep-diver** (`ja`). Celtic Cross for big decisions. | A rich reading when it matters; pays occasionally | Celtic Cross and Two Paths legible at phone width; honest packs |

Anti-persona: people seeking medical, legal, financial or pregnancy answers or gambling tips. The product redirects them (refusal card, S27 crisis resources).

### 1.4 Differentiation (01 §4.1, 4.3 evidence)

| Typical tarot app | Taro |
|---|---|
| Stock Rider–Waite scans | Original deck art (D15), one consistent visual language |
| One canned paragraph per card | AI synthesis across positions and card relations, plus deep authored per-card content |
| Single-card or 3-card only | 6 spreads including Relationship, Two Paths and Celtic Cross |
| No memory | Journal with notes, favourites, search and local pattern insights (most-drawn cards, suit balance) |
| Usually EN only | 12 locales including RTL Arabic, with the deck content localized too |
| Hard paywall after the draw | Free daily reading and free daily card; paywall only before the draw |
| Ads everywhere | Banners on three browse screens only, none near readings |
| Poor accessibility | Screen-reader-complete draw ("Draw for me"), Dynamic Type, reduced motion |

---

## 2. Platform constraints

- **Universal app (PR16, RC24).** iOS: iPhone + iPad (`TARGETED_DEVICE_FAMILY = 1,2`). Android: phones + tablets. One Flutter codebase.
- **Orientation:** portrait only on phones; iPad supports all orientations (multitasking) with the same constrained layout.
- **Wide screens:** Material window size classes (`compact` < 600, `medium` < 840, `expanded`). Content is centred and capped at `layout.maxContentWidth` (600); reading text at `layout.readingMaxWidth` (560). No separate tablet information architecture.
- **Reference frames:** phone 390 × 844 (iPhone 6.1"), tablet 1032 × 1376 (iPad 13" portrait). Goldens also run at `kPhoneSmall` and an Android tablet width (06 §3).
- **Navigation (RC17):** bottom tab bar with exactly **4 tabs**: **Today** (S05), **Journal** (S14), **Learn** (S16), **Settings** (S20). Everything else is pushed on top or shown as a sheet/dialog.
- **Offline:** daily card, Learn, Journal, Settings, crisis resources and Classic readings work offline; fonts and art are bundled.
- **No accounts.** No sign-in UI anywhere.
- **Themes:** light and dark, following the system by default (Settings → Theme). Both themes are first-class; the brand leads with dark.
- **Locales (01 §13):** `en, ar, de, es, fr, it, ja, ko, nl, pt, tr, uk`. Layouts tolerate +40% text expansion (de, nl) and CJK line-breaking.

---

## 3. Design-token contract (01 §14, 02 §14.2)

The spec fixes token **names, roles and constraints**; Claude Design supplies **values**. Names are a contract: any name change is a spec change (edit 01 §14 + `00_DECISIONS.md` in the same commit). Widgets use tokens only: no raw colours, sizes or durations (lint-enforced).

### 3.1 Colour (each defined for `light` and `dark`)

| Token | Role / constraint |
|---|---|
| `color.bg.canvas` | App background |
| `color.bg.surface` / `surfaceRaised` / `sunken` | Cards and rows / sheets and dialogs / inputs |
| `color.bg.scrim` | Modal overlay (with alpha) |
| `color.text.primary` / `secondary` / `tertiary` / `disabled` / `inverse` / `onAccent` | primary + secondary **≥ 4.5:1** on canvas and surface (the brand book also holds them on surfaceRaised and sunken); tertiary ≥ 4.5:1 on canvas and surface |
| `color.accent.primary` / `primaryPressed` / `secondary` / `subtle` | Primary CTAs and selection (ultramarine) / content emphasis (vermilion) / tinted fills |
| `color.border.subtle` / `strong` / `focus` | `focus` **≥ 3:1** against its neighbours; control outlines use `strong` (3:1); `subtle` is decorative only |
| `color.status.success` / `warning` / `error` / `info` + `color.status.on*` | Notices and errors; always with an icon and a sentence |
| `color.card.back`, `color.card.frame`, `color.card.glow`, `color.card.reversedBadge` | Deck rendering |
| `color.suit.major` / `wands` / `cups` / `swords` / `pentacles` | Decorative accents, **never the sole signal** |
| `color.chart.suit.*` | Patterns chart; categories distinguishable in both modes |
| `color.ad.container` | Banner container, visually separated from content |
| `color.skeleton.base` / `highlight` | Loading states |

### 3.2 Typography

Roles: `type.display`, `type.headline`, `type.title`, `type.titleSmall`, `type.body`, `type.bodyReading`, `type.label`, `type.caption`, `type.cardName`, `type.numeral`. Each role defines `fontFamily` (per script, `font.family.{role}.{latin|cyrillic|arabic|cjk|hangul}`), `fontSize` (sp, scaled by `TextScaler`), `fontWeight`, `lineHeight`, `letterSpacing`.

Constraints: **body ≥ 16 sp**, **caption ≥ 12 sp**; `type.bodyReading` line height **≥ 1.5** and **≤ 70 characters per line** (via `layout.readingMaxWidth`).

Approved values (phone, 1.0× scale):

| Role | Family | Size / line | Weight | Use |
|---|---|---|---|---|
| `type.display` | serif | 40 / 44 | 500 | One per screen at most: onboarding titles, Today greeting |
| `type.headline` | serif | 28 / 34 | 500 | Screen titles, reading title |
| `type.cardName` | serif | 22 / 28 | 600 | Card names on revealed cards and card detail |
| `type.bodyReading` | serif | 18 / 29 | 400 | Long-form AI and authored reading text |
| `type.title` | sans | 20 / 26 | 600 | Section headings, sheet titles, reading section headings |
| `type.titleSmall` | sans | 17 / 22 | 600 | List-row titles, position titles, pack names |
| `type.body` | sans | 16 / 24 | 400 | All UI copy |
| `type.label` | sans | 15 / 20 | 500 | Buttons, chips, tabs |
| `type.caption` | sans | 13 / 18 | 400 | Captions, disclaimers, timestamps |
| `type.numeral` | numeral | 20 / 24 | 400 | Roman numerals on card faces |

### 3.3 Fonts per script (01 §13) — bundled offline, no runtime Google Fonts fetch

| Script (locales) | UI (`sans`) | Reading + display (`serif`) | Card numerals (`numeral`) |
|---|---|---|---|
| Latin (`en de es fr it nl pt tr`) | IBM Plex Sans | Literata | IM Fell English SC |
| Cyrillic (`uk`) | IBM Plex Sans | Literata | IM Fell English SC |
| Arabic (`ar`) | IBM Plex Sans Arabic | Noto Serif Arabic (reading fallback) | IM Fell English SC |
| CJK (`ja`) | IBM Plex Sans JP | Noto Serif JP (reading fallback) | IM Fell English SC |
| Hangul (`ko`) | IBM Plex Sans KR | Noto Serif KR (reading fallback) | IM Fell English SC |

Roman numerals are Latin letters in every locale, so one numeral face serves all 12. All faces ship in `packages/taro_ui/fonts/` (subset per script; size budget checked in Phase 15 against 02 §17).

### 3.4 Spacing, sizing, radius, elevation, opacity

- `space.0` … `space.12`: 4-pt scale — 0, 2, 4, 8, 12, 16, 20, 24, 32, 40, 48, 56, 64.
- `space.adGap` = 16 (**≥ 16 dp** between the banner container and any tap target, RC59).
- `layout.gutter` = 16 (≥ 16), `layout.maxContentWidth` = 600, `layout.readingMaxWidth` = 560.
- `size.touchTarget.min` = **48** (every tap target ≥ 48 × 48 dp), `size.icon.sm/md/lg` = 16/24/32.
- `size.card.aspectRatio` = 0.58; `size.card.thumb/sm/md/lg` = 40/72/104/220 (width). `sm` in the pick fan and Celtic Cross, `md` in 1–5 card spreads, `lg` on the daily card and card detail.
- `radius.none/xs/sm/md/lg/xl/full` = 0/4/8/12/16/24/999; `radius.card` = 10; `radius.sheet` = 28 (top corners).
- `elevation.0` … `elevation.4`: shadow in light (`elevation.n.shadow`), tonal overlay in dark (`elevation.n.overlay` = 0, .03, .05, .08, .11). Spread cards on `elevation.2`; a card in flight and bottom sheets on `elevation.3`.
- `opacity.disabled` = 0.38, `opacity.scrim` = 0.64, `opacity.pressed` = 0.12.

### 3.5 Motion (01 §14.4) and reduced motion

| Token | Default | Reduced-motion value |
|---|---|---|
| `motion.duration.instant` | 100 ms | 0 |
| `motion.duration.fast` | 150 ms | 100 ms |
| `motion.duration.base` | 250 ms | 150 ms (fade only) |
| `motion.duration.slow` | 400 ms | 200 ms (fade only) |
| `motion.ritual.shuffle` | 1200 ms minimum loop | 200 ms crossfade |
| `motion.ritual.dealStagger` | 120 ms | 0 |
| `motion.ritual.flip` | 600 ms | 200 ms crossfade |
| `motion.ritual.readingReveal` | 500 ms section stagger | 0 |
| `motion.easing.standard` | cubic-bezier(0.2, 0, 0, 1) | linear |
| `motion.easing.emphasized` | cubic-bezier(0.3, 0, 0, 1.2) — a card landing in its slot | linear |
| `motion.easing.decelerate` | cubic-bezier(0, 0, 0, 1) — entering | linear |
| `motion.easing.accelerate` | cubic-bezier(0.3, 0, 1, 1) — exiting | linear |

Reduced motion is on when `MediaQuery.disableAnimations` or the in-app setting is set: shuffle, deal and flip become crossfades ≤ 200 ms; no parallax, particles or glow pulses. Every ★ ritual state has a reduced-motion variant (S08 `reducedMotion`★).

### 3.6 Haptics

`haptic.pick` = selection click (a card is picked), `haptic.flip` = light impact (a card turns), `haptic.ready` = medium impact (the reading is ready). All haptics obey Settings → Haptics. There is **no audio** in v1.

### 3.7 Token export status (fixed 2026-09-27)

All four gaps found while writing this brief are fixed in `taro.tokens.json` and in the Claude Design system (no spec change needed):

1. Layout tokens are `layout.gutter|maxContentWidth|readingMaxWidth`.
2. Font families are `font.family.{role}.{latin|cyrillic|arabic|cjk|hangul}` for every type role (mapping in §3.3); each `type.*` style references `{font.family.<role>.latin}` and the generator swaps the script at runtime.
3. `haptic.pick|flip|ready` exist (`selection`, `light`, `medium`).
4. Reduced-motion values are machine-readable under `$extensions["taro.reducedMotion"]` on every `motion.*` token.

A name and contrast check (`01 §14` names present in both modes; 34 contrast pairs) passes; see `REVIEW.md`. The Dart validator `tools/tokens/validate_tokens.dart` is written in Phase 15 Sprint 15.1, when the Dart tooling exists (Phase 2/3).

---

## 4. Screen list and states

**State source.** Phase 13.4's generated `docs/design/STATE_INVENTORY.md` does not exist yet, so this brief uses the **01 §8.3 state table** as the state inventory. Phase 13.4 will refine it; any new or renamed state is added to the designs before sign-off (REVIEW.md).

**Legend.** ★ = golden state: design it in light **and** dark, at phone **and** tablet width (iPad 13" and Android tablet, RC24). **AR** = also design an `ar` (RTL) variant (S05, S08, S09, S14; 01 §14.5). **Ad** = banner allowed. "Artboard" is the current canvas board (dark, `en`, phone unless noted).

| ID | Screen | Route | States (★ = golden) | Artboard(s) on the canvas |
|---|---|---|---|---|
| S01 | Launch / bootstrap | `/` | `bootstrapping`, `storageError` (fatal, "Contact support"), → `updateRequired`, → onboarding/home | `Launch` |
| S02 | Onboarding: Welcome | `/onboarding/welcome` | `content`★ | `Main` |
| S03 | Onboarding: Disclaimer | `/onboarding/disclaimer` | `content`★, `acknowledged` | `Disclaimer` |
| S04 | AI consent | `/consent/ai` | `undecided`★, `granted`, `declined` (from the reading flow: "AI readings need your permission" + Allow / Back) | `AiConsent` |
| S05 | Today (tab) · **Ad · AR** | `/home` | `loading`, `content`★ (free available / free used + credits / zero readings), `firstRun` (coachmark), `balanceStale`, `deviceUnverified`, `dailyCardNotDrawn` / `dailyCardDrawn`, `bannerLoaded` / `bannerFailed` / `adsRemoved`, `updateAvailable` | `Today`, `TodayLight`, `TodayAr`, `TodayTablet` |
| S06 | Spread picker | `/reading/spreads` | `content`★ (remote-disabled spreads hidden) | `Spreads` |
| S07 | Question input | `/reading/question?spread=` | `editing`★, `checking`, `offline`, `consentRequired`, `deviceUnverified`, `readingsPaused` (→ S31), `aiUnavailableRegion`, `outOfReadings` (→ S10), `dailyLimitReached`, `lowTrustLimited`, `rephrase`, `refused(category)`★, `rateLimited` | `Question` |
| S08 | Draw ritual · **AR** | `/reading/draw` | `shuffling`★, `picking`★, `revealing`, `awaitingReading` (keywords)★, `slowReading`, `generationFailed`, `holdLost`, `timeoutPolling`, `deliveryExpired`, `crisis` (→ S27), `reducedMotion`★ | `Draw` (picking) |
| S09 | Reading result · **AR** | `/reading/:id` | `content`★ (LTR/RTL, light/dark), `ratingGiven`, `sharing`, `loadingFromStorage` | `Reading`, `ReadingLight`, `ReadingAr` |
| S10 | Out-of-readings sheet | modal | `content`★ with rewarded available / cooling down / capped / disabled / failed; packs loading / loaded / store unavailable; always "Next free reading in …" | `OutOfReadings` |
| S11 | Store / paywall | `/store` | `loading`★, `content`★, `storeUnavailable`, `purchasing`, `pending`, `verifying`, `success`, `failed(kind)`, `cancelled`, `verificationDelayed`, `removeAdsOwned`, rewarded offer, `purchasesBlocked(blocked \| refundDebt)` | `Store` (content) |
| S12 | Rewarded overlay | modal | `loadingAd`, `showing` (SDK), `granting`, `granted`★, `grantDelayed`, `dismissedEarly` | `Rewarded` (granting) |
| S13 | Daily card | `/daily` | `notDrawn`★, `revealing`, `drawn`★, `noteEditing`, `reminderOffer` | `DailyCard` (drawn) |
| S14 | Journal (tab) · **Ad · AR** | `/journal` | `loading`, `empty`★, `content`★, `filteredEmpty`, `searchEmpty`, `storageError` | `Journal` (content) |
| S15 | Journal entry + note | `/journal/:id` | `content`, `pending`, `failed`, `deleted` (→ pop + undo) | `JournalEntry` |
| S16 | Learn deck (tab) · **Ad** | `/learn` | `content`★, `searchEmpty` | `Learn` |
| S17 | Card detail | `/learn/card/:cardId` | `upright`★, `reversed`, `zoomed` | `CardDetail` |
| S18 | Spreads guide + detail | `/learn/spreads[/:spreadId]` | `content` | `SpreadsGuide` (Celtic Cross) |
| S19 | About tarot & Taro | `/learn/about` | `content` | `AboutTaro` |
| S20 | Settings (tab) | `/settings` | `content`★, `adsRemoved`, `restoreInProgress`, `restoreSuccess(nothingFound \| removeAdsRestored)`, `restoreFailed` | `Settings` |
| S21 | Language picker | `/settings/language` | `content` | `Language` |
| S22 | Reminder settings | `/settings/reminder` | `content`, `permissionDenied` | `Reminder` |
| S23 | Privacy choices | `/settings/privacy` | `content` (UMP required / not required; iOS / Android) | `PrivacyChoices` |
| S24 | Export backup | `/settings/export` | `preparing`, `shareSheetOpen`, `done`, `failed(storage)` | `Export` (done) |
| S25 | Import backup | `/settings/import` | `picking`, `validating`, `invalid(notTaro \| newerVersion \| corrupt \| tooLarge)`★, `preview`★, `confirmReplace`, `importing(progress)`, `done(summary)`, `failed` | `Import` (preview) |
| S26 | Delete all data | `/settings/delete` | `confirm1`, `confirm2`, `deleting`, `done`, `partial` | `DeleteData` |
| S27 | Crisis resources | `/help/crisis` | `content`★ (country-aware, bundled, offline) | `Crisis` |
| S28 | FAQ / Help | `/help` | `content` | `Help` |
| S29 | Legal (disclaimer / terms / privacy / licences) | `/legal/:doc` | `content` | `Legal` (disclaimer) |
| S30 | Update required (blocking) | `/update` | `content`★ (store link only) | `UpdateRequired` |
| S31 | Readings paused | inline state of S07 | `readingsPaused`, copy variant `freePaused` (never a paywall, RC47) | `ReadingsPaused` |
| S32 | Classic reading | `/reading/:id?mode=classic` | `content`★ (LTR/RTL, light/dark), `loadingFromStorage` | `ClassicReading` |
| S33 | Report reading (sheet) | modal from S09 / S15 | `editing`★, `submitting`, `submitted`, `failed`, `offline`, `rateLimited`, `alreadyReported` | `Report` |

Also designed: `CardBack` (card-back artwork, 580 × 1000) and `AppIcon` (1024 master).

Still to design before sign-off (not yet on the canvas): the light, tablet and `ar` variants of every ★ state beyond those listed above (S08 `ar`, S14 `ar` in particular); the non-content ★ states (S07 `refused`, S08 `shuffling` / `awaitingReading` / `reducedMotion`, S11 `loading`, S12 `granted`, S13 `notDrawn`, S14 `empty`, S25 `invalid`); the neutral **ATT pre-prompt** (iOS, after UMP; toggled by `ads.attPrepromptEnabled`); the S05 first-run coachmark; toasts/snackbars (S11 `success` "+10 readings", S15 delete + undo); the S09 rating control; 200% text-scale layouts for S05, S09 and S13.

---

## 5. Hard rules (non-negotiable; checked in REVIEW.md)

**Ads (PR13, RC18, RC59, 04 §8)**
- Banners appear **only on S05, S14 and S16** (`kBannerAllowList = {home, journal_list, learn_library}`), anchored at the bottom above the tab bar, in their own `color.ad.container` container, full width.
- The container keeps **≥ `space.adGap` (16 dp)** from any tap target, including the tab bar and list rows. It is outside the scroll view, never over content, never inside a sheet or dialog, never near a reading or a card. One banner per screen. The AdMob "Ad" label is not overridden.
- The container reserves the adaptive banner height and **collapses** when the banner fails or Remove Banner Ads is owned.
- No ads on onboarding, question, draw, reading, Classic reading, out-of-readings, store, rewarded, settings, legal, crisis, report or the ATT pre-prompt. No interstitials. Rewarded ads are only ever user-started (S10, S11).

**Readings (05 §3, PR9, RC20)**
- The **disclaimer footer** (`disclaimerShort`: "For entertainment and self-reflection. Not professional advice.") sits on **every reading state**, AI and Classic, including loading and error.
- Every AI reading carries the **"AI-generated"** label in its header.
- The **Classic reading** (S32) shows a "Classic reading" label instead of "AI-generated", the disclaimer footer, and "Try an AI reading" only when the gate would allow one. It is visibly a complete reading, not a degraded one.
- "Report this reading" is in the overflow of every AI reading (S33).

**Consent (CS6, PR10, PR12)**
- AI consent names every AI provider in `ai.disclosedProviders` (v1: Anthropic and OpenAI; RC97, the provider is chosen by server config), and **"Allow AI readings" and "Not now" have equal visual weight** (same size, width, type and prominence). Declining never blocks the app; the free path (daily card, Classic, Learn, Journal) is stated on the screen.
- The ATT pre-prompt is neutral, with equal-weight options.
- *Review note:* the current S04 artboard gives both buttons the same width, height and label style, but "Allow" is filled ultramarine and "Not now" is outlined. REVIEW.md must either accept this as equal weight or give both the same treatment. The S10 "Not now" follows the same pattern.

**Paywall (04 §11, 05 §9.5)**
- S10 and S11 always show: a visible **close** (X, plus system back/swipe, immediately), **Restore purchases** (S11 and S20), **Terms** and **Privacy** links, and the consumable line "Readings don't expire and are kept for this app installation. They can't be restored with Restore Purchases."
- **No pre-selection:** each pack is its own buy button; no default-selected pack, no single "Continue".
- Price clarity: the localized store price is the full charge and the most legible number on the row; readings count and per-reading price shown. "Best value" only on the lowest computed per-reading price. No "Most popular".
- **No fake urgency:** no timers except the real free-reset countdown; no "limited offer", scarcity, strikethrough prices or fear copy. Decline copy is neutral ("Not now"); no confirmshaming.
- **No blurred or teased reading** behind the paywall; the paywall never appears after cards are revealed (it is evaluated on Begin, before the shuffle).
- **The free path is always visible:** "Your next free reading: in 5 h 12 min", plus the rewarded option when eligible (disabled options show their reason, never hidden).
- No prices or store in onboarding. Budget stops, `readingsPaused` and `dailyLimit` are never styled as a paywall.

**Crisis (S27)**
- Calm, no ads, no upsell, no balance chip, no reading CTA. Emergency number first, then local support lines with Call/Text actions that name the service in their semantics label.

**RTL (01 §13)**
- Full mirroring in `ar` via directional layout only. Spread layouts mirror x (`past` sits on the right). **Card art is never mirrored**; clocks and play icons never mirror; back arrows and chevrons do.

**Reversed (01 §12)**
- Shown by **180° rotation of the art and a text "Reversed" label** (vermilion badge). The card name and the badge are never rotated. Colour is never the only signal (suits have names or glyphs; status has an icon and a sentence).

**Art (05 §6.1, D15)**
- Symbolic, **not gory, not sexual, not child-oriented**. Death, the Devil and the Tower are symbolic; the Lovers is non-sexual. Store screenshot frames 1–3 contain no Death, Devil or Tower close-ups (CS13).

**Accessibility (01 §12)**
- Contrast: text ≥ 4.5:1; large text, icons and `border.focus` ≥ 3:1 — in both themes.
- Tap targets ≥ 48 × 48 dp. Focus ring: solid 2 px `color.border.focus`, 2 px offset.
- Layouts hold at 200% text scale (iOS AX5); reading text never truncates; spreads reflow to a vertical list above 1.5×.
- Every gesture has a button alternative ("Draw for me", "Reveal all"). Reading sections are headings. Live regions announce balance changes, "Reading ready" and errors.

**Store screenshots (CS13)** — real UI only; no ads, prices, paywall or countdowns; captions obey CS3.

---

## 6. Deliverables (01 §14.5)

| Deliverable | Format | Path / naming |
|---|---|---|
| Design tokens (light + dark) | W3C DTCG JSON, `$value`/`$type`, modes in `$extensions.taro.modes` | `docs/design/taro.tokens.json` |
| Brand book + component previews | Claude Design design-system artifact | https://claude.ai/artifact/C94hpvYCJKqrqYn5o8VnRb |
| Screen sources | Claude Design canvas (`*.dc.html` + `canvas.json` snapshot) | https://claude.ai/artifact/1d29x21T1WhcFhFaeo3QxL → `docs/design/screens/<Board>.dc.html` |
| Reference frames, every ★ state | PNG @2x (phone 780 × 1688; tablet 2064 × 2752) | `docs/design/screens/Sxx-<slug>/Sxx-<state>-<light\|dark>-<en\|ar>-<phone\|tablet>.png`, e.g. `S09-reading/S09-content-dark-ar-phone.png` |
| Per-screen spec | Markdown | `docs/design/screens/Sxx-<slug>/spec.md`: layout notes, components used (`components.md` names), motion, semantics/focus order |
| Component inventory | Markdown | `docs/design/components.md` |
| Card back | SVG master + PNG @3x | `docs/design/assets/card-back.svg`, `card-back@3x.png` |
| Spread layout diagrams × 6 | SVG (token colours, numbered positions) | `docs/design/assets/spreads/<spreadId>.svg` (`single`, `three_ppf`, `three_sao`, `relationship`, `two_paths`, `celtic_cross`) |
| Empty-state illustrations | SVG | `docs/design/assets/empty/journal.svg`, `empty/search.svg` |
| App icon | 1024 × 1024 PNG master (no alpha, iOS) + Android adaptive foreground/background layers (432 × 432) + monochrome layer | `docs/design/assets/icon/app-icon-1024.png`, `icon/android-foreground.png`, `icon/android-background.png`, `icon/android-monochrome.png` |
| Splash | SVG mark + background token | `docs/design/assets/splash/splash-mark.svg` |
| Store screenshot frame template | Claude Design board + PNG | `docs/design/assets/store/frame-template.*` (used in Phase 20; captions follow CS13) |
| Review checklist | Markdown, signed by the owner | `docs/design/REVIEW.md` |

Content samples attached to the design sessions: EN card texts for 5 cards, one sample AI reading per spread size (from `worker/test/fixtures/readings/`, swapped for Phase 8.6 staging outputs before S09 sign-off), the longest `de` strings (+40%), and `ar` and `ja` samples.
