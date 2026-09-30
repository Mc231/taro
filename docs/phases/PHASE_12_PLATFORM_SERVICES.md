# Phase 12: Platform Services, IAP, Ads, Consent & Attestation Plugin

**Status:** ✅ Complete (2026-09-30) — Sprint 12.6 device checks pending (separate exit criterion)
**Depends on:** Phase 4. Phase 10 is needed only for the on-device verification sprint (12.6), which is tracked as a **separate exit criterion**: Phase 12 closes when Sprints 12.1–12.5 are done, and 12.6 is ticked later, before Phase 16 (RC83).
**Parallel with:** Phases 7, 8, 11

---

## Overview

This phase implements the app's services layer, `apps/taro/lib/services/` (every platform SDK adapter behind its port; a folder of the app, not a package — Reconciled by 00_DECISIONS.md RC95) and the own `taro_attestation` Flutter plugin (Swift App Attest + DeviceCheck, Kotlin Play Integrity **Standard** + `ANDROID_ID`, RC87). It also builds the monetization orchestration that runs outside the widget tree:
- `PurchaseCoordinator` (finish only after the Worker grants);
- `RemoveAdsEntitlement` (never revoke on store silence);
- `PendingPurchaseTracker`;
- `ConsentOrchestrator` (UMP → ATT → Mobile Ads init).

The adapters take SDK entry points by injection, so every branch is unit-tested through platform-interface fakes without a device (02 Testing strategy). Nothing is excluded from coverage except generated code.

**Output of this phase:**
- `apps/taro/lib/services/`:
  - `StoreIapService`, `AdMobAdsService`, `AdMobBannerSlotView` (`services/presentation/`), `UmpConsentService`, `AttTrackingAuthorization`;
  - `FirebaseAnalyticsService`, `ConsentAwareAnalytics`, `CompositeAnalyticsService`, `FirebaseCrashReporter`;
  - `LocalReminderScheduler`, `FlutterTimezoneProvider`, `PlatformFileTransfer`, `ConnectivityPlusMonitor`, `InAppReviewPrompter`, `PackageInfoAppInfo`, `SystemClock`, `SecureRandomSource`, `LoggingLogger` + `Redactor`, `PlatformAttestationService`, `DebugAttestationService`;
  - all NoOp variants.
- The monetization orchestration: `PurchaseCoordinator`, `PendingPurchaseTracker`, `RemoveAdsEntitlement`, `ConsentOrchestrator`, and the rewarded use case `earn_reward.dart` (the `RewardedController` Notifier is app-side, Phase 13).
- `packages/taro_attestation` (Dart + Swift + Kotlin) with native tests gated at ≥ 90% (RC40).

---

## Specs referenced

`02_ARCHITECTURE.md` AR9–AR11, AR18, AR19, §5, §6.4, §9.1 step 7, §9.5–§9.7, §13, §15. `04_MONETIZATION.md` MO7, MO8, MO9, MO10, MO12, MO15, MO18, §6.1–§6.7, §9, §10, §12, §15 (client). `05_COMPLIANCE_STORE_ASO.md` CS14, 5.1.2 row (`ConsentOrchestrator`), §6.3. `03_BACKEND_WORKER.md` §3.1, §3.4, §6.1 (binding), §7.1. `01_PRODUCT.md` PR10, PR13, PR18, §7.7. `00_DECISIONS.md` RC9–RC11, RC19, RC33, RC34, RC40, RC41, RC53, RC56, RC57, RC68, RC86, RC87, RC95.

---

## Sprint 12.1: `taro_attestation` plugin (AR9, RC12, RC40)

