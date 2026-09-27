# Phase 7: Worker Credits, Purchases & Rewarded Ads

**Status:** ⬜ Not Started
**Depends on:** Phase 6
**Parallel with:** Phases 4, 5, 11, 12

---

## Overview

This phase implements the money paths on the Worker, which is the single source of truth for credits (MO1, BE5):
- the append-only ledger with atomic hold and refund;
- free-daily allowance consumption;
- purchase verification for the App Store and Google Play;
- store webhooks and the voided-purchases backstop;
- the refund policy with a negative paid balance;
- rewarded ads through AdMob SSV;
- the owner-run credit-transfer script used for support recovery (no admin route, RC84).

Every path is idempotent and property-tested for ledger invariants.

**Output of this phase:**
- `services/{BalanceService.hold/refund/commit, PurchaseService, RefundService, RewardService}`, `worker/src/monetization/catalog.ts` (`PRODUCT_CATALOG`), `src/admin/{ledgerAdjust,creditsTransfer}.ts`.
- Routes `POST /v1/purchases/verify`, `POST /v1/rewards/intents`, `GET /v1/rewards/intents/{intentId}`, `POST /v1/rewards/intents/{intentId}/cancel`, `GET /v1/ads/admob/ssv`, `POST /v1/webhooks/appstore`, `POST /v1/webhooks/googleplay`.
- Cron jobs: voided purchases, Google ack retry, reward expiry, sandbox-volume alert.
- `worker/test/fixtures/product_ids.json`, exported for the Dart test (04 §15).

---

## Specs referenced

`03_BACKEND_WORKER.md` BE5, BE6, BE8, BE14, §2.4 (abuse), §4, §5.3, §6, §7, §12, §15.2. `04_MONETIZATION.md` MO1, MO2, MO5, MO6, MO8, MO10, MO14–MO17, §4, §5, §7, §9, §12 (edge cases 12.1–12.25), §13, §14 (Worker metrics), §15 (Worker tests). `00_DECISIONS.md` RC3, RC4, RC6, RC7, RC9, RC10, RC33, RC35, RC43, RC49, RC52, RC53, RC56, RC57, RC63, RC66, RC67, RC84, RC85.

---

## Sprint 7.1: Ledger & consumption (BE5, BE6, MO5, MO6)

