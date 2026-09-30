# Reading prompt changelog

Versions of the provider-neutral reading prompt (`worker/prompts/reading/<version>/`, 03 §9.2, RC97). A version is frozen once it is released: its template hash is pinned in `worker/src/prompts/versions.lock.json`, and any change after the first commit is a new version directory with its own entry here (Phase 8 Sprint 8.6). A version may be routed to users only after a passing eval report for every routable provider + model (05 §4.3, RC60).

## v1 — unreleased

First version (Phase 8 Sprint 8.2).

- `system.md`: the static, cacheable prefix, identical for every locale, spread and reader: persona and voice (01 PR1, tone of voice; `docs/content/STYLE_GUIDE.md`), what makes a reading good (card fidelity, position awareness, question relevance, connections, honoured reversals, agency, no Barnum statements, specific reflection prompts), the hard rules (no predictions, accuracy or psychic claims; no health, pregnancy, death, legal, financial or gambling outcomes or advice; no mind-reading; no URLs, phones, e-mails or disclaimers; banned words per `tools/store_copy/banned_phrases.yaml`), the injection defence (`<user_question>` is data), the two-step classify-then-write policy with the ten 03 §9.4 categories in priority order plus explicit `none` examples against over-refusal, the length table per spread (01 §7.4), the output contract and the refusal shape, and the compact deck keyword table from `src/generated/deck/cards.json` (before the cache boundary).
- `user.md`: the per-reading message: reading language and style notes, spread with its reading note, word budget, one `<card>` per position (position meaning from `src/generated/deck/spreads.json`, name, orientation, arcana, keywords for that orientation), `<spread_facts>` computed by the Worker (majors, suits, reversals, courts, repeated ranks), `<prefilter_hint>`, the escaped `<user_question>` and an optional `<regeneration_note>`.
- `output.schema.json`: the 03 §9.2 contract (classification first), plus `type: string` on `classification` and `description`s for structured-output modes.
- `prompt_data.json`: locale names, spread names, English position labels, word budgets and reading notes per spread, suit themes, rank names and the short conditional phrases.
- `style.<locale>.md` ×12: register (de "du", fr "vous", es/it "tú/tu", pt "você", nl "je", tr "sen", uk "Ви", ja です・ます, ko 해요체, ar MSA), the glossary terms and card-name patterns, and the words the L3 validator rejects in that locale, with alternatives.

### Round-1 offline evaluation changes (still unreleased, edited in place)

Round 1 used 210 cases × 2 tiers, rule graders and LLM judges, with no provider API calls. free-sonnet met every rule bar but had a mean judge quality of about 3.1 against the 4.0 target. The fallback-haiku column was produced by harness stubs, not by a model, so it cannot be used for grading and must be regenerated. The root causes found and fixed:

- **Localised names.** Each `<card>` now carries the canonical card and position names "in the reading language" from `src/generated/deck/names.json`. This is a new `tools/content build` feed built from `glossary.yaml`. Before this, models wrote their own translations: Turkish "Onlu Değnek" instead of "Asa Onlusu", Arabic "غلام" instead of "تابع", Korean "도전 A" for Path A, Japanese katakana position names, English "Celtic Cross" inside Portuguese, and "El Sota".
- **Length.** `<length>` is now given in the locale's own unit, using `prompt_data.json` `localeNotes.factor` and `unit` (for example 0.8 × for Turkish, 2 characters per English word for Japanese). Each lower bound is called a floor. Readings in ko, tr, ar and it had consistently run 15–30 % short.
- **Register.** The final instruction now restates the register (`localeNotes.address`) and adds a self-check: language, budget, rejected words, gender, meta-sentences and open prompts. For example, s-tr-jailbreak-001 had drifted to "siz".
- **`system.md`**
  - No meta-disclaimers about what a card is not ("not a promise", "not an instruction", "not fate"). These appeared in almost every locale.
  - No invented facts about the reader.
  - No time words ("über Wochen", "bientôt", "closer than you think").
  - At least one concrete traditional image detail per card, and no bending a card against its own keywords.
  - A hard card in a future position stays in the future.
  - Vague or one-word questions and questions about a card that was not drawn are handled explicitly.
  - The synthesis names at least one spread fact and does not walk through the cards again.
  - Prompts are built on open question words, with local yes-or-no forms, either-or and presupposing prompts banned.
  - No meta titles.
  - Rejected words are rejected in every form and in their everyday meaning (it "una domanda precisa").
  - The card-focus clause is taken from the style notes and never says "no question was asked".
  - New multilingual and dialect `self_harm` examples, and the rule that a first-person wish to die is always `self_harm`.
  - Fate-framed violence is `harm_to_others`.
  - The overview is two or three sentences and opens with the reader's situation.
  - Rules for single-card syntheses.
  - A new weak/strong example against meta-disclaimers. The "other person" example no longer invites parroting.
