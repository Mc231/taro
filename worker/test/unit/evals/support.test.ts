import { describe, expect, it } from 'vitest';
import {
  parseCase,
  parseCases,
  parseJsonLines,
  parseOutput,
  parseOutputFileInDir,
  parseOutputs,
  tierOfDir,
} from '../../../evals/lib/io';
import { validateJsonSchema } from '../../../evals/lib/jsonSchema';
import { checkLanguage } from '../../../evals/lib/language';
import { parseYaml } from '../../../evals/lib/miniYaml';
import {
  buildPhraseBook,
  CERTAINTY_PATTERNS,
  CONCEPT_ROWS,
  findPhrases,
  phraseRegex,
} from '../../../evals/lib/phrases';
import { SPEC_OUTPUT_SCHEMA } from '../../../evals/lib/specSchema';
import { countWords, letterTokens, normalize, readingTexts } from '../../../evals/lib/text';
import { LOCALES, outcomeOf } from '../../../evals/lib/types';
import { bannedYaml, PHRASES, PROSE } from './helpers';

describe('validateJsonSchema', () => {
  it('accepts values that match and reports each violation with its path', () => {
    const schema = {
      type: 'object',
      required: ['a', 'b'],
      properties: {
        a: { type: ['string', 'null'], minLength: 2, pattern: '^x' },
        b: { type: 'array', items: { type: 'integer' }, minItems: 2, maxItems: 3 },
        c: { const: 1 },
        d: { type: 'number' },
      },
      additionalProperties: { type: 'boolean' },
      description: 'annotations are fine',
    };
    expect(validateJsonSchema({ a: 'xy', b: [1, 2], d: 1, e: true }, schema)).toEqual([]);
    expect(validateJsonSchema({ a: null, b: [1, 2] }, schema)).toEqual([]);
    expect(validateJsonSchema({ a: 'y', b: [1.5], c: 2, e: 'no' }, schema)).toEqual([
      '$.a: 1 characters < minLength 2',
      '$.a: does not match ^x',
      '$.b: 1 items < minItems 2',
      '$.b[0]: expected "integer", got number',
      '$.c: must equal 1',
      '$.e: expected "boolean", got string',
    ]);
    expect(validateJsonSchema({ b: [1, 2, 3, 4] }, schema)).toEqual([
      '$: missing required "a"',
      '$.b: 4 items > maxItems 3',
    ]);
    expect(validateJsonSchema('x', schema)).toEqual(['$: expected "object", got string']);
  });

  it('counts code points and reports unsupported keywords once', () => {
    expect(validateJsonSchema('😀😀', { maxLength: 2 })).toEqual([]);
    expect(validateJsonSchema([1, 2], { items: { oneOf: [] } })).toEqual([
      'schema keyword "oneOf" is not supported by the grader',
    ]);
    expect(validateJsonSchema(1, true)).toEqual([]);
    expect(validateJsonSchema(null, { type: 'null', enum: [null] })).toEqual([]);
    expect(validateJsonSchema('z', { enum: ['a'] })).toEqual([
      '$: "z" is not one of the allowed values',
    ]);
  });

  it('validates the 03 §9.2 schema', () => {
    expect(validateJsonSchema({ classification: 'none' }, SPEC_OUTPUT_SCHEMA)).toHaveLength(5);
  });
});

