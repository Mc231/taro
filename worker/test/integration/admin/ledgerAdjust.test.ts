import { describe, expect, it } from 'vitest';
import { main as ledgerAdjust, USAGE } from '../../../scripts/ledger-adjust';
import { WebCrypto } from '../../../src/adapters/cf/WebCrypto';
import {
  D1OutputError,
  numberOrNull,
  parseD1Output,
  sqlInt,
  sqlString,
  supportIdOf,
} from '../../../src/admin/d1';
import {
  idsOf,
  parseAdjustSnapshot,
  planAdjustment,
  settleRef,
  validateAdjust,
} from '../../../src/admin/ledgerAdjust';
import { InstallRepo, type InstallRow } from '../../../src/repos/InstallRepo';
import { LedgerRepo } from '../../../src/repos/LedgerRepo';
import { FixedClock } from '../../fakes/FixedClock';
import { uniqueId } from '../../fakes/testDeps';
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
 * `scripts/ledger-adjust.ts` (Sprint 7.5; 03 §6.5, §6.6; RC61, RC84) through
 * `main([...])` against the real test D1 via `D1StubCli`.
 */
const crypto = new WebCrypto();
const ledger = new LedgerRepo(db);

let counter = 0;
function ticket(): string {
  counter++;
  return `L-${String(counter)}`;
}

async function install(paid = 0): Promise<{ id: string; supportId: string }> {
  const id = await seedInstall({ id: uniqueId('adj') });
  if (paid !== 0) {
    await ledger.append({
      installId: id,
      bucket: 'paid',
      delta: paid,
      reason: paid > 0 ? 'purchase' : 'refund_revoke',
      refType: 'purchase',
      refId: uniqueId('pur'),
      createdAt: NOW,
    });
  }
  return { id, supportId: await supportIdOf(crypto, id) };
}

async function run(
  argv: string[],
  cli = new D1StubCli(),
): Promise<{ code: number; cli: D1StubCli }> {
  const code = await ledgerAdjust(argv, cli, crypto, new FixedClock(NOW));
  return { code, cli };
}

function base(target: { id: string; supportId: string }, t: string, narrow = true): string[] {
  return [
    '--env',
    'prod',
    '--ticket',
    t,
    '--support-id',
    target.supportId,
    ...(narrow ? ['--install', target.id] : []),
  ];
}

async function row(id: string): Promise<InstallRow> {
  return await mustInstall(id);
}

