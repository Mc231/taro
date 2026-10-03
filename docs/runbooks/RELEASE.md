# Release runbook

Living copy of the release checklist in `06_QUALITY_TESTING_CI.md` §12, with the command for each step. Filled in Phases 10 and 21.

## Accounts and IDs (non-secret)

| What | Value |
|---|---|
| Apple team | `M3FHKUJ7Z3` (Volodymyr Shyrochuk; the team that owns the bundle IDs, the distribution certificate and the ASC app; the repo had `9QX258UF65` until 2026-10-03) |
| App Store Connect app | `6818775977`, SKU `com.vshyrochuk.taro` |
| Bundle IDs | prod `com.vshyrochuk.taro` (96DZ6A82QT), staging `com.vshyrochuk.taro.stg` (4FBT4YG35K), dev `com.vshyrochuk.taro.dev` (7PXM43WGQX) |
| Distribution certificate | "Apple Distribution: Volodymyr Shyrochuk (M3FHKUJ7Z3)", ASC id `7D3BS8PXCS`, expires 2027-01-16 (shared with quiz_apps) |
| App Store profiles | `Taro iOS Distribution` (prod), `Taro Stg iOS Distribution`, `Taro Dev iOS Distribution`; files in `~/pet/secure/taro/`; expire with the certificate |
| ASC API key (fastlane upload) | the asa key (`APP_STORE_CONNECT_API_KEY_ID` / `_ISSUER_ID` / `_KEY_PATH` in `~/.zshrc`); bundle `shared.app_store_connect_api_key_*` for CI |
| Play package | `com.vshyrochuk.taro`; first AAB `0.1.0+1` uploaded by hand (Play App Signing on) |
| Play upload key | `~/pet/secure/taro/taro_upload.jks`, alias `upload`; bundle `taro.android_*` |
| Play release service account | bundle `shared.google_play_service_account_base64` (see § Google Play upload access) |
| Firebase | `taro-app-prod` (prod), `taro-app-dev` (dev + staging) |
| Gitea secret | `SECRETS_PASSPHRASE` (unlocks `.secrets/secrets.json.gpg`) |

## Signing

- iOS Release configurations sign manually (`apps/taro/ios/Config/Release-<flavor>.xcconfig`: `CODE_SIGN_STYLE = Manual`, Apple Distribution, `PROVISIONING_PROFILE_SPECIFIER` = the profile name above). Debug and Profile stay automatic. `flutter build ipa` exports with `ios/ExportOptions/prod.plist`.
- Profiles are created with asa: `asa signing create-profile -b <bundle> -a "Taro[ Stg| Dev]" --output-dir ~/pet/secure/taro`. Regenerate them after any App ID capability change and when the certificate is renewed, then refresh the bundle: `tools/secrets-manager.sh decrypt && tools/secrets-manager.sh set-file taro ios_provisioning_profile_base64 ~/pet/secure/taro/Taro_iOS_Distribution.mobileprovision` (`_stg_` / `_dev_` keys for the others) `&& tools/secrets-manager.sh encrypt`.
- The App IDs need **Associated Domains** (Runner.entitlements `applinks:taro.vshyrochuk.com`); App Attest is entitlement-only.
- CI imports the certificate (`shared.apple_distribution_cert_base64` / `_password`, the quiz_apps `.p12`) into a throwaway keychain in `$RUNNER_TEMP` and installs only the prod profile.

## Deploy workflows

Gitea → Actions → run on a SHA where `CI` is green (both workflows re-check the `CI / coverage-gate` status and stop otherwise).

- **Deploy iOS** (`deploy-ios.yml`): `lane` = `beta` (TestFlight, internal groups only, RC63) or `release` (App Store Connect binary; `submit_for_review` submits it; metadata stays with asa). `build_number` optional; the default is max(last TestFlight build + 1, pubspec).
- **Deploy Android** (`deploy-android.yml`): `track` = `internal` | `closed` (Play `alpha`) | `production`, `release_status` = `draft` | `completed`; `upload: false` builds the AAB only (artifact `taro-prod-aab`), `validate_only: true` validates the Play edit. The version code defaults to max(highest Play version code + 1, pubspec).
- Both: `check_changelog` (a `## [X.Y.Z]` section for `release` / `production`), secrets decrypted into `$RUNNER_TEMP`, masked, deleted in an `always()` step.
- Locally (from `apps/taro/fastlane`, `BUNDLE_PATH=~/.gem/taro-bundle bundle install` once): `bundle exec fastlane ios beta` (asa key from `~/.zshrc`, certificate in the login keychain, profile installed in `~/Library/MobileDevice/Provisioning Profiles`); `TARO_KEY_PROPERTIES=~/pet/secure/taro/key.properties bundle exec fastlane android deploy upload:false`.

### Google Play upload access

`deploy-android.yml` uploads with `shared.google_play_service_account_base64`. The Worker's `taro-worker@taro-app-prod` account only has the order/financial permissions (Phase 10.4). Before the first workflow upload, the owner either copies the quiz_apps Play release service account into that key, or grants an account in Play Console → Users and permissions → the account → app "Taro: Tarot Card Reading" → **Release apps to testing tracks** and **Release to production, exclude devices, and use Play App Signing**, then stores its JSON key there (*MANUAL*).

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

### 2026-10-03 — Signing and first builds (Phase 10.3 / 10.6)

- `asa signing create-profile` created `Taro iOS Distribution` (99KF783593), `Taro Stg iOS Distribution` (4L67WXP8MM) and `Taro Dev iOS Distribution` (W7987YJM4D) → `~/pet/secure/taro/`. Defects found: (1) asa's bundle-ID lookup was a prefix match, so the prod-named profile was bound to `com.vshyrochuk.taro.stg` (fixed in `app-store-automation` `get_bundle_id`, exact match + test); (2) the App IDs lack Associated Domains, so no profile carries `com.apple.developer.associated-domains`. Owner action: enable Associated Domains on the 3 App IDs, delete the 3 profiles, re-run `create-profile`, store them in the bundle.
- Secrets bundle: `shared.apple_team_id`, `apple_distribution_cert_*`, `app_store_connect_api_*` and `google_play_service_account_base64` exist but are empty; fill them from the quiz_apps bundle (owner).
- Android: `TARO_KEY_PROPERTIES=~/pet/secure/taro/key.properties BUILD_NUMBER=2 bundle exec fastlane android deploy upload:false` built `build/app/outputs/bundle/prodRelease/app-prod-release.aab` (`0.1.0+2`, prod, obfuscated, signed with the upload key) in 164 s and uploaded the Dart symbols to Crashlytics (`taro-app-prod` Android app). Not uploaded to Play (owner).
- iOS: first TestFlight build pending the profile fix above.