**Tasks:**
- [ ] Spike (first task): confirm how a D1 `batch` can make later statements conditional on an earlier statement's `changes()` (03 §5.3 step 1). Record the chosen pattern in `docs/ARCHITECTURE.md` §Ledger.
- [ ] `domain/ledgerRules.ts`, `domain/consumptionOrder.ts` (free → bonus → paid; free skipped while the free-stop tier is active or the device used today's allowance; `paidBlocked = paid < 0`; `purchasesAllowed = status != blocked && paid >= 0 && store.enabled`), `domain/allowance.ts` (snapshot `free_limit`, raised to `MAX(free_limit, current)` inside the upsert; low-trust caps; `device_reused`).
- [ ] `services/BalanceService.hold(install, reading)`: the 03 §5.3 algorithm without a cache table (conditional `INSERT … SELECT … WHERE SUM ≥ 1`), CAS on `readings.hold_state`, `hold_local_date`, `device_daily_usage` on Android, `state_version + 1`. Returns `{chargeSource}` or `402 INSUFFICIENT_CREDITS` with `details.freeResetsAt` and `details.reason`.
- [ ] `BalanceService.refund(reading, reason)`: CAS `held → refunded`; free → decrement the row of `hold_local_date` (never today) on both usage tables; bonus or paid → a `reading_refund` / `reading_undelivered` ledger entry with `ref_id = {readingId}#{attempt}`. `BalanceService.commit`: CAS `held → consumed`, re-hold if the cron refunded first (03 §5.3 step 4).
- [ ] Low-trust caps: KV counters `lt:ip:*` (with CGNAT ASN overrides) and the alert-only `lt:bucket:*` (03 §2.4, RC65).
- [ ] Property tests (fast-check, `test/unit/domain/ledger.property.test.ts`): for any interleaving of hold, refund, commit, grant, revoke, stale-hold cron and idempotency takeover, `SUM(bonus) ≥ 0`, `0 ≤ free_used ≤ free_limit` on both usage tables, **no double free refund**, at most one hold and one refund per `(reading, attempt)`, and `state_version` strictly increasing (03 §5.3, RC52, RC67).
- [ ] Integration: two parallel holds on the last credit → exactly one `402` (04 §15). 10 parallel holds on the same `clientReadingId` → one hold. A free hold at 23:59 local refunded at 00:01 decrements the previous day's row. `readings.freeDaily` raised mid-day → the second free hold succeeds. Android: a second install with the same device key gets no second free hold today (RC53).

---

## Sprint 7.2: Purchase verification (BE8, MO2, MO8)

**Tasks:**
- [ ] `src/monetization/catalog.ts`: `PRODUCT_CATALOG` for `readings_3`, `readings_10`, `readings_30` and `remove_ads` (RC3). `iap.retiredPacks` is supported. The public config builder injects `store.packs[].credits` from the catalog. Test: config and catalog agree. Export `test/fixtures/product_ids.json`.
- [ ] `adapters/apple/AppStoreServerApi.ts`:
  - ES256 JWT from the `APPLE_ASC_*` secrets;
  - `GET /inApps/v1/transactions/{id}` against production, then sandbox on `4040010` (05 §1 2.1, 03 §6.2);
  - JWS verification with x5c → pinned Apple Root CA G3 and cert OIDs.
- [ ] `adapters/google/PlayDeveloperApi.ts`: `purchases.products.get`, `:acknowledge`, `voidedpurchases.list`.
- [ ] `services/PurchaseService.verify({platform, …})` behind `POST /v1/purchases/verify` **[idem]**, a single route per RC4:
  - **iOS:** bundle ∈ `purchases.allowedBundleIds`, `Consumable`, product in the catalog, no `revocationDate`, env rules (sandbox accepted in prod, tagged `environment='sandbox'`), and the binding rule: `appAccountToken` mapped to a **different active install** → 409 `PURCHASE_ALREADY_CLAIMED` with `transferEligible` + `transferToken` (RC85); missing/unknown → first claim wins.
  - **Android:** `purchaseState` 0 → grant; 2 → `202 {status: pending}`; 1 → 422. Test purchases are tagged `is_test`. Binding mismatch logged, not blocking (RC9).
  - **Sandbox/test caps (RC63):** `purchases.sandboxMaxCreditsPerInstallPerDay` (30) and `purchases.sandboxGlobalCreditsPerDay` (1,000) → beyond either, 422 `PURCHASE_INVALID` `reason=sandbox_cap`; `sandbox_volume` alert at 50 % of the global cap.
  - **Grant:** one batch of `purchases` + ledger `purchase` + `state_version`. Same install → return the stored grant (`already_granted`). Another install → 409 `PURCHASE_ALREADY_CLAIMED` (+ `transferToken` when the caller re-submitted from the same store account). A **blocked or indebted** install is granted like any other; verify never returns 403 for a valid transaction (RC66), and such grants emit `blocked_purchase`.
  - **Google acknowledgement:** server-side after the grant (RC10). A failed acknowledgement is logged as `pendingAck` and retried by cron.
  - **Response:** `{status: granted|already_granted|pending|rejected, reason?, purchaseId, productId, creditsGranted, isFirstPurchase, balance}`.
- [ ] Tests: a test root CA + leaf chain (`test/helpers/apple_jws.ts`) with valid, bad-signature, wrong-root, wrong-bundle, unknown-product, revoked, sandbox-in-prod tagging, **sandbox cap per install and global → 422 `sandbox_cap`**, **prod config without sandbox caps rejected by the schema**, iOS token bound to another active install → 409 + `transferToken`, blocked install → granted. `FakePlayDeveloperApi` states 0, 1 and 2, consumed-and-known, test purchase capped, obfuscated-ID mismatch. 10 parallel verifies with the same transaction produce one ledger row (06 §7).

---

## Sprint 7.3: Webhooks, refunds, backstops (MO16, 03 §6.4–§6.5)

**Tasks:**
- [ ] `POST /v1/webhooks/appstore`: verify `signedPayload` and the inner JWS, dedupe on `notificationUUID` (`webhook_events`). Handle `REFUND` → revoke, `REFUND_REVERSED` → re-grant, `ONE_TIME_CHARGE` → grant when `appAccountToken` resolves (the crash safety net), `CONSUMPTION_REQUEST` → gated by `purchases.apple.sendConsumptionInfo` (default false, BE Q4), `TEST` → log. Respond 200 after verification and 400 only on a bad signature.
- [ ] `POST /v1/webhooks/googleplay`: Pub/Sub OIDC JWT verification (`GoogleOidcVerifier`, JWKS cached in `CACHE_KV`, audience and SA email), dedupe on `messageId`. Handle `voidedPurchaseNotification` → revoke, `ONE_TIME_PRODUCT_PURCHASED` → verify, grant and acknowledge, `testNotification` → log. Respond 204.
- [ ] `services/RefundService.revoke`: purchase `revoked`, ledger `refund_revoke` (paid may go negative), `refund_count++`, `state_version + 1`. At `abuse.refundBlockThreshold` (3) the install is `blocked`: purchases disabled (`purchasesAllowed = false`, `blocked`), free, bonus and positive paid credits keep working (03 §6.5, RC66).
- [ ] Crons: daily voided-purchases backstop (last 2 days), hourly Google ack retry. (No reconcile cron: there is no balance cache, BE5.)
- [ ] Tests: every notification type, duplicate delivery, negative balance → `paidBlocked` **and `purchasesAllowed = false` (`refundDebt`)** (04 §12.21), the refund-block threshold → `purchasesAllowed = false` (`blocked`) while free readings still work, and a purchase that still arrives for a blocked install is granted.

---

## Sprint 7.4: Rewarded ads via SSV (BE14, MO10, RC33, RC35)

**Tasks:**
- [ ] `POST /v1/rewards/intents` **[idem] [attest]** (03 §7.1, RC57):
  - checks `rewarded.enabled`, `adUnitId`, the cap (`granted_today + 1 ≤ dailyCap`, per install and per device key), the cooldown from the **last grant** (RC35), `device_reused` and the low-trust caps;
  - cancels any other open intent of the install (at most one open intent);
  - creates `ad_rewards` with `issued`, `amount` snapshot and `expires_at = now + rewarded.intentTtlSec`;
  - returns `{intentId, customData, userId, amount, expiresAt}` where `customData == userId == intentId` (RC56), so the raw install ID never goes to Google;
  - errors: 403 `REWARDED_DISABLED`, 409 `REWARDED_DAILY_CAP` (`reason: cap|cooldown`, `availableAt`).
- [ ] `POST /v1/rewards/intents/{intentId}/cancel` (auth): `issued → cancelled`, idempotent.
- [ ] `adapters/admob/AdmobKeyProvider.ts`: gstatic verifier keys, cached in KV for 24 h, refetched on an unknown `key_id`.
- [ ] `GET /v1/ads/admob/ssv` (path per RC4):
  - ECDSA-SHA256 verification over the query prefix; `ad_unit ∈ rewarded.allowedAdUnitIds`; dedupe on `transaction_id`;
  - intent lookup via `custom_data`, `user_id == custom_data`; **no cap or cooldown re-check**: any valid, unexpired, unused intent is granted (a `cancelled` one within a 2-minute grace too) (RC57);
  - grant in one batch using the snapshot amount (never `reward_amount`), incrementing `daily_usage` and `device_daily_usage`;
  - invalid signature → 403; any other rejection → 200 with no grant, logged as `ssv_rejected{reason}`.
- [ ] `GET /v1/rewards/intents/{intentId}` → `{status: issued|granted|cancelled|expired|rejected, amount, balance?}`.
- [ ] Cron: expire `ad_rewards` whose TTL has passed.
- [ ] Tests (generated P-256 keys and a fake key provider): valid, tampered query, unknown `key_id`, wrong ad unit, expired or used intent, **an intent issued under the cap is honoured after a cap reduction**, a cancelled intent inside/outside the grace window, duplicate `transaction_id`, three cancelled intents leave the install eligible, the cooldown measured from the last grant, and a second install on the same device key sharing the cap.

---

## Sprint 7.5: Support tooling & metrics (04 §12.9, RC43, RC84)

**Tasks:**
- [ ] `src/admin/creditsTransfer.ts`: a pure batch builder. Input `{ticketId, transferToken}`. It verifies the token (`TRANSFER_TOKEN_KEY`, TTL, single use), resolves the old and new installs from it, and moves `min(unspent paid of the old install, credits of the proven transactions)` with paired `admin_adjust` entries (`ref_id = ticketId`, idempotent per ticket). `worker/scripts/credits-transfer.ts` is the thin CLI that applies the batch via `wrangler d1 execute --remote` (or the D1 HTTP API) and logs ticket, install prefixes and amount. There is **no admin HTTP route and no admin bearer secret**.
- [ ] `src/admin/ledgerAdjust.ts` + `scripts/ledger-adjust.ts` (manual adjustments, `--block`, settle a refund debt), and `scripts/metrics.ts` (Analytics Engine SQL). All are covered by the gate (RC61): logic in `src/admin`, CLIs tested through `main([...])`.
- [ ] Metrics: `purchase_granted`, `purchase_revoked`, `reward_issued`, `reward_granted`, `reward_rejected`, `ssv_grant_lag_ms`, verify error rate, `sandbox_grant`, `blocked_purchase`. Alerts: verify error rate > 2% over 10 min, `ssv_rejected` spike, sandbox volume (03 §14.1, 04 §12.3, §14).
- [ ] `docs/runbooks/SUPPORT_CREDITS.md`: how to handle a "lost credits after reinstall" email, step by step: the user taps "Move readings from another device" on the new install, sends the transfer code, the owner runs the script (04 §12.9, 03 §6.6, BE-R3).
- [ ] Contract fixtures for every new route (`purchases.verify.*`, `rewards.intent.*`, `errors.*`), synced to Dart.

---

## Done when

- [ ] The Worker coverage thresholds pass (90/90/90/85), including `scripts/**` and `src/admin/**`. All integration flows in 03 §15.2 pass: register → balance → free reading hold → 402 → rewarded → SSV → bonus → purchase → paid → refund webhook → `paidBlocked` + `purchasesAllowed=false`. Readings are still simulated through `BalanceService` until Phase 8.
- [ ] `check_iap_ids.py` is green against `catalog.ts`.
- [ ] Deployed to staging. Webhook URLs registered in App Store Connect (sandbox) and the Play RTDN topic *(MANUAL, Phase 10 Sprints 10.3–10.4)*.
- [ ] Docs: `docs/ARCHITECTURE.md` (purchase and rewarded sequence diagrams), the support runbook and `worker/CHANGELOG.md`.
- [ ] One commit: `feat(worker): Phase 7 — Credits, purchases & rewarded ads`.

## Next phase

Phase 8: Worker AI Readings & Safety.
