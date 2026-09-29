# Deck content source (`apps/taro/content/source/`)

Authored deck content: card texts, spreads, Learn articles, the glossary and
the crisis-resources directory (01 §10, §11; RC25, RC26, RC95). This folder is
**not bundled**. `tools/content build` compiles it into `apps/taro/assets/deck/`
and `worker/src/generated/`; nothing else writes those files.

```bash
tools/content/validate                  # all checks; exit 0 = valid (staleness is only reported)
tools/content/validate --release        # + every crisis entry verified within 200 days
tools/content/validate --strict-locales # missing/stale translations are errors (Phase 18)
tools/content/validate --print-hashes   # print the sourceHash of every en card / spreads / article
tools/content/build                     # validate, then write the generated JSON (idempotent)
tools/content/build --check             # CI: fail if a generated file is out of date or stale
tools/content/sync_check                # app assets vs Worker feeds parity
tools/content/translate --locale de --dry-run          # plan: missing + stale files
tools/content/translate --locale de --cards cups_03    # one card (ANTHROPIC_API_KEY from env)
```

Exit codes of every command: `0` OK, `1` findings or failure, `64` usage
error. Errors are printed as `error: <path>: <message>` on stderr, the
staleness report as `report [<locale>]` blocks on stdout. The code lives in
`tools/dart_tools/lib/src/content/` (tests: `tools/dart_tools/test/content/`);
the scripts above are thin wrappers around `tools/dart_tools/bin/content_*.dart`.

`translate` options: `--locale` (required, not `en`), `--cards a,b` (default
all 78; alone it implies `--parts cards`), `--parts cards,spreads,articles`
(default all three), `--force` (also re-translate current files), `--dry-run`
(no API call, no key needed), `--model` (default `claude-opus-5`, 03
`ai.model.paid`), `--allow-unreviewed-glossary`. It refuses to run while `en`,
`glossary.yaml` or `deck.yaml` have validation errors, and while
`glossary.yaml` `review.<locale>` is not `reviewed`. It writes each file with
`reviewStatus: machine` and the current en `sourceHash`, forces `name` to the
glossary name, then re-validates the written files (exit 1 on any error; the
files stay for a person to fix). The Claude call sits behind the
`ClaudeClient` interface; tests use a fake.

The JSON Schemas in `tools/content/schema/` (`card`, `spreads`, `crisis`)
describe the same shapes as this file; `tools/content validate` enforces them
plus the rules that JSON Schema cannot express (word counts, glossary match,
banned phrases, Markdown, bidi characters, staleness). A copyable card is
`tools/content/examples/card.example.yaml`.

## Layout

```
apps/taro/content/source/
├── README.md                     # this file (ignored by the tools)
├── deck.yaml                     # deck id, content version, art set
├── glossary.yaml                 # card / suit / arcana / position names + key terms, 12 locales
├── crisis/crisis_resources.yaml  # one file for all locales (RC25)
├── en/                           # English source (the only source language)
│   ├── cards/<cardId>.yaml       # 78 files, e.g. en/cards/major_00.yaml, en/cards/cups_03.yaml
│   ├── spreads.yaml              # the 6 spreads: layout, suggestion keys, texts
│   └── articles/{about,faq}.md   # Learn articles (Markdown with front matter)
└── <locale>/                     # ar de es fr it ja ko nl pt tr uk (Phase 18)
    ├── cards/<cardId>.yaml       # translation of en/cards/<cardId>.yaml
    ├── spreads.yaml              # translated spread texts only
    └── articles/{about,faq}.md
```

Rules for every file:

- UTF-8, YAML 1.2. Keys are exactly as written here (camelCase); an unknown or
  misspelled key is an error. Duplicate keys are an error.
- IDs are the canonical ones (GLOSSARY §1, §2): cards `major_00` … `major_21`,
  `wands_01` … `wands_14`, `cups_01` … `cups_14`, `swords_01` … `swords_14`,
  `pentacles_01` … `pentacles_14` (01 = Ace, 11 = Page, 12 = Knight,
  13 = Queen, 14 = King). Locales: `en ar de es fr it ja ko nl pt tr uk`.
- Any other file or folder (other than this README) is an error, so typos in
  file names are caught.
- Use folded block scalars (`>-`) for long texts. A blank line inside a folded
  block becomes a paragraph break (allowed only where noted below).

## `reviewStatus`

Every card file, `spreads.yaml` and every article has a `reviewStatus` with
exactly one of these values (the taro_core `ReviewStatus` enum):

