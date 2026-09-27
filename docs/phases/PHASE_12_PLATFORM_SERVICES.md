# Phase 12: Platform Services, IAP, Ads, Consent & Attestation Plugin

**Status:** ⬜ Not Started
**Depends on:** Phase 4. Phase 10 is needed only for the on-device verification sprint (12.6), which is tracked as a **separate exit criterion**: Phase 12 closes when Sprints 12.1–12.5 are done, and 12.6 is ticked later, before Phase 16 (RC83).
**Parallel with:** Phases 7, 8, 11

---

## Overview

This phase implements `taro_services` (every platform SDK adapter behind its port) and the own `taro_attestation` Flutter plugin (Swift App Attest + DeviceCheck, Kotlin Play Integrity **Standard** + `ANDROID_ID`, RC87). It also builds the monetization orchestration that runs outside the widget tree:
- `PurchaseCoordinator` (finish only after the Worker grants);
- `RemoveAdsEntitlement` (never revoke on store silence);
- `PendingPurchaseTracker`;
- `ConsentOrchestrator` (UMP → ATT → Mobile Ads init).

The adapters take SDK entry points by injection, so every branch is unit-tested through platform-interface fakes without a device (02 Testing strategy). Nothing is excluded from coverage except generated code.

**Output of this phase:**
- `packages/taro_services`:
  - `StoreIapService`, `AdMobAdsService`, `AdMobBannerSlotView` (presentation barrel), `UmpConsentService`, `AttTrackingAuthorization`;
  - `FirebaseAnalyticsService`, `ConsentAwareAnalytics`, `CompositeAnalyticsService`, `FirebaseCrashReporter`;
  - `LocalReminderScheduler`, `FlutterTimezoneProvider`, `PlatformFileTransfer`, `ConnectivityPlusMonitor`, `InAppReviewPrompter`, `PackageInfoAppInfo`, `SystemClock`, `SecureRandomSource`, `LoggingLogger` + `Redactor`, `PlatformAttestationService`, `DebugAttestationService`;
  - all NoOp variants.
- The monetization orchestration: `PurchaseCoordinator`, `PendingPurchaseTracker`, `RemoveAdsEntitlement`, `ConsentOrchestrator`, `RewardedController`.
- `packages/taro_attestation` (Dart + Swift + Kotlin) with native tests gated at ≥ 90% (RC40).

---

## Specs referenced

`02_ARCHITECTURE.md` AR9–AR11, AR18, AR19, §5, §6.4, §9.1 step 7, §9.5–§9.7, §13, §15. `04_MONETIZATION.md` MO7, MO8, MO9, MO10, MO12, MO15, MO18, §6.1–§6.7, §9, §10, §12, §15 (client). `05_COMPLIANCE_STORE_ASO.md` CS14, 5.1.2 row (`ConsentOrchestrator`), §6.3. `03_BACKEND_WORKER.md` §3.1, §3.4, §6.1 (binding), §7.1. `01_PRODUCT.md` PR10, PR13, PR18, §7.7. `00_DECISIONS.md` RC9–RC11, RC19, RC33, RC34, RC40, RC41, RC53, RC56, RC57, RC68, RC86, RC87.

---

## Sprint 12.1: `taro_attestation` plugin (AR9, RC12, RC40)

