import { describe, expect, it } from 'vitest';
import { refundRule } from '../../../src/domain/ledgerRules';
import { validateReadingOutput } from '../../../src/domain/outputValidator';
import { declinedSafety, SAFETY_POLICY } from '../../../src/domain/safetyPolicy';
import {
  CLASSIFICATIONS,
  isRefusalCategory,
  LOCALES,
  type Classification,
  type Locale,
} from '../../../src/domain/types';
import type { ExpectedReading } from '../../../src/prompts/templates';
import { L1_BLOCK_CATEGORIES } from '../../../src/safety/lexiconSource';
import { prefilter } from '../../../src/safety/prefilter';
import ar from '../../fixtures/safety/ar.jsonl?raw';
import de from '../../fixtures/safety/de.jsonl?raw';
import en from '../../fixtures/safety/en.jsonl?raw';
import es from '../../fixtures/safety/es.jsonl?raw';
import fr from '../../fixtures/safety/fr.jsonl?raw';
import it_ from '../../fixtures/safety/it.jsonl?raw';
import ja from '../../fixtures/safety/ja.jsonl?raw';
import ko from '../../fixtures/safety/ko.jsonl?raw';
import nl from '../../fixtures/safety/nl.jsonl?raw';
import pt from '../../fixtures/safety/pt.jsonl?raw';
import tr from '../../fixtures/safety/tr.jsonl?raw';
import uk from '../../fixtures/safety/uk.jsonl?raw';
import { fakeReading } from '../../fakes/FakeAiProvider';

/**
 * The safety regression corpus (03 §15.2, Sprint 8.4), run in every PR:
 * `test/fixtures/safety/<locale>.jsonl`, one line per question with the
 * category it must end in and `l1`, the category the L1 prefilter must
 * decline it with before any model call (`null` = it reaches the model).
 * Questions that pass L1 get a scripted model answer (the L2
 * classification): the pipeline must end in the same category, with the
 * policy's `messageKey`, `canRephrase`, crisis resources and no charge.
 */
interface CorpusLine {
  readonly id: string;
  readonly locale: Locale;
  readonly category: Classification;
  readonly kind: string;
  readonly text: string;
  readonly l1: (typeof L1_BLOCK_CATEGORIES)[number] | null;
}

const FILES: Readonly<Record<Locale, string>> = {
  en,
  ar,
  de,
  es,
  fr,
  it: it_,
  ja,
  ko,
  nl,
  pt,
  tr,
  uk,
};

const CORPUS: Readonly<Record<Locale, readonly CorpusLine[]>> = Object.fromEntries(
  LOCALES.map((locale) => [
    locale,
    FILES[locale]
      .split('\n')
      .filter((line) => line.trim() !== '')
      .map((line) => JSON.parse(line) as CorpusLine),
  ]),
) as Record<Locale, CorpusLine[]>;

const EXPECTED: ExpectedReading = {
  cards: [{ positionId: 'focus', cardId: 'major_00', reversed: false }],
  reflectionPrompts: 2,
};

/** The scripted model answer of L2 for a question that passed L1. */
function scriptedOutput(category: Classification): unknown {
  return category === 'none'
    ? fakeReading(EXPECTED)
    : {
        classification: category,
        title: '',
        overview: '',
        cards: [],
        synthesis: '',
        reflectionPrompts: [''],
      };
}

type Outcome =
  | { readonly status: 'completed' }
  | { readonly status: 'declined'; readonly layer: 'L1' | 'L2'; readonly category: Classification };

/** L1 → (model) → L2/L3, as `ReadingService` runs them. */
function runPipeline(line: CorpusLine): Outcome {
  const l1 = prefilter(line.text, line.locale);
  if (l1.kind === 'block') {
    return { status: 'declined', layer: 'L1', category: l1.category };
  }
  const verdict = validateReadingOutput(scriptedOutput(line.category), {
    locale: 'en',
    expected: EXPECTED,
  });
  if (verdict.kind === 'declined') {
    return { status: 'declined', layer: 'L2', category: verdict.category };
  }
  expect(verdict.kind).toBe('answered');
  return { status: 'completed' };
}

describe('safety regression corpus', () => {
  it.each(LOCALES)('%s has at least 20 questions per L1 category and benign controls', (locale) => {
    const lines = CORPUS[locale];
    for (const category of L1_BLOCK_CATEGORIES) {
      expect(lines.filter((line) => line.category === category).length).toBeGreaterThanOrEqual(20);
      // High-precision patterns catch a real share of each L1 category…
      expect(lines.filter((line) => line.l1 === category).length).toBeGreaterThanOrEqual(8);
    }
    // …and never a benign control.
    const benign = lines.filter((line) => line.category === 'none');
    expect(benign.length).toBeGreaterThanOrEqual(50);
    expect(benign.every((line) => line.l1 === null)).toBe(true);
    for (const line of lines) {
      expect(CLASSIFICATIONS).toContain(line.category);
      expect(line.locale).toBe(locale);
    }
  });

  it.each(LOCALES)('%s: the L1 prefilter decides exactly as recorded', (locale) => {
    const wrong = CORPUS[locale]
      .map((line) => ({ line, got: prefilter(line.text, locale) }))
      .filter(({ line, got }) => (got.kind === 'block' ? got.category : null) !== line.l1)
      .map(
        ({ line, got }) => `${line.id}: expected ${String(line.l1)}, got ${JSON.stringify(got)}`,
      );
    expect(wrong).toEqual([]);
  });

  it.each(LOCALES)('%s: every question ends in its category, uncharged when declined', (locale) => {
    for (const line of CORPUS[locale]) {
      const outcome = runPipeline(line);
      if (line.category === 'none') {
        expect(outcome, line.id).toEqual({ status: 'completed' });
        continue;
      }
      expect(outcome, line.id).toMatchObject({ status: 'declined', category: line.category });
      if (!isRefusalCategory(line.category)) {
        throw new Error(`bad category in ${line.id}`);
      }
      const safety = declinedSafety(line.category, { country: 'DE', locale });
      const policy = SAFETY_POLICY[line.category];
      expect(safety.messageKey).toBe(policy.messageKey);
      expect(safety.canRephrase).toBe(policy.canRephrase);
      expect(safety.crisisResources.length > 0).toBe(policy.crisisResources);
    }
    // A decline refunds the hold (nothing charged) and counts as a decline; a failure does not (RC74).
    expect(refundRule('declined')).toMatchObject({
      ledgerReason: 'reading_refund',
      status: 'declined',
      countsAsDecline: true,
    });
    expect(refundRule('failed').countsAsDecline).toBe(false);
  });
});
