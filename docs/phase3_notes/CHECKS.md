# Phase 3 notes: repo checks (Sprint 3.2)

Working notes for the `tools/` checks of 06 §6.2. Each check has `main(argv) -> int`, pure functions, and fixture trees under `tools/tests/fixtures/<check>/{pass,fail_*}/`. A `fail_*` folder is an overlay on a copy of `pass/`: its files replace or add files, and an empty `<name>.delete` removes `<name>` (`tools/tests/fixture_tree.py`). Each test module asserts that every `fail_*` overlay is listed with the exact rule ids it must produce.

## Conventions shared by the checks

- Shared code: `tools/taro_tools/checkkit.py` holds the locale list, `Finding`, `InputError`, YAML/JSON loading, `**` globs, the Dart comment/string masker and the report printer. `tools/taro_tools/store.py` holds the readers for `aso.yaml`, `catalog.ts`, `taro_products.dart` and ARB files, plus the store field limits.
- Output: `path[:line]: [rule] message`, then `<check>: OK` or `<check>: FAILED (n finding(s))`. Notes print as `<check>: note: …`.
- Exit codes: 0 when clean, 1 on findings, 1 on malformed input (`<check>: malformed input: …`), 2 on a bad CLI.
- Missing inputs: when an input does not exist yet (for example `aso.yaml`, `catalog.ts`, `taro_products.dart`, deck content), the check prints a `not present yet` note and skips that part with exit 0. A file that exists but cannot be parsed, or has the wrong shape, fails.
- `--root <dir>` points a check at another tree (the tests use it). By default the check runs on the repository that contains the script.

## check_arb.dart folded into check_l10n.py

02 §11 names a Dart `tools/dart_tools/bin/check_arb.dart`, and 06 §6.2 gives the same ARB rules to `check_l10n.py`. **Choice: one Python script, `tools/check_l10n.py`.** `check_arb.dart` is not created. Reasons:

- ARB files are JSON, and the ICU parsing needed for parity is small. A Dart copy would duplicate the rules in a second coverage unit.
- `check_l10n.py` also needs YAML (the untranslated allowlist, `aso.yaml`, deck sources), which the Python tools already read.
- One CI step and one report instead of two.

Phase 3 lists this choice in `docs/ARCHITECTURE.md` too. The owner of that file should copy this paragraph there when the phase closes.

## Per-check behaviour and decisions

### `tools/import_rules.yaml` + `tools/check_forbidden_apis.py`

- The SDK allowlist maps each package to the adapter folders that may import it. It is built from the 02 §5 "Prod adapter" column and the 02 §18 "Where" column. The folder names come from the 02 §2.2 `services/` list (`ads/ consent/ iap/ analytics/ crash/ notifications/ attestation/ timezone/ files/ review/ device/ connectivity/ logging/`), `data/api/`, `data/db/`, `data/secure/` and `data/repositories/`.
- Assumptions to confirm in Phases 11–12:
  - UMP and ATT live in `services/consent/`, and `AdMobBannerSlotView` lives in `services/presentation/`.
  - `firebase_core` is also allowed in `bootstrap/`, for `Firebase.initializeApp`.
  - `uuid` is allowed anywhere under `services/`, because 02 names no area for it.
  - `http` and any other `firebase_*` package are banned everywhere.
- `api_allowlist` names the determinism adapters by their canonical file names: `system_clock.dart`, `secure_random_source.dart`, `seeded_random_source.dart`, `secure_id_generator.dart`, and `services/logging/**` for `print`/`debugPrint`.
- Scan scope: `apps/taro/lib` and `packages/*/lib`. Generated files are excluded, using the 06 §6.1 analyzer excludes. Comments and string contents are ignored, but code inside `${…}` interpolations is scanned.
- Non-directional APIs flagged: `EdgeInsets.only(` and `Positioned(`/`Positioned.fill(` with a top-level `left:`/`right:` argument, all six `Alignment.{top,center,bottom}{Left,Right}` constants, and `TextAlign.left/right`. `EdgeInsets.fromLTRB` is not flagged, because 06 does not list it.
- `check_forbidden_apis.py` passes on the current code with no violations.

### `tools/check_l10n.py`

- Plural branches are **not** required to equal `en`, because CLDR categories differ by locale (ar has six, ja has one). The rule is: `other` must be present, every `=N` branch of `en` must be kept, and each keyword must be a CLDR category of that locale (table in the script). Select branches must equal `en` exactly.
- Placeholder type is compared only where a translation declares `@key.placeholders`.
- Untranslated check: a value equal to `en` fails unless the key is in `tools/l10n_untranslated_allowlist.yaml` (`keys:` for all locales, `locales: {de: [...]}` for one locale). Values with no letters, such as `{count}`, are exempt. Allowlist entries that are not `en` keys fail as stale. The file starts with `appTitle` (the brand name).
- Literal heuristic: `Text('…')`, `label: '…'` and `tooltip: '…'` whose literal contains a letter after interpolations are removed. Scope is `apps/taro/lib/**` and `packages/taro_ui/lib/**`. `apps/taro/lib/features/debug/**` and generated code are exempt.
- Deck content is skipped until Phase 5 lands. After that, the check requires `apps/taro/content/source/{locale}/cards/{cardId}.yaml` for all 78 × 12 files, each a non-empty mapping with no empty fields. Once any `apps/taro/assets/deck/*.json` exists, it also requires `{locale}.json` for all 12 locales, each containing all 78 card ids. Field bounds belong to `tools/content validate` (01 §11).
- **RC94 glossary keys are staged.** The 37 `failure*`/`safetyDeclined*` keys of GLOSSARY §5/§5.2 are enforced from the moment the first one appears in `app_en.arb`. Before that the check prints a note. `--require-glossary-keys` enforces them now. `check_glossary.py` covers the same rule (Phase 3 task list).
- Store field limits run over `aso.yaml`. They share one implementation (`taro_tools.store`) with `check_store_copy.py`.

