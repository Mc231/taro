# Phase 11: Client Data Layer & Worker Client

**Status:** ✅ Complete (2026-09-29)
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
- [x] Two drift databases (02 §6.1, RC75):
  - `lib/data/db/journal/journal_database.dart` → file `taro_journal.db`: `readings` (01 §10.4 fields: `note`, `favourite`, `rating`, `rating_reason`, `status` incl. `classic`, `content_json`, `content_locale`, `prompt_version`, `model_id`, `charge_source`, `local_date`, `reported`, `updated_at`), `reading_cards`, `daily_cards` (PK `local_date`, `drawn_at`, `created_at`, `updated_at`), `settings`, and `journal_fts(question, note)` (FTS5 per the Phase 2.2 spike, or the LIKE fallback, RC91);
  - `lib/data/db/device/device_database.dart` → file `taro_device.db`: `balance_cache` (with `ledger_version`), `remote_config_cache`, `entitlements`, `purchase_outbox`, `consent_state`, `sync_state`, `pending_acks`;
  - indexes per 02 §6.1. Evidence: `lib/data/db/journal/{journal.drift,journal_database.dart}` and `lib/data/db/device/{device.drift,device_database.dart}` (SQL schemas; `readings.failure_json`, `purchase_outbox.transaction_id/order_id`, the `reading_cards(card_id)` index and `journal_search_refs` added to 02 §6.1 and GLOSSARY §7); FTS5 trigram with the LIKE path for < 3-character tokens and the RC91 fallback documented in `journal.drift`; `test/data/db/journal_database_test.dart`, `device_database_test.dart`.
- [x] Backup exclusion of `taro_device.db`: iOS `NSURLIsExcludedFromBackupKey` on the DB file and its `-wal`/`-shm` siblings at creation (a small platform call in `apps/taro/lib/services/`, behind a `taro_core` port and tested with a fake, since `data/` never imports `services/`); Android `data_extraction_rules.xml` `<cloud-backup>` and `<device-transfer>` excludes plus `full_backup_content.xml` (Phase 2.2 file, updated here). Evidence: port `BackupExclusion` + `NoOpBackupExclusion` (`packages/taro_core/lib/src/ports/backup_exclusion.dart`), `FakeBackupExclusion` + `runBackupExclusionContract`; `lib/services/backup/platform_backup_exclusion.dart` + `BackupExclusionPlugin` in `ios/Runner/AppDelegate.swift` (iOS simulator build green); `DeviceDatabase.open` excludes the file and `-wal`/`-shm`/`-journal` on every open; Android XML updated; `test/data/db/{database_files_test,backup_rules_test}.dart`, `test/services/backup/platform_backup_exclusion_test.dart`.
- [x] DAOs: `ReadingsDao`, `DailyCardsDao`, `SettingsDao`, `CacheDao`, `EntitlementsDao`, `OutboxDao`, `PendingAcksDao`. Use `driftDatabase(name: …, native: DriftNativeOptions(shareAcrossIsolates: true))` per file. Evidence: `lib/data/db/journal/{readings,daily_cards,settings}_dao.dart`, `lib/data/db/device/{cache,entitlements,outbox,pending_acks}_dao.dart`; `DatabaseLocation.open` (`lib/data/db/database_location.dart`) opens `<documents>/<name>.db` with `shareAcrossIsolates: true` and WAL.
- [x] `drift_dev schema dump` per database → `db/schema/{journal,device}_schema_v1.json`, `schema generate` → test helpers, and a `SchemaVerifier` test for each. The migration-test pattern is documented for future versions. Evidence: `apps/taro/db/schema/{journal,device}/drift_schema_v1.json` (GLOSSARY §7 path), helpers in `test/data/db/migrations/{journal,device}/generated/`, `test/data/db/migrations/schema_test.dart`; pattern in `docs/TESTING.md` "drift databases and migrations".
- [x] Tests on `NativeDatabase.memory()`: CRUD, cascade delete, search, outbox prune after 30 days, and a **restore simulation** (journal DB present, device DB and secure storage empty → no cached balance, no outbox rows, consent unknown). Evidence: `test/data/db/journal_database_test.dart` (CRUD, cascade, CHECKs, search), `device_database_test.dart` (`prunes finished rows 30 days after they finished`), `database_files_test.dart` (`restore simulation: journal restored, device DB and secure storage empty (RC75)`).

