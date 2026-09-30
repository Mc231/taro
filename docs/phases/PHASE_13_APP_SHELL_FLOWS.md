# Phase 13: App Shell, State Machines & Flows (skeleton UI)

**Status:** ✅ Complete (2026-09-30) — pending: the staging smoke run (owner, needs the debug attestation token), the phase commit. Follow-ups for later phases: a launcher port (store link on S30, call/text on S27, mail/settings links on S22/S23/S28/S29), a text-share port (share is a `.txt` file now), crash custom keys and a screen-view observer.
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
- the app's l10n folder `apps/taro/lib/l10n/` with English ARB strings (RC95: a folder, not a package).

Screens render with plain placeholder widgets built from the minimal `taro_ui` state kit. The real visual design lands in Phases 15–17. Because every state is a tested controller state now, the UI phases only need to add visuals and goldens, and Claude Design gets a complete state inventory.

The fake-backed patrol integration flows F1–F7 pass at the end of this phase, which proves the product works before it looks right.

**Output of this phase:**
- `apps/taro/lib/{bootstrap,di,routing,app_state,lifecycle,common,features}/**` per 02 §2.2.
- `apps/taro/lib/l10n/arb/` with `app_en.arb` (all UI strings, ICU plurals), configured by `apps/taro/l10n.yaml`. The other 11 ARB files exist with EN placeholders marked `x-translate` (translated in Phase 18).
- `docs/design/STATE_INVENTORY.md`, generated from the state unions, as the input to Phase 14.
- `apps/taro/integration_test/flows/*_test.dart` (06 §4) green on the iOS simulator with fakes.

---

## Specs referenced

`02_ARCHITECTURE.md` AR2–AR4, AR8, AR12–AR14, AR17, §2.1, §7, §8, §9, §10, §11, §19. `01_PRODUCT.md` PR3–PR13, PR16–PR19, §7 (all), §8 (all), §9 (F1–F7), §12, §13, §17. `04_MONETIZATION.md` MO11–MO13, §5.5, §6.5, §11 (states), §12. `05_COMPLIANCE_STORE_ASO.md` CS6, CS7, CS15, §3 (ARB keys). `06_QUALITY_TESTING_CI.md` §2.5, §3.1, §4. `00_DECISIONS.md` RC17–RC21, RC31, RC34, RC37, RC44, RC47, RC48, RC50, RC51, RC58, RC64, RC66, RC68, RC71–RC77, RC95.

---

## Sprint 13.1: Bootstrap, DI, flavors

**Tasks:**
- [x] `bootstrap/taro_environment.dart`: the `TaroEnvironment` interface from 02 §9.1 (`initFirebase`, `openDatabases`, `secureStore`, `buildOverrides`, `installErrorHandlers`, `runApp`) and `ProductionEnvironment` (≤ 20 lines of pure delegation, RC76). Evidence: `lib/bootstrap/taro_environment.dart` (`ProductionEnvironment` delegates to `PlatformHooks`); `test/bootstrap/taro_environment_test.dart`.
- [x] `bootstrap/bootstrap.dart` (`bootstrap(TaroEnvironment env)`), implementing 02 §9.1: Evidence: `lib/bootstrap/bootstrap.dart`, `main_{dev,staging,prod}.dart`; `test/bootstrap/bootstrap_test.dart` (`happy path: consent denied first, Home, then the launch sync`, `offline first frame…`). Deviation: `buildOverrides` is async (the cached repositories open asynchronously); consent mode and crash handlers are set right after the container is built (the adapters live in the graph).
  - `env.initFirebase()`, then analytics consent set to all-denied (RC68);
  - `env.installErrorHandlers(crashReporter)`;
  - `env.openDatabases()` (journal + device, RC75);
  - `InstallRepository.getOrCreate()`;
  - load the caches (config, balance, entitlement, settings, consent) for a correct first frame offline;
  - build the `ProviderContainer` from `env.buildOverrides(...)`;
  - `env.runApp(UncontrolledProviderScope(...))`;
  - post-frame `SyncCoordinator.run(launch)`.
  - `main_<flavor>.dart` = `void main() => bootstrap(ProductionEnvironment(Flavor.x));` (the only excluded app files, RC16).
