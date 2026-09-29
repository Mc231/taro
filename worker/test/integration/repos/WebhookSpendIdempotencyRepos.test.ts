import { describe, expect, it } from 'vitest';
import { IdempotencyRepo } from '../../../src/repos/IdempotencyRepo';
import { SpendRepo } from '../../../src/repos/SpendRepo';
import { WebhookEventRepo, type WebhookEvent } from '../../../src/repos/WebhookEventRepo';
import { uniqueId } from '../../fakes/testDeps';
import { db, NOW, seedInstall, seedReading } from '../../helpers/db';
import { InstallRepo } from '../../../src/repos/InstallRepo';

describe('WebhookEventRepo', () => {
  const repo = new WebhookEventRepo(db);

  it('records an event once and reports duplicates', async () => {
    const event: WebhookEvent = {
      id: `ssv:${uniqueId('txn')}`,
      source: 'admob',
      type: 'reward',
      status: 'processed',
      receivedAt: NOW,
    };
    expect(await repo.record(event)).toBe(true);
    expect(await repo.record({ ...event, status: 'failed' })).toBe(false);
    expect(await repo.find(event.id)).toEqual(event);
    expect(await repo.find('missing')).toBeNull();
  });

  it('updates the status of a failed event', async () => {
    const id = uniqueId('apple');
    await repo
      .recordStmt({ id, source: 'apple', type: 'REFUND', status: 'failed', receivedAt: NOW })
      .run();
    expect(await repo.updateStatus(id, 'processed')).toBe(true);
    expect((await repo.find(id))?.status).toBe('processed');
    expect(await repo.updateStatus('missing', 'ignored')).toBe(false);
  });
});

describe('SpendRepo (03 §10.1)', () => {
  const repo = new SpendRepo(db);

  it('accumulates readings and cost per UTC day', async () => {
    expect(await repo.get('2031-01-01')).toEqual({
      dateUtc: '2031-01-01',
      readings: 0,
      costMicroUsd: 0,
    });
    await repo.add('2031-01-01', 1500);
    await db.batch([repo.addStmt('2031-01-01', 2500), repo.addStmt('2031-01-02', 7)]);
    expect(await repo.get('2031-01-01')).toEqual({
      dateUtc: '2031-01-01',
      readings: 2,
      costMicroUsd: 4000,
    });
    expect((await repo.get('2031-01-02')).readings).toBe(1);
  });

  it('counts distinct active installs from syncs and readings', async () => {
    const from = '2032-03-01T00:00:00.000Z';
    const to = '2032-03-02T00:00:00.000Z';
    const synced = await seedInstall();
    await new InstallRepo(db).touch(synced, '2032-03-01T05:00:00.000Z', null);
    const reader = await seedInstall();
    await seedReading(reader, { createdAt: '2032-03-01T06:00:00.000Z' });
    await new InstallRepo(db).touch(reader, '2032-03-01T07:00:00.000Z', null);
    await seedReading(reader, { createdAt: '2032-03-01T08:00:00.000Z' });
    expect(await repo.activeInstalls(from, to)).toBe(2);
    expect(await repo.activeInstalls(to, '2032-03-03T00:00:00.000Z')).toBe(0);
  });
});

describe('IdempotencyRepo erasure (RC37)', () => {
  it('deletes every key of the install and none of another', async () => {
    const repo = new IdempotencyRepo(db);
    const claim = (installId: string) => ({
      installId,
      route: 'PUT /v1/installs/me/timezone',
      key: uniqueId('key'),
      requestHash: 'h',
      createdAt: NOW,
      expiresAt: '2026-10-03T10:00:00.000Z',
    });
    const mine = claim(uniqueId('me'));
    const other = claim(uniqueId('other'));
    await repo.insert(mine);
    await repo.insert(other);
    await repo.eraseStmt(mine.installId).run();
    expect(await repo.find(mine)).toBeNull();
    expect(await repo.find(other)).not.toBeNull();
  });
});
