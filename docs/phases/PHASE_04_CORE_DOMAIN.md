# Phase 4: Core Domain, Ports & Test Kit

**Status:** ⬜ Not Started
**Depends on:** Phase 3

---

## Overview

This phase builds `taro_core`: pure Dart, no Flutter, no I/O. It holds:
- the `Result`/`Failure` types;
- every domain model;
- every port interface;
- the pure business logic that encodes the shared contract: CSPRNG draw, paywall-before-draw gate, backup merge, reset schedule, banner policy, product catalogue validation.

It also builds `taro_testing`: one `Fake…` per port, the shared port contract suites (QA16), and fluent test-data builders.

Writing tests first is cheapest here. Every rule in this phase is table-driven or property-tested, and later layers depend on these types.

**Output of this phase:**
- `packages/taro_core` at about 100% coverage, with a barrel exporting models, ports, use-case interfaces and logic.
- `packages/taro_testing` with fakes, `runXContract` suites, builders, `TaroFakes` and a working `pumpTaro` harness.
- `docs/ARCHITECTURE.md` §Ports lists every port and its Prod, NoOp and Fake implementations.

---

## Specs referenced

`02_ARCHITECTURE.md` AR5, AR6, AR8, AR13, AR18, §3, §4, §4.1, §5. `01_PRODUCT.md` PR3, PR5, PR6, PR7, PR17, PR18, §7.11, §8.2, §10, §15. `04_MONETIZATION.md` MO4, MO5, MO11, MO18, §5.5, §6.6 (BannerPolicy), §11. `06_QUALITY_TESTING_CI.md` QA5, QA9, QA16, §2. `00_DECISIONS.md` RC1, RC2, RC5, RC6, RC17, RC18, RC27, RC30, RC41, RC44, RC50, RC57, RC62, RC64, RC66, RC67, RC70, RC74, RC77, RC81, RC89.

---

## Sprint 4.1: Result, Failure, IDs

**Tasks:**
- [ ] `taro_core/lib/src/result/result.dart`: sealed `Result<T>` with `Ok`/`Err`, `fold`, `map`, `then`, `valueOrNull` (02 §3). Test: `test/src/result/result_test.dart`.
- [ ] `failure.dart`: the sealed `Failure` hierarchy from 02 §3, with factories on `Failure` (sealed-factory rule), a stable `code`, and the added subtypes `AiConsentRequiredFailure` (RC28), `AiUnavailableRegionFailure` (RC29), `ReadingsPausedFailure(reason: budget|freePaused|disabled)` (RC47, RC64), `PurchaseAlreadyClaimedFailure{transferToken?}` (RC84), `RewardCapFailure{reason: cap|cooldown, availableAt}` (RC57), `HoldLostFailure` (409 `HOLD_CONFLICT`, RC50), `DeliveryExpiredFailure` (410 `READING_EXPIRED_REFUNDED`, RC51), `DailyLimitFailure` (429 `dailyLimit`, RC74). There is no `InstallBlockedFailure`: blocked installs are expressed by `purchasesAllowed` (RC66). `RefusalCategory` = the 03 §9.4 list (RC27).
- [ ] `ids.dart`: extension types `CardId`, `SpreadId`, `PositionId`, `ReadingId`, `InstallId`, `ProductId`, `IntentId`. `CardId.parse` validates the RC1 regex `^(major_(0\d|1\d|2[01])|(wands|cups|swords|pentacles)_(0[1-9]|1[0-4]))$`.
- [ ] `ErrorKind` sealed (`network`, `server`, `rateLimited`, `deviceUnverified`, `storage`, `invalidFile`, `unknown`) plus a `ErrorKind.fromFailure` mapper (01 §8.2).

---

## Sprint 4.2: Domain models (freezed, RC13)

