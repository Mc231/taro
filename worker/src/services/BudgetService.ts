import type { RuntimeConfig } from '../config/schema';
import { budgetFloorUsd, budgetTier, type BudgetTier } from '../domain/budget';
import { SpendRepo } from '../repos/SpendRepo';

/**
 * Budget tier lookup (03 §10.2, RC64): the read side used by
 * `GET /v1/balance` (`free.paused`, `readingsPaused`). Alerts, the model
 * fallback and hold-time enforcement arrive with the readings pipeline
 * (Phase 8) and reuse `domain/budget`.
 *
 * `dau` = distinct installs with a reading or balance sync yesterday (UTC),
 * cached per isolate and day, and queried only once today's spend has
 * reached `budgetFloorUsd` (below it no tier depends on `dau`).
 */
export interface BudgetStatus {
  readonly tier: BudgetTier;
  readonly spendUsd: number;
}

const MICRO_USD = 1_000_000;
const DAY_MS = 86_400_000;

/** `dau` per UTC day, shared by the requests of one isolate. */
export class DauCache {
  private day: string | undefined;
  private value = 0;

  get(day: string): number | undefined {
    return this.day === day ? this.value : undefined;
  }

  set(day: string, value: number): void {
    this.day = day;
    this.value = value;
  }
}

export const isolateDauCache = new DauCache();

export class BudgetService {
  private readonly spend: SpendRepo;

  constructor(
    db: D1Database,
    private readonly cache: DauCache = isolateDauCache,
  ) {
    this.spend = new SpendRepo(db);
  }

  async status(config: RuntimeConfig, now: Date): Promise<BudgetStatus> {
    const today = now.toISOString().slice(0, 10);
    const spendUsd = (await this.spend.get(today)).costMicroUsd / MICRO_USD;
    const dau = spendUsd >= budgetFloorUsd(config) ? await this.dau(today) : 0;
    return { tier: budgetTier(spendUsd, dau, config), spendUsd };
  }

  private async dau(today: string): Promise<number> {
    const cached = this.cache.get(today);
    if (cached !== undefined) {
      return cached;
    }
    const start = Date.parse(`${today}T00:00:00.000Z`);
    const value = await this.spend.activeInstalls(
      new Date(start - DAY_MS).toISOString(),
      new Date(start).toISOString(),
    );
    this.cache.set(today, value);
    return value;
  }
}
