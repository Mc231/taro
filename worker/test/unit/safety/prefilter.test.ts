import { describe, expect, it } from 'vitest';
import { LOCALES, REFUSAL_CATEGORIES } from '../../../src/domain/types';
import {
  L1_BLOCK_CATEGORIES,
  LEXICON_SOURCES,
  isL1BlockCategory,
} from '../../../src/safety/lexiconSource';
import { loadSafetyLexicons, type GeneratedLexicons } from '../../../src/safety/lexicons';
import { lexiconLocales, prefilter } from '../../../src/safety/prefilter';
import { foldText } from '../../../src/safety/text';

describe('foldText', () => {
  it('case-folds, unifies apostrophes and collapses whitespace', () => {
    expect(foldText('  I’M   So\tTIRED  ')).toBe("i'm so tired");
  });

  it('folds Latin diacritics only', () => {
    expect(foldText('Ölmek İSTİYORUM çabuk şimdi ğ ı')).toBe('olmek istiyorum cabuk simdi g i');
    expect(foldText('Suicídio, être, Straße, Øre, Æble, Œuvre, Łódź, Đ')).toBe(
      'suicidio, etre, strasse, ore, aeble, oeuvre, lodz, d',
    );
    // Cyrillic й/ї and Japanese dakuten keep their marks.
    expect(foldText('Мій її')).toBe('мій її');
    expect(foldText('ガがぱ')).toBe('ガがぱ');
  });

  it('removes invisible characters and Arabic harakat, unifies alef, yeh and teh marbuta', () => {
    expect(foldText('sui​ci­de')).toBe('suicide');
    expect(foldText('أُرِيدُ إنهاء آخر ـــ مستشفى رسالة')).toBe(
      'اريد انهاء اخر  مستشفي رساله'.replace('  ', ' '),
    );
  });
});

describe('prefilter', () => {
  it('passes an empty or missing question with no hints', () => {
    expect(prefilter(null, 'en')).toEqual({ kind: 'pass', hints: [] });
    expect(prefilter(undefined, 'de')).toEqual({ kind: 'pass', hints: [] });
    expect(prefilter('   ', 'fr')).toEqual({ kind: 'pass', hints: [] });
  });

  it('blocks high-precision crisis patterns with the deciding rule', () => {
    expect(prefilter('I want to kill myself tonight', 'en')).toEqual({
      kind: 'block',
      category: 'self_harm',
      rule: 'en:sh.kill_myself',
    });
    expect(prefilter('Will I get away with poisoning my boss?', 'en')).toMatchObject({
      kind: 'block',
      category: 'harm_to_others',
    });
    expect(
      prefilter('Is the 15-year-old next door interested in me sexually?', 'en'),
    ).toMatchObject({ kind: 'block', category: 'sexual_minors' });
  });

  it('folds before matching (case, diacritics, zero-width characters)', () => {
    expect(prefilter('SUÏ​CIDE', 'en')).toMatchObject({ kind: 'block', category: 'self_harm' });
    expect(prefilter('Ich denke an SELBSTMÖRD', 'de')).toMatchObject({ kind: 'block' });
    expect(prefilter('Kendimi öldürmek istiyorum', 'tr')).toMatchObject({
      kind: 'block',
      category: 'self_harm',
    });
  });

  it('also checks the English lexicon and the lexicon of another script', () => {
    expect(prefilter('Ich will nicht mehr, i want to kill myself', 'de')).toMatchObject({
      kind: 'block',
      rule: 'en:sh.kill_myself',
    });
    expect(prefilter('Will my exams go ok? もう死にたい', 'en')).toMatchObject({
      kind: 'block',
      rule: 'ja:sh.want_to_die',
    });
    expect(lexiconLocales('hello', 'en')).toEqual(['en']);
    expect(lexiconLocales('hallo 안녕 مرحبا привіт 今日', 'de')).toEqual([
      'de',
      'en',
      'ja',
      'ko',
      'ar',
      'uk',
    ]);
  });

  it('turns lower-precision matches into hints for the model', () => {
    const result = prefilter('Will I win the lottery and invest in bitcoin?', 'en');
    expect(result.kind).toBe('pass');
    expect(result.kind === 'pass' && [...result.hints].sort()).toEqual(['financial', 'gambling']);
    expect(prefilter('Should I get revenge on him?', 'en')).toEqual({
      kind: 'pass',
      hints: ['harm_to_others'],
    });
  });

  it('keeps benign look-alikes clear', () => {
    for (const question of [
      'This project is killing me. How do I pace myself?',
      'What does the Death card mean?',
      'Should I shoot him a message tonight?',
      'Does the Lovers card mean my 15-year-old daughter will find love?',
      'How can I talk to my 14-year-old son about sex?',
      'Our relationship is 12 years old, how can our sex life grow?',
    ]) {
      expect(prefilter(question, 'en').kind, question).toBe('pass');
    }
  });

  it('prefers self_harm when several crisis categories fire', () => {
    expect(prefilter('I want to kill myself and shoot the people who laughed', 'en')).toMatchObject(
      {
        kind: 'block',
        category: 'self_harm',
      },
    );
  });

  it('honours unless patterns and custom lexicons', () => {
    const empty = {
      reviewed: true,
      l1: [],
      l3: { rules: [], allowedContexts: [], nonClaimSpans: [] },
    };
    const data = {
      version: 1,
      locales: Object.fromEntries(LOCALES.map((l) => [l, empty])),
    } as unknown as GeneratedLexicons & { locales: Record<string, unknown> };
    (data.locales as Record<string, unknown>)['en'] = {
      ...empty,
      l1: [
        {
          id: 'x',
          category: 'harm_to_others',
          severity: 'high',
          patterns: ['boom'],
          unless: ['fireworks'],
        },
        { id: 'y', category: 'health', severity: 'hint', patterns: ['boom'], unless: [] },
      ],
    };
    const lexicons = loadSafetyLexicons(data);
    expect(prefilter('boom', 'en', lexicons)).toMatchObject({ kind: 'block', rule: 'en:x' });
    expect(prefilter('boom fireworks', 'en', lexicons)).toEqual({
      kind: 'pass',
      hints: ['health'],
    });
  });
});

describe('lexicon sources', () => {
  it('has English reviewed and the other locales drafted', () => {
    expect(LEXICON_SOURCES.en.reviewed).toBe(true);
    for (const locale of LOCALES.filter((l) => l !== 'en')) {
      expect(LEXICON_SOURCES[locale].reviewed, locale).toBe(false);
    }
  });

  it('covers every L1 category with high rules and every category with a rule, per locale', () => {
    for (const locale of LOCALES) {
      const rules = LEXICON_SOURCES[locale].l1;
      for (const category of L1_BLOCK_CATEGORIES) {
        expect(
          rules.some((r) => r.category === category && r.severity === 'high'),
          `${locale} ${category}`,
        ).toBe(true);
      }
      for (const category of REFUSAL_CATEGORIES) {
        expect(
          rules.some((r) => r.category === category),
          `${locale} ${category}`,
        ).toBe(true);
      }
      expect(LEXICON_SOURCES[locale].l3.certainty.length).toBeGreaterThan(0);
      expect(LEXICON_SOURCES[locale].l3.forbiddenClaims.length).toBeGreaterThan(0);
    }
    expect(isL1BlockCategory('self_harm')).toBe(true);
    expect(isL1BlockCategory('health')).toBe(false);
  });
});
