# Self-review: de (German, du-form)

This is the LLM self-review pass (01 Q5, Phase 18 Sprint 18.3) over the machine translation of `de`. Everything listed here is still `reviewStatus: machine`. Nothing counts as `reviewed` until a native reviewer signs it off (01 §11 step 6, launch gate).

## Scope

| Part | Files | Words (de) |
|---|---|---|
| UI strings | `apps/taro/lib/l10n/arb/app_de.arb`: 776 keys. The 673 `x-translate` placeholders are now translated and all markers are removed. | ~4,700 |
| iOS Info.plist | `apps/taro/ios/Runner/de.lproj/InfoPlist.strings` (`NSUserTrackingUsageDescription`) | 15 |
| Cards | `apps/taro/content/source/de/cards/*.yaml` (78 of 78) | ~67,600 |
| Spreads | `apps/taro/content/source/de/spreads.yaml` (the 6 `whenToUse` texts) | ~350 |
| Articles | `apps/taro/content/source/de/articles/{about,faq}.md` | ~2,700 |

Crisis resources have no per-locale description field, because `crisis/crisis_resources.yaml` is one shared file. The crisis UI copy lives in the ARB (`crisis*`, `safetyDeclined*`) and is covered above.

Format: every content file carries the current en `sourceHash` and `reviewStatus: machine`. Files use the YAML layout of `toYaml` (`tools/dart_tools/lib/src/content/yaml_writer.dart`). The header comment says the draft was made in-session, not by a `tools/content/translate` API run.

## What was checked

1. **Meaning against en.** Every card field, spread text, article section and ARB value was re-read against the English source. Long texts keep the same paragraph count as en.
2. **Register** (`worker/prompts/reading/v1/style.de.md`). The text uses warm, natural German with lower-case "du". Other people are named neutrally: "die andere Person", "ein naher Mensch", "jemand".
3. **Gender-neutral reader.** Reader nouns are doublets or neutral wording: "Anfängerin oder Anfänger", "lernend sein", "eine Fachperson". Card figures keep their grammatical gender (die Königin, der Ritter, die Gestalt) and are described as qualities.
   - Fixed in review: 6 reflection questions that used a generic "er/ihn/ihm" for another person (major_21, swords_03, swords_08, swords_10, swords_12, wands_11).
   - Fixed in review: 5 generic "einem Freund" phrasings (cups_02, cups_11, cups_12, cups_13, pentacles_06).
4. **Glossary.** Every `name` equals `glossary.yaml` `cards.<id>.de`; the emitter forces it. Running text inflects the names and writes the article in lower case ("der Narr", "die Zwei der Schwerter", "das Ass der Münzen").
   - Suits: Stäbe, Kelche, Schwerter, Münzen.
   - Arcana: Große Arkana, Kleine Arkana.
   - Orientation: aufrecht, umgekehrt.
   - Terms: reading = Deutung, spread = Legung, journal = Journal, daily card = Tageskarte, court cards Bube/Ritter/Königin/König.
   - Spread and position names in the ARB match `terms.spread_*` and `positions.*`.
5. **Banned claims.** No `common.global` or `locales.de.global` term appears. The words on the style.de.md list are also absent: genau/genauer, garantiert, Hellseher, Medium, heilen/Heilung, Therapie, Zauber… A lint for these ran over all de sources.
   - Fixed in review: 4 hits of "genau" (wands_05, cups_11, pentacles_04, pentacles_13), 2 of "genauer" (major_02, cups_07) and 1 "genauso" in the ARB.
   - "Magical" in the Moon card was translated as "geheimnisvoller", because "zauberhaft" is banned.
6. **Reflection voice.** The text says "kann spiegeln", "lädt dich ein", "vielleicht", "du könntest". It makes no predictions and no "wird passieren". "Future"/"outcome" is rendered as "wohin es gehen könnte, wenn sich nichts ändert".
7. **Machine limits.**
   - Keywords are at most 24 characters. 14 overruns were shortened in review.
   - Short texts are at most 160 characters. One overrun was fixed (pentacles_09).
   - Questions are at most 120 characters. One overrun was fixed (cups_07).
   - German word counts fall inside the ×0.7…×1.4 bounds.
