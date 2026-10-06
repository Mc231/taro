import type { RuntimeConfig } from '../config/schema';
import type { BudgetThresholds, BudgetTier } from '../domain/budget';
import type { Environment } from '../env';
import type { Clock } from '../ports/Clock';
import type { ConfigStore } from '../ports/ConfigStore';
import { StatsRepo, type DayStats } from '../repos/StatsRepo';
import { BudgetService, DauCache, MICRO_USD, type BudgetSnapshot } from './BudgetService';

/**
 * Read-only stats for the owner's Telegram bot (`POST /v1/admin/telegram`,
 * 03 §14.3): `/today`, `/week`, `/budget`, `/help`. Every number is an
 * aggregate over UTC days; no reply carries an install ID, a question, a
 * reading or any other per-user value. Nothing here writes.
 */
export const STATS_COMMANDS = ['today', 'week', 'budget', 'help'] as const;
export type StatsCommand = (typeof STATS_COMMANDS)[number];

/** Descriptions for `/help` and Telegram `setMyCommands`. */
export const STATS_COMMAND_HELP: Readonly<Record<StatsCommand, string>> = {
  today: "today's numbers (UTC day)",
  week: 'the last 7 UTC days, one line per day + totals',
  budget: 'AI budget tiers and headroom (UTC day)',
  help: 'this list',
};

const WEEK_DAYS = 7;
const DAY_MS = 86_400_000;
const PRODUCT_PREFIX = /^com\.vshyrochuk\.taro\./;
const WEEKDAYS = 'SunMonTueWedThuFriSat';
const TIER_LABEL: Readonly<Record<BudgetTier, string>> = {
  normal: 'ok',
  soft: 'soft',
  freeStop: 'free-stop',
  hard: 'hard',
};

/**
 * The command of a message text: the first word, case-insensitive, with an
 * optional `@botname` suffix (`/Today@taro_alerts_vsh_bot`). `/start` is
 * `help`. Anything else (plain text, an unknown command) is `undefined`.
 */
export function parseStatsCommand(text: string): StatsCommand | undefined {
  const word = (text.trim().split(/\s+/)[0] ?? '').toLowerCase();
  const match = /^\/([a-z_]+)(?:@[a-z0-9_]+)?$/.exec(word);
  const name = match?.[1];
  if (name === 'start') {
    return 'help';
  }
  return STATS_COMMANDS.find((command) => command === name);
}

export interface TelegramStatsDeps {
  readonly db: D1Database;
  readonly config: ConfigStore;
  readonly clock: Clock;
  readonly environment: Environment;
}

export class TelegramStatsService {
  private readonly stats: StatsRepo;

  constructor(private readonly deps: TelegramStatsDeps) {
    this.stats = new StatsRepo(deps.db);
  }

  /** The reply to one message text (unknown commands get a `/help` hint). */
  async reply(text: string): Promise<string> {
    switch (parseStatsCommand(text)) {
      case 'today':
        return this.today();
      case 'week':
        return this.week();
      case 'budget':
        return this.budget();
      case 'help':
        return this.help();
      default:
        return 'Unknown command. Send /help for the list.';
    }
  }

  help(): string {
    return [
      `🤖 Taro stats (${this.deps.environment}), read-only`,
      ...STATS_COMMANDS.map((command) => `/${command} — ${STATS_COMMAND_HELP[command]}`),
    ].join('\n');
  }

  async today(): Promise<string> {
    const now = this.deps.clock.now();
    const today = utcDay(now);
    const [days, budget] = await Promise.all([this.stats.days(today, 1), this.snapshot(now)]);
    const s = sumDays(days, today);
    return [
      `📊 Taro today (${this.deps.environment}, UTC day ${today})`,
      readingsLine(s),
      `AI spend: ${usd(s.spendMicroUsd / MICRO_USD)} · soft ${usd(budget.thresholds.soft)} · hard ${usd(budget.thresholds.hard)} · tier: ${TIER_LABEL[budget.tier]}`,
      `Avg cost: ${avgCost(s.completedCostMicroUsd, s.costedCompleted)}`,
      `Installs: ${String(s.newInstalls)} new · ${String(s.active)} active`,
      purchasesLine(s.purchases, s.sandboxPurchases),
      `Refunds: ${String(s.refunds)}`,
      `Rewarded: ${String(s.rewarded)}`,
    ].join('\n');
  }

