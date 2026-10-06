# Phase 10: Accounts, Store Registration, AdMob, Firebase & Signing

**Status:** 🟡 In progress — accounts/stores/signing done; Android CI/internal track and website pending
**Depends on:** Phase 1 (owner decisions), Phase 9 (for Sprint 10.3), Phase 6 Sprint 6.5 (staging Worker URL, only for the webhook and SSV registration steps). The Cloudflare setup formerly in Sprint 10.1 now lives in Phase 6 Sprint 6.0, which removes the 6 ↔ 10 cycle (RC83); the AI provider accounts (Anthropic, OpenAI) are Phase 8 Sprint 8.0 (RC97).
**Parallel with:** Phases 4–8, 11–13. Most of this phase is **MANUAL** console work, so it can run beside coding.

---

## Overview

This phase registers every external store/ads account and identifier Taro needs, and wires their credentials into the secrets bundle and Worker secrets (Cloudflare is done in Phase 6 Sprint 6.0 and the AI provider accounts in Phase 8 Sprint 8.0, RC97):
- Firebase projects;
- App Store Connect (bundle IDs, app record, IAP products, API keys, server notifications);
- Google Play Console (app, first AAB, IAP products, RTDN, Play Integrity, service account);
- AdMob (apps, units, SSV, UMP messages, content rating);
- signing material and fastlane deploy workflows.

It follows the quiz_apps phase pattern (Phases 3, 5, 6, 8, 10) but with Taro's differences: no Game Center, App Attest capability, Lifestyle category, and server-side verification keys.

**Output of this phase:**
- Real IDs recorded in `apps/taro/config/prod.json` (AdMob), `apps/taro/store/aso.yaml` (`admob:` block), and `~/pet/secure/taro/` (credentials, never committed).
- Staging and prod Worker secrets set; the Worker custom domains resolve.
- IAP products `readings_3`, `readings_10`, `readings_30` and `remove_ads` exist in ASC and Play (not yet submitted).
- The first TestFlight build (`deploy-ios.yml` lane `beta`) and the first internal-track AAB (manual upload) are live.

---

## Specs referenced

`05_COMPLIANCE_STORE_ASO.md` CS1, CS4, CS5, CS9, CS10, CS16, §1 technical declarations, §6.3, §8.1, §8.3 (M1–M11), §8.4. `03_BACKEND_WORKER.md` §3.3 (App Attest team ID), §6, §7, §11 (secrets), Q5. `04_MONETIZATION.md` MO17, §4, §4.1, §10 (UMP console), §15 (StoreKit file). `02_ARCHITECTURE.md` AR17, AR19, §15. `06_QUALITY_TESTING_CI.md` QA10, §8 (`deploy-ios.yml`, `deploy-android.yml`). `00_DECISIONS.md` RC3, RC9, RC36.

---

## Sprint 10.1: *(moved to Phase 6 Sprint 6.0, RC83)*

**Tasks:**
- [x] Confirm Phase 6 Sprint 6.0 is done (Cloudflare zone and resources, Worker secrets) and Phase 8 Sprint 8.0 is done (AI provider accounts and keys for every provider in `ai.disclosedProviders` that the config routes to: Anthropic workspaces, OpenAI projects; RC97). Add the store-issued secrets from Sprints 10.3–10.4 (`APPLE_ASC_*`, `APPLE_DEVICECHECK_*`, `GOOGLE_*`) with `wrangler secret put` and to `docs/runbooks/SECRET_ROTATION.md`. _Evidence: Phases 6 and 8 ✅ (README). Staging: `GOOGLE_SERVICE_ACCOUNT_JSON`, `GOOGLE_PUBSUB_AUDIENCE`, `GOOGLE_PUBSUB_SA`, `APPLE_ASC_*` (IAP key `822W5796Q2`), `APPLE_DEVICECHECK_*` (key `GR7LBHKHFS`) set (STORE_SUBMISSION.md Evidence log 2026-10-03 "Google Cloud for the Worker"). Prod: every secret set by `tools/ci/set_prod_worker_secrets.sh` (owner-authorized; `wrangler secret bulk --env prod`, copy in bundle `worker.prod_worker_secrets_json_base64`, no `DEBUG_ATTESTATION_TOKEN`, RC86). Rotation steps: `docs/runbooks/SECRET_ROTATION.md` § App Store Server API key, § Play service account._

