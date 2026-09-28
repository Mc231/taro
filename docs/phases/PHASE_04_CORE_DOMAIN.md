# Phase 4: Core Domain, Ports & Test Kit

**Status:** ✅ Complete (2026-09-28)
**Depends on:** Phase 3

---

## Overview

This phase builds `taro_core`: pure Dart, no Flutter, no I/O. It holds:
- the `Result`/`Failure` types;
- every domain model;
- every port interface;
- the pure business logic that encodes the shared contract: CSPRNG draw, paywall-before-draw gate, backup merge, reset schedule, banner policy, product catalogue validation.

It also builds the test kit in `packages/taro_core/test/`: one `Fake…` per port (`test/fakes/`), the shared port contract suites (`test/contracts/`, QA16), and fluent test-data builders. Reconciled by 00_DECISIONS.md RC95: there is no `taro_testing` package any more; the kit lives in `taro_core`'s test tree and the app's `test/helpers/`.

Writing tests first is cheapest here. Every rule in this phase is table-driven or property-tested, and later layers depend on these types.

**Output of this phase:**
- `packages/taro_core` at about 100% coverage, with a barrel exporting models, ports, use-case interfaces and logic.
- `packages/taro_core/test/fakes/` (fakes, builders) and `packages/taro_core/test/contracts/` (`runXContract` suites); `TaroFakes` and `pumpTaro` follow in `apps/taro/test/helpers/` (Phase 13.1).
- `docs/ARCHITECTURE.md` §Ports lists every port and its Prod, NoOp and Fake implementations.

---

## Specs referenced

`02_ARCHITECTURE.md` AR5, AR6, AR8, AR13, AR18, §3, §4, §4.1, §5. `01_PRODUCT.md` PR3, PR5, PR6, PR7, PR17, PR18, §7.11, §8.2, §10, §15. `04_MONETIZATION.md` MO4, MO5, MO11, MO18, §5.5, §6.6 (BannerPolicy), §11. `06_QUALITY_TESTING_CI.md` QA5, QA9, QA16, §2. `00_DECISIONS.md` RC1, RC2, RC5, RC6, RC17, RC18, RC27, RC30, RC41, RC44, RC50, RC57, RC62, RC64, RC66, RC67, RC70, RC74, RC77, RC81, RC89.

---

## Sprint 4.1: Result, Failure, IDs

**Tasks:**
- [x] `taro_core/lib/src/result/result.dart`: sealed `Result<T>` with `Ok`/`Err`, `fold`, `map`, `then`, `valueOrNull` (02 §3). Test: `test/src/result/result_test.dart`.
  - Evidence: `packages/taro_core/test/src/result/result_test.dart`.
- [x] `failure.dart`: the sealed `Failure` hierarchy from 02 §3, with factories on `Failure` (sealed-factory rule), a stable `code`, and the added subtypes `AiConsentRequiredFailure` (RC28), `AiUnavailableRegionFailure` (RC29), `ReadingsPausedFailure(reason: budget|freePaused|disabled)` (RC47, RC64), `PurchaseAlreadyClaimedFailure{transferToken?}` (RC84), `RewardUnavailableFailure{reason: disabled|cap|cooldown|noFill|consent, availableAt}` (RC57), `HoldConflictFailure` (409 `HOLD_CONFLICT`, RC50), `ReadingExpiredRefundedFailure` (410 `READING_EXPIRED_REFUNDED`, RC51), `RateLimitedFailure(reason: dailyLimit)` (429, RC74). There is no `InstallBlockedFailure`: blocked installs are expressed by `purchasesAllowed` (RC66). `RefusalCategory` = the 03 §9.4 list (RC27).
  - Evidence: `lib/src/result/failure.dart`, `refusal_category.dart`; `packages/taro_core/test/src/result/failure_test.dart`, `refusal_category_test.dart`. Names follow 02 §3 / GLOSSARY §5 and are registered in GLOSSARY §16 (RC96); `failure*`/`safetyDeclined*` ARB keys in all 12 locales.
