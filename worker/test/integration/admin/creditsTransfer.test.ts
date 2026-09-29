import { describe, expect, it } from 'vitest';
import { main as creditsTransfer, USAGE } from '../../../scripts/credits-transfer';
import { WebCrypto } from '../../../src/adapters/cf/WebCrypto';
import {
  checkTransferRequest,
  inRef,
  outRef,
  parseSnapshot,
  planTransfer,
  type PlanInput,
  type TransferSnapshot,
} from '../../../src/admin/creditsTransfer';
import { supportIdOf } from '../../../src/admin/d1';
import { utf8 } from '../../../src/crypto/encoding';
import { ApiError } from '../../../src/http/errors';
import {
  createTransferToken,
  TRANSFER_TOKEN_TTL_SEC,
} from '../../../src/monetization/transferToken';
import { InstallRepo, type InstallRow } from '../../../src/repos/InstallRepo';
import { LedgerRepo } from '../../../src/repos/LedgerRepo';
import { PurchaseService } from '../../../src/services/PurchaseService';
import { FakeAppStoreServerApi } from '../../fakes/FakeAppStoreServerApi';
import { FixedClock } from '../../fakes/FixedClock';
import { SeqIdGenerator } from '../../fakes/SeqIdGenerator';
import { createHarness, TEST_TRANSFER_TOKEN_KEY, uniqueId } from '../../fakes/testDeps';
import { D1StubCli } from '../../helpers/d1Cli';
import { db, NOW, seedInstall } from '../../helpers/db';

async function mustInstall(id: string): Promise<InstallRow> {
  const row = await new InstallRepo(db).findById(id);
  if (row === null) {
    throw new Error('install missing');
  }
  return row;
}

/**
 * Support credit transfer (Sprint 7.5; 03 §6.6, 04 §12.9, RC84):
 * `scripts/credits-transfer.ts` through `main([...])`, with `wrangler d1
 * execute` played against the real test D1 by `D1StubCli`.
 */
const crypto = new WebCrypto();
const key = utf8(TEST_TRANSFER_TOKEN_KEY);
const ledger = new LedgerRepo(db);
const installs = new InstallRepo(db);
const ENV = { TRANSFER_TOKEN_KEY: TEST_TRANSFER_TOKEN_KEY };

interface Case {
  readonly oldId: string;
  readonly newId: string;
  readonly purchaseId: string;
  readonly code: string;
  readonly supportId: string;
}

let counter = 0;

async function seedPurchase(
  oldId: string,
  options: { credits?: number; spent?: number; status?: string; environment?: string } = {},
): Promise<string> {
  counter++;
  const purchaseId = uniqueId('pur');
  const credits = options.credits ?? 10;
  await db
    .prepare(
      `INSERT INTO purchases (id, install_id, platform, product_id, store_txn_id, credits, status,
         environment, is_test, account_token_match, purchased_at, granted_at)
       VALUES (?1, ?2, 'ios', 'com.vshyrochuk.taro.readings_10', ?3, ?4, ?5, ?6, 0, 1, ?7, ?7)`,
    )
    .bind(
      purchaseId,
      oldId,
      `txn-${String(counter)}-${purchaseId}`,
      credits,
      options.status ?? 'granted',
      options.environment ?? 'production',
      NOW,
    )
    .run();
  await ledger.append({
    installId: oldId,
    bucket: 'paid',
    delta: credits,
    reason: 'purchase',
    refType: 'purchase',
    refId: purchaseId,
    createdAt: NOW,
  });
  if ((options.spent ?? 0) > 0) {
    await ledger.append({
      installId: oldId,
      bucket: 'paid',
      delta: -(options.spent ?? 0),
      reason: 'reading_hold',
      refType: 'reading',
      refId: `${uniqueId('rd')}#1`,
      createdAt: NOW,
    });
  }
  return purchaseId;
}

async function tokenFor(purchaseId: string, newInstallId: string, now = NOW): Promise<string> {
  return createTransferToken(crypto, key, {
    purchaseId,
    newInstallId,
    expiresAt: Math.floor(Date.parse(now) / 1000) + TRANSFER_TOKEN_TTL_SEC,
  });
}

