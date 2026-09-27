# Phase 13: App Shell, State Machines & Flows (skeleton UI)

**Status:** ⬜ Not Started
**Depends on:** Phases 5, 11, 12. The Worker API from Phases 6–8 is used through fakes; staging smoke comes at the end.
**Parallel with:** Phase 14 (Claude Design can start once Sprint 13.4 freezes the state unions)

---

## Overview

This phase wires the whole app **behind a skeleton UI**. It builds:
- bootstrap and the composition root;
- the Riverpod provider graph;
- go_router with the tab shell, guards and deep links;
- app-wide controllers (balance, entitlement, consent, config, connectivity);
- the `SyncCoordinator` (launch, resume, reset timer);
- a controller with a sealed state union for **every** screen and state in 01 §8.3;
- the `taro_l10n` package with English ARB strings.

Screens render with plain placeholder widgets built from the minimal `taro_ui` state kit. The real visual design lands in Phases 15–17. Because every state is a tested controller state now, the UI phases only need to add visuals and goldens, and Claude Design gets a complete state inventory.

The fake-backed patrol integration flows F1–F7 pass at the end of this phase, which proves the product works before it looks right.

**Output of this phase:**
- `apps/taro/lib/{bootstrap,di,routing,app_state,lifecycle,common,features}/**` per 02 §2.2.
- `packages/taro_l10n` with `app_en.arb` (all UI strings, ICU plurals). The other 11 ARB files exist with EN placeholders marked `x-translate` (translated in Phase 18).
- `docs/design/STATE_INVENTORY.md`, generated from the state unions, as the input to Phase 14.
- `apps/taro/integration_test/flows/*_test.dart` (06 §4) green on the iOS simulator with fakes.

---

## Specs referenced

`02_ARCHITECTURE.md` AR2–AR4, AR8, AR12–AR14, AR17, §2.1, §7, §8, §9, §10, §11, §19. `01_PRODUCT.md` PR3–PR13, PR16–PR19, §7 (all), §8 (all), §9 (F1–F7), §12, §13, §17. `04_MONETIZATION.md` MO11–MO13, §5.5, §6.5, §11 (states), §12. `05_COMPLIANCE_STORE_ASO.md` CS6, CS7, CS15, §3 (ARB keys). `06_QUALITY_TESTING_CI.md` §2.5, §3.1, §4. `00_DECISIONS.md` RC17–RC21, RC31, RC34, RC37, RC44, RC47, RC48, RC50, RC51, RC58, RC64, RC66, RC68, RC71–RC77.

---

## Sprint 13.1: Bootstrap, DI, flavors

**Tasks:**
- [ ] `bootstrap/taro_environment.dart`: the `TaroEnvironment` interface from 02 §9.1 (`initFirebase`, `openDatabases`, `secureStore`, `buildOverrides`, `installErrorHandlers`, `runApp`) and `ProductionEnvironment` (≤ 20 lines of pure delegation, RC76).
- [ ] `bootstrap/bootstrap.dart` (`bootstrap(TaroEnvironment env)`), implementing 02 §9.1:
  - `env.initFirebase()`, then analytics consent set to all-denied (RC68);
  - `env.installErrorHandlers(crashReporter)`;
  - `env.openDatabases()` (journal + device, RC75);
  - `InstallRepository.getOrCreate()`;
  - load the caches (config, balance, entitlement, settings, consent) for a correct first frame offline;
  - build the `ProviderContainer` from `env.buildOverrides(...)`;
  - `env.runApp(UncontrolledProviderScope(...))`;
  - post-frame `SyncCoordinator.run(launch)`.
  - `main_<flavor>.dart` = `void main() => bootstrap(ProductionEnvironment(Flavor.x));` (the only excluded app files, RC16).
- [ ] `di/providers.dart`: one provider per port, each throwing `UnimplementedError` until overridden. `di/overrides_prod.dart` and `overrides_dev.dart` wire the adapters; `overrides_test.dart` is selected when `TARO_ENV=test` (06 §4) and exposes a `TestControlPort` (FakeClock control, fake Worker scripting). Riverpod automatic retry is **off** globally (02 §7).
- [ ] `test/bootstrap/bootstrap_test.dart` with `FakeTaroEnvironment` covers `bootstrap/` fully: happy path, the S01 `storageError` branch, the offline first frame, and the prod assertions. `ProductionEnvironment` is tested with fake SDK entry points (RC76).
- [ ] `test/helpers/pump_app.dart`: `TaroFakes` (every fake from `taro_testing` with sane defaults, `toOverrides() → List<Override>`) and `pumpTaro(tester, {TaroFakes? fakes, Locale, ThemeMode, textScale, Size})` (RC77). `taro_testing` itself stays Riverpod-free.
- [ ] Startup assertions: `IapCatalog.validate()`, and in prod `SeededRandomSource` and `DebugAttestationService` are unreachable (02 §15).

