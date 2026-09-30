import bannedYaml from '../../../../tools/store_copy/banned_phrases.yaml?raw';
import { describe, expect, it } from 'vitest';
import { main as safetyLexiconsScript } from '../../../scripts/safety-lexicons';
import type { CliDeps, CommandResult } from '../../../src/admin/cli';
import {
  BANNED_PHRASES,
  compileSafetyLexicons,
  GENERATED_LEXICONS,
  LEXICON_DIR,
  main,
  renderSafetyLexicons,
} from '../../../src/admin/safetyLexicons';
import { LOCALES, type Locale } from '../../../src/domain/types';
import {
  LEXICON_SOURCES,
  parseLexiconSource,
  parseLexiconSources,
  type LexiconSource,
} from '../../../src/safety/lexiconSource';

class StubCli implements CliDeps {
  readonly files = new Map<string, string>();
  readonly written = new Map<string, string>();
  readonly stdout: string[] = [];
  readonly stderr: string[] = [];

  constructor() {
    for (const locale of LOCALES) {
      this.files.set(`${LEXICON_DIR}/${locale}.json`, JSON.stringify(LEXICON_SOURCES[locale]));
    }
    this.files.set(BANNED_PHRASES, bannedYaml);
  }

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
    return Promise.reject(new Error('safety-lexicons runs no commands'));
  }
}

const EXPECTED = renderSafetyLexicons(compileSafetyLexicons(LEXICON_SOURCES, bannedYaml));

function withRule(locale: Locale, rule: Record<string, unknown>): LexiconSource {
  const source = LEXICON_SOURCES[locale];
  return { ...source, l1: [...source.l1, rule as LexiconSource['l1'][number]] };
}

describe('scripts/safety-lexicons.ts main([...])', () => {
  it('writes the generated file', async () => {
    const cli = new StubCli();
    expect(await safetyLexiconsScript([], cli)).toBe(0);
    expect(cli.written.get(GENERATED_LEXICONS)).toBe(EXPECTED);
    expect(cli.stdout).toEqual([`wrote ${GENERATED_LEXICONS} (12 locales)`]);
  });

  it('--check passes when up to date and fails when stale or missing', async () => {
    const cli = new StubCli();
    cli.files.set(GENERATED_LEXICONS, EXPECTED);
    expect(await main(['--check'], cli)).toBe(0);
    expect(cli.stdout).toEqual([`${GENERATED_LEXICONS} is up to date`]);
    expect(cli.written.size).toBe(0);

    cli.files.set(GENERATED_LEXICONS, '{}');
    expect(await main(['--check'], cli)).toBe(1);
    cli.files.delete(GENERATED_LEXICONS);
    expect(await main(['--check'], cli)).toBe(1);
    expect(cli.stderr).toEqual([
      `${GENERATED_LEXICONS} is out of date; run npm run safety:lexicons`,
      `${GENERATED_LEXICONS} is out of date; run npm run safety:lexicons`,
    ]);
  });

  it('exits 2 on usage errors and 1 on unreadable or invalid sources', async () => {
    const usage = new StubCli();
    expect(await main(['--bogus'], usage)).toBe(2);
    expect(usage.stderr[0]).toContain('unknown argument --bogus');

    const missing = new StubCli();
    missing.files.delete(BANNED_PHRASES);
    expect(await main([], missing)).toBe(1);
    expect(missing.stderr[0]).toBe('failed: ENOENT');

    const wrongLocale = new StubCli();
    wrongLocale.files.set(`${LEXICON_DIR}/de.json`, JSON.stringify(LEXICON_SOURCES.fr));
    expect(await main([], wrongLocale)).toBe(1);
    expect(wrongLocale.stderr[0]).toBe('failed: lexicon de: file says locale fr');
  });
});

describe('compileSafetyLexicons', () => {
  const compile = (locale: Locale, source: LexiconSource) =>
    compileSafetyLexicons({ ...LEXICON_SOURCES, [locale]: source }, bannedYaml);

  it('wraps patterns in boundaries only where the locale uses them', () => {
    const out = compileSafetyLexicons(LEXICON_SOURCES, bannedYaml);
    expect(out.locales.en.l1[0]?.patterns[0]).toMatch(/^\(\?<!\[\\p\{L\}\\p\{N\}\]\)\(\?:/u);
    expect(out.locales.ja.l1[0]?.patterns[0]).toBe(LEXICON_SOURCES.ja.l1[0]?.patterns[0]);
    expect(out.locales.en.l1.every((rule) => Array.isArray(rule.unless))).toBe(true);
  });

  it('rejects patterns that are not folded, invalid regexes and duplicate IDs', () => {
    const rule = { id: 'x.new', category: 'health', severity: 'hint', patterns: ['Krebs'] };
    expect(() => compile('de', withRule('de', rule))).toThrow(
      'de x.new: pattern is not in foldText form: Krebs',
    );
    expect(() => compile('fr', withRule('fr', { ...rule, patterns: ['maladie é'] }))).toThrow(
      'not in foldText form',
    );
    expect(() => compile('en', withRule('en', { ...rule, patterns: ['(unclosed'] }))).toThrow(
      'en x.new: invalid pattern (unclosed',
    );
    const dup = { ...rule, id: 'sh.suicide', patterns: ['x'] };
    expect(() => compile('en', withRule('en', dup))).toThrow('en: duplicate rule id sh.suicide');
  });

  it('dedupes forbidden claims already in the banned list', () => {
    const en = LEXICON_SOURCES.en;
    const source = { ...en, l3: { ...en.l3, forbiddenClaims: ['guaranteed', 'xanax', 'xanax'] } };
    const rules = compile('en', source).locales.en.l3.rules;
    expect(rules.filter((r) => r.phrase === 'guaranteed')).toHaveLength(1);
    expect(rules.filter((r) => r.phrase === 'xanax')).toEqual([
      expect.objectContaining({ source: 'forbidden_claims', kind: 'claim' }),
    ]);
  });
});

describe('lexicon source schema', () => {
  it('rejects high severity outside the L1 categories and unknown fields', () => {
    const en = LEXICON_SOURCES.en;
    const bad = { ...en, l1: [{ id: 'a', category: 'health', severity: 'high', patterns: ['x'] }] };
    expect(() => parseLexiconSource('en', bad)).toThrow(/only self_harm/u);
    expect(() => parseLexiconSource('en', { ...en, extra: 1 })).toThrow();
    const raw = Object.fromEntries(LOCALES.map((l) => [l, LEXICON_SOURCES[l]]));
    expect(parseLexiconSources(raw as Record<Locale, unknown>)).toEqual(LEXICON_SOURCES);
  });
});
