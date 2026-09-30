import { buildPhraseBook } from '../../evals/lib/phrases';
import { LOCALES, type Locale } from '../domain/types';
import { parseLexiconSource, type L1RuleSource, type LexiconSource } from '../safety/lexiconSource';
import type {
  GeneratedL1Rule,
  GeneratedL3Rule,
  GeneratedLexicon,
  GeneratedLexicons,
} from '../safety/lexicons';
import { phraseRegex } from '../safety/phrases';
import { foldText } from '../safety/text';
import { parseArgs, type CliDeps } from './cli';

/**
 * The safety-lexicon builder (03 §9.4, RC39): `worker/safety/lexicons/*.json`
 * plus `tools/store_copy/banned_phrases.yaml` → `src/generated/safety_lexicons.json`.
 * L1 patterns get their word boundaries and are checked to be in `foldText`
 * form; the L3 list is every `global` banned phrase of the locale (RC39),
 * the lexicon's certainty wording and its L3-only forbidden claims, with the
 * allowed contexts and non-claim spans the offline graders use.
 */
export const LEXICON_DIR = 'safety/lexicons';
export const BANNED_PHRASES = '../tools/store_copy/banned_phrases.yaml';
export const GENERATED_LEXICONS = 'src/generated/safety_lexicons.json';

const BOUNDARY_BEFORE = String.raw`(?<![\p{L}\p{N}])`;
const BOUNDARY_AFTER = String.raw`(?![\p{L}\p{N}])`;

/** The pattern with its escapes (`\p{L}`, `\s`, …) masked, which `foldText` would lower-case. */
function literalPart(pattern: string): string {
  return pattern.replace(/\\(?:[pP]\{[^}]*\}|.)/gu, '\u0001');
}

function compilePattern(locale: Locale, id: string, pattern: string, boundaries: boolean): string {
  const literal = literalPart(pattern);
  if (foldText(literal) !== literal) {
    throw new Error(`${locale} ${id}: pattern is not in foldText form: ${pattern}`);
  }
  const source = boundaries ? `${BOUNDARY_BEFORE}(?:${pattern})${BOUNDARY_AFTER}` : pattern;
  try {
    new RegExp(source, 'u');
  } catch (err) {
    throw new Error(`${locale} ${id}: invalid pattern ${pattern} (${(err as Error).message})`, {
      cause: err,
    });
  }
  return source;
}

function compileL1(source: LexiconSource): GeneratedL1Rule[] {
  const ids = new Set<string>();
  return source.l1.map((rule: L1RuleSource) => {
    if (ids.has(rule.id)) {
      throw new Error(`${source.locale}: duplicate rule id ${rule.id}`);
    }
    ids.add(rule.id);
    const compile = (pattern: string): string =>
      compilePattern(source.locale, rule.id, pattern, source.wordBoundaries);
    return {
      id: rule.id,
      category: rule.category,
      severity: rule.severity,
      patterns: rule.patterns.map(compile),
      unless: (rule.unless ?? []).map(compile),
    };
  });
}

/** Compiles the twelve lexicon sources with the banned-phrases YAML. */
export function compileSafetyLexicons(
  sources: Readonly<Record<Locale, LexiconSource>>,
  bannedYaml: string,
): GeneratedLexicons {
  const book = buildPhraseBook(bannedYaml, sources);
  const locales = {} as Record<Locale, GeneratedLexicon>;
  for (const locale of LOCALES) {
    const source = sources[locale];
    const phrases = book[locale];
    const seen = new Set(phrases.rules.map((rule) => rule.phrase));
    const rules: GeneratedL3Rule[] = phrases.rules.map((rule) => ({
      phrase: rule.phrase,
      kind: rule.concept,
      source: rule.source,
      pattern: rule.pattern.source,
    }));
    for (const phrase of source.l3.forbiddenClaims) {
      if (!seen.has(phrase)) {
        seen.add(phrase);
        rules.push({
          phrase,
          kind: 'claim',
          source: 'forbidden_claims',
          pattern: phraseRegex(phrase, phrases.substring).source,
        });
      }
    }
    locales[locale] = {
      reviewed: source.reviewed,
      l1: compileL1(source),
      l3: {
        rules,
        allowedContexts: phrases.allowedContexts,
        nonClaimSpans: source.l3.nonClaimSpans,
      },
    };
  }
  return { version: 1, locales };
}

export function renderSafetyLexicons(lexicons: GeneratedLexicons): string {
  return `${JSON.stringify(lexicons, null, 2)}\n`;
}

export const USAGE = 'usage: safety-lexicons [--check]';

/**
 * `npm run safety:lexicons [-- --check]`: writes the generated file, or with
 * `--check` fails (exit 1) when it is out of date. Exit 2 = usage.
 */
export async function main(argv: readonly string[], deps: CliDeps): Promise<number> {
  const args = parseArgs(argv, { flags: ['--check'], options: [] });
  if (!args.ok) {
    deps.err(`${args.error}\n${USAGE}`);
    return 2;
  }
  let rendered: string;
  try {
    const sources = {} as Record<Locale, LexiconSource>;
    for (const locale of LOCALES) {
      const path = `${LEXICON_DIR}/${locale}.json`;
      sources[locale] = parseLexiconSource(
        locale,
        JSON.parse(await deps.readFile(path)) as unknown,
      );
    }
    rendered = renderSafetyLexicons(
      compileSafetyLexicons(sources, await deps.readFile(BANNED_PHRASES)),
    );
  } catch (err) {
    deps.err(`failed: ${(err as Error).message}`);
    return 1;
  }
  if (args.flags.has('--check')) {
    let current = '';
    try {
      current = await deps.readFile(GENERATED_LEXICONS);
    } catch {
      // a missing file is out of date
    }
    if (current !== rendered) {
      deps.err(`${GENERATED_LEXICONS} is out of date; run npm run safety:lexicons`);
      return 1;
    }
    deps.out(`${GENERATED_LEXICONS} is up to date`);
    return 0;
  }
  await deps.writeFile(GENERATED_LEXICONS, rendered);
  deps.out(`wrote ${GENERATED_LEXICONS} (${String(LOCALES.length)} locales)`);
  return 0;
}
