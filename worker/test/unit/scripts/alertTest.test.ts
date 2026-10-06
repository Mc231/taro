import { describe, expect, it } from 'vitest';
import { main as alertTest } from '../../../scripts/alert-test';
import type { FetchFn } from '../../../src/adapters/cf/WebhookAlerter';
import type { CliDeps, CommandResult } from '../../../src/admin/cli';
import { FixedClock } from '../../fakes/FixedClock';

const TOKEN = '123456:AAFakeBotToken_xyz';
const TELEGRAM_URL = `https://api.telegram.org/bot${TOKEN}/sendMessage?chat_id=42`;

class StubCli implements CliDeps {
  readonly stdout: string[] = [];
  readonly stderr: string[] = [];

  constructor(readonly env: Readonly<Record<string, string | undefined>> = {}) {}

  readFile(): Promise<string> {
    return Promise.reject(new Error('alert-test reads no files'));
  }

  writeFile(): Promise<void> {
    return Promise.reject(new Error('alert-test writes no files'));
  }

  out(line: string): void {
    this.stdout.push(line);
  }

  err(line: string): void {
    this.stderr.push(line);
  }

  run(): Promise<CommandResult> {
    return Promise.reject(new Error('alert-test runs no commands'));
  }

  all(): string {
    return [...this.stdout, ...this.stderr].join('\n');
  }
}

function recordingFetch(response: Response | Error) {
  const calls: { url: string; body: string }[] = [];
  const fetchFn: FetchFn = (url, init) => {
    calls.push({ url, body: init.body as string });
    return response instanceof Error ? Promise.reject(response) : Promise.resolve(response);
  };
  return { calls, fetchFn };
}

const clock = new FixedClock('2026-10-06T08:00:00Z');

describe('scripts/alert-test.ts', () => {
  it('sends one alert_test message to Telegram with the environment, never printing the URL', async () => {
    const cli = new StubCli({ ALERT_WEBHOOK_URL: ` ${TELEGRAM_URL} ` });
    const { calls, fetchFn } = recordingFetch(new Response('{"ok":true}'));

    expect(await alertTest(['--env', 'staging'], cli, fetchFn, clock)).toBe(0);

    expect(calls).toHaveLength(1);
    expect(calls[0]?.url).toBe(`https://api.telegram.org/bot${TOKEN}/sendMessage`);
    expect(JSON.parse(calls[0]?.body ?? '')).toEqual({
      chat_id: '42',
      text: '🔔 taro-api (staging) — alert_test\nTest alert: the alert channel works.\nsentAt: 2026-10-06T08:00:00.000Z',
      disable_web_page_preview: true,
    });
    expect(cli.stdout.at(-1)).toBe('ok   test alert (staging) sent via telegram');
    expect(cli.all()).not.toContain(TOKEN);
  });

  it('uses the Slack-style body for a generic webhook', async () => {
    const cli = new StubCli({ ALERT_WEBHOOK_URL: 'https://hooks.example/secret-path' });
    const { calls, fetchFn } = recordingFetch(new Response('ok'));

    expect(await alertTest(['--env=prod'], cli, fetchFn, clock)).toBe(0);
    expect(JSON.parse(calls[0]?.body ?? '')).toMatchObject({
      text: '[taro-api] alert_test: Test alert: the alert channel works.',
    });
    expect(cli.stdout.at(-1)).toBe('ok   test alert (prod) sent via webhook');
    expect(cli.all()).not.toContain('secret-path');
  });

  it('exits 1 on a failed delivery without printing the URL', async () => {
    const cli = new StubCli({ ALERT_WEBHOOK_URL: TELEGRAM_URL });
    const { fetchFn } = recordingFetch(new Response('{"ok":false}', { status: 400 }));

    expect(await alertTest(['--env', 'dev'], cli, fetchFn, clock)).toBe(1);
    expect(cli.stderr).toEqual([
      'error alert_failed {"kind":"alert_test","status":400}',
      'FAIL test alert (dev) via telegram',
    ]);
    expect(cli.all()).not.toContain(TOKEN);
  });

  it('exits 2 on usage errors or a missing URL', async () => {
    const { calls, fetchFn } = recordingFetch(new Response('ok'));
    for (const [argv, env, message] of [
      [['--bogus'], { ALERT_WEBHOOK_URL: TELEGRAM_URL }, 'unknown argument --bogus'],
      [[], { ALERT_WEBHOOK_URL: TELEGRAM_URL }, '--env must be one of dev, staging, prod'],
      [['--env', 'qa'], { ALERT_WEBHOOK_URL: TELEGRAM_URL }, '--env must be one of'],
      [['--env', 'staging'], {}, 'ALERT_WEBHOOK_URL is not set'],
      [['--env', 'staging'], { ALERT_WEBHOOK_URL: '  ' }, 'ALERT_WEBHOOK_URL is not set'],
    ] as const) {
      const cli = new StubCli(env);
      expect(await alertTest(argv, cli, fetchFn, clock)).toBe(2);
      expect(cli.stderr[0]).toContain(message);
    }
    const noEnv = new StubCli();
    Object.defineProperty(noEnv, 'env', { value: undefined });
    expect(await alertTest(['--env', 'dev'], noEnv, fetchFn, clock)).toBe(2);
    expect(calls).toHaveLength(0);
  });
});