**Tasks:**
- [ ] `model/`:
  - `deck_card.dart` (`DeckCard`, `Arcana`, `Suit`, `Element`), `card_text.dart` (`CardText`, `CardAspects`, `ReviewStatus`), `deck.dart` (exactly 78 validated cards) — 01 §10.1;
  - `spread.dart` (`SpreadDefinition`, `SpreadPosition{id, order, x, y, rotationDeg}`; no per-spread cost, always 1 credit, RC62) — 01 §10.2;
  - `drawn_card.dart`, `draw.dart`;
  - `reading.dart`: `Reading{id, createdAt, updatedAt, localDate, spreadId, question?, cards, status: pending|generating|complete|failed|refused|classic, content?, contentLocale, promptVersion?, modelId?, note?, favourite, rating?, ratingReason?, chargeSource?}` (01 §10.4 + RC17 + RC20);
  - `reading_content.dart` (`ReadingContent` per RC30);
  - `daily_card.dart` (`DailyCard{localDate, cardId, reversed, drawnAt, note?, favourite, updatedAt}`).
- [ ] `credit_balance.dart`: `CreditBalance` mapped from `BalanceDto` (RC6), with `free{limit,used,remaining,localDate,resetsAt,timezone,paused}`, `bonus`, `paid`, `canRead`, `canReadReason` (RC74), `nextSource`, `rewarded{enabled,amount,dailyCap,grantedToday,available,cooldownEndsAt}`, `paidBlocked`, `purchasesAllowed`, `purchasesBlockedReason` (RC66), `serverTime`, `ledgerVersion`, `syncedAt`, `isStaleAt(now, staleAfter)`, `total`, `displayPaid` (negative shown as 0, MO16), and `shouldReplace(CreditBalance cached)` implementing the RC67 rule (`>` version, or `=` with newer `serverTime`).
- [ ] `entitlement.dart` (`EntitlementState{owned,notOwned,unknown}`, source, verifiedAt), `remote_config.dart` (typed RC8 keys, `RemoteConfig.defaults`, clamping per 03 §8.2 ranges (RC8; 04 §13 mirrors them), `config_value_clamped` hook), `consent_state.dart` (ads/UMP, tracking/ATT, `AiConsent{decision: unknown|granted|declined, version, at}` (02 §4), analyticsEnabled, `onboardingStep`), `install_identity.dart` (installId, trust, `purchaseBinding{appleAccountToken?, playAccountId?}` per RC9), `user_settings.dart` (theme, localeOverride, reversalsEnabled, hapticsEnabled, reminder, reduceMotion).
- [ ] `backup.dart`: `BackupV1` per 01 §7.11 and `docs/specs/backup_schema_v1.json` (`data` wrapper, `updatedAt`/`createdAt`/`drawnAt`, `classic`, `ratingReason`; RC17, RC70). `crisis_resource.dart`: `CrisisResource` with the canonical 03 §9.5 fields `{name, phone?, sms?, url?, hours?, languages, verifiedAt}` (RC81), `CrisisDirectory`.
- [ ] `monetization/taro_products.dart`: `TaroProducts` (IDs + kind only, **no credit counts**; MO2, RC3), `IapCatalog.validate()` throws on an unqualified ID (02 §5, 04 §4). `ProductOffer` computes the per-reading price from `rawPrice`/`currencyCode`, and `bestValue` is computed, never asserted (MO18). Test currencies JPY (0 decimals), KWD (3), EUR and USD.
- [ ] `build_runner` codegen for freezed. `*.freezed.dart` is excluded (RC16). Unit tests for equality, `copyWith` and invariants per model.

---

## Sprint 4.3: Pure logic (table and property tests)

**Tasks:**
- [ ] `logic/card_drawer.dart`: `CardDrawer(RandomSource).draw(Deck, SpreadDefinition, {reversalsEnabled, now})`. It does a Fisher–Yates shuffle of 78 IDs using rejection-sampled `nextInt` (no modulo bias, 06 §2.1), takes `positions.length` cards, and draws each orientation independently (PR7). Tests:
  - exact order with `ScriptedRandomSource`;
  - property tests (no duplicates, positions filled in `order`) with `SeededRandomSource`;
  - a χ² uniformity test over 100k draws, tagged `slow` (01 §17.3).