async function setup(options: Parameters<typeof seedPurchase>[1] = {}): Promise<Case> {
  const oldId = await seedInstall({ id: uniqueId('old') });
  const newId = await seedInstall({ id: uniqueId('new') });
  const purchaseId = await seedPurchase(oldId, options);
  return {
    oldId,
    newId,
    purchaseId,
    code: await tokenFor(purchaseId, newId),
    supportId: await supportIdOf(crypto, newId),
  };
}

function ticket(): string {
  counter++;
  return `T-${String(counter)}`;
}

async function run(
  argv: string[],
  cli = new D1StubCli(ENV),
  clock = new FixedClock(NOW),
): Promise<{ code: number; cli: D1StubCli }> {
  const code = await creditsTransfer(argv, cli, crypto, clock);
  return { code, cli };
}

function args(c: Case, ticketId: string, extra: string[] = []): string[] {
  return [
    '--env',
    'staging',
    '--ticket',
    ticketId,
    '--code',
    c.code,
    '--support-id',
    c.supportId.toUpperCase(),
    ...extra,
  ];
}

async function paid(installId: string): Promise<number> {
  return (await ledger.balances(installId)).paid;
}

async function version(installId: string): Promise<number> {
  return (await mustInstall(installId)).stateVersion;
}

function expectNoFullIds(cli: D1StubCli, c: Case): void {
  for (const id of [c.oldId, c.newId, c.purchaseId]) {
    expect(cli.text).not.toContain(id);
  }
  expect(cli.text).not.toContain(c.code);
}