- [x] `ids.dart`: extension types `CardId`, `SpreadId`, `PositionId`, `ReadingId`, `InstallId`, `ProductId`, `IntentId`. `CardId.parse` validates the RC1 regex `^(major_(0\d|1\d|2[01])|(wands|cups|swords|pentacles)_(0[1-9]|1[0-4]))$`.
  - Evidence: `packages/taro_core/test/src/result/ids_test.dart`.
- [x] `ErrorKind` sealed (`network`, `server`, `rateLimited`, `deviceUnverified`, `storage`, `invalidFile`, `unknown`) plus a `ErrorKind.fromFailure` mapper (01 §8.2).
  - Evidence: `ErrorKind` enum with exhaustive `fromFailure`; `packages/taro_core/test/src/result/error_kind_test.dart`.

---

## Sprint 4.2: Domain models (freezed, RC13)

**Tasks:**
- [x] `model/`:
  - `deck_card.dart` (`DeckCard`, `Arcana`, `Suit`, `Element`), `card_text.dart` (`CardText`, `CardAspects`, `ReviewStatus`), `deck.dart` (exactly 78 validated cards) — 01 §10.1;
  - `spread.dart` (`SpreadDefinition`, `SpreadPosition{id, order, x, y, rotationDeg}`; no per-spread cost, always 1 credit, RC62) — 01 §10.2;
  - `drawn_card.dart`, `draw.dart`;
  - `reading.dart`: `Reading{id, createdAt, updatedAt, localDate, spreadId, question?, cards, status: pending|generating|complete|failed|refused|classic, content?, contentLocale, promptVersion?, modelId?, note?, favourite, rating?, ratingReason?, chargeSource?}` (01 §10.4 + RC17 + RC20);
  - `reading_content.dart` (`ReadingContent` per RC30);
  - `daily_card.dart` (`DailyCard{localDate, cardId, reversed, drawnAt, note?, favourite, updatedAt}`).
  - Evidence: `lib/src/model/`; `packages/taro_core/test/src/model/deck_test.dart`, `spread_draw_test.dart`, `reading_test.dart` (statuses per 02: `pending|complete|refused|failed|classic`).
- [x] `credit_balance.dart`: `CreditBalance` mapped from `BalanceDto` (RC6), with `free{limit,used,remaining,localDate,resetsAt,timezone,paused}`, `bonus`, `paid`, `canRead`, `canReadReason` (RC74), `nextSource`, `rewarded{enabled,amount,dailyCap,grantedToday,available,cooldownEndsAt}`, `paidBlocked`, `purchasesAllowed`, `purchasesBlockedReason` (RC66), `serverTime`, `ledgerVersion`, `syncedAt`, `isStaleAt(now, staleAfter)`, `total`, `displayPaid` (negative shown as 0, MO16), and `shouldReplace(CreditBalance cached)` implementing the RC67 rule (`>` version, or `=` with newer `serverTime`).
  - Evidence: `packages/taro_core/test/src/model/credit_balance_test.dart`.
- [x] `entitlement.dart` (`EntitlementState{owned,notOwned,unknown}`, source, verifiedAt), `remote_config.dart` (typed RC8 keys, `RemoteConfig.defaults`, clamping per 03 §8.2 ranges (RC8; 04 §13 mirrors them), `config_value_clamped` hook), `consent_state.dart` (ads/UMP, tracking/ATT, `AiConsent{decision: unknown|granted|declined, version, at}` (02 §4), analyticsEnabled, `onboardingStep`), `install_identity.dart` (installId, trust, `purchaseBinding{appleAccountToken?, playAccountId?}` per RC9), `user_settings.dart` (theme, localeOverride, reversalsEnabled, hapticsEnabled, reminder, reduceMotion).
  - Evidence: `packages/taro_core/test/src/model/state_models_test.dart`, `remote_config_test.dart`.
- [x] `backup.dart`: `BackupV1` per 01 §7.11 and `docs/specs/backup_schema_v1.json` (`data` wrapper, `updatedAt`/`createdAt`/`drawnAt`, `classic`, `ratingReason`; RC17, RC70). `crisis_resource.dart`: `CrisisResource` with the canonical 03 §9.5 fields `{name, phone?, sms?, url?, hours?, languages, verifiedAt}` (RC81), `CrisisDirectory`.
  - Evidence: `packages/taro_core/test/src/model/backup_test.dart`, `crisis_resource_test.dart`.
