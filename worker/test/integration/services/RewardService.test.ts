import { describe, expect, it } from 'vitest';
import { ApiError } from '../../../src/http/errors';
import { DailyUsageRepo } from '../../../src/repos/DailyUsageRepo';
import { InstallRepo } from '../../../src/repos/InstallRepo';
import { LedgerRepo } from '../../../src/repos/LedgerRepo';
import { RewardRepo } from '../../../src/repos/RewardRepo';
import { RewardService, type RewardIntentDto } from '../../../src/services/RewardService';
import { FakeAdmobKeyProvider } from '../../fakes/FakeAdmobKeyProvider';
import { SeqIdGenerator } from '../../fakes/SeqIdGenerator';
import { createHarness, uniqueId, type TestHarness } from '../../fakes/testDeps';
import { newSsvSigner, signedSsvPath, type SsvSigner } from '../../helpers/admobSsv';
import { db, seedInstall } from '../../helpers/db';

/**
 * `RewardService` races (03 §7, RC57): a D1 wrapper runs a hook right before
 * the Nth `batch`, so the state changes between the service's reads and its
 * compare-and-set, exactly as a concurrent request would change it.
 */

const AD_UNIT_ID = 'ca-app-pub-3940256099942544/1712485313';
const TODAY = '2026-09-26';

class UniqueIds extends SeqIdGenerator {
  override opaque(): string {
    return `svc${uniqueId('rs').replace(/-/g, '')}`;
  }
}

type Hook = () => Promise<void>;

/** `db` whose `batch` number `n` (1-based) first runs `hooks[n]`, or throws `failures[n]`. */
function hookedDb(hooks: Record<number, Hook>, failures: Record<number, Error> = {}): D1Database {
  let calls = 0;
  return {
    prepare: (sql: string) => db.prepare(sql),
    batch: async (statements: D1PreparedStatement[]) => {
      calls++;
      const failure = failures[calls];
      if (failure !== undefined) {
        throw failure;
      }
      await hooks[calls]?.();
      return db.batch(statements);
    },
  } as unknown as D1Database;
}

interface Ctx {
  readonly h: TestHarness;
  readonly service: RewardService;
  readonly signer: SsvSigner;
}

async function setup(hooks: Record<number, Hook> = {}, failures: Record<number, Error> = {}) {
  const keys = new FakeAdmobKeyProvider();
  const signer = await newSsvSigner(9);
  keys.set(9, signer.spki);
  const h = createHarness({
    overrides: { admobKeys: keys, ids: new UniqueIds(), db: hookedDb(hooks, failures) },
  });
  return { h, service: new RewardService(h.deps), signer } satisfies Ctx;
}

async function installRow(id: string) {
  const row = await new InstallRepo(db).findById(id);
  if (row === null) {
    throw new Error('no install');
  }
  return row;
}

async function issue(ctx: Ctx, installId: string): Promise<RewardIntentDto> {
  return ctx.service.createIntent({
    install: await installRow(installId),
    adUnitId: AD_UNIT_ID,
    trust: 'high',
    network: { ip: '10.9.9.9', asn: undefined },
  });
}

async function ssvQuery(ctx: Ctx, intentId: string, txn: string): Promise<string> {
  const path = await signedSsvPath(ctx.signer, {
    ad_unit: '1712485313',
    custom_data: intentId,
    transaction_id: txn,
    user_id: intentId,
  });
  return path.slice(path.indexOf('?') + 1);
}

async function codeOf(promise: Promise<unknown>): Promise<unknown> {
  try {
    await promise;
  } catch (err) {
    return err instanceof ApiError ? { code: err.code, ...err.options.details } : err;
  }
  return 'resolved';
}

describe('RewardService.createIntent races (RC57)', () => {
  it('reports the cap when a grant lands between the check and the issuing batch', async () => {
    const installId = await seedInstall({ timezone: 'UTC' });
    const usage = new DailyUsageRepo(db);
    const ctx = await setup({
      // Batch 1 is the eligibility read; batch 2 issues the intent.
      2: async () => {
        await usage.rewardedGrantStmt({ installId, localDate: TODAY }, 1).run();
      },
    });
    ctx.h.config.set({ 'rewarded.dailyCap': 1 });
    expect(await codeOf(issue(ctx, installId))).toEqual({
      code: 'REWARDED_DAILY_CAP',
      reason: 'cap',
      availableAt: '2026-09-27T00:00:00Z',
    });
  });

  it('still answers cap when the re-check no longer sees the conflicting state', async () => {
    const installId = await seedInstall({ timezone: 'UTC' });
    const usage = new DailyUsageRepo(db);
    const ctx = await setup({
      2: async () => {
        await usage.rewardedGrantStmt({ installId, localDate: TODAY }, 1).run();
      },
      3: async () => {
        await db.prepare(`DELETE FROM daily_usage WHERE install_id = ?1`).bind(installId).run();
      },
    });
    ctx.h.config.set({ 'rewarded.dailyCap': 1 });
    expect(await codeOf(issue(ctx, installId))).toMatchObject({
      code: 'REWARDED_DAILY_CAP',
      reason: 'cap',
    });
    expect(await new RewardRepo(db).lastGrantedAt(installId)).toBeNull();
  });
});

describe('RewardService.handleSsv races (03 §7.2)', () => {
  async function issuedIntent(): Promise<{ installId: string; intentId: string }> {
    const installId = await seedInstall({ timezone: 'UTC' });
    const plain = await setup();
    const intent = await issue(plain, installId);
    return { installId, intentId: intent.intentId };
  }

  it('treats a parallel delivery of the same transaction as a duplicate', async () => {
    const { installId, intentId } = await issuedIntent();
    const txn = uniqueId('txn');
    const ctx = await setup({
      1: async () => {
        await new RewardRepo(db)
          .grantGateStmt({
            id: intentId,
            admobTxnId: txn,
            adUnit: 'x',
            now: '2026-09-26T10:00:00.000Z',
          })
          .run();
      },
    });
    expect(await ctx.service.handleSsv(await ssvQuery(ctx, intentId, txn))).toEqual({
      kind: 'duplicate',
    });
    expect((await new LedgerRepo(db).balances(installId)).bonus).toBe(0);
  });

  it('rejects when the intent expires or disappears before the grant batch', async () => {
    const expiring = await issuedIntent();
    const ctx = await setup({
      1: async () => {
        await db
          .prepare(`UPDATE ad_rewards SET status = 'expired' WHERE id = ?1`)
          .bind(expiring.intentId)
          .run();
      },
    });
    expect(
      await ctx.service.handleSsv(await ssvQuery(ctx, expiring.intentId, uniqueId('txn'))),
    ).toEqual({ kind: 'rejected', reason: 'expired' });

    const erased = await issuedIntent();
    const ctx2 = await setup({
      1: async () => {
        await new RewardRepo(db).eraseStmt(erased.installId).run();
      },
    });
    expect(
      await ctx2.service.handleSsv(await ssvQuery(ctx2, erased.intentId, uniqueId('txn'))),
    ).toEqual({ kind: 'rejected', reason: 'unknown_intent' });
  });

  it('propagates an unexpected D1 failure so AdMob retries', async () => {
    const { intentId } = await issuedIntent();
    const ctx = await setup({}, { 1: new Error('D1_ERROR: storage unavailable') });
    await expect(
      ctx.service.handleSsv(await ssvQuery(ctx, intentId, uniqueId('txn'))),
    ).rejects.toThrow('storage unavailable');
    expect((await new RewardRepo(db).findById(intentId))?.status).toBe('issued');
  });
});
