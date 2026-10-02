# Phase 17: UI — Monetization, Journal, Learn, Settings & Data

**Status:** ✅ Complete (2026-10-02) — manual screen-reader pass pending
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
- [x] S10 `OutOfReadingsSheet` (a modal bottom sheet; no banner): *(`features/paywall/view/out_of_readings_screen.dart`, `paywall_parts.dart`; `TaroModals.outOfReadings` → `TaroSheet.show`; `test/features/paywall/paywall_screens_test.dart` group "S10 out-of-readings view")*
  - "Your next free reading: in 5 h 12 min (at 00:00)" from server time;
  - the rewarded option **"Watch a short ad for +1 reading"**, visible but disabled with a reason when not eligible ("Available again in 4 min", "Daily limit reached — new ones tomorrow", "No ads available right now", "Ads unavailable"; RC34);
  - pack tiles and a "See all options" link to S11;
  - links to the daily card and Learn;
  - the footer with Terms, Privacy, the entertainment line and the consumable disclosure.
- [x] S11 `StoreView`: *(`features/paywall/view/store_screen.dart`; `paywall_screens_test.dart` group "S11 store view" + "S11 …" fakes tests)*
  - one button per pack showing the store-localized price, count and per-reading price, with **no pre-selection** and a computed "Best value" badge only (MO18);
  - the Remove Banner Ads tile (title "Remove Banner Ads", body "Remove banner ads — $X once. Optional reward videos stay available.", replaced by "Banner ads removed ✓" when owned; RC80);
  - "Restore purchases";
  - the rewarded option when eligible (RC34);
  - a visible close and working system back;
  - every state from 04 §11 and 01 §8.3 S11 (`pending` "Waiting for approval", `verificationDeferred` "Payment received — adding your readings…", `granted` toast, `storeUnavailable`, `productsFailed`, `offline`, `paidBlocked` neutral line "A refunded purchase was deducted", `purchasesBlocked(blocked|refundDebt)` with pack buttons hidden and the support contact (RC66));
  - the kill switch `store.enabled` shows only the free path.
- [x] S12 `RewardedOverlay`: *(`features/paywall/view/rewarded_screen.dart`, `TaroModals.rewarded` → `TaroDialog.show`; tests "S12 rewarded view", "S12 dismissedEarly / grantDelayed / noFill")* `loadingAd` (≤ `rewarded.loadTimeoutSec` = 10 s → `noFill` and the intent is cancelled, RC57), SDK `showing`, `granting` (polls up to 20 s, RC33), `granted` ("+1 reading added"), `grantDelayed` ("Your reading will appear shortly"), `dismissedEarly` (neutral copy, no penalty).
- [x] *(`test/features/paywall/return_to_question_test.dart`; S11 from S10 pops after the grant toast: "S11 from S10: a grant shows the toast and returns to S07")* After a grant opened from the gate, return to S07 with the same question and the kept draw. The user taps Begin again, and nothing auto-starts (01 §9.4).
- [x] Widget tests (04 §15, 05 3.1.1): *(`paywall_screens_test.dart`: "every state keeps close, restore, terms, privacy …", "every combination keeps the free path …", "the countdown is the only timer …", "ready: each pack is its own buy button, none pre-selected" (Semantics labels), "the rewarded ad is never auto-shown …")*
  - close present in every state; Restore, Terms and Privacy links present; the non-restorable disclosure line present;
  - no pack pre-selected; no countdown except the real reset;
  - Semantics labels on prices ("10 readings for 4.99 US dollars, 50 cents per reading");
  - the free reading flow never shows an ad (05 3.2.2).
- [x] *(`test/golden/s10_s12_paywall_golden_test.dart`, goldens `s10_*`, `s11_*`, `s12_rewarded_granted`)* Goldens (light/dark × en/ar + `de`): S10 with rewarded eligible, cooldown and cap reached, and `lowTrustLimited`; S11 `loading`, `ready`, `pending`, `verificationDeferred`, `storeUnavailable`, `purchasesBlocked`, and Remove Banner Ads owned; S12 `granted`. ★ states also at `kTabletIpad13` and `kTabletAndroid` (06 §3, RC24), including S10 and S11 (04 §15).

---

## Sprint 17.2: Banners (MO11, RC18)