- [x] `di/providers.dart`: one provider per port, each throwing `UnimplementedError` until overridden. `di/overrides_prod.dart` and `overrides_dev.dart` wire the adapters; `overrides_test.dart` is selected when `TARO_ENV=test` (06 §4) and exposes a `TestControlPort` (FakeClock control, fake Worker scripting). Riverpod automatic retry is **off** globally (02 §7). Evidence: `lib/di/{providers,app_graph,overrides_prod,overrides_dev}.dart`, `bootstrap.dart` `noProviderRetry`; `test/di/providers_test.dart`. Deviation: the test graph is `test/helpers/test_environment.dart` (`FakeTaroEnvironment`, `TestControlPort`), because lib code cannot import the `taro_core` fakes.
- [x] `test/bootstrap/bootstrap_test.dart` with `FakeTaroEnvironment` covers `bootstrap/` fully: happy path, the S01 `storageError` branch, the offline first frame, and the prod assertions. `ProductionEnvironment` is tested with fake SDK entry points (RC76). Evidence: `test/bootstrap/{bootstrap,taro_environment,startup}_test.dart` (incl. `a storage failure shows S01 storageError; retry recovers`, `a prod graph with the CSPRNG boots`).
- [x] `test/helpers/pump_app.dart`: `TaroFakes` (every fake from `packages/taro_core/test/fakes/` with sane defaults, `toOverrides() → List<Override>`) and `pumpTaro(tester, {TaroFakes? fakes, Locale, ThemeMode, textScale, Size})` (RC77, RC95). The `taro_core` fakes themselves stay Riverpod-free. Evidence: `test/helpers/pump_app.dart` (`TaroFakes.toOverrides`, `pumpTaro`), `test/helpers/pump_app_test.dart`.
- [x] Startup assertions: `IapCatalog.validate()`, and in prod `SeededRandomSource` and `DebugAttestationService` are unreachable (02 §15). Evidence: `lib/bootstrap/startup_assertions.dart`; `test/bootstrap/bootstrap_test.dart` (`a SeededRandomSource is unreachable in prod`, `the DebugAttestationService is unreachable in prod`).

---

## Sprint 13.2: App state & sync (AR8, AR14)

**Tasks:**
- [x] `app_state/`: Evidence: `lib/app_state/{balance,entitlement,consent,remote_config,connectivity,settings}_controller.dart`; `test/app_state/app_state_controllers_test.dart`. Deviation: synchronous `Notifier`s seeded from the cache and following the repository stream (a `StreamNotifier` would flash a loading first frame).
  - `balance_controller.dart` (`StreamNotifier<CreditBalance?>`, stale flag, `syncStatus`);
  - `entitlement_controller.dart`;
  - `consent_controller.dart` (AI consent version vs `ai.consentVersion`; UMP/ATT from `ConsentOrchestrator`);
  - `remote_config_controller.dart` (`min version` → update-required redirect);
  - `connectivity_controller.dart`;
  - `settings_controller.dart`.
- [x] `app_state/sync_coordinator.dart` (02 §9.2), running on launch, resume, the reset timer and connectivity regained: Evidence: `lib/app_state/sync_coordinator.dart` (+ `taro_core` `SyncAccount`, `PurchaseOutboxDrainer`); `test/app_state/sync_coordinator_test.dart`.
  - coalesce runs (join an in-flight run; skip only if the last success was < `balance.resumeSyncThrottleSec` (30 s) ago, the local date is unchanged and `now < resetsAt`);
  - steps, each tolerating failure: config → timezone check (`PUT …/timezone`, 409 tolerated) → balance → `PurchaseCoordinator.drainOutbox()` → resume pending readings (`GET /v1/readings/{clientReadingId}`) → flush `pending_acks` (RC51) → `DataDeletionGateway` retry queue → reminder reschedule → attestation warm-up (Android) → `RemoveAdsEntitlement.refresh`;
  - `Stream<SyncStatus>`.
- [x] `lifecycle/app_lifecycle_observer.dart` + `reset_timer.dart` (fires at `resetsAt + 5 s` while foregrounded; cancelled on pause). Evidence: `lib/lifecycle/{app_lifecycle_observer,reset_timer}.dart`; `test/lifecycle/{app_lifecycle_observer,reset_timer}_test.dart`.
- [x] Tests with `ProviderContainer` + `FakeClock` (06 §2.5 "Resume re-sync"): Evidence: `test/app_state/sync_coordinator_test.dart` (resume after a day, same-day idempotent, joins in-flight, time-zone PUT once, 409 keeps the boundary, RC67 stale balance).
  - resume after `advance(1 day)` → exactly one balance sync;
  - same-day resume is idempotent;
  - resume during an in-flight sync joins it;
  - a timezone change triggers one PUT;
  - a 409 keeps the server boundary;
  - a stale balance response (lower or equal `ledgerVersion` with older `serverTime`) never overwrites a newer one (RC67).

