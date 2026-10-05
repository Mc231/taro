# Store submission runbook

Evidence of manual console work (IDs, dates, screenshots; never secrets), per `docs/phases/README.md`. Filled in Phases 9, 10, 20 and 22.

## asa command sequence (05 §8.4)

Confirmed against the asa CLI in Phase 9 (option names checked with `--help`; commands not yet run against the live stores, which happens in Phases 10 and 20). Run from the taro repo root with asa's own venv (`~/pet/app-store-automation/.venv/bin/asa`) and the store credentials in place. Every `--dry-run` below needs no write access; `set-app-availability --dry-run` still reads the app from App Store Connect.

```bash
ASO=apps/taro/store/aso.yaml
BUNDLE=com.vshyrochuk.taro

asa validate -c $ASO                                                    # ASA-6, also in CI (reusable-static.yml)

# App Store Connect
asa ios bootstrap-app -c $ASO                                           # ASA-1/2: bundle ID (IAP + App Attest, no Game Center), app record, Lifestyle / Entertainment
asa ios create-iap -b $BUNDLE -p $BUNDLE.remove_ads  -n "Remove Banner Ads" -d "Remove Banner Ads" --description "Optional reward videos stay." -t non-consumable --price-tier 4
asa ios create-iap -b $BUNDLE -p $BUNDLE.readings_3  -n "Readings 3"  -d "3 Readings"  --description "Adds 3 AI tarot readings."  -t consumable --price-tier 2
asa ios create-iap -b $BUNDLE -p $BUNDLE.readings_10 -n "Readings 10" -d "10 Readings" --description "Adds 10 AI tarot readings." -t consumable --price-tier 5
asa ios create-iap -b $BUNDLE -p $BUNDLE.readings_30 -n "Readings 30" -d "30 Readings" --description "Adds 30 AI tarot readings." -t consumable --price-tier 10
asa ios set-all-iap-prices -b $BUNDLE -c $ASO
asa ios set-all-iap-availability -b $BUNDLE -c $ASO
asa ios localize-all-iaps -b $BUNDLE -c $ASO                            # ASA-4: en-US + 11 locales per product
asa ios push-localizations -c $ASO --dry-run && asa ios push-localizations -c $ASO
asa ios update-review-info -c $ASO --platform ios                       # contact phone filled from ~/pet/secure/taro/review_contact first
asa ios set-age-rating --from-config $ASO --dry-run                     # ASA-3: prints the PATCH body
asa ios set-age-rating -b $BUNDLE --from-config $ASO                    # override rejected -> manual step M8 printed
asa ios set-app-availability -c $ASO --dry-run && asa ios set-app-availability -c $ASO   # ASA-9; API rejection -> manual step printed
asa ios upload-screenshots -b $BUNDLE -s build/screenshots/ios/iphone -d iphone-67 -l en-US   # per device and locale
asa ios upload-screenshots -b $BUNDLE -s build/screenshots/ios/ipad   -d ipad-129  -l en-US

# Google Play (app created by hand first, M5; IAP prices are set by hand, asa README "Known issues")
asa android setup-iap -p $BUNDLE -c $ASO                                # per-locale product listings
asa android push-localizations -c $ASO --dry-run && asa android push-localizations -c $ASO   # ASA-5: one edit, 12 listings
asa android upload-screenshots -p $BUNDLE --screenshots-dir build/screenshots/android/phone --type phoneScreenshots --language en-US
asa android upload-screenshots -p $BUNDLE --screenshots-dir build/screenshots/android/tab7  --type sevenInchScreenshots --language en-US
asa android upload-screenshots -p $BUNDLE --screenshots-dir build/screenshots/android/tab10 --type tenInchScreenshots --language en-US
asa android upload-feature-graphic -p $BUNDLE -i build/store/feature_graphic.png

# Web (taro.vshyrochuk.com): web.content_dir in aso.yaml points at web/
asa web generate -c $ASO -o build/web --firebase-project taro-app-prod  # ASA-7: index/privacy/terms/support in 12 locales, ?hl=
cp web/app-ads.txt build/web/taro/                                      # asa does not copy app-ads.txt
sed -i '' 's/🎮/🌙/g' build/web/taro/*.html                            # asa has no favicon option (quiz default)
asa web deploy -d build/web/taro                                        # ASA-10: refuses a hosting config that breaks .well-known; site taro-app-prod
asa web check-well-known -u https://taro.vshyrochuk.com                 # 200, no redirect, application/json
```

