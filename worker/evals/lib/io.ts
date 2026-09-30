import {
  isClassification,
  isLocale,
  isOutcome,
  outcomeOf,
  type Classification,
  type DrawnCard,
  type EvalCase,
  type Outcome,
  type RecordedOutput,
} from './types';

/**
 * Parsers for the eval inputs. Every problem is reported with its source and
 * line, and a bad line never stops the others from loading.
 */
export interface Parsed<T> {
  readonly items: T[];
  readonly errors: string[];
  /** Case IDs left out on purpose (request-validation cases without a model answer). */
  readonly skipped?: string[];
}

type Json = Readonly<Record<string, unknown>>;

function isObject(value: unknown): value is Json {
  return typeof value === 'object' && value !== null && !Array.isArray(value);
}

function optionalString(value: unknown): string | null {
  return typeof value === 'string' && value !== '' ? value : null;
}

/** JSON Lines: one JSON value per non-blank line. */
export function parseJsonLines(
  text: string,
  source: string,
): Parsed<{ line: number; value: unknown }> {
  const items: { line: number; value: unknown }[] = [];
  const errors: string[] = [];
  text.split(/\r?\n/).forEach((raw, index) => {
    const line = raw.trim();
    if (line === '') {
      return;
    }
    try {
      items.push({ line: index + 1, value: JSON.parse(line) as unknown });
    } catch {
      errors.push(`${source}:${String(index + 1)}: not valid JSON`);
    }
  });
  return { items, errors };
}

function parseCards(value: unknown): DrawnCard[] | null | 'invalid' {
  if (value === undefined || value === null) {
    return null;
  }
  if (!Array.isArray(value)) {
    return 'invalid';
  }
  const cards: DrawnCard[] = [];
  for (const card of value as unknown[]) {
    if (
      !isObject(card) ||
      typeof card['positionId'] !== 'string' ||
      typeof card['cardId'] !== 'string' ||
      (card['reversed'] !== undefined && typeof card['reversed'] !== 'boolean')
    ) {
      return 'invalid';
    }
    cards.push({
      positionId: card['positionId'],
      cardId: card['cardId'],
      reversed: card['reversed'] === true,
    });
  }
  return cards;
}

function spreadIdOf(value: unknown): string | null {
  if (isObject(value)) {
    return optionalString(value['id']);
  }
  return optionalString(value);
}

/**
 * One case object. The expectation may be given as a category
 * (`expectedCategory`, `category`, or `expected` holding a category) and/or an
 * outcome (`expectedOutcome`, or `expected` holding an outcome); a missing
 * outcome is derived from the category (03 §9.4).
 */
export function parseCase(value: unknown): EvalCase | string {
  if (!isObject(value)) {
    return 'a case must be a JSON object';
  }
  const id = optionalString(value['id']);
  if (id === null) {
    return 'a case needs a string "id"';
  }
  const locale = value['locale'];
  if (!isLocale(locale)) {
    return `${id}: unknown locale ${locale === undefined ? 'undefined' : JSON.stringify(locale)}`;
  }
  const expected = value['expected'];
  // `evals/cases/quality.jsonl` writes `expect: {classification}`.
  const expect = isObject(value['expect']) ? value['expect'] : {};
  const rawCategory: unknown =
    value['expectedCategory'] ??
    value['category'] ??
    expect['classification'] ??
    (isOutcome(expected) ? null : (expected ?? null));
  const rawOutcome: unknown = value['expectedOutcome'] ?? (isOutcome(expected) ? expected : null);
  let category: Classification | null = null;
  if (rawCategory !== null) {
    if (!isClassification(rawCategory)) {
      return `${id}: unknown category ${JSON.stringify(rawCategory)}`;
    }
    category = rawCategory;
  }
  let outcome: Outcome;
  if (rawOutcome !== null) {
    if (!isOutcome(rawOutcome)) {
      return `${id}: unknown outcome ${JSON.stringify(rawOutcome)}`;
    }
    outcome = rawOutcome;
  } else if (category !== null) {
    outcome = outcomeOf(category);
  } else {
    return `${id}: needs an expected category or outcome`;
  }
  const cards = parseCards(value['cards']);
  if (cards === 'invalid') {
    return `${id}: "cards" must be [{positionId, cardId, reversed}]`;
  }
  return {
    id,
    locale,
    expectedCategory: category,
    expectedOutcome: outcome,
    kind: optionalString(value['kind']),
    spreadId: spreadIdOf(value['spread'] ?? value['spreadId']),
    cards,
    // `evals/safety/prompts.jsonl` names the question `text`.
    question:
      typeof value['question'] === 'string'
        ? value['question']
        : typeof value['text'] === 'string'
          ? value['text']
          : null,
  };
}