**Tasks:**
- [ ] Dart API: `TaroAttestation.isSupported`, `generateKey()`, `attestKey(keyId, clientDataHash)`, `generateAssertion(keyId, clientDataHash)`, `deviceCheckToken()` (iOS); `prepareStandard(cloudProjectNumber)`, `requestStandardToken(requestHash)`, `androidId()` (Android). Registration on Android uses a Standard token with `requestHash = base64url(SHA256(challenge ‖ installId ‖ deviceKey))` (RC87). There is no Classic API. Errors map to `AttestationFailureKind{unsupported,keyInvalidated,rejected,quota,transient}`.
- [ ] Swift `TaroAttestationPlugin.swift` using `DCAppAttestService` and `DCDevice`. XCTest suite in `example/ios/RunnerTests` behind protocol wrappers `AppAttestServicing` / `DeviceCheckServicing` so the services can be faked.
- [ ] Kotlin `TaroAttestationPlugin.kt` using `StandardIntegrityManager` and `Settings.Secure.ANDROID_ID`. JUnit + Robolectric/MockK suite behind `IntegrityProvider` / `AndroidIdProvider` interfaces.
- [ ] Dart tests via a method-channel mock covering every error mapping. Native coverage is reported by `tools/ci/native_coverage_*.sh` and must be ≥ 90%.
- [ ] `PlatformAttestationService` (in `taro_services`) wraps the plugin and implements the `AttestationService` port, including `deviceSignal()` (`deviceKey = base64url(SHA-256("taro-device-v1" ‖ ANDROID_ID))` computed in Dart; iOS DeviceCheck token; 03 §3.7). `DebugAttestationService` sends the `X-Taro-Debug-Attestation` token and is available only when `!FlavorConfig.isProd`; a prod-build test asserts it is unreachable (02 §15). The Worker honours it only where its deploy env allows it (RC86).

---

## Sprint 12.2: IAP adapter & purchase coordination (AR10, MO8)

**Tasks:**
- [ ] iOS `Info.plist` key `SKIncludeConsumableInAppPurchaseHistory = YES`, so the support "Move readings" flow can re-submit a past consumable transaction (03 §6.6, RC84).
- [ ] `iap/store_iap_service.dart` (the only file importing `in_app_purchase*`; `import_rules.yaml`):
  - StoreKit 2 enabled;
  - `products(Set<ProductId>)` returns localized `price`, `rawPrice` and `currencyCode`;
  - `buy()` sets `applicationUserName` = `purchaseBinding.appleAccountToken` (iOS) or `playAccountId` (Android) (RC9); it is disabled while `purchasesAllowed == false` (RC66);
  - `buyConsumable(autoConsume: Platform.isIOS)`;
  - `finish(tx)` = `completePurchase`, plus `consumePurchase` on Android for consumables;
  - `queryOwnership()` reads SK2 current entitlements or Play `queryPastPurchases` without UI; `restore()` is user-initiated.
- [ ] `iap/purchase_coordinator.dart`, subscribed at construction (before any UI), per 04 §6.2:
  - in-flight dedupe by `deliveryId`;
  - pending → tracker, no Worker call;
  - purchased or restored → `PurchaseOutbox.enqueue` **before** verify;
  - verify result `granted`/`already_granted` → finish + balance update + `iap_purchase_completed` (only on `granted`);
  - `pending` → keep open;
  - `rejected` → finish + fail;
  - transport error or 401/403 → keep unfinished and emit `verificationDeferred`, retrying with backoff (2 s, 10 s, 60 s) and on launch, resume and connectivity until `store.verifyRetryWindowHours` (72), then `iap_verify_stuck`;
  - `422 PURCHASE_INVALID sandbox_cap` → finish (no real money) + neutral message (RC63);
  - `drainOutbox()` API for `SyncCoordinator`.
- [ ] `iap/pending_purchase_tracker.dart`: in memory, lapses after `store.pendingHoldMinutes` (30), with an injected clock.
- [ ] `iap/remove_ads_entitlement.dart` (MO7): the cache is read instantly on launch; `queryOwnership` with a 10 s bound; revoke only when the store answers without the product, never on silence; `Stream<bool> changes`; and `whenOwnershipLoaded()` (2 s) before the first banner load.
- [ ] Tests using `InAppPurchasePlatform.instance = FakeInAppPurchasePlatform()` and `InAppPurchasePlatformAddition` fakes: every scenario in 04 §15 "Unit — PurchaseCoordinator". Include a seeded randomized-order property check that `finish()` is **never** called before a `granted`, `already_granted` or `rejected` response. Run the contract suite `runIapServiceContract` against the real adapter.

---

## Sprint 12.3: Ads & consent (AR11, MO9–MO12, CS14, RC19)

