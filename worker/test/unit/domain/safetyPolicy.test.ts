import { describe, expect, it } from 'vitest';
import {
  CRISIS_DIRECTORY,
  DECLINED_LIMIT_REASON,
  declinedLimitReached,
  declinedSafety,
  MAX_CRISIS_RESOURCES,
  MODERATION_CATEGORY_MAP,
  moderationInputCategory,
  moderationOutputFlagged,
  SAFETY_POLICY,
  selectCrisisResources,
  type CrisisDirectory,
  type CrisisResource,
} from '../../../src/domain/safetyPolicy';
import { REFUSAL_CATEGORIES } from '../../../src/domain/types';

const res = (name: string, languages: string[] = []): CrisisResource => ({
  name,
  url: `https://${name}.example`,
  languages,
  verifiedAt: null,
});

const DIR: CrisisDirectory = {
  countries: {
    DE: [res('de-1', ['de']), res('de-2', ['de']), res('de-3', ['de'])],
    CA: [res('ca-en', ['en']), res('ca-fr', ['fr'])],
    BR: [res('br-1', ['pt'])],
  },
  localeFallback: { de: 'DE', pt: 'BR', ar: null },
  international: [res('intl')],
};

describe('SAFETY_POLICY (03 §9.4, GLOSSARY §5.2)', () => {
  it('has the canonical row for every category', () => {
    expect(Object.keys(SAFETY_POLICY).sort()).toEqual([...REFUSAL_CATEGORIES].sort());
    const pascal = (c: string) =>
      c.replace(/(^|_)([a-z])/gu, (_m, _s: string, ch: string) => ch.toUpperCase());
    for (const category of REFUSAL_CATEGORIES) {
      expect(SAFETY_POLICY[category].messageKey).toBe(`safetyDeclined${pascal(category)}`);
    }
    const crisis = REFUSAL_CATEGORIES.filter((c) => SAFETY_POLICY[c].crisisResources);
    expect(crisis).toEqual(['self_harm', 'harm_to_others']);
    const noRephrase = REFUSAL_CATEGORIES.filter((c) => !SAFETY_POLICY[c].canRephrase);
    expect(noRephrase).toEqual(['self_harm', 'harm_to_others', 'sexual_minors']);
    expect(REFUSAL_CATEGORIES.filter((c) => SAFETY_POLICY[c].metricOnly)).toEqual([
      'sexual_minors',
    ]);
  });
});

describe('selectCrisisResources (03 §9.5)', () => {
  it('uses cf.country, at most three entries, international always last', () => {
    expect(selectCrisisResources('de', 'en', DIR).map((r) => r.name)).toEqual([
      'de-1',
      'de-2',
      'intl',
    ]);
    expect(selectCrisisResources('DE', 'de', DIR)).toHaveLength(MAX_CRISIS_RESOURCES);
  });

  it('prefers entries in the reading language', () => {
    expect(selectCrisisResources('CA', 'fr', DIR).map((r) => r.name)).toEqual([
      'ca-fr',
      'ca-en',
      'intl',
    ]);
  });

  it('falls back to the locale country, then to international only', () => {
    expect(selectCrisisResources('XX', 'pt', DIR).map((r) => r.name)).toEqual(['br-1', 'intl']);
    expect(selectCrisisResources(null, 'de', DIR).map((r) => r.name)).toEqual([
      'de-1',
      'de-2',
      'intl',
    ]);
    expect(selectCrisisResources(undefined, 'ar', DIR).map((r) => r.name)).toEqual(['intl']);
    expect(selectCrisisResources('T1', 'ko', DIR).map((r) => r.name)).toEqual(['intl']);
  });

  it('works on the generated directory', () => {
    const picked = selectCrisisResources('DE', 'de');
    expect(picked.length).toBeGreaterThan(1);
    expect(picked.length).toBeLessThanOrEqual(MAX_CRISIS_RESOURCES);
    expect(picked.at(-1)).toEqual(CRISIS_DIRECTORY.international[0]);
  });
});

describe('declinedSafety', () => {
  it('carries crisis resources only for crisis categories', () => {
    expect(declinedSafety('self_harm', { country: 'DE', locale: 'de' }, DIR)).toEqual({
      category: 'self_harm',
      messageKey: 'safetyDeclinedSelfHarm',
      crisisResources: [DIR.countries['DE']?.[0], DIR.countries['DE']?.[1], DIR.international[0]],
      canRephrase: false,
    });
    expect(declinedSafety('health', { country: 'DE', locale: 'de' })).toEqual({
      category: 'health',
      messageKey: 'safetyDeclinedHealth',
      crisisResources: [],
      canRephrase: true,
    });
    expect(
      declinedSafety('harm_to_others', { country: null, locale: 'ar' }).crisisResources,
    ).toEqual(CRISIS_DIRECTORY.international);
  });
});

describe('moderation (RC97)', () => {
  it('maps flagged question categories to the nearest refusal category with a fixed priority', () => {
    expect(
      moderationInputCategory({
        kind: 'ok',
        flagged: true,
        categories: ['harassment', 'violence'],
      }),
    ).toBe('harm_to_others');
    expect(
      moderationInputCategory({
        kind: 'ok',
        flagged: true,
        categories: ['violence', 'self-harm/intent', 'sexual/minors'],
      }),
    ).toBe('self_harm');
    expect(
      moderationInputCategory({ kind: 'ok', flagged: true, categories: ['hate/threatening'] }),
    ).toBe('hate_or_harassment');
    expect(MODERATION_CATEGORY_MAP['sexual/minors']).toBe('sexual_minors');
  });

  it('never blocks on an error, an unflagged result or an unmapped category', () => {
    expect(moderationInputCategory({ kind: 'error' })).toBeNull();
    expect(
      moderationInputCategory({ kind: 'ok', flagged: false, categories: ['hate'] }),
    ).toBeNull();
    expect(
      moderationInputCategory({ kind: 'ok', flagged: true, categories: ['sexual'] }),
    ).toBeNull();
  });

  it('counts a flagged output as an L3 failure, an error as nothing', () => {
    expect(moderationOutputFlagged({ kind: 'ok', flagged: true, categories: ['sexual'] })).toBe(
      true,
    );
    expect(moderationOutputFlagged({ kind: 'ok', flagged: false, categories: [] })).toBe(false);
    expect(moderationOutputFlagged({ kind: 'error' })).toBe(false);
  });
});

describe('declinedLimitReached (RC74)', () => {
  it('stops the reading after maxDeclinedPerDay declined readings', () => {
    expect(declinedLimitReached(9, 10)).toBe(false);
    expect(declinedLimitReached(10, 10)).toBe(true);
    expect(declinedLimitReached(11, 10)).toBe(true);
    expect(declinedLimitReached(0, 1)).toBe(false);
    expect(DECLINED_LIMIT_REASON).toBe('declinedLimit');
  });
});
