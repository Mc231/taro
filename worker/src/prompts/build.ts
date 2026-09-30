import cardsFeed from '../generated/deck/cards.json';
import namesFeed from '../generated/deck/names.json';
import spreadsFeed from '../generated/deck/spreads.json';
import { isLocale, isRefusalCategory, type Locale, type RefusalCategory } from '../domain/types';
import {
  outputSchemaFor,
  READING_TEMPLATES,
  type ExpectedReading,
  type OutputSchema,
  type PromptVersion,
  type ReadingTemplateSet,
  type SpreadNotes,
} from './templates';

/**
 * Assembles the provider-neutral reading prompt (03 §9.2, RC97).
 *
 * `system` is the static prefix: persona, hard rules, classification table,
 * injection defence, writing principles, output contract and one example. It
 * is byte-identical for every reading of a prompt version (no locale, spread,
 * card or question in it), so every provider can cache it. Card keywords and
 * image details are sent only for the drawn cards, in `user`. `cacheBoundary` says where the cacheable prefix ends;
 * each adapter renders it its vendor's way (Anthropic: a `cache_control`
 * breakpoint on the system block; OpenAI: prefix order only). Everything
 * per reading (locale and style notes, spread, positions, cards, facts,
 * prefilter hint, question) goes into `user`, after the boundary.
 */
export const CACHE_BOUNDARY = 'after_system' as const;

export interface ReadingPromptInput {
  readonly promptVersion: PromptVersion;
  /** Static, cacheable prefix. */
  readonly system: string;
  /** The cacheable prefix ends after `system`. */
  readonly cacheBoundary: typeof CACHE_BOUNDARY;
  /** The per-reading message. */
  readonly user: string;
  /**
   * `output.schema.json` of this version expanded for the spread
   * (`outputSchemaFor`: one required `cards` key per position, `prompt1..N`);
   * adapters may drop keywords their vendor rejects.
   */
  readonly outputSchema: OutputSchema;
  readonly spreadId: string;
  readonly locale: Locale;
  /** What `parseReadingOutput` checks an answered reading against: drawn cards, prompt count. */
  readonly expected: ExpectedReading;
}

export interface ReadingPromptCard {
  readonly positionId: string;
  readonly cardId: string;
  readonly reversed: boolean;
}

export interface ReadingPromptRequest {
  readonly spreadId: string;
  /** One card per position, in any order; they are emitted in position order. */
  readonly cards: readonly ReadingPromptCard[];
  readonly locale: Locale;
  /** NFC-normalised and trimmed by `spreadValidation`; empty or absent = no question. */
  readonly question?: string | null | undefined;
  /** Lower-precision L1 matches (03 §9.4), passed on as `<prefilter_hint>`. */
  readonly prefilterHints?: readonly RefusalCategory[];
  /** The L3 violation of the previous attempt, for the one regeneration (03 §9.4). */
  readonly regenerationNote?: string;
}

export type BuildResult =
  | { readonly ok: true; readonly input: ReadingPromptInput }
  | { readonly ok: false; readonly error: string };

interface DeckCard {
  readonly id: string;
  readonly name: string;
  readonly arcana: string;
  readonly number: number;
  readonly suit: string | null;
  readonly keywordsUpright: readonly string[];
  readonly keywordsReversed: readonly string[];
}

interface DeckPosition {
  readonly id: string;
  readonly meaning: string;
  readonly order: number;
}

interface DeckSpread {
  readonly id: string;
  readonly version: number;
  readonly positions: readonly DeckPosition[];
}

const DECK: readonly DeckCard[] = cardsFeed.cards;
const CARDS_BY_ID: ReadonlyMap<string, DeckCard> = new Map(DECK.map((card) => [card.id, card]));
const SPREADS_BY_ID: ReadonlyMap<string, DeckSpread> = new Map(
  spreadsFeed.spreads.map((spread) => [spread.id, spread]),
);

/** `glossary.yaml` names per locale (emitted by `tools/content build`); a locale may be missing. */
type LocaleNames = Readonly<Partial<Record<string, string>>>;
const CARD_NAMES: Readonly<Record<string, LocaleNames>> = namesFeed.cards;
const POSITION_NAMES: Readonly<Record<string, LocaleNames>> = namesFeed.positions;

/** The canonical name in `locale`, or `undefined` for English or a missing entry. */
export function localName(
  names: Readonly<Record<string, LocaleNames>>,
  id: string,
  locale: Locale,
): string | undefined {
  return locale === 'en' ? undefined : names[id]?.[locale];
}

const SUITS = ['wands', 'cups', 'swords', 'pentacles'] as const;
type Suit = (typeof SUITS)[number];
const COURT_RANKS: ReadonlySet<string> = new Set(['11', '12', '13', '14']);