**Tasks:**
- [x] Dart API: `TaroAttestation.isSupported`, `generateKey()`, `attestKey(keyId, clientDataHash)`, `generateAssertion(keyId, clientDataHash)`, `deviceCheckToken()` (iOS); `prepareStandard(cloudProjectNumber)`, `requestStandardToken(requestHash)`, `androidId()` (Android). Registration on Android uses a Standard token with `requestHash = base64url(SHA256(challenge ‖ installId ‖ deviceKey))` (RC87). There is no Classic API. Errors map to `AttestationFailureKind{unsupported,keyInvalidated,rejected,quota,transient}`.
  - *Evidence:* `packages/taro_attestation/lib/src/{taro_attestation,taro_attestation_method_channel,attestation_error}.dart`; errors → `TaroAttestationException(AttestationErrorKind)`, mapped exhaustively to `AttestationFailureKind` in `PlatformAttestationService.failureKindOf`.
- [x] Swift `TaroAttestationPlugin.swift` using `DCAppAttestService` and `DCDevice`. XCTest suite in `example/ios/RunnerTests` behind protocol wrappers `AppAttestServicing` / `DeviceCheckServicing` so the services can be faked.
  - *Evidence:* `ios/taro_attestation/Sources/taro_attestation/TaroAttestationPlugin.swift`; `example/ios/RunnerTests/RunnerTests.swift` (15 XCTests, iPhone 17 Pro simulator), `tools/ci/native_coverage_ios.sh` 108/108 lines.
- [x] Kotlin `TaroAttestationPlugin.kt` using `StandardIntegrityManager` and `Settings.Secure.ANDROID_ID`. JUnit + Robolectric/MockK suite behind `IntegrityProvider` / `AndroidIdProvider` interfaces.
  - *Evidence:* `TaroAttestationPlugin.kt`, `IntegrityProvider.kt` (`PlayIntegrityProvider`), `AndroidIdProvider.kt`, `AttestationErrors.kt`; 29 JUnit tests with Mockito (already configured; Robolectric/MockK not needed), `tools/ci/native_coverage_android.sh` 102/102 lines.
- [x] Dart tests via a method-channel mock covering every error mapping. Native coverage is reported by `tools/ci/native_coverage_*.sh` and must be ≥ 90%.
  - *Evidence:* `packages/taro_attestation/test/src/taro_attestation_test.dart` (80 tests, every error code × method); Dart 73/73, iOS 108/108, Android 102/102 (`check_coverage.py`).
- [x] `PlatformAttestationService` (in `apps/taro/lib/services/attestation/`) wraps the plugin and implements the `AttestationService` port, including `deviceSignal()` (`deviceKey = base64url(SHA-256("taro-device-v1" ‖ ANDROID_ID))` computed in Dart; iOS DeviceCheck token; 03 §3.7). `DebugAttestationService` sends the `X-Taro-Debug-Attestation` token and is available only when `!FlavorConfig.isProd`; a prod-build test asserts it is unreachable (02 §15). The Worker honours it only where its deploy env allows it (RC86).
  - *Evidence:* `apps/taro/test/services/attestation/{platform_attestation_service,debug_attestation_service}_test.dart` (`runAttestationServiceContract` on 5 device setups; group "a prod build never reaches it (02 §15, RC86)"). The Worker debug-header wiring in the data layer is Phase 13.

---

## Sprint 12.2: IAP adapter & purchase coordination (AR10, MO8)

**Tasks:**
- [x] iOS `Info.plist` key `SKIncludeConsumableInAppPurchaseHistory = YES`, so the support "Move readings" flow can re-submit a past consumable transaction (03 §6.6, RC84).
  - *Evidence:* `apps/taro/ios/Runner/Info.plist`.
- [x] `iap/store_iap_service.dart` (the only file importing `in_app_purchase*`; `import_rules.yaml`):
  - StoreKit 2 enabled;
  - `products(Set<ProductId>)` returns localized `price`, `rawPrice` and `currencyCode`;
  - `buy()` sets `applicationUserName` = `purchaseBinding.appleAccountToken` (iOS) or `playAccountId` (Android) (RC9); it is disabled while `purchasesAllowed == false` (RC66);
  - `buyConsumable(autoConsume: Platform.isIOS)`;
  - `finish(tx)` = `completePurchase`, plus `consumePurchase` on Android for consumables;
  - `queryOwnership()` reads SK2 current entitlements or Play `queryPastPurchases` without UI; `restore()` is user-initiated.
  - *Evidence:* `apps/taro/lib/services/iap/store_iap_service.dart`; `tools/import_rules.yaml` narrows `in_app_purchase*` to that file; `test/services/iap/store_iap_service_test.dart`.
