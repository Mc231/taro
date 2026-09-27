# Glossary — Canonical Names

**Status:** v1.1 reconciled (2026-09-27). Owner: Volodymyr.
**Decisions:** see 00_DECISIONS.md
**Produced by:** Phase 1 Sprint 1.2 ([../phases/PHASE_01_SPEC_RECONCILIATION.md](../phases/PHASE_01_SPEC_RECONCILIATION.md)). Built from specs 01–06 at "v1.1 reconciled (2026-09-27)"; every cross-spec disagreement found while building it was fixed in the specs (Phase 1 verification, 2026-09-27); names that only this file defines are listed at the end (RC94).
**Checked by:** `tools/check_glossary.py` (Phase 3), which compares the tables below with the generator inputs and code constants.

---

## Purpose

Every ID, route, error code, table, config key, port, screen and secret name that code or a phase doc may use is listed here exactly once. `00_DECISIONS.md` records *why* a name won; this file records *what* the name is.

Rules:
- **Canonical names only** (02 rule 22). A new name is added here first, in the same change as the code or spec that introduces it. A renamed item needs an RC row (00_DECISIONS.md "How to add an RC").
- The owning spec stays the source of meaning; this file is the source of spelling. Each table names its owner.
- Superseded names are listed only in `00_DECISIONS.md` and the Phase 1 doc (Sprint 1.4 grep); they never appear here.
- Names marked **(glossary-defined)** are not spelled out in any spec; a spec delegates them here (see "Glossary-defined names" at the end, RC94).

---

## 1. Card IDs

Owner: 01 §10.1. Reconciled by 00_DECISIONS.md RC1. Format `major_00` … `major_21`, `{wands,cups,swords,pentacles}_01` … `_14`; rank 01 = Ace, 11 = Page, 12 = Knight, 13 = Queen, 14 = King. IDs are shared by the client, Worker prompts, exports and analytics (`learn_card_viewed.card_id`) and never change. `number` in `TarotCard` / `DeckCard` equals the rank column (0–21 major, 1–14 minor).

The English names are the `en` entries of `packages/taro_content/source/glossary.yaml` (01 §11 step 2). The specs fix only `major_00` = "The Fool"; the other names are the traditional names in RWS order (`Deck.id = rws_original`, 02 §4) until that file is authored and reviewed.

| # | `cardId` | Arcana | Suit | Rank | English name (`en`) |
|---|---|---|---|---|---|
| 1 | `major_00` | major | — | 0 | The Fool |
| 2 | `major_01` | major | — | 1 | The Magician |
| 3 | `major_02` | major | — | 2 | The High Priestess |
| 4 | `major_03` | major | — | 3 | The Empress |
| 5 | `major_04` | major | — | 4 | The Emperor |
| 6 | `major_05` | major | — | 5 | The Hierophant |
| 7 | `major_06` | major | — | 6 | The Lovers |
| 8 | `major_07` | major | — | 7 | The Chariot |
| 9 | `major_08` | major | — | 8 | Strength |
| 10 | `major_09` | major | — | 9 | The Hermit |
| 11 | `major_10` | major | — | 10 | Wheel of Fortune |
| 12 | `major_11` | major | — | 11 | Justice |
| 13 | `major_12` | major | — | 12 | The Hanged Man |
| 14 | `major_13` | major | — | 13 | Death |
| 15 | `major_14` | major | — | 14 | Temperance |
| 16 | `major_15` | major | — | 15 | The Devil |
| 17 | `major_16` | major | — | 16 | The Tower |
| 18 | `major_17` | major | — | 17 | The Star |
| 19 | `major_18` | major | — | 18 | The Moon |
| 20 | `major_19` | major | — | 19 | The Sun |
| 21 | `major_20` | major | — | 20 | Judgement |
| 22 | `major_21` | major | — | 21 | The World |
| 23 | `wands_01` | minor | `wands` | 1 (Ace) | Ace of Wands |
| 24 | `wands_02` | minor | `wands` | 2 (Two) | Two of Wands |
| 25 | `wands_03` | minor | `wands` | 3 (Three) | Three of Wands |
| 26 | `wands_04` | minor | `wands` | 4 (Four) | Four of Wands |
| 27 | `wands_05` | minor | `wands` | 5 (Five) | Five of Wands |
| 28 | `wands_06` | minor | `wands` | 6 (Six) | Six of Wands |
| 29 | `wands_07` | minor | `wands` | 7 (Seven) | Seven of Wands |
| 30 | `wands_08` | minor | `wands` | 8 (Eight) | Eight of Wands |
| 31 | `wands_09` | minor | `wands` | 9 (Nine) | Nine of Wands |
| 32 | `wands_10` | minor | `wands` | 10 (Ten) | Ten of Wands |
| 33 | `wands_11` | minor | `wands` | 11 (Page) | Page of Wands |
| 34 | `wands_12` | minor | `wands` | 12 (Knight) | Knight of Wands |
| 35 | `wands_13` | minor | `wands` | 13 (Queen) | Queen of Wands |
| 36 | `wands_14` | minor | `wands` | 14 (King) | King of Wands |
| 37 | `cups_01` | minor | `cups` | 1 (Ace) | Ace of Cups |
| 38 | `cups_02` | minor | `cups` | 2 (Two) | Two of Cups |
| 39 | `cups_03` | minor | `cups` | 3 (Three) | Three of Cups |
| 40 | `cups_04` | minor | `cups` | 4 (Four) | Four of Cups |
| 41 | `cups_05` | minor | `cups` | 5 (Five) | Five of Cups |
| 42 | `cups_06` | minor | `cups` | 6 (Six) | Six of Cups |
| 43 | `cups_07` | minor | `cups` | 7 (Seven) | Seven of Cups |
| 44 | `cups_08` | minor | `cups` | 8 (Eight) | Eight of Cups |
| 45 | `cups_09` | minor | `cups` | 9 (Nine) | Nine of Cups |
| 46 | `cups_10` | minor | `cups` | 10 (Ten) | Ten of Cups |
| 47 | `cups_11` | minor | `cups` | 11 (Page) | Page of Cups |
| 48 | `cups_12` | minor | `cups` | 12 (Knight) | Knight of Cups |
| 49 | `cups_13` | minor | `cups` | 13 (Queen) | Queen of Cups |
| 50 | `cups_14` | minor | `cups` | 14 (King) | King of Cups |
| 51 | `swords_01` | minor | `swords` | 1 (Ace) | Ace of Swords |
| 52 | `swords_02` | minor | `swords` | 2 (Two) | Two of Swords |
| 53 | `swords_03` | minor | `swords` | 3 (Three) | Three of Swords |
| 54 | `swords_04` | minor | `swords` | 4 (Four) | Four of Swords |
| 55 | `swords_05` | minor | `swords` | 5 (Five) | Five of Swords |
| 56 | `swords_06` | minor | `swords` | 6 (Six) | Six of Swords |
| 57 | `swords_07` | minor | `swords` | 7 (Seven) | Seven of Swords |
| 58 | `swords_08` | minor | `swords` | 8 (Eight) | Eight of Swords |
| 59 | `swords_09` | minor | `swords` | 9 (Nine) | Nine of Swords |
| 60 | `swords_10` | minor | `swords` | 10 (Ten) | Ten of Swords |
| 61 | `swords_11` | minor | `swords` | 11 (Page) | Page of Swords |
| 62 | `swords_12` | minor | `swords` | 12 (Knight) | Knight of Swords |
| 63 | `swords_13` | minor | `swords` | 13 (Queen) | Queen of Swords |
| 64 | `swords_14` | minor | `swords` | 14 (King) | King of Swords |
| 65 | `pentacles_01` | minor | `pentacles` | 1 (Ace) | Ace of Pentacles |
| 66 | `pentacles_02` | minor | `pentacles` | 2 (Two) | Two of Pentacles |
| 67 | `pentacles_03` | minor | `pentacles` | 3 (Three) | Three of Pentacles |
| 68 | `pentacles_04` | minor | `pentacles` | 4 (Four) | Four of Pentacles |
| 69 | `pentacles_05` | minor | `pentacles` | 5 (Five) | Five of Pentacles |
| 70 | `pentacles_06` | minor | `pentacles` | 6 (Six) | Six of Pentacles |
| 71 | `pentacles_07` | minor | `pentacles` | 7 (Seven) | Seven of Pentacles |
| 72 | `pentacles_08` | minor | `pentacles` | 8 (Eight) | Eight of Pentacles |
| 73 | `pentacles_09` | minor | `pentacles` | 9 (Nine) | Nine of Pentacles |
| 74 | `pentacles_10` | minor | `pentacles` | 10 (Ten) | Ten of Pentacles |
| 75 | `pentacles_11` | minor | `pentacles` | 11 (Page) | Page of Pentacles |
| 76 | `pentacles_12` | minor | `pentacles` | 12 (Knight) | Knight of Pentacles |
| 77 | `pentacles_13` | minor | `pentacles` | 13 (Queen) | Queen of Pentacles |
| 78 | `pentacles_14` | minor | `pentacles` | 14 (King) | King of Pentacles |

