# Phase 17: UI — Monetization, Journal, Learn, Settings & Data

**Status:** ⬜ Not Started
**Depends on:** Phase 16
**Parallel with:** Phase 18 (art and translations can land in parallel)

---

## Overview

This phase implements the designed UI for everything outside the core reading flow:
- the out-of-readings sheet, the store/paywall and the rewarded overlay;
- banners on the three allowed screens;
- the Journal list, entry, patterns and search;
- Learn (deck browser, card detail, spread guide, About);
- Settings and all their sub-screens, export/import, delete-all-data, FAQ, legal, and update-required.

The paywall and store screens get the compliance widget tests from 04 §11 and 05 (3.1.1 row).

**Output of this phase:**
- Designed views for S10–S12, S14–S26, S28–S30 in `apps/taro/lib/features/{paywall,journal,learn,settings,backup,help}/view/`.
- `BannerSlot` live on S05, S14 and S16, with the layout test proving it never intersects the scroll viewport.
- Goldens for every ★ state here, including the monetization matrix from 04 §15 (`de` added for store and sheet); ★ states also at `kTabletIpad13` and `kTabletAndroid` (06 §3, RC24), with content constrained to `layout.maxContentWidth`.

---

## Specs referenced

`01_PRODUCT.md` PR3, PR13, PR17, §7.1, §7.8–§7.11, §8 (S10–S12, S14–S26, S28–S30), §9.4–§9.6, §12. `04_MONETIZATION.md` MO7, MO9, MO11, MO13, MO16, MO18, §6.4, §8, §9.1, §11, §12 (visible edge-case states), §15 (widget + golden lists). `05_COMPLIANCE_STORE_ASO.md` CS10, CS15, 3.1.1/3.2.2/5.1.1 rows, §9.5 banned patterns. `02_ARCHITECTURE.md` §9.5–§9.6, §12, §14.3. `06_QUALITY_TESTING_CI.md` §2.5, §3. `00_DECISIONS.md` RC17, RC18, RC34, RC37, RC43, RC57–RC59, RC66, RC74, RC80, RC84.

---

## Sprint 17.1: Out-of-readings, store, rewarded (04 §11)

**Tasks:**
- [ ] S10 `OutOfReadingsSheet` (a modal bottom sheet; no banner):
  - "Your next free reading: in 5 h 12 min (at 00:00)" from server time;
  - the rewarded option **"Watch a short ad for +1 reading"**, visible but disabled with a reason when not eligible ("Available again in 4 min", "Daily limit reached — new ones tomorrow", "No ads available right now", "Ads unavailable"; RC34);
  - pack tiles and a "See all options" link to S11;
  - links to the daily card and Learn;
  - the footer with Terms, Privacy, the entertainment line and the consumable disclosure.
- [ ] S11 `StoreView`:
  - one button per pack showing the store-localized price, count and per-reading price, with **no pre-selection** and a computed "Best value" badge only (MO18);
  - the Remove Banner Ads tile (title "Remove Banner Ads", body "Remove banner ads — $X once. Optional reward videos stay available.", replaced by "Banner ads removed ✓" when owned; RC80);
  - "Restore purchases";
  - the rewarded option when eligible (RC34);
  - a visible close and working system back;
  - every state from 04 §11 and 01 §8.3 S11 (`pending` "Waiting for approval", `verificationDeferred` "Payment received — adding your readings…", `granted` toast, `storeUnavailable`, `productsFailed`, `offline`, `paidBlocked` neutral line "A refunded purchase was deducted", `purchasesBlocked(blocked|refundDebt)` with pack buttons hidden and the support contact (RC66));
  - the kill switch `store.enabled` shows only the free path.
- [ ] S12 `RewardedOverlay`: `loadingAd` (≤ `rewarded.loadTimeoutSec` = 10 s → `noFill` and the intent is cancelled, RC57), SDK `showing`, `granting` (polls up to 20 s, RC33), `granted` ("+1 reading added"), `grantDelayed` ("Your reading will appear shortly"), `dismissedEarly` (neutral copy, no penalty).
- [ ] After a grant opened from the gate, return to S07 with the same question and the kept draw. The user taps Begin again, and nothing auto-starts (01 §9.4).
- [ ] Widget tests (04 §15, 05 3.1.1):
  - close present in every state; Restore, Terms and Privacy links present; the non-restorable disclosure line present;
  - no pack pre-selected; no countdown except the real reset;
  - Semantics labels on prices ("10 readings for 4.99 US dollars, 50 cents per reading");
  - the free reading flow never shows an ad (05 3.2.2).
- [ ] Goldens (light/dark × en/ar + `de`): S10 with rewarded eligible, cooldown and cap reached, and `lowTrustLimited`; S11 `loading`, `ready`, `pending`, `verificationDeferred`, `storeUnavailable`, `purchasesBlocked`, and Remove Banner Ads owned; S12 `granted`. ★ states also at `kTabletIpad13` and `kTabletAndroid` (06 §3, RC24), including S10 and S11 (04 §15).

---

## Sprint 17.2: Banners (MO11, RC18)

**Tasks:**
- [ ] Place `BannerSlot` on S05 `home`, S14 `journal_list` and S16 `learn_library` only: a fixed-height `BannerContainer` below the scroll view and above the tab bar, collapsing on failure, offline or Remove Ads.
- [ ] Layout test: the banner rect ∩ scroll viewport = ∅ on all three screens at `kPhoneSmall` and text scale 2.0. Also assert a gap of **≥ 16 dp** (`space.adGap`, RC59) between the banner container and any tap target.
- [ ] Test the `ads.bannerMinCompletedReadings` gate: a first-session user sees no banner until their first reading completes (04 §8).
- [ ] Goldens: home with banner (light/dark × en/ar), with the fake banner view; also home with banner at `kTabletIpad13` and `kTabletAndroid` (RC24).