- [x] `iap/purchase_coordinator.dart`, subscribed at construction (before any UI), per 04 §6.2:
  - in-flight dedupe by `deliveryId`;
  - pending → tracker, no Worker call;
  - purchased or restored → `PurchaseOutbox.enqueue` **before** verify;
  - verify result `granted`/`already_granted` → finish + balance update + `iap_purchase_completed` (only on `granted`);
  - `pending` → keep open;
  - `rejected` → finish + fail;
  - transport error or 401/403 → keep unfinished and emit `verificationDeferred`, retrying with backoff (2 s, 10 s, 60 s) and on launch, resume and connectivity until `store.verifyRetryWindowHours` (72), then `iap_verify_stuck`;
  - `422 PURCHASE_INVALID sandbox_cap` → finish (no real money) + neutral message (RC63);
  - `drainOutbox()` API for `SyncCoordinator`.
  - *Evidence:* `apps/taro/lib/services/iap/purchase_coordinator.dart`; `test/services/iap/purchase_coordinator_test.dart`. The event is the canonical `purchase_completed` (`PurchaseCompletedEvent`, GLOSSARY, 04 §14).
- [x] `iap/pending_purchase_tracker.dart`: in memory, lapses after `store.pendingHoldMinutes` (30), with an injected clock.
  - *Evidence:* `test/services/iap/pending_purchase_tracker_test.dart`.
- [x] `iap/remove_ads_entitlement.dart` (MO7): the cache is read instantly on launch; `queryOwnership` with a 10 s bound; revoke only when the store answers without the product, never on silence; `Stream<bool> changes`; and `whenOwnershipLoaded()` (2 s) before the first banner load.
  - *Evidence:* `test/services/iap/remove_ads_entitlement_test.dart` (silence never revokes; authoritative answer revokes).
- [x] Tests using `InAppPurchasePlatform.instance = FakeInAppPurchasePlatform()` and `InAppPurchasePlatformAddition` fakes: every scenario in 04 §15 "Unit — PurchaseCoordinator". Include a seeded randomized-order property check that `finish()` is **never** called before a `granted`, `already_granted` or `rejected` response. Run the contract suite `runIapServiceContract` against the real adapter.
  - *Evidence:* `test/services/iap/support/fake_in_app_purchase_platform.dart`; 111 IAP tests incl. the 40-seed randomized-order property test (verified to fail when finish-on-transport-error is injected); `runIapServiceContract` over fake StoreKit 2 and fake Play.

---

## Sprint 12.3: Ads & consent (AR11, MO9–MO12, CS14, RC19)

**Tasks:**
- [x] `consent/ump_consent_service.dart`: `requestConsentInfoUpdate` on every launch with `tagForUnderAgeOfConsent: false`, `loadAndShowConsentFormIfRequired`, `canRequestAds`, `privacyOptionsRequirementStatus`, `showPrivacyOptionsForm`. Debug geography comes from a hidden debug menu in non-prod builds only.
  - *Evidence:* `apps/taro/lib/services/consent/ump_consent_service.dart`; `test/services/consent/ump_consent_service_test.dart` (real plugin channels; `runConsentServiceContract`).
- [x] `consent/att_tracking_authorization.dart` (iOS) and `NotSupportedTrackingAuthorization` (Android).
  - *Evidence:* `test/services/consent/att_tracking_authorization_test.dart` (both classes run `runTrackingAuthorizationContract`).