describe('credits-transfer end to end (03 §6.6)', () => {
  it('moves min(unspent paid, purchase credits) with a 409 transfer code from PurchaseService', async () => {
    const h = createHarness({ overrides: { ids: new SeqIdGenerator('7d000001') } });
    const service = new PurchaseService(h.deps);
    const oldId = await seedInstall({ id: uniqueId('own') });
    const newId = await seedInstall({ id: uniqueId('nxt') });
    const txn = h.appStore.add({
      transactionId: '2000000555000001',
      productId: 'com.vshyrochuk.taro.readings_3',
    });
    const owner = await mustInstall(oldId);
    const granted = await service.verify(owner, {
      platform: 'ios',
      productId: txn.productId,
      transactionId: txn.transactionId,
    });
    expect(granted.status).toBe('granted');
    await ledger.append({
      installId: oldId,
      bucket: 'paid',
      delta: -1,
      reason: 'reading_hold',
      refType: 'reading',
      refId: `${uniqueId('rd')}#1`,
      createdAt: NOW,
    });

    const newcomer = await mustInstall(newId);
    const claim = await service
      .verify(newcomer, {
        platform: 'ios',
        productId: txn.productId,
        transactionId: txn.transactionId,
        signedTransaction: FakeAppStoreServerApi.signed(txn.transactionId),
      })
      .then(
        () => null,
        (err: unknown) => err,
      );
    expect(claim).toBeInstanceOf(ApiError);
    const details = (claim as ApiError).options.details as { transferToken: string };
    const c: Case = {
      oldId,
      newId,
      purchaseId: granted.status === 'granted' ? granted.purchaseId : '',
      code: details.transferToken,
      supportId: await supportIdOf(crypto, newId),
    };
    const before = { old: await version(oldId), next: await version(newId) };

    const t = ticket();
    const { code, cli } = await run(args(c, t), new D1StubCli(ENV), h.clock);
    expect({ code, stderr: cli.stderr }).toEqual({ code: 0, stderr: [] });
    expect(cli.stdout).toEqual([
      `transferred (staging, remote): ticket ${t}: 2 paid credit(s) ${oldId.slice(0, 8)} → ${newId.slice(0, 8)} (purchase ${c.purchaseId.slice(0, 8)})`,
    ]);
    expect(await paid(oldId)).toBe(0);
    expect(await paid(newId)).toBe(2);
    expect(await version(oldId)).toBe(before.old + 1);
    expect(await version(newId)).toBe(before.next + 1);
    const legs = (await ledger.entries(newId)).concat(await ledger.entries(oldId));
    const adjust = legs.filter((e) => e.reason === 'admin_adjust');
    expect(adjust.map((e) => [e.installId, e.delta, e.refType, e.refId])).toEqual([
      [newId, 2, 'admin', inRef(t)],
      [oldId, -2, 'admin', outRef(t)],
    ]);
    expect(adjust[0]?.note).toBe(adjust[1]?.note);
    expect(adjust[0]?.note).toMatch(
      new RegExp(
        `^transfer purchase=${c.purchaseId} token=[0-9a-f]{16} from=${oldId.slice(0, 8)} to=${newId.slice(0, 8)} $`,
      ),
    );
    expect(cli.calls[0]?.slice(0, 8)).toEqual([
      'wrangler',
      'd1',
      'execute',
      'DB',
      '--env',
      'staging',
      '--remote',
      '--json',
    ]);
    expectNoFullIds(cli, c);
  });

  it('is idempotent per ticket and single-use per code', async () => {
    const c = await setup({ credits: 10, spent: 3 });
    const t = ticket();
    expect((await run(args(c, t))).code).toBe(0);
    expect(await paid(c.newId)).toBe(7);

    const again = await run(args(c, t));
    expect(again.code).toBe(0);
    expect(again.cli.stdout[0]).toMatch(/^already applied: ticket T-\d+: 7 paid credit/);
    expect(again.cli.writes).toEqual([]);

    const other = await run(args(c, ticket()));
    expect(other.code).toBe(1);
    expect(other.cli.stderr[0]).toContain(`already transferred under ticket ${t}`);
    expect(await paid(c.newId)).toBe(7);
    expect(await paid(c.oldId)).toBe(0);
  });

  it('caps the amount at the purchase credits when the old install holds more', async () => {
    const c = await setup({ credits: 3 });
    await seedPurchase(c.oldId, { credits: 10 });
    expect((await run(args(c, ticket()))).code).toBe(0);
    expect(await paid(c.newId)).toBe(3);
    expect(await paid(c.oldId)).toBe(10);
  });

  it('--dry-run prints the plan with redacted IDs and writes nothing', async () => {
    const c = await setup({ environment: 'sandbox' });
    const { code, cli } = await run(args(c, ticket(), ['--dry-run', '--local']));
    expect(code).toBe(0);
    expect(cli.stdout[0]).toBe('note: the purchase is a sandbox/test purchase');
    expect(cli.stdout[1]).toMatch(/^\[dry-run\] apply: ticket T-\d+: 10 paid credit/);
    expect(cli.stdout.at(-1)).toBe('nothing written (--dry-run).');
    expect(cli.stdout.join('\n')).toContain(`<${c.oldId.slice(0, 8)}…>`);
    expect(cli.calls[0]).toContain('--local');
    expect(cli.writes).toEqual([]);
    expect(await paid(c.newId)).toBe(0);
    expectNoFullIds(cli, c);
  });

  it('resumes a partly applied command from the #out leg', async () => {
    const c = await setup({ credits: 5 });
    const t = ticket();
    const cli = new D1StubCli(ENV);
    cli.intercept = async (index, statements) => {
      if (index !== 1) {
        return null;
      }
      await D1StubCli.execute(statements.slice(0, 1));
      return { code: 1, stdout: '', stderr: `network error near ${c.oldId}` };
    };
    const failed = await run(args(c, t), cli);
    expect(failed.code).toBe(1);
    expect(failed.cli.stderr[1]).toContain(`<${c.oldId.slice(0, 8)}…>`);
    expect(await paid(c.oldId)).toBe(0);
    expect(await paid(c.newId)).toBe(0);

    const resumed = await run(args(c, t));
    expect(resumed.code).toBe(0);
    expect(resumed.cli.writes[0]?.at(-1)).not.toContain(outRef(t) + "', ");
    expect(await paid(c.newId)).toBe(5);

    const dry = await run(args(c, ticket(), ['--dry-run']));
    expect(dry.code).toBe(1);
  });

  it('does not apply when the old install spends meanwhile (guarded #out)', async () => {
    const c = await setup({ credits: 4 });
    const cli = new D1StubCli(ENV);
    cli.intercept = async (index) => {
      if (index === 1) {
        await ledger.append({
          installId: c.oldId,
          bucket: 'paid',
          delta: -2,
          reason: 'reading_hold',
          refType: 'reading',
          refId: `${uniqueId('rd')}#1`,
          createdAt: NOW,
        });
      }
      return null;
    };
    const { code } = await run(args(c, ticket()), cli);
    expect(code).toBe(1);
    expect(cli.stderr[0]).toMatch(
      /^not applied: ticket T-\d+: the old install's paid balance changed/,
    );
    expect(await paid(c.newId)).toBe(0);
    expect(await paid(c.oldId)).toBe(2);
    // A re-run with a fresh ticket re-plans with the new balance.
    expect((await run(args(c, ticket()))).code).toBe(0);
    expect(await paid(c.newId)).toBe(2);
  });

  it('refuses revoked purchases, empty balances, unknown installs and reused tickets', async () => {
    const revoked = await setup({ status: 'revoked' });
    const r1 = await run(args(revoked, ticket()));
    expect([r1.code, r1.cli.stderr[0]]).toEqual([1, expect.stringContaining('refunded')]);

    const spent = await setup({ credits: 3, spent: 3 });
    const r2 = await run(args(spent, ticket()));
    expect(r2.cli.stderr[0]).toContain('no unspent paid credits');

    const gone = await setup();
    await installs.setStatus(gone.newId, 'deleted');
    expect((await run(args(gone, ticket()))).cli.stderr[0]).toContain('unknown or erased');

    const missing = await setup();
    const ghost = uniqueId('gho');
    const ghostCase = {
      ...missing,
      newId: ghost,
      code: await tokenFor(missing.purchaseId, ghost),
      supportId: await supportIdOf(crypto, ghost),
    };
    expect((await run(args(ghostCase, ticket()))).cli.stderr[0]).toContain('unknown or erased');

    const self = await setup();
    const selfCase = {
      ...self,
      code: await tokenFor(self.purchaseId, self.oldId),
      supportId: await supportIdOf(crypto, self.oldId),
    };
    expect((await run(args(selfCase, ticket()))).cli.stderr[0]).toContain('already owns');

    const noPurchase = await setup();
    const fake = { ...noPurchase, code: await tokenFor(uniqueId('nop'), noPurchase.newId) };
    expect((await run(args(fake, ticket()))).cli.stderr[0]).toContain('was not found');

    const first = await setup();
    const second = await setup();
    const shared = ticket();
    expect((await run(args(first, shared))).code).toBe(0);
    const reused = await run(args(second, shared));
    expect([reused.code, reused.cli.stderr[0]]).toEqual([
      1,
      `refused: ticket ${shared}: ticket ${shared} was already used for a different transfer`,
    ]);
  });

  it('refuses a wrong Support ID, a bad or expired code, and a missing key', async () => {
    const c = await setup();
    const wrong = await run([...args(c, ticket()).slice(0, 7), '00000000']);
    expect(wrong.cli.stderr[0]).toBe(
      'refused: Support ID does not match the install that requested this transfer code',
    );
    const bad = await run(args({ ...c, code: `${c.code}x` }, ticket()));
    expect(bad.cli.stderr[0]).toMatch(/^refused: transfer code is invalid or expired/);
    const clock = new FixedClock(NOW);
    clock.advance({ days: 8 });
    expect((await run(args(c, ticket()), new D1StubCli(ENV), clock)).code).toBe(1);
    const noKey = await run(args(c, ticket()), new D1StubCli({}));
    expect([noKey.code, noKey.cli.stderr[0]]).toEqual([
      1,
      expect.stringMatching(/^TRANSFER_TOKEN_KEY is not set.*--env staging\)$/),
    ]);
    expect(await paid(c.newId)).toBe(0);
    for (const r of [wrong, bad]) {
      expect(r.cli.calls).toEqual([]);
    }
  });

  it('reports wrangler failures and unreadable output', async () => {
    const c = await setup();
    const failing = new D1StubCli(ENV);
    failing.intercept = () => Promise.resolve({ code: 1, stdout: '', stderr: 'auth error' });
    const r1 = await run(args(c, ticket()), failing);
    expect([r1.code, r1.cli.stderr[0]]).toEqual([
      1,
      'failed: wrangler d1 execute failed (exit 1): auth error',
    ]);
    const garbage = new D1StubCli(ENV);
    garbage.intercept = () => Promise.resolve({ code: 0, stdout: 'not json', stderr: '' });
    expect((await run(args(c, ticket()), garbage)).cli.stderr[0]).toBe(
      'failed: wrangler did not print JSON',
    );
  });

  it('exits 2 on usage errors', async () => {
    for (const argv of [
      [],
      ['--env', 'qa', '--ticket', 'T', '--code', 'x', '--support-id', 'abcdef12'],
      ['--env', 'prod', '--ticket', 'T'],
      ['--bogus'],
    ]) {
      const r = await run(argv);
      expect(r.code, argv.join(' ')).toBe(2);
      expect(r.cli.stderr.at(-1)?.endsWith(USAGE)).toBe(true);
    }
  });
});

