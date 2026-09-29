-- 0001_init.sql: initial D1 schema (03 §4, canonical DDL, RC7).
--
-- Every 03 §4 table, index and trigger as amended by the review pass: no
-- `balances` table (balances are ledger SUMs, BE5), `device_daily_usage`
-- (RC53), reading hold columns (RC49, RC50, RC52), route-scoped idempotency
-- (RC49), `reading_reports` (RC22) and `purchases.is_test` (RC7, RC63).
-- Table and column names are GLOSSARY §6.
--
-- Forward-only: once applied to a remote database this file is frozen
-- (check_migrations.py, append-only); later changes are new NNNN_*.sql files
-- that stay compatible with the previous Worker version (expand → deploy →
-- contract).

PRAGMA foreign_keys = ON;

CREATE TABLE installs (
  id                 TEXT PRIMARY KEY,                -- client UUID v4
  platform           TEXT NOT NULL CHECK (platform IN ('ios','android')),
  status             TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active','blocked','deleted')),
  trust              TEXT NOT NULL CHECK (trust IN ('high','low')),
  token_generation   INTEGER NOT NULL DEFAULT 1,
  state_version      INTEGER NOT NULL DEFAULT 0,      -- bumped in every batch touching this install's
                                                      -- ledger, daily_usage, ad_rewards or reading holds;
                                                      -- returned as BalanceDto.ledgerVersion (RC67)
  install_secret_hash TEXT,                           -- SHA-256(installSecret), RC54
  device_key_hash    TEXT,                            -- HMAC(DEVICE_KEY_SECRET, deviceKey), Android, §3.7
  device_reused      INTEGER NOT NULL DEFAULT 0,      -- iOS DeviceCheck bit0 was already set, §3.7
  app_version        TEXT,
  locale             TEXT,
  timezone           TEXT,                            -- IANA
  tz_changed_at      TEXT,
  attest_key_id      TEXT,                            -- iOS App Attest key id
  attest_public_key  BLOB,                            -- SPKI
  attest_counter     INTEGER,
  attest_env         TEXT CHECK (attest_env IN ('production','development')),
  integrity_verdict  TEXT,                            -- compact: 'device|basic|none'
  apple_account_token TEXT UNIQUE,                    -- UUIDv5(APPLE_NS, id), StoreKit appAccountToken
  play_account_hash  TEXT UNIQUE,                     -- base64url(HMAC(PLAY_ACCOUNT_KEY,id))[0..43], obfuscatedAccountId
  refund_count       INTEGER NOT NULL DEFAULT 0,
  reregister_count_day TEXT,                          -- 'yyyy-mm-dd:n'
  created_at         TEXT NOT NULL,
  last_seen_at       TEXT NOT NULL
);

CREATE TABLE ledger (
  id          INTEGER PRIMARY KEY AUTOINCREMENT,
  install_id  TEXT NOT NULL REFERENCES installs(id),
  bucket      TEXT NOT NULL CHECK (bucket IN ('paid','bonus')),
  delta       INTEGER NOT NULL CHECK (delta <> 0),
  reason      TEXT NOT NULL CHECK (reason IN (
                'purchase','purchase_reversal_regrant','refund_revoke',
                'ad_reward','promo','admin_adjust',
                'reading_hold','reading_refund','reading_undelivered')),
  ref_type    TEXT NOT NULL,       -- 'purchase' | 'ad_reward' | 'reading' | 'admin'
  ref_id      TEXT NOT NULL,       -- readings: '{readings.id}#{attempt}' (RC49); purchases: purchaseId
  note        TEXT,                -- admin only, never user content
  created_at  TEXT NOT NULL,
  UNIQUE (reason, ref_type, ref_id, bucket)
);
CREATE INDEX ledger_install ON ledger(install_id, bucket, id);
CREATE TRIGGER ledger_no_update BEFORE UPDATE ON ledger BEGIN SELECT RAISE(ABORT,'ledger is append-only'); END;
CREATE TRIGGER ledger_no_delete BEFORE DELETE ON ledger BEGIN SELECT RAISE(ABORT,'ledger is append-only'); END;