---

## Sprint 17.3: Journal (01 §7.8)

**Tasks:**
- [ ] S14 `JournalListView`:
  - month-grouped list; each row shows the date, spread icon, thumbnails, question or spread name, and favourite and note indicators;
  - filters (All, Readings, Daily cards, Favourites, spread, contains card X) and FTS search;
  - the Patterns card (≥ 5 entries; most-drawn cards over 30/90 days, suit balance chart, major/minor and reversed ratios; copy "patterns in your draws, not predictions");
  - states `empty` ("Your readings will live here" + Start a reading), `filteredEmpty`, `searchEmpty`, `storageError`;
  - a "Finish reading" badge for pending readings.
- [ ] S15 `JournalEntryView`: the S09 renderer + a notes editor (5,000 chars, autosave), delete confirmation + 5 s Undo snackbar, `pending` → resume into S08 `awaitingReading`, and `failed`.
- [ ] Goldens: S14 `empty` and `content` (+ `de` and `ja` per 01 §17.1); ★ states also at `kTabletIpad13` and `kTabletAndroid` (06 §3, RC24).

---

## Sprint 17.4: Learn (01 §7.9)

**Tasks:**
- [ ] S16 `DeckBrowserView`: a grid grouped as Major, Wands, Cups, Swords and Pentacles; search by localized name and keywords; `searchEmpty`; banner (RC18).
- [ ] S17 `CardDetailView`: art with tap-to-zoom (`zoomed`), name, arcana/suit/number, element and correspondences, an Upright/Reversed toggle, aspects, reflection questions, "In your journal: drawn N times" → filtered journal, prev/next.
- [ ] S18 `SpreadGuideView` + detail (layout diagram, position meanings, "Start this spread" → S07). S19 `AboutView` (the authored article + disclaimer).
- [ ] Goldens: S16 `content`; S17 `upright` (+ `de` and `ja`); ★ states also at `kTabletIpad13` and `kTabletAndroid` (06 §3, RC24).

---

## Sprint 17.5: Settings, data, help, legal

**Tasks:**
- [ ] S20 `SettingsView` with the groups from 01 §7.10:
  - Readings (reversals, haptics), Daily card (reminder), Appearance (theme, language), Purchases (Store, Remove Ads / "Ads removed ✓", Restore with its states);
  - Privacy (→ S23), Your data (Export, Import, Delete all data), Help (FAQ, Crisis resources, Contact support via mailto with app version, OS, locale and **Support ID** = the RC43 code, "Move readings from another device" showing the transfer code (RC84), Rate Taro);
  - About (Disclaimer, Terms, Privacy, Licenses, version/build, Support ID).
- [ ] S21 `LanguageView` (System + 12 locales; applies immediately; old readings keep their `contentLocale` label). S22 `ReminderSettingsView` (toggle + time picker using the 12/24 h device setting, `permissionDenied` → Open settings). S23 `PrivacyView`:
  - AI data sharing: view, grant or revoke; revoking blocks the next reading (06 §2.5);
  - "Ad privacy choices", shown only when UMP requires it;
  - Tracking (ATT status + open iOS Settings), shown on iOS only;
  - the Usage analytics toggle.
- [ ] S24 `ExportView` and S25 `ImportView` (pick → validating → `invalid(reason)` | `preview` "128 readings, 240 daily cards… Readings balance and purchases are not part of backups" → Merge/Replace (with a replace confirmation) → progress → `done(summary)`).
- [ ] S26 `DeleteDataView`: two-step confirm → deleting → `done` | `partial` (local data wiped, Worker deletion queued). The copy says "Your remaining readings and Remove Banner Ads are kept" (RC37, CS15).
- [ ] S28 `FaqView` (authored, offline), S29 `LegalView` (in-app browser for the terms/privacy URLs from config `legal.*` per CS10; disclaimer from ARB; `showLicensePage`), S30 `UpdateRequiredView` (blocking, store link only).
- [ ] Goldens: S20 `content`, S25 `invalid` and `preview`, S30 `content`; ★ states also at `kTabletIpad13` and `kTabletAndroid` (06 §3, RC24).

---

## Sprint 17.6: Golden regeneration & a11y pass

**Tasks:**
- [ ] Regenerate this phase's goldens in one commit (06 §3). Run the full golden suite on the reference runner.
- [ ] Accessibility guideline tests on all ★ screens here. Manual VoiceOver and TalkBack pass on the paywall and settings. Maximum Dynamic Type on the paywall *(MANUAL)*.
- [ ] The 12-locale smoke test covers every screen.

---

## Done when

- [ ] `apps/taro` ≥ 90% and `taro_ui` ≥ 90%. All goldens are green, including tablet-width goldens (`kTabletIpad13`, `kTabletAndroid`) for every ★ state of this phase (RC24). All integration flows are green on iOS (PR) and Android (nightly).
- [ ] The 04 §11 and 05 paywall widget tests pass. The banner layout test passes.
- [ ] Docs: `docs/ANALYTICS_EVENTS.md` (banner and paywall events verified), CHANGELOG.
- [ ] One commit: `feat(taro): Phase 17 — UI: monetization, journal, learn, settings & data`.

## Next phase

Phase 18: Deck Art & Full Localization.