  async week(): Promise<string> {
    const now = this.deps.clock.now();
    const first = utcDay(new Date(now.getTime() - (WEEK_DAYS - 1) * DAY_MS));
    const days = await this.stats.days(first, WEEK_DAYS);
    const total = sumDays(days, first);
    const lines = days.map(
      (s) =>
        `${s.day.slice(5)} ${weekday(s.day)}: ${String(s.completed)} ✓ · ${String(s.declined)} ✗ · ${usd(s.spendMicroUsd / MICRO_USD)} · ${String(s.newInstalls)} new · ${String(s.active)} active · ${String(purchaseCount(s))} 💳`,
    );
    return [
      `📅 Taro week (${this.deps.environment}, UTC days ${first} – ${utcDay(now)})`,
      ...lines,
      'Total:',
      readingsLine(total),
      `AI spend: ${usd(total.spendMicroUsd / MICRO_USD)} · avg ${avgCost(total.completedCostMicroUsd, total.costedCompleted)}`,
      `Installs: ${String(total.newInstalls)} new`,
      purchasesLine(total.purchases, total.sandboxPurchases),
      `Refunds: ${String(total.refunds)} · Rewarded: ${String(total.rewarded)}`,
    ].join('\n');
  }

  async budget(): Promise<string> {
    const now = this.deps.clock.now();
    const snap = await this.snapshot(now);
    const t: BudgetThresholds = snap.thresholds;
    const left = (limit: number) =>
      snap.spendUsd >= limit ? 'reached' : `${usd(limit - snap.spendUsd)} left`;
    return [
      `💰 Taro budget (${this.deps.environment}, UTC day ${utcDay(now)})`,
      `Spend today: ${usd(snap.spendUsd)} · tier: ${TIER_LABEL[snap.tier]}`,
      `DAU (yesterday): ${String(snap.dau)}`,
      `Soft: ${usd(t.soft)} · ${left(t.soft)}`,
      `Free-stop: ${usd(t.freeStop)} · ${left(t.freeStop)}`,
      `Hard: ${usd(t.hard)} · ${left(t.hard)}`,
    ].join('\n');
  }

  private async snapshot(now: Date): Promise<BudgetSnapshot> {
    const config: RuntimeConfig = await this.deps.config.snapshot();
    // A fresh DAU cache: the stats show the current value, not an isolate's cached one.
    return new BudgetService(this.deps.db, new DauCache()).snapshot(config, now);
  }
}

function utcDay(now: Date): string {
  return now.toISOString().slice(0, 10);
}

function weekday(day: string): string {
  const index = new Date(`${day}T00:00:00.000Z`).getUTCDay() * 3;
  return WEEKDAYS.slice(index, index + 3);
}

function usd(value: number): string {
  return `$${value.toFixed(2)}`;
}

function avgCost(costMicroUsd: number, readings: number): string {
  return readings === 0 ? '—' : `$${(costMicroUsd / readings / MICRO_USD).toFixed(3)}/reading`;
}

function readingsLine(s: DayStats): string {
  return `Readings: ${String(s.completed)} ✓ · ${String(s.declined)} declined · ${String(s.failed)} failed · ${String(s.refunded)} refunded · ${String(s.crisis)} crisis`;
}

function purchaseCount(s: DayStats): number {
  return Object.values(s.purchases).reduce((a, b) => a + b, 0);
}

function purchasesLine(purchases: Readonly<Record<string, number>>, sandbox: number): string {
  const entries = Object.entries(purchases).sort(([a, x], [b, y]) => y - x || a.localeCompare(b));
  const total = entries.reduce((sum, [, n]) => sum + n, 0);
  const detail =
    entries.length === 0
      ? ''
      : ` (${entries.map(([id, n]) => `${String(n)}× ${id.replace(PRODUCT_PREFIX, '')}`).join(', ')})`;
  return `Purchases: ${String(total)}${detail}${sandbox > 0 ? ` · sandbox ${String(sandbox)}` : ''}`;
}

function sumDays(days: readonly DayStats[], label: string): DayStats {
  const purchases: Record<string, number> = {};
  let total: DayStats = {
    day: label,
    completed: 0,
    declined: 0,
    failed: 0,
    refunded: 0,
    crisis: 0,
    completedCostMicroUsd: 0,
    costedCompleted: 0,
    spendMicroUsd: 0,
    newInstalls: 0,
    active: 0,
    purchases,
    sandboxPurchases: 0,
    refunds: 0,
    rewarded: 0,
  };
  for (const s of days) {
    for (const [id, n] of Object.entries(s.purchases)) {
      purchases[id] = (purchases[id] ?? 0) + n;
    }
    total = {
      ...total,
      completed: total.completed + s.completed,
      declined: total.declined + s.declined,
      failed: total.failed + s.failed,
      refunded: total.refunded + s.refunded,
      crisis: total.crisis + s.crisis,
      completedCostMicroUsd: total.completedCostMicroUsd + s.completedCostMicroUsd,
      costedCompleted: total.costedCompleted + s.costedCompleted,
      spendMicroUsd: total.spendMicroUsd + s.spendMicroUsd,
      newInstalls: total.newInstalls + s.newInstalls,
      active: total.active + s.active,
      sandboxPurchases: total.sandboxPurchases + s.sandboxPurchases,
      refunds: total.refunds + s.refunds,
      rewarded: total.rewarded + s.rewarded,
    };
  }
  return total;
}