CREATE TABLE daily_usage (
  install_id       TEXT NOT NULL REFERENCES installs(id),
  local_date       TEXT NOT NULL,            -- 'yyyy-mm-dd' in install tz
  free_limit       INTEGER NOT NULL,         -- snapshot of readings.freeDaily at first use that day
  free_used        INTEGER NOT NULL DEFAULT 0,
  rewarded_granted INTEGER NOT NULL DEFAULT 0,   -- count of grants (not credits)
  readings_total   INTEGER NOT NULL DEFAULT 0,
  declined_count   INTEGER NOT NULL DEFAULT 0,
  PRIMARY KEY (install_id, local_date),
  CHECK (free_used >= 0 AND free_used <= free_limit)
);

CREATE TABLE device_daily_usage (             -- §3.7; Android only (iOS uses DeviceCheck bits)
  device_key_hash  TEXT NOT NULL,
  local_date       TEXT NOT NULL,
  free_used        INTEGER NOT NULL DEFAULT 0 CHECK (free_used >= 0),
  rewarded_granted INTEGER NOT NULL DEFAULT 0,
  PRIMARY KEY (device_key_hash, local_date)
);

CREATE TABLE purchases (
  id               TEXT PRIMARY KEY,         -- UUIDv7
  install_id       TEXT NOT NULL REFERENCES installs(id),
  platform         TEXT NOT NULL CHECK (platform IN ('ios','android')),
  product_id       TEXT NOT NULL,            -- com.vshyrochuk.taro.readings_3 | _10 | _30 (PRODUCT_CATALOG, RC3)
  store_txn_id     TEXT NOT NULL,            -- Apple transactionId | Google orderId
  original_txn_id  TEXT,                     -- Apple originalTransactionId
  purchase_token   TEXT,                     -- Google only (needed for ack/voided mapping)
  credits          INTEGER NOT NULL CHECK (credits > 0),
  status           TEXT NOT NULL CHECK (status IN ('granted','revoked','reversal_regranted')),
  environment      TEXT NOT NULL CHECK (environment IN ('production','sandbox')),
  is_test          INTEGER NOT NULL DEFAULT 0,  -- 1 for Apple sandbox or Play license-tester purchases (RC7, RC63)
  account_token_match INTEGER NOT NULL,      -- 1 if appAccountToken/obfuscatedId matched this install
  purchased_at     TEXT NOT NULL,
  granted_at       TEXT NOT NULL,
  revoked_at       TEXT,
  UNIQUE (platform, store_txn_id)
);
CREATE INDEX purchases_install ON purchases(install_id);
CREATE UNIQUE INDEX purchases_token ON purchases(purchase_token) WHERE purchase_token IS NOT NULL;

CREATE TABLE ad_rewards (
  id               TEXT PRIMARY KEY,         -- intentId (opaque, 128-bit random, base64url)
  install_id       TEXT NOT NULL REFERENCES installs(id),
  local_date       TEXT NOT NULL,
  status           TEXT NOT NULL CHECK (status IN ('issued','granted','cancelled','expired','rejected')),
  amount           INTEGER NOT NULL,         -- snapshot of rewarded.amount at issue
  ad_unit          TEXT,
  admob_txn_id     TEXT UNIQUE,
  reject_reason    TEXT,
  issued_at        TEXT NOT NULL,
  expires_at       TEXT NOT NULL,
  granted_at       TEXT
);
CREATE INDEX ad_rewards_install ON ad_rewards(install_id, local_date);

