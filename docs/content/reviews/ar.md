# Self-review: ar (Arabic, Modern Standard Arabic, RTL)

This is the LLM self-review pass (01 Q5, Phase 18 Sprint 18.3) over the machine translation of `ar`. Everything listed here is still `reviewStatus: machine`. Nothing counts as `reviewed` until a native reviewer signs it off (01 §11 step 6, launch gate).

## Scope

| Part | Files | Words (ar) |
|---|---|---|
| UI strings | `apps/taro/lib/l10n/arb/app_ar.arb`: 776 keys. All 673 `x-translate` placeholders are translated and the markers are removed. The ~100 keys translated earlier were re-checked and partly rewritten (gendered imperatives). | ~4,650 |
| iOS Info.plist | `apps/taro/ios/Runner/ar.lproj/InfoPlist.strings` (`NSUserTrackingUsageDescription`) | 14 |
| Cards | `apps/taro/content/source/ar/cards/*.yaml` (78 of 78) | ~56,000 |
| Spreads | `apps/taro/content/source/ar/spreads.yaml` (the 6 `whenToUse` texts) | ~300 |
| Articles | `apps/taro/content/source/ar/articles/{about,faq}.md` | ~2,300 |

Arabic word counts run lower than English (clitics, no articles as separate words); all long fields are inside the ×0.7…×1.4 bounds.

Crisis resources have no per-locale description field (`crisis/crisis_resources.yaml` is one shared file). The crisis UI copy lives in the ARB (`crisis*`, `safetyDeclined*`) and is covered above.

Format: every content file carries the current en `sourceHash` and `reviewStatus: machine`, emitted with `toYaml` (`tools/dart_tools/lib/src/content/yaml_writer.dart`) and the glossary-forced `name`, exactly as `tools/content/translate` writes them. The header comment says the draft was made in-session, not by an API run.

## What was checked

1. **Meaning against en.** Every card field, spread text, article section and ARB value was re-read against the English source. Long texts keep the en paragraph count.
2. **Register** (`worker/prompts/reading/v1/style.ar.md`). Clear MSA, second person singular. The reader is addressed with the forms the style file accepts (يمكنك، قد تلاحظ، ربما) and with verbal nouns.
   - Fixed in review: about 35 gendered adjectives or participles describing the reader (e.g. «مستعدًا»، «متأكدًا»، «عالقًا»، «لطيفًا»، «محقًا»، «وفيًّا») were rephrased with verbal nouns or verbs (بالاستعداد، باليقين، بالعلوق، اللطف…).
   - Fixed in review: all imperatives addressed to the reader (اسمح، لاحظ، خذ، اختر، افتح، ثبّت، أرسل، صدّر…) in cards, FAQ steps and the ARB were turned into «يمكنك …», «يُرجى …» or verbal nouns (UI buttons use verbal nouns: «إعادة المحاولة»، «بدء»، «اختيار ملف»). The one imperative kept is the user's own reply `dailyReminderOfferYes` «نعم، ذكّرني», addressed to the app.
   - Court-card imagery: en says "figure"; the draft first used «شاب / امرأة / رجل». Changed to «شخص يافع / شخصية / شخص». The card names stay gendered (الملكة، الملك) as in the glossary, with verbs agreeing (تجلس ملكة الكؤوس، يجلس ملك السيوف).
