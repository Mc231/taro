# Taro content style guide

How every piece of deck content is written: card texts, spread texts, Learn
articles and the glossary. It applies to the English source and, through
`tools/content translate`, to every translation. Authoring agents, the owner
and native reviewers all work from this file.

- **Owner:** the product owner (Batch 0 sign-off, `docs/phases/PHASE_05_CONTENT_PIPELINE.md` Sprint 5.3).
- **Specs:** 01 PR1, PR2, PR15, §7.5, §7.9, §10.1–10.3, §11; 05 CS3, §9.5; 03 §9.2; 00_DECISIONS RC1, RC2, RC26, RC39, RC94.
- **File format and machine rules:** `apps/taro/content/source/README.md` (field names, YAML layout, what `tools/content validate` enforces).
- **Per-card review:** `docs/content/REVIEW_CHECKLIST.md`. **Batch log:** `docs/content/AUTHORING_LOG.md`.

If this guide and a spec disagree, the spec wins (00_DECISIONS first) and this guide is fixed in the same change.

---

## 1. Positioning and voice

Taro is **a reflective tarot journal** (01 PR1). The cards are prompts for
self-reflection; they never predict the future. Every sentence must survive the
question: *"Could a reader take this as a promise, a diagnosis or a verdict?"*
If yes, rewrite it.

The voice is:

| Quality | Means | Sounds like |
|---|---|---|
| Reflective | Offers a lens, not an answer | "This card invites you to consider…", "may reflect…", "you might notice…" |
| Warm, plain | Short sentences, everyday words, no jargon without a gloss | "a pause before the next step" |
| Respectful of agency | The reader decides; the card only asks | "What would you choose if…?", "You may want to…" |
| Grounded | Concrete images and situations, not mystical abstractions | "an unanswered message", "a desk cleared for new work" |
| Calm | No alarm, no drama, no doom, even for Death, the Tower or Ten of Swords | "an ending that clears space" |

Preferred verbs and frames: *invites, suggests, may point to, can reflect, asks,
offers, highlights, you might, perhaps, consider, notice, explore*.

Avoid: *will, must, always, never (about outcomes), destined, fated, reveals the
truth, the cards say/know/show that, warns you, you are going to*.

### Person and pronouns

- Address the reader as **"you"**, singular and gender-neutral. Never assume
  the reader's gender, age, relationship status, sexuality, family, job,
  religion, health or income.
- Other people are **"someone", "a partner", "a friend", "a colleague",
  "the other person"**, and are referred to as **"they"**. Never "he/she",
  "your husband/wife", "your boyfriend/girlfriend".
