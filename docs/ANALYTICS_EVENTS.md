# Analytics events

The catalogue of every analytics event the app sends. The code is the sealed `TaroAnalyticsEvent` in `packages/taro_core/lib/src/analytics/`; this page and the code must match. `tools/check_analytics_events.py` compares event names and parameter names on both sides and fails CI when they drift. `packages/taro_core/test/src/analytics/` checks that every enum value listed here is documented and snapshots each event's name and parameters.

Sources: 01 §15 (product events), 04 §14 (monetization events; 04's names and parameters win where the two overlap), PR18, RC3, RC18, RC34, RC57, RC68, RC74, RC94.

## Rules

- **No user content or identifiers (PR18).** Events never carry question, reading, note or search text, card-level text, the install ID, tokens or raw product IDs. Every parameter is a bounded enum (sent as its wire string), an `int` or a `bool`. No event class has a `String` field.
- Names are `snake_case`, at most 40 characters, with at most 25 parameters (01 §15).
- An optional parameter (`name?`) is omitted when it has no value.
- Lengths and counts are sent as buckets, never exact values (`question_len_bucket`, `note_len_bucket`, `entries_bucket`, `results_bucket`).
- Products are always the alias in `product` (`pack_s`, `pack_m`, `pack_l`, `remove_ads`; GLOSSARY §3), never the store product ID (RC3).
- **Consent (RC68).** Everything goes through `AnalyticsService` behind `ConsentAwareAnalytics`. Consent defaults to denied; up to 50 events are buffered until UMP resolves and are then flushed or dropped. The Settings toggle (`analytics_toggled`) turns collection off entirely.
- Parameter values are sent as they are in the tables. `bool` values are passed to the adapter as `bool`; the Firebase adapter converts them to what the SDK accepts.

## Value sets

Large enums are listed once here and referenced by name from the tables.

### ScreenId

`screen_view.screen`, `screen_view.previous`, `error_shown.screen`: the literal screen IDs (GLOSSARY §10, RC94).

S01, S02, S03, S04, S05, S06, S07, S08, S09, S10, S11, S12, S13, S14, S15, S16, S17, S18, S19, S20, S21, S22, S23, S24, S25, S26, S27, S28, S29, S30, S31, S32, S33

### SpreadId

`spread_id` (RC2). An ID outside the v1 set is sent as `unknown`.

single, three_ppf, three_sao, relationship, two_paths, celtic_cross, unknown

### CardId

`learn_card_viewed.card_id`: one of the 78 card IDs (RC1, GLOSSARY §1), or `unknown` for an ID that does not match the format.

major_00 … major_21, wands_01 … wands_14, cups_01 … cups_14, swords_01 … swords_14, pentacles_01 … pentacles_14, unknown

### Locale

`reading_generated.locale` and the language `setting_changed.value` (01 §13). Region subtags are dropped (`pt-BR` → `pt`); an unsupported language is `other`.

en, ar, de, es, fr, it, ja, ko, nl, pt, tr, uk, other

### Currency

`currency` of the purchase events: the ISO 4217 code of the store price, upper case. Codes not listed are sent as `other`.

AED, AUD, BGN, BRL, CAD, CHF, CLP, CNY, COP, CZK, DKK, EGP, EUR, GBP, HKD, HUF, IDR, ILS, INR, JPY, KRW, KWD, KZT, MXN, MYR, NGN, NOK, NZD, PEN, PHP, PKR, PLN, QAR, RON, SAR, SEK, SGD, THB, TRY, TWD, TZS, UAH, USD, VND, ZAR, other

### ConfigKey

`config_value_clamped.key`: the remote-config keys the client reads (03 §8.2). Any other key is `other`.

readings.enabled, readings.freeDaily, readings.maxPerInstallPerDay, readings.tzCooldownHours, spreads.enabled, rewarded.enabled, rewarded.amount, rewarded.dailyCap, rewarded.cooldownSec, rewarded.intentTtlSec, rewarded.loadTimeoutSec, rewarded.grantPollTimeoutSec, ads.enabled, ads.bannerEnabled, ads.bannerScreens, ads.bannerMinCompletedReadings, ads.attPrepromptEnabled, store.enabled, store.packs, store.verifyRetryWindowHours, store.pendingHoldMinutes, store.removeAdsEnabled, store.showBestValueBadge, store.showPerReadingPrice, ai.consentVersion, ai.questionMaxChars, balance.resumeSyncThrottleSec, balance.staleAfterSec, review.promptAfterPositiveReadings, legal.privacyUrl, legal.termsUrl, support.email, other

## Screen

| Event | Params (type) | When fired | Screen |
|---|---|---|---|
| `screen_view` | `screen` (enum [ScreenId]), `previous?` (enum [ScreenId]) | A route or modal becomes visible | any |

## Onboarding

| Event | Params (type) | When fired | Screen |
|---|---|---|---|
| `onboarding_step_viewed` | `step` (enum: welcome\|disclaimer\|ai_consent\|ump\|att) | An onboarding step is shown | S02, S03, S04, UMP form, ATT pre-prompt |
| `onboarding_completed` | `duration_s` (int), `ai_consent` (bool) | The last onboarding step finishes | S04 → S05 |
| `disclaimer_accepted` | – | The disclaimer is accepted | S03 |

## Consent

| Event | Params (type) | When fired | Screen |
|---|---|---|---|
| `ai_consent_decided` | `granted` (bool), `origin` (enum: onboarding\|reading_gate\|settings), `consent_version` (int) | The AI data-sharing choice is made | S04, S23 |
| `consent_ump_result` | `status` (enum: obtained\|not_required\|required_declined\|error), `form_shown` (bool), `can_request_ads` (bool) | The UMP flow finishes (04 §14) | onboarding, S23 |
| `consent_att_result` | `status` (enum: authorized\|denied\|restricted\|not_determined), `preprompt_shown` (bool) | The ATT prompt finishes, iOS only (04 §14) | onboarding |
| `analytics_toggled` | `enabled` (bool) | The analytics toggle changes | S23 |

## Reading

| Event | Params (type) | When fired | Screen |
|---|---|---|---|
| `reading_flow_started` | `source` (enum: home\|spreads_guide\|daily_card\|deep_link\|journal_retry), `spread_id` (enum [SpreadId]) | A reading flow is entered | S05, S13, S18, S15, deep link |
| `reading_gate_blocked` | `reason` (enum: no_consent\|offline\|insufficient_credits\|readings_paused\|spread_disabled\|device_unverified\|rate_limited\|daily_limit\|low_trust\|region\|free_paused), `spread_id` (enum [SpreadId]) | `ReadingGate` does not allow the reading | S07 |
| `reading_hold_result` | `result` (enum: held\|insufficient_credits\|paused\|error), `spread_id` (enum [SpreadId]) | `POST /v1/readings/holds` answers | S07 |
| `question_submitted` | `spread_id` (enum [SpreadId]), `has_question` (bool), `question_len_bucket` (enum: 0\|1-50\|51-150\|151-300), `used_suggestion` (bool) | Begin is tapped (never the question text) | S07 |
| `draw_completed` | `spread_id` (enum [SpreadId]), `auto_draw` (bool), `reversed_count` (int), `major_count` (int), `duration_ms` (int) | Every card of the spread is drawn | S08 |
| `reading_generated` | `spread_id` (enum [SpreadId]), `latency_ms` (int), `prompt_version` (int), `credit_type` (enum: free\|paid\|rewarded), `locale` (enum [Locale]) | An AI reading is delivered | S09 |
| `reading_failed` | `spread_id` (enum [SpreadId]), `error` (enum: network\|timeout\|server\|moderation\|hold_lost\|delivery_expired), `refunded` (bool) | An AI reading fails | S09 |
| `classic_reading_started` | `spread_id` (enum [SpreadId]), `reason` (enum: no_consent\|region\|paused) | A Classic reading starts (RC20) | S07, S31 |
| `classic_reading_completed` | `spread_id` (enum [SpreadId]), `reason` (enum: no_consent\|region\|paused) | The Classic result is shown | S32 |
| `reading_reported` | `spread_id` (enum [SpreadId]), `reason` (enum: offensive\|harmful_advice\|sexual\|hateful\|other) | A report is submitted (RC72) | S33 |
| `reading_refused` | `spread_id` (enum [SpreadId]), `category` (enum: health\|pregnancy\|death\|legal\|financial\|gambling\|self_harm\|harm_to_others\|sexual_minors\|hate_or_harassment\|other), `can_rephrase` (bool) | The Worker declines the reading (03 §9.4, RC27) | S09 |
| `crisis_resources_viewed` | `origin` (enum: reading\|help\|settings) | Crisis resources are shown | S27 |
| `reading_viewed` | `spread_id` (enum [SpreadId]), `origin` (enum: fresh\|journal) | A reading result is opened | S09, S15 |
| `reading_rated` | `spread_id` (enum [SpreadId]), `rating` (enum: up\|down), `reason?` (enum: too_generic\|mismatch\|tone\|other) | Thumbs up or down | S09, S15 |
| `reading_shared` | `spread_id` (enum [SpreadId]), `include_question` (bool) | The share image is shared | S09, S15 |
| `reflection_prompt_used` | `spread_id` (enum [SpreadId]) | A reflection prompt is tapped | S09, S15 |

## Daily card

| Event | Params (type) | When fired | Screen |
|---|---|---|---|
| `daily_card_revealed` | `reversed` (bool), `arcana` (enum: major\|minor), `streak_days` (int) | Today's card is revealed; `streak_days` is computed locally (01 Q10) | S13 |
| `daily_card_deeper_tapped` | – | "Go deeper" is tapped | S13 |

## Journal

| Event | Params (type) | When fired | Screen |
|---|---|---|---|
| `journal_note_saved` | `entry_type` (enum: reading\|daily), `note_len_bucket` (enum: 0\|1-100\|101-500\|501-2000\|2001+) | A note is autosaved (never the note text) | S15 |
| `journal_entry_deleted` | `entry_type` (enum: reading\|daily), `undone` (bool) | An entry is deleted, or the delete is undone | S14, S15 |
| `journal_favourite_toggled` | `entry_type` (enum: reading\|daily), `on` (bool) | The favourite star changes | S14, S15 |
| `journal_filter_used` | `filter` (enum: type\|spread\|card\|favourites\|search) | A filter is applied (never the search text) | S14 |
| `patterns_viewed` | `range` (enum: d30\|d90) | Journal insights are opened (01 §7.8) | S14 |

## Learn

| Event | Params (type) | When fired | Screen |
|---|---|---|---|
| `learn_card_viewed` | `card_id` (enum [CardId]), `orientation` (enum: upright\|reversed), `origin` (enum: deck\|search\|reading\|patterns) | Card detail is shown | S17 |
| `learn_search` | `results_bucket` (enum: 0\|1-5\|6+) | A deck search runs (never the query) | S16 |
| `learn_spread_viewed` | `spread_id` (enum [SpreadId]) | A spread detail is shown | S18 |

## Notifications

| Event | Params (type) | When fired | Screen |
|---|---|---|---|
| `reminder_offer_answered` | `accepted` (bool) | The daily reminder offer is answered | S13, S22 |
| `notification_permission_result` | `granted` (bool) | The OS permission prompt is answered | S22 |
| `reminder_changed` | `enabled` (bool), `hour` (int) | Reminder settings are saved | S22 |
| `reminder_opened` | – | The app opens from the reminder | S13 |

## Monetization (04 §14)

| Event | Params (type) | When fired | Screen |
|---|---|---|---|
| `reading_gate_evaluated` | `decision` (enum: device_unverified\|needs_ai_consent\|offline\|readings_paused\|ai_unavailable_region\|spread_disabled\|needs_credits\|daily_limit_reached\|needs_sync\|allowed), `spread_id` (enum [SpreadId]) | Begin is tapped and `ReadingGate` decides (the `GateDecision` variant) | S07 |
| `free_reading_used` | `bucket` (enum: free\|bonus\|paid) | The Worker commit of a free reading is confirmed | S09 |
| `reading_credit_consumed` | `bucket` (enum: free\|bonus\|paid) | The Worker commit of a bonus or paid reading is confirmed | S09 |
| `out_of_readings_viewed` | `source` (enum: question_gate\|hold_402\|balance_chip\|hold_lost\|low_trust), `rewarded_available` (bool), `free_reset_in_min` (int) | The out-of-readings sheet is shown (RC74) | S10 |
| `store_viewed` | `source` (enum: out_of_readings\|settings\|balance_chip\|deep_link) | The store is shown | S11 |
| `paywall_dismissed` | `surface` (enum: out_of_readings\|store), `seconds_visible` (int), `action_taken` (enum: none\|purchase\|reward) | S10 or S11 is closed | S10, S11 |
| `iap_products_loaded` | `count` (int), `ms` (int), `result` (enum: ok\|partial\|empty\|error) | The store product query finishes | S11 |
| `purchase_started` | `product` (enum: pack_s\|pack_m\|pack_l\|remove_ads), `price_micros` (int), `currency` (enum [Currency]) | Buy is tapped | S10, S11 |
| `purchase_pending` | `product` (enum: pack_s\|pack_m\|pack_l\|remove_ads) | The store reports a pending purchase | S11 |
| `purchase_cancelled` | `product` (enum: pack_s\|pack_m\|pack_l\|remove_ads), `error?` (enum: store_error\|verify_rejected\|already_claimed\|purchases_blocked\|product_unavailable\|network\|unknown) | The user cancels the store sheet | S10, S11 |
| `purchase_failed` | `product` (enum: pack_s\|pack_m\|pack_l\|remove_ads), `error?` (enum: store_error\|verify_rejected\|already_claimed\|purchases_blocked\|product_unavailable\|network\|unknown) | The store or Worker verification fails | S10, S11 |
| `purchase_verification_delayed` | `product` (enum: pack_s\|pack_m\|pack_l\|remove_ads) | Verification is deferred because the Worker is unreachable | S11 |
| `iap_verify_result` | `product` (enum: pack_s\|pack_m\|pack_l\|remove_ads), `status` (enum: granted\|already_granted\|pending\|rejected\|already_claimed\|error), `ms` (int), `attempt` (int) | The Worker answers a verify call | background |
| `iap_verify_stuck` | `product` (enum: pack_s\|pack_m\|pack_l\|remove_ads), `hours` (int) | An outbox row is older than `store.verifyRetryWindowHours` | background |
| `purchase_completed` | `product` (enum: pack_s\|pack_m\|pack_l\|remove_ads), `value` (int, price in micros), `currency` (enum [Currency]), `credits` (int), `is_first_purchase` (bool) | **Only** when the Worker answers `granted`; the revenue source of truth | S10, S11 |
| `restore_completed` | `result` (enum: nothing\|remove_ads) | Restore purchases finishes | S11, S20 |
| `remove_ads_changed` | `owned` (bool), `source` (enum: purchase\|restore\|ownership_check\|revoked) | The Remove Ads entitlement flips | background |
| `rewarded_offer_shown` | `eligible` (bool), `ineligible_reason?` (enum: disabled\|cap\|cooldown\|no_fill\|consent) | The rewarded option is rendered | S10, S11 |
| `rewarded_offer_tapped` | `source` (enum: out_of_readings\|store) | The rewarded option is tapped (RC34) | S10, S11 |
| `rewarded_ad_result` | `result` (enum: completed\|dismissed\|no_fill\|error) | The rewarded ad lifecycle ends | S12 |
| `rewarded_grant_result` | `result` (enum: granted\|delayed\|capped\|cooldown), `wait_ms` (int) | Polling for the SSV grant finishes (RC57) | S12 |
| `ad_banner_impression` | `screen_id` (enum: home\|journal_list\|learn_library) | A banner is shown (`kBannerAllowList`, RC18) | S05, S14, S16 |
| `ad_banner_failed` | `screen_id` (enum: home\|journal_list\|learn_library), `error_code?` (int) | A banner fails to load | S05, S14, S16 |
| `config_value_clamped` | `key` (enum [ConfigKey]) | A remote-config value is clamped or replaced by its default (RC8) | background |

## Data

| Event | Params (type) | When fired | Screen |
|---|---|---|---|
| `export_completed` | `entries_bucket` (enum: 0\|1-10\|11-50\|51-200\|201+) | A backup is exported | S24 |
| `export_failed` | `entries_bucket` (enum: 0\|1-10\|11-50\|51-200\|201+), `error?` (enum: storage\|share_failed\|unknown) | Exporting fails | S24 |
| `import_completed` | `mode` (enum: merge\|replace), `entries_bucket` (enum: 0\|1-10\|11-50\|51-200\|201+), `schema_version` (int) | A backup is imported | S25 |
| `import_failed` | `reason` (enum: not_taro\|newer_version\|corrupt\|too_large\|storage) | A backup cannot be imported | S25 |
| `data_deleted` | `worker_ack` (bool) | All data is deleted | S26 |

## Settings

| Event | Params (type) | When fired | Screen |
|---|---|---|---|
| `setting_changed` | `key` (enum: theme\|language\|reversals\|haptics), `value` (enum: system\|light\|dark for theme; [Locale]\|system for language; on\|off for reversals and haptics) | A setting changes | S20, S21 |

## App

| Event | Params (type) | When fired | Screen |
|---|---|---|---|
| `app_update_required_shown` | `origin` (enum: launch\|resume\|reading_gate) | The blocking update screen is shown | S30 |
| `app_update_available_shown` | `origin` (enum: launch\|resume\|reading_gate) | The soft update notice is shown | S05 |
| `readings_paused_shown` | `origin` (enum: launch\|resume\|reading_gate) | Readings-paused is shown (RC47) | S31 |
| `device_unverified_shown` | `origin` (enum: launch\|resume\|reading_gate) | The device-unverified state is shown | S07 |
| `rate_prompt_shown` | – | The in-app review prompt is requested | S09 |

## Errors

| Event | Params (type) | When fired | Screen |
|---|---|---|---|
| `error_shown` | `kind` (enum: network\|server\|rate_limited\|device_unverified\|storage\|invalid_file\|unknown), `screen` (enum [ScreenId]) | `TaroErrorView` is shown (`ErrorKind`, 01 §8.2) | any |

## User properties

Set by the analytics adapter (Phase 12), not events. Same PR18 rules.

| Property | Values |
|---|---|
| `app_locale` | [Locale] |
| `theme` | system\|light\|dark |
| `reversals_enabled` | bool |
| `ads_removed` | bool |
| `ai_consent` | granted\|declined\|unknown |
| `has_purchased` | bool |
| `journal_size_bucket` | 0\|1-10\|11-50\|51-200\|201+ |

## Differences from the specs

- `prompt_version` is an `int` (the `N` of `ai.promptVersion` `vN`, BE11) instead of 01's "str enum", so no string value is open-ended.
- `purchase_completed.value` is the price in micros (`int`, PR18), like `purchase_started.price_micros`. The Firebase adapter converts it to currency units for the reserved `purchase` revenue fields.
- `currency` is the closed [Currency] set above instead of a raw ISO string.
- `reading_refused.category` also has `other` (model refusal or unknown category, `RefusalCategory.other`).
- 01 lists `export_completed / export_failed` with `entries_bucket, error?`; only `export_failed` has `error?`. Likewise `ad_banner_impression` has no `error_code?`, only `ad_banner_failed` does.
- Unspecified value sets were fixed here: `note_len_bucket`, `entries_bucket`, `iap_products_loaded.result`, `iap_verify_result.status`, `purchase_*.error`, `export_failed.error`, the `origin` of the app notice events, `rewarded_offer_shown.ineligible_reason` (= `RewardUnavailableReason`).