---

## Sprint 13.3: Routing & deep links (AR4, RC17)

**Tasks:**
- [x] `routing/routes.dart`: the 01 §8.1 route table (S01–S33, incl. S32 `/reading/:id?mode=classic` and the S33 modal) with a `StatefulShellRoute` for the 4 tabs Today, Journal, Learn and Settings (RC17), and modal routes for S10 and S12. Evidence: `lib/routing/{routes,route_paths,router,tab_shell,screen_builders}.dart`; `test/routing/router_test.dart` (`every route renders its screen (S01–S32)`, `modals open S10, S12 and S33`).
- [x] `routing/guards.dart` (pure functions): `upgradeGuard` (S30) → `onboardingGuard` (resume at the persisted step, 01 §7.12) → `deepLinkPolicy`. Evidence: `lib/routing/guards.dart` (named `updateGuard` per GLOSSARY); `test/routing/guards_test.dart`.
- [x] `routing/deep_link_policy.dart`: allowlist `taro://daily`, `taro://reading/new?spread=`, `taro://journal/{id}`, `taro://learn/card/{cardId}`, `taro://store`, plus Universal Links / App Links on `https://taro.vshyrochuk.com/app/*`. Links during onboarding are queued until Home. **No link starts a draw, spends a credit or triggers a purchase** (02 §8.2). Evidence: `lib/routing/deep_link_policy.dart`; `test/routing/deep_link_policy_test.dart`.
- [x] iOS Associated Domains entitlement and the Android intent filters with `autoVerify`. The AASA / `assetlinks.json` hosting task is in Phase 20. Evidence: `ios/Runner/Runner.entitlements` (`CODE_SIGN_ENTITLEMENTS` on all Runner configs), `Info.plist` `taro` scheme, `AndroidManifest.xml` App Links `autoVerify` on `/app/`.
- [x] Back behaviour (01 §9.1): S08 asks for confirmation after the first pick; S09 goes back to Home. Evidence: `lib/routing/back_behaviour.dart` (`DrawBackScope`, `ReadingResultBackScope`); `test/routing/router_test.dart` (`DrawBackScope (01 §9.1)…`, `S09 back goes Home`).
- [x] Tests: the guards table, deep-link sanitize (malicious and unknown links → `/home`), and the notification-tap route. Evidence: `test/routing/{guards,deep_link_policy,router}_test.dart` (`deep links and notification taps are sanitized`).

---

## Sprint 13.4: Feature controllers & state unions (01 §8.3, PR17)

One `Notifier`/`AsyncNotifier` per screen with an `@freezed sealed` state union. Every state listed in 01 §8.3 (plus the RC20 Classic states) has a controller test and a skeleton widget test.