## 2. Spread IDs and position IDs

Owner: 01 §10.3. Reconciled by 00_DECISIONS.md RC2, RC62. The daily card is **not** a spread and never calls the Worker. Every spread costs exactly 1 credit (no per-spread cost key). Positions are listed in draw and reveal order (`SpreadPosition.order` = list index + 1). ARB keys: `spread_{spreadId}_pos_{positionId}_name` and `spread_{spreadId}_pos_{positionId}_desc` (01 §10.2, 02 AR15). `ai.maxTokensBySpread` values are 03 §8.2 defaults.

| `spreadId` | Cards | `positionId`s (in order) | `ai.maxTokensBySpread` |
|---|---|---|---|
| `single` | 1 | `focus` | 2500 |
| `three_ppf` | 3 | `past`, `present`, `future` | 4000 |
| `three_sao` | 3 | `situation`, `action`, `outcome` | 4000 |
| `relationship` | 5 | `you`, `other`, `connection`, `challenge`, `potential` | 5500 |
| `two_paths` | 5 | `situation`, `path_a`, `path_a_outcome`, `path_b`, `path_b_outcome` | 5500 |
| `celtic_cross` | 10 | `present`, `challenge`, `foundation`, `recent_past`, `potential`, `near_future`, `self`, `environment`, `hopes_fears`, `outcome` | 8000 |
| `*` (fallback key) | — | — | 4000 |

`spreads.enabled` default = all six IDs. Default spread version on the wire: `spread: {id, version: 1}`. Generated files: `packages/taro_content/assets/spreads/spreads.json`, `worker/src/generated/deck/spreads.json` (RC26).

## 3. Product IDs and analytics aliases

Owner: 04 §4, §4.1. Reconciled by 00_DECISIONS.md RC3, RC80. Same IDs on both stores. Credits live only in `PRODUCT_CATALOG` (`worker/src/monetization/catalog.ts`); the client constant `TaroProducts` (`taro_core`) holds IDs, kind and alias only. A size change means a new product ID.

| Product ID | Analytics alias (`product`) | Kind (`PRODUCT_CATALOG`) | Store type (`aso.yaml`) | Credits | Price (USD) | `price_tier` | Store display name |
|---|---|---|---|---|---|---|---|
| `com.vshyrochuk.taro.readings_3` | `pack_s` | `consumable` | `CONSUMABLE` | 3 | $1.99 | 2 | "3 Readings" |
| `com.vshyrochuk.taro.readings_10` | `pack_m` | `consumable` | `CONSUMABLE` | 10 | $4.99 | 5 | "10 Readings" |
| `com.vshyrochuk.taro.readings_30` | `pack_l` | `consumable` | `CONSUMABLE` | 30 | $9.99 | 10 | "30 Readings" |
| `com.vshyrochuk.taro.remove_ads` | `remove_ads` | `non_consumable` | `NON_CONSUMABLE` | — | $3.99 | 4 | "Remove Banner Ads" |

`remove_ads` is never sent to the Worker (`422 PRODUCT_UNKNOWN` if it is). Family Sharing: on for `remove_ads` (MO17). Default `store.packs` sort order: `readings_3` 0, `readings_10` 1, `readings_30` 2. Drift `entitlements.key` for Remove Ads = `remove_ads`.

## 4. Endpoints

Owner: 03 §2.1 (complete v1 surface). Reconciled by 00_DECISIONS.md RC4, RC11, RC50, RC51, RC57, RC84. Base URL `https://{API_HOST}/v1`. **[idem]** = `Idempotency-Key` required; **[attest]** = `X-Taro-Attestation` required (exactly the four routes of RC11 as extended by RC50). There is **no admin route** (RC84).

| # | Method + path | Auth | [idem] | [attest] | Client call (02 §6.3) | Client timeout | 03 § |
|---|---|---|---|---|---|---|---|
| E01 | `GET /v1/health` | public | — | — | — (smoke only) | — | §14.2 |
| E02 | `GET /v1/config` | public | — | — | Remote config (`If-None-Match`) | 10 s | §8.1 |
| E03 | `POST /v1/attest/challenge` | public, rate-limited | — | — | Challenge | 10 s | §3.2 |
| E04 | `POST /v1/installs` | public (attestation in body) | yes (fresh UUID per attempt, RC55) | — | Register install | 15 s | §3.3 |
| E05 | `POST /v1/installs/token` | token (may be expired) | — | **yes** | Refresh token | 15 s | §3.4 |
| E06 | `PUT /v1/installs/me/timezone` | token | yes | — | Update timezone | 15 s | §3.5 |
| E07 | `DELETE /v1/installs/me` | token | yes (fresh UUID per action, RC55) | — | Delete server data | 15 s | §3.6 |
| E08 | `GET /v1/balance` | token | — | — | Balance sync (also the resume sync, RC46) | 10 s | §5.1 |
| E09 | `POST /v1/readings/holds` | token | yes (`== clientReadingId`) | **yes** | Pre-draw hold | 15 s | §9.0 |
| E10 | `POST /v1/readings` | token | yes (`== clientReadingId`) | **yes** | Create reading | **60 s** (slow state at 20 s) | §9.1 |
| E11 | `GET /v1/readings/{clientReadingId}` | token | — | — | Get reading (resume / poll) | 10 s | §9.1 |
| E12 | `POST /v1/readings/{clientReadingId}/ack` | token | — (idempotent, no body) | — | Acknowledge delivery | 10 s | §9.1 |
| E13 | `POST /v1/readings/{clientReadingId}/report` | token | yes (fresh UUID per submit) | — | Report reading | 15 s | §9.7 |
| E14 | `POST /v1/purchases/verify` | token | yes (UUID stored on the `purchase_outbox` row) | — | Verify purchase (`platform` discriminator) | 20 s | §6.2, §6.3 |
| E15 | `POST /v1/rewards/intents` | token | yes (new UUID per tap) | **yes** | Reward intent | 10 s | §7.1 |
| E16 | `GET /v1/rewards/intents/{intentId}` | token | — | — | Reward status (poll every 1.5 s) | 10 s | §7.3 |
| E17 | `POST /v1/rewards/intents/{intentId}/cancel` | token | — | — | Cancel reward intent | 10 s | §7.3 |
| E18 | `GET /v1/ads/admob/ssv` | AdMob ECDSA signature | — | — | — (AdMob callback) | — | §7.2 |
| E19 | `POST /v1/webhooks/appstore` | Apple JWS (ASSN v2) | — | — | — | — | §6.4 |
| E20 | `POST /v1/webhooks/googleplay` | Pub/Sub OIDC JWT | — | — | — | — | §6.4 |

Success statuses: E04 `201` new / `200` existing; E07 `204`; E09 `201`; E10 `200` (`status: completed | declined`); E13 `201`; E14 `200 granted` or `202 pending`; E15 `201`; E12 and E17 `204` (04 §7). The only non-`/v1` route is the RC92 fallback `taro.vshyrochuk.com/.well-known/*`, used only if static hosting cannot set the content type.

Owner-run CLIs instead of routes (03 §1): `worker/scripts/config-push.ts`, `ledger-adjust.ts`, `credits-transfer.ts`, `reports-export.ts`, `metrics.ts`, `smoke.ts`, each over `src/admin/*`.

### 4.1 Request headers

Owner: 03 §2.1.

| Header | Value | Sent on |
|---|---|---|
| `Authorization` | `Bearer <installToken>` | every token route |
| `X-Taro-Platform` | `ios` \| `android` | every app request |
| `X-Taro-App-Version` | `1.2.0+14` | every app request |
| `X-Taro-Locale` | one of the 12 locales | every app request |
| `Idempotency-Key` | UUID v4 | [idem] routes |
| `X-Taro-Attestation` | `aa1.<assertion>` (iOS), `pi1.<standard integrity token>` (Android), `none` (low trust) | [attest] routes |
| `X-Taro-AI-Consent` | granted consent version (int) | E09, E10 (RC28) |
| `X-Request-Id` | UUID per attempt | optional; echoed on every response |
| `Idempotent-Replayed` | `true` | response header on a replay |

## 5. Error codes → HTTP → `Failure` → ARB key

Owners: codes 03 §2.2 (UPPER_SNAKE, RC5); `Failure` subtypes 02 §3; client states 01 §8.3. Envelope: `{error: {code, message, requestId, retryable, retryAfterSec?, details?}}`. **ARB keys (glossary-defined):** `failure` + the `Failure` class name without the `Failure` suffix, one key per `Failure` subtype (02 §3); screen states keep their own copy keys. A declined reading is `200 status: declined`, never an error (§5.2).

