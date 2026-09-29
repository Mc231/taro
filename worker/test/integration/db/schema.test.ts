import { describe, expect, it } from 'vitest';
import { LedgerRepo } from '../../../src/repos/LedgerRepo';
import { db, NOW, rejection, seedInstall } from '../../helpers/db';

// 03 §4 / GLOSSARY §6: migrations/0001_init.sql applied to an empty D1 by
// test/setup/apply_migrations.ts.
const TABLES = [
  'installs',
  'ledger',
  'daily_usage',
  'device_daily_usage',
  'purchases',
  'ad_rewards',
  'readings',
  'reading_reports',
  'idempotency_keys',
  'webhook_events',
  'used_challenges',
  'ai_spend_daily',
];

const INDEXES = [
  'ledger_install',
  'purchases_install',
  'purchases_token',
  'ad_rewards_install',
  'readings_created',
  'readings_open',
  'readings_unacked',
  'reading_reports_expires',
  'idem_expires',
];

async function names(type: 'table' | 'index' | 'trigger'): Promise<string[]> {
  const { results } = await db
    .prepare(
      `SELECT name FROM sqlite_master WHERE type = ?1 AND name NOT LIKE 'sqlite_%'
         AND name NOT LIKE '_cf_%' AND name NOT LIKE 'd1_%' ORDER BY name`,
    )
    .bind(type)
    .all<{ name: string }>();
  return results.map((r) => r.name);
}

async function columns(table: string): Promise<string[]> {
  const { results } = await db.prepare(`PRAGMA table_info(${table})`).all<{ name: string }>();
  return results.map((r) => r.name);
}

async function seedLedger(): Promise<string> {
  const installId = await seedInstall();
  await new LedgerRepo(db).append({
    installId,
    bucket: 'paid',
    delta: 3,
    reason: 'purchase',
    refType: 'purchase',
    refId: `p-${installId}`,
    createdAt: NOW,
  });
  return installId;
}

describe('0001_init.sql', () => {
  it('creates every 03 §4 table and no balances cache table (BE5)', async () => {
    expect(await names('table')).toEqual([...TABLES].sort());
  });

  it('creates every GLOSSARY §6 index', async () => {
    expect(await names('index')).toEqual(expect.arrayContaining(INDEXES));
  });

  it('adds purchases.is_test (RC7) and the reading_reports columns (RC22)', async () => {
    expect(await columns('purchases')).toContain('is_test');
    expect(await columns('reading_reports')).toEqual([
      'id',
      'install_id',
      'client_reading_id',
      'reading_id',
      'local_date',
      'reason',
      'locale',
      'prompt_version',
      'model',
      'payload_enc',
      'created_at',
      'expires_at',
    ]);
  });

  it('keeps the reading hold columns (RC49, RC50, RC52) and the idempotency scope (RC49)', async () => {
    expect(await columns('readings')).toEqual(
      expect.arrayContaining([
        'attempt',
        'hold_source',
        'hold_state',
        'hold_local_date',
        'hold_expires_at',
        'acked_at',
      ]),
    );
    expect(await columns('idempotency_keys')).toEqual(
      expect.arrayContaining(['install_id', 'route', 'key', 'request_hash']),
    );
    expect(await columns('installs')).toEqual(
      expect.arrayContaining([
        'state_version',
        'install_secret_hash',
        'device_key_hash',
        'device_reused',
      ]),
    );
  });
});

describe('ledger append-only triggers', () => {
  it('has the two triggers', async () => {
    expect(await names('trigger')).toEqual(['ledger_no_delete', 'ledger_no_update']);
  });

  it('rejects UPDATE', async () => {
    const installId = await seedLedger();
    const message = await rejection(
      db.prepare(`UPDATE ledger SET delta = 100 WHERE install_id = ?1`).bind(installId).run(),
    );
    expect(message).toContain('ledger is append-only');
    expect(await new LedgerRepo(db).balances(installId)).toEqual({ paid: 3, bonus: 0 });
  });

  it('rejects DELETE', async () => {
    const installId = await seedLedger();
    const message = await rejection(
      db.prepare(`DELETE FROM ledger WHERE install_id = ?1`).bind(installId).run(),
    );
    expect(message).toContain('ledger is append-only');
    expect(await new LedgerRepo(db).entries(installId)).toHaveLength(1);
  });

  it('rejects an UPDATE inside a batch and rolls the whole batch back', async () => {
    const installId = await seedLedger();
    const ledger = new LedgerRepo(db);
    const message = await rejection(
      db.batch([
        ledger.appendStmt({
          installId,
          bucket: 'bonus',
          delta: 1,
          reason: 'ad_reward',
          refType: 'ad_reward',
          refId: `r-${installId}`,
          createdAt: NOW,
        }),
        db.prepare(`UPDATE ledger SET note = 'x' WHERE install_id = ?1`).bind(installId),
      ]),
    );
    expect(message).toContain('ledger is append-only');
    expect(await ledger.balances(installId)).toEqual({ paid: 3, bonus: 0 });
  });
});

describe('constraints', () => {
  it('enforces foreign keys to installs', async () => {
    const message = await rejection(
      new LedgerRepo(db).append({
        installId: 'no-such-install',
        bucket: 'paid',
        delta: 1,
        reason: 'promo',
        refType: 'admin',
        refId: 'fk',
        createdAt: NOW,
      }),
    );
    expect(message).toMatch(/FOREIGN KEY/i);
  });

  it('rejects a zero ledger delta and unknown enum values', async () => {
    const installId = await seedInstall();
    const insert = (bucket: string, delta: number) =>
      db
        .prepare(
          `INSERT INTO ledger (install_id, bucket, delta, reason, ref_type, ref_id, created_at)
           VALUES (?1, ?2, ?3, 'promo', 'admin', ?4, ?5)`,
        )
        .bind(installId, bucket, delta, `${bucket}${String(delta)}`, NOW)
        .run();
    expect(await rejection(insert('paid', 0))).toMatch(/CHECK/i);
    expect(await rejection(insert('gold', 1))).toMatch(/CHECK/i);
  });

  it('keeps free_used within [0, free_limit] on daily_usage', async () => {
    const installId = await seedInstall();
    const insert = (limit: number, used: number) =>
      db
        .prepare(
          `INSERT INTO daily_usage (install_id, local_date, free_limit, free_used) VALUES (?1, ?2, ?3, ?4)`,
        )
        .bind(installId, `2026-01-0${String(used + 2)}`, limit, used)
        .run();
    expect(await rejection(insert(1, 2))).toMatch(/CHECK/i);
    expect(await rejection(insert(1, -1))).toMatch(/CHECK/i);
  });

  it('allows one purchase_token but many NULL tokens (partial unique index)', async () => {
    const installId = await seedInstall();
    const insert = (id: string, txn: string, token: string | null) =>
      db
        .prepare(
          `INSERT INTO purchases (id, install_id, platform, product_id, store_txn_id, purchase_token,
             credits, status, environment, account_token_match, purchased_at, granted_at)
           VALUES (?1, ?2, 'android', 'com.vshyrochuk.taro.readings_3', ?3, ?4, 3, 'granted',
             'production', 1, ?5, ?5)`,
        )
        .bind(id, installId, txn, token, NOW)
        .run();
    await insert(`${installId}-1`, `${installId}-t1`, null);
    await insert(`${installId}-2`, `${installId}-t2`, null);
    await insert(`${installId}-3`, `${installId}-t3`, `tok-${installId}`);
    expect(
      await rejection(insert(`${installId}-4`, `${installId}-t4`, `tok-${installId}`)),
    ).toMatch(/UNIQUE/i);
  });
});