- [x] `monetization/taro_products.dart`: `TaroProducts` (IDs + kind only, **no credit counts**; MO2, RC3), `IapCatalog.validate()` throws on an unqualified ID (02 §5, 04 §4). `ProductOffer` computes the per-reading price from `rawPrice`/`currencyCode`, and `bestValue` is computed, never asserted (MO18). Test currencies JPY (0 decimals), KWD (3), EUR and USD.
  - Evidence: `lib/src/monetization/`; `packages/taro_core/test/src/monetization/monetization_test.dart`.
- [x] `build_runner` codegen for freezed. `*.freezed.dart` is excluded (RC16). Unit tests for equality, `copyWith` and invariants per model.
  - Evidence: `melos run gen:build`; `packages/taro_core/test/src/model/*_test.dart`.

---

## Sprint 4.3: Pure logic (table and property tests)

**Tasks:**
- [x] `logic/card_drawer.dart`: `CardDrawer(RandomSource).draw(Deck, SpreadDefinition, {reversalsEnabled, now})`. It does a Fisher–Yates shuffle of 78 IDs using rejection-sampled `nextInt` (no modulo bias, 06 §2.1), takes `positions.length` cards, and draws each orientation independently (PR7). Tests:
  - exact order with `ScriptedRandomSource`;
  - property tests (no duplicates, positions filled in `order`) with `SeededRandomSource`;
  - a χ² uniformity test over 100k draws, tagged `slow` (01 §17.3).
  - Evidence: `packages/taro_core/test/src/logic/card_drawer_test.dart`, `card_drawer_slow_test.dart` (tag `slow`), `uniform_int_test.dart`.
- [x] `logic/reading_gate.dart`: `ReadingGate.evaluate(...) → GateDecision` in the RC44 order, plus `dailyLimitReached` from `canReadReason == dailyLimit` (RC74); `lowTrustCap` → `needsCredits(PaywallOptions{reason: lowTrustCap})` (UI state `lowTrustLimited`, Phase 13). Table-driven test over balance × config × consent × online × trust × region × spread enabled. Assert that `needsCredits` carries `PaywallOptions{reason, packs, rewardedAvailable, nextFreeAt}` per 02 §4.1 (store availability comes from `CreditBalance.purchasesAllowed` / `purchasesBlockedReason`, not from the gate), that rewarded is available only when `free.remaining == 0` (RC34), and that `dailyLimitReached` never yields a paywall. The gate is followed by the Worker pre-draw hold (RC50), which is the authority.
  - Evidence: `packages/taro_core/test/src/logic/reading_gate_test.dart`.
- [x] `logic/reset_schedule.dart`: `nextSyncAt(CreditBalance, now)`. `logic/server_clock.dart`: `ServerClockOffset` applied to countdowns (02 §6.3, 04 §5.3). Tested across the `kBoundaryZones` matrix (06 §2.1).
  - Evidence: `packages/taro_core/test/src/logic/server_clock_test.dart` (`kBoundaryZones` in `boundary_zones.dart`).
- [x] `logic/backup_merge.dart`: Merge (union by `id` / `localDate`; the newer `updatedAt` wins; if notes differ, keep the longer one) and Replace (01 §7.11). `MergeReport{added, updated, skipped}`. Conflict-table test.
  - Evidence: `packages/taro_core/test/src/logic/backup_merge_test.dart`.
- [x] `logic/backup_validator.dart`: validates against `backup_schema_v1.json` (01 §7.11, RC70): format, `schemaVersion` ≤ current, size ≤ 20 MB, ≤ 50,000 entries, string limits, card IDs exist; `additionalProperties: false` means files with forbidden keys (`credits`, `balance`, `installId`, `entitlements`, `consent`) are rejected, never imported (06 §2.5). `logic/backup_checksum.dart`: RFC 8785 (JCS) canonicalisation + SHA-256, tested against the golden fixture.
  - Evidence: `packages/taro_core/test/src/logic/backup_validator_test.dart`, `backup_checksum_test.dart` (golden `fixtures/backup_v1_sample.json`).