| HTTP | `code` | Retryable | `details` | `Failure` (02 §3) | ARB key | Client state (01 §8.3) |
|---|---|---|---|---|---|---|
| 400 | `VALIDATION_FAILED` | no | `issues[]` | `ContractFailure` | `failureContract` | generic error + crash report |
| 400 | `IDEMPOTENCY_KEY_REQUIRED` | no | — | `ContractFailure` | `failureContract` | generic error + crash report |
| 401 | `UNAUTHENTICATED` | no | — | `SessionExpiredFailure` | `failureSessionExpired` | silent re-registration |
| 401 | `TOKEN_EXPIRED` | no | — | handled by the auth interceptor (E05, one retry); then `SessionExpiredFailure` | `failureSessionExpired` | — |
| 401 | `ATTESTATION_REQUIRED` | no | — | `AttestationFailure` | `failureAttestation` | `deviceUnverified` |
| 402 | `INSUFFICIENT_CREDITS` | no | `freeResetsAt`, `reason` ∈ `noCredits \| lowTrustCap \| freePaused` | `InsufficientCreditsFailure` | `failureInsufficientCredits` | S10; `lowTrustCap` → `lowTrustLimited`; `freePaused` → S31 `freePaused` variant |
| 403 | `ATTESTATION_FAILED` | no | — | `AttestationFailure` | `failureAttestation` | `deviceUnverified` |
| 403 | `REWARDED_DISABLED` | no | — | `RewardUnavailableFailure` | `failureRewardUnavailable` | S10 option disabled |
| 403 | `AI_UNAVAILABLE_REGION` | no | — | `AiUnavailableRegionFailure` | `failureAiUnavailableRegion` | S07 `aiUnavailableRegion` → Classic offer (RC29) |
| 404 | `NOT_FOUND` | no | — | `ContractFailure` | `failureContract` | generic error + crash report |
| 409 | `REQUEST_IN_PROGRESS` | yes (`Retry-After: 3`) | — | `RequestInProgressFailure` | `failureRequestInProgress` | retried, then polling |
| 409 | `HOLD_CONFLICT` | no | — | `HoldConflictFailure` | `failureHoldConflict` | S08 `holdLost` → S10, cards face-down |
| 409 | `PURCHASE_ALREADY_CLAIMED` | no | `transferEligible`, `transferToken` | `PurchaseAlreadyClaimedFailure` | `failurePurchaseAlreadyClaimed` | S11 `failed` + transfer hint (RC84, RC85) |
| 409 | `REWARDED_DAILY_CAP` | no | `reason` ∈ `cap \| cooldown`, `availableAt` | `RewardUnavailableFailure` | `failureRewardUnavailable` | S10 option capped / cooling down |
| 409 | `TIMEZONE_CHANGE_TOO_SOON` | no | `allowedAfter` | `TimezoneChangeRejectedFailure` | `failureTimezoneChangeRejected` | none (server boundary kept) |
| 410 | `READING_EXPIRED_REFUNDED` | no | `balance` | `ReadingExpiredRefundedFailure` | `failureReadingExpiredRefunded` | S08 `deliveryExpired` (RC51) |
| 412 | `AI_CONSENT_REQUIRED` | no | `requiredVersion` | `AiConsentRequiredFailure` | `failureAiConsentRequired` | S04 re-prompt (RC21, RC28) |
| 422 | `IDEMPOTENCY_KEY_REUSED` | no | — | `ContractFailure` | `failureContract` | generic error + crash report |
| 422 | `PURCHASE_INVALID` | no | `reason` (e.g. `sandbox_cap`) | `PurchaseFailure` | `failurePurchase` | S11 `failed(kind)`, transaction finished |
| 422 | `PRODUCT_UNKNOWN` | no | — | `PurchaseFailure` | `failurePurchase` | S11 `failed(kind)`, transaction finished |
| 422 | `SPREAD_INVALID` | no | `reason` (e.g. `disabled`) | `ContractFailure` | `failureContract` | generic error + crash report |
| 426 | `UPGRADE_REQUIRED` | no | — | `UpgradeRequiredFailure` | `failureUpgradeRequired` | S30 `/update` |
| 429 | `RATE_LIMITED` | yes (`Retry-After`) | `reason` ∈ `burst \| dailyLimit \| declinedLimit \| lowTrustCap \| reportLimit` | `RateLimitedFailure` | `failureRateLimited` | `rateLimited`; `dailyLimit` → S07 `dailyLimitReached` (RC74); `reportLimit` → S33 `rateLimited` |
| 202 | `PURCHASE_PENDING` (status body, not an error) | — | — | `PurchasePendingFailure` | `failurePurchasePending` | S11 `pending` |
| 500 | `INTERNAL` | yes | — | `ServerFailure` | `failureServer` | generic error |
| 503 | `AI_UNAVAILABLE` | yes | — | `AiUnavailableFailure` | `failureAiUnavailable` | S08 `generationFailed` + Try again |
| 503 | `AI_BUDGET_EXHAUSTED` | yes | `tier` ∈ `freeStop \| hard` | `ReadingsPausedFailure` | `failureReadingsPaused` | S31 `readingsPaused` + Classic offer, never S10 (RC47) |
| 503 | `READINGS_DISABLED` | yes | — | `ReadingsPausedFailure` | `failureReadingsPaused` | S31 `readingsPaused` + Classic offer, never S10 (RC47) |
| any | unknown code / unparseable | — | — | `ServerFailure` | `failureServer` | generic error |

Client-side `Failure` subtypes with no wire code (02 §3):

| `Failure` | Raised by | ARB key |
|---|---|---|
| `NetworkFailure` | offline, DNS, socket | `failureNetwork` |
| `TimeoutFailure` | client timeout | `failureTimeout` |
| `PurchaseCancelledFailure` | store cancel (silent return) | `failurePurchaseCancelled` |
| `PurchasesBlockedFailure` | `BalanceDto.purchasesAllowed == false`, reason `blocked \| refundDebt \| storeDisabled` (RC66) | `failurePurchasesBlocked` |
| `ProductUnavailableFailure` | store product missing | `failureProductUnavailable` |
| `StorageFailure` | drift / secure storage | `failureStorage` |
| `BackupInvalidFailure` | import, reason `notJson \| wrongFormat \| unsupportedVersion \| checksum \| schema \| tooLarge` | `failureBackupInvalid` |
| `UnexpectedFailure` | anything unmapped (always reported to crash) | `failureUnexpected` |

Sub-reason enums (Dart, 02 §3): `RateLimitReason` = `burst | dailyLimit | declinedLimit | lowTrustCap | reportLimit`; `InsufficientReason` = `noCredits | lowTrustCap | freePaused`; `PausedReason` = `disabled | budgetHard | freeStop`; `RewardUnavailableReason` = `disabled | cap | cooldown | noFill | consent`; `AttestationFailureKind` = `unsupported | keyInvalidated | rejected | quota | transient`. Shared UI `ErrorKind` (01 §8.2) = `network | server | rateLimited | deviceUnverified | storage | invalidFile | unknown`.

### 5.1 Other wire enums

| Field | Values | Owner |
|---|---|---|
| `BalanceDto.canReadReason` | `noCredits \| dailyLimit \| lowTrustCap \| readingsPaused` | 03 §5.1 (RC74) |
| `BalanceDto.purchasesBlockedReason` | `blocked \| refundDebt \| storeDisabled` | 03 §5.1 (RC66) |
| `BalanceDto.nextSource`, `chargeSource` | `free \| bonus \| paid` (`none` for a declined reading) | 03 §5.1, §9.1 |
| Reading response `status` | `completed \| declined` | 03 §9.1 |
| `GET /v1/readings/{clientReadingId}` `status` | `readings.status` values (§6) | 03 §9.1 |
| Verify response `status` | `granted \| already_granted \| pending` (`already_granted` = idempotent replay for the same install; `pending` = `202`, Android; rejections are `422`/`409` errors). `200` body also carries `purchaseId, productId, creditsGranted, isFirstPurchase, balance` | 03 §6.2, §6.3 |
| Reward intent `status` | `issued \| granted \| cancelled \| expired \| rejected` | 03 §7.3 |
| Registration `trust` | `high \| low` | 03 §3.3 |
| `attestation.type` | `app_attest \| play_integrity \| none` | 03 §3.3 |
| Report `reason` | `offensive \| harmful_advice \| sexual \| hateful \| other` | 03 §9.7 |
| Report response `status` | `received` | 03 §9.7 |
| Health response | `{status: "ok", workerVersion, environment}` | 03 §14.2 |

DTO names: `BalanceDto` (wire, → `CreditBalance` domain), `PublicConfigDto`, `ReadingResponseDto`, `CrisisResource{name, phone?, sms?, url?, hours?, languages[], verifiedAt}` (RC81). Reading wire object: `{title, overview, cards[{positionId, cardId, reversed, interpretation}], synthesis, reflectionPrompts}` → domain `ReadingContent{title, summary, positions[{positionId, text}], synthesis, reflectionPrompts}` (RC30).

### 5.2 Refusal categories and `messageKey`s

Owner: 03 §9.4 (RC27). `messageKey` values follow the 03 §9.1 example `safetyDeclinedSelfHarm` (**glossary-defined** for the other categories).