**Tasks:**
- [x] `features/onboarding/`: `OnboardingController` (welcome pages, disclaimer ack, step persistence) and `AiConsentController` (S04 `undecided|granted|declined`, origin-aware return, versioned; RC21). Consent orchestration is triggered after onboarding (RC19). Evidence: `lib/features/onboarding/controller/{onboarding_controller,ai_consent_controller}.dart`; `test/features/onboarding/`.
- [x] Feature folders per 02 §2.2: `onboarding/`, `consent/`, `home/`, `daily_card/`, `reading/`, `paywall/`, `journal/`, `learn/`, `settings/`, `backup/`, `help/`, `legal/`, `update/` (and `debug/`, non-prod only, Phase 12). Evidence: `apps/taro/lib/features/{onboarding,consent,home,daily_card,reading,paywall,journal,learn,settings,backup,help,legal,update}/` (+ `debug/`).
- [x] `features/home/`: `HomeController` (S05: `loading`, `content` variants, `firstRun`, `balanceStale`, `deviceUnverified`, daily-card drawn or not, banner states, `updateAvailable` once per version (RC73)); `features/daily_card/`: `DailyCardController` (S13: `notDrawn`, `revealing`, `drawn`, `noteEditing`, `reminderOffer` shown once; "Reflect deeper" → S07 with the card pre-set, PR4). Evidence: `lib/features/home/controller/home_controller.dart`, `lib/features/daily_card/controller/daily_card_controller.dart`; `test/features/{home,daily_card}/`.
- [x] `features/reading/`: Evidence: `lib/features/reading/controller/{reading_session,question_controller,draw_controller,spread_picker_controller,reading_result_controller,classic_reading_controller,report_reading_controller}.dart`; `test/features/reading/{question_controller,draw_controller,reading_flow_controllers}_test.dart`.
  - `SpreadPickerController` (S06, hides spreads disabled by config);
  - `QuestionController` (S07: `editing`, `checking`, `offline`, `consentRequired`, `deviceUnverified`, `readingsPaused` (RC47, with the `freePaused` copy variant, RC64), `aiUnavailableRegion`, `outOfReadings`, `dailyLimitReached`, `lowTrustLimited` (RC74), `rephrase`, `refused(category)`, `rateLimited`), which evaluates `ReadingGate` on **Begin** and then takes the **pre-draw hold** before any draw (PR5, RC44, RC50): hold 402 → S10, 503 → S31, 429 `dailyLimit` → `dailyLimitReached`;
  - `DrawController` (S08: `shuffling`, `picking`, `revealing` (only while the hold has ≥ 120 s left; renew otherwise), `awaitingReading`, `slowReading` (20 s), `generationFailed` (retry with the same cards and `clientReadingId`; the Worker runs a new attempt, PR6, RC49), `holdLost` → S10 with the cards face-down (RC48, RC50), `deliveryExpired` (RC51), `crisis` → S27, reduced-motion variant); on success it persists, then acks;
  - `ReadingResultController` (S09: `content`, `ratingGiven`, `sharing`, `loadingFromStorage`; report action → S33; rate-app trigger);
  - `ClassicReadingController` (S32, flow F8, RC20/RC71: static meanings per position from the bundled content (`ContentRepository` over `apps/taro/assets/deck/`), no hold, no Worker call, saved with `status: classic`; no banner or rate-app credit; `classic_reading_started/completed` events);
  - `ReportReadingController` (S33, RC72: `editing`, `submitting`, `submitted`, `failed`, `offline`, `rateLimited`, `alreadyReported`; disclosure; `reading_reported{reason}`; sets the local `reported` flag).
- [x] `features/paywall/` (MO13, 04 §11): Evidence: `lib/features/paywall/controller/{paywall_catalog,out_of_readings_controller,store_controller,rewarded_controller}.dart`; `test/features/paywall/`.
  - `OutOfReadingsController` (S10: rewarded available/capped/cooldown/disabled/failed; packs loading/loaded/unavailable/`purchasesBlocked`; `lowTrustLimited` copy; next-free countdown from server time); after a grant it returns to S07 with Begin enabled and nothing auto-starts (RC58);
  - `StoreController` (S11: `loading`, `ready`, `storeUnavailable`, `productsFailed`, `purchasing(productId)`, `pending(productId)`, `verifying`, `verificationDeferred`, `granted`, `failed(reason)`, `cancelled`, `offline`, `removeAdsOwned`, `paidBlocked` notice (03 §5.1), `purchasesBlocked(blocked|refundDebt)` (RC66), kill switch `store.enabled`);
  - `RewardedController` (S12: `loadingAd`, `noFill`, `showing`, `granting`, `granted`, `grantDelayed`, `dismissedEarly`; cancels the intent on `noFill`/failure/early dismissal, RC57).
- [x] `features/journal/`: `JournalListController` (S14: `loading`, `empty`, `content`, `filteredEmpty`, `searchEmpty`, `storageError`, patterns card when ≥ 5 entries, filters and FTS search) and `JournalEntryController` (S15: `content`, `pending` → finish reading, `failed`, `deleted` + 5 s undo, 5,000-char note autosave). Evidence: `lib/features/journal/controller/{journal_list_controller,journal_entry_controller}.dart`; `test/features/journal/`.
- [x] `features/learn/`: `DeckBrowserController` (S16: grid by arcana/suit, search), `CardDetailController` (S17: upright, reversed, zoomed, drawn-N-times link, prev/next), `SpreadGuideController` (S18), `AboutController` (S19). Evidence: `lib/features/learn/controller/{deck_browser,card_detail,spread_guide,about}_controller.dart`; `test/features/learn/`.
- [x] `features/settings/`: Evidence: `lib/features/settings/controller/{settings,language,reminder_settings,privacy,delete_data}_controller.dart`; `test/features/settings/`.
  - `SettingsController` (S20, including restore in progress, success or failure; RC43 Support ID in About; "Move readings from another device" → re-verify past purchases and show the transfer code, RC84);
  - `LanguageController` (S21, in-app override);
  - `ReminderSettingsController` (S22, `permissionDenied` → open settings);
  - `PrivacyController` (S23: AI consent grant/revoke, UMP privacy options when required, ATT status + open iOS Settings, analytics toggle);
  - `DeleteDataController` (S26: `confirm1`, `confirm2`, `deleting`, `done`, `partial`; RC37: keeps the install ID, credits and Remove Ads, and says so).
