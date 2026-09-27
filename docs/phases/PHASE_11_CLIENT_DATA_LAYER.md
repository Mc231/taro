# Phase 11: Client Data Layer & Worker Client

**Status:** ⬜ Not Started
**Depends on:** Phase 4 (ports, models), Phase 6 (contract fixtures; Phases 7–8 fixtures are added as they land)
**Parallel with:** Phases 7, 8, 12

---

## Overview

This phase implements the app's data layer, `apps/taro/lib/data/` (Reconciled by 00_DECISIONS.md RC95: a folder of the app, not a package; paths below are relative to `apps/taro/`):
- the drift database;
- secure storage for the install identity;
- the dio-based `WorkerClient` with its interceptor chain (headers, auth refresh, attestation, retry, error mapping);
- every repository that talks to the Worker or local storage;
- the persistent purchase outbox;
- the backup codec and migrator.

Every adapter passes the shared port contract suite from `packages/taro_core/test/contracts/` (QA16), and the Dart side decodes the Worker's contract fixtures (QA15).

**Output of this phase:**
- `apps/taro/lib/data/` with `TaroDatabase` (schema v1 + schema dump), `FlutterSecureStore`, `WorkerClient`, and the repositories `InstallRepositoryImpl`, `BalanceRepositoryImpl`, `ReadingRepositoryImpl`, `DailyCardRepositoryImpl`, `RemoteConfigRepositoryImpl`, `SettingsRepositoryImpl`, `EntitlementCacheImpl`, `PurchaseOutboxImpl`, `PurchaseVerifierImpl`, `RewardGatewayImpl`, `ReportGatewayImpl`, `DataDeletionGatewayImpl`, plus `BackupCodec` and `BackupMigrator`.
- Contract tests green against `apps/taro/test/contract/fixtures/`.

---

## Specs referenced

`02_ARCHITECTURE.md` AR5–AR8, AR10, §6, §9.2 (sync steps), §9.5, §10, §12, §16. `03_BACKEND_WORKER.md` §2.1–§2.3, §3, §5.1, §6, §7, §9.1, cross-spec contract (02). `04_MONETIZATION.md` MO1, MO8, §5.3 (`ledgerVersion`), §6.2 (outbox), §6.5. `01_PRODUCT.md` PR6, PR14, §7.11, §10.4. `06_QUALITY_TESTING_CI.md` QA15, QA16, §2.5 (export/import). `00_DECISIONS.md` RC4–RC6, RC14, RC17, RC28, RC30, RC31, RC37, RC42, RC48, RC49–RC51, RC53–RC55, RC67, RC70, RC75, RC95.

---

## Sprint 11.1: drift database (AR7, RC14, RC17)

**Tasks:**
- [ ] Two drift databases (02 §6.1, RC75):
  - `lib/data/db/journal/journal_database.dart` → file `taro_journal.db`: `readings` (01 §10.4 fields: `note`, `favourite`, `rating`, `rating_reason`, `status` incl. `classic`, `content_json`, `content_locale`, `prompt_version`, `model_id`, `charge_source`, `local_date`, `reported`, `updated_at`), `reading_cards`, `daily_cards` (PK `local_date`, `drawn_at`, `created_at`, `updated_at`), `settings`, and `journal_fts(question, note)` (FTS5 per the Phase 2.2 spike, or the LIKE fallback, RC91);
  - `lib/data/db/device/device_database.dart` → file `taro_device.db`: `balance_cache` (with `ledger_version`), `remote_config_cache`, `entitlements`, `purchase_outbox`, `consent_state`, `sync_state`, `pending_acks`;
  - indexes per 02 §6.1.
- [ ] Backup exclusion of `taro_device.db`: iOS `NSURLIsExcludedFromBackupKey` on the DB file and its `-wal`/`-shm` siblings at creation (a small platform call in `apps/taro/lib/services/`, behind a `taro_core` port and tested with a fake, since `data/` never imports `services/`); Android `data_extraction_rules.xml` `<cloud-backup>` and `<device-transfer>` excludes plus `full_backup_content.xml` (Phase 2.2 file, updated here).
- [ ] DAOs: `ReadingsDao`, `DailyCardsDao`, `SettingsDao`, `CacheDao`, `EntitlementsDao`, `OutboxDao`, `PendingAcksDao`. Use `driftDatabase(name: …, native: DriftNativeOptions(shareAcrossIsolates: true))` per file.
- [ ] `drift_dev schema dump` per database → `db/schema/{journal,device}_schema_v1.json`, `schema generate` → test helpers, and a `SchemaVerifier` test for each. The migration-test pattern is documented for future versions.
- [ ] Tests on `NativeDatabase.memory()`: CRUD, cascade delete, search, outbox prune after 30 days, and a **restore simulation** (journal DB present, device DB and secure storage empty → no cached balance, no outbox rows, consent unknown).

---

## Sprint 11.2: Secure storage & install identity