| Wire `category` | Dart `RefusalCategory` | `canRephrase` | Crisis resources (S27) | `messageKey` / ARB key |
|---|---|---|---|---|
| `self_harm` | `selfHarm` | no | yes | `safetyDeclinedSelfHarm` |
| `harm_to_others` | `harmToOthers` | no | yes (emergency line) | `safetyDeclinedHarmToOthers` |
| `health` | `health` | yes | no | `safetyDeclinedHealth` |
| `pregnancy` | `pregnancy` | yes | no | `safetyDeclinedPregnancy` |
| `death` | `death` | yes | no | `safetyDeclinedDeath` |
| `legal` | `legal` | yes | no | `safetyDeclinedLegal` |
| `financial` | `financial` | yes | no | `safetyDeclinedFinancial` |
| `gambling` | `gambling` | yes | no | `safetyDeclinedGambling` |
| `sexual_minors` | `sexualMinors` | no | no | `safetyDeclinedSexualMinors` |
| `hate_or_harassment` | `hateOrHarassment` | yes | no | `safetyDeclinedHateOrHarassment` |
| model refusal / unknown | `other` | no | no | `refusalGeneric` (05 §3) |

Mapping of older terms: 01 "rephrase" = declined with `canRephrase: true`; 01 "crisis" = `self_harm` or `harm_to_others`; 05 "moderation blocked" = `sexual_minors` or `hate_or_harassment`. Model output `classification` adds `none`. `readings.safety_layer` ∈ `L1 | L2 | L3 | model_refusal`.

### 5.3 Compliance ARB keys fixed by 05 §3

`disclaimerShort`, `disclaimerOnboardingTitle`, `disclaimerOnboardingBody`, `aiConsentTitle`, `aiConsentBody`, `aiConsentAccept`, `aiConsentDecline`, `aiLabel`, `refusalGeneric`, `crisisTitle`, `crisisBody`, `reportReadingTitle`, `reportReadingDisclosure`. ARB file: `packages/taro_l10n/lib/src/arb/app_en.arb` + 11 translations (02 §11, RC15).

## 6. D1 tables (Worker)

Owner: 03 §4 (`migrations/0001_init.sql`, canonical DDL, RC7) + `reading_reports` (RC22). Retention per 03 §13 (single source, RC69). "Erase" = effect of `DELETE /v1/installs/me` (RC37).

| Table | Primary key / unique | Holds | Retention | Erase |
|---|---|---|---|---|
| `installs` | PK `id` (client UUID v4); UNIQUE `apple_account_token`, `play_account_hash` | identity, `platform`, `status`, `trust`, `token_generation`, `state_version` (= `ledgerVersion`, RC67), `install_secret_hash`, `device_key_hash`, `device_reused`, attestation key, `timezone`, `tz_changed_at`, `refund_count` | while active; pseudonymised (`status='deleted'`) after 24 months inactive with balance 0 | kept, `status` unchanged, `locale` nulled |
| `ledger` | PK `id` (autoincrement); UNIQUE `(reason, ref_type, ref_id, bucket)`; append-only triggers `ledger_no_update`, `ledger_no_delete` | paid and bonus credit movements | 7 years | kept |
| `daily_usage` | PK `(install_id, local_date)` | `free_limit`, `free_used`, `rewarded_granted`, `readings_total`, `declined_count` | 90 days | past rows erased; today kept |
| `device_daily_usage` | PK `(device_key_hash, local_date)` | Android per-device `free_used`, `rewarded_granted` (RC53) | 90 days | rows older than today erased |
| `purchases` | PK `id` (UUIDv7); UNIQUE `(platform, store_txn_id)`; partial UNIQUE `purchase_token` | verified store transactions, `credits`, `is_test`, `environment` | 7 years | kept |
| `ad_rewards` | PK `id` (= `intentId`); UNIQUE `admob_txn_id` | reward intents and grants | 13 months | erased |
| `readings` | PK `id` (UUIDv7, server); UNIQUE `(install_id, client_reading_id)` | reading **metadata only**, hold state machine, tokens, cost | 13 months | erased |
| `reading_reports` | PK `id` (UUIDv7); UNIQUE `(install_id, client_reading_id)` | user-initiated report, `payload_enc` (AES-256-GCM, `REPORT_ENC_KEY`) | 90 days (`expires_at`) | erased |
| `idempotency_keys` | PK `(install_id, route, key)` | encrypted replay bodies (`IDEMPOTENCY_ENC_KEY`) | 7 days | erased |
| `webhook_events` | PK `id` (`notificationUUID` \| Pub/Sub `messageId` \| `ssv:{transaction_id}`) | webhook / SSV dedupe | — | — |
| `used_challenges` | PK `nonce` | replay protection for challenges | until `expires_at` | — |
| `ai_spend_daily` | PK `date_utc` | `readings`, `cost_micro_usd` per UTC day | — | — |

Indexes: `ledger_install`, `purchases_install`, `purchases_token`, `ad_rewards_install`, `readings_created`, `readings_open`, `readings_unacked`, `reading_reports_expires`, `idem_expires`.

Column enums:

| Column | Values |
|---|---|
| `installs.status` | `active \| blocked \| deleted` |
| `installs.trust` | `high \| low` |
| `installs.attest_env` | `production \| development` |
| `ledger.bucket` | `paid \| bonus` |
| `ledger.reason` | `purchase \| purchase_reversal_regrant \| refund_revoke \| ad_reward \| promo \| admin_adjust \| reading_hold \| reading_refund \| reading_undelivered` |
| `ledger.ref_type` | `purchase \| ad_reward \| reading \| admin`; readings use `ref_id = '{readings.id}#{attempt}'` (RC49) |
| `purchases.status` | `granted \| revoked \| reversal_regranted` |
| `purchases.environment` | `production \| sandbox` |
| `ad_rewards.status` | `issued \| granted \| cancelled \| expired \| rejected` |
| `readings.status` | `held \| generating \| completed \| declined \| failed \| no_credit \| expired_hold \| expired_refunded` |
| `readings.hold_source` | `free \| bonus \| paid` |
| `readings.hold_state` | `none \| held \| consumed \| refunded` |
| `readings.charge_source` | `free \| bonus \| paid \| none` |
| `reading_reports.reason` | `offensive \| harmful_advice \| sexual \| hateful \| other` |
| `idempotency_keys.state` | `in_progress \| done` |
| `webhook_events.source` | `apple \| google \| admob` |
| `webhook_events.status` | `processed \| ignored \| failed` |

Logical ledger operations (04 §5.2) → 03 names: reserve → `reading_hold` (or `daily_usage.free_used + 1`), release → `reading_refund` / `reading_undelivered`, commit → `readings.status='completed'` + `hold_state='consumed'` (RC7).

### 6.1 KV, bindings, Worker environments

Owner: 03 §1, §2.4, §8.1, §11.

| Name | Kind | Use |
|---|---|---|
| `DB` | D1 binding | the one D1 database (`taro-staging`, `taro-prod`; local miniflare in dev) |
| `CONFIG_KV` | KV namespace | keys `config:public`, `config:server` |
| `RL_KV` | KV namespace | approximate counters `lt:ip:{hash}:{yyyymmdd}`, `lt:bucket:{plat}:{ver}:{yyyymmdd}`, registration counters |
| `CACHE_KV` | KV namespace | Google OAuth token, Google JWKS, AdMob verifier keys, alert dedupe timestamps |
| `METRICS` | Analytics Engine dataset `taro_api_events` | metrics events (03 §14.1) |
| `RL_BURST` | Workers Rate Limiting binding | keys `inst:{id}`, `ip:{prefix hash}` |
| `RL_READINGS` | Workers Rate Limiting binding | key `inst:{id}` |

| Environment (`ENVIRONMENT`) | Worker name | D1 | Anthropic workspace | Host |
|---|---|---|---|---|
| `dev` | local `wrangler dev` | local miniflare | none (`AI_PROVIDER=fake`) | `http://localhost:8787` |
| `staging` | `taro-api-staging` | `taro-staging` | `taro-staging` | `api-staging.taro.vshyrochuk.com` |
| `prod` | `taro-api` | `taro-prod` | `taro-prod` | `api.taro.vshyrochuk.com` |

Cron triggers (03 §12): `*/15 * * * *` (`BudgetService.check`, `releaseExpiredHolds`, `refundStaleHolds`, intent expiry, `AlertService.check`), `7 * * * *` (`refundUndeliveredReadings`, idempotency and challenge purges, pending Google acknowledgements), `30 3 * * *` (Voided Purchases backstop, retention purge, daily summary).

## 7. drift tables (client)

Owner: 02 §6.1 as edited by RC14, RC17, RC51, RC75, RC91. Two files, each `schemaVersion` 1, opened with `driftDatabase(name: 'taro_journal' | 'taro_device')`. Schema dumps: `db/schema/{journal,device}/drift_schema_v{n}.json`.

