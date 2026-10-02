# Content review checklist

The per-card checklist for the **owner's English edit pass** (Phase 5
Sprint 5.3) and for **native reviewers** of translations (Phase 18, 01 §11
step 6). A card may be set to `reviewStatus: reviewed` only when every box
below is ticked. Rules and examples: `docs/content/STYLE_GUIDE.md`. File
format: `apps/taro/content/source/README.md`.

Only a person flips `reviewStatus` from `machine` to `reviewed`. Record every
batch in `docs/content/AUTHORING_LOG.md`.

---

## 0. Before the batch

- [ ] `tools/content validate` runs clean for the batch (schema, bounds, glossary, banned phrases, plain text, bidi).
- [ ] The locale's glossary block is `review: reviewed` (translations only; 01 §11 step 2 gate).
- [ ] For translations: the `sourceHash` matches the current `en` card (not reported **stale**).

## 1. Identity (per card)

- [ ] `cardId` is canonical (GLOSSARY §1) and equals the file name.
- [ ] `name` equals `glossary.yaml` `cards.<cardId>.<locale>` exactly.
- [ ] `element` / `astrology` (en only) are the traditional correspondence; minor cards carry the suit element.

## 2. Voice and safety

- [ ] Reflection voice throughout: invites, may, might, consider (01 PR1). No sentence reads as a prediction, promise or verdict.
- [ ] No certainty or accuracy claims, no supernatural agency ("the cards/spirits/universe say"), no fate, doom or fear.
- [ ] No health, pregnancy, death-of-a-person, legal, financial, investment or gambling claims or advice.
- [ ] No religious or spiritual-authority claims; religious card names are described through human themes.
- [ ] No mention of self-harm, violence or hopelessness (crisis topics belong to the refusal flow, 01 §7.5).
- [ ] Gender-neutral "you"; other people are "someone", "a partner", "they". No assumptions about gender, relationship, family, job, faith, health or income.
- [ ] No blame or shame, especially in reversed texts. Each reversed text ends on something the reader can notice, ask or try.
- [ ] No banned words from `tools/store_copy/banned_phrases.yaml` for this locale, including the "ordinary" ones (best, heal, medium, precise …); the validator catches exact words, the reviewer catches paraphrases and near-synonyms ("definitely", "for sure", "destined").
- [ ] Nothing about time frames ("within weeks"), yes/no answers or odds.

## 3. Content quality

- [ ] Keywords (3–6 each) are short, concrete themes; reversed keywords follow a reversed framing (blocked, inward, too much/too little, revisit), not just antonyms.
- [ ] `shortUpright` / `shortReversed` are one self-contained sentence each, ≤ 160 characters, and read well on the daily card.
- [ ] `meaningUpright` / `meaningReversed` explain the theme, give everyday situations and end with an invitation; no repetition of the short text word for word.
- [ ] The six aspects each add something specific to Relationships, Work & purpose and Personal growth, and each stands alone.
- [ ] Relationships aspects fit any close bond (partner, friend, family, colleague).
- [ ] Exactly 3 reflection questions: open (not yes/no), not leading, one inward, one about others or context, one about a small next step.
- [ ] `imageryNote` describes Taro's **original** art (or, until D15 lands, general traditional motifs); it does not describe Rider–Waite–Smith or any other published illustration.
- [ ] The card is consistent with its neighbours (same suit, same rank across suits) and does not contradict the glossary terms.
- [ ] Plain text only: no Markdown, HTML or emoji; paragraphs only where allowed.

## 4. Originality

- [ ] The text is original. Spot-check two distinctive sentences with a web search; nothing matches a book, guide, app or website closely.
- [ ] No deck, publisher or artist names (Rider–Waite, Thoth, Marseille …).

## 5. Translations only (native reviewer)

- [ ] Meaning, warmth and agency match the `en` source; nothing is added or dropped.
- [ ] Register follows the locale's style note (e.g. `de` "du", `ja` polite form, `ar` Modern Standard Arabic).
- [ ] Every card, suit, position and key term uses the glossary spelling.
- [ ] Natural, idiomatic text; no calques or machine-translation artefacts.
- [ ] Locale-specific banned words and their natural synonyms are absent.
- [ ] `ar`: text renders correctly RTL; numbers and Latin fragments are placed correctly; no stray bidi control characters.
- [ ] `ja`/`ko`: line breaks and punctuation look natural; `ja` questions may end in `？`.

## 6. Sign-off

- [ ] `reviewStatus: reviewed` set on the card. For a minor card outside the 20 % long-text sample, set only `shortReviewStatus: reviewed` once sections 1, 2 (name, keywords, short texts), 3 (keywords, short texts) and 5 are ticked for those fields.
- [ ] Batch row added to `docs/content/AUTHORING_LOG.md` (date, batch, cards, author = owner or native reviewer, `reviewed`).
- [ ] `tools/content validate` green again after the edits.

---

## Glossary review (per locale)

- [ ] All 78 card names use the established traditional name in this language and the rank/suit pattern is consistent across all four suits.
- [ ] Suit, arcana, position and key-term names are natural and consistent with the app's ARB strings (spread and position labels).
- [ ] No entry contains a banned word for the locale.
- [ ] Set `review.<locale>: reviewed` in `glossary.yaml` and log it in `AUTHORING_LOG.md` (batch `glossary`).
