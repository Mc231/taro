import { describe, expect, it } from 'vitest';
import cardsFeed from '../../../src/generated/deck/cards.json';
import spreadsFeed from '../../../src/generated/deck/spreads.json';
import { WebCrypto } from '../../../src/adapters/cf/WebCrypto';
import { CLASSIFICATIONS, LOCALES } from '../../../src/domain/types';
import { buildReadingPrompt, systemPrompt } from '../../../src/prompts/build';
import {
  isPromptVersion,
  outputSchemaFor,
  parseModelOutput,
  parseReadingOutput,
  promptDataSchema,
  PROMPT_VERSIONS,
  READING_TEMPLATES,
  templateFiles,
  toModelOutput,
  type OutputSchema,
} from '../../../src/prompts/templates';
import { promptVersionHash } from '../../../src/prompts/versions';
import lock from '../../../src/prompts/versions.lock.json';

// Sprint 8.2 / 06 §7: the versioned templates are complete, provider-neutral
// (RC97), and frozen by the hash in versions.lock.json.
describe.each(PROMPT_VERSIONS)('reading prompt templates %s', (version) => {
  const set = READING_TEMPLATES[version];

  it('knows its versions', () => {
    expect(PROMPT_VERSIONS).toEqual(['v1', 'v2']);
    expect(isPromptVersion(version)).toBe(true);
    expect(isPromptVersion('v3')).toBe(false);
    expect(isPromptVersion(1)).toBe(false);
  });

  it('pins the hash of every version in versions.lock.json', async () => {
    const crypto = new WebCrypto();
    expect(Object.keys(lock.reading).sort()).toEqual([...PROMPT_VERSIONS].sort());
    for (const version of PROMPT_VERSIONS) {
      const hash = await promptVersionHash(version, crypto);
      expect(
        hash,
        `prompt ${version} changed: released prompt versions are frozen; add prompts/reading/<next>/ ` +
          `(and its CHANGELOG entry) instead. While ${version} is still unreleased, pin ${hash}.`,
      ).toBe(lock.reading[version]);
    }
  });

  it('hashes all template files in a stable order', () => {
    const names = templateFiles(set).map(([name]) => name);
    expect(names).toEqual([...names].sort());
    expect(names).toEqual(
      expect.arrayContaining([
        'system.md',
        'user.md',
        'output.schema.json',
        'prompt_data.json',
        ...LOCALES.map((l) => `style.${l}.md`),
      ]),
    );
    expect(names).toHaveLength(4 + LOCALES.length);
  });

  it('has a non-empty style note and a language name for every locale', () => {
    for (const locale of LOCALES) {
      expect(set.styles[locale].trim().length, locale).toBeGreaterThan(200);
      // Consolidation: short per-locale notes, not a second rule book.
      expect(new TextEncoder().encode(set.styles[locale]).length, locale).toBeLessThanOrEqual(1024);
      expect(set.styles[locale], locale).toMatch(/^Card-focus clause: /m);
      expect(set.styles[locale], locale).toMatch(/^Rejected words/m);
      expect(set.data.locales[locale].length, locale).toBeGreaterThan(0);
      const notes = set.data.localeNotes[locale];
      expect(notes.factor, locale).toBeGreaterThan(0.5);
      expect(notes.factor, locale).toBeLessThanOrEqual(2);
      expect(notes.address.length, locale).toBeGreaterThan(10);
    }
    expect(set.data.localeNotes.en).toMatchObject({ factor: 1, unit: 'words' });
  });

  it('has notes, labels and budgets for every generated spread and position', () => {
    expect(Object.keys(set.data.spreads).sort()).toEqual(
      spreadsFeed.spreads.map((s) => s.id).sort(),
    );
    for (const spread of spreadsFeed.spreads) {
      const notes = set.data.spreads[spread.id];
      expect(notes, spread.id).toBeDefined();
      expect(Object.keys(notes?.positions ?? {})).toEqual(spread.positions.map((p) => p.id));
      for (const [min, max] of Object.values(notes?.words ?? {})) {
        expect(min).toBeLessThan(max);
      }
    }
  });

  it('keeps word budgets inside 01 §7.4 and the schema character limits', () => {
    // 01 §7.4 totals include the title (2–7 words) and the reflection prompts
    // (about 8–15 words each); the per-field budgets plus those must add up to them.
    const totals: Record<string, [number, number]> = {
      single: [150, 220],
      three_ppf: [300, 400],
      three_sao: [300, 400],
      relationship: [400, 550],
      two_paths: [400, 550],
      celtic_cross: [650, 850],
    };
    for (const spread of spreadsFeed.spreads) {
      const notes = set.data.spreads[spread.id];
      if (notes === undefined) {
        throw new Error(spread.id);
      }
      expect(notes.words.total, spread.id).toEqual(totals[spread.id]);
      const n = spread.positions.length;
      const p = notes.reflectionPrompts;
      const min =
        notes.words.overview[0] + n * notes.words.card[0] + notes.words.synthesis[0] + 2 + p * 8;
      const max =
        notes.words.overview[1] + n * notes.words.card[1] + notes.words.synthesis[1] + 7 + p * 15;
      expect(min, spread.id).toBeGreaterThanOrEqual(notes.words.total[0] * 0.9);
      expect(max, spread.id).toBeLessThanOrEqual(notes.words.total[1]);
      // ~6 characters per English word (German runs ~30 % longer) must fit the schema limits.
      expect(notes.words.card[1] * 6 * 1.3, spread.id).toBeLessThanOrEqual(900);
      expect(notes.words.overview[1] * 6 * 1.3, spread.id).toBeLessThanOrEqual(700);
      expect(notes.words.synthesis[1] * 6 * 1.3, spread.id).toBeLessThanOrEqual(1400);
      expect(notes.reflectionPrompts).toBeGreaterThanOrEqual(2);
      // The prompt's own position notes cover every position and never negate ("not a promise").
      expect(Object.keys(notes.positionNotes).sort(), spread.id).toEqual(
        spread.positions.map((position) => position.id).sort(),
      );
      for (const note of Object.values(notes.positionNotes)) {
        expect(note, spread.id).not.toMatch(/\bnot\b|\bnever\b/i);
        // Worded as instructions, with no quotable sentence the model would echo.
        expect(note, spread.id).toMatch(/^Read as /);
        expect(note, spread.id).not.toMatch(/if nothing changes/i);
      }
      // No contrast aphorism ("go deep rather than wide") to lift into a reading.
      expect(notes.note, spread.id).not.toMatch(/\brather than\b/i);
      for (const range of Object.values(notes.sentences)) {
        const [lo, hi] = range.split('–').map(Number);
        expect(lo, spread.id).toBeLessThanOrEqual(hi ?? 0);
      }
    }
  });

  it('gives every deck card an image line', () => {
    expect(Object.keys(set.data.images).sort()).toEqual(cardsFeed.cards.map((c) => c.id).sort());
  });

  it('keeps contrast wording out of the image lines', () => {
    // An image line such as "more like a contest than a fight" was copied as a contrast framing.
    for (const [id, image] of Object.entries(set.data.images)) {
      expect(image, id).not.toMatch(/\bthan\b|\brather\b|\binstead\b|\bnot\b/i);
    }
  });

  it('names all 14 ranks', () => {
    expect(Object.keys(set.data.ranks).sort()).toEqual(
      Array.from({ length: 14 }, (_, i) => String(i + 1).padStart(2, '0')),
    );
  });

  it('rejects malformed prompt data', () => {
    expect(promptDataSchema.safeParse({}).success).toBe(false);
    expect(
      promptDataSchema.safeParse({ ...set.data, locales: { en: 'English' } }).success,
    ).toBe(false);
  });

  describe('output.schema.json (03 §9.2)', () => {
    const schema = set.outputSchema as {
      required: string[];
      properties: Record<string, Record<string, unknown>>;
      additionalProperties: boolean;
    };

    it('puts classification first and lists the canonical categories', () => {
      expect(schema.required[0]).toBe('classification');
      expect(Object.keys(schema.properties)[0]).toBe('classification');
      expect(schema.properties['classification']?.['enum']).toEqual([...CLASSIFICATIONS]);
    });

    it('uses no conditional keywords that vendor strict modes reject', () => {
      expect(JSON.stringify(schema)).not.toMatch(/"(if|then|else|oneOf|anyOf|allOf|not)":/);
    });

    it('is strict and keeps the 03 §9.2 limits', () => {
      expect(schema.additionalProperties).toBe(false);
      expect(schema.required).toEqual([
        'classification',
        'title',
        'overview',
        'cards',
        'synthesis',
        'reflectionPrompts',
      ]);
      expect(schema.properties['title']?.['maxLength']).toBe(80);
      expect(schema.properties['overview']?.['maxLength']).toBe(700);
      expect(schema.properties['synthesis']?.['maxLength']).toBe(1400);
      const cards = schema.properties['cards'] as {
        properties: Record<string, { properties: Record<string, Record<string, unknown>> }>;
        additionalProperties: boolean;
      };
      expect(cards.additionalProperties).toBe(false);
      expect(cards.properties['<positionId>']).toMatchObject({
        required: ['cardId', 'reversed', 'interpretation'],
        additionalProperties: false,
        properties: { interpretation: { maxLength: 900 } },
      });
      expect(schema.properties['reflectionPrompts']).toMatchObject({
        type: 'object',
        required: ['prompt<n>'],
        additionalProperties: false,
        properties: { 'prompt<n>': { type: 'string', maxLength: 200 } },
      });
    });

    it('expands per spread: one required key per position and prompt, no count keywords', () => {
      const built = outputSchemaFor(set.outputSchema, ['past', 'present', 'future'], 3) as {
        properties: Record<string, { properties: Record<string, unknown>; required: string[] }>;
      };
      expect(built.properties['cards']?.required).toEqual(['past', 'present', 'future']);
      expect(Object.keys(built.properties['cards']?.properties ?? {})).toEqual([
        'past',
        'present',
        'future',
      ]);
      expect(built.properties['reflectionPrompts']?.required).toEqual([
        'prompt1',
        'prompt2',
        'prompt3',
      ]);
      expect(JSON.stringify({ ...built, $comment: '' })).not.toMatch(/<positionId>|prompt<n>|minItems|maxItems/);
      // The template itself is left untouched.
      expect(schema.properties['cards']?.['required']).toEqual(['<positionId>']);
    });

    it('refuses a template without the placeholders', () => {
      const noProps: OutputSchema = { type: 'object' };
      expect(() => outputSchemaFor(noProps, ['focus'], 1)).toThrow(/no properties/);
      const plain: OutputSchema = { properties: { cards: { type: 'array' } } };
      expect(() => outputSchemaFor(plain, ['focus'], 1)).toThrow(/<positionId>/);
    });
  });

  describe('provider neutrality (RC97)', () => {
    const vendorSyntax =
      /cache_control|ephemeral|anthropic|openai|claude|chatgpt|\bgpt\b|<\|im_|\[INST\]|\bHuman:|\bAssistant:|<<SYS>>|output_config|response_format|json_schema/i;

    it('has no vendor-specific syntax in any template file', () => {
      for (const [name, text] of templateFiles(set)) {
        expect(vendorSyntax.test(text), name).toBe(false);
      }
    });

    it('has a static prefix with no placeholders, the refusal shape and every category', () => {
      const system = systemPrompt(version);
      expect(system).not.toMatch(/\{\{[a-z_]+\}\}/);
      expect(system).toContain(
        '{"classification":"health","title":"","overview":"","cards":{"focus":{"cardId":"swords_02","reversed":false,"interpretation":""}},"synthesis":"","reflectionPrompts":{"prompt1":"","prompt2":""}}',
      );
      for (const category of CLASSIFICATIONS) {
        expect(system).toContain(`| \`${category}\` |`);
      }
    });

    it('keeps the deck out of the static prefix: keywords and images only for drawn cards', () => {
      const system = systemPrompt(version);
      for (const card of cardsFeed.cards) {
        expect(system, card.id).not.toContain(card.keywordsUpright.join('; '));
        expect(system, card.id).not.toContain(set.data.images[card.id]);
      }
    });

    it('stays inside the size budget (static ≤ 12 KB, Celtic Cross ≤ 18 KB in v1, ≤ +10 % later)', () => {
      const bytes = (text: string): number => new TextEncoder().encode(text).length;
      expect(bytes(systemPrompt(version))).toBeLessThanOrEqual(12 * 1024);
      const celtic = spreadsFeed.spreads.find((s) => s.id === 'celtic_cross');
      for (const locale of LOCALES) {
        const request = {
          spreadId: 'celtic_cross',
          locale,
          // The longest question the route accepts (300 graphemes, 03 §9.1).
          question: 'ж'.repeat(300),
          cards: (celtic?.positions ?? []).map((p, i) => ({
            positionId: p.id,
            cardId: cardsFeed.cards[i * 7]?.id ?? 'major_00',
            reversed: i % 2 === 0,
          })),
        };
        const size = (v: (typeof PROMPT_VERSIONS)[number]): number => {
          const built = buildReadingPrompt(request, v);
          if (!built.ok) {
            throw new Error(built.error);
          }
          return bytes(built.input.system) + bytes(built.input.user);
        };
        // v1 consolidation budget; v2 adds the answer-first and plain-words rules (≈ 1 KB).
        expect(size(version), locale).toBeLessThanOrEqual((version === 'v1' ? 18 : 19.5) * 1024);
        // A later version grows the rendered prompt by at most 10 % over v1.
        expect(size(version), locale).toBeLessThanOrEqual(size('v1') * 1.1);
      }
    });

    it('keeps the static prefix identical across locales, spreads and questions', () => {
      const systems = new Set<string>();
      for (const locale of LOCALES) {
        for (const spread of spreadsFeed.spreads) {
          const built = buildReadingPrompt(
            {
            spreadId: spread.id,
            locale,
            question: `${locale} ${spread.id}?`,
            cards: spread.positions.map((p, i) => ({
              positionId: p.id,
              cardId: cardsFeed.cards[i * 7]?.id ?? 'major_00',
              reversed: i % 2 === 1,
            })),
            },
            version,
          );
          if (!built.ok) {
            throw new Error(built.error);
          }
          systems.add(built.input.system);
        }
      }
      expect(systems.size).toBe(1);
    });
  });

  describe('parseReadingOutput (Worker-side zod, 03 §9.2)', () => {
    const drawn = [
      { positionId: 'past', cardId: 'major_16', reversed: false },
      { positionId: 'present', cardId: 'cups_03', reversed: true },
    ];
    const answered = {
      classification: 'none',
      title: 'A tower in the rain',
      overview: 'Two sentences. About the question.',
      cards: drawn.map((c) => ({ ...c, interpretation: 'The card may reflect something.' })),
      synthesis: 'The cards connect. One step.',
      reflectionPrompts: ['What might you notice?', 'Which part matters?'],
    };
    const expected = { cards: drawn, reflectionPrompts: 2 };

    it('accepts an answered reading and the refusal shape', () => {
      expect(parseReadingOutput(answered, expected)).toMatchObject({ ok: true });
      const refusal = {
        classification: 'self_harm',
        title: '',
        overview: '',
        cards: [],
        synthesis: '',
        reflectionPrompts: [''],
      };
      expect(parseReadingOutput(refusal, expected)).toEqual({ ok: true, output: refusal });
    });

    it('rejects an empty answered reading that output.schema.json lets through', () => {
      const empty = {
        ...answered,
        title: ' ',
        overview: '',
        cards: [],
        synthesis: '',
        reflectionPrompts: [''],
      };
      const result = parseReadingOutput(empty);
      expect(result.ok).toBe(false);
      const issues = result.ok ? [] : result.issues;
      for (const path of ['$.title', '$.overview', '$.cards', '$.synthesis', '$.reflectionPrompts.0']) {
        expect(issues.some((issue) => issue.startsWith(`${path}:`)), path).toBe(true);
      }
    });

    it('enforces the character limits in code points and rejects unknown keys', () => {
      const long = parseReadingOutput({ ...answered, title: '😀'.repeat(80) });
      expect(long.ok).toBe(true);
      expect(parseReadingOutput({ ...answered, title: 'x'.repeat(81) }).ok).toBe(false);
      expect(parseReadingOutput({ ...answered, extra: 1 }).ok).toBe(false);
      expect(parseReadingOutput({ ...answered, classification: 'astrology' }).ok).toBe(false);
    });

    it('checks the card echo and prompt count against the drawn cards', () => {
      const swapped = { ...answered, cards: [...answered.cards].reverse() };
      expect(parseReadingOutput(swapped, expected)).toEqual({
        ok: false,
        issues: [
          '$.cards.0: does not echo past/major_16',
          '$.cards.1: does not echo present/cups_03',
        ],
      });
      const short = { ...answered, cards: answered.cards.slice(0, 1), reflectionPrompts: ['What?'] };
      expect(parseReadingOutput(short, expected)).toEqual({
        ok: false,
        issues: ['$.cards: 1 entries, 2 drawn', '$.reflectionPrompts: 1, expected 2'],
      });
      expect(parseReadingOutput(answered)).toMatchObject({ ok: true });
    });
  });

  describe('parseModelOutput (the keyed wire form, 03 §9.2)', () => {
    const drawn = [
      { positionId: 'past', cardId: 'major_16', reversed: false },
      { positionId: 'present', cardId: 'cups_03', reversed: true },
    ];
    const expected = { cards: drawn, reflectionPrompts: 2 };
    const wire = {
      classification: 'none',
      title: 'A tower in the rain',
      overview: 'Two sentences. About the question.',
      cards: {
        present: { cardId: 'cups_03', reversed: true, interpretation: 'The cups may reflect.' },
        past: { cardId: 'major_16', reversed: false, interpretation: 'The tower may reflect.' },
      },
      synthesis: 'The cards connect. One step.',
      reflectionPrompts: { prompt2: 'Which part matters?', prompt1: 'What might you notice?' },
    };

    it('converts to the Worker form in the drawn order and back', () => {
      const parsed = parseModelOutput(wire, expected);
      expect(parsed.ok).toBe(true);
      if (!parsed.ok) {
        return;
      }
      expect(parsed.output.cards.map((c) => c.positionId)).toEqual(['past', 'present']);
      expect(parsed.output.cards[0]).toEqual({
        positionId: 'past',
        cardId: 'major_16',
        reversed: false,
        interpretation: 'The tower may reflect.',
      });
      expect(parsed.output.reflectionPrompts).toEqual(['What might you notice?', 'Which part matters?']);
      expect(parseModelOutput(toModelOutput(parsed.output), expected)).toEqual(parsed);
    });

    it('keeps object order without expected cards, and accepts the refusal shape', () => {
      const parsed = parseModelOutput(wire);
      expect(parsed.ok && parsed.output.cards.map((c) => c.positionId)).toEqual(['present', 'past']);
      const refusal = {
        classification: 'health',
        title: '',
        overview: '',
        cards: {
          past: { cardId: 'major_16', reversed: false, interpretation: '' },
          present: { cardId: 'cups_03', reversed: true, interpretation: '' },
        },
        synthesis: '',
        reflectionPrompts: { prompt1: '', prompt2: '' },
      };
      expect(parseModelOutput(refusal, expected)).toMatchObject({
        ok: true,
        output: { classification: 'health', reflectionPrompts: ['', ''] },
      });
    });

    it('rejects the list form, missing or extra positions and a wrong prompt count', () => {
      const list = parseModelOutput({ ...wire, cards: [] }, expected);
      expect(list.ok).toBe(false);
      const onlyPast = { past: wire.cards.past };
      const extra = {
        ...onlyPast,
        future: { cardId: 'cups_03', reversed: true, interpretation: 'Extra.' },
      };
      expect(parseModelOutput({ ...wire, cards: onlyPast }, expected)).toEqual({
        ok: false,
        issues: ['$.cards: 1 entries, 2 drawn'],
      });
      expect(parseModelOutput({ ...wire, cards: extra }, expected)).toEqual({
        ok: false,
        issues: ['$.cards.1: does not echo present/cups_03'],
      });
      expect(
        parseModelOutput({ ...wire, reflectionPrompts: { prompt1: 'What?' } }, expected),
      ).toEqual({ ok: false, issues: ['$.reflectionPrompts: 1, expected 2'] });
    });
  });
});

