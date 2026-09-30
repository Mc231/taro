/**
 * Text normalisation shared by the safety layers (03 §9.4) and the offline
 * eval graders (`evals/lib`, RC61), so both match the same way.
 */

/** NFKC, lower-cased, curly apostrophes as `'` (mirrors `check_store_copy.normalize`). */
export function normalize(text: string): string {
  return text.normalize('NFKC').replace(/[‘’]/gu, "'").toLowerCase();
}

/** Letter tokens (Unicode letters, marks and apostrophes) of the normalised text. */
export function letterTokens(text: string): string[] {
  return normalize(text)
    .split(/[^\p{L}\p{M}']+/u)
    .map((token) => token.replace(/^'+|'+$/gu, ''))
    .filter((token) => token !== '');
}

/** Zero-width and formatting characters used to split a word past a filter. */
const INVISIBLE = /[\u00AD\u180E\u200B-\u200F\u2060-\u2064\uFEFF]/gu;

/** Latin letters without a decomposition that users type as their base letter. */
const LATIN_EXTRA: Readonly<Record<string, string>> = {
  ı: 'i',
  ß: 'ss',
  ø: 'o',
  æ: 'ae',
  œ: 'oe',
  ł: 'l',
  đ: 'd',
};

/**
 * The L1 prefilter form (03 §9.4): NFKC, case-folded, apostrophes unified,
 * invisible characters removed, **diacritics folded on Latin letters only**
 * (so "é" → "e", "ö" → "o", Turkish "ı" → "i", but Cyrillic "й"/"ї" and
 * Japanese dakuten stay), Arabic harakat and tatweel removed with alef, yeh
 * and teh marbuta unified, and whitespace collapsed. Lexicon patterns are
 * written in this form (`compileSafetyLexicons` rejects any that are not).
 */
export function foldText(text: string): string {
  const lower = text
    .normalize('NFKC')
    .replace(INVISIBLE, '')
    .replace(/[‘’ʼ`´]/gu, "'")
    .toLowerCase();
  let folded = lower
    .normalize('NFD')
    .replace(/(\p{Script=Latin})\p{M}+/gu, '$1')
    .normalize('NFC');
  for (const [from, to] of Object.entries(LATIN_EXTRA)) {
    folded = folded.replaceAll(from, to);
  }
  return folded
    .replace(/[ً-ٰٟـ]/gu, '')
    .replace(/[أإآٱ]/gu, 'ا')
    .replace(/ى/gu, 'ي')
    .replace(/ة/gu, 'ه')
    .replace(/\s+/gu, ' ')
    .trim();
}
