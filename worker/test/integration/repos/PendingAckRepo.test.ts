import { describe, expect, it } from 'vitest';
import { PENDING_ACK_PREFIX, PendingAckRepo } from '../../../src/repos/PendingAckRepo';
import { bindings } from '../../fakes/testDeps';

/** `pendingAck` markers for the Google acknowledgement retry (03 §6.3 step 4, RC10). */
describe('PendingAckRepo', () => {
  it('marks, lists and clears purchases awaiting acknowledgement', async () => {
    const repo = new PendingAckRepo(bindings.CACHE_KV);
    await repo.mark('p-1', '2026-09-26T10:00:00.000Z');
    await repo.mark('p-2', '2026-09-26T10:01:00.000Z');
    await bindings.CACHE_KV.put(`${PENDING_ACK_PREFIX}p-3`, 'not json');
    expect(await repo.list().catch(() => null)).toBeNull();
    await bindings.CACHE_KV.put(`${PENDING_ACK_PREFIX}p-3`, '{}');
    expect(await repo.list()).toEqual([
      { purchaseId: 'p-1', markedAt: '2026-09-26T10:00:00.000Z' },
      { purchaseId: 'p-2', markedAt: '2026-09-26T10:01:00.000Z' },
      { purchaseId: 'p-3', markedAt: '' },
    ]);
    await repo.clear('p-1');
    await repo.clear('p-3');
    expect((await repo.list(10)).map((p) => p.purchaseId)).toEqual(['p-2']);
  });
});