CREATE TABLE readings (                      -- METADATA ONLY (BE13)
  id                TEXT PRIMARY KEY,        -- UUIDv7, server
  install_id        TEXT NOT NULL REFERENCES installs(id),
  client_reading_id TEXT NOT NULL,
  spread_id         TEXT NOT NULL,
  card_count        INTEGER NOT NULL,
  has_question      INTEGER NOT NULL,        -- 0/1, never the text
  locale            TEXT NOT NULL,
  local_date        TEXT NOT NULL,
  status            TEXT NOT NULL CHECK (status IN ('held','generating','completed','declined',
                      'failed','no_credit','expired_hold','expired_refunded')),   -- state machine §9.1
  attempt           INTEGER NOT NULL DEFAULT 1,   -- +1 on every re-hold of the same clientReadingId (RC49)
  hold_source       TEXT CHECK (hold_source IN ('free','bonus','paid')),   -- bucket of the current attempt
  hold_state        TEXT NOT NULL DEFAULT 'none'
                      CHECK (hold_state IN ('none','held','consumed','refunded')),   -- CAS target (RC52)
  hold_local_date   TEXT,                    -- local date the free hold was taken on; refunds use it
  hold_expires_at   TEXT,                    -- pre-draw hold TTL (§9.0)
  charge_source     TEXT NOT NULL CHECK (charge_source IN ('free','bonus','paid','none')),
  safety_category   TEXT,                    -- null | refusal category (§9.4)
  safety_layer      TEXT,                    -- 'L1' | 'L2' | 'L3' | 'model_refusal'
  prompt_version    TEXT,
  model             TEXT,
  input_tokens      INTEGER, cache_read_tokens INTEGER, cache_write_tokens INTEGER, output_tokens INTEGER,
  cost_micro_usd    INTEGER,
  latency_ms        INTEGER,
  error_code        TEXT,
  created_at        TEXT NOT NULL,
  completed_at      TEXT,
  acked_at          TEXT,                    -- delivery acknowledged by the client (RC51)
  UNIQUE (install_id, client_reading_id)
);
CREATE INDEX readings_created ON readings(created_at);
CREATE INDEX readings_open ON readings(status, hold_expires_at);          -- stale-hold cron
CREATE INDEX readings_unacked ON readings(status, acked_at, completed_at); -- undelivered cron

CREATE TABLE reading_reports (               -- user-initiated reports only (§9.7, RC22, CS7)
  id                TEXT PRIMARY KEY,        -- UUIDv7
  install_id        TEXT NOT NULL REFERENCES installs(id),
  client_reading_id TEXT NOT NULL,
  reading_id        TEXT REFERENCES readings(id),
  local_date        TEXT NOT NULL,           -- for the per-day report limit
  reason            TEXT NOT NULL CHECK (reason IN ('offensive','harmful_advice','sexual','hateful','other')),
  locale            TEXT NOT NULL,
  prompt_version    TEXT,
  model             TEXT,
  payload_enc       BLOB NOT NULL,           -- AES-256-GCM({question?, reading, note?}) with REPORT_ENC_KEY
  created_at        TEXT NOT NULL,
  expires_at        TEXT NOT NULL,           -- created_at + 90 days
  UNIQUE (install_id, client_reading_id)
);
CREATE INDEX reading_reports_expires ON reading_reports(expires_at);

CREATE TABLE idempotency_keys (
  install_id        TEXT NOT NULL,
  route             TEXT NOT NULL,              -- e.g. 'POST /v1/readings/holds'
  key               TEXT NOT NULL,
  request_hash      TEXT NOT NULL,
  state             TEXT NOT NULL CHECK (state IN ('in_progress','done')),
  response_status   INTEGER,
  response_body_enc BLOB,
  created_at        TEXT NOT NULL,
  expires_at        TEXT NOT NULL,
  PRIMARY KEY (install_id, route, key)
);
CREATE INDEX idem_expires ON idempotency_keys(expires_at);

CREATE TABLE webhook_events (               -- dedupe for ASSN v2 / RTDN / SSV
  id           TEXT PRIMARY KEY,            -- notificationUUID | Pub/Sub messageId | 'ssv:'||transaction_id
  source       TEXT NOT NULL CHECK (source IN ('apple','google','admob')),
  type         TEXT NOT NULL,
  status       TEXT NOT NULL CHECK (status IN ('processed','ignored','failed')),
  received_at  TEXT NOT NULL
);

CREATE TABLE used_challenges (nonce TEXT PRIMARY KEY, expires_at TEXT NOT NULL);

CREATE TABLE ai_spend_daily (
  date_utc        TEXT PRIMARY KEY,
  readings        INTEGER NOT NULL DEFAULT 0,
  cost_micro_usd  INTEGER NOT NULL DEFAULT 0
);
