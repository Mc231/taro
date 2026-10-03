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
asa web generate -c $ASO -o build/web                                   # ASA-7: privacy/terms in 12 locales, ?hl=
asa web deploy -d build/web/taro                                        # ASA-10: refuses a hosting config that breaks .well-known
asa web check-well-known -u https://taro.vshyrochuk.com                 # 200, no redirect, application/json
```

Notes:
- `apps/taro/store/aso.yaml` is checked by `asa validate` and by `tools/store_copy/check_store_copy.py`, `check_pack_sizes.py`, `check_iap_ids.py`, `check_l10n.py` and `check_urls.py`.
- `app_store.availability.excluded_territories` is an owner decision (CS16 + the App Store storefronts in `ai.blockedCountries`); confirm it before `set-app-availability` in Phase 10.
- `index` and `support` pages have no taro Markdown yet, so `asa web generate` uses its built-in template for them (quiz wording) until `web/{index,support}.<locale>.md` exist (Phase 20).

## App Store Connect

## Google Play Console

## AdMob and Firebase

## Review notes

## Rejection response plan

## Evidence log
