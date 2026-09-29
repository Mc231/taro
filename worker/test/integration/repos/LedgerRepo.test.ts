import { describe, expect, it } from 'vitest';
import { LedgerRepo, readingRef, type LedgerEntryInput } from '../../../src/repos/LedgerRepo';
import { db, NOW, seedInstall } from '../../helpers/db';

const repo = new LedgerRepo(db);

function entry(installId: string, overrides: Partial<LedgerEntryInput> = {}): LedgerEntryInput {
  return {
    installId,
    bucket: 'paid',
    delta: 10,
    reason: 'purchase',
    refType: 'purchase',
    refId: `p-${installId}`,
    createdAt: NOW,
    ...overrides,
  };
}

describe('LedgerRepo', () => {
  it('derives balances as SUM(delta) per bucket (BE5)', async () => {
    const id = await seedInstall();
    expect(await repo.balances(id)).toEqual({ paid: 0, bonus: 0 });
    await repo.append(entry(id));
    await repo.append(
      entry(id, {
        bucket: 'bonus',
        delta: 2,
        reason: 'ad_reward',
        refType: 'ad_reward',
        refId: 'r1',
      }),
    );
    await repo.append(entry(id, { delta: -13, reason: 'refund_revoke', refId: 'p2' }));
    expect(await repo.balances(id)).toEqual({ paid: -3, bonus: 2 });
  });

  it('is idempotent per (reason, ref_type, ref_id, bucket)', async () => {
    const id = await seedInstall();
    expect(await repo.append(entry(id))).toBe(true);
    expect(await repo.append(entry(id, { delta: 99 }))).toBe(false);
    expect(await repo.append(entry(id, { bucket: 'bonus' }))).toBe(true);
    expect(await repo.balances(id)).toEqual({ paid: 10, bonus: 10 });
  });

  it('lists entries oldest first with the admin note', async () => {
    const id = await seedInstall();
    await repo.append(
      entry(id, { reason: 'admin_adjust', refType: 'admin', refId: 'a1', note: 'goodwill' }),
    );
    await repo.append(entry(id, { refId: 'p2' }));
    const entries = await repo.entries(id);
    expect(entries.map((e) => [e.reason, e.note])).toEqual([
      ['admin_adjust', 'goodwill'],
      ['purchase', null],
    ]);
    expect(entries[0]?.id).toBeLessThan(entries[1]?.id ?? 0);
    expect(await repo.entries(id, 1)).toHaveLength(1);
  });

  it('takes a guarded hold only while the bucket has at least one credit (03 §5.3)', async () => {
    const id = await seedInstall();
    await repo.append(
      entry(id, {
        bucket: 'bonus',
        delta: 1,
        reason: 'ad_reward',
        refType: 'ad_reward',
        refId: 'r',
      }),
    );
    const hold = (readingId: string, bucket: 'paid' | 'bonus' = 'bonus') =>
      repo.holdStmt({ installId: id, bucket, readingId, attempt: 1, now: NOW }).run();

    expect((await hold('reading-a')).meta.changes).toBe(1);
    expect((await hold('reading-b')).meta.changes).toBe(0);
    expect((await hold('reading-c', 'paid')).meta.changes).toBe(0);
    expect(await repo.balances(id)).toEqual({ paid: 0, bonus: 0 });
    const holds = (await repo.entries(id)).filter((e) => e.reason === 'reading_hold');
    expect(holds.map((e) => [e.refId, e.delta])).toEqual([[readingRef('reading-a', 1), -1]]);
  });

  it('never takes two holds for the same (reading, attempt)', async () => {
    const id = await seedInstall();
    await repo.append(entry(id));
    const stmt = () =>
      repo.holdStmt({ installId: id, bucket: 'paid', readingId: 'rd', attempt: 2, now: NOW });
    await db.batch([stmt(), stmt()]);
    expect(await repo.balances(id)).toEqual({ paid: 9, bonus: 0 });
  });

  it('formats reading refs as {readingId}#{attempt} (RC49)', () => {
    expect(readingRef('abc', 3)).toBe('abc#3');
  });
});