Notes:
- `apps/taro/store/aso.yaml` is checked by `asa validate` and by `tools/store_copy/check_store_copy.py`, `check_pack_sizes.py`, `check_iap_ids.py`, `check_l10n.py` and `check_urls.py`.
- `app_store.availability.excluded_territories` is an owner decision (CS16 + the App Store storefronts in `ai.blockedCountries`); confirm it before `set-app-availability` in Phase 10.
- All four pages come from `web/{index,privacy,terms,support}.<locale>.md` (12 locales); the generator warns about the 11 machine-translated locales of each page (native review in Phase 20).

## App Store Connect

## Google Play Console

## AdMob and Firebase

**UMP consent message language (iOS-R2-02).** The app can't choose the language of the Google consent form: the UMP SDK has no language parameter (`UmpConsentService` sends only the debug geography). The form uses the OS language for the app, and only the languages added to the message in AdMob. The in-app language picker doesn't change it. On iOS, users can pick a per-app language in Settings → Taro → Language, because `Info.plist` declares all 12 localizations. Owner steps, before release:
1. AdMob → Privacy & messaging → GDPR message → Edit → **Languages**: add en, ar, de, es, fr, it, ja, ko, nl, pt, tr, uk. Set the default language to English. Publish.
2. Do the same for the US state regulations message.
3. Keep the IDFA explainer message **off** (RC19, 05 M3). The app shows its own neutral pre-prompt after UMP, then ATT.
4. Check: set the device (not just the app) to Ukrainian, use the UMP debug geography EEA, then fresh-install. The form should be in Ukrainian.

The form's text is Google's template, so the app can't change it. RC59 is the banner-gap rule (`space.adGap` ≥ 16 dp), not consent wording. The consent rules are RC18/RC19: UMP comes first, then the neutral pre-prompt, then ATT, and there is no IDFA explainer.

## Review notes

## Rejection response plan

## Evidence log

### 2026-10-03 — App Store Connect via asa (Phase 10.3)
- App record `6818775977` created by the owner in the ASC UI (the API no longer allows app creation); `bootstrap-app` set LIFESTYLE / ENTERTAINMENT.
- Bundle IDs: `com.vshyrochuk.taro`, `.dev` (7PXM43WGQX), `.stg` (4FBT4YG35K), IN_APP_PURCHASE. App Attest: the API has no APP_ATTEST capability, but the App ID needs "App Attest" ticked in the developer portal (done by the owner on all 3) or profiles lack the entitlement.
- IAPs created: `remove_ads` (non-consumable, tier 4), `readings_3` (tier 2), `readings_10` (tier 5), `readings_30` (tier 10); prices set; availability 175 territories; 48 localizations (4 × 12).
- `push-localizations`: 12 locales pushed (whats_new skipped on the first version).
- Age rating declaration set from config, `ageRatingOverrideV2 = THIRTEEN_PLUS` accepted.
- App availability: 154 territories, excluded AFG AIA ARE BHR BLR BMU CHN CYM HKG KWT MAC MMR MSR OMN QAT RUS SAU TCA VEN VGB YEM.
- Firebase: `taro-app-dev` (dev + stg apps), `taro-app-prod` (prod app); Analytics linked by the owner in the console.

### 2026-10-03 — Google Play (Phase 10.4)
- App "Taro: Tarot Card Reading" created by the owner (free app, Lifestyle).
- Upload key `~/pet/secure/taro/taro_upload.jks` (alias `upload`; bundle `taro.android_*`): SHA-1 `C4:C2:3D:76:1C:2F:5F:39:72:F2:F8:F4:90:8E:7E:6D:76:13:5B:64`, SHA-256 `11:CF:E3:62:DA:9C:FF:F7:E7:A2:D9:06:88:19:BE:3B:A5:E5:56:D4:54:EF:17:86:8C:F6:C5:D9:70:FB:65:DF`.
- First AAB `0.1.0+1` (prod) uploaded by hand to Internal testing → Play App Signing enabled. App signing key: SHA-1 `7C:E9:37:2A:49:6F:CF:7E:27:AC:56:F1:AA:A2:EB:D6:AE:82:79:F7`, SHA-256 `D2:87:8B:46:F7:1B:80:01:B2:36:9E:2F:75:6B:62:70:E2:0C:AD:0F:26:6B:99:83:28:5B:1F:50:86:02:40:4E`.
- Both keys' SHA-1/SHA-256 added to the Firebase `taro-app-prod` Android app; `web/.well-known/assetlinks.json` carries the app signing SHA-256.
- `asa android setup-iap`: 4 one-time products created with 12-locale listings and activated (remove_ads $3.99, readings_3 $1.99, readings_10 $4.99, readings_30 $9.99 — check the per-country prices in the console, asa known issue).
- `asa android push-localizations`: 12 Play listings in one edit (01579234249443737213).