- [x] `logic/banner_policy.dart`: `BannerPolicy.shouldShow(screenId, …)` = `ads.enabled && ads.bannerEnabled && screenId ∈ (kBannerAllowList ∩ ads.bannerScreens) && !removeAds && canRequestAds && completedReadings >= ads.bannerMinCompletedReadings`. `kBannerAllowList = {home, journal_list, learn_library}` (RC18, MO11). Truth-table test over every screen ID in GLOSSARY.
  - Evidence: `packages/taro_core/test/src/logic/banner_policy_test.dart`.
- [x] `logic/patterns.dart`: journal insights (most-drawn cards over 30/90 days, suit balance, major/minor ratio, reversed ratio; hidden below 5 entries; 01 §7.8), plus a `streak_days` counter used for analytics only (01 Q10).
  - Evidence: `packages/taro_core/test/src/logic/patterns_test.dart`.
- [x] `logic/question_precheck.dart`: trim, grapheme count ≤ `ai.questionMaxChars`, reject emoji/punctuation-only input, warn on email or phone patterns (01 §7.2).
  - Evidence: `packages/taro_core/test/src/logic/question_precheck_test.dart`.
- [x] `logic/daily_card_rules.dart`: the same local day returns the same card; this is idempotent (01 §7.6, §17.3).
  - Evidence: `packages/taro_core/test/src/logic/daily_card_rules_test.dart`.

---

## Sprint 4.4: Ports (interfaces only)

**Tasks:**
- [x] One file per port in `taro_core/lib/src/ports/`:
  - from 02 §5: `InstallRepository`, `SessionTokenStore`, `BalanceRepository`, `ReadingRepository`, `DailyCardRepository`, `ContentRepository`, `RemoteConfigRepository`, `SettingsRepository`, `ConsentStore`, `IapService`, `PurchaseVerifier`, `PurchaseOutbox`, `EntitlementCache`, `AdsService`, `RewardGateway`, `ConsentService` (UMP), `TrackingAuthorization` (ATT), `AnalyticsService`, `CrashReporter`, `ReminderScheduler`, `AttestationService`, `Clock`, `TimezoneProvider`, `RandomSource`, `FileTransfer`, `ConnectivityMonitor`, `ReviewPrompter`, `AppInfo`, `SecureStore`;
  - added: `IdGenerator`, `Logger` (RC41); `ReportGateway` (CS7); `DataDeletionGateway` (CS15, RC37); `CrisisResourcesRepository` (RC25). **No** `DailyCardWidgetBridge` in v1: it arrives with its adapter in Phase 23.1 (RC89).
  - Evidence: 35 ports in `lib/src/ports/` (plus `JournalRepository`); table in `docs/ARCHITECTURE.md` §Ports; `packages/taro_core/test/src/ports/ports_test.dart`.
- [x] `IapEvent` sealed (02 §5), `PurchaseOutcome` sealed (04 §6.2), `RewardedShowResult`, `SyncReason`, `SyncStatus`.
  - Evidence: `lib/src/ports/{iap_event,purchase_outcome,rewarded_show_result,sync_reason,sync_status}.dart`.
- [x] Use-case classes in `usecases/` (constructor-injected ports; logic tested with fakes in Phase 4.5 and wired in Phase 13): `DrawCards`, `RequestReading`, `ResumeReading`, `SyncAccount`, `PurchaseCredits`, `EarnReward`, `ExportBackup`, `ImportBackup`, `ResolveReadingGate`, `ReportReading`, `DeleteAllData`, `StartClassicReading` (RC20).
  - Evidence: `lib/src/usecases/`; `packages/taro_core/test/src/usecases/*_test.dart`.
