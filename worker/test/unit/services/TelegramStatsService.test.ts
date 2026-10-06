import { describe, expect, it } from 'vitest';
import { telegramBotDeps } from '../../../src/routes/telegram';
import { parseStatsCommand, STATS_COMMANDS } from '../../../src/services/TelegramStatsService';

const URL_ = 'https://api.telegram.org/bot123:abc/sendMessage?chat_id=577000001';
const noFetch = () => Promise.reject(new TypeError('unused'));

describe('parseStatsCommand', () => {
  it.each([
    ['/today', 'today'],
    ['  /WEEK  extra words', 'week'],
    ['/budget@taro_alerts_vsh_bot', 'budget'],
    ['/Help@Taro_Alerts_Vsh_Bot', 'help'],
    ['/start', 'help'],
  ])('%j → %s', (text, command) => {
    expect(parseStatsCommand(text)).toBe(command);
  });

  it.each(['', 'today', '/stats', '/today@', '/to-day', 'hi /today'])('%j → undefined', (text) => {
    expect(parseStatsCommand(text)).toBeUndefined();
  });

  it('knows exactly the four read-only commands', () => {
    expect(STATS_COMMANDS).toEqual(['today', 'week', 'budget', 'help']);
  });
});

describe('telegramBotDeps', () => {
  it('takes the reply target and default chat from ALERT_WEBHOOK_URL', () => {
    const deps = telegramBotDeps(
      { ALERT_WEBHOOK_URL: ` ${URL_} `, TELEGRAM_WEBHOOK_SECRET: ' s3cret ' },
      noFetch,
    );
    expect(deps.target).toEqual({
      endpoint: 'https://api.telegram.org/bot123:abc/sendMessage',
      chatId: '577000001',
    });
    expect(deps.adminChatIds).toEqual(['577000001']);
    expect(deps.webhookSecret).toBe('s3cret');
    expect(deps.fetch).toBe(noFetch);
  });

  it('adds TELEGRAM_ADMIN_CHAT_IDS, dropping blanks, junk and duplicates', () => {
    const deps = telegramBotDeps(
      {
        ALERT_WEBHOOK_URL: URL_,
        TELEGRAM_ADMIN_CHAT_IDS: '-1001234567890, 577000001,,abc, 42',
      },
      noFetch,
    );
    expect(deps.adminChatIds).toEqual(['577000001', '-1001234567890', '42']);
  });

  it('without a Telegram URL or secret: no target, no secret', () => {
    const deps = telegramBotDeps(
      { ALERT_WEBHOOK_URL: 'https://hooks.example.com/x', TELEGRAM_WEBHOOK_SECRET: '  ' },
      noFetch,
    );
    expect(deps.target).toBeUndefined();
    expect(deps.webhookSecret).toBeUndefined();
    expect(deps.adminChatIds).toEqual([]);
    expect(telegramBotDeps({}, noFetch)).toMatchObject({
      target: undefined,
      webhookSecret: undefined,
      adminChatIds: [],
    });
  });
});
