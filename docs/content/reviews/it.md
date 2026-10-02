# Self-review: it (Italian)

This is the LLM self-review pass (01 Q5, Phase 18 Sprint 18.3) over the machine translation of `it`. Every file listed here is `reviewStatus: machine`. Nothing is `reviewed` until a native reviewer signs off (01 §11 step 6, launch gate).

## Scope

| Part | Files | Words (it) |
|---|---|---|
| UI strings | `apps/taro/lib/l10n/arb/app_it.arb`: 776 keys. 673 were `x-translate` placeholders. All are now translated and the markers are removed. | ~5,100 |
| iOS Info.plist | `apps/taro/ios/Runner/it.lproj/InfoPlist.strings` (`NSUserTrackingUsageDescription`) | 15 |
| Cards | `apps/taro/content/source/it/cards/*.yaml` (78/78) | ~68,800 (incl. YAML keys) |
| Spreads | `apps/taro/content/source/it/spreads.yaml` (6 `whenToUse`) | ~350 |
| Articles | `apps/taro/content/source/it/articles/{about,faq}.md` | ~2,900 |

There is no per-locale crisis description field. `crisis/crisis_resources.yaml` is a single file, and its `IT` entries carry their own names. The crisis UI copy lives in the ARB (`crisis*`, `safetyDeclined*`) and is covered by the UI strings row.

**Format.** Every content file carries the current en `sourceHash` and `reviewStatus: machine`. The files were emitted with `toYaml` (`tools/dart_tools/lib/src/content/yaml_writer.dart`) in the same layout that `tools/content translate` writes. The `name` field is forced to `glossary.yaml` `cards.<id>.it`. The header comment says the draft was made in-session, with no `tools/content/translate` API run.

## What was checked

1. **Meaning vs en.** I re-read every card field, spread text, article section and ARB value against the English source. Long texts keep the en paragraph structure.
2. **Register** (`worker/prompts/reading/v1/style.it.md`). The copy is warm, natural Italian with "tu". Other people are "l’altra persona", "una persona vicina", "entrambe le persone" or "un’amica o un amico". The suit is "il seme" and the layout is "la stesa". Card names use contracted articles ("del Carro", "il Fante di Coppe").
3. **Gender-neutral reader.** No adjective or participle agrees with the reader: no solo/sola, pronto/pronta, sicuro di sé, stanco, libero, disposto, visto, bloccato, orgoglioso, and no "o/a" doublets. These were rephrased with nouns, verbs or invariable forms ("senza nessuno accanto", "quando te la senti", "provare orgoglio", "a un passo dal limite", "in ascolto", "al sicuro"). Card figures keep their grammatical gender (la Regina, il Re, la figura).
4. **Glossary.** Card names equal `glossary.yaml` (`it`) exactly. The other terms used:
   - suits Bastoni, Coppe, Spade, Denari; Arcani maggiori and Arcani minori;
   - "diritta" and "rovesciata", agreeing with "la carta";
   - stesa, lettura, lettura classica, carta del giorno, Diario;
   - court cards Fante, Cavaliere, Regina, Re;
   - position names and spread names exactly as in `terms.spread_*`.
5. **Banned claims** (`banned_phrases.yaml`: `common.global` plus `locales.it.global`).
   - None of these appear: `accurat*`, `precis*`, `garantit*`, `veggente*`, `sensitiv*`, "predire il futuro", guarire, guarisce, `terapia*`, `incantesim*`, 100%.
   - The draft had two hits, fixed in this pass: "un conto preciso" became "il conto", and "accurato" became "curato".
   - Professional help is always "un professionista qualificato" and never a `terapi*` word.
   - Copy says "Taro non predice il futuro", which is not the banned phrase.
6. **Future and outcome framing.** These are always "dove le cose potrebbero andare se nulla cambia" or "un esito possibile", never fate or a time frame. "presto" and "succederà" do not appear.
7. **Compliance copy (05 §3).** Meaning is kept 1:1, with no softening and no additions, in:
   - `disclaimer*`;
   - `aiConsent*`: OpenAI only, 7 / 90 days, no training, "possono essere sbagliate o inattese";
   - `refusalGeneric`, `crisis*`, `reportReadingDisclosure`;
   - `storeConsumableDisclosure`, `restoreNothingFound`;
   - `att*` and `nsUserTrackingUsageDescription`.