/** Position IDs of a generated spread in draw order, or `undefined` for an unknown spread. */
export function spreadPositionIds(spreadId: string): readonly string[] | undefined {
  return SPREADS_BY_ID.get(spreadId)
    ?.positions.slice()
    .sort((a, b) => a.order - b.order)
    .map((position) => position.id);
}

/** Replaces `{{name}}` in one pass; values are inserted literally, never re-scanned. */
export function fillTemplate(template: string, values: Readonly<Record<string, string>>): string {
  const missing = new Set<string>();
  const out = template.replace(/\{\{([a-z_]+)\}\}/g, (_match, name: string) => {
    const value = values[name];
    if (value === undefined) {
      missing.add(name);
      return '';
    }
    return value;
  });
  if (missing.size > 0) {
    throw new Error(`prompt template placeholder(s) without a value: ${[...missing].join(', ')}`);
  }
  return out;
}

/** Makes reader-supplied text inert inside a tag: no tag can be opened or closed from it. */
export function escapeTagText(text: string): string {
  return text.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
}

/** NFC, control characters (except line breaks and tabs) removed, trimmed. */
export function normaliseQuestion(question: string | null | undefined): string {
  if (question === undefined || question === null) {
    return '';
  }
  return (
    question
      .normalize('NFC')
      // eslint-disable-next-line no-control-regex
      .replace(/[\u0000-\u0008\u000B\u000C\u000E-\u001F\u007F]/g, '')
      .replace(/\r\n?/g, '\n')
      .trim()
  );
}

function range([min, max]: readonly [number, number]): string {
  return `${String(min)}–${String(max)}`;
}

function rankOf(card: DeckCard): string {
  return card.id.slice(-2);
}

function suitOf(card: DeckCard): Suit | null {
  return SUITS.find((suit) => suit === card.suit) ?? null;
}

const systemCache = new Map<PromptVersion, string>();
const schemaCache = new Map<string, OutputSchema>();

/** The output schema of a spread (one per version and spread, so vendors reuse one grammar). */
export function spreadOutputSchema(
  set: ReadingTemplateSet,
  spreadId: string,
  positionIds: readonly string[],
  reflectionPrompts: number,
): OutputSchema {
  const key = `${set.version}/${spreadId}`;
  const cached = schemaCache.get(key);
  if (cached !== undefined) {
    return cached;
  }
  const schema = outputSchemaFor(set.outputSchema, positionIds, reflectionPrompts);
  schemaCache.set(key, schema);
  return schema;
}

/** The static, cacheable system prefix of a prompt version (identical for every reading). */
export function systemPrompt(version: PromptVersion): string {
  const cached = systemCache.get(version);
  if (cached !== undefined) {
    return cached;
  }
  // No placeholders: the prefix must not vary per reading (a stray one throws).
  const system = fillTemplate(READING_TEMPLATES[version].system, {}).trimEnd();
  systemCache.set(version, system);
  return system;
}

function cardBlock(
  set: ReadingTemplateSet,
  notes: SpreadNotes,
  locale: Locale,
  index: number,
  placed: Placed,
): string {
  const { position, drawn, card } = placed;
  const keywords = drawn.reversed ? card.keywordsReversed : card.keywordsUpright;
  const orientation = drawn.reversed ? 'reversed' : 'upright';
  // The prompt's own position note (worded without "not a promise"-style
  // negations the model would echo); the content meaning is the fallback.
  const positionNote = notes.positionNotes[position.id] ?? position.meaning;
  // Only the names to write: English names were copied into local readings.
  return [
    `<card n="${String(index + 1)}" positionId="${position.id}" cardId="${card.id}" reversed="${String(drawn.reversed)}">`,
    `Position: ${positionLabel(notes, position.id, locale)}. ${positionNote}`,
    `Card: ${cardLabel(card, locale)}; ${orientation}`,
    `Image: ${set.data.images[card.id] ?? ''}`,
    `Keywords: ${keywords.join('; ')}`,
    '</card>',
  ].join('\n');
}

interface Placed {
  readonly position: DeckPosition;
  readonly drawn: ReadingPromptCard;
  readonly card: DeckCard;
}

/** The card name to write in `locale` (the canonical English name as fallback). */
function cardLabel(card: DeckCard, locale: Locale): string {
  return localName(CARD_NAMES, card.id, locale) ?? card.name;
}

/** The position name to write in `locale` (the English label as fallback). */
function positionLabel(notes: SpreadNotes, positionId: string, locale: Locale): string {
  return (
    localName(POSITION_NAMES, positionId, locale) ?? notes.positions[positionId] ?? positionId
  );
}