**Tasks:**
- [ ] `consent/ump_consent_service.dart`: `requestConsentInfoUpdate` on every launch with `tagForUnderAgeOfConsent: false`, `loadAndShowConsentFormIfRequired`, `canRequestAds`, `privacyOptionsRequirementStatus`, `showPrivacyOptionsForm`. Debug geography comes from a hidden debug menu in non-prod builds only.
- [ ] `consent/att_tracking_authorization.dart` (iOS) and `NotSupportedTrackingAuthorization` (Android).
- [ ] `consent/consent_orchestrator.dart`:
  - order: onboarding done → UMP → if `canRequestAds` and iOS and ATT `notDetermined` → neutral pre-prompt (`ads.attPrepromptEnabled`, RC19) → ATT → `AdsService.initialize`;
  - `canRequestAds == false` → no SDK init this launch, ads hidden, rewarded disabled with the "Ads unavailable" reason;
  - Firebase consent mode: all purposes denied until resolved, then set from the UMP purposes (02 §9.7, RC68);
  - `Future<void> whenResolved`.
  - Tests: every UMP status × ATT status, and "no `initialize` before `canRequestAds`" (04 §15, 05 Testing).
- [ ] `ads/admob_ads_service.dart`:
  - `initialize`, `loadRewarded({userId: intentId, customData: intentId})` (never the install ID; BE14, RC56), `showRewarded` → `earned|dismissedEarly|failedToShow`;
  - rewarded loaded lazily when S10 opens, expiring after 1 h;
  - NPA requests when consent is denied.
- [ ] `presentation.dart` `AdMobBannerSlotView`: anchored adaptive, loads on first build, disposes on unmount, collapses to zero height on failure (02 §10).
- [ ] `RewardedController` (in `taro_core` usecases + services wiring), per 04 §9.2 and 02 §9.6:
  - `createIntent` → load (timeout `rewarded.loadTimeoutSec` = 10 → `noFill`) → show → on earned, poll `GET /v1/rewards/intents/{id}` every 1.5 s up to `rewarded.grantPollTimeoutSec` (20, RC33) → `granted` or `grantDelayed`;
  - load timeout, show failure or dismissed early → `POST /v1/rewards/intents/{id}/cancel` (best effort), no poll (RC57);
  - after `granted`, return to S07 with Begin enabled; nothing auto-starts (RC58).
  - Eligibility: enabled, not capped, cooldown passed, `canRequestAds`, online, `free.remaining == 0` (RC34).
- [ ] Tests via method-channel mocks (`TestDefaultBinaryMessengerBinding`) for google_mobile_ads, UMP and ATT; `NoOpAdsService` when Remove Ads is owned and rewarded is disabled.

---

## Sprint 12.4: Analytics, crash, logging (AR19, PR18)

**Tasks:**
- [ ] Native consent defaults (RC68): `Info.plist` `GOOGLE_ANALYTICS_DEFAULT_ALLOW_ANALYTICS_STORAGE`, `…_AD_STORAGE`, `…_AD_USER_DATA`, `…_AD_PERSONALIZATION` = `false`; the matching `google_analytics_default_allow_*` `<meta-data>` = `false` in `AndroidManifest.xml`. `FirebaseAnalyticsService.setConsent(AnalyticsConsent.allDenied())` is called at bootstrap before any event.
- [ ] `analytics/firebase_analytics_service.dart` (no user ID; install ID never sent), `ConsentAwareAnalytics` (buffers up to 50 events until `ConsentOrchestrator.whenResolved`, then flushes them or drops them if analytics consent is denied; drops events while collection is disabled), `CompositeAnalyticsService` (Firebase + console in dev), `ConsoleAnalyticsService`. The user properties are from 01 §15. Unit test: **no event reaches the Firebase adapter before `whenResolved`**; denied → buffer dropped; not-required → flushed.
- [ ] `crash/firebase_crash_reporter.dart`: collection bound to the analytics toggle; custom keys `flavor`, `locale`, `sync_status`, `last_route`; non-fatal for every `UnexpectedFailure`.
- [ ] `logging/logging_logger.dart` over `package:logging` with sinks (debug console in dev/staging; Crashlytics breadcrumbs INFO+ in prod), and `Redactor` (tokens, JWS, purchase tokens, the install secret, device key, install IDs truncated to 8 chars, and any `question`, `note` or `body` field). Test the redactor with the sensitive corpus.
- [ ] Tests with `FirebaseAnalyticsPlatform` / `FirebaseCrashlyticsPlatform` fakes.