**Tasks:**
- [ ] `lib/data/secure/keys.dart`: `taro.install_id`, `taro.install_secret` (RC54), `taro.session_token`, `taro.attest_key_id`, `taro.purchase_binding` (RC9). `FlutterSecureStore` uses `first_unlock_this_device` on iOS (no iCloud sync) and encrypted prefs on Android (02 §6.2).
- [ ] `InstallRepositoryImpl`:
  - `getOrCreate()` writes `install_id` and a 32-byte `install_secret` (from `IdGenerator`/secure random) together **before** anything else. On a secure-storage exception it returns `StorageFailure` (bootstrap shows the fatal S01 `storageError`) and never generates a second ID (02 §6.2);
  - `ensureRegistered()` (challenge → device signal (`deviceKey` / DeviceCheck token) → attest, or proof-of-work for `type: none` → `POST /v1/installs` with a **fresh Idempotency-Key per attempt**, RC55) stores the token, trust and `purchaseBinding`. The `installSecret` is sent only here and is covered by the `Redactor`;
  - `updateTimezone()` → `PUT /v1/installs/me/timezone` (409 → keep the server boundary, 03 §3.5);
  - re-registration with the same `installId` on `keyInvalidated` (02 §6.4).
- [ ] `IdGenerator` prod adapter `SecureIdGenerator` (uuid v4; RC41).
- [ ] Tests: the `runSecureStoreContract` and `runInstallRepositoryContract` suites; reinstall simulation (the same install ID and secret persist; RC37 deletion keeps them); re-registration within 7 days uses a new idempotency key; the secret never appears in a log record or request other than `POST /v1/installs`.

---

## Sprint 11.3: WorkerClient (dio) & interceptors

**Tasks:**
- [ ] `lib/data/api/worker_client.dart`, `endpoints.dart` (the RC4 set). Timeouts per 02 §6.3, with the reading timeout at **60 s** (RC31).
- [ ] Interceptors in order (02 §6.3):
  - `HeadersInterceptor`: `X-Taro-Platform`, `-App-Version`, `-Locale`, `-Flavor` (non-prod only), `X-Request-Id` per attempt, and `Idempotency-Key` (per user action, reused on retry; for holds and readings it equals `clientReadingId`, RC42; for registration a fresh UUID per attempt, RC55);
  - `AuthInterceptor`: single-flight refresh on `401 TOKEN_EXPIRED` via `POST /v1/installs/token`; `UNAUTHENTICATED` → re-register;
  - `AttestationInterceptor`: `X-Taro-Attestation` `aa1.`/`pi1.`/`none` for the RC11 routes, over `SHA256(method‖path‖SHA256(body)‖Idempotency-Key)`;
  - `AiConsentInterceptor`: adds `X-Taro-AI-Consent` on `POST /v1/readings/holds` and `POST /v1/readings` (RC28);
  - `RetryInterceptor`: at most 3 attempts, exponential backoff with jitter, capped at 8 s; retries only GETs and `Idempotency-Key` requests on connection errors, 408, 429 (`Retry-After` ≤ 30 s) and 502/503/504; never on 4xx business errors;
  - `ErrorInterceptor`: `ApiErrorMapper`, UPPER_SNAKE codes → `Failure` subtypes (RC5); an unknown code → `ServerFailure`; 426 → `UpgradeRequiredFailure`.
- [ ] `ServerClockOffset` updated from every `Date` header.
- [ ] DTOs (`json_serializable`) and mappers: `BalanceDto` → `CreditBalance` (RC6, incl. `canReadReason`, `purchasesAllowed`, `purchasesBlockedReason`, `free.paused`; the `ledgerVersion` rule of RC67); `HoldDto`; `ReadingResponseDto` → `ReadingContent` (RC30); declined → `ReadingStatus.refused(SafetyInfo{category, messageKey, canRephrase, crisisResources})` (02 §3, RC27); `410 READING_EXPIRED_REFUNDED` → `DeliveryExpiredFailure`; `409 HOLD_CONFLICT` → `HoldLostFailure`.
- [ ] Tests with a scripted fake `HttpClientAdapter`: headers, retry matrix under `FakeClock`, 401 single-flight refresh, every error-code mapping, timeout → the polling hand-off.
- [ ] **Contract tests** `test/contract/contract_fixtures_test.dart`: decode every fixture in `test/contract/fixtures/**` and encode requests that validate against the schema (QA15). `melos run contract:sync` + `check_contract_fixtures.py` are green.

---

## Sprint 11.4: Repositories