8. **ARB.**
   - Placeholders and ICU structure are identical to en. Plurals use the CLDR categories `one`/`other`, and en `=0` branches are kept.
   - Strings that equal en are allowlisted in `tools/l10n_untranslated_allowlist.yaml` under `de`: `cardElementValue`, `tabJournal`, `commonJournal`, `journalTitle`, `privacyTracking`.
   - `tabJournal` was "Tagebuch" and is now "Journal", per the glossary.

## Compliance strings (05 §3), kept to their exact meaning

- **`disclaimerShort` / `disclaimerOnboardingBody`.** The text says "Zur Unterhaltung und Selbstreflexion. Keine professionelle Beratung." and "keine medizinische, rechtliche, finanzielle oder psychologische Beratung".
- **About/FAQ disclaimer.** It uses the `required_sentences.yaml` de sentence word for word.
- **`aiConsentBody`.**
  - It names OpenAI only, with the 7-day and 90-day retention periods.
  - It says the data is not used for training.
  - It says the reading "kann falsch oder unerwartet sein".
  - `privacyAiAllowedSubtitle` also names OpenAI.
- **`aiConsentAccept` / `aiConsentDecline`** ("KI-Deutungen erlauben" / "Jetzt nicht"). Both are short and carry equal weight.
- **`crisisTitle` / `crisisBody` and `safetyDeclined*`.** These are unchanged in meaning.
- **`reportReadingDisclosure`.** It says "an Taro gesendet und 90 Tage lang aufbewahrt".
- **`storeConsumableDisclosure` and `restoreNothingFound`.** Both say the packs cannot be restored and are tied to the install.
- **`storeBestValue`** = "Bester Preis pro Deutung". This keeps it an honest, computed badge (04 MO18) and avoids a bare "Bester".
- **`nsUserTrackingUsageDescription`** = InfoPlist.strings. It makes the same promise: the app stays the same either way.

## Open questions for the native reviewer and the owner

1. **About/FAQ provider names (source issue, not de).** The en About and FAQ still say "Anthropic's Claude or OpenAI's GPT models", while `aiConsentBody` is OpenAI-only (2026-10-01). The de text follows en. Fix en first, then re-translate.
2. **FAQ settings paths (source issue).** En uses "Settings → Purchases", "Settings → Your data" and "Settings → Privacy → AI data sharing", but the UI sections are "Readings", "Privacy & data" and "Privacy choices". The de text translates en literally ("Einstellungen → Käufe", "Deine Daten", "Datenschutz → Datenweitergabe für KI"). The crisis path is mapped to the real label "Hilfe → Hilfetelefone".
3. **"Deutung" for both the reading and the credit unit.** The glossary says reading = Deutung, so balances read "3 Deutungen" and "Mehr Deutungen holen". The 14.1 sample used "Legung", which is spread in the glossary. Please confirm.
4. **Rad des Schicksals.** The glossary name contains "Schicksal", while the voice avoids fate. The name is kept and the text says no fate is implied. A reviewer could consider "Das Glücksrad", which is a glossary change.
5. **Bube vs. Page; Münzen vs. Pentakel.** These follow the glossary and need native confirmation (glossary report).
6. **Contrast words.** style.de.md (written for AI readings) asks to avoid "statt", "sondern" and "eher … als". The card prose uses about 80 of these across 78 cards where the en has "rather than / not … but". A reviewer may want to thin them out; they are not banned.
7. **`storeBestValue` length.** "Bester Preis pro Deutung" (24 characters) may be long for the badge. A shorter honest option is "Günstigster Preis".
8. **`deleteConfirmWord` = "LÖSCHEN".** Confirm that the case-insensitive compare handles "ö" and "Ö".
9. **`durationHoursMinutes` and `durationMinutes`.** These use "Std."/"Min.". Check that this matches the `intl` formatting used elsewhere.

## Items needing native review (launch gate, 01 §11 step 6)

- All 22 Major Arcana: every field.
- All 78 cards: `name`, `keywordsUpright/Reversed`, `shortUpright/Reversed`. The names are already locked by the glossary.
- At least 20% of the minor long texts (about 12 cards). Suggested sample: one Ace, one 5, one 10 and one court card per suit, for example wands_01, cups_05, swords_10, pentacles_13, and so on.
- The compliance strings above, plus `InfoPlist.strings` (Sprint 18.2, compliance review).
- The glossary `review.de` must flip to `reviewed` first (step 2).