---

## Sprint 10.2: Firebase *(scripted + MANUAL)*

**Tasks:**
- [x] Create the Firebase projects `taro-app-dev` (used by dev and staging) and `taro-app-prod` (RC36). Enable Analytics and Crashlytics only; no Remote Config, FCM or App Check (AR19). Link GA4. _Evidence: projects `taro-app-dev` (dev + stg apps) and `taro-app-prod` (prod app), iOS + Android (original IDs taken globally; RC36 owner override); only `firebase_analytics` + `firebase_crashlytics` linked; Analytics linked by the owner in the console (STORE_SUBMISSION.md Evidence log 2026-10-03 "App Store Connect via asa")._
- [x] `flutterfire configure` per flavor → `apps/taro/lib/firebase_options_{dev,staging,prod}.dart` (excluded per RC16), `ios/config/<flavor>/GoogleService-Info.plist`, `android/app/src/<flavor>/google-services.json`. _(Done 2026-10-03, commit `af5ac03`: `apps/taro/lib/firebase_options_{dev,staging,prod}.dart`, `apps/taro/ios/Config/{dev,staging,prod}/GoogleService-Info.plist`, `apps/taro/android/app/src/{dev,staging,prod}/google-services.json`, `apps/taro/firebase.json`. Wiring: `main_<flavor>.dart` → `ProductionEnvironment(firebaseOptions:)`; iOS build phase "Copy GoogleService-Info.plist" (`FIREBASE_CONFIG_FLAVOR` in `Config/{Dev,Staging,Prod}.xcconfig`); Gradle plugin `com.google.gms.google-services` 4.4.4. Coverage exclusion `**/firebase_options_*.dart` already in `tools/coverage_exclusions.txt`, `sonar-project.properties`, 06 §5.3; gitleaks path allowlist in `.gitleaks.toml`. Tests: `test/bootstrap/firebase_options_test.dart`, `taro_environment_test.dart` "initFirebase passes the flavor options (Sprint 10.2)". `flutter build ios --simulator` and `flutter build apk --debug` green for dev, staging, prod.)_
- [x] Add the SHA-1 and SHA-256 fingerprints of the upload key and the Play App Signing key to the Android apps *(MANUAL; after Sprint 10.4)*. _Evidence: both keys' SHA-1/SHA-256 on the `taro-app-prod` Android app; app-signing SHA-256 in `web/.well-known/assetlinks.json` (commit `1192824`; fingerprints in STORE_SUBMISSION.md Evidence log 2026-10-03 "Google Play")._

---

## Sprint 10.3: Apple *(asa + MANUAL)*

**Tasks:**
- [x] `asa validate -c apps/taro/store/aso.yaml` with the draft from 05 §8.1 (copied into the repo now; completed in Phase 20). _Evidence: re-run 2026-10-04 "✓ apps/taro/store/aso.yaml: store fields valid"; CI step in `.gitea/workflows/reusable-static.yml` (Phase 9)._
- [x] `asa ios create-bundle-id` / `bootstrap-app -c …`:
  - bundle ID `com.vshyrochuk.taro` with capabilities IAP + App Attest and **no Game Center** (ASA-2);
  - app record "Taro: Tarot Card Reading", Lifestyle + Entertainment (ASA-1);
  - SKU `com.vshyrochuk.taro`;
  - fallback name option C if the name is taken (05 §9.2).
  - _Evidence: bundle ID `com.vshyrochuk.taro` (96DZ6A82QT), IN_APP_PURCHASE, no Game Center; App Attest + Associated Domains ticked by the owner in the developer portal (ASC rejects APP_ATTEST via the API, asa `480488b`/`0feca31`). App record `6818775977`, SKU `com.vshyrochuk.taro`, created by the owner in the ASC UI (the API can no longer create apps); `bootstrap-app` set LIFESTYLE / ENTERTAINMENT. Name not taken, no fallback needed. STORE_SUBMISSION.md Evidence log 2026-10-03; RELEASE.md § Accounts and IDs; commit `9673626`._
