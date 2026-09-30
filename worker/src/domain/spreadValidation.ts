import cardsFeed from '../generated/deck/cards.json';
import spreadsFeed from '../generated/deck/spreads.json';
import { normaliseQuestion } from '../prompts/build';
import type { Locale } from './types';

/**
 * Reading request validation (03 §9.0, §9.1; RC1, RC2, RC45). Pure: the
 * route's zod schema checks shapes and types; this checks the request
 * against the generated deck (`src/generated/deck/{cards,spreads}.json`,
 * RC26) and the active config.
 *
 * - Spread ID **and** version are in the generated spreads, and the spread
 *   is in `spreads.enabled` → else `422 SPREAD_INVALID` (`reason`
 *   `unknownSpread` | `disabled`).
 * - Exactly one card per position, every `positionId` of the spread, card
 *   IDs known and unique → else `422 SPREAD_INVALID` (`reason` `cards`).
 * - `question`: NFC, control characters stripped, trimmed; at most
 *   `ai.questionMaxChars` grapheme clusters → else `400 VALIDATION_FAILED`.
 */
export type SpreadInvalidReason = 'unknownSpread' | 'disabled' | 'cards';

export interface SpreadRef {
  readonly id: string;
  readonly version: number;
}

export interface DrawnCard {
  readonly positionId: string;
  readonly cardId: string;
  readonly reversed: boolean;
}

export interface ReadingRequestInput {
  readonly spread: SpreadRef;
  readonly cards: readonly DrawnCard[];
  readonly question?: string | null | undefined;
  readonly locale: Locale;
}

/** A request that passed validation: cards in position order, the question normalised (`''` = none). */
export interface ValidReading {
  readonly spreadId: string;
  readonly cards: readonly DrawnCard[];
  readonly question: string;
  readonly locale: Locale;
}

export type SpreadCheck =
  | { readonly ok: true; readonly positionIds: readonly string[] }
  | { readonly ok: false; readonly reason: SpreadInvalidReason };

export type ReadingCheck =
  | { readonly ok: true; readonly reading: ValidReading }
  | { readonly ok: false; readonly error: 'spread'; readonly reason: SpreadInvalidReason }
  | { readonly ok: false; readonly error: 'question'; readonly graphemes: number };

interface FeedSpread {
  readonly id: string;
  readonly version: number;
  readonly positions: readonly { readonly id: string; readonly order: number }[];
}

const SPREADS: ReadonlyMap<string, FeedSpread> = new Map(
  (spreadsFeed.spreads as readonly FeedSpread[]).map((spread) => [spread.id, spread]),
);
const CARD_IDS: ReadonlySet<string> = new Set(cardsFeed.cards.map((card) => card.id));

/** The spread gate of the hold and the reading (03 §9.0 order: after region, before budget). */
export function checkSpread(spread: SpreadRef, enabled: readonly string[]): SpreadCheck {
  const found = SPREADS.get(spread.id);
  if (found?.version !== spread.version) {
    return { ok: false, reason: 'unknownSpread' };
  }
  if (!enabled.includes(found.id)) {
    return { ok: false, reason: 'disabled' };
  }
  const positionIds = [...found.positions].sort((a, b) => a.order - b.order).map((p) => p.id);
  return { ok: true, positionIds };
}

/** Grapheme clusters (RC45): what the client's counter shows, not UTF-16 units. */
export function graphemeCount(text: string): number {
  return [...new Intl.Segmenter(undefined, { granularity: 'grapheme' }).segment(text)].length;
}

export function validateReading(
  input: ReadingRequestInput,
  config: { readonly enabledSpreads: readonly string[]; readonly questionMaxChars: number },
): ReadingCheck {
  const spread = checkSpread(input.spread, config.enabledSpreads);
  if (!spread.ok) {
    return { ok: false, error: 'spread', reason: spread.reason };
  }
  const cards = orderedCards(input.cards, spread.positionIds);
  if (cards === null) {
    return { ok: false, error: 'spread', reason: 'cards' };
  }
  const question = normaliseQuestion(input.question);
  const graphemes = graphemeCount(question);
  if (graphemes > config.questionMaxChars) {
    return { ok: false, error: 'question', graphemes };
  }
  return {
    ok: true,
    reading: { spreadId: input.spread.id, cards, question, locale: input.locale },
  };
}

/** The cards in position order, or null unless there is exactly one known, unique card per position. */
function orderedCards(
  cards: readonly DrawnCard[],
  positionIds: readonly string[],
): DrawnCard[] | null {
  if (cards.length !== positionIds.length) {
    return null;
  }
  const byPosition = new Map(cards.map((card) => [card.positionId, card]));
  const cardIds = new Set(cards.map((card) => card.cardId));
  if (byPosition.size !== cards.length || cardIds.size !== cards.length) {
    return null;
  }
  const ordered: DrawnCard[] = [];
  for (const positionId of positionIds) {
    const card = byPosition.get(positionId);
    if (card === undefined || !CARD_IDS.has(card.cardId)) {
      return null;
    }
    ordered.push({ positionId, cardId: card.cardId, reversed: card.reversed });
  }
  return ordered;
}
