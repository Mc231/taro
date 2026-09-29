import { describe, expect, it } from 'vitest';
import cards from '../../../src/generated/deck/cards.json';
import promptEn from '../../../src/generated/deck_prompt.en.json';

// Phase 5 Sprint 5.4 stub (RC26): the prompt feed and the card feed that
// `tools/content build` writes must describe the same 78 cards. The Worker
// suite owns this test from Phase 8.
describe('generated deck parity', () => {
  const cardIds = cards.cards.map((card) => card.id);
  const promptIds = Object.keys(promptEn.cards);

  it('deck_prompt.en.json card IDs equal deck/cards.json card IDs', () => {
    expect([...promptIds].sort()).toEqual([...cardIds].sort());
  });

  it('covers the 78 canonical cards once each', () => {
    expect(cardIds).toHaveLength(78);
    expect(new Set(cardIds).size).toBe(78);
    for (const id of cardIds) {
      expect(id).toMatch(/^(major_(0\d|1\d|2[01])|(wands|cups|swords|pentacles)_(0[1-9]|1[0-4]))$/);
    }
  });

  it('both feeds carry the same content version', () => {
    expect(promptEn.version).toBe(cards.version);
    expect(promptEn.locale).toBe('en');
  });
});