---

## Sprint 12.5: Remaining adapters

**Tasks:**
- [ ] `notifications/local_reminder_scheduler.dart` (`flutter_local_notifications` + `timezone`):
  - daily reminder at the chosen local time via `zonedSchedule` with **`AndroidScheduleMode.inexactAllowWhileIdle`**, rotating through 6 ARB variants (the locale is passed in), no badge;
  - **no** `SCHEDULE_EXACT_ALARM` / `USE_EXACT_ALARM` in the manifest (Play restricts them on Android 14+);
  - `requestPermission()` asks for `POST_NOTIFICATIONS` (API 33+) / iOS authorization **only** after the user taps "Yes, remind me" (01 §7.7), never at launch;
  - a `RECEIVE_BOOT_COMPLETED` receiver (the plugin's `ScheduledNotificationBootReceiver`) reschedules after reboot;
  - the tap payload `taro://daily` → `Stream<String> taps`;
  - `reschedule` is idempotent (01 §7.7).
- [ ] `timezone/flutter_timezone_provider.dart`, `files/platform_file_transfer.dart` (`share_plus` + `file_picker` `.json`), `connectivity/connectivity_plus_monitor.dart`, `review/in_app_review_prompter.dart` (policy: after the 3rd positively rated reading, at most once per 120 days, never after a refusal; 01 §6.1), `device/package_info_app_info.dart`.
- [ ] `SystemClock` (wraps `package:clock`), `SecureRandomSource` (`Random.secure()`, rejection sampling, plus the `slow` χ² smoke test per 06 §2.1). These are the **only** allowlisted files for `DateTime.now` and `Random.secure` in `check_forbidden_apis.py`.
- [ ] Every adapter passes its `runXContract` suite, and every NoOp variant is tested.

---

## Sprint 12.6: On-device verification *(MANUAL, needs Phase 10)*

**Tasks:**
- [ ] A dev menu screen (non-prod only) in `apps/taro/lib/features/debug/`: attest, register, buy each sandbox product, restore, show rewarded (test unit), UMP debug geography EEA, reset ATT (instructions), schedule a test reminder.
- [ ] On a physical iPhone (TestFlight staging): App Attest registration → `trust: high`; a sandbox pack purchase → Worker grant → finish; Ask to Buy pending; Remove Ads + restore; rewarded SSV grant on the staging unit.
- [ ] On a physical Android device (internal track, `prodStaging`): Play Integrity Standard registration (with the device key bound) + Standard per call; reinstall → same `deviceKey`, no second free reading today; purchase with the license tester including "slow test card" pending; consume after the grant; RTDN delivery.
- [ ] Record the results in the phase notes. Any mismatch between the real behaviour and the fakes is fixed in the fake **and** the contract suite.

---

## Done when

- [ ] `taro_services` ≥ 90%. `taro_attestation` Dart ≥ 90%, and Swift and Kotlin ≥ 90% each (RC40). `check_coverage.py` is green.
- [ ] The `check_forbidden_apis.py` allowlist matches `import_rules.yaml`. SDK imports appear only in adapter files.
- [ ] *(Separate exit criterion, may be ticked after the phase commit, before Phase 16 starts)* The Sprint 12.6 device checks passed on both platforms.
- [ ] Docs: `docs/ARCHITECTURE.md` (purchase, rewarded and consent sequence diagrams), `docs/ANALYTICS_EVENTS.md` (monetization and consent events), CHANGELOG.
- [ ] One commit: `feat(taro): Phase 12 — Platform services & attestation plugin`.

## Next phase

Phase 13: App Shell, State & Flows.
