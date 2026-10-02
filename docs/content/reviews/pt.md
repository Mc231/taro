# Self-review: pt (Brazilian Portuguese, pt-BR tone)

LLM self-review pass (01 Q5, Phase 18 Sprint 18.3) over the machine translation of
`pt`. Everything listed here is `reviewStatus: machine`; nothing is `reviewed` until
a native reviewer signs off (01 §11 step 6, launch gate). Date: 2026-10-02.

## Scope

| Part | Files | Words (pt) |
|---|---|---|
| UI strings | `apps/taro/lib/l10n/arb/app_pt.arb` (776 keys; 673 were `x-translate` placeholders, now translated; markers removed; no `@` metadata, same as the other non-en ARBs) | ~5,100 |
| iOS Info.plist | `apps/taro/ios/Runner/pt.lproj/InfoPlist.strings` (`NSUserTrackingUsageDescription`) | 16 |
| Cards | `apps/taro/content/source/pt/cards/*.yaml` (78/78) | ~69,000 |
| Spreads | `apps/taro/content/source/pt/spreads.yaml` (6 `whenToUse`) | ~370 |
| Articles | `apps/taro/content/source/pt/articles/{about,faq}.md` | ~3,000 |

Crisis resources have no per-locale description field (`crisis/crisis_resources.yaml`
is one file for all locales; the `BR` and `PT` entry names are already Portuguese). The
crisis UI copy lives in the ARB (`crisis*`, `safetyDeclined*`) and is covered above.

Format: every content file carries the current en `sourceHash` (from
`tools/content/validate --print-hashes`) and `reviewStatus: machine`, emitted with the
same YAML layout as `toYaml` (`tools/dart_tools/lib/src/content/yaml_writer.dart`). The
header comment says the draft was made in-session (no `tools/content/translate` API run).
Card `name` is the glossary name.

## What was checked

1. **Meaning against en**: every card field, spread text, article section and ARB value
   was re-read against the English source. Long texts keep the en paragraph structure.
2. **Register** (`worker/prompts/reading/v1/style.pt.md`): warm Brazilian Portuguese with
   "você". Other people are "a outra pessoa", "alguém próximo", "uma pessoa amiga" or
   "as duas pessoas". There are no Portugal-only forms ("tu", "telemóvel", "ecrã").
3. **Gender-neutral reader**: no adjective agrees with the reader. Rewrites use nouns or
   verbs: "sem companhia", "por conta própria", "estar em condições de", "sentir
   segurança", "a sensação de invisibilidade". Words that agree with a noun ("a mente
   preocupada", "a força de vontade sozinha") were kept. Card figures keep their
   grammatical gender (o Valete, a Rainha, a figura).
4. **Glossary** (`glossary.yaml` pt):
   - Every card `name` equals the glossary entry (the emitter enforces this).
   - Suits are Paus, Copas, Espadas and Ouros; the arcana are Arcanos Maiores and Arcanos Menores.
   - The spread is "tiragem". Other terms: "leitura", "leitura clássica", "carta do dia", "Diário".
   - Position names are as in the glossary.
   - ARB `spread_*_name` values equal `terms.spread_*`, and `spread_*_pos_*_name` values equal `positions.*`.
   - Orientation follows `style.pt.md`. An upright card is left unmarked in running text. A reversed card is "invertido/invertida", agreeing with the card: "Invertido, o Louco…", "Invertida, a Torre…". The UI labels keep the glossary's "Normal" and "Invertida".
5. **Banned claims** (`banned_phrases.yaml` `common.global` + `locales.pt.global`): none of
   `precis*`, `exat*`, `garanti*`, `vidente*`, `médium*`, "prever o futuro", `curar`,
   `terapia*`, `feitiç*`, `amarraç*` or `100%`. `tools/store_copy/check_store_copy.py`
   reports no pt finding. The Worker style's avoid list was also followed: "em vez de" is
   replaced by "no lugar de", and there is no "vai acontecer", "em breve" or "as cartas
   mostram que" about the reader.
6. **Future and outcome framing** (STYLE_GUIDE §5): "para onde as coisas podem estar
   indo se nada mudar". There is never a fate claim and never a time frame.
7. **Compliance copy (05 §3)** was compared line by line, and the meaning is kept 1:1 with
   nothing softened or added. Keys checked:
   - `disclaimerShort`, `disclaimerOnboardingBody`, `legalDisclaimerBody`
   - `aiConsent*`: OpenAI only, 7 days, 90 days, no training, "podem conter erros ou ser inesperadas"
   - `aiLabel`, `refusalGeneric`, `crisisTitle` / `crisisBody`, `reportReading*`
   - `questionCharge*`, `storeConsumableDisclosure`, `restoreNothingFound`, `storeRemoveAds*`
   - `rewardedOfferTitle`, which still says it is an ad
   - `att*` and `nsUserTrackingUsageDescription`, which stay neutral with no incentive
8. **ICU and placeholders**: placeholders are identical to en, and every plural or select
   structure is kept. Plurals use `one`/`other` plus en's `=0`. CLDR `pt` puts 0 in the
   `one` category, so `one{}` branches use the placeholder rather than a literal "1":
   `{count} leitura`, `+{count} leitura`, `{count} registro deste celular será removido`.
   That way a 0 never renders as "1". The `\n` lines of `helpEmailBody` are kept.
9. **Bounds**: `tools/content/validate --strict-locales` reports no `pt` error or stale
   item. That covers keywords up to 24 characters, short texts up to 160, questions up
   to 120, and word ranges of ×0.7 to ×1.4.

## Issues fixed during the pass