// Prompt v2 (tester feedback on v1: too general): answer first, plain words,
// the same output contract so the app needs no update.
describe('reading prompt v2', () => {
  const v1 = READING_TEMPLATES.v1;
  const v2 = READING_TEMPLATES.v2;

  it('keeps the v1 output contract, data shape and style notes', () => {
    expect(v2.outputSchema).toEqual(v1.outputSchema);
    expect(Object.keys(v2.data)).toEqual(Object.keys(v1.data));
    expect(v2.data.spreads).toEqual(v1.data.spreads);
    expect(v2.data.images).toEqual(v1.data.images);
    expect(v2.styles).toEqual(v1.styles);
  });

  it('asks for a direct, plain answer in the first overview sentence', () => {
    const system = systemPrompt('v2');
    expect(system).toContain('**Answer first.**');
    expect(system).toContain("The overview's first sentence answers the question directly");
    expect(system).toContain('With no question, it names the reading');
    expect(system).toContain('**Plain words.**');
    expect(system).toMatch(/`overview`: two or three sentences: first the direct answer/);
    expect(systemPrompt('v1')).not.toContain('Answer first');
  });

  it('restates the answer-first check in the user message, with and without a question', () => {
    const request = {
      spreadId: 'single',
      locale: 'uk' as const,
      cards: [{ positionId: 'focus', cardId: 'swords_02', reversed: false }],
    };
    const asked = buildReadingPrompt({ ...request, question: 'Чи варто міняти роботу?' }, 'v2');
    const empty = buildReadingPrompt({ ...request, question: null }, 'v2');
    if (!asked.ok || !empty.ok) {
      throw new Error('build failed');
    }
    expect(asked.input.promptVersion).toBe('v2');
    expect(asked.input.user).toContain("the overview's first sentence answers the question");
    expect(asked.input.user).toContain(v2.data.phrases.withQuestion);
    expect(empty.input.user).toContain(v2.data.phrases.noQuestion);
    expect(v2.data.phrases.noQuestion).toMatch(/main theme plainly/);
  });
});
