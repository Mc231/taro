import bannedYaml from '../../../../tools/store_copy/banned_phrases.yaml?raw';
import { describe, expect, it } from 'vitest';
import { buildPhraseBook, CERTAINTY_PATTERNS, NON_CLAIM_SPANS } from '../../../evals/lib/phrases';
import { compileSafetyLexicons, renderSafetyLexicons } from '../../../src/admin/safetyLexicons';
import generated from '../../../src/generated/safety_lexicons.json';
import { LOCALES } from '../../../src/domain/types';
import { findContacts } from '../../../src/safety/contacts';
import { LEXICON_SOURCES } from '../../../src/safety/lexiconSource';
import { findForbiddenClaims, safetyLexicons } from '../../../src/safety/lexicons';

const LEX = safetyLexicons();

function claims(text: string, locale: (typeof LOCALES)[number]): string[] {
  return findForbiddenClaims(text, LEX[locale]).map((hit) => hit.phrase);
}

describe('src/generated/safety_lexicons.json', () => {
  it('is the compiled form of the lexicon sources and banned_phrases.yaml (npm run safety:lexicons)', () => {
    expect(
      JSON.parse(renderSafetyLexicons(compileSafetyLexicons(LEXICON_SOURCES, bannedYaml))),
    ).toEqual(generated);
  });

  it('is loaded once per isolate', () => {
    expect(safetyLexicons()).toBe(LEX);
    expect(Object.keys(LEX).sort()).toEqual([...LOCALES].sort());
  });
});

describe('L3 forbidden claims', () => {
  it('holds every global banned phrase and certainty pattern of the locale (RC39)', () => {
    const book = buildPhraseBook(bannedYaml);
    for (const locale of LOCALES) {
      const phrases = new Set(LEX[locale].l3.rules.map((rule) => rule.phrase));
      for (const rule of book[locale].rules) {
        expect(phrases.has(rule.phrase), `${locale} ${rule.phrase}`).toBe(true);
      }
      for (const phrase of LEXICON_SOURCES[locale].l3.forbiddenClaims) {
        expect(phrases.has(phrase), `${locale} ${phrase}`).toBe(true);
      }
    }
  });

  it('shares the certainty and non-claim lists with the offline graders', () => {
    for (const locale of LOCALES) {
      expect(CERTAINTY_PATTERNS[locale]).toEqual(LEXICON_SOURCES[locale].l3.certainty);
      expect(NON_CLAIM_SPANS[locale]).toEqual(LEXICON_SOURCES[locale].l3.nonClaimSpans);
    }
  });

  it('rejects certainty, banned and L3-only wording', () => {
    expect(claims('This is guaranteed to work.', 'en')).toContain('guaranteed');
    expect(claims('You will definitely find love.', 'en')).toContain('will definitely');
    expect(claims('Take ibuprofen and invest in bitcoin.', 'en')).toEqual(
      expect.arrayContaining(['ibuprofen*', 'invest in']),
    );
    expect(claims('Das wird sicher gut.', 'de')).toContain('wird sicher');
    expect(claims('必ず成功します。', 'ja')).toContain('必ず');
    expect(claims('Uma leitura precisa do seu caminho.', 'pt')).toContain('precis*');
  });

  it('lets benign uses of the same words through (non-claim spans, allowed contexts)', () => {
    expect(claims('Você precisa saber o que quer. Isso precisa de tempo.', 'pt')).toEqual([]);
    expect(claims('Senza una domanda precisa, resta aperta.', 'it')).toEqual([]);
    expect(claims('Genau das ist der Punkt.', 'de')).toEqual([]);
    expect(claims('Nothing here is guaranteed; ask what will happen if you rest.', 'en')).toEqual(
      [],
    );
    expect(claims('Invest time in your relationships and invest in yourself.', 'en')).toEqual([]);
    expect(claims('This is not medical, legal, financial or psychological advice.', 'en')).toEqual(
      [],
    );
    expect(claims('Bu kesin bir sonuç değil.', 'tr')).toEqual([]);
  });

  it('Arabic: clitics and harakat still match, words that only contain the letters do not', () => {
    for (const text of ['حتما', 'حتماً', 'حتمًا سيتحقق', 'وحتما', 'فحتما', 'سيحدث حتما.']) {
      expect(claims(text, 'ar'), text).toEqual(['حتما']);
    }
    for (const text of ['الاحتمال', 'احتمالات', 'أسوأ الاحتمالات', 'باحتمال فقط', 'احتمالًا']) {
      expect(claims(text, 'ar'), text).toEqual([]);
    }
    expect(claims('وبالتأكيد', 'ar')).toEqual(['بالتأكيد']);
    expect(claims('بالتاكيد', 'ar')).toEqual(['بالتأكيد']);
    expect(claims('ومن المؤكد', 'ar')).toEqual(['من المؤكد']);
    expect(claims('وبلا شكّ', 'ar')).toEqual(['بلا شك']);
    expect(claims('للتنبؤ بالمستقبل', 'ar')).toEqual(['التنبؤ بالمستقبل']);
    expect(claims('بسحر', 'ar')).toEqual(['سحر*']);
  });

  it('ja / ko: negated certainty is not a claim, a plain one still is', () => {
    expect(claims('必ずしもそうとは限りません。', 'ja')).toEqual([]);
    expect(claims('不確実に感じるときもあります。', 'ja')).toEqual([]);
    expect(claims('必ずしも悪くないが、必ず叶う。', 'ja')).toEqual(['必ず']);
    expect(claims('確実にうまくいきます。', 'ja')).toEqual(['確実に']);
    expect(claims('반드시 그렇지는 않아요.', 'ko')).toEqual([]);
    expect(claims('반드시 나쁜 것은 아니에요.', 'ko')).toEqual([]);
    expect(claims('반드시 이루어질 거예요.', 'ko')).toEqual(['반드시']);
    expect(claims('반드시 잘될 거예요. 걱정하지 않아도 돼요.', 'ko')).toEqual(['반드시']);
  });

  it('reports the kind and source of each hit', () => {
    expect(findForbiddenClaims('A real psychic knows.', LEX.en)).toEqual(
      expect.arrayContaining([
        {
          phrase: 'real psychic',
          kind: 'supernatural',
          source: 'banned_phrases',
          match: 'real psychic',
        },
      ]),
    );
    expect(findForbiddenClaims('Take xanax.', LEX.en)).toEqual([
      { phrase: 'xanax', kind: 'claim', source: 'forbidden_claims', match: 'xanax' },
    ]);
  });
});

describe('findContacts', () => {
  it('finds URLs, domains, e-mails and phone numbers, Arabic-Indic digits included', () => {
    expect(findContacts('Visit https://example.org now')).toEqual([
      'url: https://example.org',
      'domain: example.org',
    ]);
    expect(findContacts('write to help@example.com')).toContain('email: help@example.com');
    expect(findContacts('call ٠٨٠٠ ١١١ ٠ ١١١')).toContain('phone: 0800 111 0 111');
    expect(findContacts('Call 112 now')).toEqual(['phone: 112']);
    expect(findContacts('The Tower asks for a pause.')).toEqual([]);
  });
});