3. **Glossary.** Every `name` equals `glossary.yaml` `cards.<id>.ar` (forced by the emitter). Running text uses: العصي، الكؤوس، السيوف، العملات؛ الأركانا الكبرى/الصغرى؛ معتدلة/معكوسة; «في وضعها المعكوس» once per reversed meaning; توزيع (spread)، قراءة، بطاقة اليوم، المذكرات، الموضع. Spread and position names in the ARB match `terms.spread_*` and `positions.*` (e.g. «المسار أ»، «الطرف الآخر»، «الآمال والمخاوف»).
4. **Banned claims.** No `common.global` or `locales.ar.global` term appears (`check_store_copy.py` OK). The style.ar.md reject list, including prefixed forms, was linted separately:
   - Fixed in review: «دقة الإنجاز» (pentacles_12 keyword), «التخطيط الدقيق» (pentacles_12), «الحساب الدقيق» (pentacles_04), «وسحر الرسائل» (cups_11).
   - "Magical" in the Moon card became «أكثر غموضًا». "Therapy/healing" are rendered as «مختص مؤهل» and «التعافي», never علاج.
   - ARB: «دقيقة» (minute) starts with the banned stem دقيق*, so `durationMinutes` / `durationHoursMinutes` use the abbreviations «د» / «س», and `durationLessThanMinute` is «ثوانٍ معدودة» (see open question 3).
5. **Reflection voice.** «قد تعكس»، «تدعوك إلى»، «يمكنك أن تسأل». No predictions; "future/outcome" is always «إلى أين قد تتجه الأمور إن لم يتغير شيء». No reflection question starts with هل; 196 of 234 start with ما/ماذا/أيّ/أين/كيف, the rest with مَن/عمّ/ممن or a preposition (mostly questions about a person).
6. **Machine limits.** Keywords ≤ 24 characters, short texts ≤ 160, questions ≤ 120 and ending in «؟», every field contains Arabic script, no bidi control characters anywhere (lines that would start with the Latin "Taro" were reworded instead of using U+200F). `tools/content/validate` reports no `ar` error and no `ar` staleness item.
7. **ARB.**
   - Placeholders identical to en. Plurals use the Arabic CLDR categories `zero/one/two/few/many/other`; the en `=0` branches are kept (`balanceReadings`, `cardDrawnTimes`, `deleteErasedJournal`).
   - Only `appTitle` and `launchSemantics` ("Taro") and pure-placeholder values equal en; `check_l10n.py --strict-translations` reports nothing for `ar`.
   - `deleteConfirmWord` = «حذف».

## Compliance strings (05 §3), kept to their exact meaning

- **`disclaimerShort`** «للترفيه والتأمل الذاتي. ليست نصيحة مهنية.»; **`disclaimerOnboardingBody`** keeps "not predictions" and «ليست نصيحة طبية أو قانونية أو مالية أو نفسية».
- **`aiConsentBody`**: names OpenAI only («نماذج GPT التابعة لشركة OpenAI»), no name/email/advertising ID, question not stored, encrypted until delivered (at most 7 days), reports kept 90 days, not used for training, "may be wrong or unexpected". `privacyAiAllowedSubtitle` also names OpenAI only. `questionChargeFree/Credits` stay provider-neutral («خدمة ذكاء اصطناعي»).
- **`aiConsentAccept` / `aiConsentDecline`** «السماح بقراءات الذكاء الاصطناعي» / «ليس الآن» (no confirmshaming).
- **`crisisTitle` / `crisisBody` / `safetyDeclinedSelfHarm` / `safetyDeclinedHarmToOthers`**: same meaning, urge to reach out now, local emergency services.
- **`refusalGeneric` and `safetyDeclined*`**: all six refused categories kept; each points to a professional where en does.
- **`reportReadingDisclosure`**: «سيُرسَل سؤالك وهذه القراءة إلى Taro وسيُحفظان لمدة 90 يومًا».
- **`storeConsumableDisclosure` / `restoreNothingFound`**: packs don't expire, are tied to the install and can't be restored.
- **`storeBestValue`** «القيمة الأفضل» (honest computed badge; أفضل is not on the ar list).
- **`nsUserTrackingUsageDescription`** = InfoPlist.strings: «السماح بالتتبع يتيح لك رؤية إعلانات أقرب إلى اهتماماتك. يبقى التطبيق نفسه في الحالتين.» (neutral, no incentive, same app either way).
- About/FAQ disclaimer sections keep "does not predict the future", "not a substitute for professional advice" and the medical/legal/financial/psychological sentence.

