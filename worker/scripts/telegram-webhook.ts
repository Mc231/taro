import { parseTelegramUrl, type FetchFn } from '../src/adapters/cf/WebhookAlerter';
import { parseArgs, type CliDeps } from '../src/admin/cli';
import { API_HOSTS } from '../src/admin/smoke';
import { TELEGRAM_ROUTE } from '../src/routes/telegram';
import { STATS_COMMAND_HELP, STATS_COMMANDS } from '../src/services/TelegramStatsService';

/**
 * `npm run telegram:webhook -- --env <staging|prod> [--commands]`
 *
 * Points the owner's stats bot (@taro_alerts_vsh_bot) at the Worker
 * (03 §14.3): Telegram `setWebhook` with
 * `url = https://<API_HOST>/v1/admin/telegram`, `secret_token` =
 * `TELEGRAM_WEBHOOK_SECRET`, `allowed_updates = ["message"]` and
 * `drop_pending_updates = true`. With `--commands` it also sets the bot's
 * command menu (`setMyCommands`: /today, /week, /budget, /help).
 *
 * The bot token comes from `ALERT_WEBHOOK_URL` and the secret from
 * `TELEGRAM_WEBHOOK_SECRET`, both from the shell environment only (never
 * argv), and neither is ever printed. Exit codes: 0 done, 1 Telegram
 * refused or the request failed, 2 usage or a missing/invalid variable.
 */
export const USAGE = [
  'usage: ALERT_WEBHOOK_URL=… TELEGRAM_WEBHOOK_SECRET=… telegram-webhook --env <staging|prod> [--commands]',
  '  ALERT_WEBHOOK_URL (env only): https://api.telegram.org/bot<TOKEN>/sendMessage?chat_id=<ID>',
  '  TELEGRAM_WEBHOOK_SECRET (env only): 1-256 of A-Z a-z 0-9 _ - (same value as the Worker secret)',
  '  --commands: also set the bot command menu (setMyCommands)',
].join('\n');

const ENVIRONMENTS = ['staging', 'prod'] as const;
type BotEnvironment = (typeof ENVIRONMENTS)[number];

/** Telegram's `secret_token` alphabet and length. */
export const SECRET_TOKEN_RE = /^[A-Za-z0-9_-]{1,256}$/;

interface TelegramReply {
  readonly ok?: boolean;
  readonly description?: string;
}

export async function main(
  argv: readonly string[],
  deps: CliDeps,
  fetchFn: FetchFn = (url, init) => fetch(url, init),
): Promise<number> {
  const args = parseArgs(argv, { flags: ['--commands'], options: ['--env'] });
  if (!args.ok) {
    deps.err(`${args.error}\n${USAGE}`);
    return 2;
  }
  const environment = args.options.get('--env') as BotEnvironment | undefined;
  if (environment === undefined || !ENVIRONMENTS.includes(environment)) {
    deps.err(`--env must be one of ${ENVIRONMENTS.join(', ')}\n${USAGE}`);
    return 2;
  }
  const target = parseTelegramUrl(deps.env?.['ALERT_WEBHOOK_URL']?.trim() ?? '');
  if (target === undefined) {
    deps.err(`ALERT_WEBHOOK_URL is not set or not a Telegram sendMessage URL\n${USAGE}`);
    return 2;
  }
  const secret = deps.env?.['TELEGRAM_WEBHOOK_SECRET']?.trim() ?? '';
  if (!SECRET_TOKEN_RE.test(secret)) {
    deps.err(`TELEGRAM_WEBHOOK_SECRET is not set or invalid\n${USAGE}`);
    return 2;
  }
  const api = target.endpoint.replace(/\/sendMessage$/, '');
  const webhookUrl = `${API_HOSTS[environment]}${TELEGRAM_ROUTE}`;
  const call = async (method: string, body: unknown): Promise<boolean> => {
    try {
      const res = await fetchFn(`${api}/${method}`, {
        method: 'POST',
        headers: { 'content-type': 'application/json' },
        body: JSON.stringify(body),
      });
      const reply = (await res.json().catch(() => ({}))) as TelegramReply;
      if (res.ok && reply.ok === true) {
        return true;
      }
      deps.err(`FAIL ${method}: HTTP ${String(res.status)} ${reply.description ?? ''}`.trimEnd());
    } catch (err) {
      deps.err(`FAIL ${method}: ${err instanceof Error ? err.name : 'unknown error'}`);
    }
    return false;
  };
  const webhookSet = await call('setWebhook', {
    url: webhookUrl,
    secret_token: secret,
    allowed_updates: ['message'],
    drop_pending_updates: true,
  });
  if (!webhookSet) {
    return 1;
  }
  deps.out(`ok   webhook (${environment}) → ${webhookUrl}`);
  if (args.flags.has('--commands')) {
    const commandsSet = await call('setMyCommands', {
      commands: STATS_COMMANDS.map((command) => ({
        command,
        description: STATS_COMMAND_HELP[command],
      })),
    });
    if (!commandsSet) {
      return 1;
    }
    deps.out(`ok   commands: ${STATS_COMMANDS.map((c) => `/${c}`).join(' ')}`);
  }
  return 0;
}
