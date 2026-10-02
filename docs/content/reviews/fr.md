# Self-review: fr (French, vous-form)

This is the LLM self-review pass (01 Q5, Phase 18 Sprint 18.3) over the machine translation of `fr`. Everything listed here is still `reviewStatus: machine`. Nothing counts as `reviewed` until a native reviewer signs it off (01 §11 step 6, launch gate).

## Scope

| Part | Files | Words (fr) |
|---|---|---|
| UI strings | `apps/taro/lib/l10n/arb/app_fr.arb`: 776 keys. The 673 `x-translate` placeholders are now translated and all markers are removed. 25 earlier strings were revised for register and glossary (see 8). | ~5,100 |
| iOS Info.plist | `apps/taro/ios/Runner/fr.lproj/InfoPlist.strings` (`NSUserTrackingUsageDescription`) | 17 |
| Cards | `apps/taro/content/source/fr/cards/*.yaml` (78 of 78) | ~67,200 |
| Spreads | `apps/taro/content/source/fr/spreads.yaml` (the 6 `whenToUse` texts) | ~340 |
| Articles | `apps/taro/content/source/fr/articles/{about,faq}.md` | ~2,900 |

Crisis resources have no per-locale description field, because `crisis/crisis_resources.yaml` is one shared file. The crisis UI copy lives in the ARB (`crisis*`, `safetyDeclined*`) and is covered above.

Format: every content file carries the current en `sourceHash` and `reviewStatus: machine`. Card and spread files use the `toYaml` layout (`tools/dart_tools/lib/src/content/yaml_writer.dart`). The header comment says the draft was made in-session, not by a `tools/content/translate` API run.

## What was checked

1. **Meaning against en.** Every card field, spread text, article section and ARB value was re-read against the English source. Long texts keep the same paragraph count as en.
2. **Register.** The text uses warm, simple French with **vous**, following `worker/prompts/reading/v1/style.fr.md`, the glossary (`positions.you` = "Vous") and the 40 strings already in `app_fr.arb`. This differs from the Phase 18 brief, which asked for tu; see open question 1. The few earlier strings in tu (bootstrap error, reminder bodies) were moved to vous.
3. **Gender-neutral reader.** style.fr.md says no gendered adjectives and no inclusive marks for the reader. French agrees adjectives and some past participles with "vous", so the review rewrote every such phrase without the adjective. Examples: "prêt" → "le moment est venu" / "en mesure de"; "seul" → "sans aide" / "sans soutien"; "attiré" → "ce qui vous attire"; "vous êtes-vous engagé" → "quels sont vos engagements".
   - A lint flagged adjectives and participles near "vous" in all fr sources. About 60 phrases were rewritten across cards, spreads, articles and the ARB, including `crisisTitle` and the inclusive "ouvert·e" from the first draft.
   - "Renversé, la motivation vacille…" style openers (29) dangled onto the reader or a non-card subject. They now read "Carte renversée, …". Openers with the card as subject keep "Renversé, le Mat…" / "Renversée, la Lune…", agreeing with the card.
   - Other people: "un proche", "l’autre personne", "quelqu’un". Generic masculine "un ami", "un collègue", "un mentor" remains in about 35 places; see open question 4.
   - Card figures keep their grammatical gender (la Reine, le Cavalier, la figure) and are described as qualities.
4. **Glossary.** Every `name` equals `glossary.yaml` `cards.<id>.fr`; the emitter forces it. Running text adds the article: "le Mat", "la Grande Prêtresse", "l’As de Coupes", "le Valet d’Épées".
   - Suits: Bâtons, Coupes, Épées, Deniers.
   - Arcana: Arcanes majeurs, Arcanes mineurs.
   - Orientation: à l’endroit, renversé/renversée (agrees with the card).
   - Terms: reading = lecture, spread = tirage, daily card = carte du jour, journal = journal, court cards Valet/Cavalier/Reine/Roi.
   - Spread and position names in the ARB match `terms.spread_*` and `positions.*`.
5. **Banned claims.** No `common.global` or `locales.fr.global` term appears. The lint covered précis*, exact*, garanti*, voyant*/voyance, médium*, guérir/guérit, thérapie*, sort/sorts, envoûtement*.
   - Fixed in review: "exactement" (wands_07, cups_04), "précis" (wands_06, pentacles_11), "sort" (wands_11, "une pousse qui sort du bois").
   - The About/FAQ disclaimer uses the `tools/store_copy/required_sentences.yaml` fr sentence word for word ("Il ne lit pas l'avenir…").
6. **Reflection voice.** The text says "peut refléter", "vous invite à", "peut-être", "vous pourriez". It makes no predictions. "Future"/"outcome" is rendered as "la direction que les choses pourraient prendre si rien ne change".
7. **Machine limits.**
   - Keywords are at most 24 characters. 7 overruns were shortened in review.
   - Short texts are at most 160 characters. 7 overruns were shortened.
   - French word counts fall inside the ×0.7…×1.4 bounds; `tools/content/validate` reports no fr item.
   - Typography: curly apostrophe ’ as in the glossary, « » quotes, and a no-break space before ? ! : ; and inside « » in the ARB.