| DB file | Database class | Table | Key | Notes |
|---|---|---|---|---|
| `taro_journal.db` | `JournalDatabase` | `readings` | `id` (= `clientReadingId`) | `status` ∈ `pending \| complete \| failed \| refused \| classic`; `content_json`, `safety_json`, `charge_source`, `delivery_acked`, `reported` |
| `taro_journal.db` | `JournalDatabase` | `reading_cards` | `(reading_id, position_id)` | FK `ON DELETE CASCADE` |
| `taro_journal.db` | `JournalDatabase` | `daily_cards` | `local_date` | |
| `taro_journal.db` | `JournalDatabase` | `settings` | `key` | `UserSettings` only (exported) |
| `taro_journal.db` | `JournalDatabase` | `journal_fts` | — | FTS5, or indexed lowercase column + `LIKE` per the Phase 2.2 spike (RC91) |
| `taro_device.db` | `DeviceDatabase` | `balance_cache` | single row | `BalanceDto` JSON, `ledger_version`, `server_time`, `synced_at` |
| `taro_device.db` | `DeviceDatabase` | `remote_config_cache` | single row | `json`, `etag`, `fetched_at` |
| `taro_device.db` | `DeviceDatabase` | `entitlements` | `key` (`remove_ads`) | kept by "Delete all data" |
| `taro_device.db` | `DeviceDatabase` | `purchase_outbox` | `txn_key` | `status` ∈ `awaitingVerification \| granted \| finished \| rejected`; kept by "Delete all data" |
| `taro_device.db` | `DeviceDatabase` | `consent_state` | single row | `ConsentState` JSON |
| `taro_device.db` | `DeviceDatabase` | `sync_state` | `key` | e.g. queued `DELETE /v1/installs/me` |
| `taro_device.db` | `DeviceDatabase` | `pending_acks` | `reading_id` | ack retry queue (RC51) |

`taro_journal.db` may be included in OS backups; `taro_device.db` (plus `-wal`/`-shm`) is excluded on iOS (`NSURLIsExcludedFromBackupKey`) and Android (`data_extraction_rules.xml`, `full_backup_content.xml`) (RC75).

Backup file: `taro-backup-YYYY-MM-DD.json`, `format: "taro.backup"`, `schemaVersion: 1`, JSON Schema `docs/specs/backup_schema_v1.json` (copy: `packages/taro_data/lib/src/backup/backup_schema_v1.json`), checksum SHA-256 over RFC 8785 JCS of `data` (RC70). Exported reading statuses: `complete`, `refused`, `classic`.

## 8. Remote-config keys

Owner: 03 §8.2 (names, schema, defaults; RC8); monetization types and ranges from 04 §13. One schema `worker/src/config/schema.ts`, one defaults file `worker/config/remote_config.default.json`. Config is not signed (RC82). "Enforcer" = where the value has an effect; a Worker-enforced value is always read server-side.

### 8.1 Public (`PublicConfigDto`, `config:public`)

| Key | Type | Default | Range / values | Enforcer |
|---|---|---|---|---|
| `readings.enabled` | bool | `true` | only reading kill switch → `503 READINGS_DISABLED` | Worker |
| `readings.freeDaily` | int | `1` | 1–5 (MO14) | Worker |
| `readings.maxPerInstallPerDay` | int | `30` | 5–100 | Worker |
| `readings.tzCooldownHours` | int | `24` | 12–168 | Worker |
| `spreads.enabled` | list\<string\> | all six spread IDs | subset of §2 IDs | Worker + client |
| `rewarded.enabled` | bool | `true` | — | Worker + client |
| `rewarded.amount` | int | `1` | 1–2 | Worker |
| `rewarded.dailyCap` | int | `3` | 0–10 (0 ≡ disabled) | Worker |
| `rewarded.cooldownSec` | int | `300` | 0–3600, from the last grant | Worker |
| `rewarded.intentTtlSec` | int | `900` | 300–3600 | Worker |
| `rewarded.loadTimeoutSec` | int | `10` | 5–30 | client |
| `rewarded.grantPollTimeoutSec` | int | `20` | 5–60 (poll every 1.5 s) | client |
| `ads.enabled` | bool | `true` | global ads kill switch (also hides rewarded) | client |
| `ads.bannerEnabled` | bool | `true` | — | client |
| `ads.bannerScreens` | list\<string\> | `["home","journal_list","learn_library"]` | subset of `kBannerAllowList` | client |
| `ads.bannerMinCompletedReadings` | int | `1` | 0–10 (Classic readings do not count) | client |
| `ads.attPrepromptEnabled` | bool | `true` | — | client (iOS) |
| `store.enabled` | bool | `true` | false → `purchasesBlockedReason = storeDisabled`; verify still grants | client + Worker |
| `store.packs` | list\<object\> | the three consumables, sortOrder 0/1/2 | 1–4 items | client (display) |
| `store.packs[].productId` | string | — | consumable in `PRODUCT_CATALOG` | — |
| `store.packs[].enabled` | bool | `true` | — | client |
| `store.packs[].sortOrder` | int | 0..n | 0–9 | client |
| `store.packs[].credits` | int | from `PRODUCT_CATALOG` | read-only, injected by the Worker | Worker |
| `store.verifyRetryWindowHours` | int | `72` | 24–168 | client |
| `store.pendingHoldMinutes` | int | `30` | 5–240 | client |
| `store.removeAdsEnabled` | bool | `true` | hides the offer; owners keep the entitlement | client |
| `store.showBestValueBadge` | bool | `true` | — | client |
| `store.showPerReadingPrice` | bool | `true` | — | client |
| `ai.consentVersion` | int | `1` | integer | Worker + client |
| `ai.questionMaxChars` | int | `300` | grapheme clusters after NFC + trim (RC45) | Worker + client |
| `app.minVersion.ios`, `app.minVersion.android` | string | `"1.0.0"` | below → `426 UPGRADE_REQUIRED` | Worker + client |
| `app.recommendedVersion.ios`, `app.recommendedVersion.android` | string | `"1.0.0"` | S05 `updateAvailable` (RC73) | client |
| `balance.staleAfterSec` | int | `300` | 30–3600 | client |
| `balance.resumeSyncThrottleSec` | int | `30` | 0–600 | client |
| `review.promptAfterPositiveReadings` | int | `3` | 1–20 | client |
| `legal.termsUrl` | string | `https://taro.vshyrochuk.com/terms` | — | client |
| `legal.privacyUrl` | string | `https://taro.vshyrochuk.com/privacy` | — | client |
| `support.email` | string | `support@taro.vshyrochuk.com` (05 CS10; mailbox confirmation open in 00_DECISIONS) | — | client |

### 8.2 Server-only (`config:server`, never sent to clients)

| Key | Type | Default | Enforcer |
|---|---|---|---|
| `ai.model.paid` | string | `"claude-opus-5"` | Worker |
| `ai.model.free` | string | `"claude-sonnet-5"` (BE Q1 deferred to Phase 21 cost data, owner 2026-09-27) | Worker |
| `ai.model.freeFallback` | string | `"claude-haiku-4-5"` (soft tier) | Worker |
| `ai.effort` | string | `"low"` | Worker |
| `ai.promptVersion` | string | `"v1"` | Worker |
| `ai.maxTokensBySpread` | map\<spreadId,int\> | see §2 | Worker |
| `ai.blockedCountries` | list\<string\> (ISO 3166-1 alpha-2) | `CN, RU, SA, AE, QA, KW, BH, OM` + Anthropic-unsupported snapshot (dated in 00_DECISIONS.md) | Worker (→ `403 AI_UNAVAILABLE_REGION`) |
| `ai.timeoutMs` | int | `40000` | Worker |
| `ai.maxRetries` | int | `1` | Worker |
| `ai.refusalFallbacks` | bool | `true` | Worker |
| `ai.deadlineMs` | int | `55000` | Worker |
| `ai.budget.freeUsdPerDau` | number | `0.03` | Worker |
| `ai.budget.softFloorUsd` | number | `50` | Worker |
| `ai.budget.freeStopFloorUsd` | number | `100` | Worker |
| `ai.budget.dailyHardUsd` | number | `300` | Worker |
| `readings.holdTtlSec` | int | `900` | Worker |
| `rewarded.allowedAdUnitIds` | list\<string\> | prod rewarded unit IDs (non-empty) | Worker |
| `attest.allowedAppIds` | list\<string\> | prod `["{TEAM}.com.vshyrochuk.taro", "com.vshyrochuk.taro"]`; staging adds `.stg` (RC78) | Worker |
| `attest.requiredOnReadings` | bool | `true` | Worker |
| `purchases.allowedBundleIds` | list\<string\> | prod `["com.vshyrochuk.taro"]`; staging adds `.stg` | Worker |
| `purchases.sandboxMaxCreditsPerInstallPerDay` | int | `30` | Worker |
| `purchases.sandboxGlobalCreditsPerDay` | int | `1000` | Worker |
| `purchases.apple.sendConsumptionInfo` | bool | `false` (BE Q4) | Worker |
| `alerts.error5xxRatePct` | number | `2` | Worker |
| `alerts.readingFailedRatePct` | number | `10` | Worker |
| `alerts.webhookSigFailuresPer15m` | int | `5` | Worker |
| `abuse.lowTrust.freeDaily` | int | `1` | Worker |
| `abuse.lowTrust.freePerIpPerDay` | int | `3` | Worker |
| `abuse.lowTrust.freePerCgnatPrefixPerDay` | int | `20` | Worker |
| `abuse.lowTrust.cgnatAsns` | list\<int\> | curated carrier ASNs | Worker |
| `abuse.lowTrust.powBits` | int | `20` | Worker |
| `abuse.lowTrust.registrationsPerPrefixPerDay` | int | `5` | Worker |
| `abuse.lowTrust.alertPerBucketPerDay` | int | `500` (alert only) | Worker |
| `abuse.refundBlockThreshold` | int | `3` | Worker |
| `safety.maxDeclinedPerDay` | int | `10` | Worker |
| `rl.install.perMinute` | int | `60` (`RL_BURST`) | Worker |
| `rl.readings.perMinute` | int | `6` (`RL_READINGS`) | Worker |