- [x] `consent/consent_orchestrator.dart`:
  - order: onboarding done → UMP → if `canRequestAds` and iOS and ATT `notDetermined` → neutral pre-prompt (`ads.attPrepromptEnabled`, RC19) → ATT → `AdsService.initialize`;
  - `canRequestAds == false` → no SDK init this launch, ads hidden, rewarded disabled with the "Ads unavailable" reason;
  - Firebase consent mode: all purposes denied until resolved, then set from the UMP purposes (02 §9.7, RC68);
  - `Future<void> whenResolved`.
  - Tests: every UMP status × ATT status, and "no `initialize` before `canRequestAds`" (04 §15, 05 Testing).
  - *Evidence:* `test/services/consent/consent_orchestrator_test.dart`: 5 UMP scenarios × 5 ATT statuses, "no initialize before canRequestAds", call order. The on-device TCF purpose read is open (Phase 13): consented EEA users stay all-denied for Firebase until then.
- [x] `ads/admob_ads_service.dart`:
  - `initialize`, `loadRewarded({userId: intentId, customData: intentId})` (never the install ID; BE14, RC56), `showRewarded` → `earned|dismissedEarly|failedToShow`;
  - rewarded loaded lazily when S10 opens, expiring after 1 h;
  - NPA requests when consent is denied.
  - *Evidence:* `apps/taro/lib/services/ads/admob_ads_service.dart` (SSV bound at show time via `setServerSideOptions`; the load timeout lives in the adapter); `test/services/ads/admob_ads_service_test.dart` (`runAdsServiceContract`).
- [x] `services/presentation/banner_slot_view.dart` `AdMobBannerSlotView`: anchored adaptive, loads on first build, disposes on unmount, collapses to zero height on failure (02 §10).
  - *Evidence:* `test/services/presentation/banner_slot_view_test.dart`.
- [x] The rewarded use case `earn_reward.dart` in `taro_core/usecases` (04 §6) + adapters in `apps/taro/lib/services/`; the `RewardedController` Notifier lives in `apps/taro/lib/features/paywall` (Phase 13). Per 04 §9.2 and 02 §9.6:
  - `createIntent` → load (timeout `rewarded.loadTimeoutSec` = 10 → `noFill`) → show → on earned, poll `GET /v1/rewards/intents/{intentId}` every 1.5 s up to `rewarded.grantPollTimeoutSec` (20, RC33) → `granted` or `grantDelayed`;
  - load timeout, show failure or dismissed early → `POST /v1/rewards/intents/{intentId}/cancel` (best effort), no poll (RC57);
  - after `granted`, return to S07 with Begin enabled; nothing auto-starts (RC58).
  - Eligibility: enabled, not capped, cooldown passed, `canRequestAds`, online, `free.remaining == 0` (RC34).
  - *Evidence:* `packages/taro_core/lib/src/usecases/earn_reward.dart` (+ required `ConnectivityMonitor`, offline → `NetworkFailure`); `packages/taro_core/test/src/usecases/earn_reward_test.dart`. `RewardedController` is Phase 13.
- [x] Tests via method-channel mocks (`TestDefaultBinaryMessengerBinding`) for google_mobile_ads, UMP and ATT; `NoOpAdsService` when Remove Ads is owned and rewarded is disabled.
  - *Evidence:* `test/services/{ads,consent,presentation}/` (122 tests); `NoOpAdsService.applies` covered in `admob_ads_service_test.dart`.

---

## Sprint 12.4: Analytics, crash, logging (AR19, PR18)