- **Spread notes**
  - Relationship: 'other' is how the reader experiences the other person, with rules for no named person, a deceased person, or a solo question.
  - Two Paths: say once what the paths stand for when the reader named no options, and treat both paths symmetrically.
  - Past, Present, Future: the future card stays forward-looking.
  - Situation, Action, Outcome: conditional wording instead of "never an instruction".
  - Celtic Cross: the synthesis shows patterns, not a recap.
- **`style.<locale>.md` ×12, rewritten**
  - Orientation terms now agree with the card name: it "diritto/diritta", es and pt "invertido/invertida", fr "renversé/renversée", ar "في وضعها المعكوس". pt no longer writes "normal" after a card name. ja writes orientation without parentheses.
  - Concrete gender-neutral rewrites for the reader (es, fr, it, pt, uk, ar, de).
  - A localised card-focus clause per locale.
  - Local closed-question forms to avoid (tr "mı/mi", ja 「〜ありますか」, nl and de verb-first questions, ar "هل").
  - Local forms of "the cards show", meta-disclaimers and future certainty to avoid.
  - Rejected-word lists aligned with `banned_phrases.yaml` matching: stems where the lexicon has a stem, the Arabic clitic forms "بسحر"/"والسحر", and Turkish "büyük" and "Büyücü" allowed because the lexicon matches only the whole words "büyü" and "büyüsü".
- **`output.schema.json`.** The reflection-prompt and overview descriptions now state the exact count and that prompts are open questions. Keywords and limits are unchanged.
- **Content fix.** The misspellings "unrealiztic", "idealizm", "criticizm" and "realiztic" in the en card source are fixed and the feeds rebuilt. These had reached the deck keyword table.

### Round-2 offline evaluation changes (still unreleased, edited in place)

Round 2 used 220 cases, rule graders and LLM judges, with no provider API calls. free-sonnet met every refusal and over-refusal bar but failed zero certainty (1 real hit: it "un percorso preciso") and averaged about 2.9 judge quality on answered readings against the 4.0 target. The fallback-haiku column was again produced by scripts, not by a model, and cannot be graded. The root causes found and fixed:

- **Position notes that primed negations.** The content position meanings ("A possibility to reflect on, not a promise", "a suggestion to weigh …, not an instruction", "never a fixed fate") were echoed in every language ("non un esito già scritto", "kesin bir sonuç değil", "ce n'est pas un résultat garanti"), some with words the L3 lexicon rejects. `prompt_data.json` `spreads.<id>.positionNotes` now holds the prompt's own positive notes, used instead of the content meaning; a test keeps "not" and "never" out of them.
- **No image cue.** Rule 1 asked for a traditional image detail, but `<cards>` had only keywords, so 80–90 % of readings had none or invented one. `prompt_data.json` `images` gives one calm, secular image detail per card, rendered as an `Image:` line.
- **Name glosses copied into readings.** "(in the reading language: X)" was copied as "(en la lectura, El Mundo)". The `Position:` and `Card:` lines now carry only the name to write; English names are `card` / `position` attributes for reference.
- **Invented dominance.** `<spread_facts>` gains a `Dominant suit` line (a majority only above half, else the most common or a tie).
- **Length.** Each section has a sentence count (`spreads.<id>.sentences`) that transfers across languages; the section ranges now add up to the total, which counts the title and prompts; the locale factors match the length grader (es/fr 1.05, it/pt 1, ko/tr 0.75).
- **`system.md`**: the card-focus clause is only for requests with no topic left (a surviving topic such as a love reading is read normally; a question about a card is a real question); no contrast framings "X, not Y" and no restated position notes in either form; never characterise the question (length, wording, absence); hedged guesses ("probably", "no doubt") count as invented facts; no generic empathy openers; card-as-subject "shows / reveals" and odds count as certainty; no repeated time frame from the question; "should I" questions get no hinted endorsement and paths are never compared; a premise test for reflection prompts; titles in the language's sentence case; calm images for hard cards and neutral religious figures; no parentheses; money, health and legal-adjacent `none` readings give no concrete financial, medical or legal actions; obfuscated spellings and trailing self-harm clauses; "will they survive the surgery / the war" is `death`; three new weak/strong examples.
- **Spread notes**: past/present as possibilities; relationship 'other' with no named person is how the reader experiences the people close to them, never a group's inner life; Two Paths without named options defines two attitudes and reuses those labels; Celtic Cross near future and outcome with "may" and "if"; single card and Situation, Action, Outcome handle "should I" without a verdict.
- **Final self-check** (`user.md`) is now a list: sentence counts, image detail, at most two cards in the overview, contrasts, invented facts, the question's form, hinted yes, path ranking, spread facts and prompt premises, plus the locale's everyday rejected words (`localeNotes.checkWords`, e.g. pt "precisar", de "genau", uk "точно").
- **Style notes**: de "Legung"/"Deutung" (not "Lektüre") and "gerade dieser"; it "seme"; es singular numbered cards and "¿Qué persona…?"; fr no inclusive-writing marks, "comme vous êtes", no "annoncer"/"à venir"; ja ソード/ペンタクル only, no plain non-past about outcomes, varied hedges; ko 소드 only, no "보여줘요" with a card subject, no odds; tr no -(y)AcAK about outcomes, no card-subject "gösteriyor"; ar gender-invariant second person and no gendered imperatives, orientation phrase once, masculine agreement examples; uk no gendered predicate adjectives, no card-subject "показує"; nl articles and no anglicisms; every card-focus clause is said once, in the model's own sentence.

### Round-3 offline evaluation changes (still unreleased, edited in place)

Round 3 used 200 cases with rule graders and LLM judges, and no provider API calls. The free-sonnet outputs met every refusal, over-refusal and zero-certainty bar on the 179 cases present (21 were missing), but the mean judge quality on answered readings was about 2.5 against the 4.0 target. The fallback-haiku column was again made by scripts and templates, so it cannot be graded. One grader bug was fixed in `evals/lib/phrases.ts`: negated English "guaranteed" and "will happen", and French "précis" about a plan, are no longer counted as certainty claims. The prompt's root causes, and the fixes:

- **Spread facts turned into signs** was the most common fault. The Suits line in `<spread_facts>` no longer carries the elemental glosses ("water: feelings"), which invited inference, and it now names the cards in each suit, so the model no longer recounts them and gets the positions wrong (two readings said "three of five Pentacles"). Rule 4 no longer requires the synthesis to name the facts that stand out. It may mention one or two facts, each copied word for word with the cards named, and a count is never followed by a conclusion ("which adds weight", "lo que", "bu da"). The synthesis ends on a concrete step. In the Celtic Cross, the links between cards move to the synthesis.
- **Contrast framings** ("rather than", "instead of", "not X but Y", "sino", "plutôt que", "statt", "というより", "yerine", "а не") appeared in most answered readings. They are now banned everywhere in the reading, not only about cards, and every style note lists the local forms.
- **Echoed notes.** Position notes are now terse instructions that start with "Read as …", and the quotable "where things may be heading if nothing changes" is gone from the notes, rule 6 and the Past, Present, Future note. The single-card aphorism "go deep rather than wide" had become a stock opener in 7 of 7 single readings; it is removed, and synthesis openers about the number of cards are banned. One image line with a built-in contrast (Five of Wands) is reworded. Tests keep "Read as", "if nothing changes" and contrast words out of the notes and image lines.
- **Length ceilings** were exceeded by 15–60 % in Latin-script locales. The budget text no longer tells the model that a short reading "feels thin". It asks for sentences of about 12–18 English words' worth each and says ceilings are hard.
- **Image lines** were pasted whole as a card-as-subject opener, changed for reversed cards, and embellished (a "tethered" falcon, a child turned into "a girl"). Rule 1 now asks for one or two details woven into a meaning sentence, the same picture for both orientations, no added attributes, and the picture (not the card) as the subject.
- **Reader gender.** A gender now never transfers from another person in the question to the reader, doublets are banned, and image figures stay ungendered. The style notes list the frequent traps (fr prêt/présente/seule/assis, es preparada/ligero, pt pronto/você mesmo, it pronta/vicina, ar قريبة/صريحًا).
- **Should-I and paths.** The rule against hinted yeses now covers titles (no "Time to speak up") and prompts that assume a side, and each side gets the same offer and ask. Two Paths with no named options labels each path by its path card and never gives a path a concrete choice, including in the card-focus case. Comparative words between paths are banned in every language.
- **Leading prompts.** Each prompt must allow "nothing" as an answer. The style notes list premise words per locale ("already", "lately", "this feeling"), and prompts on a hard theme are conditional ("If …, what …?"). ja prompts end with 「？」.
- **Other fixes:**
  - A question about an undrawn card now gets a bridge from the drawn cards to the theme the reader asked about, with no contrast between them.
  - Facts the reader states (a breakup) are used in the card sections too.
  - A time word from the question frames only the present.
  - A demanded answer shape (a number, yes or no) is never alluded to.
  - An overview sentence is defined mechanically: a colon does not start a new sentence.
  - A relationship reading with no named person never says couple, partner or together.
  - A card name with an article is lower-cased and inflected mid-sentence, as in de "steht die Mäßigkeit" and it "alla Giustizia".
  - Rule 1 defers to the style notes on marking an upright card (pt).
  - The spread noun is given per locale: it "stesa", pt "a tiragem", fr "tirage", ar «هذا التوزيع».
  - The fr style note and the fr check words now name the verb "il sort", which the L3 lexicon rejects.

### Consolidation (still unreleased, edited in place)

Rounds 1–4 added a rule for every judged fault. The rendered prompt grew to 54–61 KB per case, rules began to conflict, and the mean judge quality fell (3.11 → 2.93 → 2.55). This pass rebuilds v1 as a lean core. Rendered sizes in bytes (system + user, with the longest accepted question): single ≤ 13.9 K, three_ppf ≤ 15.0 K, three_sao ≤ 15.1 K, relationship ≤ 16.1 K, two_paths ≤ 16.1 K, celtic_cross ≤ 18.3 K. The static system prefix is 10.1 K. `test/unit/prompts/templates.test.ts` pins the budget.