### 2026-10-03 — AdMob (Phase 10.5)
- Publisher `pub-5769204800499735`. iOS app `ca-app-pub-5769204800499735~4008802776` (banner `/3457129271`, rewarded `/4059850229`); Android app `~4087770387` (banner `/4730768217`, rewarded `/6195807406`). Wired into `apps/taro/config/prod.json`, `ios/Config/Prod.xcconfig` and the Android `prod` flavor; dev/staging keep Google's test IDs.
- Owner configured SSV (staging URL), privacy messages and blocking controls in the AdMob UI.
- `web/app-ads.txt` prepared. Like the quiz apps, it is served from the app's own site (`https://taro.vshyrochuk.com/app-ads.txt`, the store "developer website"), published with the site deploy (Phase 20) — not from vshyrochuk.com.

### 2026-10-03 — Google Cloud for the Worker (Phase 10.4)
- GCP project `taro-app-prod` (number 207843881010): Play Integrity, Android Publisher, Pub/Sub, IAM APIs enabled. `playCloudProjectNumber` = 207843881010 in `apps/taro/config/{dev,staging,prod}.json`.
- Service account `taro-worker@taro-app-prod.iam.gserviceaccount.com` (Play Developer API); key in `~/pet/secure/taro/taro-worker-sa.json` + bundle `worker.play_service_account_base64`; staging secret `GOOGLE_SERVICE_ACCOUNT_JSON` set.
- Pub/Sub topic `projects/taro-app-prod/topics/play-rtdn` (publisher: google-play-developer-notifications@system.gserviceaccount.com); push subscriptions `play-rtdn-staging` → api-staging…/v1/webhooks/googleplay and `play-rtdn-prod` → api…/v1/webhooks/googleplay, OIDC via `taro-pubsub-push@taro-app-prod.iam.gserviceaccount.com` (audience = endpoint URL); staging secrets `GOOGLE_PUBSUB_AUDIENCE` / `GOOGLE_PUBSUB_SA` set.

### 2026-10-04 — Signing and first TestFlight build (Phase 10.3/10.6)
- Owner enabled Associated Domains + App Attest on the 3 App IDs; asa recreated the 3 App Store profiles (prod/stg/dev, both entitlements present), installed locally and stored in the bundle (`taro.ios_provisioning_profile{,_stg,_dev}_base64`).
- Shared store credentials copied from the quiz_apps bundle into `shared.*` at the owner's request (ASC API key, distribution cert, team ID M3FHKUJ7Z3, Play upload SA).
- `fastlane ios beta` (local): build 0.1.0 (1), prod flavor, uploaded to TestFlight (app 6818775977). The Crashlytics Dart-symbol step logged a java error (non-fatal; dSYMs/symbols to be rechecked in CI).

