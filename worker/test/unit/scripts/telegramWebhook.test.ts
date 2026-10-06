import { describe, expect, it } from 'vitest';
import { main as telegramWebhook } from '../../../scripts/telegram-webhook';
import type { FetchFn } from '../../../src/adapters/cf/WebhookAlerter';
import type { CliDeps, CommandResult } from '../../../src/admin/cli';

const TOKEN = '123456:AAFakeBotToken_xyz';
const URL_ = `https://api.telegram.org/bot${TOKEN}/sendMessage?chat_id=42`;
const SECRET = 'fake_webhook-Secret_0123456789';
const ENV = { ALERT_WEBHOOK_URL: ` ${URL_} `, TELEGRAM_WEBHOOK_SECRET: SECRET };

class StubCli implements CliDeps {
  readonly stdout: string[] = [];
  readonly stderr: string[] = [];

  constructor(readonly env: Readonly<Record<string, string | undefined>> = ENV) {}

  readFile(): Promise<string> {
    return Promise.reject(new Error('reads no files'));
  }

  writeFile(): Promise<void> {
    return Promise.reject(new Error('writes no files'));
  }

  out(line: string): void {
    this.stdout.push(line);
  }

  err(line: string): void {
    this.stderr.push(line);
  }

  run(): Promise<CommandResult> {
    return Promise.reject(new Error('runs no commands'));
  }

  all(): string {
    return [...this.stdout, ...this.stderr].join('\n');
  }
}

function recordingFetch(...responses: (Response | Error)[]) {
  const calls: { url: string; body: Record<string, unknown> }[] = [];
  const fetchFn: FetchFn = (url, init) => {
    calls.push({ url, body: JSON.parse(init.body as string) as Record<string, unknown> });
    const next = responses.shift() ?? new Response('{"ok":true}');
    return next instanceof Error ? Promise.reject(next) : Promise.resolve(next);
  };
  return { calls, fetchFn };
}

function expectNoSecrets(cli: StubCli): void {
  expect(cli.all()).not.toContain(TOKEN);
  expect(cli.all()).not.toContain(SECRET);
  expect(cli.all()).not.toMatch(/api\.telegram\.org\/bot\d/);
}

describe('scripts/telegram-webhook.ts', () => {
  it('sets the staging webhook with the secret, message updates only, dropping pending ones', async () => {
    const cli = new StubCli();
    const { calls, fetchFn } = recordingFetch();
    expect(await telegramWebhook(['--env', 'staging'], cli, fetchFn)).toBe(0);
    expect(calls).toEqual([
      {
        url: `https://api.telegram.org/bot${TOKEN}/setWebhook`,
        body: {
          url: 'https://api-staging.taro.vshyrochuk.com/v1/admin/telegram',
          secret_token: SECRET,
          allowed_updates: ['message'],
          drop_pending_updates: true,
        },
      },
    ]);
    expect(cli.stdout).toEqual([
      'ok   webhook (staging) → https://api-staging.taro.vshyrochuk.com/v1/admin/telegram',
    ]);
    expectNoSecrets(cli);
  });

  it('prod with --commands also sets the four commands', async () => {
    const cli = new StubCli();
    const { calls, fetchFn } = recordingFetch();
    expect(await telegramWebhook(['--env=prod', '--commands'], cli, fetchFn)).toBe(0);
    expect(calls[0]?.body['url']).toBe('https://api.taro.vshyrochuk.com/v1/admin/telegram');
    expect(calls[1]?.url).toBe(`https://api.telegram.org/bot${TOKEN}/setMyCommands`);
    const commands = calls[1]?.body['commands'] as { command: string }[];
    expect(commands.map((c) => c.command)).toEqual(['today', 'week', 'budget', 'help']);
    expect(cli.stdout[1]).toBe('ok   commands: /today /week /budget /help');
    expectNoSecrets(cli);
  });

  it.each([
    [[], '--env must be one of staging, prod'],
    [['--env', 'dev'], '--env must be one of staging, prod'],
    [['--bogus'], 'unknown argument --bogus'],
  ])('usage error %j → exit 2', async (argv, message) => {
    const cli = new StubCli();
    expect(await telegramWebhook(argv, cli, recordingFetch().fetchFn)).toBe(2);
    expect(cli.stderr.join('\n')).toContain(message);
  });

  it.each([
    [{ TELEGRAM_WEBHOOK_SECRET: SECRET }, 'ALERT_WEBHOOK_URL is not set'],
    [
      { ALERT_WEBHOOK_URL: 'https://hooks.example.com/x', TELEGRAM_WEBHOOK_SECRET: SECRET },
      'not a Telegram sendMessage URL',
    ],
    [{ ALERT_WEBHOOK_URL: URL_ }, 'TELEGRAM_WEBHOOK_SECRET is not set or invalid'],
    [
      { ALERT_WEBHOOK_URL: URL_, TELEGRAM_WEBHOOK_SECRET: 'has spaces!' },
      'TELEGRAM_WEBHOOK_SECRET is not set or invalid',
    ],
  ])('missing or invalid env → exit 2 (%#)', async (env, message) => {
    const cli = new StubCli(env);
    const { calls, fetchFn } = recordingFetch();
    expect(await telegramWebhook(['--env', 'staging'], cli, fetchFn)).toBe(2);
    expect(cli.stderr.join('\n')).toContain(message);
    expect(calls).toHaveLength(0);
    expectNoSecrets(cli);
  });

  it('no env at all → exit 2', async () => {
    const cli = new StubCli();
    Object.defineProperty(cli, 'env', { value: undefined });
    expect(await telegramWebhook(['--env', 'staging'], cli, recordingFetch().fetchFn)).toBe(2);
  });

  it('Telegram refusing setWebhook → exit 1 with its description', async () => {
    const cli = new StubCli();
    const { fetchFn } = recordingFetch(
      new Response('{"ok":false,"description":"Unauthorized"}', { status: 401 }),
    );
    expect(await telegramWebhook(['--env', 'staging', '--commands'], cli, fetchFn)).toBe(1);
    expect(cli.stderr).toEqual(['FAIL setWebhook: HTTP 401 Unauthorized']);
    expectNoSecrets(cli);
  });

  it('a non-JSON reply or a network error → exit 1', async () => {
    const cli = new StubCli();
    const { fetchFn } = recordingFetch(new Response('<html>', { status: 502 }));
    expect(await telegramWebhook(['--env', 'staging'], cli, fetchFn)).toBe(1);
    expect(cli.stderr).toEqual(['FAIL setWebhook: HTTP 502']);

    const cli2 = new StubCli();
    const network = recordingFetch(new Response('{"ok":true}'), new TypeError('offline'));
    expect(await telegramWebhook(['--env', 'staging', '--commands'], cli2, network.fetchFn)).toBe(
      1,
    );
    expect(cli2.stderr).toEqual(['FAIL setMyCommands: TypeError']);

    const cli3 = new StubCli();
    const notAnError = 'x' as unknown as Error;
    const throwing: FetchFn = () => Promise.reject(notAnError);
    expect(await telegramWebhook(['--env', 'staging'], cli3, throwing)).toBe(1);
    expect(cli3.stderr).toEqual(['FAIL setWebhook: unknown error']);
  });
});
