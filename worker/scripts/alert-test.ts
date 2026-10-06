import { SystemClock } from '../src/adapters/cf/SystemClock';
import { parseTelegramUrl, WebhookAlerter, type FetchFn } from '../src/adapters/cf/WebhookAlerter';
import { parseArgs, type CliDeps } from '../src/admin/cli';
import type { Environment } from '../src/env';
import type { Clock } from '../src/ports/Clock';
import type { LogFields, LogLevel, Logger } from '../src/ports/Logger';

/**
 * `ALERT_WEBHOOK_URL=… npm run alert:test -- --env <dev|staging|prod>`
 *
 * Sends one `alert_test` alert through the production `WebhookAlerter`
 * (Telegram or Slack-style, same format as the Worker) to the URL in the
 * `ALERT_WEBHOOK_URL` environment variable. The URL is read from the
 * environment only (it holds the bot token), never from argv or wrangler
 * secrets, and is never printed. No dedupe. Exit codes: 0 sent, 1 the
 * delivery failed, 2 usage or a missing URL.
 */
export const USAGE = [
  'usage: ALERT_WEBHOOK_URL=… alert-test --env <dev|staging|prod>',
  '  ALERT_WEBHOOK_URL (env only): the Telegram sendMessage URL or a webhook URL',
].join('\n');

const ENVIRONMENTS: readonly Environment[] = ['dev', 'staging', 'prod'];

/** Forwards the alerter's log lines to the CLI (they never contain the URL). */
class CliLogger implements Logger {
  failed = false;

  constructor(private readonly deps: CliDeps) {}

  log(level: LogLevel, event: string, fields: LogFields = {}): void {
    if (event === 'alert_failed') {
      this.failed = true;
    }
    const line = `${level} ${event} ${JSON.stringify(fields)}`;
    if (level === 'error') {
      this.deps.err(line);
    } else {
      this.deps.out(line);
    }
  }
}

export async function main(
  argv: readonly string[],
  deps: CliDeps,
  fetchFn: FetchFn = (url, init) => fetch(url, init),
  clock: Clock = new SystemClock(),
): Promise<number> {
  const args = parseArgs(argv, { flags: [], options: ['--env'] });
  if (!args.ok) {
    deps.err(`${args.error}\n${USAGE}`);
    return 2;
  }
  const environment = args.options.get('--env') as Environment | undefined;
  if (environment === undefined || !ENVIRONMENTS.includes(environment)) {
    deps.err(`--env must be one of ${ENVIRONMENTS.join(', ')}\n${USAGE}`);
    return 2;
  }
  const url = deps.env?.['ALERT_WEBHOOK_URL']?.trim() ?? '';
  if (url === '') {
    deps.err(`ALERT_WEBHOOK_URL is not set\n${USAGE}`);
    return 2;
  }
  const logger = new CliLogger(deps);
  await new WebhookAlerter(fetchFn, url, logger, undefined, environment).send({
    kind: 'alert_test',
    message: 'Test alert: the alert channel works.',
    fields: { sentAt: clock.now().toISOString() },
  });
  const sink = parseTelegramUrl(url) === undefined ? 'webhook' : 'telegram';
  if (logger.failed) {
    deps.err(`FAIL test alert (${environment}) via ${sink}`);
    return 1;
  }
  deps.out(`ok   test alert (${environment}) sent via ${sink}`);
  return 0;
}