Not remote-configurable by design (04 §13): credits per product, cost per reading, refund clawback, `kBannerAllowList`, interstitials, consent order, client ad unit IDs. Flavor config (not remote): `iap.storekit2_enabled` (02 Risks).

## 9. Ports

### 9.1 Dart ports (`packages/taro_core/lib/src/ports`)

Owner: 02 §5 + RC41. Every port has a Prod adapter, a NoOp (shipped) where listed, and a `Fake<Port>` in `taro_testing` unless a named test implementation is given.

| Port | Prod adapter | NoOp / test implementation |
|---|---|---|
| `InstallRepository` | `InstallRepositoryImpl` | `FakeInstallRepository` |
| `SessionTokenStore` | `SecureSessionTokenStore` | `FakeSessionTokenStore` |
| `BalanceRepository` | `BalanceRepositoryImpl` | `FakeBalanceRepository` |
| `ReadingRepository` | `ReadingRepositoryImpl` | `FakeReadingRepository` |
| `JournalRepository` | `JournalRepositoryImpl` (drift) | `FakeJournalRepository` |
| `DailyCardRepository` | `DailyCardRepositoryImpl` (drift) | `FakeDailyCardRepository` |
| `ContentRepository` | `taro_content` asset repositories (`AssetDeckRepository`, `AssetSpreadRepository`, `AssetCardTextRepository`, `AssetCrisisRepository`) | `FakeContentRepository` |
| `RemoteConfigRepository` | `RemoteConfigRepositoryImpl` (E02 + drift cache) | `StaticRemoteConfigRepository` |
| `SettingsRepository` (incl. `ConsentStore`) | `SettingsRepositoryImpl` (drift) | `FakeSettingsRepository` |
| `IapService` | `StoreIapService` | `NoOpIapService` |
| `PurchaseVerifier` | Worker E14 | `FakePurchaseVerifier` |
| `PurchaseOutbox` | `PurchaseOutboxImpl` (drift `purchase_outbox`) | `FakePurchaseOutbox` |
| `EntitlementCache` | `EntitlementCacheImpl` (drift `entitlements`) | `FakeEntitlementCache` |
| `AdsService` | `AdMobAdsService` | `NoOpAdsService` |
| `BannerSlotView` (presentation port, `taro_services/presentation.dart`) | `AdMobBannerSlotView` | `NoOpBannerSlotView` |
| `RewardGateway` | `RewardGatewayImpl` (E15–E17) | `FakeRewardGateway` |
| `ConsentService` (UMP) | `UmpConsentService` | `NoOpConsentService` |
| `TrackingAuthorization` (ATT) | `AttTrackingAuthorization` | `NotSupportedTrackingAuthorization` (Android) |
| `AnalyticsService` | `FirebaseAnalyticsService`, `ConsoleAnalyticsService` (dev), `CompositeAnalyticsService`; decorator `ConsentAwareAnalytics` | `NoOpAnalyticsService` |
| `CrashReporter` | `FirebaseCrashReporter` | `NoOpCrashReporter` |
| `ReminderScheduler` | `LocalReminderScheduler` | `NoOpReminderScheduler` |
| `AttestationService` | `PlatformAttestationService` (via `taro_attestation`) | `DebugAttestationService` (dev/staging only, RC86) |
| `Clock` | `SystemClock` | `FixedClock`, `FakeClock` |
| `TimezoneProvider` | `FlutterTimezoneProvider` | `FixedTimezoneProvider` |
| `RandomSource` | `SecureRandomSource` | `SeededRandomSource`, `ScriptedRandomSource` (tests only) |
| `IdGenerator` (RC41) | `SecureIdGenerator` | `SequentialIdGenerator` |
| `Logger` (RC41) | `PackageLoggingLogger` | `SilentLogger`, `CapturingLogger` |
| `FileTransfer` | `PlatformFileTransfer` | `FakeFileTransfer` |
| `ConnectivityMonitor` | `ConnectivityPlusMonitor` | `AlwaysOnlineMonitor` |
| `ReviewPrompter` | `InAppReviewPrompter` | `NoOpReviewPrompter` |
| `AppInfo` | `PackageInfoAppInfo` | `FakeAppInfo` |
| `SecureStore` | `FlutterSecureStore` | `InMemorySecureStore` |

Not ports (pure logic or orchestration, same names everywhere): `ReadingGate` → `GateDecision`, `CardDrawer`, `ResetSchedule`, `BackupMerge`, `ProductOffer`, `BannerPolicy`, `PendingPurchaseTracker`, `IapCatalog`, `ConsentOrchestrator`, `SyncCoordinator`, `ResetTimer`, `ApiErrorMapper`, `WorkerClient`, `Redactor`, `ServerClockOffset`, `TaroEnvironment` / `ProductionEnvironment` (RC76). Controllers (Riverpod `Notifier`s, 02 §7): `QuestionController`, `DrawController`, `ReadingResultController`, `OutOfReadingsController`, `StoreController`, `RewardedController`, `ReportReadingController`, `DailyCardController`, `BackupController`. App-wide providers: `balanceProvider`, `entitlementProvider`, `consentProvider`, `remoteConfigProvider`, `connectivityProvider`, `settingsProvider`. Removed from v1: `DailyCardWidgetBridge` (Phase 23.1, RC89).

`GateDecision` (02 §4.1, RC44, RC74): `deviceUnverified | needsAiConsent | offline | readingsPaused({freePaused}) | aiUnavailableRegion | spreadDisabled | needsCredits(PaywallOptions) | dailyLimitReached | needsSync | allowed(ChargeSource)`; check order registration/trust → AI consent → online → `readings.enabled` / region → spread enabled → balance.

### 9.2 Worker ports (`worker/src/ports`)

Owner: 03 §1 (composition root `buildApp(deps: Deps)`, prod deps `makeProdDeps(env)`; RC38). Fakes in `worker/test/fakes/` (03 §15.3).

| Port | Prod adapter | Fake |
|---|---|---|
| `AiProvider` | `AnthropicAiProvider` (`adapters/anthropic/`) | `FakeAiProvider` |
| `AppAttestVerifier` | `adapters/apple/` | `FakeAppAttestVerifier` |
| `PlayIntegrityVerifier` | `adapters/google/` (Standard API only, RC87) | `FakePlayIntegrityVerifier` |
| `AppStoreServerApi` | `adapters/apple/` | `FakeAppStoreServerApi` |
| `PlayDeveloperApi` | `adapters/google/` | `FakePlayDeveloperApi` |
| `AdmobKeyProvider` | `adapters/admob/` | `FakeAdmobKeyProvider` |
| `GoogleOidcVerifier` | `adapters/google/` | — |
| `DeviceCheckApi` | `adapters/apple/` | — |
| `TokenSigner` | `jose` EdDSA | — |
| `Clock` | system clock | `FixedClock` |
| `IdGenerator` | UUIDv7 / random IDs | `SeqIdGenerator` |
| `Crypto` | WebCrypto | — |
| `ConfigStore` | `CONFIG_KV` | — |
| `Metrics` | Analytics Engine (`METRICS`) | `InMemoryMetrics` |
| `Logger` | `console.log` → Workers Logs | `CapturingLogger` (`expectNoSensitive()`) |
| `Alerter` | `ALERT_WEBHOOK_URL` | — |

Services (`src/services/`): `InstallService`, `BalanceService`, `ReadingService`, `PurchaseService` (`verifyApple`, `verifyGoogle`), `RewardService`, `RefundService`, `ConfigService`, `BudgetService`, `AlertService`. Repos (`src/repos/`): `InstallRepo`, `LedgerRepo`, `DailyUsageRepo`, `DeviceUsageRepo`, `PurchaseRepo`, `RewardRepo`, `ReadingRepo`, `IdempotencyRepo`, `WebhookEventRepo`, `SpendRepo`. Domain (`src/domain/`): `dayBoundary`, `allowance`, `ledgerRules`, `consumptionOrder`, `pricing`, `spreadValidation`, `safetyPolicy`, `outputValidator`. Admin (`src/admin/`): `ledgerAdjust`, `creditsTransfer`, `reportsExport`, `configPush`. `AiResult` = `ok | refused | truncated | error{timeout | rate_limited | upstream | invalid_output}`.

## 10. Screens S01–S33