8. **ARB.**
   - Placeholders and ICU structure are identical to en. French `one` covers 0 and 1, so every `one{1 …}` branch of en became `one{{count} …}`. en `=0` branches are kept. `many` is not used.
   - Strings equal to en are allowlisted under `fr` in `tools/l10n_untranslated_allowlist.yaml`: `commonJournal`, `journalTitle` ("Journal") and `durationHoursMinutes` ("{hours} h {minutes} min").
   - Revised existing strings: "tirage par IA" / "tirage classique" → "lecture par IA" / "lecture classique" in the `failure*` and `safetyDeclined*` keys, per the glossary (reading = lecture, spread = tirage). `drawLeaveTitle` → "Quitter cette lecture ?".
   - `deleteConfirmWord` = "SUPPRIMER".

## Compliance strings (05 §3), kept to their exact meaning

- **`disclaimerShort` / `disclaimerOnboardingBody`.** These say "Pour le divertissement et la réflexion personnelle. Ne constitue pas un conseil professionnel." and "ne constituent pas un avis médical, juridique, financier ou psychologique".
- **`aiConsentBody`.**
  - It names OpenAI only ("les modèles GPT d’OpenAI"), with the 7-day and 90-day retention periods.
  - It says the data is not used for training.
  - It says readings "peuvent être erronées ou inattendues".
  - `privacyAiAllowedSubtitle` also names OpenAI.
- **`aiConsentAccept` / `aiConsentDecline`** ("Autoriser les lectures par IA" / "Pas maintenant"). Both are short and carry equal weight.
- **`crisisTitle`** = "Des personnes sont là pour vous". "Vous n’êtes pas seul" is gendered, and style.fr.md bans "seul·e". **`crisisBody`** and `safetyDeclined*` keep their meaning.
- **`reportReadingDisclosure`.** It says "envoyées à Taro et conservées 90 jours".
- **`storeConsumableDisclosure` and `restoreNothingFound`.** Both say the packs cannot be restored and are tied to the install.
- **`storeBestValue`** = "Meilleur rapport qualité-prix". This is the honest computed badge (04 MO18).
- **`nsUserTrackingUsageDescription`** = InfoPlist.strings. It makes the same promise: the app stays the same either way.

## Open questions for the native reviewer and the owner

1. **Register: tu or vous.** The Phase 18 brief asked for tu. style.fr.md (the AI readings), the glossary position "Vous" and the existing failure strings all use vous, so vous was used everywhere to keep the app and the AI readings consistent. If the owner wants tu, the ARB, cards, articles, style.fr.md and the glossary must all change together.
2. **About/FAQ provider names (source issue, not fr).** The en About and FAQ still say "Anthropic's Claude or OpenAI's GPT models", while `aiConsentBody` is OpenAI-only (RC97). The fr text follows en. Fix en first, then re-translate.
3. **FAQ settings paths (source issue).** En uses "Settings → Purchases", "Settings → Your data" and "Settings → Privacy → AI data sharing", but the UI sections are "Readings", "Privacy & data" and "Privacy choices". The fr text uses the real fr UI labels: "Réglages → Lectures", "Confidentialité et données", "Choix de confidentialité → Lectures par IA", "Aide → Lignes d’écoute", "Aide → Contacter l’assistance".
4. **Generic masculine for other people.** "un ami", "un collègue", "un mentor" remain in about 35 places as generic masculine nouns (not reader adjectives). A reviewer may prefer "une personne amie" or "une personne proche".
5. **"plutôt que" / "au lieu de".** style.fr.md (written for AI readings) asks to avoid them. The card prose uses about 70 where en has "rather than / instead of". They are not banned; a reviewer may thin them out.
6. **"Carte renversée, …" openers.** These avoid gender and dangling participles, but a native reviewer may prefer "À l’envers, …" or "Quand la carte est renversée, …".
7. **Valet / Deniers / Le Mat.** These follow the glossary (Le Mat is the traditional Marseille name with RWS names for the rest) and need native confirmation (glossary report).
8. **`commonAdLabel` = "Pub".** It is short for the banner marker. Confirm against store and AdMob wording ("Annonce" is the alternative).

## Items needing native review (launch gate, 01 §11 step 6)

- All 22 Major Arcana: every field.
- All 78 cards: `name`, `keywordsUpright/Reversed`, `shortUpright/Reversed`. The names are already locked by the glossary.
- At least 20% of the minor long texts (about 12 cards). Suggested sample: one Ace, one 5, one 10 and one court card per suit: wands_01, wands_05, wands_10, wands_13, cups_01, cups_05, cups_10, cups_12, swords_01, swords_03, swords_10, pentacles_13.
- The compliance strings above, plus `InfoPlist.strings` (Sprint 18.2, compliance review).
- The glossary `review.fr` must flip to `reviewed` first (step 2).
