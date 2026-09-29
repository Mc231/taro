import { describe, expect, it } from 'vitest';
import { db, rejection } from '../../helpers/db';

/**
 * Phase 7.1 spike (03 §5.3 step 1): can a D1 `batch` make later statements
 * conditional on an earlier statement's `changes()`? These tests pin the
 * semantics the ledger relies on (docs/ARCHITECTURE.md §Ledger). They run on
 * workerd's D1 (SQLite), the same engine as production D1.
 */

async function freshTable(name: string): Promise<void> {
  await db.batch([
    db.prepare(`DROP TABLE IF EXISTS ${name}`),
    db.prepare(`CREATE TABLE ${name} (k TEXT PRIMARY KEY, n INTEGER NOT NULL CHECK (n >= 0))`),
  ]);
}

async function rows(name: string): Promise<Record<string, number>> {
  const { results } = await db
    .prepare(`SELECT k, n FROM ${name} ORDER BY k`)
    .all<{ k: string; n: number }>();
  return Object.fromEntries(results.map((r) => [r.k, r.n]));
}

describe('D1 batch: statements guarded by (SELECT changes()) (Phase 7.1 spike)', () => {
  it('a guarded statement sees the changes() of the previous statement in the same batch', async () => {
    await freshTable('spike_a');
    await db.prepare(`INSERT INTO spike_a (k, n) VALUES ('gate', 0)`).run();
    const applied = await db.batch([
      db.prepare(`UPDATE spike_a SET n = 1 WHERE k = 'gate' AND n = 0`),
      db.prepare(`INSERT INTO spike_a (k, n) SELECT 'follow', 1 WHERE (SELECT changes()) = 1`),
    ]);
    expect(applied.map((r) => r.meta.changes)).toEqual([1, 1]);
    // Second run: the gate CAS fails, so the follow-up is skipped.
    const skipped = await db.batch([
      db.prepare(`UPDATE spike_a SET n = 1 WHERE k = 'gate' AND n = 0`),
      db.prepare(`INSERT INTO spike_a (k, n) SELECT 'second', 1 WHERE (SELECT changes()) = 1`),
    ]);
    expect(skipped.map((r) => r.meta.changes)).toEqual([0, 0]);
    expect(await rows('spike_a')).toEqual({ follow: 1, gate: 1 });
  });

  it('chains: each guard reads its direct predecessor, and a SELECT in between does not reset it', async () => {
    await freshTable('spike_b');
    const chain = (gate: string) => [
      db
        .prepare(
          `INSERT INTO spike_b (k, n) SELECT ?1, 1 WHERE NOT EXISTS (SELECT 1 FROM spike_b WHERE k = ?1)`,
        )
        .bind(gate),
      db.prepare(`SELECT COUNT(*) AS c FROM spike_b`),
      db.prepare(
        `INSERT INTO spike_b (k, n) SELECT 'counter', 1 WHERE (SELECT changes()) = 1
         ON CONFLICT (k) DO UPDATE SET n = n + 1`,
      ),
      db.prepare(`UPDATE spike_b SET n = n + 10 WHERE k = 'tail' AND (SELECT changes()) = 1`),
      db.prepare(
        `INSERT OR IGNORE INTO spike_b (k, n) SELECT 'tail', 0 WHERE (SELECT changes()) = 1`,
      ),
    ];
    await db.batch(chain('g1'));
    // g1 applied: counter inserted (1), the tail UPDATE matched no row (0), so the
    // tail INSERT is skipped: a zero-change statement breaks the chain.
    expect(await rows('spike_b')).toEqual({ counter: 1, g1: 1 });
    await db.batch(chain('g1'));
    expect(await rows('spike_b')).toEqual({ counter: 1, g1: 1 });
    await db.batch(chain('g2'));
    // The upsert's DO UPDATE branch also reports changes() = 1.
    expect(await rows('spike_b')).toEqual({ counter: 2, g1: 1, g2: 1 });
  });

  it('an upsert whose DO UPDATE WHERE is false reports 0 changes; a multi-row UPDATE does not see its own count', async () => {
    await freshTable('spike_c');
    await db.batch([
      db.prepare(`INSERT INTO spike_c (k, n) VALUES ('a', 5), ('b', 5)`),
      db.prepare(
        `INSERT INTO spike_c (k, n) VALUES ('a', 0) ON CONFLICT (k) DO UPDATE SET n = n + 1 WHERE n < 5`,
      ),
      db.prepare(`UPDATE spike_c SET n = n + 100 WHERE (SELECT changes()) = 0`),
      db.prepare(`INSERT INTO spike_c (k, n) SELECT 'multi', 1 WHERE (SELECT changes()) = 2`),
    ]);
    expect(await rows('spike_c')).toEqual({ a: 105, b: 105, multi: 1 });
  });

  it('a failing statement rolls back the whole batch', async () => {
    await freshTable('spike_d');
    const message = await rejection(
      db.batch([
        db.prepare(`INSERT INTO spike_d (k, n) VALUES ('kept?', 1)`),
        db.prepare(`INSERT INTO spike_d (k, n) VALUES ('neg', -1)`),
      ]),
    );
    expect(message).toMatch(/CHECK constraint failed/);
    expect(await rows('spike_d')).toEqual({});
  });

  it('parallel batches are serialised: two CAS gates on one row, exactly one follow-up', async () => {
    await freshTable('spike_e');
    await db.prepare(`INSERT INTO spike_e (k, n) VALUES ('gate', 0)`).run();
    const race = (tag: string) =>
      db.batch([
        db.prepare(`UPDATE spike_e SET n = 1 WHERE k = 'gate' AND n = 0`),
        db
          .prepare(`INSERT INTO spike_e (k, n) SELECT ?1, 1 WHERE (SELECT changes()) = 1`)
          .bind(tag),
      ]);
    await Promise.all([race('w1'), race('w2'), race('w3'), race('w4')]);
    const result = await rows('spike_e');
    expect(Object.keys(result).filter((k) => k.startsWith('w'))).toHaveLength(1);
  });
});