Owner: 01 §8.1 (routes and IDs; RC17, RC71, RC72); 02 §8.1 follows. Analytics `screen` (event `screen_view`, `error_shown`) is the S-ID enum of 01 §15; its values are the literal IDs `S01` … `S33` (glossary-defined format). Banner screen IDs: `kBannerAllowList = {home, journal_list, learn_library}` (RC18); every other screen has none.

| ID | Screen | Route | Analytics `screen` | Banner screen ID |
|---|---|---|---|---|
| S01 | Launch / bootstrap | `/` | `S01` | — |
| S02 | Onboarding: Welcome | `/onboarding/welcome` | `S02` | — |
| S03 | Onboarding: Disclaimer | `/onboarding/disclaimer` | `S03` | — |
| S04 | AI consent (onboarding + re-entry) | `/consent/ai` | `S04` | — |
| S05 | Home ("Today" tab 1) | `/home` | `S05` | `home` |
| S06 | Spread picker | `/reading/spreads` | `S06` | — |
| S07 | Question input + Begin | `/reading/question?spread=` | `S07` | — |
| S08 | Draw ritual | `/reading/draw` | `S08` | — |
| S09 | Reading result | `/reading/:id` | `S09` | — |
| S10 | Out-of-readings sheet | modal | `S10` | — |
| S11 | Store / paywall | `/store` | `S11` | — |
| S12 | Rewarded flow overlay | modal | `S12` | — |
| S13 | Daily card | `/daily` | `S13` | — |
| S14 | Journal list ("Journal" tab 2) | `/journal` | `S14` | `journal_list` |
| S15 | Journal entry detail + note editor | `/journal/:id` | `S15` | — |
| S16 | Learn: deck browser ("Learn" tab 3) | `/learn` | `S16` | `learn_library` |
| S17 | Learn: card detail | `/learn/card/:cardId` | `S17` | — |
| S18 | Learn: spreads guide + spread detail | `/learn/spreads[/:spreadId]` | `S18` | — |
| S19 | Learn: About tarot & Taro | `/learn/about` | `S19` | — |
| S20 | Settings ("Settings" tab 4) | `/settings` | `S20` | — |
| S21 | Language picker | `/settings/language` | `S21` | — |
| S22 | Reminder settings | `/settings/reminder` | `S22` | — |
| S23 | Privacy choices | `/settings/privacy` | `S23` | — |
| S24 | Export backup | `/settings/export` | `S24` | — |
| S25 | Import backup | `/settings/import` | `S25` | — |
| S26 | Delete all data | `/settings/delete` | `S26` | — |
| S27 | Crisis resources | `/help/crisis` | `S27` | — |
| S28 | FAQ / Help | `/help` | `S28` | — |
| S29 | Legal (disclaimer / terms / privacy / licenses) | `/legal/:doc` | `S29` | — |
| S30 | Update required (blocking) | `/update` | `S30` | — |
| S31 | Readings paused (`readingsPaused`) | inline state of S07 (no route) | `S31` | — |
| S32 | Classic reading result | `/reading/:id?mode=classic` | `S32` | — |
| S33 | Report reading | modal from S09 / S15 | `S33` | — |

Deep links (01 §9.1, 02 §8.2): `taro://daily` → `/daily`, `taro://reading/new?spread={spreadId}` → `/reading/question?spread=`, `taro://journal/{id}` → `/journal/:id`, `taro://learn/card/{cardId}` → `/learn/card/:cardId`, `taro://store` → `/store`; anything else → `/home`. Universal / App Links host `https://taro.vshyrochuk.com/app/*`. Router guards: `updateGuard` → `onboardingGuard` → `deepLinkPolicy`.

## 11. Flows F1–F8

Owner: 01 §9.2–§9.9. Integration tests per 06 §4 (patrol, `apps/taro/integration_test/flows/`).

| ID | Flow | 01 § | Path | Endpoints | Integration test |
|---|---|---|---|---|---|
| F1 | First launch | §9.2 | S01 → S02 → S03 → S04 → UMP → ATT pre-prompt → ATT → S05 | E02, E03, E04, E08 | `first_launch_free_reading_test` |
| F2 | Daily free reading | §9.3 | S05 → S06 → S07 Begin → hold → S08 → S09 | E09, E10, E12, E08 | `first_launch_free_reading_test`, `daily_reset_resume_test` |
| F3 | Out of readings → rewarded ad or purchase | §9.4 | S07 → S10 → S12 or S11 → back to S07 (Begin enabled, no auto-start, RC58) | E09, E15, E16, E17, E14 | `out_of_credits_purchase_test`, `rewarded_ad_test` |
| F4 | Restore purchases | §9.5 | S20 or S11 → restore; "Move readings from another device" → `transferToken` | E14 (transfer path only) | `remove_ads_restore_test` |
| F5 | Export / import | §9.6 | S20 → S24; S20 → S25 | none | `export_import_test` |
| F6 | Generation failure and retry | §9.7 | S08 `awaitingReading` → poll → `generationFailed` → Try again (same `clientReadingId`) | E10, E11 | `reading_failure_refund_test` |
| F7 | AI consent declined, then reading | §9.8 | S07 `needsAiConsent` → S04 re-entry → Allow (gate re-run) or Not now → F8 offer | none until consent | `classic_reading_test` |
| F8 | Classic reading | §9.9 | S07 (`needsAiConsent` / `aiUnavailableRegion` / `readingsPaused`) → S08 (no commit) → S32, saved `status: classic` | none | `classic_reading_test` |

## 12. Secure-storage keys

Owner: 02 §6.2 (`taro_data/src/secure/keys.dart`, over `flutter_secure_storage`). iOS accessibility `first_unlock_this_device`; Android Keystore-backed, excluded from backup. Never exported, logged or sent to analytics.

| Key | Content |
|---|---|
| `taro.install_id` | install UUID v4 |
| `taro.install_secret` | 32 random bytes, base64url; sent only in E04 (RC54) |
| `taro.session_token` | Worker `installToken` (EdDSA JWT, 7 days) + `expiresAt` |
| `taro.purchase_binding` | `purchaseBinding{appleAccountToken?, playAccountId?}` (RC9, RC85) |
| `taro.attest_key_id` | App Attest key ID (iOS only) |

## 13. Worker secrets and vars

Owner: 03 §11 (secrets set with `wrangler secret put --env <env>`; owner copy in the GPG bundle `.secrets/`), BE20 / RC86 for test-only vars. There is no admin secret (RC84).

| Name | Kind | Envs | Purpose |
|---|---|---|---|
| `ANTHROPIC_API_KEY` | secret | staging, prod (dev optional) | Claude API |
| `TOKEN_SIGNING_KEYS` | secret | all | JWKS, Ed25519 keys (current + previous `kid`) |
| `CHALLENGE_KEY` | secret | all | HMAC for stateless challenges |
| `IDEMPOTENCY_ENC_KEY` | secret | all | AES-256-GCM replay bodies |
| `IP_HASH_KEY` | secret | all | HMAC for IP-prefix limiter keys |
| `PLAY_ACCOUNT_KEY` | secret | all | HMAC for `obfuscatedAccountId` |
| `DEVICE_KEY_SECRET` | secret | all | HMAC for `device_key_hash` |
| `TRANSFER_TOKEN_KEY` | secret | all | HMAC for `transferToken` |
| `REPORT_ENC_KEY` | secret | all | AES-256-GCM for `reading_reports.payload_enc` |
| `APPLE_DEVICECHECK_KEY_ID`, `APPLE_DEVICECHECK_PRIVATE_KEY` | secret | staging, prod | DeviceCheck API |
| `APPLE_ACCOUNT_NS` | secret | all | UUID namespace for `appAccountToken` |
| `APPLE_TEAM_ID` | var (kept with secrets) | all | App Attest `rpId` |
| `APPLE_ASC_ISSUER_ID`, `APPLE_ASC_KEY_ID`, `APPLE_ASC_PRIVATE_KEY` | secret | staging, prod | App Store Server API |
| `GOOGLE_SERVICE_ACCOUNT_JSON` | secret | staging, prod | Play Developer API + Play Integrity decode |
| `GOOGLE_PUBSUB_AUDIENCE`, `GOOGLE_PUBSUB_SA` | secret | staging, prod | RTDN push auth |
| `ALERT_WEBHOOK_URL` | secret | staging, prod | alert sink |
| `DEBUG_ATTESTATION_TOKEN` | secret | **dev, staging only** | honoured only with `ALLOW_DEBUG_ATTESTATION` |
| `ENVIRONMENT` | `[vars]` | all | `dev \| staging \| prod` |
| `ALLOW_DEBUG_ATTESTATION` | `[env.dev]` / `[env.staging]` var | **dev, staging only** | debug attestation (`"true"`) |
| `AI_PROVIDER` | `[env.dev]` / `[env.staging]` var | **dev, staging only** | `fake` (dev) / `anthropic` |

`makeProdDeps(env)` throws and `tools/check_worker_env.py` fails if `ALLOW_DEBUG_ATTESTATION`, `AI_PROVIDER` or `DEBUG_ATTESTATION_TOKEN` is set for prod. CI secrets (06 §8, 03 §14.2): `CLOUDFLARE_API_TOKEN`, `CLOUDFLARE_ACCOUNT_ID`, GPG bundle `.secrets/secrets.json.gpg` + `SECRETS_PASSPHRASE`. Signing material lives in `~/pet/secure/taro/`.