| Value | Meaning |
|---|---|
| `machine` | Written or translated by an LLM and **not yet reviewed by a person**. Every LLM draft, English included, starts here. |
| `reviewed` | A person did the edit / review pass (owner for `en`, native reviewer for other locales). Only a person sets this. |

## Voice (all text)

Reflection voice only (01 PR1, `docs/content/STYLE_GUIDE.md`): "invites you to
consider", "may reflect", "you might notice". Never predict, promise or claim
certainty; no fear, fate or doom; no health, legal, financial, pregnancy or
religious claims; gender-neutral "you". "Future"/"outcome" means "where things
may be heading if nothing changes". Write original text; never copy or
paraphrase closely from tarot books or websites.

The per-locale banned phrases in `tools/store_copy/banned_phrases.yaml`
(`common.global` + `locales.<locale>.global`) are errors anywhere in card
texts, spread texts and articles. Matching is case-insensitive on whole words;
a trailing `*` is a stem. The words themselves are listed only in that YAML
and in `docs/content/STYLE_GUIDE.md` §2 (with rephrasing hints): this folder
is scanned by `tools/store_copy/check_store_copy.py`, so no file here may
quote them, not even this README. Several ordinary English words are on the
list; rephrase rather than work around the matcher.

## `deck.yaml`

```yaml
id: rws_original      # Deck.id (02 §4)
version: 1            # content version, integer >= 1; bump when card texts change meaningfully
artSet: placeholder   # art set key: `placeholder` until the D15 art arrives
```

## `en/cards/<cardId>.yaml`

One file per card; the file name must equal `cardId`. Field names match
taro_core `CardText` (01 §10.1).

| Field | Type | Rule |
|---|---|---|
| `cardId` | string | equals the file name |
| `reviewStatus` | `machine` \| `reviewed` | see above |
| `element` | `fire` \| `water` \| `air` \| `earth` | **en only.** Required for minor cards and must be the suit element (wands = fire, cups = water, swords = air, pentacles = earth). Optional for major cards (authored correspondence). |
| `astrology` | string | **en only**, optional. Correspondence key, lower snake_case (`^[a-z][a-z0-9_]*$`), e.g. `venus`, `aries`, `sun_in_leo` |
| `name` | string | exactly the glossary name (`glossary.yaml` `cards.<cardId>.<locale>`); single line |
| `keywordsUpright` | list of strings | 3–6 items, each 1–24 characters, single line, no duplicates (case-insensitive) |
| `keywordsReversed` | list of strings | same as above |
| `shortUpright` | string | 1–160 characters, single line (daily card and reveal) |
| `shortReversed` | string | 1–160 characters, single line |
| `meaningUpright` | string | 120–220 words; paragraph breaks allowed |
| `meaningReversed` | string | 100–200 words; paragraph breaks allowed |
| `aspects` | mapping | exactly the 6 keys below, each 40–90 words, paragraph breaks allowed |
| `aspects.relationshipsUpright` / `relationshipsReversed` | string | Relationships |
| `aspects.workUpright` / `workReversed` | string | Work & purpose |
| `aspects.growthUpright` / `growthReversed` | string | Personal growth |
| `reflectionQuestions` | list of strings | exactly 3, each 1–120 characters, single line, ending in `?` (`؟` in `ar`, `？` allowed in `ja`) |
| `imageryNote` | string | 40–100 words about the symbolism of Taro's **original** art (D15), not RWS artwork |
| `sourceHash` | — | **must be absent in `en`** (the build computes it) |

Text rules (every string field of a card):