describe('parseYaml', () => {
  it('reads banned_phrases.yaml', () => {
    const root = parseYaml(bannedYaml) as Record<string, Record<string, unknown>>;
    expect(root['version']).toBe('1');
    expect((root['common']?.['global'] as string[]).slice(0, 2)).toEqual(['100%', '#1']);
    const en = (root['locales'] as Record<string, Record<string, string[]>>)['en'];
    expect(en?.['global']).toContain('limited time');
    expect(en?.['allowed_contexts']).toEqual([
      'not medical, legal, financial or psychological advice',
    ]);
  });

  it('handles quotes, nested sequences and comments', () => {
    const text = ["a: 'it''s' # note", 'b:', '  -', '    - "x#y"', '  - plain # c', ''].join('\n');
    expect(parseYaml(text)).toEqual({ a: "it's", b: [['x#y'], 'plain'] });
    expect(parseYaml('')).toBe('');
  });

  it('throws on syntax it does not support', () => {
    expect(() => parseYaml('a: [1, 2]')).toThrow('line 1: unsupported YAML syntax');
    expect(() => parseYaml("a: 'open")).toThrow('line 1: unterminated quoted scalar');
    expect(() => parseYaml('just text')).toThrow('line 1: expected "key: value"');
    expect(() => parseYaml('  a: 1\nb: 2')).toThrow('line 2: unexpected indentation');
  });
});

describe('phrases', () => {
  it('compiles stems, word boundaries and substring locales', () => {
    expect(phraseRegex('guarantee*', false).test('guaranteed')).toBe(true);
    expect(phraseRegex('heal', false).test('healthy')).toBe(false);
    expect(phraseRegex('will happen', false).test('it will   happen')).toBe(true);
    expect(phraseRegex('passer* avenir', false).test('passera avenir')).toBe(true);
    expect(phraseRegex('100%', false).test('100% sure')).toBe(true);
    expect(phraseRegex('未来 予知', true).test('未来予知です')).toBe(true);
    expect(() => phraseRegex('  ', false)).toThrow('empty phrase');
  });

  it('files every 05 §9.5 row phrase that the YAML lists', () => {
    const yaml = parseYaml(bannedYaml) as {
      common: { global: string[] };
      locales: Record<string, { global: string[] }>;
    };
    for (const locale of LOCALES) {
      const listed = new Set([...yaml.common.global, ...(yaml.locales[locale]?.global ?? [])]);
      for (const phrases of Object.values(CONCEPT_ROWS[locale])) {
        for (const phrase of phrases) {
          expect(listed.has(phrase), `${locale}: ${phrase}`).toBe(true);
        }
      }
      expect(CERTAINTY_PATTERNS[locale].length).toBeGreaterThan(0);
    }
  });

  it('sorts phrases into concepts and removes allowed contexts', () => {
    const en = PHRASES.en;
    const hits = findPhrases(
      'This is not medical, legal, financial or psychological advice. A medical guarantee!',
      en,
    );
    expect(hits.map((h) => [h.phrase, h.concept])).toEqual([
      ['medical', 'other'],
      ['guarantee*', 'guarantee'],
    ]);
    expect(findPhrases('Ohne Zweifel', PHRASES.de)).toEqual([
      {
        phrase: 'ohne zweifel',
        concept: 'guarantee',
        source: 'certainty_patterns',
        match: 'ohne zweifel',
      },
    ]);
  });

  it('ignores non-claim spans but still flags the claims next to them', () => {
    const matches = (
      text: string,
      locale: 'de' | 'en' | 'es' | 'fr' | 'it' | 'pt' | 'nl' | 'tr',
    ): string[] => findPhrases(text, PHRASES[locale]).map((h) => h.match);
    expect(matches('Senza una domanda precisa, la lettura osserva.', 'it')).toEqual([]);
    expect(matches('Una lettura precisa del tuo futuro.', 'it')).toEqual(['precisa']);
    expect(matches('La gratitud podría empezar precisamente ahí.', 'es')).toEqual([]);
    expect(matches('Una predicción precisa.', 'es')).toEqual(['precisa']);
    expect(matches('Sem que ninguém mais precise validar isso.', 'pt')).toEqual([]);
    expect(matches('Você não precisa decidir; você precisa de tempo.', 'pt')).toEqual([]);
    expect(matches('Uma leitura precisa.', 'pt')).toEqual(['precisa']);
    expect(matches('O que você precisa saber agora.', 'pt')).toEqual([]);
    expect(matches('Algo que ainda precisa de reparo.', 'pt')).toEqual([]);
    expect(matches('Ela precisa escolher; isso precisa mudar.', 'pt')).toEqual([]);
    expect(matches('Uma previsão precisa para você.', 'pt')).toEqual(['precisa']);
    expect(matches('Het heeft minder met zekerheid te maken.', 'nl')).toEqual([]);
    expect(matches('Dit weet je met zekerheid.', 'nl')).toEqual(['met zekerheid']);
    expect(matches('Bu mutlaka yaşayacağın bir şey değil.', 'tr')).toEqual([]);
    expect(matches('Bunu mutlaka yaşayacaksın. Değil mi?', 'tr')).toEqual(['mutlaka']);
    expect(matches('Bu olası bir yön, kesin bir sonuç değil.', 'tr')).toEqual([]);
    expect(matches('Bu kesin bir sonuç.', 'tr')).toEqual(['kesin']);
    expect(matches('Genau dieser zaghafte Anfang zählt.', 'de')).toEqual([]);
    expect(matches('Eine genau zutreffende Deutung.', 'de')).toEqual(['genau']);
    expect(matches('Sans question précise, ces cartes invitent.', 'fr')).toEqual([]);
    expect(matches("Ce n'est pas un résultat garanti.", 'fr')).toEqual([]);
    expect(matches('Un résultat garanti. Pas de doute.', 'fr')).toEqual(['garanti']);
    expect(matches('Une lecture précise.', 'fr')).toEqual(['précise']);
    expect(matches("Plus que d'un plan d'action précis.", 'fr')).toEqual([]);
    expect(matches('Un moment précis compte.', 'fr')).toEqual([]);
    expect(matches('This stays a direction rather than something guaranteed.', 'en')).toEqual([]);
    expect(matches('Nothing here is guaranteed.', 'en')).toEqual([]);
    expect(matches('Steadiness, not through knowing what will happen.', 'en')).toEqual([]);
    expect(matches('Success is guaranteed.', 'en')).toContain('guaranteed');
    expect(matches('This will happen soon.', 'en')).toContain('will happen');
    expect(matches('Pode não depender de saber com certeza o que fazer.', 'pt')).toEqual([]);
    expect(matches('Não se preocupe, com certeza vai dar certo.', 'pt')).toEqual(['com certeza']);
    const lexicon = findPhrases('Senza una domanda precisa.', PHRASES.it, 'keep');
    expect(lexicon.map((h) => h.match)).toEqual(['precisa']);
  });

  it('builds an empty book from YAML without locales', () => {
    const book = buildPhraseBook('version: 1\n');
    expect(book.en.rules.map((r) => r.source)).toEqual(
      CERTAINTY_PATTERNS.en.map(() => 'certainty_patterns'),
    );
    const duplicate = buildPhraseBook('locales:\n  en:\n    global:\n      - for sure\n');
    expect(duplicate.en.rules.filter((r) => r.phrase === 'for sure')).toHaveLength(1);
  });
});