- [x] Register the dev and staging bundle IDs `com.vshyrochuk.taro.dev` / `.stg` (App Attest capability) for local and ad-hoc testing of the non-prod flavors. _(App side done 2026-10-03 (`af5ac03`): `com.apple.developer.devicecheck.appattest-environment` in `ios/Runner/Runner.entitlements` (`production`, Release/Profile) and `ios/Runner/RunnerDebug.entitlements` (`development`, Debug).)_ *(2026-10-03: registered via asa: com.vshyrochuk.taro (prod), .dev (7PXM43WGQX), .stg (4FBT4YG35K), IN_APP_PURCHASE; App Attest must be ticked in the developer portal (the API cannot); done by the owner on all 3 App IDs, with Associated Domains.)*
- [ ] **`prodStaging` build configuration** (02 §15, RC78) for sandbox IAP testing against the staging Worker:
  - iOS: scheme `ProdStaging` + `Config/ProdStaging.xcconfig` (prod bundle ID, `API_BASE_URL` = staging host, Google test AdMob IDs);
  - Android: build type `prodStaging` on the `prod` flavor (prod `applicationId`);
  - `apps/taro/config/prod_staging.json`;
  - fastlane lanes `ios beta_internal` (internal TestFlight group only, never a public link, RC63) and `android internal_staging` (internal track);
  - staging Worker config: `attest.allowedAppIds` includes `{TEAM}.com.vshyrochuk.taro`, `com.vshyrochuk.taro` and the `.stg` IDs; `purchases.allowedBundleIds` includes `com.vshyrochuk.taro`;
  - test: `test/config/prod_staging_config_test.dart` asserts the prod bundle + staging URL + test ad IDs.
  - _OPEN: documented only, not built — steps (incl. the `flutter build` limit on custom Android build types) in `docs/runbooks/RELEASE.md` § `prodStaging` build configuration._
- [x] IAP products (MO §4, RC3; Remove Ads display name "Remove Banner Ads", RC80): `asa ios create-iap` ×4, `set-all-iap-prices` (tiers per the Phase 1 owner decision), `set-all-iap-availability`, and `localize-all-iaps` (EN now; 12 locales in Phase 20). Remove Ads: **Family Sharing on** (MO17, irreversible; owner confirms). Review screenshots are attached in Phase 20 (M10). _Evidence: `remove_ads` (non-consumable, tier 4), `readings_3` (tier 2), `readings_10` (tier 5), `readings_30` (tier 10); prices and availability (175 territories) set; 48 localizations (4 × 12, all locales already). Also done here: 12-locale listings via `push-localizations`, age rating from config with `ageRatingOverrideV2 = THIRTEEN_PLUS` (13+), app availability 154 territories / 21 excluded (`set-app-availability`). STORE_SUBMISSION.md Evidence log 2026-10-03; commit `9673626`._
- [ ] App Store Connect *(MANUAL, M8/M9)*:
  - [ ] Paid Apps agreement, tax and banking — _owner to confirm_;
  - [ ] Small Business Program enrolment (04 §4.1) — _owner to confirm_;
  - [x] In-App Purchase key (`.p8`) → Worker secrets `APPLE_ASC_ISSUER_ID`, `APPLE_ASC_KEY_ID`, `APPLE_ASC_PRIVATE_KEY`, plus `APPLE_TEAM_ID` (03 §11) — _key `822W5796Q2`, team `M3FHKUJ7Z3`; staging + prod (`tools/ci/set_prod_worker_secrets.sh`)_;
  - [x] DeviceCheck key (`.p8`) → `APPLE_DEVICECHECK_KEY_ID`, `APPLE_DEVICECHECK_PRIVATE_KEY` (03 §3.7, RC53) — _key `GR7LBHKHFS`; staging + prod_;
  - [x] App Store Server Notifications V2 URLs: production → `https://api.taro.vshyrochuk.com/v1/webhooks/appstore`, sandbox → the staging host (RC4);
  - [ ] EU DSA trader status and export compliance — _owner to confirm_.
