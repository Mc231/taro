# Self-review: nl (Dutch, je-form)

This is the LLM self-review pass (01 Q5, Phase 18 Sprint 18.3) over the machine translation of `nl`. Everything listed here is still `reviewStatus: machine`. Nothing counts as `reviewed` until a native reviewer signs it off (01 §11 step 6, launch gate).

## Scope

| Part | Files | Words (nl) |
|---|---|---|
| UI strings | `apps/taro/lib/l10n/arb/app_nl.arb`: 776 keys. The 673 `x-translate` placeholders are translated and all markers are removed. | ~4,800 |
| iOS Info.plist | `apps/taro/ios/Runner/nl.lproj/InfoPlist.strings` (`NSUserTrackingUsageDescription`) | 15 |
| Cards | `apps/taro/content/source/nl/cards/*.yaml` (78 of 78) | ~68,000 |
| Spreads | `apps/taro/content/source/nl/spreads.yaml` (the 6 `whenToUse` texts) | ~370 |
| Articles | `apps/taro/content/source/nl/articles/{about,faq}.md` | ~2,800 |

Crisis resources have no per-locale description field: `crisis/crisis_resources.yaml` is one shared file. The crisis UI copy lives in the ARB (`crisis*`, `safetyDeclined*`) and is covered above.

Format: the content files were written through the real `tools/content translate` code path (`runContentTranslate` with a file-backed `ClaudeClient`, no network), so the YAML layout, the forced glossary `name`, the en `sourceHash` and `reviewStatus: machine` are exactly what the tool emits. The header comment says the draft was made in-session (claude-opus-5-5), not by an API run.

## What was checked

1. **Meaning against en.** Every card field, spread text, article section and ARB value was re-read against the English source. Long texts keep the en paragraph count.
2. **Register** (`worker/prompts/reading/v1/style.nl.md`). Warm, direct Dutch with "je"/"jij". Other people are neutral: "de ander", "iemand die dicht bij je staat", "een vriend", "die persoon". No anglicisms in running text except established UI words (see open question 5).
3. **Gender-neutral reader and others.** Cards are referred to as "de kaart … ze"; figures as "deze figuur … die". Court titles keep their grammatical gender (de Koningin … haar).
   - Fixed in review: `swords_05` ("met de rug naar hem toe", a generic "he") and `pentacles_09` ("op haar gemak" for "de figuur"). Early drafts of `major_00` used "ze" for the Fool; changed to "de kaart".
   - Remaining "hij/hem" refer only to objects (wens, cyclus, regel, regen, aanpak).
4. **Glossary.** Every `name` equals `glossary.yaml` `cards.<id>.nl` (forced by the emitter). Running text uses lower-case articles ("de Dwaas", "de Zes van Staven", "het Rad van Fortuin"); Gerechtigheid, Kracht and Gematigdheid have no article.
   - Suits: Staven, Kelken, Zwaarden, Pentakels. Arcana: Grote Arcana, Kleine Arcana. Orientation: rechtop, omgekeerd.
   - Terms: reading = lezing, spread = legging, journal = dagboek, daily card = dagkaart, keywords = trefwoorden, court ranks Schildknaap/Ridder/Koningin/Koning.
   - ARB spread names equal `terms.spread_*` ("Eén kaart", "Verleden, heden, toekomst", "Situatie, actie, uitkomst", "Relatie", "Twee paden", "Keltisch kruis"); position names were already glossary values.
5. **Banned claims.** No `common.global` or `locales.nl.global` term appears (`check_store_copy.py` and `tools/content/validate` are green). The style.nl.md rejected stems (nauwkeurig, accura, garantie, helderziend, therapie, betover, paranormaal, genezen) are absent.
   - Fixed in review: one "nauwkeurig bij te houden" (`pentacles_04`), now "precies".
   - "Magical" (the Moon) is "magisch", because "betoverend" is banned. "Heal" is never rendered as "genezen"; "herstellen" is used.
6. **Reflection voice.** "kan … weerspiegelen", "nodigt je uit", "misschien", "je kunt". No predictions; "future"/"outcome" is "waar het naartoe kan gaan als er niets verandert". Death, the Tower, the Devil and the Ten/Nine/Three of Swords keep the en framing (no physical death, no catastrophe, no evil).
7. **Machine limits.** Keywords ≤ 24 characters (15 overruns shortened in review), short texts ≤ 160 (1 overrun fixed, `pentacles_09`), questions ≤ 120 and ending in "?", word counts inside ×0.7…×1.4.
8. **ARB.**
   - Placeholders and ICU structure are identical to en; plurals use the nl CLDR categories `one`/`other`, and en `=0` branches are kept. `flutter gen-l10n` compiles `app_nl.arb` without warnings.
   - Strings equal to en are allowlisted in `tools/l10n_untranslated_allowlist.yaml` under `nl`: `cardElementValue`, `durationMinutes`, `commonPrivacy`, `legalDisclaimer`, `privacyTracking` (plus the existing `spread_single_pos_focus_name`, `cardElementLabel`, `elementWater`). `homeRecent` ("Onlangs") and `journalFilterMore` ("Filteren") were reworded instead.