- [ ] `logic/reading_gate.dart`: `ReadingGate.evaluate(...) → GateDecision` in the RC44 order, plus `dailyLimitReached` from `canReadReason == dailyLimit` (RC74); `lowTrustCap` → `needsCredits(PaywallOptions{reason: lowTrustCap})` (UI state `lowTrustLimited`, Phase 13). Table-driven test over balance × config × consent × online × trust × region × spread enabled. Assert that `needsCredits` carries `PaywallOptions{reason, packs, rewardedAvailable, nextFreeAt}` per 02 §4.1 (store availability comes from `CreditBalance.purchasesAllowed` / `purchasesBlockedReason`, not from the gate), that rewarded is available only when `free.remaining == 0` (RC34), and that `dailyLimitReached` never yields a paywall. The gate is followed by the Worker pre-draw hold (RC50), which is the authority.
- [ ] `logic/reset_schedule.dart`: `nextSyncAt(CreditBalance, now)`. `logic/server_clock.dart`: `ServerClockOffset` applied to countdowns (02 §6.3, 04 §5.3). Tested across the `kBoundaryZones` matrix (06 §2.1).
- [ ] `logic/backup_merge.dart`: Merge (union by `id` / `localDate`; the newer `updatedAt` wins; if notes differ, keep the longer one) and Replace (01 §7.11). `MergeReport{added, updated, skipped}`. Conflict-table test.
- [ ] `logic/backup_validator.dart`: validates against `backup_schema_v1.json` (01 §7.11, RC70): format, `schemaVersion` ≤ current, size ≤ 20 MB, ≤ 50,000 entries, string limits, card IDs exist; `additionalProperties: false` means files with forbidden keys (`credits`, `balance`, `installId`, `entitlements`, `consent`) are rejected, never imported (06 §2.5). `logic/backup_checksum.dart`: RFC 8785 (JCS) canonicalisation + SHA-256, tested against the golden fixture.
- [ ] `logic/banner_policy.dart`: `BannerPolicy.shouldShow(screenId, …)` = `ads.enabled && ads.bannerEnabled && screenId ∈ (kBannerAllowList ∩ ads.bannerScreens) && !removeAds && canRequestAds && completedReadings >= ads.bannerMinCompletedReadings`. `kBannerAllowList = {home, journal_list, learn_library}` (RC18, MO11). Truth-table test over every screen ID in GLOSSARY.
- [ ] `logic/patterns.dart`: journal insights (most-drawn cards over 30/90 days, suit balance, major/minor ratio, reversed ratio; hidden below 5 entries; 01 §7.8), plus a `streak_days` counter used for analytics only (01 Q10).
- [ ] `logic/question_precheck.dart`: trim, grapheme count ≤ `ai.questionMaxChars`, reject emoji/punctuation-only input, warn on email or phone patterns (01 §7.2).
- [ ] `logic/daily_card_rules.dart`: the same local day returns the same card; this is idempotent (01 §7.6, §17.3).

---

## Sprint 4.4: Ports (interfaces only)

**Tasks:**
- [ ] One file per port in `taro_core/lib/src/ports/`:
  - from 02 §5: `InstallRepository`, `SessionTokenStore`, `BalanceRepository`, `ReadingRepository`, `DailyCardRepository`, `ContentRepository`, `RemoteConfigRepository`, `SettingsRepository`, `ConsentStore`, `IapService`, `PurchaseVerifier`, `PurchaseOutbox`, `EntitlementCache`, `AdsService`, `RewardGateway`, `ConsentService` (UMP), `TrackingAuthorization` (ATT), `AnalyticsService`, `CrashReporter`, `ReminderScheduler`, `AttestationService`, `Clock`, `TimezoneProvider`, `RandomSource`, `FileTransfer`, `ConnectivityMonitor`, `ReviewPrompter`, `AppInfo`, `SecureStore`;
  - added: `IdGenerator`, `Logger` (RC41); `ReportGateway` (CS7); `DataDeletionGateway` (CS15, RC37); `CrisisResourcesRepository` (RC25). **No** `DailyCardWidgetBridge` in v1: it arrives with its adapter in Phase 23.1 (RC89).
