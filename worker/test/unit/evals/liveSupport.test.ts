import { describe, expect, it } from 'vitest';
import qualityText from '../../../evals/cases/quality.jsonl?raw';
import safetyText from '../../../evals/safety/prompts.jsonl?raw';
import {
  callsUsd,
  estimateTokens,
  evalPrice,
  SpendGuard,
  typicalUsd,
  usd,
  worstCaseUsd,
} from '../../../evals/lib/cost';
import { parseCase, parseCases } from '../../../evals/lib/io';
import {
  anthropicJudge,
  judgeJsonl,
  judgeMarkdown,
  judgeMessage,
  judgeReading,
  makeJudge,
  openAiJudge,
  parseJudge,
  type JudgeClient,
} from '../../../evals/lib/judge';
import { l1Probe, selectSample, SMOKE_QUOTAS, SMOKE_SPREADS } from '../../../evals/lib/sample';
import { LOCALES, REFUSAL_CATEGORIES } from '../../../evals/lib/types';
import { cardNames } from '../../../evals/lib/cli';
import { AiFetch, hang } from '../../helpers/aiFixtures';
import { evalCase } from './helpers';

const PRICE = { input: 2, output: 10, cacheRead: 0.2, cacheWrite: 2.5 };

describe('cost', () => {
  it('estimates tokens and the worst / typical spend', () => {
    expect(estimateTokens('abcdefg')).toBe(3);
    expect(worstCaseUsd(1000, 4000, PRICE, false)).toBeCloseTo(0.104);
    expect(worstCaseUsd(1000, 4000, PRICE, true)).toBeCloseTo(0.208);
    expect(typicalUsd(3000, 1000, 4000, PRICE)).toBeCloseTo(0.0186);
    expect(evalPrice('anthropic', 'claude-sonnet-5')).toEqual(PRICE);
    expect(evalPrice('openai', 'unknown').output).toBeGreaterThanOrEqual(25);
    expect(evalPrice('anthropic', 'claude-sonnet-5', true)).toEqual({
      input: 4,
      output: 20,
      cacheRead: 0.4,
      cacheWrite: 5,
    });
    expect(usd(0.5)).toBe('$0.5000');
    expect(usd(12.345)).toBe('$12.35');
  });

  it('prices calls with the Worker table and logs unknown models', () => {
    const logged: string[] = [];
    const logger = { log: (_l: string, event: string) => logged.push(event) };
    const usage = {
      inputTokens: 1000,
      outputTokens: 1000,
      cacheReadTokens: 0,
      cacheWriteTokens: 0,
    };
    expect(
      callsUsd([{ provider: 'anthropic', model: 'claude-sonnet-5', usage }], logger),
    ).toBeCloseTo(0.012);
    expect(
      callsUsd([{ provider: 'anthropic', model: 'claude-sonnet-5', usage, fast: true }], logger),
    ).toBeCloseTo(0.024);
    callsUsd([{ provider: 'openai', model: 'nope', usage }], logger);
    expect(logged).toEqual(['pricing_unknown']);
  });

  it('books worst cases, settles real costs and waits for bookings', async () => {
    const guard = new SpendGuard(1);
    expect(guard.reserve(0.6)).toBe(true);
    expect(guard.reserve(0.6)).toBe(false);
    const waiting = guard.acquire(0.6);
    guard.settle(0.6, 0.1);
    expect(await waiting).toBe(true);
    expect(guard.spent).toBeCloseTo(0.1);
    guard.settle(0.6, 0.5);
    expect(await guard.acquire(0.6)).toBe(false);
  });
});