### `tools/check_iap_ids.py`

- Expected Dart shape of `TaroProducts`: one constructor call per product with named arguments, for example `TaroProduct(id: 'com.vshyrochuk.taro.readings_3', kind: ProductKind.consumable, alias: 'pack_s')`. `kind` may be `consumable`, `nonConsumable` or `non_consumable`.
- `catalog.ts` must contain a `PRODUCT_CATALOG = { 'id': { kind, credits?, retired? } }` object literal. Retired entries are left out of the set comparison (04 §4).
- `aso.yaml`: the check reads `app_store.iap_products`. It also reads `google_play.iap_products` when that is a list; the 05 §8.1 draft alias text is ignored.
- Sets are compared across whichever sources exist. The "N Readings" name-vs-credits rule is also in `check_pack_sizes.py`, which additionally checks every locale and the descriptions.

### `tools/store_copy/` (`check_store_copy.py`, `banned_phrases.yaml`, `required_sentences.yaml`, `check_pack_sizes.py`)

- **Matching:** text is NFKC-normalised and case-folded, and curly apostrophes are turned into straight ones. Phrases match on word boundaries. A token ending in `*` is a stem, so `guarantee*` matches "guaranteed". `ja` uses substring matching. Stems are marked explicitly so that `heal` does not hit "health", `büyü` does not hit "büyük" and `sort` does not hit "sortir".
- **Lists:** `common` (applies to all locales: `100%`, `#1`, `no.1`; `apple_only`: Android, Google Play, Play Store, Google; `play_only`: iPhone, iPad, App Store, iOS) plus per-locale `global`, `apple_only`, `play_only`, `name_subtitle` and `allowed_contexts`. The seeds come from the 05 §9.5 table for all 12 locales plus the 06 §6.2 English list.
- **Exemptions:** the locale's required disclaimer sentence and its `allowed_contexts` spans are removed before matching. That is how the 05 §3 disclaimer "They are not medical, legal, financial or psychological advice" passes even though "medical" is a 06 seed phrase.
- **Field platforms:** `localizations.*`, `app_store.*` and App Store IAP fields are Apple. `google_play.*`, top-level `short_description` and `full_description` are Play. Top-level `whats_new`, the top-level `keywords` list and screenshot captions count as both. The App Review notes are checked against `global` only, because the 05 §7 notes legitimately name "Play Integrity (Android)" and "Google AdMob". ARB, deck content and prompt templates are also checked against `global` only; `whats_new/**` files are checked against all lists.
- **Surfaces:**
  - "CHANGELOG-derived release notes" means the `whats_new` fields and `apps/taro/store/whats_new/**`; the developer `CHANGELOG.md` is not scanned.
  - Worker user-visible templates are expected under `worker/prompts/**/templates/**`. This is a convention for Phase 8; `system.md` is not user-visible and is not scanned.
- `description_has_disclaimer`: the first 3 non-empty lines of every long description (Apple `description`, Play `full_description`, top-level `full_description`) must contain the `required_sentences.yaml` sentence for that locale. The 11 translations are drafts pending the reviewed store-copy pass, and each avoids its own locale's banned phrases (a test asserts this).
- `review_notes_labels_exist` (RC79): labels in straight or curly double quotes inside the HOW TO REVIEW block, up to the next ALL-CAPS heading.
- `remove_banner_ads_name` (RC80): the English name is exactly "Remove Banner Ads", and there is a display name ≤ 30 characters for each of the 12 locales. `iap_localized` requires the other products to have display names in all 12 locales (05 §8.1 rule 6).
- `check_pack_sizes.py` reads Unicode digits, so Arabic-Indic "٣ قراءات" counts as 3.

### `tools/check_urls.py`

- Collects `http(s)://` URLs from every string in `aso.yaml` and every ARB message (not `@` metadata). `admob.ssv_callback_url` is skipped because 05 §8.1 marks it doc-only.
- `--offline` (PR mode) checks syntax only: https, a dotted public host, and no placeholder such as `XXXX`, `...` or `<…>`.
- The default online mode (weekly in `nightly.yml`) does HEAD, then GET if HEAD returns 403/405/501, follows redirects, and requires a final 200. Each distinct URL is fetched once.

## Spec discrepancies found (for the owner)

1. **Keyword limit unit.** 06 §6.2 says "keywords 100 bytes"; 05 §8.1 rule 1 says lengths use Python `len()`. The checks use `len()`, because 05 owns store copy and its ja/ko counts (69/58) are character counts; in UTF-8 bytes the ja field would be about 200. Suggest changing 06 to "100 characters".
2. **05 §9.3 keyword table breaks 05 rule 2.** `tr` keywords repeat "tarot" from the name "Taro: Tarot Falı", and `uk` keywords repeat "таро" from "Taro: Карти Таро". `check_store_copy.py` will reject those rows when `aso.yaml` is authored, so drop them then. (`yes,no` also has to be swapped out, as 05 already notes.)
3. **06 seed "medical" vs the 05 §3 disclaimer.** The seed phrase appears in the required onboarding copy. This is resolved with `allowed_contexts`, not by dropping the seed.
4. **Plural parity.** 06 says "an ICU plural/select branch differs from en". Taken literally, this would reject correct ar/ja/uk plurals, so the CLDR rule above is used instead.
5. **App Review notes vs `apple_fields_no_android`.** The 05 §7 notes name Android and Google, so the notes are checked against the `global` list only.