- [x] Signing: distribution certificate (shared), App Store provisioning profiles for the prod, stg and dev bundles → `~/pet/secure/taro/` and the secrets bundle (quiz_apps Phase 3 pattern). _Evidence: certificate `7D3BS8PXCS` (team `M3FHKUJ7Z3`, to 2027-01-16, shared with quiz_apps); profiles `Taro iOS Distribution`, `Taro Stg iOS Distribution`, `Taro Dev iOS Distribution` recreated 2026-10-04 after the owner enabled Associated Domains + App Attest (both entitlements present), in `~/pet/secure/taro/` and bundle `taro.ios_provisioning_profile{,_stg,_dev}_base64`; shared ASC key / cert / team ID / Play upload SA copied into `shared.*`. asa prefix-match bug fixed (`7bce62f`). Commits `22b92a7`, `d6dcbbc`; RELEASE.md § Signing; STORE_SUBMISSION.md Evidence log 2026-10-04._
- [x] `apps/taro/ios/Taro.storekit` StoreKit Configuration file with the 4 products for local testing (04 §15, 06). _(Done 2026-10-03, `af5ac03`: `readings_3|10|30` consumables at $1.99/$4.99/$9.99 and `remove_ads` non-consumable at $3.99, family shareable (MO17), en_US names/descriptions from `aso.yaml`; Run StoreKit configuration of the `dev` scheme.)_

---

## Sprint 10.4: Google Play *(MANUAL, M5–M7)*

**Tasks:**
- [x] Account type is personal (Phase 1 decision) → closed test ≥ 12 testers × 14 days before production. Create the app "Taro: Tarot Card Reading" (free, app not game, category Lifestyle). _Evidence: created by the owner (STORE_SUBMISSION.md Evidence log 2026-10-03 "Google Play"). The closed test runs in Phase 21._
- [ ] Upload keystore `taro_upload.jks` → `~/pet/secure/taro/` + bundle. **Manually upload** the first internal-track AAB (prod flavor, placeholder UI) to enable Play App Signing (quiz_apps convention). _Done: upload key `~/pet/secure/taro/taro_upload.jks` (alias `upload`, bundle `taro.android_*`, commit `8406019`); AAB `0.1.0+1` uploaded by hand → Play App Signing on (fingerprints in STORE_SUBMISSION.md, `1192824`). OPEN: the first Android build via CI (`deploy-android.yml`) and its internal-track upload; needs the Play release service account (RELEASE.md § Google Play upload access)._
- [x] In-app products: `asa android setup-iap -c …` (ASA-5); set prices manually (known asa bug); activate. _Evidence: 4 one-time products with 12-locale listings, activated ($3.99 / $1.99 / $4.99 / $9.99); 12 Play store listings in one edit `01579234249443737213` (`push-localizations`). Commit `46bb10b`; STORE_SUBMISSION.md Evidence log 2026-10-03 "Google Play"._
- [x] Google Cloud project for the Worker:
  - enable the Play Integrity API and link it in Play Console → `playCloudProjectNumber` in `apps/taro/config/*.json`;
  - service account with Play Developer API access (view financial data, manage orders) → `GOOGLE_SERVICE_ACCOUNT_JSON` Worker secret;
  - Pub/Sub topic + push subscription → `https://api.taro.vshyrochuk.com/v1/webhooks/googleplay` with OIDC auth → `GOOGLE_PUBSUB_AUDIENCE` and `GOOGLE_PUBSUB_SA`;
  - RTDN enabled in Play Console (M7).
  - _Evidence: project `taro-app-prod` (number 207843881010, linked in Play Console by the owner), `playCloudProjectNumber` in `apps/taro/config/{dev,staging,prod}.json` (`8bbd051`); SA `taro-worker@taro-app-prod.iam.gserviceaccount.com`; topic `play-rtdn`, push subscriptions `play-rtdn-staging` / `play-rtdn-prod` with OIDC SA `taro-pubsub-push@…`; secrets on staging and prod. STORE_SUBMISSION.md Evidence log 2026-10-03 "Google Cloud for the Worker"._