- [x] `features/backup/`: `ExportController` (S24: `preparing`, `shareSheetOpen`, `done`, `failed`) and `ImportController` (S25: `picking`, `validating`, `invalid(reason)`, `preview` (with "balance not included" copy), `confirmReplace`, `importing(progress)`, `done(summary)`, `failed`). Evidence: `lib/features/backup/controller/{export,import}_controller.dart`; `test/features/backup/`.
- [x] `features/help/`: `CrisisResourcesController` (S27; the device region is never sent; offline), `FaqController` (S28), `LegalController` (S29: disclaimer, terms, privacy, licenses via `showLicensePage`), `UpdateRequiredController` (S30). Evidence: `lib/features/help/controller/{crisis_resources,faq}_controller.dart`, `lib/features/legal/controller/legal_controller.dart`, `lib/features/update/controller/update_required_controller.dart`; `test/features/{help,legal,update}/`.
- [x] Share (PR19): `ShareReadingUseCase` builds text with localized card names, the summary, an excerpt and the disclaimer line, with an opt-in "include my question" toggle. Evidence: `lib/features/reading/share/share_reading_use_case.dart`; `test/features/reading/reading_flow_controllers_test.dart`. Open: shared as a `.txt` file until a text-share port exists.
- [x] Analytics: fire every 01 §15 and 04 §14 event from its controller. `check_analytics_events.py` is green. Tests assert the events and params with `FakeAnalyticsService`. Evidence: `check_analytics_events.py` OK; `docs/ANALYTICS_EVENTS.md` §Emitters in the app shell; controller tests assert events via `FakeAnalyticsService` (`eventsOf<…>`).
- [x] `tools/gen_state_inventory.dart` → `docs/design/STATE_INVENTORY.md`: screen → route → states → ★ golden flag → banner allowed. This is the input to Phase 14. Evidence: `tools/dart_tools/bin/gen_state_inventory.dart` (`melos run gen:state_inventory`, `--check`) → `docs/design/STATE_INVENTORY.md`; `tools/dart_tools/test/state_inventory_test.dart`.

---

## Sprint 13.5: Skeleton UI, l10n, common widgets

**Tasks:**
- [x] `apps/taro/lib/l10n/`: `apps/taro/l10n.yaml` per 02 §11 (output `lib/l10n/generated/`). Write `app_en.arb` with every UI string, including the 05 §3 compliance keys (`disclaimerShort`, `disclaimerOnboarding*`, `aiConsent*`, `aiLabel`, `refusalGeneric`, `crisis*`, `reportReadingTitle`), every error `code` → message key (RC5), the 6 reminder variants, suggestion chips, the spread and position names (`spread_{id}_pos_{pos}_name/_desc`), IAP disclosure lines (04 §11), and ICU plurals. The 11 other ARB files are copied with an `x-translate` marker so `check_l10n.py` passes in development mode. Evidence: `lib/l10n/arb/app_en.arb` (716+ keys), 11 ARBs with `x-translate`; `check_l10n.py` OK; `test/l10n/arb_catalogue_test.dart`.
- [x] Minimal `taro_ui` state kit (to be restyled in Phase 15): `TaroLoadingView`, `TaroEmptyView`, `TaroErrorView(kind, onRetry)`, `TaroOfflineBanner`, `TaroInlineNotice`, `TaroScaffold` (01 §8.2). Use Material defaults and **no raw values** (temporary token stubs in `taro_ui/lib/src/tokens/stub_tokens.dart`, replaced in Phase 15). Evidence: superseded by the real Phase 15 kit (`packages/taro_ui/lib/src/components/state/`), so `stub_tokens.dart` was never created.
- [x] `common/`: `BalanceChip` (the 01 §7.1 sync states), `BannerSlot(screenId)` (`BannerPolicy`, placed outside the scroll view; RC18), `DisclaimerFooter` (rendered on every reading state, including loading and error; 05 §3), `OfflineBanner`, `FailureMessage.of(context, failure)`. Evidence: `lib/common/{balance_chip,banner_slot,disclaimer_footer,offline_banner,failure_message}.dart`; `test/common/`.
- [x] One skeleton screen per S-ID, rendering each state with the kit plus plain `Text` from ARB. Widget tests for **every state** (PR17), including: Evidence: `lib/features/*/view/*_screen.dart` (33 screens); `test/features/**/view/*_test.dart`, `test/features/*/*_screens_test.dart` (no card face before the gate, disclaimer in every S09 state, no banner on reading screens, equal-weight S04 buttons, paywall close/restore/terms/privacy/non-restorable line, no pre-selected pack).
  - no `CardFace` in the tree before the gate allows (06 §2.5);
  - `DisclaimerFooter` present in every S09 state;
  - no `BannerSlot` on the reading screens;
  - equal-weight consent buttons;
  - paywall has close, restore, terms, privacy, the non-restorable line and no pre-selected pack (04 §11, 05 3.1.1 row).