/**
 * A case that expects the Worker to reject the request (`expect.httpStatus`,
 * such as an over-long question): no model is called, so it is not graded.
 */
export function isRequestRejectionCase(value: unknown): boolean {
  return (
    isObject(value) && isObject(value['expect']) && value['expect']['httpStatus'] !== undefined
  );
}

export function parseCases(text: string, source: string): Parsed<EvalCase> {
  const lines = parseJsonLines(text, source);
  const items: EvalCase[] = [];
  const errors = [...lines.errors];
  const skipped: string[] = [];
  for (const { line, value } of lines.items) {
    if (isRequestRejectionCase(value)) {
      skipped.push(optionalString((value as Json)['id']) ?? `${source}:${String(line)}`);
      continue;
    }
    const parsed = parseCase(value);
    if (typeof parsed === 'string') {
      errors.push(`${source}:${String(line)}: ${parsed}`);
    } else {
      items.push(parsed);
    }
  }
  return { items, errors, skipped };
}

/**
 * One recorded output: `{id, tier?, provider?, model?, output, refusal?}`.
 * `output` is the raw model text; an object is accepted and re-serialised.
 * `refusal` is `true` or `{category?}` for a provider refusal (03 §9.3).
 */
export function parseOutput(value: unknown, defaultTier: string): RecordedOutput | string {
  if (!isObject(value)) {
    return 'an output must be a JSON object';
  }
  const id = optionalString(value['id']);
  if (id === null) {
    return 'an output needs a string "id"';
  }
  const raw = value['output'];
  const refusalRaw = value['refusal'];
  const refusal =
    refusalRaw === true
      ? { category: null }
      : isObject(refusalRaw)
        ? { category: optionalString(refusalRaw['category']) }
        : null;
  let output: string;
  if (typeof raw === 'string') {
    output = raw;
  } else if (isObject(raw) || Array.isArray(raw)) {
    output = JSON.stringify(raw);
  } else if ((raw === undefined || raw === null) && refusal !== null) {
    output = '';
  } else {
    return `${id}: "output" must be the raw model text`;
  }
  return {
    id,
    tier: optionalString(value['tier']) ?? defaultTier,
    provider: optionalString(value['provider']),
    model: optionalString(value['model']),
    output,
    refusal,
  };
}

/** A `.jsonl` of outputs, or a `.json` holding one output or an array of them. */
export function parseOutputs(
  text: string,
  source: string,
  defaultTier: string,
): Parsed<RecordedOutput> {
  const items: RecordedOutput[] = [];
  const errors: string[] = [];
  let values: { line: number; value: unknown }[];
  if (source.endsWith('.json')) {
    try {
      const parsed = JSON.parse(text) as unknown;
      values = (Array.isArray(parsed) ? (parsed as unknown[]) : [parsed]).map((value) => ({
        line: 1,
        value,
      }));
    } catch {
      return { items, errors: [`${source}: not valid JSON`] };
    }
  } else {
    const lines = parseJsonLines(text, source);
    errors.push(...lines.errors);
    values = lines.items;
  }
  for (const { line, value } of values) {
    const parsed = parseOutput(value, defaultTier);
    if (typeof parsed === 'string') {
      errors.push(`${source}:${String(line)}: ${parsed}`);
    } else {
      items.push(parsed);
    }
  }
  return { items, errors };
}

/**
 * One file found in an `--outputs` directory. `<id>.json` may hold a recorded
 * output (`{id, output…}`) or an array of them, as `parseOutputs` reads; any
 * other content, valid JSON or not, is the raw model text of case `<id>`
 * (the file stem), so a folder of raw provider responses grades as is and a
 * malformed response fails the schema grader instead of being dropped.
 */
export function parseOutputFileInDir(
  text: string,
  source: string,
  defaultTier: string,
): Parsed<RecordedOutput> {
  if (source.endsWith('.json')) {
    let parsed: unknown;
    try {
      parsed = JSON.parse(text) as unknown;
    } catch {
      parsed = undefined;
    }
    const wrapped =
      Array.isArray(parsed) || (isObject(parsed) && ('output' in parsed || 'refusal' in parsed));
    if (!wrapped) {
      const name = source.slice(source.lastIndexOf('/') + 1);
      const id = name.slice(0, -'.json'.length);
      return {
        items: [
          { id, tier: defaultTier, provider: null, model: null, output: text, refusal: null },
        ],
        errors: [],
      };
    }
  }
  return parseOutputs(text, source, defaultTier);
}

/** `out_<tier>` names the tier of an outputs directory; anything else is `null`. */
export function tierOfDir(dir: string): string | null {
  const base = dir.replace(/\/+$/u, '').split('/').at(-1) ?? '';
  const match = /^out_(.+)$/u.exec(base);
  return match?.[1] ?? null;
}