/**
 * The suit line the synthesis may name, so the model never invents a
 * dominance: a majority only above half the cards, otherwise the most common
 * suit or a tie.
 */
function joinAnd(items: readonly string[]): string {
  return items.length < 2 ? items.join('') : `${items.slice(0, -1).join(', ')} and ${items.at(-1) ?? ''}`;
}

function suitName(set: ReadingTemplateSet, suit: Suit): string {
  return set.data.suits[suit];
}

function dominantSuit(set: ReadingTemplateSet, placed: readonly Placed[]): string {
  const counts = SUITS.map((suit) => ({
    suit,
    count: placed.filter((p) => suitOf(p.card) === suit).length,
  })).filter((c) => c.count > 0);
  const top = Math.max(0, ...counts.map((c) => c.count));
  const leaders = counts.filter((c) => c.count === top);
  const name = (suit: Suit): string => suitName(set, suit);
  const of = `${String(top)} of ${String(placed.length)}`;
  if (top === 0) {
    return 'Dominant suit: none (no Minor Arcana).';
  }
  if (leaders.length > 1) {
    return `Dominant suit: none (${joinAnd(leaders.map((c) => name(c.suit)))} tied at ${String(top)} ${top === 1 ? 'card' : 'cards'} each).`;
  }
  const leader = leaders[0]?.suit ?? 'wands';
  if (top === 1) {
    return `Dominant suit: none (a single ${name(leader)} card).`;
  }
  return top * 2 > placed.length
    ? `Dominant suit: ${name(leader)} (${of}, a majority).`
    : `Dominant suit: ${name(leader)} is the most common (${of}), not a majority.`;
}

/** Counts the synthesis can lean on (01 §7.4: suit balance, majors, recurring numbers). */
function spreadFacts(
  set: ReadingTemplateSet,
  locale: Locale,
  placed: readonly Placed[],
): string {
  const total = String(placed.length);
  const list = (items: readonly Placed[]): string =>
    items.length === 0 ? 'none' : items.map((p) => cardLabel(p.card, locale)).join(', ');

  const majors = placed.filter((p) => suitOf(p.card) === null);
  const reversed = placed.filter((p) => p.drawn.reversed);
  const courts = placed.filter((p) => suitOf(p.card) !== null && COURT_RANKS.has(rankOf(p.card)));

  // Suit names only, with the cards that carry them: the elemental glosses
  // ("water: feelings") invited readings of a count as a sign, and bare
  // counts invited recounting with the wrong positions.
  const present: string[] = [];
  const absent: string[] = [];
  for (const suit of SUITS) {
    const inSuit = placed.filter((p) => suitOf(p.card) === suit);
    if (inSuit.length > 0) {
      present.push(`${String(inSuit.length)} × ${suitName(set, suit)} (${list(inSuit)})`);
    } else {
      absent.push(suit.charAt(0).toUpperCase() + suit.slice(1));
    }
  }

  const dominant = dominantSuit(set, placed);

  const byRank = new Map<string, Placed[]>();
  for (const p of placed) {
    if (suitOf(p.card) !== null) {
      const rank = rankOf(p.card);
      byRank.set(rank, [...(byRank.get(rank) ?? []), p]);
    }
  }
  const repeated = [...byRank.entries()]
    .filter(([, items]) => items.length > 1)
    .map(
      ([rank, items]) =>
        `${set.data.ranks[rank] ?? rank} ×${String(items.length)} (${list(items)})`,
    );

  return [
    '<spread_facts>',
    `Major Arcana: ${String(majors.length)} of ${total} (${list(majors)}).`,
    `Suits: ${present.length === 0 ? 'none' : present.join('; ')}.${absent.length === 0 ? '' : ` Absent: ${absent.join(', ')}.`}`,
    dominant,
    `Reversed: ${String(reversed.length)} of ${total} (${list(reversed)}).`,
    `Court cards: ${list(courts)}.`,
    `Repeated ranks: ${repeated.length === 0 ? 'none' : repeated.join('; ')}.`,
    '</spread_facts>',
    '',
  ].join('\n');
}

/** Scales an English word range to the locale's unit, rounded to fives. */
export function scaledRange([min, max]: readonly [number, number], factor: number): string {
  const scale = (n: number): number => Math.max(5, Math.round((n * factor) / 5) * 5);
  return range([scale(min), scale(max)]);
}