- **Gendered reader forms** from the first drafts were rewritten. The forms were:
  - "parecer bobo", "ficar parado", "se sente realmente visto", "honesto consigo"
  - "disposto a se comprometer", "puxado em duas direções", "ocupado", "atento"
  - "se sentir vivo", "cansado de", "não é valorizado", "seguro de si"
  - "ansioso para testar", "preso a um papel", "encaixotado", "comprometido"
  - "ser bom logo de cara", "deixado de fora"
  - The keyword "preso ao passado", now "apego ao passado"
- **Banned stems** slipped into drafts and were replaced:
  - "exatamente" (three times) became "justamente" or "de fato".
  - Forms of "precisar" (about 15) became "pedir", "sentir falta", "ser útil", "ter de" or "procurar".
  - The ARB "precisam da sua permissão" became "dependem da sua permissão" (`aiConsentReentryTitle`, About).
  - About: "não precisa de conexão" became "funciona sem conexão".
- **"Reversed, you…"** openers had first been rendered as "Invertido, você…". In pt that
  reads as if the reader were reversed. All 43 are now "Com a carta invertida, …".
- **Existing ARB strings** that were already translated gave the reader a gender ("sobre si
  mesmo", "cuidar de si mesmo"). They were rewritten in `safetyDeclinedHealth`,
  `safetyDeclinedPregnancy` and `safetyDeclinedLegal` as "o que esta situação pode
  revelar sobre você" and "cuidar de você".
- **Gendered first person in the UI**:
  - `drawShuffleReady` "Estou pronto" became "Tudo certo — tirar".
  - `readingRatingThanks` and `reportSubmitted` "Obrigado" became "Agradecemos".
  - `dailyReminderOfferNo` "Não, obrigado" became "Prefiro não".
- **Keywords over 24 characters** were shortened: "fugir do próprio papel", "reaproximação",
  "medos noturnos".
- **Other fixes**: `pentacles_14` `shortUpright` was cut to 160 characters or fewer. In
  `durationHoursMinutes`, "{hours} h e {minutes} min" makes it differ from en, so no
  allowlist entry is needed.

## Open questions for the native reviewer

1. **"Normal" for upright** (glossary `terms.upright`, `commonUpright`,
   `cardMeaningUpright` "Significado normal"). Brazilian tarot texts also use "Direita"
   or "Na posição normal". `style.pt.md` says to leave upright unmarked in prose, which
   the cards do.
2. **"Denunciar"** for Report (`reportReadingTitle`, `readingReported`, `screenReport`).
   "Reportar" is common in Brazilian apps and sounds less severe. Pick one wording for
   all report strings.
3. **`crisisTitle`** is "Você não está só". "Só" has no gender form, but please confirm
   the tone, and also the tone of `crisisBody`: "procure ajuda agora".
4. **`storeBestValue`** "Melhor custo-benefício" may be long for the badge. "Mais vantajoso"
   is an alternative.
5. **`settingsHaptics`** "Vibração ao toque": iOS pt-BR uses "Tátil". Match the platform
   label?
6. **"Ajustes"** is the iOS pt-BR label. Android uses "Configurações". The same ARB serves
   both platforms.
7. **`spread_single_meta`** is "um ponto claro de reflexão" (en "one clear prompt").
8. **`journalPatternsMajorMinor`** reads "Maiores {major} · Menores {minor}" for the arcana
   counts. Confirm that it is clear without "Arcanos".
9. **Menu paths in the FAQ and About** follow en, with the pt labels where they exist:
   "Ajustes → Compras", "Ajustes → Seus dados", "Ajustes → Privacidade → Compartilhamento
   de dados com a IA". Several en paths do not match the ARB section names: the ARB has
   "Privacidade e dados", and the en "Crisis resources" path was rendered "Ajuda → Linhas
   de apoio" (`settingsSupportLines`). Fix the paths in en first, then re-translate.
10. **"Valete"** is the glossary court card (an alternative is "Pajem"). "Ouros" was kept
    for Pentacles; "Pentáculos" is the other common choice.

## Upstream (en) inconsistency found

- `en/articles/about.md` and `en/articles/faq.md` still name "Anthropic's Claude or
  OpenAI's GPT models" ("o Claude, da Anthropic, ou os modelos GPT, da OpenAI"). But
  `aiConsentBody` and `privacyAiAllowedSubtitle` (05 §3, RC97) disclose OpenAI only. The
  pt articles follow en faithfully. The owner should correct the en articles, which will
  make the pt articles stale and need a re-translation.

## Needs native review before release (launch gate, 01 §11 step 6)

- All 22 Major Arcana card files.
- The name, keywords, `shortUpright` and `shortReversed` of all 78 cards.
- At least 20% of the Minor Arcana long texts, as a sample.
- Every 05 §3 compliance key in `app_pt.arb` and `pt.lproj/InfoPlist.strings` (Sprint 18.2
  MANUAL item).
- The `safetyDeclined*`, `refusalGeneric` and `crisis*` copy.
- The `pt` entries of `glossary.yaml` (`review.pt` is still `machine`).
- The `banned_phrases.yaml` `locales.pt` table (Sprint 18.4).

## Not done here

- `ios/Runner.xcodeproj/project.pbxproj` is unchanged. Its `knownRegions` lists only
  `en, Base`, and no `InfoPlist.strings` variant group exists. Xcode needs `pt` added to
  `knownRegions`, and an `InfoPlist.strings` variant group that holds `pt.lproj` in the
  Runner Resources build phase. This is one shared edit for all locales.
- `tools/content/build` was not run. `assets/deck/pt.json` and `deck_prompt.pt.json` are
  built when the phase builds all locales.
