import { describe, expect, it } from 'vitest';
import { SPREAD_IDS } from '../../../src/config/schema';
import {
  checkSpread,
  graphemeCount,
  validateReading,
  type ReadingRequestInput,
} from '../../../src/domain/spreadValidation';

const ENABLED = [...SPREAD_IDS];
const CONFIG = { enabledSpreads: ENABLED, questionMaxChars: 300 };

function request(extra: Partial<ReadingRequestInput> = {}): ReadingRequestInput {
  return {
    spread: { id: 'three_ppf', version: 1 },
    cards: [
      { positionId: 'future', cardId: 'pentacles_14', reversed: false },
      { positionId: 'past', cardId: 'major_16', reversed: false },
      { positionId: 'present', cardId: 'cups_03', reversed: true },
    ],
    question: '  How can I approach the change?\u0007  ',
    locale: 'de',
    ...extra,
  };
}

describe('checkSpread (03 §9.1, RC2)', () => {
  it('accepts a generated spread and version, with its positions in draw order', () => {
    expect(checkSpread({ id: 'three_ppf', version: 1 }, ENABLED)).toEqual({
      ok: true,
      positionIds: ['past', 'present', 'future'],
    });
  });

  it('rejects an unknown spread or version, and a disabled one', () => {
    expect(checkSpread({ id: 'nope', version: 1 }, ENABLED)).toEqual({
      ok: false,
      reason: 'unknownSpread',
    });
    expect(checkSpread({ id: 'single', version: 2 }, ENABLED)).toEqual({
      ok: false,
      reason: 'unknownSpread',
    });
    expect(checkSpread({ id: 'single', version: 1 }, ['three_ppf'])).toEqual({
      ok: false,
      reason: 'disabled',
    });
  });
});

describe('validateReading (03 §9.1; RC1, RC45)', () => {
  it('orders the cards by position and normalises the question', () => {
    const result = validateReading(request(), CONFIG);
    expect(result).toEqual({
      ok: true,
      reading: {
        spreadId: 'three_ppf',
        cards: [
          { positionId: 'past', cardId: 'major_16', reversed: false },
          { positionId: 'present', cardId: 'cups_03', reversed: true },
          { positionId: 'future', cardId: 'pentacles_14', reversed: false },
        ],
        question: 'How can I approach the change?',
        locale: 'de',
      },
    });
  });

  it('treats a missing question as none', () => {
    const result = validateReading(request({ question: undefined }), CONFIG);
    expect(result.ok && result.reading.question).toBe('');
  });

  it.each([
    ['a card too few', request().cards.slice(0, 2)],
    [
      'a position twice',
      [
        { positionId: 'past', cardId: 'major_16', reversed: false },
        { positionId: 'past', cardId: 'cups_03', reversed: false },
        { positionId: 'future', cardId: 'pentacles_14', reversed: false },
      ],
    ],
    [
      'a card twice',
      [
        { positionId: 'past', cardId: 'major_16', reversed: false },
        { positionId: 'present', cardId: 'major_16', reversed: true },
        { positionId: 'future', cardId: 'pentacles_14', reversed: false },
      ],
    ],
    [
      'an unknown card',
      [
        { positionId: 'past', cardId: 'major_22', reversed: false },
        { positionId: 'present', cardId: 'cups_03', reversed: true },
        { positionId: 'future', cardId: 'pentacles_14', reversed: false },
      ],
    ],
    [
      'a position of another spread',
      [
        { positionId: 'past', cardId: 'major_16', reversed: false },
        { positionId: 'present', cardId: 'cups_03', reversed: true },
        { positionId: 'outcome', cardId: 'pentacles_14', reversed: false },
      ],
    ],
  ])('rejects %s as SPREAD_INVALID cards', (_name, cards) => {
    expect(validateReading(request({ cards }), CONFIG)).toEqual({
      ok: false,
      error: 'spread',
      reason: 'cards',
    });
  });

  it('reports the spread reason before the cards', () => {
    expect(validateReading(request({ spread: { id: 'x', version: 1 } }), CONFIG)).toMatchObject({
      error: 'spread',
      reason: 'unknownSpread',
    });
  });

  it('counts grapheme clusters, not UTF-16 units (RC45)', () => {
    expect(graphemeCount('👩‍👩‍👧‍👦é')).toBe(2);
    const emoji = '👍🏽'.repeat(300);
    expect(validateReading(request({ question: emoji }), CONFIG).ok).toBe(true);
    expect(validateReading(request({ question: `${emoji}!` }), CONFIG)).toEqual({
      ok: false,
      error: 'question',
      graphemes: 301,
    });
  });
});