- **Plain text only**: no Markdown (`*`, `` ` ``, `~~`, `__`, `](`, a line
  starting with `#`, `>`, `- `, `+ ` or `1. `) and no HTML tags or entities.
- No leading or trailing whitespace; single-line fields contain no line break.
- A word is a whitespace-separated token containing a letter or digit.
  Characters are Unicode code points.
- Bidi controls: U+202A–U+202E (embeddings/overrides) and U+FEFF are never
  allowed; isolates U+2066–U+2069 must be balanced; the marks U+200E, U+200F,
  U+061C are allowed only in `ar` and never at the start or end of a field.
  Every `ar` text field contains Arabic script.

Bounds for other locales: character limits are the same; word limits are
widened to ×0.7 (min) … ×1.4 (max) for translation expansion, and not applied
to `ja` (which has no spaces; only a cap of 4 × the max word count in
characters).

## `<locale>/cards/<cardId>.yaml` (translations)

Same fields as `en` except: **no** `element` / `astrology`, and a required
`sourceHash` (64 lowercase hexadecimal digits): the `sourceHash` of the `en`
card this translation was made from (`tools/content translate` writes it;
`validate` prints it for each en card with `--print-hashes`). When the `en`
card changes, its hash changes and the translation is reported **stale**.

Hash definitions (SHA-256 of UTF-8 text, lowercase hexadecimal):

- card: the compact JSON (keys sorted recursively, no spaces) of the en card's
  `name`, `keywordsUpright`, `keywordsReversed`, `shortUpright`,
  `shortReversed`, `meaningUpright`, `meaningReversed`, `aspects`,
  `reflectionQuestions`, `imageryNote`; not `reviewStatus`, `element` or
  `astrology`, so a review-status flip does not make translations stale;
- spreads: the compact sorted JSON of `{<spreadId>: whenToUse}` of
  `en/spreads.yaml` (position `meaning`s are en-only Worker context);
- article: the en body after the front matter, trimmed.

## `en/spreads.yaml`

```yaml
reviewStatus: machine
spreads:                        # exactly the 6 spreads, in 01 §10.3 order
  - id: three_ppf
    version: 1                  # integer >= 1 (sent as spread.version, 03 §9.1)
    allowsReversals: true
    questionSuggestionKeys:     # 3–4 ARB keys, spread_<id>_suggestion_<n> (n = 1..4)
      - spread_three_ppf_suggestion_1
      - spread_three_ppf_suggestion_2
      - spread_three_ppf_suggestion_3
    whenToUse: >-              # 15–80 words, plain text (Learn spreads guide)
      ...
    positions:                  # exactly the 01 §10.3 position ids, in draw order (order = index + 1)
      - id: past
        x: 0.2                  # 0..1, LTR; the app mirrors x in RTL
        y: 0.5                  # 0..1
        rotationDeg: 0          # optional, default 0; -360..360 (Celtic Cross `challenge` = 90)
        meaning: >-            # English, 5–40 words, plain text: what this position invites
          ...                   # the reader to consider (Worker prompt context, 03 §9.2)
```

Spread and position **names and descriptions shown in the app** are ARB keys
(`spread_{spreadId}_pos_{positionId}_name/_desc`), not this file.

`<locale>/spreads.yaml` (translations) holds only the translated `whenToUse`:

```yaml
reviewStatus: machine
sourceHash: <sha256>            # sourceHash of en/spreads.yaml texts
whenToUse:
  single: ...
  three_ppf: ...                # all 6 spread ids
```

## `<locale>/articles/{about,faq}.md`

Markdown with a YAML front matter block. Both files are required for `en`.

```markdown
---
reviewStatus: machine
---
# About tarot and Taro

Body in Markdown (headings, paragraphs, lists, **bold**, links). No raw HTML.
```

- Front matter keys: `reviewStatus` (required), `sourceHash` (required for
  non-en, forbidden for en).
- The first line after the front matter is a level-1 heading (`# …`).
- 100–3000 words. Banned phrases apply (the fixed disclaimer wording
  "not medical, legal, financial or psychological advice" is allowed).

## `glossary.yaml`

```yaml
review:                 # review state of each locale's glossary (machine | reviewed)
  en: reviewed          # translation needs the target locale to be `reviewed`
  de: machine
cards:                  # all 78 card ids; en required, other locales optional until Phase 18
  major_00: { en: The Fool, de: Der Narr, fr: Le Mat }
suits:                  # wands, cups, swords, pentacles
  wands: { en: Wands }
arcana:                 # major, minor
  major: { en: Major Arcana }
positions:              # every position id of 01 §10.3 (each id once)
  past: { en: Past }
terms:                  # free snake_case keys for key terms (upright, reversed, spread, …)
  upright: { en: Upright }
```

All six top-level keys are required. `review` must contain `en`; its values
are `machine` | `reviewed`. `cards`, `suits`, `arcana` and `positions` must
list exactly the canonical IDs; every entry needs `en`, other locales are
optional (missing ones are reported per locale). Every value is a non-empty
single-line plain-text string without banned phrases. A locale that appears in
a card file must have that card's name in `cards.<cardId>.<locale>`, and the
card's `name` must equal it exactly.

## `crisis/crisis_resources.yaml`

Canonical `CrisisResource` schema (03 §9.5, RC81), one file for all locales.

```yaml
localeFallback:          # all 12 locales -> ISO country in `countries`, or null (= international only)
  en: US
  ar: null
countries:               # ISO 3166-1 alpha-2, upper case
  US:
    - name: 988 Suicide & Crisis Lifeline
      phone: "988"       # quote numbers; digits, spaces, +, -, ( ) only
      sms: "988"
      url: https://988lifeline.org   # https only
      hours: 24/7
      languages: [en, es]            # BCP 47; [] = not stated
      verifiedAt: null   # null until a person verifies it (Phase 18.4), then YYYY-MM-DD
international:           # always shown; must include https://findahelpline.com
  - name: Find A Helpline
    url: https://findahelpline.com
    languages: []
    verifiedAt: null
```

- Each entry: `name` (required), at least one of `phone` / `sms` / `url`,
  optional `hours`, `languages` (list, may be empty), `verifiedAt` (null or
  `YYYY-MM-DD`, not in the future).
- Required countries (05 §4.2): US, GB, IE, CA, AU, DE, FR, ES, IT, NL, JP,
  KR, TR, UA, BR, PT.
- `validate` reports unverified entries; `validate --release` fails on any
  entry that is unverified or verified more than 200 days ago.

## Staleness report

`validate` always prints a per-locale report: a card / spreads / article /
glossary entry that is **missing** in a non-en locale, or **stale** (its
`sourceHash` differs from the current en hash). Until Phase 18 this is a report
only (exit 0). `validate --strict-locales` turns it into errors. Everything
else about a translation file that exists (fields, bounds, glossary name,
banned phrases, bidi) is always an error. `en` itself is never optional: a
missing en card, `en/spreads.yaml` or en article is an error.

`tools/check_l10n.py` mirrors this: missing `en` cards or `en.json` are
findings, untranslated locales are notices (`--require-all-locales` makes
them findings in Phase 18).

Also reported (not errors): unverified crisis entries (see above) and
`questionSuggestionKeys` missing from `apps/taro/lib/l10n/arb/app_en.arb`.

## Generated output (do not edit)

| File | Content |
|---|---|
| `apps/taro/assets/deck/deck_meta.json` | `id`, `version`, `artSet`, `locales` (the built locales), `cards[]` (`DeckCard`: `id`, `arcana`, `suit` (null for majors), `number`, `element` (null when not authored), `astrology` (null when absent), `artKey` (= card ID)), `checksums` (SHA-256 hexadecimal digest of `spreads.json`, `crisis_resources.json` and each `<locale>.json`, keyed by file name) |
| `apps/taro/assets/deck/<locale>.json` | `locale`, `cards[]` (`CardText`: `cardId`, `locale`, the text fields, `sourceHash` (en: its own hash), `reviewStatus`), `spreads.<spreadId>.whenToUse`, `articles.<about\|faq>` = `markdown`, `reviewStatus`, `sourceHash`. Only for **complete** locales: all 78 cards, `spreads.yaml` and both articles present (and the whole source valid). |
| `apps/taro/assets/deck/spreads.json` | `spreads[]`: `id`, `version`, `allowsReversals`, `questionSuggestionKeys`, `positions[]` (`id`, `order` = index + 1, `x`, `y`, `rotationDeg`; numbers always with a fraction, e.g. `0.0`) |
| `apps/taro/assets/deck/crisis_resources.json` | `CrisisDirectory`: `countries`, `localeFallback` (all 12 locales), `international`; each entry `name`, optional `phone` / `sms` / `url` / `hours`, `languages`, `verifiedAt` (`YYYY-MM-DD`, or `null` until verified) |
| `worker/src/generated/deck/cards.json` | `deckId`, `version`, `cards[]`: `DeckCard` fields + canonical en `name`, `keywordsUpright`, `keywordsReversed` |
| `worker/src/generated/deck/spreads.json` | `version` (deck), `spreads[]`: `id`, `version`, `allowsReversals`, `positions[]` (`id`, `order`, `meaning`) |
| `worker/src/generated/deck_prompt.<locale>.json` | `locale`, `version`, `cards.<cardId>` = `name`, `keywordsUpright`, `keywordsReversed`, `shortUpright`, `shortReversed` (one file per built locale) |
| `worker/src/generated/crisis_resources.json` | byte-identical to the app copy |

`build` deletes an owned output that is no longer generated (e.g. a locale
that became incomplete) and never touches other files (such as
`assets/deck/art/`). `sync_check` reads only these outputs: Worker card IDs and
`DeckCard` fields equal `deck_meta.json`, en names and keywords equal
`en.json`, each `deck_prompt.<locale>.json` equals `<locale>.json` for exactly
the `deck_meta.locales`, the checksums match, spread IDs / versions /
reversals / positions agree, and the two crisis files are identical.

JSON is written with sorted keys, 2-space indent and a trailing newline;
lists keep the canonical order (GLOSSARY §1 cards, 01 §10.3 spreads).
