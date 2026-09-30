import { describe, expect, it } from 'vitest';
import {
  readingText,
  regenerationNote,
  validateReadingOutput,
  type AnsweredReading,
} from '../../../src/domain/outputValidator';
import type { ExpectedReading } from '../../../src/prompts/templates';
import { safetyLexicons } from '../../../src/safety/lexicons';

const EXPECTED: ExpectedReading = {
  cards: [
    { positionId: 'past', cardId: 'major_16', reversed: false },
    { positionId: 'present', cardId: 'cups_03', reversed: true },
    { positionId: 'future', cardId: 'pentacles_14', reversed: false },
  ],
  reflectionPrompts: 3,
};

const EN =
  'The Tower in the past position suggests that an old structure in your life may have been shaken. ' +
  'Consider what you learned from that change and how it can help you approach the present with more openness and care for yourself.';
const DE =
  'Der Turm in der Vergangenheit zeigt, dass eine alte Struktur in deinem Leben erschüttert wurde. ' +
  'Frage dich, was du aus dieser Veränderung gelernt hast und wie es dir helfen kann, der Gegenwart mit mehr Offenheit zu begegnen.';

function answered(text = EN, overrides: Partial<AnsweredReading> = {}): AnsweredReading {
  return {
    classification: 'none',
    title: 'A turning point',
    overview: text,
    cards: EXPECTED.cards.map((card) => ({ ...card, interpretation: text })),
    synthesis: text,
    reflectionPrompts: ['What is shifting?', 'What would help?', 'What can wait?'],
    ...overrides,
  };
}

const ctx = { locale: 'en' as const, expected: EXPECTED };

describe('validateReadingOutput (L3)', () => {
  it('accepts a clean answered reading', () => {
    const reading = answered();
    expect(validateReadingOutput(reading, ctx)).toEqual({ kind: 'answered', reading });
    expect(
      validateReadingOutput(answered(DE), {
        locale: 'de',
        expected: EXPECTED,
        lexicon: safetyLexicons().de,
      }),
    ).toMatchObject({ kind: 'answered' });
  });

  it('returns the L2 decline of a classified answer', () => {
    const declined = {
      classification: 'gambling',
      title: '',
      overview: '',
      cards: [],
      synthesis: '',
      reflectionPrompts: [''],
    };
    expect(validateReadingOutput(declined, ctx)).toEqual({
      kind: 'declined',
      category: 'gambling',
    });
  });

  it('classifies zod, echo, length and prompt-count issues', () => {
    expect(validateReadingOutput('not json', ctx)).toMatchObject({
      kind: 'invalid',
      violations: [{ kind: 'schema' }],
    });
    const swapped = answered(EN, {
      cards: [...EXPECTED.cards].reverse().map((card) => ({ ...card, interpretation: EN })),
    });
    const echo = validateReadingOutput(swapped, ctx);
    expect(echo.kind === 'invalid' && echo.violations.map((v) => v.kind)).toContain('echo');
    const short = validateReadingOutput(answered(EN, { cards: [] }), ctx);
    expect(short.kind === 'invalid' && short.violations.map((v) => v.kind)).toContain('schema');
    const twoCards = answered(EN, {
      cards: EXPECTED.cards.slice(0, 2).map((card) => ({ ...card, interpretation: EN })),
    });
    const drawn = validateReadingOutput(twoCards, ctx);
    expect(drawn.kind === 'invalid' && drawn.violations.map((v) => v.kind)).toEqual(['echo']);
    expect(validateReadingOutput(answered(EN, { title: 'x'.repeat(81) }), ctx)).toMatchObject({
      kind: 'invalid',
      violations: [{ kind: 'length' }],
    });
    expect(
      validateReadingOutput(answered(EN, { reflectionPrompts: ['Only one?'] }), ctx),
    ).toMatchObject({
      kind: 'invalid',
      violations: [{ kind: 'reflection_prompts', detail: '$.reflectionPrompts: 1, expected 3' }],
    });
  });

  it('rejects forbidden claims, contact details and the wrong language', () => {
    const claim = validateReadingOutput(
      answered(EN, { synthesis: `${EN} This will definitely happen. Call 0800 111 0 111.` }),
      ctx,
    );
    expect(claim.kind).toBe('invalid');
    const kinds = claim.kind === 'invalid' ? claim.violations.map((v) => v.kind) : [];
    expect(kinds).toEqual(['forbidden_claim', 'contact']);
    expect(validateReadingOutput(answered(EN), { locale: 'de', expected: EXPECTED })).toMatchObject(
      {
        kind: 'invalid',
        violations: [{ kind: 'language' }],
      },
    );
  });

  it('lets a benign use of a lexicon stem through (pt "precisa saber")', () => {
    const pt =
      'A Torre na posição do passado sugere que uma estrutura antiga da sua vida foi abalada. ' +
      'Você precisa saber o que aprendeu com essa mudança e como isso pode ajudar você a olhar para o presente com mais abertura.';
    expect(validateReadingOutput(answered(pt), { locale: 'pt', expected: EXPECTED })).toMatchObject(
      { kind: 'answered' },
    );
  });

  it('does not fail the language check on too little text', () => {
    const tiny = answered('Ja.', { title: 'Ja' });
    expect(validateReadingOutput(tiny, { locale: 'en', expected: EXPECTED })).toMatchObject({
      kind: 'answered',
    });
  });
});

describe('readingText and regenerationNote', () => {
  it('joins the prose in wire order and lists violations', () => {
    const text = readingText(answered('x'));
    expect(text.split('\n')).toEqual([
      'A turning point',
      'x',
      'x',
      'x',
      'x',
      'x',
      'What is shifting?',
      'What would help?',
      'What can wait?',
    ]);
    expect(
      regenerationNote([
        { kind: 'length', detail: '$.title: longer than 80 characters' },
        { kind: 'contact', detail: 'contact detail url: https://x.example' },
      ]),
    ).toBe('- $.title: longer than 80 characters\n- contact detail url: https://x.example');
  });
});
