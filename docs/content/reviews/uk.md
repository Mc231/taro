# Self-review: uk (Ukrainian)

LLM self-review pass (01 Q5, Phase 18 Sprint 18.3) over the machine translation of
`uk`. Everything listed here is `reviewStatus: machine`; nothing is `reviewed` until
a native reviewer signs off (01 §11 step 6, launch gate).

## Scope

| Part | Files | Words (uk) |
|---|---|---|
| UI strings | `apps/taro/lib/l10n/arb/app_uk.arb` (776 keys; 673 `x-translate` placeholders translated, markers removed; the 103 earlier drafts re-done for glossary and register consistency) | ~4,600 |
| iOS Info.plist | `apps/taro/ios/Runner/uk.lproj/InfoPlist.strings` (`NSUserTrackingUsageDescription`) | 14 |
| Cards | `apps/taro/content/source/uk/cards/*.yaml` (78/78) | ~57,500 |
| Spreads | `apps/taro/content/source/uk/spreads.yaml` (6 `whenToUse`) | ~300 |
| Articles | `apps/taro/content/source/uk/articles/{about,faq}.md` | ~2,450 |

Crisis resources have no per-locale description field (`crisis/crisis_resources.yaml`
is one file; the `UA` entries and `localeFallback.uk` are owned by Sprint 18.4). The
crisis UI copy lives in ARB (`crisis*`, `safetyDeclined*`) and is covered above.

Format: every content file carries the current en `sourceHash` and
`reviewStatus: machine`, written with the `toYaml` layout of
`tools/dart_tools/lib/src/content/yaml_writer.dart`; `name` is forced to
`glossary.yaml` `cards.<id>.uk`. The header comment says the draft was made in-session
(no `tools/content/translate` API run).

## What was checked

1. **Meaning vs en**: every card field, spread text, article section and ARB value
   re-read against the English source; long texts keep the en paragraph count.
2. **Register** (`worker/prompts/reading/v1/style.uk.md`): warm Ukrainian with
   capitalised formal «Ви» (Ви, Вас, Вам, Ваш…) everywhere, including the ARB; a scan
   for lower-case `ви/вас/вам/ваш*` finds none. Apostrophe is `’` (U+2019), never `'`
   (also keeps ICU quoting safe). No Russian words found on the pass.
3. **Gender-neutral reader**: the formal plural «Ви» takes plural agreement
   («Ви готові», «Ви не самі», «Ви втомилися»), so no reader-gendered forms are
   needed. First-person question suggestions avoid gendered adjectives. Other people
   are «інша людина», «хтось близький», «партнер чи партнерка». Card figures are
   «фігура» (feminine noun, neutral meaning); court titles keep their glossary gender.
4. **Glossary** (`glossary.yaml`, all `uk` entries): card names, suits (Жезли, Кубки,
   Мечі, Пентаклі), Старші / Молодші аркани, «пряма» / «перевернута», «розклад» for
   spread, «тлумачення» for reading (also as the credit unit: «3 тлумачення»),
   «класичне тлумачення», «Карта дня», «Щоденник», position names and the six spread
   names exactly as in `terms.spread_*`.
5. **Banned claims** (`common.global` + `locales.uk.global`): no `точн*`, `гарант*`,
   `ясновид*`, `екстрасенс*`, `лікув*`, `приворот*`, `заклинан*`, «передбач* майбутн*»,
   `100%`. «Does not predict the future» is rendered «не прогнозує майбутнє». Also
   avoided the style file's «станеться», «незабаром», «карта показує, що».
6. **Future/outcome framing** (STYLE_GUIDE §5): «куди все може рухатися, якщо нічого не
   зміниться»; `outcome_desc` keeps «це ніколи не доля»; no time frames.
7. **Compliance copy (05 §3)**: `disclaimer*`, `legalDisclaimerBody`, `aiConsent*`
   (OpenAI GPT only, question not stored, encrypted until delivered, at most 7 days,
   reports 90 days, no training, «можуть бути хибними або неочікуваними»),
   `refusalGeneric`, `safetyDeclined*`, `crisis*`, `reportReadingDisclosure`,
   `storeConsumableDisclosure`, `restoreNothingFound`, `att*`,
   `nsUserTrackingUsageDescription`, `privacyAiAllowedSubtitle`: meaning kept 1:1, no
   softening and no additions. Apple-facing strings name only iOS / App Store;
   `updateCaptionAndroid` alone names Google Play (as in en).