**Tasks:**
- [ ] `BalanceRepositoryImpl`: `watch()` from the drift cache, `sync(reason)` → `GET /v1/balance` with coalesced concurrent calls. Only Worker responses change the balance (AR8, rule 5). Every response carrying a balance (sync, hold, reading, purchase, reward) goes through one `apply(balance)` that accepts `ledgerVersion ≥ cached` and replaces on `>` or on `=` with newer `serverTime` (RC67). **Race test:** a `GET /v1/balance` started before a reading but answered after it (same or lower version) never overwrites the post-reading cache with "free remaining 1".
- [ ] `RemoteConfigRepositoryImpl`: `GET /v1/config` with ETag and the drift cache. Offline → last cached, else `RemoteConfig.defaults` (02 §10).
- [ ] `ReadingRepositoryImpl`:
  - `hold(clientReadingId, spread, locale)` → `POST /v1/readings/holds` (RC50); `renewHold` when < 120 s remain;
  - `create(pending)` persists **before** the network call (PR6);
  - `POST /v1/readings` → complete, refused, or classic fallback signals; on `completed` it persists the text, then enqueues `pending_acks` and calls `POST /v1/readings/{clientReadingId}/ack` (retried by `SyncCoordinator`, RC51);
  - on timeout, polls `GET /v1/readings/{clientReadingId}` at 1, 2, 4 and 8 s within a 30 s budget (02 §6.3);
  - `409 HOLD_CONFLICT` / renewal 402 → **keeps** the pending draw face-down for reuse after purchase (RC48; 01 PR6, 04 §12.1); a resubmit uses the same `clientReadingId` and the Worker runs a new attempt (RC49);
  - `410 READING_EXPIRED_REFUNDED` → status `failed(deliveryExpired)` with "not charged" and retry with the same cards;
  - `resume(id)`, `watchHistory(ReadingQuery)` with filters (type, spread, card, favourites, FTS search), `setFavourite`, `setNote`, `setRating`, `delete` + undo support (soft-delete for 5 s).
- [ ] `DailyCardRepositoryImpl`: one card per local day (device timezone; 01 §7.6), idempotent.
- [ ] `SettingsRepositoryImpl` + `ConsentStore`: `UserSettings`, `ConsentState` (AI consent version + timestamp, onboarding step), analytics toggle.
- [ ] `EntitlementCacheImpl` (drift `entitlements`; cleared only on a definitive store "not owned", MO7). `PurchaseOutboxImpl`: `enqueue` **before** verify, `pending()`, `markGranted`, `markFinished`, `recordAttempt`, `markRejected` (MO8, AR10).
- [ ] `PurchaseVerifierImpl` → `POST /v1/purchases/verify` (maps `409 PURCHASE_ALREADY_CLAIMED` with `transferToken` for the "Move readings" support screen, RC84); `RewardGatewayImpl` → intents create, status and **cancel** (RC57); `ReportGatewayImpl` → report (RC22); `DataDeletionGatewayImpl` → `DELETE /v1/installs/me`, with a local queue for retry (01 S26 `partial`).
- [ ] Each implementation passes its `runXContract` suite from `packages/taro_core/test/contracts/` (run from `apps/taro/test/data/`).

---

## Sprint 11.5: Backup codec (01 §7.11, RC17)

**Tasks:**
- [ ] `lib/data/backup/backup_codec.dart`: encodes `taro.backup` v1 from `taro_journal.db` (readings with status `complete`, `refused` or `classic`; daily cards; settings) inside the `data` wrapper, computes `checksum` = lowercase hex SHA-256 of the **RFC 8785 (JCS)** canonical JSON of `data`, and runs in an isolate. It **never** writes credits, entitlements, install ID, install secret, tokens, outbox, consent or config (01 §7.11, 06 §2.5, RC70).
- [ ] `lib/data/backup/backup_schema_v1.json`: a byte-identical copy of `docs/specs/backup_schema_v1.json` (a test compares them). `BackupMigrator` (a stepwise chain; v1 only now, with the pattern tested using a synthetic v0). Golden fixture `test/fixtures/backup_v1_sample.json` with its known checksum.
- [ ] `ImportBackupUseCase` wiring: size → parse → format → version → migrate → validate (`backup_validator` from Phase 4) → checksum → preview → merge or replace in one drift transaction.
- [ ] Tests:
  - a round trip preserves every field;
  - a key scan proves forbidden keys are absent;
  - a tampered file with `credits` has no effect;
  - newer version → `unsupportedVersion`; checksum mismatch; > 20 MB; > 50,000 entries.

---

## Done when

- [ ] `apps/taro` ≥ 90% with every `lib/data/` file ≥ 70% (`check_coverage.py`). Every contract suite is green. The Worker contract fixtures decode.
- [ ] `check_architecture.dart`: `apps/taro/lib/data/` imports only `taro_core` and its storage/HTTP dependencies — never `services/`, `features/`, `taro_ui` or Riverpod (02 §2.1).
- [ ] Docs: `docs/ARCHITECTURE.md` (data layer, interceptor chain, outbox) and the `docs/TESTING.md` contract-fixture section. CHANGELOG updated.
- [ ] One commit: `feat(taro): Phase 11 — Client data layer & Worker client`.

## Next phase

Phase 12: Platform Services & Attestation Plugin.