- [ ] Request a Play Integrity quota increase before launch (03 BE-R4, 02 risks) *(MANUAL; track in `docs/runbooks/RELEASE.md`)*. _OPEN._
- [ ] License testers (owner + 2) for sandbox purchases, including the "slow test card" (04 §15). _OPEN (owner)._

---

## Sprint 10.5: AdMob *(MANUAL, M1–M4)*

**Tasks:**
- [x] Create the AdMob apps "Taro" for iOS and Android. Ad units per platform: `taro_banner_home` (anchored adaptive banner, used for all 3 allowed screens) and `taro_rewarded_reading`. Record the IDs in `apps/taro/config/prod.json`, the `aso.yaml` `admob:` block, and Worker config `rewarded.allowedAdUnitIds` (prod). _Evidence: publisher `pub-5769204800499735`, iOS `~4008802776` (banner `/3457129271`, rewarded `/4059850229`), Android `~4087770387` (banner `/4730768217`, rewarded `/6195807406`); in `apps/taro/config/prod.json`, `ios/Config/Prod.xcconfig`, Android `prod` flavor (`a3b8c05`). Follow-up: the `aso.yaml` `admob:` block still holds placeholders and `worker/config/remote_config.default.json` `rewarded.allowedAdUnitIds` still lists Google's test units; set the prod units with the prod config push (Phase 21). **Done 2026-10-06:** `aso.yaml` `admob:` holds the real IDs and the Worker default lists only the two prod rewarded units._
- [x] Rewarded units: SSV callback URL `https://api.taro.vshyrochuk.com/v1/ads/admob/ssv` (staging units → the staging host). Reward item `reading`, amount 1 (the Worker ignores the amount, MO10). Use the "Verify URL" test. _Evidence: SSV set to the staging URL by the owner (STORE_SUBMISSION.md Evidence log 2026-10-03 "AdMob"); switch to the prod host before launch._
- [x] Privacy & messaging: GDPR message (EEA/UK/CH), US state regulations message, and the **IDFA explainer disabled** (own pre-prompt, RC19). Publish. _Evidence: configured by the owner. OPEN (owner): add the 12 consent languages to both messages (STORE_SUBMISSION.md § AdMob and Firebase, iOS-R2-02)._
- [x] Blocking controls: max ad content rating **T**; block the categories Gambling & Betting, Dating, Get-Rich-Quick, Astrology & Esoteric, Sexual & Reproductive Health and Politics (05 §6.3). `tagForChildDirectedTreatment` false. _Evidence: configured by the owner (STORE_SUBMISSION.md Evidence log 2026-10-03 "AdMob")._
- [ ] Publish `app-ads.txt` at `https://vshyrochuk.com/app-ads.txt` (M4). Link AdMob to Firebase `taro-app-prod`. _Prepared: `web/app-ads.txt` (`a3b8c05`), served from the developer website `https://taro.vshyrochuk.com/app-ads.txt` like the quiz apps. OPEN: goes live with the website deploy, which needs the owner's legal details (Phase 19/20)._
- [x] SKAdNetwork list: copy Google's current list into `tools/skadnetwork_ids.txt` and `ios/Runner/Info.plist`; `check_skadnetwork.py` is green. _Evidence: `tools/skadnetwork_ids.txt`, `Info.plist` `SKAdNetworkItems`; `tools/check_skadnetwork.py` exit 0 (2026-10-04)._