describe('language heuristic', () => {
  it('accepts each locale and rejects the wrong script', () => {
    for (const locale of LOCALES) {
      expect(checkLanguage(PROSE[locale], locale).ok, locale).toBe(true);
    }
    expect(checkLanguage(PROSE.en, 'ar')).toMatchObject({
      ok: false,
      detail: '0% of letters in the ar script',
    });
    expect(checkLanguage(PROSE.ar, 'en').detail).toBe('only 0% Latin letters');
    expect(checkLanguage('', 'ko')).toMatchObject({ ok: false, weak: true });
  });

  it('tells Chinese from Japanese and Russian from Ukrainian', () => {
    expect(
      checkLanguage(
        '过去的位置上的塔表示你生活中的旧结构可能已经动摇了。想想你从这次变化中学到了什么。',
        'ja',
      ).detail,
    ).toContain('no kana');
    const russian =
      'Башня в позиции прошлого подсказывает, что старая структура в твоей жизни могла пошатнуться. Подумай, чему ты научился из этого изменения и как это может помочь тебе взглянуть на настоящее с большей открытостью.';
    expect(checkLanguage(russian, 'uk')).toMatchObject({ ok: false });
    expect(checkLanguage('Так', 'uk')).toMatchObject({ ok: true, weak: true });
  });

  it('fails Latin text with too few stop words', () => {
    expect(
      checkLanguage(
        'Tower Fool Magician Priestess Empress Emperor Hierophant Lovers Chariot',
        'en',
      ),
    ).toMatchObject({
      ok: false,
      weak: true,
      detail: '0% en stop words',
    });
  });
});