describe('ledger-adjust main([...])', () => {
  it('adds a bonus adjustment once per ticket and bumps state_version', async () => {
    const target = await install();
    const t = ticket();
    const before = (await row(target.id)).stateVersion;
    const argv = [
      ...base(target, t),
      '--bucket',
      'bonus',
      '--delta',
      '+2',
      '--note',
      'SSV lost (support)',
    ];
    const first = await run(argv);
    expect({ code: first.code, stderr: first.cli.stderr }).toEqual({ code: 0, stderr: [] });
    expect(first.cli.stdout).toEqual([
      `applied (prod, remote): ticket ${t}: bonus +2 on ${target.id.slice(0, 8)}`,
      `${target.id.slice(0, 8)}: status active, paid 0, bonus 2`,
    ]);
    expect((await row(target.id)).stateVersion).toBe(before + 1);
    const entry = (await ledger.entries(target.id))[0];
    expect(entry).toMatchObject({
      reason: 'admin_adjust',
      refType: 'admin',
      refId: t,
      note: 'SSV lost (support)',
    });

    const again = await run(argv);
    expect([again.code, again.cli.stdout[0]]).toEqual([
      0,
      `already applied: ticket ${t}: bonus +2 on ${target.id.slice(0, 8)}`,
    ]);
    const different = await run([...base(target, t), '--bucket', 'bonus', '--delta', '3']);
    expect(different.cli.stderr[0]).toContain('already adjusted bonus by 2');
    expect(first.cli.text + again.cli.text).not.toContain(target.id);
  });

  it('refuses a negative adjustment below 0 and applies one within the balance', async () => {
    const target = await install(5);
    const low = await run([...base(target, ticket()), '--bucket', 'paid', '--delta', '-6']);
    expect([low.code, low.cli.stderr[0]]).toEqual([
      1,
      'refused: paid balance is 5; -6 would go below 0',
    ]);
    const ok = await run([...base(target, ticket()), '--bucket', 'paid', '--delta', '-5']);
    expect(ok.code).toBe(0);
    expect((await ledger.balances(target.id)).paid).toBe(0);
  });

  it('settles a refund debt once; refuses when there is none', async () => {
    const target = await install(-3);
    const t = ticket();
    const settled = await run([...base(target, t), '--settle-debt']);
    expect(settled.cli.stdout[0]).toBe(
      `applied (prod, remote): ticket ${t}: refund debt of 3 settled on ${target.id.slice(0, 8)} (paid → 0)`,
    );
    expect((await ledger.balances(target.id)).paid).toBe(0);
    const entries = await ledger.entries(target.id);
    expect(entries.some((e) => e.refId === settleRef(t) && e.delta === 3)).toBe(true);
    const again = await run([...base(target, t), '--settle-debt']);
    expect(again.cli.stdout[0]).toMatch(/^already applied: ticket L-\d+: refund debt of 3 settled/);
    const none = await run([...base(target, ticket()), '--settle-debt']);
    expect(none.cli.stderr[0]).toBe(
      'refused: paid balance is 0; there is no refund debt to settle',
    );
  });

  it('does not settle when the debt changed between plan and apply', async () => {
    const target = await install(-2);
    const cli = new D1StubCli();
    cli.intercept = async (_index, statements) => {
      if ((statements[0] ?? '').startsWith('INSERT')) {
        await ledger.append({
          installId: target.id,
          bucket: 'paid',
          delta: -1,
          reason: 'refund_revoke',
          refType: 'purchase',
          refId: uniqueId('pur'),
          createdAt: NOW,
        });
      }
      return null;
    };
    const r = await run([...base(target, ticket()), '--settle-debt'], cli);
    expect(r.code).toBe(1);
    expect(r.cli.stderr[0]).toMatch(/^not applied: .*re-run to re-plan$/);
    expect((await ledger.balances(target.id)).paid).toBe(-3);
  });

  it('blocks and unblocks an install', async () => {
    const target = await install();
    const blocked = await run([...base(target, ticket()), '--block']);
    expect(blocked.code).toBe(0);
    expect((await row(target.id)).status).toBe('blocked');
    expect((await run([...base(target, ticket()), '--block'])).cli.stdout[0]).toMatch(
      /^already applied/,
    );
    expect((await run([...base(target, ticket()), '--unblock'])).code).toBe(0);
    expect((await row(target.id)).status).toBe('active');
  });

  it('resolves the install by Support ID alone (paged scan) or by store transaction ID', async () => {
    const target = await install();
    const scan = await run([
      ...base(target, ticket(), false),
      '--bucket',
      'bonus',
      '--delta',
      '1',
      '--dry-run',
    ]);
    expect(scan.code).toBe(0);
    expect(scan.cli.stdout[0]).toMatch(/^\[dry-run\] ticket L-\d+: bonus \+1/);
    expect(scan.cli.stdout.join('\n')).not.toContain(target.id);
    expect(scan.cli.writes).toEqual([]);

    const txn = `txn-${uniqueId('t')}`;
    await db
      .prepare(
        `INSERT INTO purchases (id, install_id, platform, product_id, store_txn_id, credits, status,
           environment, is_test, account_token_match, purchased_at, granted_at)
         VALUES (?1, ?2, 'android', 'com.vshyrochuk.taro.readings_3', ?3, 3, 'granted', 'production', 0, 1, ?4, ?4)`,
      )
      .bind(uniqueId('pur'), target.id, txn, NOW)
      .run();
    const byTxn = await run([...base(target, ticket(), false), '--txn', txn, '--block', '--local']);
    expect(byTxn.code).toBe(0);
    expect(byTxn.cli.calls[0]).toContain('--local');
    const unknownTxn = await run([...base(target, ticket(), false), '--txn', 'nope', '--block']);
    expect(unknownTxn.cli.stderr[0]).toBe(
      'refused: no purchase with that store transaction / order ID',
    );
  });

  it('pages through installs during a Support ID scan', async () => {
    const target = await install();
    const cli = new D1StubCli();
    const pages: string[] = [];
    cli.intercept = (_index, statements) => {
      const sql = statements[0] ?? '';
      if (!sql.startsWith('SELECT id FROM installs')) {
        return Promise.resolve(null);
      }
      pages.push(sql);
      const rows =
        pages.length === 1
          ? Array.from({ length: 1000 }, (_, i) => ({ id: `zz${String(i).padStart(8, '0')}` }))
          : [{ id: target.id }];
      return Promise.resolve({
        code: 0,
        stdout: JSON.stringify([{ results: rows, success: true }]),
        stderr: '',
      });
    };
    const r = await run([...base(target, ticket(), false), '--block', '--dry-run'], cli);
    expect(r.code).toBe(0);
    expect(pages).toHaveLength(2);
    expect(pages[1]).toContain("id > 'zz00000999'");
  });

  it('refuses a Support ID that matches nothing or several installs, and unknown installs', async () => {
    const target = await install();
    const wrongId = await run([
      ...base(target, ticket()).slice(0, 5),
      '0000000f',
      '--install',
      target.id,
      '--block',
    ]);
    expect(wrongId.cli.stderr[0]).toBe('refused: Support ID does not match the install');

    const cli = new D1StubCli();
    cli.intercept = () =>
      Promise.resolve({
        code: 0,
        stdout: JSON.stringify([
          { results: [{ id: target.id }, { id: target.id }], success: true },
        ]),
        stderr: '',
      });
    const twice = await run([...base(target, ticket(), false), '--block'], cli);
    expect(twice.cli.stderr[0]).toContain('matches 2 installs');

    const ghost = uniqueId('gho');
    const unknown = await run([
      ...base({ id: ghost, supportId: await supportIdOf(crypto, ghost) }, ticket()),
      '--block',
    ]);
    expect(unknown.cli.stderr[0]).toBe('refused: install not found (or erased)');
    const bad = await run([...base(target, ticket(), false), '--install', "x'--", '--block']);
    expect(bad.cli.stderr[0]).toBe('refused: --install is not an install ID');
  });

  it('refuses a ticket already used for another install', async () => {
    const a = await install();
    const b = await install();
    const t = ticket();
    expect((await run([...base(a, t), '--bucket', 'bonus', '--delta', '1'])).code).toBe(0);
    const r = await run([...base(b, t), '--bucket', 'bonus', '--delta', '1']);
    expect(r.cli.stderr[0]).toBe(`refused: ticket ${t} was already used for another install`);
  });

  it('reports wrangler failures on read and on apply', async () => {
    const target = await install();
    const readFail = new D1StubCli();
    readFail.intercept = () =>
      Promise.resolve({ code: 2, stdout: '', stderr: `boom ${target.id}` });
    const r1 = await run([...base(target, ticket()), '--block'], readFail);
    expect(r1.cli.stderr[0]).toBe(
      `failed: wrangler d1 execute failed (exit 2): boom <${target.id.slice(0, 8)}…>`,
    );

    const applyFail = new D1StubCli();
    applyFail.intercept = (index) =>
      Promise.resolve(index === 1 ? { code: 1, stdout: '', stderr: `denied ${target.id}` } : null);
    const r2 = await run([...base(target, ticket()), '--block'], applyFail);
    expect(r2.code).toBe(1);
    expect(r2.cli.stderr).toEqual([
      'wrangler d1 execute failed (exit 1); re-run the same command:',
      `denied <${target.id.slice(0, 8)}…>`,
    ]);
  });

  it('exits 2 on usage errors', async () => {
    const target = await install();
    const cases = [
      [],
      ['--nope'],
      [...base(target, 'bad ticket'), '--block'],
      [...base(target, ticket()), '--txn', 'x', '--block'],
      [...base(target, ticket())],
      [...base(target, ticket()), '--block', '--settle-debt'],
      [...base(target, ticket()), '--bucket', 'gold', '--delta', '1'],
      [...base(target, ticket()), '--bucket', 'paid', '--delta', '0'],
      [...base(target, ticket()), '--bucket', 'paid', '--delta', '1.5'],
      [...base(target, ticket()), '--bucket', 'paid', '--delta', '1', '--note', 'semi;colon'],
    ];
    for (const argv of cases) {
      const r = await run(argv);
      expect(r.code, argv.join(' ')).toBe(2);
      expect(r.cli.stderr.at(-1)?.endsWith(USAGE)).toBe(true);
    }
  });
});

