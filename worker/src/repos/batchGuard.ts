/**
 * Conditional D1 batches (Phase 7.1 spike, docs/ARCHITECTURE.md §Ledger,
 * `test/integration/db/batchConditional.test.ts`).
 *
 * A D1 `batch` runs its statements in order, in one serialised transaction,
 * on one SQLite connection, and rolls everything back if any statement fails.
 * SQLite's `changes()` returns the row count of the most recently *completed*
 * INSERT/UPDATE/DELETE (a SELECT does not reset it), so a statement guarded by
 * `(SELECT changes()) = 1` runs only when its direct predecessor changed
 * exactly one row.
 *
 * Rules for a money batch built on it:
 * 1. The first statement is the **gate**: one compare-and-set that carries
 *    every condition (`readings.hold_state`, the balance or free counter).
 * 2. Every later statement is guarded by `PREV_APPLIED` and shaped to change
 *    **exactly one row** whenever the chain is live (single-row UPDATEs on rows
 *    that must exist, or `INSERT … SELECT … WHERE guard ON CONFLICT DO UPDATE`
 *    upserts), so the chain never breaks half way.
 * 3. What "cannot happen" fails loudly instead of silently skipping: a
 *    duplicate ledger `ref_id` or a counter above its CHECK aborts the batch,
 *    which rolls back the gate too.
 * 4. Several alternative gates may share one batch (free, bonus, paid): after
 *    one applies, the others' `hold_state` condition no longer matches.
 */
export const PREV_APPLIED = '(SELECT changes()) = 1';