describe('creditsTransfer pure pieces', () => {
  const now = new Date(NOW);

  it('checkTransferRequest validates the ticket, Support ID and token IDs', async () => {
    const c = await setup();
    const base = { ticketId: 'T-1', transferToken: c.code, supportId: c.supportId };
    expect(
      await checkTransferRequest(crypto, key, { ...base, ticketId: 'bad ticket' }, now),
    ).toEqual({
      ok: false,
      error: expect.stringContaining('ticket ID') as string,
    });
    expect(
      await checkTransferRequest(crypto, key, { ...base, supportId: 'xyz' }, now),
    ).toMatchObject({
      ok: false,
      error: expect.stringContaining('8 hex') as string,
    });
    const malformed = await createTransferToken(crypto, key, {
      purchaseId: "x'",
      newInstallId: c.newId,
      expiresAt: Math.floor(now.getTime() / 1000) + 60,
    });
    expect(
      await checkTransferRequest(crypto, key, { ...base, transferToken: malformed }, now),
    ).toEqual({ ok: false, error: 'transfer code carries malformed IDs' });
    const ok = await checkTransferRequest(
      crypto,
      key,
      { ...base, transferToken: ` ${c.code} ` },
      now,
    );
    expect(ok).toMatchObject({
      ok: true,
      claims: { purchaseId: c.purchaseId, newInstallId: c.newId },
    });
  });

  it('parseSnapshot: no row → null; a row without purchase columns throws', () => {
    expect(parseSnapshot([])).toBeNull();
    expect(() => parseSnapshot([{ purchase_id: 'p' }])).toThrow('missing purchase columns');
    expect(parseSnapshot([{ purchase_id: 'p', old_install_id: 'o', credits: '3' }])).toMatchObject({
      credits: 3,
      purchaseStatus: '',
      environment: '',
      oldPaid: 0,
      outDelta: null,
    });
  });

  it('planTransfer refuses a #out leg of another purchase or without a note', () => {
    const input: PlanInput = {
      ticketId: 'T-9',
      claims: { purchaseId: 'p1', newInstallId: 'new00000-x', expiresAt: 0 },
      tokenDigest: 'd',
      now: NOW,
    };
    const snapshot: TransferSnapshot = {
      purchaseId: 'p1',
      oldInstallId: 'old00000-x',
      credits: 3,
      purchaseStatus: 'granted',
      environment: 'production',
      oldStatus: 'active',
      oldPaid: 3,
      newStatus: 'active',
      outDelta: -3,
      outInstallId: 'old00000-x',
      outNote: null,
      inDelta: null,
      otherOutRef: null,
    };
    expect(planTransfer(input, snapshot)).toMatchObject({ kind: 'refused' });
    expect(
      planTransfer(input, {
        ...snapshot,
        outNote: 'transfer purchase=p1 token=d from=old00000 to=new00000 ',
      }),
    ).toMatchObject({ kind: 'resume', amount: 3 });
  });
});
