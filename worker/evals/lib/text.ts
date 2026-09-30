import type { Locale } from './types';

// Shared with the Worker's safety layers (one normalisation for L3 and graders).
export { letterTokens, normalize } from '../../src/safety/text';

function stringAt(value: unknown): string {
  return typeof value === 'string' ? value : '';
}

/**
 * The prose of a reading (title, overview, interpretations, synthesis,
 * reflection prompts), one entry per field, in wire order. Non-string parts
 * are ignored; the schema grader reports them.
 */
export function readingTexts(reading: Readonly<Record<string, unknown>>): string[] {
  const texts = [stringAt(reading['title']), stringAt(reading['overview'])];
  // Keyed objects on the wire (03 §9.2); lists in older recordings.
  const cards = reading['cards'];
  if (typeof cards === 'object' && cards !== null) {
    for (const card of Object.values(cards) as unknown[]) {
      if (typeof card === 'object' && card !== null) {
        texts.push(stringAt((card as Record<string, unknown>)['interpretation']));
      }
    }
  }
  texts.push(stringAt(reading['synthesis']));
  const prompts = reading['reflectionPrompts'];
  if (typeof prompts === 'object' && prompts !== null) {
    for (const prompt of Object.values(prompts) as unknown[]) {
      texts.push(stringAt(prompt));
    }
  }
  return texts.filter((text) => text !== '');
}

/**
 * Word count used for the 01 §7.4 length targets. Japanese has no spaces, so
 * it is counted in `Intl.Segmenter` word segments.
 */
export function countWords(text: string, locale: Locale): number {
  if (locale === 'ja') {
    return countJapanese(text);
  }
  return text.split(/[^\p{L}\p{M}\p{N}'’-]+/u).filter((word) => /[\p{L}\p{N}]/u.test(word)).length;
}

function countJapanese(text: string): number {
  let words = 0;
  for (const segment of new Intl.Segmenter('ja', { granularity: 'word' }).segment(text)) {
    if (segment.isWordLike === true) {
      words++;
    }
  }
  return words;
}