describe('ledgerAdjust and d1 pure pieces', () => {
  it('validateAdjust bounds the delta and the note', () => {
    expect(validateAdjust(1001, null)).toContain('--delta');
    expect(validateAdjust(-1000, 'ok note')).toBeNull();
    expect(validateAdjust(1, "it's")).toContain('--note');
  });

  it('planAdjustment refuses erased installs; idsOf skips malformed rows', () => {
    expect(
      planAdjustment(
        { ticketId: 'T', installId: 'abcdefgh-1', action: { kind: 'block' }, now: NOW },
        {
          installId: 'abcdefgh-1',
          status: 'deleted',
          paid: 0,
          bonus: 0,
          ticketPaid: null,
          ticketBonus: null,
          ticketSettle: null,
          ticketInstallId: null,
        },
      ),
    ).toEqual({ kind: 'refused', reason: 'install not found (or erased)' });
    expect(idsOf([{ id: 'abcdefgh-1' }, { id: 'x' }, null, { id: 3 }])).toEqual(['abcdefgh-1']);
    expect(parseAdjustSnapshot([{ id: 'abcdefgh-1' }])).toMatchObject({
      status: '',
      paid: 0,
      bonus: 0,
    });
    expect(parseAdjustSnapshot([{}])).toBeNull();
  });

  it('SQL literals and wrangler output parsing', () => {
    expect(sqlString("a'b")).toBe("'a''b'");
    expect(() => sqlInt(1.5)).toThrow('not an integer');
    expect(numberOrNull('12')).toBe(12);
    expect(numberOrNull('')).toBeNull();
    expect(numberOrNull(null)).toBeNull();
    expect(() => parseD1Output('{}')).toThrow(D1OutputError);
    expect(() => parseD1Output('[{"success":false}]')).toThrow('did not succeed');
    expect(() => parseD1Output('[null]')).toThrow('did not succeed');
    expect(parseD1Output('[{"success":true,"results":[{"a":1}]}]')).toEqual([[{ a: 1 }]]);
  });
});