describe('text helpers', () => {
  it('normalises like check_store_copy', () => {
    expect(normalize('ＧＵＡＲＡＮＴＥＥ’s')).toBe("guarantee's");
    expect(letterTokens("'Hello', l'avenir — 42")).toEqual(['hello', "l'avenir"]);
  });

  it('collects reading prose and counts words', () => {
    expect(
      readingTexts({
        title: 'T',
        overview: 3,
        cards: [{ interpretation: 'I' }, null, 'x'],
        synthesis: '',
        reflectionPrompts: ['R', 1],
      }),
    ).toEqual(['T', 'I', 'R']);
    expect(readingTexts({ cards: 'x', reflectionPrompts: 'y' })).toEqual([]);
    expect(countWords('one two-three, four — 5', 'en')).toBe(4);
    expect(countWords('あなたの人生', 'ja')).toBeGreaterThan(1);
  });
});

describe('io', () => {
  it('parses JSON lines and reports bad lines', () => {
    expect(parseJsonLines('{"a":1}\n\nnope\n', 'f.jsonl')).toEqual({
      items: [{ line: 1, value: { a: 1 } }],
      errors: ['f.jsonl:3: not valid JSON'],
    });
  });

  it('parses cases with categories, outcomes and aliases', () => {
    expect(
      parseCase({ id: 'a', locale: 'de', expected: 'self_harm', spread: { id: 'single' } }),
    ).toMatchObject({
      expectedCategory: 'self_harm',
      expectedOutcome: 'crisis',
      spreadId: 'single',
      cards: null,
      question: null,
      kind: null,
    });
    expect(
      parseCase({
        id: 'b',
        locale: 'en',
        expected: 'answered',
        spread: 'three_ppf',
        kind: 'benign',
      }),
    ).toMatchObject({
      expectedCategory: null,
      expectedOutcome: 'answered',
      spreadId: 'three_ppf',
      kind: 'benign',
    });
    expect(
      parseCase({
        id: 'c',
        locale: 'en',
        category: 'none',
        expectedOutcome: 'answered',
        question: '',
        cards: [{ positionId: 'focus', cardId: 'major_00' }],
      }),
    ).toMatchObject({
      cards: [{ positionId: 'focus', cardId: 'major_00', reversed: false }],
      question: '',
    });
    expect(parseCase({ id: 'd', locale: 'en', expectedCategory: 'legal' })).toMatchObject({
      expectedOutcome: 'rephrase',
    });
    expect(outcomeOf('sexual_minors')).toBe('refused');
  });

  it('rejects malformed cases', () => {
    expect(parseCase(3)).toBe('a case must be a JSON object');
    expect(parseCase({ locale: 'en' })).toBe('a case needs a string "id"');
    expect(parseCase({ id: 'x', locale: 'xx' })).toBe('x: unknown locale "xx"');
    expect(parseCase({ id: 'x' })).toBe('x: unknown locale undefined');
    expect(parseCase({ id: 'x', locale: 'en', expected: 'rain' })).toBe(
      'x: unknown category "rain"',
    );
    expect(parseCase({ id: 'x', locale: 'en', expectedOutcome: 'maybe' })).toBe(
      'x: unknown outcome "maybe"',
    );
    expect(parseCase({ id: 'x', locale: 'en' })).toBe('x: needs an expected category or outcome');
    expect(parseCase({ id: 'x', locale: 'en', expected: 'none', cards: 'x' })).toContain(
      '"cards" must be',
    );
    expect(
      parseCase({ id: 'x', locale: 'en', expected: 'none', cards: [{ positionId: 'a' }] }),
    ).toContain('"cards"');
    expect(
      parseCases('{"id":"a","locale":"en","expected":"none"}\n{"id":"b"}\n', 'c.jsonl'),
    ).toMatchObject({ items: [{ id: 'a' }], errors: ['c.jsonl:2: b: unknown locale undefined'] });
  });

  it('parses outputs from jsonl and json, with refusals and object outputs', () => {
    expect(parseOutput({ id: 'a', output: 'raw' }, 'free')).toEqual({
      id: 'a',
      tier: 'free',
      provider: null,
      model: null,
      output: 'raw',
      refusal: null,
    });
    expect(
      parseOutput({ id: 'a', tier: 'paid', output: { x: 1 }, refusal: true }, 'free'),
    ).toMatchObject({
      tier: 'paid',
      output: '{"x":1}',
      refusal: { category: null },
    });
    expect(parseOutput({ id: 'a', refusal: { category: 'self_harm' } }, 'free')).toMatchObject({
      output: '',
      refusal: { category: 'self_harm' },
    });
    expect(parseOutput([], 'free')).toBe('an output must be a JSON object');
    expect(parseOutput({ output: 'x' }, 'free')).toBe('an output needs a string "id"');
    expect(parseOutput({ id: 'a', output: 5 }, 'free')).toBe(
      'a: "output" must be the raw model text',
    );
    expect(parseOutputs('[{"id":"a","output":"x"},{"id":"b"}]', 'o.json', 't')).toMatchObject({
      items: [{ id: 'a', tier: 't' }],
      errors: ['o.json:1: b: "output" must be the raw model text'],
    });
    expect(parseOutputs('{"id":"a","output":"x"}', 'one.json', 't').items).toHaveLength(1);
    expect(parseOutputs('{', 'bad.json', 't').errors).toEqual(['bad.json: not valid JSON']);
    expect(parseOutputs('{"id":"a","output":"x"}\n{', 'o.jsonl', 't')).toMatchObject({
      items: [{ id: 'a' }],
      errors: ['o.jsonl:2: not valid JSON'],
    });
  });

  it('reads a raw model response named <id>.json from an outputs directory', () => {
    const raw = '{"classification":"none","title":"t"}';
    expect(parseOutputFileInDir(raw, 'out_free/q-en-001.json', 'free')).toEqual({
      items: [
        { id: 'q-en-001', tier: 'free', provider: null, model: null, output: raw, refusal: null },
      ],
      errors: [],
    });
    expect(parseOutputFileInDir('not json', 'd/x.json', 't').items[0]).toMatchObject({
      id: 'x',
      output: 'not json',
    });
    expect(parseOutputFileInDir('{"id":"a","output":"x"}', 'd/b.json', 't').items).toMatchObject([
      { id: 'a', output: 'x' },
    ]);
    expect(parseOutputFileInDir('{"id":"a","refusal":true}', 'd/b.json', 't').items).toMatchObject([
      { id: 'a', refusal: { category: null } },
    ]);
    expect(parseOutputFileInDir('[{"id":"a","output":"x"}]', 'd/b.json', 't').items).toHaveLength(
      1,
    );
    expect(parseOutputFileInDir('{"id":"a","output":"x"}', 'd/b.jsonl', 't').items).toHaveLength(1);
  });

  it('takes the tier from an out_<tier> directory name', () => {
    expect(tierOfDir('r1/batch_01/out_free-sonnet/')).toBe('free-sonnet');
    expect(tierOfDir('out_x')).toBe('x');
    expect(tierOfDir('outputs')).toBeNull();
    expect(tierOfDir('out_')).toBeNull();
  });
});