## Compliance strings (05 §3), kept to their exact meaning

- **`disclaimerShort` / `disclaimerOnboardingBody` / article disclaimers.** "Voor entertainment en zelfreflectie. Geen professioneel advies." and "geen medisch, juridisch, financieel of psychologisch advies". The About and FAQ disclaimer uses the `required_sentences.yaml` nl sentence word for word, and the ARB uses the same word "entertainment".
- **`aiConsentBody`.** Names OpenAI only (GPT-modellen van OpenAI), the 7-day and 90-day retention, no training use, and "kunnen onjuist of onverwacht zijn". `privacyAiAllowedSubtitle` also names OpenAI only.
- **`aiConsentAccept` / `aiConsentDecline`** ("AI-lezingen toestaan" / "Niet nu"): short, equal weight, no confirmshaming.
- **`crisisTitle` / `crisisBody` / `crisisEmergency`.** "Je staat er niet alleen voor"; "Denk je erover om jezelf iets aan te doen? Neem dan nu contact op met iemand. Erover praten kan helpen."; "Ben je in direct gevaar? Bel {number}". `safetyDeclined*` were already translated and unchanged.
- **`reportReadingDisclosure`.** "naar Taro gestuurd en 90 dagen bewaard".
- **`storeConsumableDisclosure` / `restoreNothingFound`.** Both say packs cannot be restored and belong to this installation.
- **`storeBestValue`** = "Voordeligst" (an honest computed badge, no "beste").
- **`nsUserTrackingUsageDescription`** = InfoPlist.strings: "Sta tracking toe om relevantere advertenties te zien. Je krijgt hoe dan ook dezelfde app."
- **Platform names.** `updateCaptionIos` names only the App Store and `updateCaptionAndroid` only Google Play, as in en.

## Open questions for the native reviewer and the owner

1. **About/FAQ provider names (source issue, not nl).** The en About and FAQ still say "Anthropic's Claude or OpenAI's GPT models", while `aiConsentBody` is OpenAI-only (2026-10-01). The nl text follows en so the `sourceHash` stays honest. Fix en first, then re-translate (nl will report stale).
2. **FAQ settings paths (source issue).** En uses "Settings → Purchases", "Settings → Your data", "Settings → Privacy → AI data sharing", which do not match the UI sections. nl translates en literally ("Instellingen → Aankopen", "Je gegevens", "Privacy → Gegevens delen met AI"); the crisis path is mapped to the real label "Instellingen → Hulp → Hulplijnen".
3. **Crisis entry name.** `crisis_resources.yaml` NL has "113 Zelfmoordpreventie (short number)" with an English suffix shown to Dutch users. Suggest "(kort nummer)" in the shared file during the 18.4 verification pass.
4. **"lezing" for both the reading and the credit unit.** Balances read "3 lezingen", "Meer lezingen". Per glossary; confirm this reads naturally for a purchasable unit.
5. **Loanwords kept in UI:** "AI", "support"/"support-ID", "tracking", "disclaimer", "back-up", "deck", "pitch", "flow", "multitasken", "brainstormen". style.nl.md asks for no anglicisms; most are standard Dutch UI terms, but a reviewer may prefer "ondersteuning", "klantenservice" or "kaartspel".
6. **Contrast constructions.** style.nl.md (written for AI readings) avoids "in plaats van" and "niet … maar". The card prose was drafted to avoid them; 12 "in plaats van" remain across cards/articles where en has "rather than / instead of". Not banned; thin out if desired.
7. **"Schildknaap" for Page and "Zegewagen" for the Chariot** follow the glossary; native confirmation pending (glossary report). "kleur" is used for suit in running text.
8. **`deleteConfirmWord` = "VERWIJDER".** Confirm the confirm-field compare uses the localized word.
9. **`durationHoursMinutes` = "{hours} u {minutes} min".** Check against the `intl` duration format used elsewhere.
10. **`readingContentLocaleNote` = "Geschreven in het {language}".** Correct for a Dutch language name ("in het Engels"); check what `{language}` is filled with.

## Items needing native review (launch gate, 01 §11 step 6)

- All 22 Major Arcana: every field.
- All 78 cards: `name`, `keywordsUpright/Reversed`, `shortUpright/Reversed` (names already glossary-locked).
- At least 20% of the minor long texts (≥ 12 cards). Suggested sample: an Ace, a 5, a 10 and a court card per suit, for example `wands_01`, `wands_05`, `wands_13`, `cups_05`, `cups_10`, `cups_13`, `swords_03`, `swords_09`, `swords_10`, `pentacles_04`, `pentacles_05`, `pentacles_13`.
- The compliance strings above, plus `nl.lproj/InfoPlist.strings` (Sprint 18.2 compliance review).
- `glossary.yaml` `review.nl` must flip to `reviewed` first (step 2).