---

## Sprint 13.2: App state & sync (AR8, AR14)

**Tasks:**
- [ ] `app_state/`:
  - `balance_controller.dart` (`StreamNotifier<CreditBalance?>`, stale flag, `syncStatus`);
  - `entitlement_controller.dart`;
  - `consent_controller.dart` (AI consent version vs `ai.consentVersion`; UMP/ATT from `ConsentOrchestrator`);
  - `remote_config_controller.dart` (`min version` → update-required redirect);
  - `connectivity_controller.dart`;
  - `settings_controller.dart`.
- [ ] `app_state/sync_coordinator.dart` (02 §9.2), running on launch, resume, the reset timer and connectivity regained:
  - coalesce runs (join an in-flight run; skip only if the last success was < `balance.resumeSyncThrottleSec` (30 s) ago, the local date is unchanged and `now < resetsAt`);
  - steps, each tolerating failure: config → timezone check (`PUT …/timezone`, 409 tolerated) → balance → `PurchaseCoordinator.drainOutbox()` → resume pending readings (`GET /v1/readings/{clientReadingId}`) → flush `pending_acks` (RC51) → `DataDeletionGateway` retry queue → reminder reschedule → attestation warm-up (Android) → `RemoveAdsEntitlement.refresh`;
  - `Stream<SyncStatus>`.
- [ ] `lifecycle/app_lifecycle_observer.dart` + `reset_timer.dart` (fires at `resetsAt + 5 s` while foregrounded; cancelled on pause).
- [ ] Tests with `ProviderContainer` + `FakeClock` (06 §2.5 "Resume re-sync"):
  - resume after `advance(1 day)` → exactly one balance sync;
  - same-day resume is idempotent;
  - resume during an in-flight sync joins it;
  - a timezone change triggers one PUT;
  - a 409 keeps the server boundary;
  - a stale balance response (lower or equal `ledgerVersion` with older `serverTime`) never overwrites a newer one (RC67).

---

## Sprint 13.3: Routing & deep links (AR4, RC17)

**Tasks:**
- [ ] `routing/routes.dart`: the 01 §8.1 route table (S01–S33, incl. S32 `/reading/:id?mode=classic` and the S33 modal) with a `StatefulShellRoute` for the 4 tabs Today, Journal, Learn and Settings (RC17), and modal routes for S10 and S12.
- [ ] `routing/guards.dart` (pure functions): `upgradeGuard` (S30) → `onboardingGuard` (resume at the persisted step, 01 §7.12) → `deepLinkPolicy`.
- [ ] `routing/deep_link_policy.dart`: allowlist `taro://daily`, `taro://reading/new?spread=`, `taro://journal/{id}`, `taro://learn/card/{cardId}`, `taro://store`, plus Universal Links / App Links on `https://taro.vshyrochuk.com/app/*`. Links during onboarding are queued until Home. **No link starts a draw, spends a credit or triggers a purchase** (02 §8.2).
- [ ] iOS Associated Domains entitlement and the Android intent filters with `autoVerify`. The AASA / `assetlinks.json` hosting task is in Phase 20.
- [ ] Back behaviour (01 §9.1): S08 asks for confirmation after the first pick; S09 goes back to Home.
- [ ] Tests: the guards table, deep-link sanitize (malicious and unknown links → `/home`), and the notification-tap route.

---

## Sprint 13.4: Feature controllers & state unions (01 §8.3, PR17)

One `Notifier`/`AsyncNotifier` per screen with an `@freezed sealed` state union. Every state listed in 01 §8.3 (plus the RC20 Classic states) has a controller test and a skeleton widget test.