describe('case parsing aliases', () => {
  it('reads the safety file `text` and the `spreadId` key', () => {
    expect(
      parseCase({ id: 'a', locale: 'en', category: 'none', text: 'Hi?', spreadId: 'single' }),
    ).toMatchObject({ question: 'Hi?', spreadId: 'single' });
    expect(
      parseCase({ id: 'b', locale: 'en', expect: { classification: 'gambling', notes: 'n' } }),
    ).toMatchObject({ expectedCategory: 'gambling', expectedOutcome: 'rephrase' });
    const parsed = parseCases(
      [
        JSON.stringify({ id: 'long', locale: 'en', expect: { httpStatus: 400 } }),
        JSON.stringify({ locale: 'en', expect: { httpStatus: 400 } }),
        JSON.stringify({ id: 'ok', locale: 'en', expect: { classification: 'none' } }),
      ].join('\n'),
      'q.jsonl',
    );
    expect(parsed.items.map((c) => c.id)).toEqual(['ok']);
    expect(parsed.skipped).toEqual(['long', 'q.jsonl:2']);
    expect(parsed.errors).toEqual([]);
  });
});

describe('smoke sample', () => {
  it('covers every locale, spread, category and probe kind from the committed suites', () => {
    const cases = [
      ...parseCases(safetyText, 'safety').items,
      ...parseCases(qualityText, 'quality').items,
    ];
    const sample = selectSample(cases);
    expect(sample.unmet).toEqual({});
    expect(sample.cases.length).toBeGreaterThanOrEqual(40);
    expect(sample.cases.length).toBeLessThanOrEqual(60);
    const has = (pred: (c: (typeof sample.cases)[number]) => boolean) => sample.cases.some(pred);
    for (const locale of LOCALES) {
      expect(has((c) => c.locale === locale)).toBe(true);
    }
    for (const spread of SMOKE_SPREADS) {
      expect(has((c) => c.spreadId === spread)).toBe(true);
    }
    for (const category of REFUSAL_CATEGORIES) {
      expect(has((c) => c.expectedCategory === category)).toBe(true);
    }
    for (const kind of ['benign_tricky', 'jailbreak', 'injection']) {
      expect(has((c) => c.kind === kind)).toBe(true);
    }
    expect(has((c) => l1Probe(c) === 'hint')).toBe(true);
    expect(has((c) => l1Probe(c) === 'block')).toBe(true);
    // Deterministic.
    expect(selectSample(cases).cases.map((c) => c.id)).toEqual(sample.cases.map((c) => c.id));
  });

  it('skips cases that cannot run live and reports unmet quotas', () => {
    const sample = selectSample(
      [evalCase({ id: 'x', cards: null }), evalCase({ id: 'y' })],
      SMOKE_QUOTAS,
      () => 'pass',
    );
    expect(sample.cases.map((c) => c.id)).toEqual(['y']);
    expect(sample.unmet['locale:de']).toBe(4);
    expect(l1Probe(evalCase({ question: null }))).toBe('pass');
  });
});

function jsonResponse(status: number, body: unknown): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { 'content-type': 'application/json' },
  });
}

const READING = {
  classification: 'none' as const,
  title: 'T',
  overview: 'O',
  cards: [
    { positionId: 'past', cardId: 'major_16', reversed: false, interpretation: 'I' },
    { positionId: 'present', cardId: 'cups_03', reversed: true, interpretation: 'I' },
    { positionId: 'future', cardId: 'pentacles_14', reversed: false, interpretation: 'I' },
  ],
  synthesis: 'S',
  reflectionPrompts: ['P'],
};