---

## Sprint 11.2: Secure storage & install identity

**Tasks:**
- [x] `lib/data/secure/keys.dart`: `taro.install_id`, `taro.install_secret` (RC54), `taro.session_token`, `taro.attest_key_id`, `taro.purchase_binding` (RC9). `FlutterSecureStore` uses `first_unlock_this_device` on iOS (no iCloud sync) and encrypted prefs on Android (02 §6.2). Evidence: `lib/data/secure/{keys,flutter_secure_store,secure_session_token_store}.dart` (Android `resetOnError: false`, so a Keystore error is a `StorageFailure`, never a silent wipe; `SecureSessionTokenStore` is the `SessionTokenStore` the `AuthInterceptor` reads); `test/data/secure/{keys,flutter_secure_store,secure_session_token_store}_test.dart`.
- [x] `InstallRepositoryImpl`:
  - `getOrCreate()` writes `install_id` and a 32-byte `install_secret` (from `IdGenerator`/secure random) together **before** anything else. On a secure-storage exception it returns `StorageFailure` (bootstrap shows the fatal S01 `storageError`) and never generates a second ID (02 §6.2);
  - `ensureRegistered()` (challenge → device signal (`deviceKey` / DeviceCheck token) → attest, or proof-of-work for `type: none` → `POST /v1/installs` with a **fresh Idempotency-Key per attempt**, RC55) stores the token, trust and `purchaseBinding`. The `installSecret` is sent only here and is covered by the `Redactor`;
  - `updateTimezone()` → `PUT /v1/installs/me/timezone` (409 → keep the server boundary, 03 §3.5);
  - re-registration with the same `installId` on `keyInvalidated` (02 §6.4).
  Evidence: `lib/data/install/{install_repository_impl,install_secret,proof_of_work}.dart`. The registration outcome (instant, trust, zone) is the `sync_state` key `install_registration` in `taro_device.db` (not backed up), so an iOS reinstall keeps the Keychain ID and secret and re-registers. `refreshToken()` re-registers on `AttestationFailure(keyInvalidated)` or `SessionExpiredFailure`; `reRegister()` is public for other callers. `type: none` solves `SHA-256(challenge ‖ installId ‖ pow)` on an isolate; a `transient`/`quota` attest error falls back to `none` with `reason: error`. The `Redactor` does not exist yet (Phase 13 logging); the no-leak guarantee is tested with `CapturingLogger`.