**Tasks:**
- [ ] `features/onboarding/`: `OnboardingController` (welcome pages, disclaimer ack, step persistence) and `AiConsentController` (S04 `undecided|granted|declined`, origin-aware return, versioned; RC21). Consent orchestration is triggered after onboarding (RC19).
- [ ] Feature folders per 02 §2.2: `onboarding/`, `consent/`, `home/`, `daily_card/`, `reading/`, `paywall/`, `journal/`, `learn/`, `settings/`, `backup/`, `help/`, `legal/`, `update/` (and `debug/`, non-prod only, Phase 12).
- [ ] `features/home/`: `HomeController` (S05: `loading`, `content` variants, `firstRun`, `balanceStale`, `deviceUnverified`, daily-card drawn or not, banner states, `updateAvailable` once per version (RC73)); `features/daily_card/`: `DailyCardController` (S13: `notDrawn`, `revealing`, `drawn`, `noteEditing`, `reminderOffer` shown once; "Reflect deeper" → S07 with the card pre-set, PR4).
- [ ] `features/reading/`:
  - `SpreadPickerController` (S06, hides spreads disabled by config);
  - `QuestionController` (S07: `editing`, `checking`, `offline`, `consentRequired`, `deviceUnverified`, `readingsPaused` (RC47, with the `freePaused` copy variant, RC64), `aiUnavailableRegion`, `outOfReadings`, `dailyLimitReached`, `lowTrustLimited` (RC74), `rephrase`, `refused(category)`, `rateLimited`), which evaluates `ReadingGate` on **Begin** and then takes the **pre-draw hold** before any draw (PR5, RC44, RC50): hold 402 → S10, 503 → S31, 429 `dailyLimit` → `dailyLimitReached`;
  - `DrawController` (S08: `shuffling`, `picking`, `revealing` (only while the hold has ≥ 120 s left; renew otherwise), `awaitingReading`, `slowReading` (20 s), `generationFailed` (retry with the same cards and `clientReadingId`; the Worker runs a new attempt, PR6, RC49), `holdLost` → S10 with the cards face-down (RC48, RC50), `deliveryExpired` (RC51), `crisis` → S27, reduced-motion variant); on success it persists, then acks;
  - `ReadingResultController` (S09: `content`, `ratingGiven`, `sharing`, `loadingFromStorage`; report action → S33; rate-app trigger);
  - `ClassicReadingController` (S32, flow F8, RC20/RC71: static meanings per position from `taro_content`, no hold, no Worker call, saved with `status: classic`; no banner or rate-app credit; `classic_reading_started/completed` events);
  - `ReportReadingController` (S33, RC72: `editing`, `submitting`, `submitted`, `failed`, `offline`, `rateLimited`, `alreadyReported`; disclosure; `reading_reported{reason}`; sets the local `reported` flag).
- [ ] `features/paywall/` (MO13, 04 §11):
  - `OutOfReadingsController` (S10: rewarded available/capped/cooldown/disabled/failed; packs loading/loaded/unavailable/`purchasesBlocked`; `lowTrustLimited` copy; next-free countdown from server time); after a grant it returns to S07 with Begin enabled and nothing auto-starts (RC58);
  - `StoreController` (S11: `loading`, `ready`, `storeUnavailable`, `productsFailed`, `purchasing(productId)`, `pending(productId)`, `verifying`, `verificationDeferred`, `granted`, `failed(reason)`, `cancelled`, `offline`, `removeAdsOwned`, `paidBlocked` notice (03 §5.1), `purchasesBlocked(blocked|refundDebt)` (RC66), kill switch `store.enabled`);
  - `RewardedController` (S12: `loadingAd`, `noFill`, `showing`, `granting`, `granted`, `grantDelayed`, `dismissedEarly`; cancels the intent on `noFill`/failure/early dismissal, RC57).
- [ ] `features/journal/`: `JournalListController` (S14: `loading`, `empty`, `content`, `filteredEmpty`, `searchEmpty`, `storageError`, patterns card when ≥ 5 entries, filters and FTS search) and `JournalEntryController` (S15: `content`, `pending` → finish reading, `failed`, `deleted` + 5 s undo, 5,000-char note autosave).
- [ ] `features/learn/`: `DeckBrowserController` (S16: grid by arcana/suit, search), `CardDetailController` (S17: upright, reversed, zoomed, drawn-N-times link, prev/next), `SpreadGuideController` (S18), `AboutController` (S19).
- [ ] `features/settings/`:
  - `SettingsController` (S20, including restore in progress, success or failure; RC43 Support ID in About; "Move readings from another device" → re-verify past purchases and show the transfer code, RC84);
  - `LanguageController` (S21, in-app override);
  - `ReminderSettingsController` (S22, `permissionDenied` → open settings);
  - `PrivacyController` (S23: AI consent grant/revoke, UMP privacy options when required, ATT status + open iOS Settings, analytics toggle);
  - `DeleteDataController` (S26: `confirm1`, `confirm2`, `deleting`, `done`, `partial`; RC37: keeps the install ID, credits and Remove Ads, and says so).
- [ ] `features/backup/`: `ExportController` (S24: `preparing`, `shareSheetOpen`, `done`, `failed`) and `ImportController` (S25: `picking`, `validating`, `invalid(reason)`, `preview` (with "balance not included" copy), `confirmReplace`, `importing(progress)`, `done(summary)`, `failed`).
- [ ] `features/help/`: `CrisisResourcesController` (S27; the device region is never sent; offline), `FaqController` (S28), `LegalController` (S29: disclaimer, terms, privacy, licenses via `showLicensePage`), `UpdateRequiredController` (S30).
- [ ] Share (PR19): `ShareReadingUseCase` builds text with localized card names, the summary, an excerpt and the disclaimer line, with an opt-in "include my question" toggle.
- [ ] Analytics: fire every 01 §15 and 04 §14 event from its controller. `check_analytics_events.py` is green. Tests assert the events and params with `FakeAnalyticsService`.
- [ ] `tools/gen_state_inventory.dart` → `docs/design/STATE_INVENTORY.md`: screen → route → states → ★ golden flag → banner allowed. This is the input to Phase 14.