## Open questions for the native reviewer and the owner

1. **About/FAQ provider names (source issue, not ar).** en About and FAQ still say "Anthropic's Claude or OpenAI's GPT models", while `aiConsentBody` is OpenAI-only. The ar text follows en faithfully. Fix en first; ar then goes stale and is re-translated.
2. **FAQ settings paths (source issue).** en uses "Settings → Purchases", "Settings → Your data", "Settings → Privacy → AI data sharing", "Settings → Help → Crisis resources", which do not match the UI labels. ar translates en literally («الإعدادات ← المشتريات» …) rather than inventing paths.
3. **"Minute" vs the banned stem دقيق\*.** The whole-word matcher also hits «دقيقة» (minute). Durations therefore use «د»/«س» abbreviations. If a reviewer prefers «دقيقة واحدة», add an `allowed_contexts` entry for ar in `banned_phrases.yaml` (05 §9.5 owner).
4. **Masculine as the generic "you".** Arabic has no gender-neutral 2nd person verb; present-tense verbs (تلاحظ، تشعر، تحتاج) use the unmarked masculine form, as style.ar.md itself does. A reviewer may prefer more verbal-noun phrasing in the most visible strings.
5. **«مجموعة» for both suit and deck.** Suit = «مجموعة» (e.g. «مجموعة الماء»), deck = «مجموعة الأوراق» (glossary). Confirm this is clear, or choose «فئة» for suit.
6. **Page = «تابع»** (glossary), Judgement = «الحكم», «الأركانا» transliterated: confirm with the glossary review.
7. **Reflection questions starting with مَن / عمّ.** style.ar.md lists ما، ماذا، أيّ، كيف، أين، متى for prompts. 38 card questions ask about a person and start with مَن or a preposition. Not banned (only هل is), but a reviewer may rephrase.
8. **Contrast words.** style.ar.md (written for AI readings) asks to avoid «بدلًا من» and «ليس … بل». Card prose uses «بدلًا من» about 70 times where en has "rather than / instead of". Not banned; a reviewer may thin them out.
9. **Numerals.** Western digits (7، 90، 20) are used throughout, matching the ARB placeholders and `intl` defaults. Confirm vs Arabic-Indic digits for the launch markets.
10. **Brand inside RTL text.** "Taro" (Latin) is kept in running text («يمكن لـTaro»، «عن التاروت وTaro»). Check the rendering of the attached prefix «لـ/وـ» before a Latin word on device.

## iOS project wiring (not edited; shared file)

`ios/Runner/ar.lproj/InfoPlist.strings` exists, but `Runner.xcodeproj/project.pbxproj` has no `InfoPlist.strings` variant group and `knownRegions = (en, Base)`. To bundle it (once, for all locales):
- add `ar` (and the other 10 locales) to `knownRegions`;
- add a `PBXVariantGroup` named `InfoPlist.strings` with a `PBXFileReference` per locale (`ar.lproj/InfoPlist.strings`, `lastKnownFileType = text.plist.strings`), placed in the Runner group;
- add a `PBXBuildFile` for that variant group to the Runner target's `PBXResourcesBuildPhase`.

## Items needing native review (launch gate, 01 §11 step 6)

- All 22 Major Arcana: every field.
- All 78 cards: `name`, `keywordsUpright/Reversed`, `shortUpright/Reversed` (names already locked by the glossary).
- At least 20% of the minor long texts (about 12 cards). Suggested sample: an Ace, a 5, a 10 and a court card per suit, e.g. wands_01, wands_05, wands_13, cups_05, cups_10, cups_13, swords_03, swords_09, swords_14, pentacles_05, pentacles_10, pentacles_14 (heavier emotional or court-gender content).
- The compliance strings above plus `InfoPlist.strings` (Sprint 18.2 compliance review), and the RTL goldens.
- The glossary `review.ar` must flip to `reviewed` first (step 2).