8. **ICU / placeholders**: placeholders identical to en; plurals use the uk CLDR
   categories `one / few / many / other` (plus en's `=0`); `helpEmailBody` keeps the
   `\n` structure. `check_l10n.py` passes.
9. **Bounds**: `tools/content/validate` (keywords ≤ 24 chars, shorts ≤ 160, questions
   ≤ 120 and ending in `?`, word ranges ×0.7–×1.4) and `--strict-locales` pass with
   no `uk` errors; `uk` is a complete locale.

## Issues fixed during the pass

- The 103 pre-existing `app_uk.arb` values used «розклад» for *reading* (glossary:
  «тлумачення», «розклад» = spread) and mixed «вас» / «Ваш»; all re-done.
- uk `one` also covers 21, 31, …, so «Uses your last reading» and «Pick one more card»
  moved to `=1` branches (`questionChargeCredits`, `drawPickTitle`); the `one` branch
  now carries `{count}`.
- `helpSupportIdLabel` / `settingsSupportId` first kept the English «Support ID» and
  failed the equal-to-en check; now «ID підтримки» everywhere (ARB and FAQ).
- `drawShuffleReady` draft «Я готові» (ungrammatical, gendered in the singular) →
  «Готово, тягнемо карти»; `spread_relationship_suggestion_2` draft «відкритішою
  людиною» → «Як мені поводитися відкритіше…».
- Three keywords over 24 characters shortened (`swords_05`, `swords_14`,
  `pentacles_09`); two typos fixed («почитися», «пнетеся»).

## Open questions for the native reviewer

1. **Register**: capitalised formal «Ви» follows `style.uk.md` and the glossary, but
   the Phase 18 brief names no uk register. Many consumer apps use lower-case «ви» or
   «ти». The owner should confirm before review; changing it is a mechanical pass.
2. **«Тлумачення» as the credit unit** («Отримати більше тлумачень», «+3 тлумачення»)
   is glossary-correct but reads long on paywall chips; confirm, or add a separate
   glossary term for the purchasable unit.
3. **Learn tab = «Навчання»** (alternatives «Довідник», «Знання»). Not in the glossary.
4. **iOS Settings = «Параметри»** (Apple's uk name) vs the app's own «Налаштування»;
   used in `attPrepromptFootnote`, `privacyTracking*`.
5. **«не згоряють»** for «don't expire» (store copy) and **«ВИДАЛИТИ»** as
   `deleteConfirmWord`.
6. `style.uk.md` asks AI readings to avoid «а не» / «замість»; card texts use «а не»
   where en has «rather than». Decide whether the rule applies to deck content too.
7. Court ranks (Паж, Лицар, Королева, Король) and «Тлумачення» vs «Читання» follow the
   glossary notes from the glossary pass; the reviewer owns them.

## Upstream (en) inconsistency found

- `en/articles/about.md` and `en/articles/faq.md` name «Anthropic's Claude or OpenAI's
  GPT models», while `aiConsentBody` / `privacyAiAllowedSubtitle` (05 §3, RC97) disclose
  OpenAI only. The uk articles follow en faithfully; the en articles should be fixed
  (owner), which will make every locale's articles stale and need re-translation.
- The en FAQ menu paths («Settings → Purchases», «Settings → Your data»,
  «Settings → Privacy → AI data sharing») do not match the ARB section names; uk mirrors
  en.

## Needs native review before release (launch gate, 01 §11 step 6)

- All 22 Major Arcana files, and names / keywords / `shortUpright` / `shortReversed`
  of all 78 cards.
- Every 05 §3 compliance key in `app_uk.arb` and `uk.lproj/InfoPlist.strings`
  (Sprint 18.2 MANUAL item); `safetyDeclined*`, `refusalGeneric`, `crisis*` copy.
- Both articles (consent and data-handling paragraphs in particular).
- The `uk` row of `glossary.yaml` (`review.uk` is still `machine`) and the
  `banned_phrases.yaml` `locales.uk` table (Sprint 18.4).

## Not done here

- `ios/Runner.xcodeproj/project.pbxproj` is unchanged: `knownRegions` lists only
  `en, Base` and no `InfoPlist.strings` variant group exists. Xcode needs `uk` in
  `knownRegions` and the `uk.lproj/InfoPlist.strings` file in an `InfoPlist.strings`
  variant group in the Runner Resources build phase (one shared edit for all locales).
- `tools/content/build` was not run (generated deck assets are rebuilt once for all
  locales).
