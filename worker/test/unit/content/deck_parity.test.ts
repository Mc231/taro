import { describe, expect, it } from 'vitest';
import cards from '../../../src/generated/deck/cards.json';
import names from '../../../src/generated/deck/names.json';
import promptAr from '../../../src/generated/deck_prompt.ar.json';
import promptDe from '../../../src/generated/deck_prompt.de.json';
import promptEn from '../../../src/generated/deck_prompt.en.json';
import promptEs from '../../../src/generated/deck_prompt.es.json';
import promptFr from '../../../src/generated/deck_prompt.fr.json';
import promptIt from '../../../src/generated/deck_prompt.it.json';
import promptJa from '../../../src/generated/deck_prompt.ja.json';
import promptKo from '../../../src/generated/deck_prompt.ko.json';
import promptNl from '../../../src/generated/deck_prompt.nl.json';
import promptPt from '../../../src/generated/deck_prompt.pt.json';
import promptTr from '../../../src/generated/deck_prompt.tr.json';
import promptUk from '../../../src/generated/deck_prompt.uk.json';

// RC26: the prompt feeds and the card feed that `tools/content build` writes
// must describe the same 78 cards. Phase 18: one prompt feed per locale, each
// carrying the glossary name that names.json gives the Worker.
interface PromptFeed {
  locale: string;
  version: number;
  cards: Record<string, { name: string }>;
}

const prompts: Record<string, PromptFeed> = {
  ar: promptAr,
  de: promptDe,
  en: promptEn,
  es: promptEs,
  fr: promptFr,
  it: promptIt,
  ja: promptJa,
  ko: promptKo,
  nl: promptNl,
  pt: promptPt,
  tr: promptTr,
  uk: promptUk,
};
const cardNames: Record<string, Record<string, string>> = names.cards;

describe('generated deck parity', () => {
  const cardIds = cards.cards.map((card) => card.id);

  it('covers the 78 canonical cards once each', () => {
    expect(cardIds).toHaveLength(78);
    expect(new Set(cardIds).size).toBe(78);
    for (const id of cardIds) {
      expect(id).toMatch(/^(major_(0\d|1\d|2[01])|(wands|cups|swords|pentacles)_(0[1-9]|1[0-4]))$/);
    }
  });

  it('has a prompt feed for each of the 12 locales', () => {
    expect(Object.keys(prompts)).toHaveLength(12);
  });

  for (const [locale, feed] of Object.entries(prompts)) {
    describe(`deck_prompt.${locale}.json`, () => {
      it('has the card IDs of deck/cards.json', () => {
        expect(Object.keys(feed.cards).sort()).toEqual([...cardIds].sort());
      });

      it('carries its locale and the content version', () => {
        expect(feed.locale).toBe(locale);
        expect(feed.version).toBe(cards.version);
      });

      it('uses the names.json name for every card', () => {
        for (const id of cardIds) {
          expect(feed.cards[id]?.name, id).toBe(cardNames[id]?.[locale]);
        }
      });
    });
  }
});