---

## Sprint 10.6: Deploy workflows & first builds

**Tasks:**
- [x] `apps/taro/fastlane/` (shared-fastlane approach from quiz_apps): lanes `ios beta`, `ios release`, `android deploy` (track, release_status). Build with `--dart-define-from-file=config/prod.json --obfuscate --split-debug-info=build/symbols`, and upload the Crashlytics symbols (02 §13). _(2026-10-03, `22b92a7`, `b80c17f`: `apps/taro/fastlane/{Fastfile,Appfile,Gemfile,Gemfile.lock}`; `android deploy upload:false` built the signed prod AAB locally, RELEASE.md Evidence log.)_
- [x] `.gitea/workflows/deploy-ios.yml` and `deploy-android.yml` (06 §8): _(2026-10-03, `22b92a7`; actionlint + shellcheck clean; `beta_internal` / `internal_staging` wait for `prodStaging`.)_
  - require `ci` green on the SHA, `check_changelog`, and a build number greater than the last uploaded one (the Sonar gate is advisory and not queried, RC88);
  - decrypt secrets to `$RUNNER_TEMP` and shred them in an `always()` step.
- [ ] First TestFlight build via `deploy-ios.yml` lane `beta` (placeholder UI). The first Android AAB was uploaded manually in Sprint 10.4; subsequent Android builds go through the workflow. _iOS done: TestFlight builds 0.1.0 (1)…(6) uploaded with `fastlane ios beta` (app 6818775977; first one 2026-10-04, `b80c17f`, STORE_SUBMISSION.md Evidence log 2026-10-04). OPEN: the first Android build through `deploy-android.yml` to the internal track._
- [x] `docs/runbooks/RELEASE.md`: record the accounts, IDs table (non-secret), and first-build steps. _(2026-10-03: § Accounts and IDs, § Signing, § Deploy workflows, Evidence log.)_
- [x] Prod Worker deployed with the store-issued secrets (`tools/ci/set_prod_worker_secrets.sh`, owner-authorized) and a single cron trigger per env (`*/15 * * * *`, `worker/wrangler.toml`, `d373142`); staging and prod smoke green.

---

## Done when

- [ ] Every M1–M11 step that can be done before submission is ticked, with evidence (screenshots or IDs) in `docs/runbooks/STORE_SUBMISSION.md`. M8 App Privacy and M10 "submit IAPs with the first version" remain open until Phase 20/22. _Mostly done (STORE_SUBMISSION.md Evidence log 2026-10-03/04). OPEN: M4 app-ads.txt live, Paid Apps agreement / tax / banking and Small Business Program (owner to confirm), Play Integrity quota, license testers, AdMob consent languages._
- [x] Staging and prod Worker secrets are set. `tools/worker_smoke.sh staging` is green. _Evidence: Sprint 10.1 row; staging and prod smoke green._
- [ ] A sandbox purchase from an internal `prodStaging` TestFlight build reaches the **staging** `POST /v1/purchases/verify` (it may fail until Phase 12; only the connectivity is verified here). _OPEN: needs the `prodStaging` build._
- [x] `check_iap_ids.py`, `check_skadnetwork.py` and `asa validate` are green. _Evidence: all three exit 0 on 2026-10-04._
- [x] No secret committed (gitleaks green). Docs: runbooks RELEASE, SECRET_ROTATION, STORE_SUBMISSION. _Evidence: secrets only in `~/pet/secure/taro/` and the GPG bundle; `.gitleaks.toml` allowlist for `firebase_options_*`; runbooks updated in `9673626`, `8bbd051`, `22b92a7`, `d6dcbbc`._
- [ ] One commit: `chore(taro): Phase 10 — Accounts, store registration & signing`. _OPEN: the work landed as separate commits (`af5ac03` … `d373142`); the phase commit follows when the open items close._

## Next phase

Continue the client track (Phases 11–13). Store listings are finished in Phase 20.