- [x] `IdGenerator` prod adapter `SecureIdGenerator` (uuid v4; RC41). Evidence: `lib/services/ids/secure_id_generator.dart` (`CryptoRNG`; `services/` per `tools/import_rules.yaml`), `test/services/ids/secure_id_generator_test.dart`.
- [x] Tests: the `runSecureStoreContract` and `runInstallRepositoryContract` suites; reinstall simulation (the same install ID and secret persist; RC37 deletion keeps them); re-registration within 7 days uses a new idempotency key; the secret never appears in a log record or request other than `POST /v1/installs`. Evidence: `test/data/secure/flutter_secure_store_test.dart` (contract over the plugin's mock), `test/data/install/install_repository_impl_test.dart` (contract; `iOS reinstall: Keychain survives, …`, `Delete all data (RC37) keeps …`, `keyInvalidated re-registers with the same ID and secret`, `each attempt has a fresh Idempotency-Key (RC55)`, `a network retry of one attempt reuses its key`, `appears only in POST /v1/installs and never in a log`), `proof_of_work_test.dart`, `install_secret_test.dart`.

---

## Sprint 11.3: WorkerClient (dio) & interceptors

**Tasks:**
- [x] `lib/data/api/worker_client.dart`, `endpoints.dart` (the RC4 set). Timeouts per 02 §6.3, with the reading timeout at **60 s** (RC31). Evidence: `WorkerClient` (never throws, returns `Result`), `Endpoints` E02–E17, `ApiTimeouts`; `test/data/api/endpoints_and_clock_test.dart` (`the client route set is E02–E17`, `timeouts per 02 §6.3 (reading 60 s, RC31)`), `worker_client_test.dart`.
- [x] Interceptors in order (02 §6.3):
  - `HeadersInterceptor`: `X-Taro-Platform`, `-App-Version`, `-Locale`, `-Flavor` (non-prod only), `X-Request-Id` per attempt, and `Idempotency-Key` (per user action, reused on retry; for holds and readings it equals `clientReadingId`, RC42; for registration a fresh UUID per attempt, RC55);
  - `AuthInterceptor`: single-flight refresh on `401 TOKEN_EXPIRED` via `POST /v1/installs/token`; `UNAUTHENTICATED` → re-register;
  - `AttestationInterceptor`: `X-Taro-Attestation` `aa1.`/`pi1.`/`none` for the RC11 routes, over `SHA256(method‖path‖SHA256(body)‖Idempotency-Key)`;
  - `AiConsentInterceptor`: adds `X-Taro-AI-Consent` on `POST /v1/readings/holds` and `POST /v1/readings` (RC28);
  - `RetryInterceptor`: at most 3 attempts, exponential backoff with jitter, capped at 8 s; retries only GETs and `Idempotency-Key` requests on connection errors, 408, 429 (`Retry-After` ≤ 30 s) and 502/503/504; never on 4xx business errors;
  - `ErrorInterceptor`: `ApiErrorMapper`, UPPER_SNAKE codes → `Failure` subtypes (RC5); an unknown code → `ServerFailure`; 426 → `UpgradeRequiredFailure`.
  - Evidence: `lib/data/api/interceptors/{headers,auth,attestation,ai_consent,retry,error}_interceptor.dart`, added in this order by `WorkerClient`; the body is encoded once and those bytes are hashed and sent. `X-Taro-Flavor` added to GLOSSARY §4.1 / 03 §2.1. Tests: `test/data/api/interceptors_test.dart` (`sends the common headers; flavor only when set`, `concurrent TOKEN_EXPIRED responses share a single refresh`, `UNAUTHENTICATED → SessionExpired and the re-register hook`, `clientDataHash matches the Worker known answers`, `adds the granted version on holds and readings only`), `retry_interceptor_test.dart` (`backoff doubles and stops after 3 attempts`, `capped at 8 s`, `429 with Retry-After > 30 s fails with RateLimitedFailure`, `a POST without Idempotency-Key (ack) is never re-sent`), `api_error_mapper_test.dart` (`the table covers every known code`, `an unknown code keeps its wire code`, `426 is UpgradeRequired even without an envelope`).
- [x] `ServerClockOffset` updated from every `Date` header. Evidence: `lib/data/api/server_clock.dart` (`ServerClockTracker` holds the core `ServerClockOffset`, fed by `HeadersInterceptor` and every `BalanceDto.serverTime`); `endpoints_and_clock_test.dart` (`records samples and emits only changes`), `worker_client_test.dart` (`fetchBalance equals CreditBalance.fromDto and moves the server clock`).
- [x] DTOs (`json_serializable`) and mappers: `BalanceDto` → `CreditBalance` (RC6, incl. `canReadReason`, `purchasesAllowed`, `purchasesBlockedReason`, `free.paused`; the `ledgerVersion` rule of RC67); `HoldDto`; `ReadingResponseDto` → `ReadingContent` (RC30); declined → `ReadingStatus.refused(SafetyInfo{category, messageKey, canRephrase, crisisResources})` (02 §3, RC27); `410 READING_EXPIRED_REFUNDED` → `ReadingExpiredRefundedFailure`; `409 HOLD_CONFLICT` → `HoldConflictFailure` (RC96). Evidence: `lib/data/api/dto/{balance_dto,reading_dtos,install_dtos,store_dtos,error_envelope_dto}.dart` (+ committed `*.g.dart`), `lib/data/api/worker_models.dart` (`ReadingOutcome`); `test/data/api/dto_test.dart` (`maps every field and agrees with CreditBalance.fromDto`, `the RC67 order holds on mapped responses`, `the wire reading round-trips through the domain (RC30)`), `worker_client_test.dart` (`createReading maps declined to refused(SafetyInfo) (RC27)`, `409 HOLD_CONFLICT and 410 READING_EXPIRED_REFUNDED map to their failures`).
- [x] Tests with a scripted fake `HttpClientAdapter`: headers, retry matrix under `FakeClock`, 401 single-flight refresh, every error-code mapping, timeout → the polling hand-off. Evidence: `test/data/api/support/{scripted_http_adapter,worker_client_harness}.dart`; `worker_client_test.dart` (`a timed-out reading is handed to polling after one attempt`) plus the tests above.
- [x] **Contract tests** `test/contract/contract_fixtures_test.dart`: decode every fixture in `test/contract/fixtures/**` and encode requests that validate against the schema (QA15). `melos run contract:sync` + `check_contract_fixtures.py` are green. Evidence: one test per fixture (39), responses validated against `worker/openapi/openapi.json` via `test/contract/support/openapi_schema.dart`, request fixtures re-encoded byte-for-byte and strictly validated; a fixture without a decoder fails. 2026-09-29: `contract:sync` 0 copied / 0 removed, `check_contract_fixtures: OK` (39). **Pending:** reading-route fixtures (holds, readings, ack, report) follow in Phase 8; until then those calls are tested against scripted HTTP and `test/data/repositories/support/fake_worker_server.dart`. `VerifyPurchaseRequest.transferToken` is not yet in the Worker OpenAPI (pinned by a test).

---

## Sprint 11.4: Repositories

**Tasks:**
- [x] `BalanceRepositoryImpl`: `watch()` from the drift cache, `sync(reason)` → `GET /v1/balance` with coalesced concurrent calls. Only Worker responses change the balance (AR8, rule 5). Every response carrying a balance (sync, hold, reading, purchase, reward) goes through one `apply(balance)` that accepts `ledgerVersion ≥ cached` and replaces on `>` or on `=` with newer `serverTime` (RC67). **Race test:** a `GET /v1/balance` started before a reading but answered after it (same or lower version) never overwrites the post-reading cache with "free remaining 1". Evidence: `lib/data/repositories/balance_repository_impl.dart` (`apply` via `CacheDao.replaceBalanceIf` in one transaction; `watch` follows the drift row through `SerialValue`); `test/data/repositories/balance_repository_impl_test.dart` (group `RC67 race (Sprint 11.4)`, `a GET /v1/balance sent before a reading and answered after it …`, `syncs through WorkerClient.fetchBalance`, plus `runBalanceRepositoryContract`).
- [x] `RemoteConfigRepositoryImpl`: `GET /v1/config` with ETag and the drift cache. Offline → last cached, else `RemoteConfig.defaults` (02 §10). Evidence: `lib/data/repositories/remote_config_repository_impl.dart`; `test/data/repositories/remote_config_repository_impl_test.dart` (`the ETag of the fetched document goes out as If-None-Match`, `offline without a cache keeps the compiled defaults`, `concurrent refreshes share one request`, contract suite).
- [x] `ReadingRepositoryImpl`:
  - `hold(clientReadingId, spread, locale)` → `POST /v1/readings/holds` (RC50); `renewHold` when < 120 s remain;
  - `create(pending)` persists **before** the network call (PR6);
  - `POST /v1/readings` → complete, refused, or classic fallback signals; on `completed` it persists the text, then enqueues `pending_acks` and calls `POST /v1/readings/{clientReadingId}/ack` (retried by `SyncCoordinator`, RC51);
  - on timeout, polls `GET /v1/readings/{clientReadingId}` at 1, 2, 4 and 8 s within a 30 s budget (02 §6.3);
  - `409 HOLD_CONFLICT` / renewal 402 → **keeps** the pending draw face-down for reuse after purchase (RC48; 01 PR6, 04 §12.1); a resubmit uses the same `clientReadingId` and the Worker runs a new attempt (RC49);
  - `410 READING_EXPIRED_REFUNDED` → status `ReadingStatus.failed(ReadingExpiredRefundedFailure, refunded: true)` (S08 `deliveryExpired`) with "not charged" and retry with the same cards;
  - `resume(id)`, `JournalRepository.watchAll(query: JournalQuery)` with filters (type, spread, card, favourites, FTS search), `setFavourite`, `setNote`, `setRating`, `delete` + undo support (soft-delete for 5 s).
  - Evidence: `lib/data/repositories/reading_repository_impl.dart` (`hold`/`renewHold`, `submit` persisting `pending` first, polling via `ApiTimeouts.readingPollDelay`, `409`/`402` keep the draw `pending`, `410`/`503 AI_UNAVAILABLE` → `failed(…, refunded: true)`, delivered readings queued in `pending_acks` before `ack`, `flushPendingAcks` also sweeps delivered-but-unacked rows, `undoDelete` within `undoWindow` = 5 s), `lib/data/repositories/journal_repository_impl.dart` (`watchAll` with favourites/spread/daily filters plus `cardId`, FTS5 + card-name `search`, `snapshot`/`replaceAll` via `JournalBackupStore`); `test/data/repositories/{reading,journal}_repository_impl_test.dart` (`submit persists pending before the network call (PR6)`, `polls GET until the reading completes`, `gives up after the 30 s budget, leaving the draw pending`, `409 HOLD_CONFLICT keeps the draw pending; resubmit reuses the ID (RC48, RC49)`, `a renewal 402 keeps the stored draw face-down (RC48)`, `410 READING_EXPIRED_REFUNDED → failed(refunded) and applies the refund balance`, `undoDelete restores within 5 s, not after`, `search finds readings and daily cards by card name`). Reading-route contract fixtures follow in Phase 8; these calls are tested against `test/data/repositories/support/fake_worker_server.dart`.
- [x] `DailyCardRepositoryImpl`: one card per local day (device timezone; 01 §7.6), idempotent. Evidence: `lib/data/repositories/daily_card_repository_impl.dart`; `test/data/repositories/daily_card_repository_impl_test.dart` (`today is the device-local date, not the UTC date`, `concurrent draws keep one card for the day`, contract suite).
- [x] `SettingsRepositoryImpl` + `ConsentStore`: `UserSettings`, `ConsentState` (AI consent version + timestamp, onboarding step), analytics toggle. Evidence: `lib/data/repositories/settings_repository_impl.dart` (`taro_journal.db` `settings`, one row per backup key + device-only `reduceMotion`) and `consent_store_impl.dart` (`ConsentStoreImpl`, `taro_device.db` `consent_state`; separate class because the ports live in different databases, GLOSSARY §9.1); `test/data/repositories/{settings_repository_impl,consent_store_impl}_test.dart` (`settings survive a restart, reduceMotion included`, `a row cleared by "Delete all data" resets the state`, both contract suites).
- [x] `EntitlementCacheImpl` (drift `entitlements`; cleared only on a definitive store "not owned", MO7). `PurchaseOutboxImpl`: `enqueue` **before** verify, `pending()`, `markGranted`, `markFinished`, `recordAttempt`, `markRejected` (MO8, AR10). Evidence: `lib/data/repositories/{entitlement_cache,purchase_outbox}_impl.dart`; `test/data/repositories/entitlement_cache_impl_test.dart` (`a restart reads the row back as a cached value`), `purchase_outbox_impl_test.dart` (`an iOS row keeps the JWS; an Android row keeps the token`, `finished rows are pruned 30 days after they finish`, `database errors are storage failures, logged without data`), both contract suites. The MO7 "clear only on definitive not-owned" rule is the caller's (the cache stores what it is given).
- [x] `PurchaseVerifierImpl` → `POST /v1/purchases/verify` (maps `409 PURCHASE_ALREADY_CLAIMED` with `transferToken` for the "Move readings" support screen, RC84); `RewardGatewayImpl` → intents create, status and **cancel** (RC57); `ReportGatewayImpl` → report (RC22); `DataDeletionGatewayImpl` → `DELETE /v1/installs/me`, with a local queue for retry (01 S26 `partial`). Evidence: `lib/data/repositories/{purchase_verifier,reward_gateway,report_gateway,data_deletion_gateway}_impl.dart` (queue key `pending_erasure` in `sync_state`, GLOSSARY §7); `test/data/repositories/{purchase_verifier,reward_gateway,report_gateway,data_deletion_gateway}_impl_test.dart` (`409 PURCHASE_ALREADY_CLAIMED carries the transfer token (RC84)`, `a failed cancel is logged and swallowed`, `sends the stored reading with its cards (03 §9.7)`, `the queue lives in sync_state and survives a new gateway`), each also running its `runXContract` suite.
- [x] Each implementation passes its `runXContract` suite from `packages/taro_core/test/contracts/` (run from `apps/taro/test/data/`). Evidence (2026-09-29): `runInstallRepositoryContract`, `runSessionTokenStoreContract`, `runSecureStoreContract`, `runBalanceRepositoryContract`, `runRemoteConfigRepositoryContract`, `runSettingsRepositoryContract`, `runConsentStoreContract`, `runDailyCardRepositoryContract`, `runEntitlementCacheContract`, `runPurchaseOutboxContract`, `runReadingRepositoryContract`, `runJournalRepositoryContract`, `runPurchaseVerifierContract`, `runRewardGatewayContract`, `runReportGatewayContract`, `runDataDeletionGatewayContract` in `test/data/**`; `runBackupExclusionContract` and `runIdGeneratorContract` in `test/services/**`. All green.

---

## Sprint 11.5: Backup codec (01 §7.11, RC17)

**Tasks:**
- [x] `lib/data/backup/backup_codec.dart`: encodes `taro.backup` v1 from `taro_journal.db` (readings with status `complete`, `refused` or `classic`; daily cards; settings) inside the `data` wrapper, computes `checksum` = lowercase hex SHA-256 of the **RFC 8785 (JCS)** canonical JSON of `data`, and runs in an isolate. It **never** writes credits, entitlements, install ID, install secret, tokens, outbox, consent or config (01 §7.11, 06 §2.5, RC70). Evidence: `BackupCodec.encode/encodeJournal/decode` (`Isolate.run` by default; `runs in a real isolate by default`), `lib/data/backup/journal_backup_store.dart` (`exportData`), `lib/data/db/journal/journal_row_mapper.dart`; `test/data/backup/backup_codec_test.dart`.
- [x] `lib/data/backup/backup_schema_v1.json`: a byte-identical copy of `docs/specs/backup_schema_v1.json` (a test compares them). `BackupMigrator` (a stepwise chain; v1 only now, with the pattern tested using a synthetic v0). Golden fixture `test/fixtures/backup_v1_sample.json` with its known checksum. Evidence: `test/data/backup/backup_schema_test.dart` (`the app copy is byte-identical to docs/specs`, `is byte-identical to the taro_core fixture`, `its known checksum pins the JCS canonicalisation`), `lib/data/backup/backup_migrator.dart` + `test/data/backup/backup_migrator_test.dart` (`synthetic v0 migrates to the golden v1 file, checksum included`).
- [x] `ImportBackup` wiring: size → parse → format → version → migrate → validate (`backup_validator` from Phase 4) → checksum → preview → merge or replace in one drift transaction. Evidence: `BackupCodec.decode` (up to the preview), `JournalBackupStore.importBackup` (read → `BackupMerge` → diff write in one transaction); `test/data/backup/journal_backup_store_test.dart` (`a failure rolls the whole import back`).
- [x] Tests (`test/data/backup/backup_codec_test.dart`):
  - a round trip preserves every field;
  - a key scan proves forbidden keys are absent;
  - a tampered file with `credits` has no effect;
  - newer version → `unsupportedVersion`; checksum mismatch; > 20 MB; > 50,000 entries.

---

## Done when

- [x] `apps/taro` ≥ 90% with every `lib/data/` file ≥ 70% (`check_coverage.py`). Every contract suite is green. The Worker contract fixtures decode. Evidence (2026-09-29): `bash tools/ci/dart_coverage.sh apps/taro` + `check_coverage.py --unit apps/taro` PASS, 100.00 % (2669/2669 lines, 70 files; `SecureKeys.all` became a getter and `SecureIdGenerator` lost its never-executed const constructor to clear QA4/QA2); `melos run test` green (app 659, taro_core 1227).
- [x] `check_architecture.dart`: `apps/taro/lib/data/` imports only `taro_core` and its storage/HTTP dependencies — never `services/`, `features/`, `taro_ui` or Riverpod (02 §2.1). Evidence: `check_architecture: OK (479 file(s))`, `check_forbidden_apis: OK`.
- [x] Docs: `docs/ARCHITECTURE.md` (data layer, interceptor chain, outbox) and the `docs/TESTING.md` contract-fixture section. CHANGELOG updated. Evidence: `docs/ARCHITECTURE.md` "Data layer (`apps/taro/lib/data/`, Phase 11)" (incl. the provider-agnostic rule), `docs/TESTING.md` "Worker contract fixtures in the app (QA15, Phase 11)" (Phase 8 fixtures pending), `CHANGELOG.md` Phase 11.1–11.5 lines.
- [x] One commit: `feat(taro): Phase 11 — Client data layer & Worker client`.

## Next phase

Phase 12: Platform Services & Attestation Plugin.