- Figures on the cards (the Empress, the King of Cups) may keep their traditional
  titles, but describe them as **qualities anyone can hold** ("the Empress's
  nurturing energy", "the steadiness the King of Cups stands for"), not as
  a person of a particular gender who will enter the reader's life.
- "Relationships" means any close bond: romantic, family, friendship, chosen
  family, working relationships. Write aspects that make sense for all of them.

### Register

- English: contemporary, neutral international English; US spelling (the canonical card name keeps the traditional "Judgement").
- Contractions are fine ("you're", "it's"). No slang, no emoji, no exclamation marks.
- Translations follow the Worker's per-locale register notes (03 §9.2 `style.<locale>.md`: e.g. `de` "du", `ja` polite form, `ar` Modern Standard Arabic); native reviewers own the register.

---

## 2. Banned claims

The single list of banned words and phrases is
[`tools/store_copy/banned_phrases.yaml`](../../tools/store_copy/banned_phrases.yaml)
(05 §9.5, RC39): `common.global` plus `locales.<locale>.global`. `tools/content
validate` fails any card, spread text or article that contains one
(case-insensitive, whole words, a trailing `*` is a stem), and
`tools/store_copy/check_store_copy.py` scans every text file under
`apps/taro/content/source/` (README and glossary included; the locale comes
from the path, `en` otherwise). The full list lives only in the YAML; read it there. Watch for ordinary English words on it: **best,
heal, heals, healing, medium, precise, accurate, accuracy, cure(s/d), therapy,
therapist, therapeutic, spell(s), hex, guarantee…, psychic…, clairvoyan…,
will happen, true reading**. Rephrase: "a middle path" (not *medium*), "mend",
"recover", "care for" (not *heal*), "most helpful" (not *best*), "clear" or
"specific" (not *precise*), "a charm", "a ritual" (not *spell*).

Beyond the lexicon, these **kinds of claims** are never made, in any wording
and any locale (01 PR1, 01 §7.5, 03 §9.2, 05 CS3):

| Never | Example to avoid | Write instead |
|---|---|---|
| Prediction or certainty about events | "You will meet someone new." / "Success is coming." | "This card may invite you to stay open to new connections." |
| Accuracy or special ability | "The cards know what you need." | "The card offers one lens for what you need right now." |
| Fate, doom, fear | "Disaster awaits if you ignore this." | "This may be a moment to look at what feels unstable." |
| Health, pregnancy, death of a person | "A recovery is near." / "A child is on the way." / "Someone will die." | Talk about energy, rest, care and change in general terms; point to a professional for health questions. |
| Legal outcomes | "You will win the case." | "Justice can invite you to weigh what feels fair to everyone involved." |
| Money, investment, gambling | "A windfall is coming." / "Now is the time to invest." | "You might reflect on how you relate to security and resources." |
| Religious or spiritual authority | "God is guiding you." / "Your angels are speaking." / "Your past life…" | Keep to psychology-neutral, secular language ("inner guidance", "your values", "what feels meaningful"). |
| Supernatural agency | "The universe/spirits are sending you a sign." | "You might treat this as a prompt to notice…" |
| Diagnosis or treatment | "This shows depression." / "Tarot as therapy." | "If heavy feelings stay with you, talking to someone you trust or a qualified professional can help." |
| Blame or judgement of the reader | "You are selfish." / "You failed." | "You may want to look at where your needs and others' needs meet." |
| Magic services | "A love spell", "remove a curse" | Never mentioned. |
| Fake urgency | "Act now before it's too late." | "There is no rush; the question can stay open." |

**Religious words that are part of a traditional card name** (the Hierophant,
the High Priestess, the Devil, Judgement) are allowed as names. Describe them
through their human themes (tradition and shared belief systems, inner
knowing, patterns that bind, reckoning and renewal), never as religious truth or
as statements about any faith.

**Death (`major_13`)** is always about transformation and endings of phases,
never about physical death. **The Devil (`major_15`)** is about patterns,
attachments and choices, never evil or possession. **The Tower (`major_16`)**
is sudden change and clearing, never catastrophe.

Crisis topics (self-harm, harm to others) are **never** discussed in card
texts. They are handled by the Worker's refusal flow and the crisis-resources
screen (01 §7.5). Cards like Three of Swords, Nine of Swords and Ten of Swords
speak about sorrow, worry and endings in a gentle, general way and never
describe injury, violence or hopelessness.

---

## 3. Length and format rules (01 §10.1)

The bounds below are **quoted exactly** from the `CardText` model in 01 §10.1
and enforced by `tools/content validate` (JSON Schema
`tools/content/schema/card.schema.json` plus word counts):

```dart
final String name;             // glossary-locked
final List<String> keywordsUpright;   // 3..6, each ≤ 24 chars
final List<String> keywordsReversed;  // 3..6, each ≤ 24 chars
final String shortUpright;     // ≤ 160 chars — daily card + reveal
final String shortReversed;    // ≤ 160 chars
final String meaningUpright;   // 120..220 words
final String meaningReversed;  // 100..200 words
final CardAspects aspects;     // relationships, work, growth: 40..90 words each, upright+reversed
final List<String> reflectionQuestions; // 3, each ≤ 120 chars
final String? imageryNote;     // 40..100 words describing the (original) art symbolism
```

| Field | Bound | Line breaks |
|---|---|---|
| `name` | glossary value, exact | single line |
| `keywordsUpright`, `keywordsReversed` | 3–6 items, each 1–24 characters, no duplicates (case-insensitive) | single line each |
| `shortUpright`, `shortReversed` | 1–160 characters | single line |
| `meaningUpright` | 120–220 words | paragraph breaks allowed |
| `meaningReversed` | 100–200 words | paragraph breaks allowed |
| `aspects.*` (6 texts) | 40–90 words each | paragraph breaks allowed |
| `reflectionQuestions` | exactly 3, each 1–120 characters, ending in `?` | single line each |
| `imageryNote` | 40–100 words | paragraph breaks allowed |

Counting: a **word** is a whitespace-separated token containing a letter or
digit; **characters** are Unicode code points. Translations keep the character
limits; word limits widen to ×0.7 (min) … ×1.4 (max), and `ja` is capped at
4 × the max word count in characters (see the source README).

**Aim for the middle of each range**, not the edge: about 160–180 words for
`meaningUpright`, 140–160 for `meaningReversed`, 55–70 per aspect and 60–80 for
`imageryNote`. Translations expand, and an edit pass should not have to cut.

Format (all fields):

- **Plain text only.** No Markdown (`*`, `` ` ``, `~~`, `__`, `](`, lines
  starting with `#`, `>`, `- `, `+ `, `1. `), no HTML, no emoji.
- No leading or trailing whitespace. Use folded YAML blocks (`>-`) for long
  texts; a blank line inside is a paragraph break. Use at most two or three
  paragraphs in a meaning and one or two in an aspect.
- Typographic apostrophes and quotes are fine ("you're", "‘inner voice’"); be
  consistent within a card.
- Do not repeat the card's name more than once or twice per field; say "this
  card" or name the image instead.
- Numbers in running text are words ("two paths", "three cups").

---

## 4. Upright and reversed framing

**Upright** describes the card's core theme in its open, available form: what
the image invites you to notice or try.

**Reversed** is **not** "the bad version" of the card. Use one of these
framings, and vary them across the deck:

1. **Blocked or delayed:** the energy is present but held back ("the
   spark may be there, but something keeps it from catching").
2. **Turned inward:** the theme is working privately rather than outwardly
   ("confidence that needs to be found inside before it shows").
3. **Too much or too little:** the quality is overdone or missing
   ("care that has turned into control", "rest that has become avoidance").
4. **An invitation to revisit:** something in the upright theme asks for a
   second look ("an old plan that may need updating").

Rules for reversed text:

- Stay as warm as upright. Never shame, blame or frighten.
- Each reversed text ends on agency: something the reader can notice, ask or
  try.
- For cards whose upright is already difficult (Five of Pentacles, Three of
  Swords, Ten of Swords, the Tower), the reversed text often points to
  **recovery, release or the worst passing**; say so in reflective terms
  ("may reflect a slow return of steadiness"), never as a promise.
- The app shows reversals only when the spread `allowsReversals`; the text
  must still make sense on its own.

---

## 5. Future, outcome and potential positions (01 §10.3)

01 §10.3: *"'Future' or 'outcome' positions are described as 'where things may
be heading if nothing changes', never as fate (PR1)."*

This applies to the position ids `future`, `outcome`, `near_future`,
`potential`, `path_a_outcome`, `path_b_outcome` and `hopes_fears`, and to any
card text that talks about what comes next.

| Position | Wording pattern |
|---|---|
| `future`, `near_future` | "Where things may be heading if nothing changes." / "A direction that current patterns may lead toward." |
| `outcome` | "Where the situation may be heading if the present course continues; something you can still shape." |
| `path_a_outcome`, `path_b_outcome` | "Where this path may lead if you follow it as it is now." |
| `potential` | "What could grow here, if it is given attention." |
| `hopes_fears` | "What you hope for or worry about, sometimes both at once." Never frames a fear as something that will happen. |

Rules:

- Always pair a "heading" statement with **agency**: the reader can change
  course, and the reading is one lens among many.
- Never give a time frame ("within three months", "by spring").
- Never give yes/no answers, odds or comparisons of which path is "right".
  Two Paths compares what each path may **ask of you** and **offer you**.
- Card texts are position-agnostic: do not write "in the future position,
  this card means…". Position meanings live in `en/spreads.yaml` (`meaning`,
  5–40 words, Worker prompt context 03 §9.2), and position names and
  descriptions for the UI live in ARB (`spread_{spreadId}_pos_{positionId}_name/_desc`).

---

## 6. Per-field guidance (`CardText`)

Field names are exactly those of taro_core `CardText` (01 §10.1) and of the
source YAML (`apps/taro/content/source/README.md`).

### `cardId`
Canonical ID only (GLOSSARY §1): `major_00` … `major_21`,
`{wands,cups,swords,pentacles}_01` … `_14` (01 = Ace, 11 = Page, 12 = Knight,
13 = Queen, 14 = King). Equals the file name.

### `reviewStatus`
`machine` for every LLM draft, **English included**, and every machine
translation. Only a person sets `reviewed`, after the edit pass in
`REVIEW_CHECKLIST.md`, and records it in `AUTHORING_LOG.md`.

### `element`, `astrology` (en only)
Minor cards: the suit element (wands = fire, cups = water, swords = air,
pentacles = earth). Major cards: the traditional elemental/astrological
correspondence as a lower snake_case key (`venus`, `aries`, `sun_in_leo`).
These are shown as correspondences in Learn (01 §7.9); body text never claims
astrology influences events.

### `name`
Exactly the glossary value (`glossary.yaml` `cards.<cardId>.<locale>`). Never
abbreviate, re-case or add "the" when the glossary has none ("Strength", not
"The Strength").

### `keywordsUpright`, `keywordsReversed`
- 3–6 short noun phrases, lower case (unless a proper noun), ≤ 24 characters.
  Aim for 4–5.
- Concrete, reflective themes: "fresh start", "trust in the process",
  "honest boundaries". Not predictions ("new lover"), not labels of people
  ("liar"), not banned words.
- Reversed keywords describe the reversed framing (§4), not simply the
  opposite word ("hesitation", "inner doubt", "scattered energy"). They must
  not all be negative; at least one can point to recovery or reflection.
- Keywords feed the Worker prompt (03 §9.2), so keep them unambiguous and
  free of irony.

### `shortUpright`, `shortReversed`
- One sentence, ≤ 160 characters, shown on the daily card and on reveal.
- A self-contained invitation in second person: "A moment to notice who shares
  your joys, and how you share theirs."
- No name repetition, no keywords list, no question (questions go in
  `reflectionQuestions`).

### `meaningUpright` (120–220 words)
Suggested shape, two or three paragraphs:
1. What the image and theme are about, in plain words.
2. How this theme might show up in everyday life (two or three concrete
   situations the reader may recognise).
3. A gentle invitation: what the card asks the reader to notice or try.

### `meaningReversed` (100–200 words)
Same shape, using one of the reversed framings in §4. Ends on agency.

### `aspects` (six texts, 40–90 words each)
`relationshipsUpright`, `relationshipsReversed`, `workUpright`, `workReversed`,
`growthUpright`, `growthReversed`. Shown under the headings Relationships,
Work & purpose, Personal growth (01 §7.9).

- **Relationships:** any close bond (§1). No predictions about partners,
  meeting someone, break-ups, fidelity or pregnancy. Focus on communication,
  needs, boundaries, care.
- **Work & purpose:** work, study, caregiving, creative projects, volunteering
  and purpose in general. No career or money outcomes, no advice to quit, sign,
  invest or sue.
- **Personal growth:** habits, self-understanding, values, rest, learning.
  No medical or mental-health claims; "rest" and "care" are fine, "treatment"
  and "healing" are not.
- Each aspect stands alone (the app may show one without the others) and does
  not simply repeat the meaning.

### `reflectionQuestions` (exactly 3, each ≤ 120 characters)
- Open questions, second person, answerable in a journal: "What", "Where",
  "How", "Which", "When did you last…".
- Avoid yes/no questions and leading questions ("Isn't it time you left?").
- One question looks inward, one looks at a relationship or context, one at a
  small next step. End with `?` (`؟` in `ar`, `？` allowed in `ja`).

### `imageryNote` (40–100 words)
Describes the symbolism of **Taro's original art** (D15), never the
Rider–Waite–Smith artwork or any other published deck (05 §1 row 4.1/5.2).
Until the D15 art exists, write it as an art-direction note in general terms:
the traditional motifs the card is known for (a cliff edge, cups, a wheel,
a star over water) and what they may symbolise, without describing a
specific published illustration's composition, colours or details. Rewrite it
when the art lands (`docs/ART_PROVENANCE.md`).

### `sourceHash`
Never written by hand. Absent in `en`; written by `tools/content translate`
in translations.

---

## 7. Examples

### Good and bad sentences

| Bad (and why) | Good |
|---|---|
| "The Ten of Cups means your family will be happy." (prediction) | "The Ten of Cups may invite you to notice where you already feel at home." |
| "Beware: the Tower warns of disaster." (fear) | "The Tower can reflect a sudden change that clears away what no longer holds." |
| "Death means someone close to you will pass." (death claim) | "Death points to an ending of a phase, and the space it can leave for something new." |
| "This card guarantees success in your exams." (certainty, banned word) | "This card may reflect the steady effort you are already putting in." |
| "Your boyfriend is hiding something from you." (gender, accusation, prediction) | "You might consider whether something between you and someone close is going unsaid." |
| "The Ace of Pentacles is a sign money is coming; invest now." (financial) | "The Ace of Pentacles can invite you to notice a practical opportunity worth a closer look." |
| "Temperance heals your wounds." (banned word, health claim) | "Temperance can suggest a slower pace that gives you room to recover your balance." |
| "The High Priestess connects you with the spirit world." (supernatural) | "The High Priestess invites you to listen to what you already sense but have not said out loud." |
| "This is the best card in the deck!" (banned word, hype) | "Many readers find this card a hopeful one to sit with." |
| "Reversed, the Empress means you are a bad carer." (blame) | "Reversed, the Empress may ask whether you have left yourself out of the care you give." |
| "In the outcome position the Sun means you will win." (fate) | (Card text is position-agnostic; see §5.) "Where things may be heading if nothing changes: toward more clarity and warmth." |

### Good keyword sets

- Upright: `new beginnings`, `curiosity`, `trust`, `a leap into the unknown` (secular; not "a leap of faith").
- Reversed: `hesitation`, `holding back`, `careless risk`, `waiting for readiness`.
- Bad: `new lover` (prediction), `betrayal` (accusation), `guaranteed win` (banned word, certainty), `bad luck` (fear).

### Good reflection questions

- "What would you try if you trusted yourself a little more?"
- "Who in your life makes it easier to rest, and how could you tell them?"
- "What is one small step you could take this week?"

---

## 8. Original writing

- Write every text **from scratch**, from the card's traditional theme and
  Taro's own art. Never copy, closely paraphrase or translate text from tarot
  books, guidebooks, the Rider–Waite–Smith "Pictorial Key", apps or websites.
- Traditional keyword ideas (e.g. "new beginnings" for an Ace) are common
  vocabulary and may be used; sentences, examples and structure must be ours.
- LLM drafts are drafts: they stay `reviewStatus: machine` until the owner's
  edit pass (`REVIEW_CHECKLIST.md`) and a row in `AUTHORING_LOG.md`.
- Do not mention Rider–Waite, Waite, Smith, Thoth, Marseille or any other
  deck or publisher by name in card texts (05 §9.3 excludes deck trademarks);
  the Learn "About" article may give neutral history.

---

## 9. Glossary and translation

- `apps/taro/content/source/glossary.yaml` fixes card, suit, arcana and
  position names and key terms in all 12 locales (01 §11 step 2). A card's
  `name` must equal its glossary entry exactly, and translations must use the
  glossary's term for every suit, position and key term they mention.
- Each locale's glossary block carries a `review` state: `machine` until a
  native reviewer checks it, then `reviewed`. The glossary must be 100 %
  reviewed for a locale before any card translation into it (01 §11 step 4).
- Translators keep meaning, warmth and agency, not word order. The banned
  lists for the target locale apply (`banned_phrases.yaml`
  `locales.<locale>`), including stems like `genau` (de), `exact*` (es/fr),
  `kesin*` (tr), `точн*` (uk) and `必ず` (ja).
- Card names keep the established traditional name in each language; do not
  invent new ones.