function lengthBudget(
  set: ReadingTemplateSet,
  notes: SpreadNotes,
  locale: Locale,
  cardCount: number,
): string {
  const w = notes.words;
  const n = notes.sentences;
  const { factor, unit } = set.data.localeNotes[locale];
  const r = (words: readonly [number, number]): string => `${scaledRange(words, factor)} ${unit}`;
  const cards = cardCount === 1 ? 'the card' : 'each card';
  const converted =
    factor === 1 ? '' : ` ${set.data.phrases.lengthConverted.replace('{factor}', String(factor))}`;
  return `Overview ${n.overview} sentences, ${r(w.overview)}; ${cards} ${n.card} sentences, ${r(w.card)}; synthesis ${n.synthesis} sentences, ${r(w.synthesis)}; exactly ${String(notes.reflectionPrompts)} reflection prompts; about ${r(w.total)} in total, title and prompts included.${converted} ${set.data.phrases.lengthFloor}`;
}

/**
 * Builds the prompt for one reading. Inputs are validated by
 * `domain/spreadValidation.ts` before this runs; a failure here is a bug or a
 * bad eval case, reported as `{ok: false}`.
 */
export function buildReadingPrompt(
  request: ReadingPromptRequest,
  version: PromptVersion = 'v1',
): BuildResult {
  const set = READING_TEMPLATES[version];
  if (!isLocale(request.locale)) {
    return { ok: false, error: `unknown locale ${String(request.locale)}` };
  }
  const spread = SPREADS_BY_ID.get(request.spreadId);
  const notes = set.data.spreads[request.spreadId];
  if (spread === undefined || notes === undefined) {
    return { ok: false, error: `unknown spread ${request.spreadId}` };
  }
  if (request.cards.length !== spread.positions.length) {
    return {
      ok: false,
      error: `spread ${spread.id} needs ${String(spread.positions.length)} cards, got ${String(request.cards.length)}`,
    };
  }
  const seenCards = new Set<string>();
  const placed: Placed[] = [];
  for (const position of [...spread.positions].sort((a, b) => a.order - b.order)) {
    const matches = request.cards.filter((c) => c.positionId === position.id);
    const drawn = matches[0];
    if (drawn === undefined || matches.length > 1) {
      return { ok: false, error: `spread ${spread.id} needs exactly one card at ${position.id}` };
    }
    const card = CARDS_BY_ID.get(drawn.cardId);
    if (card === undefined) {
      return { ok: false, error: `unknown card ${drawn.cardId}` };
    }
    if (seenCards.has(card.id)) {
      return { ok: false, error: `card ${card.id} drawn twice` };
    }
    seenCards.add(card.id);
    placed.push({ position, drawn, card });
  }
  const hints = request.prefilterHints ?? [];
  // Runtime check: eval cases and future callers may pass unchecked strings.
  const badHint = (hints as readonly string[]).find((hint) => !isRefusalCategory(hint));
  if (badHint !== undefined) {
    return { ok: false, error: `unknown prefilter category ${badHint}` };
  }

  const question = normaliseQuestion(request.question);
  const regeneration = normaliseQuestion(request.regenerationNote);
  const localeName = set.data.locales[request.locale];
  const user = fillTemplate(set.user, {
    locale_code: request.locale,
    locale_name: localeName,
    style_notes: set.styles[request.locale].trim(),
    spread_id: spread.id,
    spread_name: notes.name,
    card_count: String(placed.length),
    spread_note: notes.note,
    length_budget: lengthBudget(set, notes, request.locale, placed.length),
    cards: placed.map((p, i) => cardBlock(set, notes, request.locale, i, p)).join('\n'),
    spread_facts: placed.length > 1 ? spreadFacts(set, request.locale, placed) : '',
    prefilter_hint: hints.length === 0 ? set.data.phrases.noHint : [...new Set(hints)].join(', '),
    user_question: question === '' ? '' : `\n${escapeTagText(question)}\n`,
    regeneration_note:
      regeneration === ''
        ? ''
        : `<regeneration_note>\n${set.data.phrases.regenerationIntro}\n${escapeTagText(regeneration)}\n</regeneration_note>\n`,
    question_focus: question === '' ? set.data.phrases.noQuestion : set.data.phrases.withQuestion,
    address: set.data.localeNotes[request.locale].address,
    check_words: set.data.localeNotes[request.locale].checkWords,
  }).trimEnd();

  return {
    ok: true,
    input: {
      promptVersion: version,
      system: systemPrompt(version),
      cacheBoundary: CACHE_BOUNDARY,
      user,
      outputSchema: spreadOutputSchema(
        set,
        spread.id,
        placed.map((p) => p.position.id),
        notes.reflectionPrompts,
      ),
      spreadId: spread.id,
      locale: request.locale,
      expected: {
        cards: placed.map(({ position, drawn }) => ({
          positionId: position.id,
          cardId: drawn.cardId,
          reversed: drawn.reversed,
        })),
        reflectionPrompts: notes.reflectionPrompts,
      },
    },
  };
}
