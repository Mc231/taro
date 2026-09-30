import { describe, expect, it } from 'vitest';
import { main as renderPrompt } from '../../../scripts/render-prompt';
import type { CliDeps, CommandResult } from '../../../src/admin/cli';
import { parseCases, providerView, renderCase } from '../../../src/admin/renderPrompt';
import { systemPrompt } from '../../../src/prompts/build';

class StubCli implements CliDeps {
  readonly files = new Map<string, string>();
  readonly written = new Map<string, string>();
  readonly stdout: string[] = [];
  readonly stderr: string[] = [];

  readFile(path: string): Promise<string> {
    const text = this.files.get(path);
    return text === undefined ? Promise.reject(new Error('ENOENT')) : Promise.resolve(text);
  }

  writeFile(path: string, text: string): Promise<void> {
    this.written.set(path, text);
    return Promise.resolve();
  }

  out(line: string): void {
    this.stdout.push(line);
  }

  err(line: string): void {
    this.stderr.push(line);
  }

  run(): Promise<CommandResult> {
    return Promise.reject(new Error('render-prompt runs no commands'));
  }
}

const SINGLE = {
  id: 'en-single-01',
  locale: 'en',
  spreadId: 'single',
  cards: [{ cardId: 'major_13', reversed: true }],
  question: 'What should I let go of?',
};
const THREE = {
  id: 'de-three',
  locale: 'de',
  spreadId: 'three_ppf',
  cards: [
    { cardId: 'major_16', reversed: false },
    { cardId: 'cups_03', reversed: true },
    { cardId: 'pentacles_14', reversed: false },
  ],
  question: null,
  prefilterHint: 'financial',
  regenerationNote: 'synthesis too long',
  expected: { classification: 'none' },
};

describe('render-prompt CLI', () => {
  it('renders a JSONL file into one provider view per case', async () => {
    const cli = new StubCli();
    cli.files.set('cases.jsonl', `${JSON.stringify(SINGLE)}\n\n${JSON.stringify(THREE)}\n`);
    expect(await renderPrompt(['--cases', 'cases.jsonl', '--out', 'out/'], cli)).toBe(0);
    expect([...cli.written.keys()]).toEqual(['out/en-single-01.txt', 'out/de-three.txt']);
    const text = cli.written.get('out/de-three.txt') ?? '';
    expect(text.startsWith(`=== SYSTEM ===\n${systemPrompt('v1')}\n=== USER ===\n`)).toBe(true);
    expect(text).toContain('<prefilter_hint>financial</prefilter_hint>');
    expect(text).toContain('<regeneration_note>');
    expect(text.endsWith('</user_question>\n\nStep 1')).toBe(false);
    expect(cli.stdout).toEqual(['rendered 2 of 2 case(s) to out (prompt v1)']);
    expect(cli.stderr).toEqual([]);
  });

  it('renders a JSON array or a single JSON case with an explicit version', async () => {
    const cli = new StubCli();
    cli.files.set('cases.json', JSON.stringify([SINGLE]));
    cli.files.set('one.json', JSON.stringify(THREE));
    expect(await renderPrompt(['--cases', 'cases.json', '--out', 'a', '--prompt', 'v1'], cli)).toBe(
      0,
    );
    expect(await renderPrompt(['--cases=one.json', '--out=b'], cli)).toBe(0);
    expect([...cli.written.keys()]).toEqual(['a/en-single-01.txt', 'b/de-three.txt']);
  });

  it('reports failed cases, still renders the others and exits 1', async () => {
    const cli = new StubCli();
    const bad = { ...SINGLE, id: 'bad', spreadId: 'nine_card' };
    const tooMany = { ...SINGLE, id: 'too-many', cards: [...SINGLE.cards, SINGLE.cards[0]] };
    const unknownCard = {
      ...SINGLE,
      id: 'unknown-card',
      cards: [{ cardId: 'x', reversed: false }],
    };
    cli.files.set(
      'c.jsonl',
      [SINGLE, bad, tooMany, unknownCard].map((c) => JSON.stringify(c)).join('\n'),
    );
    expect(await renderPrompt(['--cases', 'c.jsonl', '--out', 'o'], cli)).toBe(1);
    expect([...cli.written.keys()]).toEqual(['o/en-single-01.txt']);
    expect(cli.stderr).toEqual([
      'bad: unknown spread nine_card',
      'too-many: spread single has only 1 positions',
      'unknown-card: unknown card x',
    ]);
    expect(cli.stdout).toEqual(['rendered 1 of 4 case(s) to o (prompt v1)']);
  });

  it.each([
    [[], '--cases and --out are required'],
    [['--cases', 'c.json'], '--cases and --out are required'],
    [['--nope'], 'unknown argument --nope'],
    [['--cases', 'c.json', '--out', 'o', '--prompt', 'v9'], '--prompt must be one of v1'],
  ])('exits 2 on usage errors (%#)', async (argv, message) => {
    const cli = new StubCli();
    expect(await renderPrompt(argv, cli)).toBe(2);
    expect(cli.stderr[0]).toContain(message);
    expect(cli.stderr[0]).toContain('usage: render-prompt');
  });

  it('exits 1 when the cases file is missing or invalid', async () => {
    const cli = new StubCli();
    expect(await renderPrompt(['--cases', 'missing.json', '--out', 'o'], cli)).toBe(1);
    cli.files.set('bad.json', '{');
    expect(await renderPrompt(['--cases', 'bad.json', '--out', 'o'], cli)).toBe(1);
    expect(cli.stderr).toEqual(['cannot read missing.json', 'bad.json: not valid JSON']);
  });
});

describe('parseCases', () => {
  it.each([
    ['{', false, 'not valid JSON'],
    ['[]', false, 'no cases'],
    ['\n', true, 'no cases'],
    [`${JSON.stringify(SINGLE)}\n{`, true, 'line 2: not valid JSON'],
    [JSON.stringify([SINGLE, SINGLE]), false, 'case 2: duplicate id en-single-01'],
    [JSON.stringify({ ...SINGLE, id: '../x' }), false, 'case 1: id: id must be a safe file name'],
    [JSON.stringify({ ...SINGLE, locale: 'xx' }), false, 'case 1: locale:'],
    [JSON.stringify({ ...SINGLE, prefilterHint: 'astrology' }), false, 'case 1: prefilterHint:'],
    [JSON.stringify('text'), false, 'case 1: (case):'],
  ])('rejects %j', (text, jsonl, error) => {
    const result = parseCases(text, jsonl);
    expect(result.ok).toBe(false);
    expect(result.ok ? '' : result.error).toContain(error);
  });

  it('accepts hint lists, "none" and explicit positions', () => {
    const parsed = parseCases(
      JSON.stringify([
        { ...THREE, id: 'a', prefilterHint: ['health', 'death'] },
        { ...THREE, id: 'b', prefilterHint: 'none' },
        {
          ...SINGLE,
          id: 'c',
          cards: [{ cardId: 'major_01', reversed: false, positionId: 'focus' }],
        },
      ]),
      false,
    );
    if (!parsed.ok) {
      throw new Error(parsed.error);
    }
    const [a, b, c] = parsed.cases.map((evalCase) => renderCase(evalCase, 'v1'));
    expect(a?.ok && a.input.user).toContain('<prefilter_hint>health, death</prefilter_hint>');
    expect(b?.ok && b.input.user).toContain('<prefilter_hint>none</prefilter_hint>');
    expect(c?.ok && providerView(c.input)).toContain('positionId="focus" cardId="major_01"');
  });
});
