# Release runbook

Living copy of the release checklist in `06_QUALITY_TESTING_CI.md` §12, with the command for each step. Filled in Phases 10 and 21.

## Build and automated checks

- [ ] `eval:safety` passed against staging with the production prompt version for **every routed provider + model** (the `ai.provider.*` / `ai.model.*` pair of `paid`, `free` and `freeFallback`, plus `ai.outageFallback.*` when set; 05 §4.3, RC60, RC97), and the full report is committed under `worker/evals/reports/`. The weekly Monday `eval:safety` smoke run in `nightly.yml` is green. Command: `cd worker && npm run eval:safety -- --env staging --provider <p> --model <m> --prompt <v> --max-usd <approved>` (see `docs/runbooks/AI_SAFETY.md`).

### `prodStaging` build configuration (02 §15, RC78): not built yet

Deferred on 2026-10-03 (Phase 10 Sprint 10.3): it is only usable once the fastlane lanes (Sprint 10.5) exist, and the Android half does not fit `flutter build` (the tool builds only `debug|profile|release` build types per `--flavor`; a `prodStaging` build type is reachable only through Gradle tasks with `-Pdart-defines`). Steps when it is picked up:

1. `apps/taro/config/prod_staging.json`: a copy of `prod.json` with `apiBaseUrl` = `https://api-staging.taro.vshyrochuk.com` and Google's test AdMob IDs (as in `staging.json`). `FlavorConfig` must accept `flavor: "prod"` with the staging host (prod bundle, so `isProd` stays true and IAP is the real `StoreIapService`). Test `apps/taro/test/config/prod_staging_config_test.dart`: prod bundle, staging URL, test ad IDs.
2. Firebase (02 §15 row "Firebase project" = `taro-app-dev`): register `com.vshyrochuk.taro` in `taro-app-dev` with `flutterfire configure --project=taro-app-dev --platforms=ios,android --ios-bundle-id=com.vshyrochuk.taro --android-package-name=com.vshyrochuk.taro --out=lib/firebase_options_prod_staging.dart --ios-out=ios/Config/prodStaging/GoogleService-Info.plist --android-out=android/app/src/prodStaging/google-services.json`, discard its `project.pbxproj` / Gradle edits, and add `lib/main_prod_staging.dart` (`Flavor.prod` + those options). The gitleaks path allowlist and the coverage exclusions already match `firebase_options_*.dart`; extend the gitleaks path regexes with `prodStaging`.
3. iOS: build configurations `Debug-prodStaging` / `Profile-prodStaging` / `Release-prodStaging` (duplicate the `-prod` ones in Xcode for the project and both targets), `Config/ProdStaging.xcconfig` (`PRODUCT_BUNDLE_IDENTIFIER = com.vshyrochuk.taro`, `APP_DISPLAY_NAME = Taro`, Google test `ADMOB_APP_ID`, `FIREBASE_CONFIG_FLAVOR = prodStaging`) plus the three `{Debug,Profile,Release}-prodStaging.xcconfig` includes, the Podfile `project` mapping (`'Debug-prodStaging' => :debug`, …), `pod install`, and a shared scheme `prodStaging` (flutter's `--flavor prodStaging` then picks it). Entitlements: Debug → `RunnerDebug.entitlements`, others → `Runner.entitlements`.
4. Android: a `prodStaging` product flavor in dimension `env` with no `applicationIdSuffix` (same `applicationId` as prod; Play accepts any upload signed with the app key) is the `flutter build`-compatible form of the spec's build type; record the deviation as an RC before doing it.
5. fastlane `ios beta_internal` (internal TestFlight group only, RC63) and `android internal_staging` (internal track); staging Worker `attest.allowedAppIds` / `purchases.allowedBundleIds` include the prod IDs (RC78).

## Real-device checks

## Store

## Tag and submit

## Evidence log