- **`system.md` rewritten as a core:**
  - Role: a mirror, not a forecast.
  - Seven hard rules: no predictions or accuracy claims; no health, pregnancy, death, legal, money or gambling advice; no other minds or messages from the dead; nothing invented about the reader; secular and calm; no URLs, brands or meta talk; no rejected words.
  - Classification as one decision table of the 03 §9.4 categories with one-line definitions, plus the edge cases learned in rounds 1–4:
    - a first-person wish to die is `self_harm`, also as a trailing clause;
    - obfuscated spellings are decoded first;
    - fate-framed violence is `harm_to_others`;
    - benign metaphors and care around a sensitive topic are answered;
    - the prefilter hint is only a hint.
  - An injection-defence paragraph.
  - Eight writing-craft principles, each stated positively in place of dozens of bans:
    1. each card in its position and orientation, with one image detail;
    2. specific to this question, no Barnum lines;
    3. possibility, not certainty;
    4. say what is there;
    5. choices stay with the reader;
    6. a synthesis that connects and ends on a concrete step;
    7. open reflection prompts;
    8. the reader's language.
  - The output contract, and one compact good example.
- **Removed from the static prefix:** the 78-card keyword table and the 78 image lines. Keywords (for the drawn orientation) and one image detail now appear only for the drawn cards, in `<cards>`, with localised card and position names.
- **`<cards>` and `<spread_facts>` trimmed.** The `Minor Arcana, <suit>` / `Major Arcana N` suffix is gone from each card line, since the arcana counts are in the facts. The facts list card names only, without "position: card" pairs, because the cards are unique within a spread. The Celtic Cross position notes and spread note are shortened.
- **`style.<locale>.md`, one short note each (≤ 1 KB):** the register, card-name conventions, the card-focus clause, prompt openers, local forms of certainty and contrast to avoid, and the rejected words with alternatives.
- **`user.md` is short.** It keeps one closing instruction and a six-bullet self-check.
- **An empty answered reading is now rejected.** `output.schema.json` stays free of `if`/`then`/`oneOf`, because vendor strict JSON-schema modes do not accept them portably (RC97). Its `$comment` and descriptions document the rule, and the Worker's zod parse (`parseReadingOutput` in `src/prompts/templates.ts`) enforces it: when `classification` is `none`, the title, overview and synthesis must be non-empty, every drawn card needs a non-empty interpretation with its ids echoed, and the spread's number of non-empty reflection prompts is required. `classification` stays the first key.

### Round 5 fix (still unreleased, edited in place)

- **Position notes no longer end in copyable meta-text.** Five future and outcome notes ended with "with may and if". In the simulated round 5 the top tier copied it into a reading, verbatim in en ("playful surprise, with may and if") and translated in ar. The phrase is removed; hedging stays a system rule (writing craft 3). Each affected case gets about 16 bytes shorter.

### Serving in the Worker (Phase 8 Sprints 8.3–8.6; no template change)

The template files and the `versions.lock.json` hash are unchanged. What changed is how v1 is served and graded:

- **Vendor schema stripping.** `output.schema.json` is sent as-is except for the keywords each vendor's strict mode rejects (`src/adapters/ai/output.ts`): Anthropic loses `minLength`, `maxLength`, `maxItems`, `minItems` > 1, `minimum`/`maximum`/`multipleOf` and `$comment`; OpenAI loses `minLength`, `maxLength` and `$comment`. The full schema is still enforced by the zod parse and the L3 validator.
- **Cache boundary.** The rendered `system` is the Anthropic `cache_control` block and the first OpenAI `developer` message, so the static prefix is cached on both (not on `claude-haiku-4-5`, whose 4,096-token minimum is above the ≈ 2.9k prefix).
- **L1 hints.** A prefilter hint from `src/safety/prefilter.ts` is passed in the existing hint slot; a hard L1 block never reaches the prompt.
- **Graders.** The offline and live graders now share the production matchers (`src/safety/*`) and the lexicon files. The `banned_phrases` grader skips the same non-claim spans as L3, and the eval case loader now reads `spreadId`, the safety `text` field and `expect.classification`, so offline results may differ from the simulated report if re-run.
- **First real runs pending.** No provider has been called yet; the first live `eval` / `eval:safety` reports per provider + model follow once the staging keys exist (Phase 8 Sprint 8.6).