### 2026-10-04 — Website taro.vshyrochuk.com (ASA-7, ASA-10)
- Owner approved publishing. `[OWNER: …]` placeholders filled in `web/privacy.*.md` (trader: Volodymyr Shyrochuk, individual developer, Skrypnuka St 278, Lviv 79049, Ukraine, +380 93 815 0581, volodymyr.shyrochuk@gmail.com) and `web/terms.*.md` (governing law: Ukraine, mandatory consumer protection kept); `effective` 2026-10-04, version 1.0. New `web/index.<locale>.md` and `web/support.<locale>.md` (12 locales). `check_retention.py` OK, `check_store_copy.py` OK; banned-phrase scan of `web/*.md` with the store-copy matcher: index/support clean except the support address `gmail` (an email address, not a platform claim).
- `asa web generate` → `build/web/taro` (48 pages: 4 pages × 12 locales, `?hl=` redirect script on every page, `.well-known/` byte for byte, `firebase.json` with `cleanUrls` and `application/json` headers); `app-ads.txt` copied in by hand. `asa web deploy` → Firebase Hosting default site `taro-app-prod` (55 files) → https://taro-app-prod.web.app.
- Verified on taro-app-prod.web.app: `/`, `/privacy`, `/terms`, `/support`, `/privacy.uk`, `/support.ar` 200 `text/html`; `/privacy?hl=uk` → client-side `location.replace` to `privacy.uk.html`; `/app-ads.txt` 200 `text/plain` = `google.com, pub-5769204800499735, DIRECT, f08c47fec0942fa0`; `/.well-known/apple-app-site-association` and `/.well-known/assetlinks.json` 200 `application/json`, no redirect.
- Custom domain `taro.vshyrochuk.com` added to site `taro-app-prod` through the Firebase Hosting REST API (`customDomains`); Cloudflare zone `vshyrochuk.com`: `CNAME taro → taro-app-prod.web.app` (DNS only) and `TXT _acme-challenge.taro` (Firebase cert challenge) created via the API.

- SSL issued about 25 min after the DNS records (Firebase state `HOST_ACTIVE` / `OWNERSHIP_ACTIVE`). On https://taro.vshyrochuk.com: `/`, `/privacy`, `/terms`, `/support`, `/privacy?hl=uk` 200 `text/html`; `/app-ads.txt` 200 `text/plain` (pub-5769204800499735 line); both `.well-known` files 200 `application/json`, no redirect; `asa web check-well-known -u https://taro.vshyrochuk.com` "served correctly"; `tools/check_urls.py` (online) OK.

### 2026-10-05 — Phase 20.3 read-back (read-only, nothing pushed)
- Live writes (`push-localizations`, `update-review-info`, screenshot and feature-graphic uploads) were not run in this session: the automation's permission gate blocked live store writes without the owner's own approval. Commands to run: `CONSOLE_FORMS.md` Part C.
- Dry runs: `asa ios push-localizations --dry-run` (12 locales), `asa ios update-review-info --platform ios --dry-run` (notes 3,527 chars, no phone), `asa ios set-age-rating --from-config --dry-run`, `asa ios set-app-availability --dry-run` (0 changes, 154 territories), `asa android push-localizations --dry-run` (12 listings).
- ASC read-back (API, version 1.0 PREPARE_FOR_SUBMISSION) vs `aso.yaml`: name, subtitle, keywords, description, promotional text and URLs match in all 12 locales. What's New empty in all 12 (expected: Apple refuses it on a first version). Category LIFESTYLE. Age rating `ageRatingOverrideV2 = THIRTEEN_PLUS`, advertising true. IAPs `readings_3|10|30`, `remove_ads`: 12 localizations each, state MISSING_METADATA (review screenshot missing; files in `build/store/iap_review/`). Screenshots: none in any locale. App Review detail: empty (no email, phone or notes).
- Play read-back (edit opened and deleted) vs `aso.yaml`: title, short and full description match in all 12 listings. Phone, 7" and 10" screenshots and feature graphic: 0 in every listing. `asa android list-products` fails with 403 "Please migrate to the new publishing API" (asa bug in the legacy listing call; the products were created with the new API in Phase 10).
- IAP review screenshots prepared: `build/store/iap_review/{readings_3,readings_10,readings_30,remove_ads}.png`, 1290 × 2796, from the `s11_store_content` golden.

### 2026-10-05 — Store assets pushed (Phase 20.3, owner-authorized)
- `asa ios update-review-info --platform ios` from a temp copy of aso.yaml with the phone filled (temp deleted): review contact + 3,527-char notes set on version 1.0.
- `tools/screenshots/upload_store_assets.sh`: 421 uploads, 0 errors. Read-back: App Store Connect — 12 locales × APP_IPHONE_67=7 + APP_IPAD_PRO_129=7; Google Play — 12 listings × phone 7 / 7-inch 7 / 10-inch 7; feature graphic on en-US (default language; other locales fall back to it).