**Tasks:**
- [x] Native consent defaults (RC68): `Info.plist` `GOOGLE_ANALYTICS_DEFAULT_ALLOW_ANALYTICS_STORAGE`, `…_AD_STORAGE`, `…_AD_USER_DATA`, `…_AD_PERSONALIZATION` = `false`; the matching `google_analytics_default_allow_*` `<meta-data>` = `false` in `AndroidManifest.xml`. `FirebaseAnalyticsService.setConsent(AnalyticsConsent.allDenied())` is called at bootstrap before any event.
  - *Evidence:* `Info.plist` `GOOGLE_ANALYTICS_DEFAULT_ALLOW_*` (the ad-personalization key is Firebase's `…_AD_PERSONALIZATION_SIGNALS`), manifest `google_analytics_default_allow_*` (present in the merged dev manifest). The bootstrap `setConsent(allDenied)` call is wired in Phase 13 (DI); `ConsentOrchestrator` also sets it before UMP.
- [x] `analytics/firebase_analytics_service.dart` (no user ID; install ID never sent), `ConsentAwareAnalytics` (buffers up to 50 events until `ConsentOrchestrator.whenResolved`, then flushes them or drops them if analytics consent is denied; drops events while collection is disabled), `CompositeAnalyticsService` (Firebase + console in dev), `ConsoleAnalyticsService`. The user properties are from 01 §15. Unit test: **no event reaches the Firebase adapter before `whenResolved`**; denied → buffer dropped; not-required → flushed.
  - *Evidence:* `test/services/analytics/{firebase_analytics_service,consent_aware_analytics,analytics_backends}_test.dart` ("no event reaches Firebase before whenResolved", denied → dropped, not required → flushed in order).
- [x] `crash/firebase_crash_reporter.dart`: collection bound to the analytics toggle; custom keys `flavor`, `locale`, `sync_status`, `last_route`; non-fatal for every `UnexpectedFailure`.
  - *Evidence:* `test/services/crash/firebase_crash_reporter_test.dart` (`runCrashReporterContract` on Firebase and NoOp).
- [x] `logging/logging_logger.dart` over `package:logging` with sinks (debug console in dev/staging; Crashlytics breadcrumbs INFO+ in prod), and `Redactor` (tokens, JWS, purchase tokens, the install secret, device key, install IDs truncated to 8 chars, and any `question`, `note` or `body` field). Test the redactor with the sensitive corpus.
  - *Evidence:* `test/services/logging/{logging_logger,redactor}_test.dart` (22-line sensitive corpus; no secret survives).
- [x] Tests with `FirebaseAnalyticsPlatform` / `FirebaseCrashlyticsPlatform` fakes.
  - *Evidence:* `test/services/analytics/firebase_fakes.dart` (platform-interface fakes + mocked core app).

---

## Sprint 12.5: Remaining adapters

**Tasks:**
- [x] `notifications/local_reminder_scheduler.dart` (`flutter_local_notifications` + `timezone`):
  - daily reminder at the chosen local time via `zonedSchedule` with **`AndroidScheduleMode.inexactAllowWhileIdle`**, rotating through 6 ARB variants (the locale is passed in), no badge;
  - **no** `SCHEDULE_EXACT_ALARM` / `USE_EXACT_ALARM` in the manifest (Play restricts them on Android 14+);
  - `requestPermission()` asks for `POST_NOTIFICATIONS` (API 33+) / iOS authorization **only** after the user taps "Yes, remind me" (01 §7.7), never at launch;
  - a `RECEIVE_BOOT_COMPLETED` receiver (the plugin's `ScheduledNotificationBootReceiver`) reschedules after reboot;
  - the tap payload `taro://daily` → `Stream<String> taps`;
  - `reschedule` is idempotent (01 §7.7).
  - *Evidence:* `apps/taro/lib/services/notifications/local_reminder_scheduler.dart`; manifest `RECEIVE_BOOT_COMPLETED` + plugin receivers + `tools:node="remove"` for both exact-alarm permissions (merged dev manifest checked: none present); `AppDelegate.swift` notification delegate; `test/services/notifications/local_reminder_scheduler_test.dart` (33 tests). Reminder ARB keys (6 variants + channel) are added with the Phase 13 DI (`ReminderCopy`).
- [x] `timezone/flutter_timezone_provider.dart`, `files/platform_file_transfer.dart` (`share_plus` + `file_picker` `.json`), `connectivity/connectivity_plus_monitor.dart`, `review/in_app_review_prompter.dart` (policy: after the 3rd positively rated reading, at most once per 120 days, never after a refusal; 01 §6.1), `device/package_info_app_info.dart`.
  - *Evidence:* `test/services/{timezone,files,connectivity,review,device}/`. "Never after a refusal": neither store reports a refusal, so `InAppReviewPrompter.recordRefusal()` exists but has no caller yet (product decision open). State under the secure key `taro.review_prompt` (GLOSSARY §12, `SecureKeys.reviewPrompt`).
- [x] `SystemClock` (wraps `package:clock`), `SecureRandomSource` (`Random.secure()`, rejection sampling, plus the `slow` χ² smoke test per 06 §2.1). These are the **only** allowlisted files for `DateTime.now` and `Random.secure` in `check_forbidden_apis.py`.
  - *Evidence:* Kept in `taro_core/lib/src/ports/` (GLOSSARY §9; a second class in the app would clash with the core export). `packages/taro_core/test/src/ports/secure_random_source_test.dart` (rejection sampling + `slow` χ² 1,000,000 draws of 0..77). The `api_allowlist` also keeps `apps/taro/lib/services/**/{system_clock,secure_random_source}.dart` globs (no such files; the `check_forbidden_apis` pytest pass fixtures use them).
- [x] Every adapter passes its `runXContract` suite, and every NoOp variant is tested.
  - *Evidence:* `apps/taro/test/services/**` (all adapters and NoOp variants).

---

## Sprint 12.6: On-device verification *(MANUAL, needs Phase 10)*

**Tasks:**
- [ ] A dev menu screen (non-prod only) in `apps/taro/lib/features/debug/`: attest, register, buy each sandbox product, restore, show rewarded (test unit), UMP debug geography EEA, reset ATT (instructions), schedule a test reminder.
- [ ] On a physical iPhone (TestFlight staging): App Attest registration → `trust: high`; a sandbox pack purchase → Worker grant → finish; Ask to Buy pending; Remove Ads + restore; rewarded SSV grant on the staging unit.
- [ ] On a physical Android device (internal track, `prodStaging`): Play Integrity Standard registration (with the device key bound) + Standard per call; reinstall → same `deviceKey`, no second free reading today; purchase with the license tester including "slow test card" pending; consume after the grant; RTDN delivery.
- [ ] Record the results in the phase notes. Any mismatch between the real behaviour and the fakes is fixed in the fake **and** the contract suite.

---

## Done when

- [x] `apps/taro` ≥ 90% with every `lib/services/` file ≥ 70%; `check_architecture.dart` green (`services/` never imports `data/`, `features/` or `taro_ui`). `taro_attestation` Dart ≥ 90%, and Swift and Kotlin ≥ 90% each (RC40). `check_coverage.py` is green.
  - *Evidence:* `check_coverage.py --verify-sonar` PASS: apps/taro 100 % (every `lib/services/` file 100 %), taro_attestation Dart/Swift/Kotlin 100 % each (Phase 12 notes below).
- [x] The `check_forbidden_apis.py` allowlist matches `import_rules.yaml`. SDK imports appear only in adapter files.
  - *Evidence:* The check reads `api_allowlist` and `sdk_packages` from `tools/import_rules.yaml` itself; `check_forbidden_apis: OK`, `check_architecture: OK`.
- [ ] *(Separate exit criterion, may be ticked after the phase commit, before Phase 16 starts)* The Sprint 12.6 device checks passed on both platforms.
- [x] Docs: `docs/ARCHITECTURE.md` (purchase, rewarded and consent sequence diagrams), `docs/ANALYTICS_EVENTS.md` (monetization and consent events), CHANGELOG.
  - *Evidence:* `docs/ARCHITECTURE.md` §Services layer (map + purchase, rewarded, consent mermaid diagrams, dependency notes), `docs/ANALYTICS_EVENTS.md` §Emitters in the services layer (no new events), `CHANGELOG.md` Unreleased.
- [ ] One commit: `feat(taro): Phase 12 — Platform services & attestation plugin`.

## Phase 12 notes (2026-09-30)

**Verification (`tools/verify.sh`, full):** format, analyze (`--fatal-infos`, 6 packages), every repo check (incl. `check_forbidden_apis`, `check_architecture` 545 files, `check_glossary`, `check_skadnetwork` 49 IDs, `check_analytics_events` 74/74), content checks, gitleaks, shellcheck, actionlint and worker lint/typecheck/prettier pass; tests: apps/taro 1205, taro_core 1244, taro_attestation 80 (+3 example), taro_ui 30, dart_tools 298, tools pytest 594. Builds: `flutter build ios --simulator --flavor dev` and `flutter build apk --debug --flavor dev` succeed; the merged dev manifest has no exact-alarm permission and carries the four `google_analytics_default_allow_*` = false.

**Coverage (`check_coverage.py --verify-sonar`, PASS):**

| Unit | Lines | % |
|---|---:|---:|
| apps/taro | 4243/4243 | 100.00 (every `lib/services/` file 100) |
| taro_attestation (Dart) | 73/73 | 100.00 |
| taro_attestation_ios (Swift) | 108/108 | 100.00 |
| taro_attestation_android (Kotlin) | 102/102 | 100.00 |
| taro_core | 2392/2392 | 100.00 |
| worker | 3572/3584 | 99.67 (branches 96.21) |
| tools | 3954/3972 | 99.55 |

**Wrap-up fixes:** `SecureKeys.reviewPrompt` added to `data/secure/keys.dart` (GLOSSARY §12 row from 12.5; `check_glossary` failed) plus the `check_glossary` fixture trees; three NoOp tests instantiate non-const so their constructor lines are covered (`AlwaysOnlineMonitor` was 66.67 % < 70 %).

**Open for Phase 13 (DI and flows):** providers for every adapter; `PurchaseCoordinator` + `RemoveAdsEntitlement.refresh()` + `drainOutbox()` and `PlatformAttestationService.warmUp()` in `SyncCoordinator`; `DebugAttestationService.headers` added to Worker requests (`HeadersInterceptor` has no hook yet) and the `bootstrap_test` prod assertion; bootstrap `setConsent(allDenied)` and `ConsentAwareAnalytics` over the composite; `Redactor.registerInstallId/registerSecret`; crash custom keys on locale/sync/route changes; ATT pre-prompt and debug-EEA hooks; `StoreController` over `PurchaseCoordinator.buy` (overlaps `PurchaseCredits`); `consent_ump_result` / `consent_att_result`, `purchase_started` and the rewarded events; reminder ARB keys (6 variants + channel) in all 12 locales; `NSUserTrackingUsageDescription` in `InfoPlist.strings` × 12; the on-device TCF purpose read (`IABTCF_PurposeConsents`, until then consented EEA users are all-denied for Firebase); a monochrome Android notification small icon.

**Owner decision needed:** what counts as a review "refusal" (neither store reports it; `InAppReviewPrompter.recordRefusal()` has no caller).

**Device-only (Sprint 12.6):** App Attest / DeviceCheck / Play Integrity real tokens; the 1 s SK2 restore settle; Play "already owned" message text; acknowledge-then-consume after a Worker acknowledge; Ask to Buy / slow test card; SK2 redelivery at launch; UMP EEA debug geography; ATT prompt; AdMob test rewarded + SSV to staging and the earned-vs-dismissed callback order; banner rendering; reminder firing inexactly after reboot/update and `POST_NOTIFICATIONS` timing; iOS notification delegate + `taro://daily`; file picker `.json` filter; iPad share popover; review sheet; Firebase consent defaults and DebugView once the Firebase projects exist.

## Next phase

Phase 13: App Shell, State & Flows.