describe('LLM judge', () => {
  it('calls the Anthropic Messages API and normalises usage', async () => {
    const stub = new AiFetch([
      () =>
        jsonResponse(200, {
          model: 'claude-haiku-4-5',
          content: [
            { type: 'thinking', thinking: '…' },
            { type: 'text', text: '{"tone":4,"coherence":5,"fidelity":4}' },
          ],
          usage: { input_tokens: 10, output_tokens: 5, cache_read_input_tokens: 2 },
        }),
      () => jsonResponse(529, { type: 'error' }),
      () => jsonResponse(200, { content: [] }),
    ]);
    const judge = anthropicJudge('k', 'claude-haiku-4-5', stub.fetch);
    expect(await judge('sys', 'user')).toEqual({
      kind: 'ok',
      text: '{"tone":4,"coherence":5,"fidelity":4}',
      call: {
        provider: 'anthropic',
        model: 'claude-haiku-4-5',
        usage: { inputTokens: 10, outputTokens: 5, cacheReadTokens: 2, cacheWriteTokens: 0 },
      },
    });
    expect(stub.requests[0]?.url).toBe('https://api.anthropic.com/v1/messages');
    expect(stub.requests[0]?.headers.get('x-api-key')).toBe('k');
    expect(stub.requests[0]?.body).toMatchObject({ model: 'claude-haiku-4-5', system: 'sys' });
    expect(await judge('s', 'u')).toEqual({ kind: 'error', detail: 'http 529' });
    const noUsage = await judge('s', 'u');
    expect(noUsage).toMatchObject({ kind: 'ok', text: '', call: { model: 'claude-haiku-4-5' } });
  });

  it('calls the OpenAI Responses API and subtracts cached tokens', async () => {
    const stub = new AiFetch([
      () =>
        jsonResponse(200, {
          model: 'gpt-6-luna',
          output: [
            { type: 'reasoning' },
            { type: 'message', content: [{ type: 'output_text', text: 'ok' }, { type: 'x' }] },
            { type: 'message' },
          ],
          usage: {
            input_tokens: 100,
            output_tokens: 7,
            input_tokens_details: { cached_tokens: 40, cache_write_tokens: 10 },
          },
        }),
      () => jsonResponse(200, { output: [] }),
      () => jsonResponse(400, { error: {} }),
      () => Promise.reject(new Error('offline')),
    ]);
    const judge = openAiJudge('k', 'gpt-6-luna', stub.fetch);
    expect(await judge('sys', 'user')).toEqual({
      kind: 'ok',
      text: 'ok',
      call: {
        provider: 'openai',
        model: 'gpt-6-luna',
        usage: { inputTokens: 50, outputTokens: 7, cacheReadTokens: 40, cacheWriteTokens: 10 },
      },
    });
    expect(stub.requests[0]?.headers.get('authorization')).toBe('Bearer k');
    expect(stub.requests[0]?.body).toMatchObject({
      store: false,
      model: 'gpt-6-luna',
      reasoning: { effort: 'low' },
      max_output_tokens: 2000,
    });
    expect(await judge('s', 'u')).toMatchObject({
      kind: 'ok',
      call: { usage: { inputTokens: 0 } },
    });
    expect(await judge('s', 'u')).toEqual({ kind: 'error', detail: 'http 400' });
    expect(await judge('s', 'u')).toEqual({ kind: 'error', detail: 'network' });
  });

  it('times out a hanging call', async () => {
    const stub = new AiFetch([hang, () => new Response('not json', { status: 200 })]);
    expect(await openAiJudge('k', 'm', stub.fetch, 5)('s', 'u')).toEqual({
      kind: 'error',
      detail: 'timeout',
    });
    // No reasoning parameter for a model without one.
    expect(stub.requests[0]?.body['reasoning']).toBeUndefined();
    expect(await anthropicJudge('k', 'm', stub.fetch)('s', 'u')).toEqual({
      kind: 'error',
      detail: 'http 200',
    });
  });

  it('picks the vendor client', async () => {
    const stub = new AiFetch([() => jsonResponse(500, {}), () => jsonResponse(500, {})]);
    await makeJudge('anthropic', 'k', 'm', stub.fetch)('s', 'u');
    await makeJudge('openai', 'k', 'm', stub.fetch)('s', 'u');
    expect(stub.requests.map((r) => new URL(r.url).pathname)).toEqual([
      '/v1/messages',
      '/v1/responses',
    ]);
  });

  it('parses scores strictly', () => {
    const full = '"tone":5,"coherence":4,"fidelity":3,"clarity":2,"answerFirst":true';
    expect(parseJudge(`Sure: {${full},"notes":"n"} done`)).toEqual({
      tone: 5,
      coherence: 4,
      fidelity: 3,
      clarity: 2,
      answerFirst: true,
      notes: 'n',
    });
    expect(parseJudge(`{${full}}`)?.notes).toBe('');
    // Clarity and answer-first are required (prompt v2 criteria).
    expect(parseJudge('{"tone":5,"coherence":4,"fidelity":3}')).toBeNull();
    expect(
      parseJudge('{"tone":5,"coherence":4,"fidelity":3,"clarity":4,"answerFirst":"yes"}'),
    ).toBeNull();
    expect(
      parseJudge('{"tone":5,"coherence":4,"fidelity":3,"clarity":0,"answerFirst":false}'),
    ).toBeNull();
    expect(parseJudge('no json')).toBeNull();
    expect(parseJudge('{bad json}')).toBeNull();
    expect(parseJudge('[1]')).toBeNull();
    expect(parseJudge('{"tone":6,"coherence":4,"fidelity":3}')).toBeNull();
    expect(parseJudge('{"tone":5,"coherence":"4","fidelity":3}')).toBeNull();
    expect(parseJudge('{"tone":5,"coherence":4}')).toBeNull();
  });

  it('builds the message from the case and grades a reading', async () => {
    const c = evalCase({ question: '  ' });
    const message = judgeMessage(c, READING, cardNames());
    expect(message).toContain('Question: (none)');
    expect(message).toContain('- present: Three of Cups (reversed)');
    expect(judgeMessage(evalCase({ cards: null, spreadId: null }), READING, new Map())).toContain(
      'Spread: unknown.',
    );
    const call = {
      provider: 'openai' as const,
      model: 'm',
      usage: { inputTokens: 1, outputTokens: 1, cacheReadTokens: 0, cacheWriteTokens: 0 },
    };
    const replies: Awaited<ReturnType<JudgeClient>>[] = [
      {
        kind: 'ok',
        text: '{"tone":2,"coherence":2,"fidelity":2,"clarity":2,"answerFirst":false,"notes":"flat"}',
        call,
      },
      { kind: 'ok', text: 'nope', call },
      { kind: 'error', detail: 'timeout' },
    ];
    const client: JudgeClient = () =>
      Promise.resolve(replies.shift() ?? { kind: 'error', detail: 'x' });
    const ok = await judgeReading(client, c, READING, cardNames());
    expect(ok).toMatchObject({ kind: 'ok', scores: { tone: 2 }, calls: [call] });
    expect(await judgeReading(client, c, READING, cardNames())).toEqual({
      kind: 'error',
      detail: 'unparseable judge answer',
      calls: [call],
    });
    expect(await judgeReading(client, c, READING, cardNames())).toEqual({
      kind: 'error',
      detail: 'timeout',
      calls: [],
    });
    const md = judgeMarkdown(
      [
        { id: 'a', locale: 'en', outcome: ok },
        {
          id: 'b',
          locale: 'de',
          outcome: {
            kind: 'ok',
            scores: {
              tone: 5,
              coherence: 5,
              fidelity: 5,
              clarity: 5,
              answerFirst: true,
              notes: '',
            },
            calls: [],
          },
        },
        { id: 'c', locale: 'fr', outcome: { kind: 'error', detail: 'x', calls: [] } },
      ],
      'm',
    ).join('\n');
    expect(md).toContain('2 answered readings scored, 1 judge errors');
    expect(md).toContain('| tone | 3.50 |');
    expect(md).toContain('| clarity | 3.50 |');
    expect(md).toContain('first sentence answers the question): 50.0 % (1/2).');
    expect(md).toContain(
      '- `a` (en): tone 2, coherence 2, fidelity 2, clarity 2, not answer-first. flat',
    );
    expect(md).not.toContain('`b`');
    expect(judgeMarkdown([], 'm').join('\n')).toContain('| tone | – |');
    expect(judgeMarkdown([], 'm').join('\n')).toContain('the question): –.');
    const lines = judgeJsonl([
      { id: 'a', locale: 'en', outcome: ok },
      { id: 'c', locale: 'fr', outcome: { kind: 'error', detail: 'x', calls: [] } },
    ])
      .trimEnd()
      .split('\n')
      .map((line) => JSON.parse(line) as Record<string, unknown>);
    expect(lines[0]).toMatchObject({ id: 'a', clarity: 2, answerFirst: false });
    expect(lines[1]).toEqual({ id: 'c', locale: 'fr', error: 'x' });
  });
});