- [x] Analytics: sealed `TaroAnalyticsEvent` with the groups from 01 §15 and 04 §14 (merged and deduplicated; the 04 event names win for monetization). Every param is an enum, int or bool (PR18). Write `docs/ANALYTICS_EVENTS.md` in the same change and keep `check_analytics_events.py` green. Snapshot test of every event's `name` and `parameters`, plus a reflective test that no param is a free-form `String` (01 §17.6).
  - Evidence: 74 events; `packages/taro_core/test/src/analytics/taro_analytics_event_test.dart` (snapshot + source-scan "no String" test); `check_analytics_events.py` OK.

---

## Sprint 4.5: Test kit (`taro_core/test/fakes/` + `test/contracts/`, QA16)

**Tasks:**
- [x] `packages/taro_core/test/fakes/`: a `FakeX` for every Sprint 4.4 port, with in-memory state and test hooks. Examples:
  - `FakeWorkerGateway.failNext(Failure)`, `FakeIapService.emitPending(productId)`, `FakeIapService.redeliver(txn)`;
  - `FakeAdsService.completeRewarded()`, `FakeConsentService(status)`, `FakeAttestationService(kind)`;
  - `FakeClock.advance`/`setTimeZone`, `SeededRandomSource`, `ScriptedRandomSource`, `SequentialIdGenerator`, `CapturingLogger`, `InMemorySecureStore`.
  - Evidence: `packages/taro_core/test/fakes/` (`fakes.dart`).
- [x] `packages/taro_core/test/contracts/`: `runBalanceRepositoryContract`, `runReadingRepositoryContract`, `runIapServiceContract`, `runPurchaseOutboxContract`, `runSecureStoreContract`, `runClockContract`, `runRandomSourceContract`, … (one per port). Each runs against its fake in `taro_core/test/` now, and against the real adapters in `apps/taro/test/data/` and `apps/taro/test/services/` in Phases 11–12 (imported by relative path, the one cross-package test import 02 §2.1 allows).
  - Evidence: 35 `run<Port>Contract` suites in `packages/taro_core/test/contracts/`, each with a `*_fake_test.dart`.
- [x] `packages/taro_core/test/fakes/builders/`: `aReading()`, `aDailyCard()`, `aCreditBalance().withFreeRemaining(0).withPaid(3)`, `aRemoteConfig().withRewardedEnabled(false)`, `aBackup().withVersion(1)`, `aCard('major_00').reversed()`, `aSpread('celtic_cross')`. Defaults live in `builders/defaults.dart`; builders never read the clock or RNG.
  - Evidence: `packages/taro_core/test/fakes/builders/`.
- [x] The fakes stay Riverpod-free (RC77). `pumpTaroWidget` lives in `apps/taro/test/helpers/pump_taro_widget.dart` (Phase 3.3), and the `TaroFakes` bundle and the Riverpod-aware `pumpTaro` in `apps/taro/test/helpers/pump_app.dart` (Phase 13.1) (02 §2.1, AR3, RC95).
  - Evidence: No Riverpod import under `packages/taro_core/`.
- [x] `check_forbidden_apis.py` and `check_architecture.dart` pass: `taro_core/test/fakes/` and `test/contracts/` are imported only from `test/` and `integration_test/`, never from any `lib/`.
  - Evidence: `check_forbidden_apis: OK`, `check_architecture: OK (346 file(s))`.

---

## Done when

- [x] `taro_core` ≥ 90% (target ~100%); every contract suite is green against its fake. `check_coverage.py` is green.
  - Evidence: 2339/2339 lines (100.00 %), `check_coverage.py --unit taro_core` PASS; 1219 tests green.
- [x] `check_architecture.dart`: `taro_core` has no Flutter or I/O imports.
  - Evidence: `check_architecture: OK`.
- [x] `docs/ANALYTICS_EVENTS.md` and `docs/ARCHITECTURE.md` §Ports and §Domain are updated. CHANGELOG `Unreleased` updated.
  - Evidence: `docs/ARCHITECTURE.md` §Domain, §Ports; CHANGELOG `Unreleased`.
- [x] One commit: `feat(taro): Phase 4 — Core domain, ports & test kit`.

## Next phase

Phase 5: Deck Content Pipeline. Phase 11 (client data layer) also depends on this phase.