- [ ] `IapEvent` sealed (02 §5), `PurchaseOutcome` sealed (04 §6.2), `RewardedShowResult`, `SyncReason`, `SyncStatus`.
- [ ] Use-case classes in `usecases/` (constructor-injected ports; logic tested with fakes in Phase 4.5 and wired in Phase 13): `DrawCards`, `RequestReading`, `ResumeReading`, `SyncAccount`, `PurchaseCredits`, `EarnReward`, `ExportBackup`, `ImportBackup`, `ResolveReadingGate`, `ReportReading`, `DeleteAllData`, `StartClassicReading` (RC20).
- [ ] Analytics: sealed `TaroAnalyticsEvent` with the groups from 01 §15 and 04 §14 (merged and deduplicated; the 04 event names win for monetization). Every param is an enum, int or bool (PR18). Write `docs/ANALYTICS_EVENTS.md` in the same change and keep `check_analytics_events.py` green. Snapshot test of every event's `name` and `parameters`, plus a reflective test that no param is a free-form `String` (01 §17.6).

---

## Sprint 4.5: Test kit (`taro_testing`, QA16)

**Tasks:**
- [ ] `fakes/`: a `FakeX` for every Sprint 4.4 port, with in-memory state and test hooks. Examples:
  - `FakeWorkerGateway.failNext(Failure)`, `FakeIapService.emitPending(productId)`, `FakeIapService.redeliver(txn)`;
  - `FakeAdsService.completeRewarded()`, `FakeConsentService(status)`, `FakeAttestationService(kind)`;
  - `FakeClock.advance`/`setTimeZone`, `SeededRandomSource`, `ScriptedRandomSource`, `SequentialIdGenerator`, `CapturingLogger`, `InMemorySecureStore`.
- [ ] `contracts/`: `runBalanceRepositoryContract`, `runReadingRepositoryContract`, `runIapServiceContract`, `runPurchaseOutboxContract`, `runSecureStoreContract`, `runClockContract`, `runRandomSourceContract`, … (one per port). Each runs against its fake in `taro_testing/test/` now, and against the real adapters in Phases 11–12.
- [ ] `builders/`: `aReading()`, `aDailyCard()`, `aCreditBalance().withFreeRemaining(0).withPaid(3)`, `aRemoteConfig().withRewardedEnabled(false)`, `aBackup().withVersion(1)`, `aCard('major_00').reversed()`, `aSpread('celtic_cross')`. Defaults live in `builders/defaults.dart`; builders never read the clock or RNG.
- [ ] `harness/pump_taro_widget.dart` (`pumpTaroWidget`, Riverpod-free). The `TaroFakes` bundle and the Riverpod-aware `pumpTaro` live in `apps/taro/test/helpers/pump_app.dart` (Phase 13.1), because `taro_testing` must not depend on Riverpod or the app's providers (02 §2.1, AR3, RC77).
- [ ] `check_forbidden_apis.py` passes: `taro_testing` is imported only from `test/` and `integration_test/`.

---

## Done when

- [ ] `taro_core` ≥ 90% (target ~100%) and `taro_testing` ≥ 90% via the contract suites. `check_coverage.py` is green for both.
- [ ] `check_architecture.dart`: `taro_core` has no Flutter or I/O imports.
- [ ] `docs/ANALYTICS_EVENTS.md` and `docs/ARCHITECTURE.md` §Ports and §Domain are updated. CHANGELOG `Unreleased` updated.
- [ ] One commit: `feat(taro): Phase 4 — Core domain, ports & test kit`.

## Next phase

Phase 5: Deck Content Pipeline. Phase 11 (client data layer) also depends on this phase.
