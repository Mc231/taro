# web/: content for taro.vshyrochuk.com

These are the inputs for `asa web generate` (gap tasks ASA-7 and ASA-10 in 05 §8.2). Nothing here is deployed from this repo.

- `privacy.<locale>.md`, `terms.<locale>.md`: the privacy policy (05 §5.3) and the terms of use (05 §5.4), one file per locale for the 12 locales. Each file has front matter with `version`, `effective`, `source` and `review`. `en` is the source. The other 11 locales are machine translations (`translation: machine`) and need a native legal review before they are published. `tools/check_retention.py` checks `privacy.en.md` §Retention against 03 §13. Placeholders marked `[OWNER: …]` (trader address and phone, governing law) must be filled in before publishing.
- `.well-known/apple-app-site-association`: Universal Links for `/app/*`, team `M3FHKUJ7Z3`, prod and staging bundle IDs. Serve it with no file extension.
- `.well-known/assetlinks.json`: App Links. Replace `PLAY_APP_SIGNING_SHA256_FROM_PLAY_CONSOLE` with the Play App Signing certificate SHA-256 (Play Console → App integrity) before deploying.
- Serve both `.well-known` files as `application/json`, with status 200 and no redirect (RC92).