## 14. Packages

### 14.1 Monorepo packages

Owner: 02 §2, AR1 (RC15, RC77). Pub workspace + melos 8. This is the only package list.

| Package | Path | Flutter? | May depend on (taro) |
|---|---|---|---|
| `taro` (app) | `apps/taro` | yes | all (`taro_testing` as dev_dependency only) |
| `taro_core` | `packages/taro_core` | no (pure Dart) | — |
| `taro_content` | `packages/taro_content` | yes (assets) | `taro_core` |
| `taro_data` | `packages/taro_data` | yes | `taro_core` |
| `taro_services` | `packages/taro_services` | yes | `taro_core`, `taro_attestation` |
| `taro_attestation` | `packages/taro_attestation` | yes (plugin, Swift + Kotlin) | — |
| `taro_l10n` | `packages/taro_l10n` | yes | — |
| `taro_ui` | `packages/taro_ui` | yes | `taro_l10n` |
| `taro_testing` | `packages/taro_testing` | yes, dev-only, Riverpod-free | `taro_core`, `taro_ui`, `taro_l10n` |
| `taro-api` (Worker) | `worker/` | — (TypeScript, Hono) | — |
| `dart_tools` | `tools/dart_tools` | no | — (06 Testing strategy) |

Coverage units (06 QA1): each package above, `apps/taro`, `worker`, `tools`, `taro_attestation_ios`, `taro_attestation_android` (RC40). App feature folders (`apps/taro/lib/features/`): `onboarding`, `consent`, `home`, `daily_card`, `reading`, `paywall`, `journal`, `learn`, `settings`, `backup`, `help`, `legal`, `update`, `debug` (dev menu, non-prod flavors only).

Content and generator paths (RC25, RC26, RC39): `packages/taro_content/source/{locale}/cards/{cardId}.yaml`, `packages/taro_content/source/glossary.yaml`, `packages/taro_content/source/crisis/crisis_resources.yaml`; generator `tools/content` (`translate`, `validate`, `build`); parity check `tools/sync_deck`; tokens `docs/design/taro.tokens.json` → `tools/tokens/` → `packages/taro_ui/lib/src/tokens/generated/`; banned phrases `tools/store_copy/banned_phrases.yaml`; contract fixtures `worker/test/contract/fixtures/` → `packages/taro_data/test/contract/fixtures/` (`melos run contract:sync`).

### 14.2 Dart dependencies

Owner: 02 §18 (checked 2026-09-26; Flutter 3.44.x, `sdk: ^3.9.0`). `flutter_riverpod` ^3.4.3, `go_router` ^18.0.1, `freezed_annotation` ^3.1.0 / `freezed` ^4.0.2 (dev), `json_annotation` ^4.12.0 / `json_serializable` ^6.14.1 (dev), `build_runner` ^2.16.1 (dev), `meta` ^1.19.0, `collection` ^1.19.1, `clock` ^1.1.3, `crypto` ^3.0.6, `uuid` ^4.6.0, `drift` ^2.35.0 / `drift_dev` ^2.35.0 (dev) / `drift_flutter` ^0.3.1, `flutter_secure_storage` ^11.2.0, `dio` ^5.11.1, `logging` ^1.3.0, `intl` (pinned by `flutter_localizations`), `flutter_localizations` (sdk), `firebase_core` ^4.15.0, `firebase_analytics` ^12.6.0, `firebase_crashlytics` ^5.4.0, `google_mobile_ads` ^9.1.0, `app_tracking_transparency` ^2.0.7, `in_app_purchase` ^3.3.1, `in_app_purchase_storekit` ^0.4.13, `in_app_purchase_android` ^0.5.3, `flutter_local_notifications` ^22.3.1, `timezone` ^0.11.1, `flutter_timezone` ^5.1.0, `share_plus` ^13.3.0, `file_picker` ^13.1.0, `package_info_plus` ^10.2.1, `device_info_plus` ^13.2.0, `connectivity_plus` ^7.3.1, `in_app_review` ^2.0.12, `plugin_platform_interface` ^2.1.8, `flutter_native_splash` ^2.4.8 (dev), `very_good_analysis` ^11.0.0 (dev), `mocktail` ^1.0.5 (dev), `patrol` ^4.10.0 (dev), `integration_test` (sdk), `melos` ^8.9.0 (root dev). Not used: `sqlite3_flutter_libs` (EOL), `mockito`, `golden_toolkit`, `fpdart`, `riverpod_generator`, `home_widget` (v1, RC89); no other local database or golden package.

### 14.3 Worker dependencies

Owner: 03 §1. `hono`, `@hono/zod-openapi`, `zod`, `jose`, `@anthropic-ai/sdk`, `cbor-x`, `@peculiar/x509`; dev: `vitest`, `@cloudflare/vitest-pool-workers`, `@vitest/coverage-istanbul`, `fast-check`, `eslint`, `typescript`. Node 22 LTS (`worker/.nvmrc`); Python 3.12 for `tools/`.

## 15. Other canonical identifiers

| Item | Value | Owner |
|---|---|---|
| Bundle / applicationId | prod + `prodStaging` `com.vshyrochuk.taro`; staging `com.vshyrochuk.taro.stg`; dev `com.vshyrochuk.taro.dev` | 02 §15 (RC78) |
| Flavors / build configs | `dev`, `staging`, `prod`, `prodStaging` (config files `apps/taro/config/{dev,staging,prod,prod_staging}.json`) | 02 AR17 |
| Firebase projects | `taro-dev` (dev, staging, prodStaging), `taro-prod` | 02 AR17 (RC36) |
| Web host | `taro.vshyrochuk.com` (`/privacy`, `/terms`, `/support`, `/.well-known/*`) | 05 CS10 (RC92) |
| API hosts | `api.taro.vshyrochuk.com` (prod), `api-staging.taro.vshyrochuk.com` (staging) | 03 §2.1 (BE Q5) |
| Store name | "Taro: Tarot Card Reading"; on-device name "Taro" | 05 CS2 |
| Locales | `en, ar, de, es, fr, it, ja, ko, nl, pt, tr, uk` (fallback `en`; `pt` = pt-BR) | 01 §13 |
| Repo / CI | origin `git@github.com:Mc231/taro.git` (owner `Mc231`); CI on a self-hosted Gitea pull-mirror, workflows in `.gitea/workflows/` | 06 QA10 (owner 2026-09-27) |
| Tags | `app-vX.Y.Z+B`, `worker-vX.Y.Z` | 06 §10.1 |
| Banner allow-list | `kBannerAllowList = {home, journal_list, learn_library}` | 01 PR13 (RC18) |
| Banner analytics events | `ad_banner_impression`, `ad_banner_failed` (`screen_id` ∈ `kBannerAllowList`, `error_code?`) | 04 §14 (RC18) |
| Consent analytics events | `consent_ump_result` (`status` obtained\|not_required\|required_declined\|error, `form_shown`, `can_request_ads`), `consent_att_result` (`status` authorized\|denied\|restricted\|not_determined, `preprompt_shown`) | 04 §14 (owns the monetization/consent event list; 01 §15 mirrors) |
| Monetization event enums | `out_of_readings_viewed.source` = question_gate\|hold_402\|balance_chip\|hold_lost\|low_trust (RC74); `rewarded_grant_result.result` = granted\|delayed\|capped\|cooldown (RC57) | 04 §14 |
| Support ID | first 8 hex chars of `SHA-256(installId)` | 01 §7.10 (RC43) |
| Golden sizes | `kPhoneSmall` 375×667, `kPhoneLarge` 430×932, `kTabletIpad13` 1032×1376, `kTabletAndroid` 800×1280 | 06 §3 (RC24) |
| Tabs | Today (`/home`), Journal, Learn, Settings | 01 §8.1 (RC17) |

---

## Glossary-defined names (RC94)

Names that no spec spelled out and this glossary fixed; RC94 makes them canonical and the owning specs now point here. The cross-spec disagreements found while building the glossary (former U1–U20) were fixed in the specs on 2026-09-27 and are no longer listed.

| # | Spec | Section | What | Glossary uses |
|---|---|---|---|---|
| U21 | 01 | §11 step 2, §10.1 | Only `major_00` = "The Fool" is fixed; the other 77 English names and the Strength (08) / Justice (11) numbering are not stated in any spec. | Traditional RWS names and order (§1), pending `packages/taro_content/source/glossary.yaml`. |
| U22 | 02 | §3 | 02 delegates the per-`Failure` ARB keys to this file, and 03 §9.1 shows only one `messageKey` (`safetyDeclinedSelfHarm`). | Glossary-defined `failure*` and `safetyDeclined*` keys (§5, §5.2). |
| U23 | 01 | §15 | `screen_view.screen` is only described as "S-id enum"; the value format is not fixed. | Literal `S01` … `S33` (§10). |