**Tasks:**
- [x] *(S05 `home_screen.dart`, S14 `journal_list_screen.dart`, S16 `deck_browser_screen.dart` in the scaffold's bottom slot; `AdMobBannerSlotView` fires `ad_banner_impression` / `ad_banner_failed`)* Place `BannerSlot` on S05 `home`, S14 `journal_list` and S16 `learn_library` only: a fixed-height `BannerContainer` below the scroll view and above the tab bar, collapsing on failure, offline or Remove Ads.
- [x] *(`test/common/banner_layout_test.dart`)* Layout test: the banner rect ∩ scroll viewport = ∅ on all three screens at `kPhoneSmall` and text scale 2.0. Also assert a gap of **≥ 16 dp** (`space.adGap`, RC59) between the banner container and any tap target.
- [x] *(`banner_layout_test.dart` group "ads.bannerMinCompletedReadings")* Test the `ads.bannerMinCompletedReadings` gate: a first-session user sees no banner until their first reading completes (04 §8).
- [x] *(`s05_home_content_{free,credits,zero}` render `GoldenBannerSlotView`, ★ incl. tablets, `test/golden/s05_home_golden_test.dart`)* Goldens: home with banner (light/dark × en/ar), with the fake banner view; also home with banner at `kTabletIpad13` and `kTabletAndroid` (RC24).

---

## Sprint 17.3: Journal (01 §7.8)

**Tasks:**
- [x] S14 `JournalListView`: *(`features/journal/view/journal_list_screen.dart`, `journal_dialogs.dart`, `controller/journal_content.dart`; `test/features/journal/view/journal_list_screen_test.dart`)*
  - month-grouped list; each row shows the date, spread icon, thumbnails, question or spread name, and favourite and note indicators;
  - filters (All, Readings, Daily cards, Favourites, spread, contains card X) and FTS search;
  - the Patterns card (≥ 5 entries; most-drawn cards over 30/90 days, suit balance chart, major/minor and reversed ratios; copy "patterns in your draws, not predictions");
  - states `empty` ("Your readings will live here" + Start a reading), `filteredEmpty`, `searchEmpty`, `storageError`;
  - a "Finish reading" badge for pending readings.
- [x] S15 `JournalEntryView`: *(`features/journal/view/journal_entry_screen.dart`; `JournalEntryController.writeAbout` / `share`; S09 "Write about this" → `?prompt=`; `test/features/journal/view/journal_entry_screen_test.dart`, `journal_entry_controller_test.dart`)* the S09 renderer + a notes editor (5,000 chars, autosave), delete confirmation + 5 s Undo snackbar, `pending` → resume into S08 `awaitingReading`, and `failed`.
- [x] Goldens: S14 `empty` and `content` (+ `de` and `ja` per 01 §17.1); ★ states also at `kTabletIpad13` and `kTabletAndroid` (06 §3, RC24). *(`test/golden/s14_s15_journal_golden_test.dart`: `s14_journal_{content,empty}` incl. a11y, plus `s15_journal_entry_content`)*

---

## Sprint 17.4: Learn (01 §7.9)

**Tasks:**
- [x] *(`test/features/learn/learn_screens_test.dart` "S16 deck browser view" + "S16: search, open a card, spreads guide, about"; `BannerSlot(BannerScreen.learnLibrary)`)* S16 `DeckBrowserView`: a grid grouped as Major, Wands, Cups, Swords and Pentacles; search by localized name and keywords; `searchEmpty`; banner (RC18).
- [x] *(`test/features/learn/learn_screens_test.dart` "S17 card detail view" + "S17: toggle, zoom, neighbours, journal, retry"; element shown, astrology correspondence left out per 05 "no astrology feature")* S17 `CardDetailView`: art with tap-to-zoom (`zoomed`), name, arcana/suit/number, element and correspondences, an Upright/Reversed toggle, aspects, reflection questions, "In your journal: drawn N times" → filtered journal, prev/next.
- [x] *(`test/features/learn/learn_screens_test.dart` "S18 spread guide view", "S19 about view" and the routed S18/S19 tests)* S18 `SpreadGuideView` + detail (layout diagram, position meanings, "Start this spread" → S07). S19 `AboutView` (the authored article + disclaimer).
- [x] *(`test/golden/s16_s19_learn_golden_test.dart`: `s16_learn_content`, `s17_card_detail_upright` incl. `de`/`ja`, tablets, a11y)* Goldens: S16 `content`; S17 `upright` (+ `de` and `ja`); ★ states also at `kTabletIpad13` and `kTabletAndroid` (06 §3, RC24).

---

## Sprint 17.5: Settings, data, help, legal

**Tasks:**
- [x] S20 `SettingsView` with the groups from 01 §7.10:
  - Readings (reversals, haptics), Daily card (reminder), Appearance (theme, language), Purchases (Store, Remove Ads / "Ads removed ✓", Restore with its states);
  - Privacy (→ S23), Your data (Export, Import, Delete all data), Help (FAQ, Crisis resources, Contact support via mailto with app version, OS, locale and **Support ID** = the RC43 code, "Move readings from another device" showing the transfer code (RC84), Rate Taro);
  - About (Disclaimer, Terms, Privacy, Licenses, version/build, Support ID).
- [x] S21 `LanguageView` (System + 12 locales; applies immediately; old readings keep their `contentLocale` label). S22 `ReminderSettingsView` (toggle + time picker using the 12/24 h device setting, `permissionDenied` → Open settings). S23 `PrivacyView`:
  - AI data sharing: view, grant or revoke; revoking blocks the next reading (06 §2.5);
  - "Ad privacy choices", shown only when UMP requires it;
  - Tracking (ATT status + open iOS Settings), shown on iOS only;
  - the Usage analytics toggle.
- [x] S24 `ExportView` and S25 `ImportView` (pick → validating → `invalid(reason)` | `preview` "128 readings, 240 daily cards… Readings balance and purchases are not part of backups" → Merge/Replace (with a replace confirmation) → progress → `done(summary)`).
- [x] S26 `DeleteDataView`: two-step confirm → deleting → `done` | `partial` (local data wiped, Worker deletion queued). The copy says "Your remaining readings and Remove Banner Ads are kept" (RC37, CS15).
- [x] S28 `FaqView` (authored, offline), S29 `LegalView` (in-app browser for the terms/privacy URLs from config `legal.*` per CS10; disclaimer from ARB; `showLicensePage`), S30 `UpdateRequiredView` (blocking, store link only).
- [x] Goldens: S20 `content`, S25 `invalid` and `preview`, S30 `content`; ★ states also at `kTabletIpad13` and `kTabletAndroid` (06 §3, RC24).

*Evidence (17.5):* `settings_screen.dart`, `language_screen.dart`, `reminder_settings_screen.dart`, `privacy_screen.dart`, `delete_data_screen.dart` (`features/settings/view/`), `export_screen.dart`, `import_screen.dart` (`features/backup/view/`), `faq_screen.dart`, `legal_screen.dart`, `update_required_screen.dart`; tests `test/features/settings/settings_screens_test.dart`, `test/features/backup/backup_screens_test.dart`, `test/features/help/help_legal_screens_test.dart`, `test/features/update/view/update_required_screen_test.dart`, `test/services/links/platform_url_launcher_test.dart`; goldens `test/golden/s20_settings_golden_test.dart`, `s25_import_golden_test.dart`, `s30_update_required_golden_test.dart`.

---

## Sprint 17.6: Golden regeneration & a11y pass

**Tasks:**
- [x] *(`melos run golden:update` on this reference Mac 2026-10-02: only the 5 `product_offer_tile` PNGs changed beyond the sprint goldens; full golden suite green in `tools/verify.sh`)* Regenerate this phase's goldens in one commit (06 §3). Run the full golden suite on the reference runner.
- [ ] *(automated part done: `accessibility: true` goldens on S10 `content`, S11 `loading`/`ready`, S12 `granted`, S14 `empty`/`content`, S16 `content`, S17 `upright`, S20 `content`, S25 `invalid`/`preview`, S30 `content`; MANUAL screen-reader and Dynamic Type pass pending)* Accessibility guideline tests on all ★ screens here. Manual VoiceOver and TalkBack pass on the paywall and settings. Maximum Dynamic Type on the paywall *(MANUAL)*.
- [x] *(`test/l10n/locale_smoke_test.dart` iterates every `screenBuilders` key, S01–S33, × 12 locales)* The 12-locale smoke test covers every screen.

---

## Done when

- [x] *(`tools/verify.sh` full 2026-10-02: apps/taro 99.52 %, taro_ui 99.97 %, every file ≥ 70 %; 2706 app tests incl. goldens green; `melos run test:integration` on the iOS 26.2 iPhone 16e simulator: 19 flows passed, staging smoke skipped; `flutter build ios --simulator --flavor dev` OK; Android nightly not run locally)* `apps/taro` ≥ 90% and `taro_ui` ≥ 90%. All goldens are green, including tablet-width goldens (`kTabletIpad13`, `kTabletAndroid`) for every ★ state of this phase (RC24). All integration flows are green on iOS (PR) and Android (nightly).
- [x] *(`test/features/paywall/paywall_screens_test.dart`, `test/common/banner_layout_test.dart`; `BannerSlot` used only in `home_screen.dart`, `journal_list_screen.dart`, `deck_browser_screen.dart`)* The 04 §11 and 05 paywall widget tests pass. The banner layout test passes.
- [x] *(ANALYTICS_EVENTS "Verified in Phase 17.6" line; CHANGELOG Phase 17.6 + worker CHANGELOG "best value")* Docs: `docs/ANALYTICS_EVENTS.md` (banner and paywall events verified), CHANGELOG.
- [ ] One commit: `feat(taro): Phase 17 — UI: monetization, journal, learn, settings & data`.

## Next phase

Phase 18: Deck Art & Full Localization.
