# Self-review: es (Spanish, neutral international)

LLM self-review pass (01 Q5, Phase 18 Sprint 18.3) over the machine translation of
`es`. Everything listed here is `reviewStatus: machine`; nothing is `reviewed` until
a native reviewer signs off (01 §11 step 6, launch gate).

## Scope

| Part | Files | Words (es) |
|---|---|---|
| UI strings | `apps/taro/lib/l10n/arb/app_es.arb` (776 keys; 673 were `x-translate` placeholders, now translated; markers removed) | ~5,100 |
| iOS Info.plist | `apps/taro/ios/Runner/es.lproj/InfoPlist.strings` (`NSUserTrackingUsageDescription`) | 15 |
| Cards | `apps/taro/content/source/es/cards/*.yaml` (78/78) | ~64,000 |
| Spreads | `apps/taro/content/source/es/spreads.yaml` (6 `whenToUse`) | ~320 |
| Articles | `apps/taro/content/source/es/articles/{about,faq}.md` | ~2,900 |

Crisis resources have no per-locale description field (`crisis/crisis_resources.yaml`
is one file; `ES` entry name is already Spanish). The crisis UI copy lives in ARB
(`crisis*`, `safetyDeclined*`) and is covered above.

Format: every content file carries the current en `sourceHash` and
`reviewStatus: machine`, emitted with the same YAML layout as `toYaml`
(`tools/dart_tools/lib/src/content/yaml_writer.dart`). The header comment states the
draft was made in-session (no `tools/content/translate` API run).

## What was checked

1. **Meaning vs en**: every card field, spread text, article section and ARB value
   re-read against the English source. Long texts kept their paragraph structure
   (same paragraph count as en).
2. **Register** (`worker/prompts/reading/v1/style.es.md`): warm, neutral Spanish with
   "tú"; no `vosotros` forms; other people as "la otra persona", "alguien cercano",
   "ambas personas".
3. **Gender-neutral reader**: no adjectives that agree with the reader (no
   solo/a, listo/a, preparado/a, seguro/a, visto/a, doublets). Rephrased with nouns
   or verbs ("sin compañía", "con calma", "sentir seguridad", "te sientes con ánimo
   de"). Card figures keep their grammatical gender (la Reina, el Caballero, la
   figura).
4. **Glossary**: every `name` equals `glossary.yaml` `cards.<id>.es` (forced by the
   emitter); suits Bastos/Copas/Espadas/Oros; Arcanos mayores/menores; "al derecho",
   "invertido/invertida" agreeing with the card; "tirada", "lectura", "lectura
   clásica", "carta del día", "Diario", position names as in the glossary.
5. **Banned claims** (`banned_phrases.yaml` `common.global` + `locales.es.global`):
   none of `precis*`, `exact*`, `garantiza*`, `vidente*`, `psíquic*`,
   "predecir el futuro", `curar`, `terapia*`, `hechizo*`, `amarre*`, `100%`.
   "It does not predict the future" is rendered as "No hace predicciones" / "Taro no
   predice el futuro" (never the banned phrase). Also avoided the style file's
   "las cartas muestran que", "va a pasar", "pronto".
6. **Future/outcome framing** (STYLE_GUIDE §5): "hacia dónde pueden ir las cosas si
   nada cambia", never fate, no time frames.
7. **Compliance copy (05 §3)**: `disclaimer*`, `aiConsent*` (OpenAI only, retention
   7 days / 90 days, no training, "pueden ser erróneas o inesperadas"),
   `refusalGeneric`, `crisis*`, `reportReadingDisclosure`, `storeConsumableDisclosure`,
   `restoreNothingFound`, `att*`, `nsUserTrackingUsageDescription`: meaning kept
   1:1, no softening or additions.
