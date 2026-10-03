import { normalize } from './text';

/**
 * The phrase syntax of `tools/store_copy/banned_phrases.yaml` (RC39), shared
 * by the Worker's L3 lexicon (03 §9.4) and the offline graders: NFKC + lower
 * case, tokens on word boundaries, a trailing `*` makes a stem, and
 * `match: substring` locales (ja) match anywhere.
 *
 * Arabic attaches clitics to the next word, so a phrase starting with an
 * Arabic letter also matches after the proclitics و / ف (and), then
 * ب / ل / ك (with, for, as): "وحتما", "فبالتأكيد". A leading "ال" also
 * matches its "لل" form after ل ("للتنبؤ"). Suffixes are not added: a
 * pronoun suffix changes the word, so stems stay explicit (`*`).
 */
export const WORD = String.raw`[\p{L}\p{N}\p{M}_]`;

const ARABIC_START = /^\p{Script=Arabic}/u;

/** The left part of an Arabic phrase's first token, clitics included. */
function arabicHead(token: string): string {
  return token.startsWith('ال')
    ? `(?:[وف]?[بك]?ال|[وف]?لل)${token.slice(2)}`
    : `[وف]?[بلك]?${token}`;
}

/** Regex for one phrase (`*` = stem; word boundaries unless `substring`). */
export function phraseRegex(phrase: string, substring: boolean): RegExp {
  const tokens = normalize(phrase)
    .split(/\s+/u)
    .filter((token) => token !== '');
  if (tokens.length === 0) {
    throw new Error('empty phrase');
  }
  const escape = (token: string): string => token.replace(/[.*+?^${}()|[\]\\]/gu, '\\$&');
  if (substring) {
    return new RegExp(tokens.map((t) => escape(t.replace(/\*$/u, ''))).join(String.raw`\s*`), 'u');
  }
  const parts = tokens.map(
    (t) => escape(t.replace(/\*$/u, '')) + (t.endsWith('*') ? `${WORD}*` : ''),
  );
  if (ARABIC_START.test(parts[0] ?? '')) {
    parts[0] = arabicHead(parts[0] ?? '');
  }
  const tail = tokens.at(-1)?.endsWith('*') === true ? '' : `(?!${WORD})`;
  return new RegExp(`(?<!${WORD})${parts.join(String.raw`\s+`)}${tail}`, 'u');
}

/**
 * A non-claim span source (`NON_CLAIM_SPANS`), compiled on word boundaries,
 * or anywhere in a `match: substring` locale (ja: no spaces between words).
 */
export function nonClaimRegex(source: string, substring = false): RegExp {
  return substring
    ? new RegExp(`(?:${source})`, 'gu')
    : new RegExp(`(?<!${WORD})(?:${source})(?!${WORD})`, 'gu');
}

export interface MatchRule {
  readonly pattern: RegExp;
}

export interface MatchBook<R extends MatchRule> {
  readonly rules: readonly R[];
  /** Exact normalised spans removed first (`allowed_contexts`). */
  readonly allowedContexts: readonly string[];
  /** Spans that use a listed word without a claim, removed before matching (global regexes). */
  readonly nonClaims: readonly RegExp[];
}

/**
 * Every rule that occurs in `text`, with the matched span: the text is
 * normalised, allowed contexts and (unless `keep`) non-claim spans removed.
 */
export function matchRules<R extends MatchRule>(
  text: string,
  book: MatchBook<R>,
  nonClaims: 'remove' | 'keep' = 'remove',
): { readonly rule: R; readonly match: string }[] {
  let normalized = normalize(text);
  for (const context of book.allowedContexts) {
    normalized = normalized.replaceAll(context, ' ');
  }
  if (nonClaims === 'remove') {
    for (const span of book.nonClaims) {
      normalized = normalized.replace(span, ' ');
    }
  }
  const hits: { rule: R; match: string }[] = [];
  for (const rule of book.rules) {
    const match = rule.pattern.exec(normalized);
    if (match !== null) {
      hits.push({ rule, match: match[0] });
    }
  }
  return hits;
}