- [x] 12-locale smoke test (06 §3.1) against skeleton screens, and the RTL `Directionality` assertion for `ar`. Evidence: `test/l10n/locale_smoke_test.dart` (33 screens × 12 locales, `ar` RTL only).

---

## Sprint 13.6: Integration flows (fakes) & staging smoke

**Tasks:**
- [x] patrol + `integration_test` flows (RC13), each with `TARO_ENV=test`: Evidence: `integration_test/flows/*_test.dart` (14 flows, harness `integration_test/support/flow_harness.dart`), green on the iOS simulator and Android emulator (API 36) on 2026-09-30.
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
- [x] `integration_test/staging/smoke_test.dart`: the real staging Worker, register, balance, one free reading with the debug attestation bypass. Manual dispatch only (06 §4). Evidence: `integration_test/staging/smoke_test.dart` (skips unless `TARO_STAGING_SMOKE=1` + `TARO_DEBUG_ATTESTATION_TOKEN`). Not yet run against staging: the owner runs it (the token is in the secrets bundle).
- [x] Performance baseline: `integration_test/perf/cold_start_test.dart` and a timeline summary for the draw screen (02 §17). Record the numbers; the budgets are enforced in Phase 19. Evidence: `integration_test/perf/{cold_start,draw_screen_perf}_test.dart`; numbers in `docs/ARCHITECTURE.md` §Integration flows and performance baseline.

---

## Done when

- [x] `apps/taro` (incl. `lib/l10n/`) and `taro_ui` (kit) are each ≥ 90%, and `check_coverage.py` is green. The integration flows are green on the iOS simulator (PR) and the Android emulator (nightly). Evidence (2026-09-30, `tools/verify.sh` full): apps/taro 99.57 % (215 files, incl. `lib/l10n/`), taro_ui 99.97 %, `coverage:check` PASS for all 9 units; the 14 flows green on the iOS simulator (iPhone 17 Pro, iOS 26.5) after the pre-prompt wiring, and on the Android emulator (API 36) before it.
- [x] `docs/design/STATE_INVENTORY.md` is generated and committed. Evidence: `gen_state_inventory --check` OK.
- [x] `check_architecture.dart` is green: features never import `lib/data/`, `lib/services/` or vendor SDKs; `BannerSlot` gets its `BannerSlotView` from `di/`, and only `bootstrap/`/`di/` import `services/presentation/` (02 §2.1, RC95). Evidence: `dart run tools/dart_tools/bin/check_architecture.dart` OK (verify.sh).
- [x] Docs: `docs/ARCHITECTURE.md` (routing, state, sync), `docs/ANALYTICS_EVENTS.md`, `docs/TESTING.md` (integration harness), CHANGELOG. Evidence: `docs/ARCHITECTURE.md` §App shell, §Localization and common widgets, §Integration flows; `docs/ANALYTICS_EVENTS.md`; `docs/TESTING.md` §Integration tests; `CHANGELOG.md`.
- [ ] One commit: `feat(taro): Phase 13 — App shell, state machines & flows`.

## Next phase

Phase 14: Claude Design Handoff (it can already have started from the Sprint 13.4 inventory).