8. **ICU / placeholders**: placeholders identical to en; plurals use `one`/`other`
   (plus en's `=0`), valid CLDR categories for es; `\n` structure of
   `helpEmailBody` kept.
9. **Bounds**: `tools/content/validate` (keywords ≤ 24 chars, shorts ≤ 160,
   questions ≤ 120, word ranges ×0.7–×1.4) passes with no `es` errors.

## Issues fixed during the pass

- Gendered reader forms in the first drafts (e.g. "te sientes visto", "estás
  dispuesto", "quedarte quieto", "te mantienen ocupado", "sentirte preparado",
  "inexperto", "estancado", "valorado", "orgulloso") rewritten neutrally.
- `vosotros` forms ("os une", "compartís", "podáis", "vuestra", "aprendéis",
  "comunicáis") replaced with "ustedes"/third-person forms.
- One draft used "exactamente" (banned stem `exact*`): replaced with "en concreto".
- Keywords over 24 characters shortened (e.g. "un salto a lo desconocido",
  "cuestionar lo establecido", "sensación de estancamiento").
- Existing ARB strings: `safetyDeclinedHarmToOthers` "estáis" → "están";
  `failureRewardUnavailable` "vídeo" → "video" (consistent with new strings).
- `crisisTitle` ("You're not alone"): "No estás solo/a" is gendered; used
  "No tienes que pasar por esto sin compañía".
- `questionIdeas`: "Ideas" equalled en; changed to "Sugerencias" (matches
  `questionSuggestionSemantics`). `durationHoursMinutes` / `durationMinutes` are
  identical to en by design and were added to `tools/l10n_untranslated_allowlist.yaml`
  (`locales.es`), as already done for fr/it.

## Open questions for the native reviewer

1. **Neutral vs Spain Spanish**: strings use "Ajustes" (iOS Spain label; LatAm iOS
   uses "Configuración"), "app", "video", "móvil" avoided in favor of "teléfono".
   Confirm the target variant.
2. **"Denunciar"** for Report (`reportReadingTitle`, `readingReported`): alternatives
   "Reportar" (LatAm) or "Informar de". Pick one for all report strings.
3. **"Rastreo"** for Tracking (ATT): matches Apple's Spanish UI; confirm.
4. **`crisisTitle`** phrasing (see above) and `crisisBody` tone.
5. **`storeBestValue`** "Mejor relación calidad-precio" may be long for the badge;
   "Mejor precio" is shorter.
6. **Court card "Sota"**: glossary term; FAQ/About use it consistently. Confirm
   against the reviewer's preferred deck tradition.
7. **`spread_single_meta`** "una pregunta clara" (en "one clear prompt"); "un
   enfoque claro" is an alternative.
8. **Menu paths in the FAQ/About** mirror en ("Ajustes → Compras", "Ajustes → Tus
   datos", "Ajustes → Privacidad → Envío de datos a la IA"). The en paths do not all
   match the ARB section names (`settingsSectionPrivacyData` = "Privacidad y
   datos"); fix in en first, then re-translate.

## Upstream (en) inconsistency found

- `en/articles/about.md` and `en/articles/faq.md` still name "Anthropic's Claude or
  OpenAI's GPT models", while `aiConsentBody` / `privacyAiAllowedSubtitle` (05 §3,
  RC97) disclose OpenAI only. The es translation follows en faithfully; the en
  articles should be corrected (owner), which will make the es articles stale and
  require a re-translation.

## Needs native review before release (launch gate, 01 §11 step 6)

- All 22 Major Arcana card files, and names / keywords / `shortUpright` /
  `shortReversed` of all 78 cards.
- Every 05 §3 compliance key in `app_es.arb` and `es.lproj/InfoPlist.strings`
  (Phase 18 Sprint 18.2 MANUAL item).
- `safetyDeclined*`, `refusalGeneric`, `crisis*` copy.
- The `es` row of `glossary.yaml` (`review.es` is still `machine`).
- `banned_phrases.yaml` `locales.es` table (Sprint 18.4).

## Not done here

- `ios/Runner.xcodeproj/project.pbxproj` is unchanged: `knownRegions` has only
  `en, Base`, and no `InfoPlist.strings` variant group exists yet. Xcode needs
  `es` in `knownRegions` and an `InfoPlist.strings` variant group with the
  `es.lproj` file in the Runner Resources build phase (one shared edit for all
  locales).
- `tools/content/build` was not run (deck assets for `es` are built once the
  locale is reviewed / the phase builds all locales).
