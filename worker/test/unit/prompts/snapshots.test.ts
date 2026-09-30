import { describe, expect, it } from 'vitest';
import spreadsFeed from '../../../src/generated/deck/spreads.json';
import { LOCALES } from '../../../src/domain/types';
import { buildReadingPrompt, type ReadingPromptRequest } from '../../../src/prompts/build';
import { PROMPT_VERSIONS } from '../../../src/prompts/templates';

// 06 §7: the assembled prompt per prompt_version × locale is snapshot-tested.
// The static system prefix is one snapshot per version (it is identical for
// every locale); the user message has one per locale, plus one per spread.
// A snapshot change of a released version needs a new prompt version.
const SNAPSHOTS = './__snapshots__';

const CASE: Omit<ReadingPromptRequest, 'locale'> = {
  spreadId: 'three_ppf',
  question: 'How can I approach the change at work?',
  prefilterHints: [],
  cards: [
    { positionId: 'past', cardId: 'major_16', reversed: false },
    { positionId: 'present', cardId: 'cups_03', reversed: true },
    { positionId: 'future', cardId: 'pentacles_14', reversed: false },
  ],
};

function built(request: ReadingPromptRequest, version: (typeof PROMPT_VERSIONS)[number]) {
  const result = buildReadingPrompt(request, version);
  if (!result.ok) {
    throw new Error(result.error);
  }
  return result.input;
}

describe.each(PROMPT_VERSIONS)('reading prompt %s snapshots', (version) => {
  it('system prefix', async () => {
    await expect(`${built({ ...CASE, locale: 'en' }, version).system}\n`).toMatchFileSnapshot(
      `${SNAPSHOTS}/reading.${version}.system.txt`,
    );
  });

  it.each(LOCALES)('user message, locale %s', async (locale) => {
    await expect(`${built({ ...CASE, locale }, version).user}\n`).toMatchFileSnapshot(
      `${SNAPSHOTS}/reading.${version}.user.${locale}.txt`,
    );
  });

  it.each(spreadsFeed.spreads.map((s) => s.id))('user message, spread %s', async (spreadId) => {
    const spread = spreadsFeed.spreads.find((s) => s.id === spreadId);
    const cards = (spread?.positions ?? []).map((p, i) => ({
      positionId: p.id,
      cardId: ['major_02', 'swords_09', 'cups_10', 'wands_01', 'pentacles_05'][i % 5] ?? 'major_00',
      reversed: i % 3 === 1,
    }));
    // Cards repeat after five positions in the Celtic Cross; use distinct ones there.
    const unique = cards.map((c, i) => (i >= 5 ? { ...c, cardId: `major_${String(10 + i)}` } : c));
    await expect(
      `${built({ spreadId, locale: 'en', question: null, cards: unique }, version).user}\n`,
    ).toMatchFileSnapshot(`${SNAPSHOTS}/reading.${version}.spread.${spreadId}.txt`);
  });
});