---

## Sprint 13.5: Skeleton UI, l10n, common widgets

**Tasks:**
- [ ] `taro_l10n`: `l10n.yaml` per 02 §11. Write `app_en.arb` with every UI string, including the 05 §3 compliance keys (`disclaimerShort`, `disclaimerOnboarding*`, `aiConsent*`, `aiLabel`, `refusalGeneric`, `crisis*`, `reportReadingTitle`), every error `code` → message key (RC5), the 6 reminder variants, suggestion chips, the spread and position names (`spread_{id}_pos_{pos}_name/_desc`), IAP disclosure lines (04 §11), and ICU plurals. The 11 other ARB files are copied with an `x-translate` marker so `check_l10n.py` passes in development mode.
- [ ] Minimal `taro_ui` state kit (to be restyled in Phase 15): `TaroLoadingView`, `TaroEmptyView`, `TaroErrorView(kind, onRetry)`, `TaroOfflineBanner`, `TaroInlineNotice`, `TaroScaffold` (01 §8.2). Use Material defaults and **no raw values** (temporary token stubs in `taro_ui/lib/src/tokens/stub_tokens.dart`, replaced in Phase 15).
- [ ] `common/`: `BalanceChip` (the 01 §7.1 sync states), `BannerSlot(screenId)` (`BannerPolicy`, placed outside the scroll view; RC18), `DisclaimerFooter` (rendered on every reading state, including loading and error; 05 §3), `OfflineBanner`, `FailureMessage.of(context, failure)`.
- [ ] One skeleton screen per S-ID, rendering each state with the kit plus plain `Text` from ARB. Widget tests for **every state** (PR17), including:
  - no `CardFace` in the tree before the gate allows (06 §2.5);
  - `DisclaimerFooter` present in every S09 state;
  - no `BannerSlot` on the reading screens;
  - equal-weight consent buttons;
  - paywall has close, restore, terms, privacy, the non-restorable line and no pre-selected pack (04 §11, 05 3.1.1 row).
- [ ] 12-locale smoke test (06 §3.1) against skeleton screens, and the RTL `Directionality` assertion for `ar`.

---

## Sprint 13.6: Integration flows (fakes) & staging smoke

**Tasks:**
- [ ] patrol + `integration_test` flows (RC13), each with `TARO_ENV=test`:
  - `first_launch_free_reading_test` (F1 + F2: hold → draw → reading → ack; no analytics event before consent resolves, RC68);
  - `out_of_credits_purchase_test` (F3: hold 402 → S10 before any draw → purchase; finish only after the grant; back to S07, Begin, hold, reading);
  - `hold_lost_test` (renewal 402 after the pick → S10 with cards face-down → grant → same cards reused, RC48/RC50);
  - `classic_reading_test` (F8, RC71);
  - `rewarded_ad_test`;
  - `remove_ads_restore_test` (F4);
  - `daily_reset_resume_test` (with FakeClock);
  - `export_import_test` (F5);
  - `reading_failure_refund_test` (F6);
  - `consent_denied_test` (F7 + UMP/ATT denied + Classic reading, RC20);
  - `rtl_locale_test`;
  - `reinstall_same_install_id_test`;
  - `os_restore_test` (journal DB present, device DB + secure storage empty → new registration, consent re-asked, no outbox replay, RC75);
  - `timezone_change_test`.
- [ ] `integration_test/staging/smoke_test.dart`: the real staging Worker, register, balance, one free reading with the debug attestation bypass. Manual dispatch only (06 §4).
- [ ] Performance baseline: `integration_test/perf/cold_start_test.dart` and a timeline summary for the draw screen (02 §17). Record the numbers; the budgets are enforced in Phase 19.

---

## Done when

- [ ] `apps/taro`, `taro_l10n` and `taro_ui` (kit) are each ≥ 90%, and `check_coverage.py` is green. The integration flows are green on the iOS simulator (PR) and the Android emulator (nightly).
- [ ] `docs/design/STATE_INVENTORY.md` is generated and committed.
- [ ] `check_architecture.dart` is green: features never import `taro_data`, `taro_services` (except the `presentation.dart` barrel for `BannerSlot`) or vendor SDKs.
- [ ] Docs: `docs/ARCHITECTURE.md` (routing, state, sync), `docs/ANALYTICS_EVENTS.md`, `docs/TESTING.md` (integration harness), CHANGELOG.
- [ ] One commit: `feat(taro): Phase 13 — App shell, state machines & flows`.

## Next phase

Phase 14: Claude Design Handoff (it can already have started from the Sprint 13.4 inventory).