8. **ICU and placeholders.** Placeholders are identical to en. Plurals use `one`/`other` (plus en's `=0`), which are valid CLDR categories for `it`. The `\n` structure of `helpEmailBody` is kept.
9. **Bounds.** `tools/content/validate` reports no `it` errors and no `[it]` report lines. That covers keywords of at most 24 characters, short texts of at most 160, questions of at most 120 ending in `?`, and word ranges of ×0.7 to ×1.4.

## Issues fixed during the pass

- **Gendered reader forms** in the first drafts were rewritten neutrally. Examples: "ti senti pronto", "sei stato preso", "sincero o sincera", "attratto", "disposto", "ti tiene stretto", "sentirti visto e sostenuto", "più vuoto dentro", "sei rimasto incastrato", "ti sei guadagnato", "restare calmi", "dell’essere giudicati", "sentirsi rispettato".
- **Banned stems**: "preciso istante" became "proprio in quel momento", "conto preciso" became "il conto", and "accurato" became "curato".
- **Keywords over 24 characters** were shortened, for example "guardare la tua ombra", "rispondere a un richiamo", "rivedere vecchie storie", "verità che affiorano" and "ansia che si allenta".
- **`crisisTitle`** ("You’re not alone"): "Non sei solo/sola" is gendered, so it became "Non devi affrontarlo senza nessuno accanto". The meaning is the same, the reader's gender is not assumed, and this follows the style file's "senza nessuno accanto".
- **`cardMeaningUpright` / `cardMeaningReversed`**: "Significato con la carta diritta/rovesciata", because "Significato diritto" reads oddly.
- **`helpEmail`**: "Email" equalled en, so it became "Indirizzo email".
- **Allowlist entries.** Identical-by-design values were added to `tools/l10n_untranslated_allowlist.yaml`:
  - `locales.it`: `commonPrivacy` ("Privacy" is the Italian UI word), `durationHoursMinutes`, `durationMinutes`;
  - global `keys`: `settingsVersion` ("Taro {version} ({build})", brand plus numbers).

## Open questions for the native reviewer

1. **Major Arcana names in the glossary.** La Papessa and Il Papa follow the Italian tradition; La Sacerdotessa and Lo Ierofante are the alternatives. For Il Mago the alternative is Il Bagatto. The Fool is Il Matto. Confirm before launch, because these names are in every card file and article.
2. **"Fante"** for Page. The traditional Italian rank is used throughout the cards, About and spreads.
3. **`storeBestValue`** is "Più conveniente". The literal "Miglior rapporto qualità-prezzo" is too long for the badge.
4. **`storeRemoveAdsTitle`** is "Rimuovi i banner pubblicitari". It has to match the IAP display name in App Store Connect and Play Console (RC80).
5. **`deleteConfirmWord`** is "ELIMINA", typed by the user and compared case-insensitively.
6. **`spread_single_name`** is "Una carta" (glossary `terms.spread_single`). "Carta singola" is an alternative.
7. **ATT strings** use "tracciamento", which matches Apple's Italian iOS UI ("Impostazioni → Privacy e sicurezza → Tracciamento"). Confirm the wording.
8. **Menu paths in the FAQ/About.** These mirror en: "Impostazioni → Acquisti", "Impostazioni → I tuoi dati", "Impostazioni → Privacy → Condivisione dei dati con l’IA", "Impostazioni → Aiuto → Risorse per le crisi". Not all of the en paths match the ARB labels (`settingsSectionPrivacyData` "Privacy e dati", `settingsSupportLines` "Linee di supporto"). Fix them in en first, then re-translate.
9. **Contrastive constructions.** Card texts use "invece di" about 12 times. `style.it.md` lists it under "Avoid" for AI readings. It is not banned in card content, but a reviewer may prefer lighter phrasing.
10. **Impersonal plurals.** A few generic plurals remain where no reader is meant, such as "parte dell’essere umani" and "restare vicini" (two people). Check that they read naturally.

## Upstream (en) inconsistency found

- `en/articles/about.md` and `en/articles/faq.md` still name "Anthropic's Claude or OpenAI's GPT models". `aiConsentBody` and `privacyAiAllowedSubtitle` (05 §3, RC97, `ai.consentVersion` 2) disclose OpenAI only.
- The `it` articles follow en faithfully (Claude di Anthropic o i modelli GPT di OpenAI), so they keep the en sourceHash.
- The owner should correct the en articles. That will mark the `it` articles stale, and they need a re-translation.

## Needs native review before release (launch gate, 01 §11 step 6)

- All 22 Major Arcana card files.
- Names, keywords, `shortUpright` and `shortReversed` of all 78 cards.
- A sample of at least 20% of the minor-card long texts.
- Every 05 §3 compliance key in `app_it.arb` and `it.lproj/InfoPlist.strings` (Phase 18 Sprint 18.2 MANUAL item).
- The `safetyDeclined*`, `refusalGeneric` and `crisis*` copy. The `failure*` and `safetyDeclined*` strings were translated earlier (Phase 13); they were re-read here and need no change.
- The `it` row of `glossary.yaml` (`review.it` is still `machine`).
- The `banned_phrases.yaml` `locales.it` table (Sprint 18.4).

## Not done here

- `ios/Runner.xcodeproj/project.pbxproj` is unchanged. `knownRegions` has only `en, Base`, and there is no `InfoPlist.strings` variant group yet. Xcode needs two changes, made as one shared edit for all locales:
  - add `it` to `knownRegions`;
  - add an `InfoPlist.strings` PBXVariantGroup with `it.lproj/InfoPlist.strings` in the Runner Resources build phase.
- `tools/content/build` was not run. It builds the deck assets and `deck_prompt.it.json` when the phase builds all locales.
