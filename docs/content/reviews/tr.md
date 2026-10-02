# Self-review: tr (Turkish, sen-form)

This is the LLM self-review pass (01 Q5, Phase 18 Sprint 18.3) over the machine translation of `tr`. Everything listed here is still `reviewStatus: machine`. Nothing counts as `reviewed` until a native reviewer signs it off (01 §11 step 6, launch gate).

## Scope

| Part | Files | Words (tr) |
|---|---|---|
| UI strings | `apps/taro/lib/l10n/arb/app_tr.arb`: 776 keys. The 673 `x-translate` placeholders are now translated and all markers are removed. The 103 keys translated earlier were kept. | ~4,050 |
| iOS Info.plist | `apps/taro/ios/Runner/tr.lproj/InfoPlist.strings` (`NSUserTrackingUsageDescription`) | 14 |
| Cards | `apps/taro/content/source/tr/cards/*.yaml` (78 of 78) | ~49,700 |
| Spreads | `apps/taro/content/source/tr/spreads.yaml` (the 6 `whenToUse` texts) | ~290 |
| Articles | `apps/taro/content/source/tr/articles/{about,faq}.md` | ~2,280 |

Crisis resources have no per-locale description field, because `crisis/crisis_resources.yaml` is one shared file. The crisis UI copy lives in the ARB (`crisis*`, `safetyDeclined*`) and is covered above.

Format: every content file carries the current en `sourceHash` and `reviewStatus: machine`, written with `toYaml` (`tools/dart_tools/lib/src/content/yaml_writer.dart`) and the hash functions of `validator.dart`. `name` is forced from `glossary.yaml`. The header comment says the draft was made in-session, not by a `tools/content/translate` API run.

Turkish is agglutinative, so word counts run at about 0.75 × en. Every field still sits inside the ×0.7…×1.4 bounds.

## What was checked

1. **Meaning against en.** Every card field, spread text, article section and ARB value was re-read against the English source. Long texts keep the en paragraph count.
2. **Register** (`worker/prompts/reading/v1/style.tr.md`). The text uses warm "sen" throughout (senin, sana, "deneyebilirsin") and has no "siz" forms. Other people are neutral: "diğer kişi", "sana yakın biri", "biri".
3. **Gender-neutral reader.** Turkish has no grammatical gender, and the reader is never gendered. Court figures are described as "figür" and as qualities ("İmparatoriçe’nin besleyici enerjisi"), not as a person who will enter the reader's life.
4. **Glossary.** Every `name` equals `glossary.yaml` `cards.<id>.tr`.
   - Running text uses the glossary terms: Büyük/Küçük Arkana; Asalar, Kupalar, Kılıçlar, Tılsımlar; düz/ters ("Ters geldiğinde …"); açılım, okuma, günlük, günün kartı, iç gözlem, Prens/Şövalye/Kraliçe/Kral.
   - Spread and position names in the ARB match `terms.spread_*` and `positions.*`.
5. **Banned claims.** No `common.global` or `locales.tr.global` term appears. A local stem lint ran over all tr sources, and `check_store_copy` passes.
   - Fixed in review: 6 hits of the stem `kesin*`, across 5 cards, which also catches "kesinlikle", "kesintisiz" and "kesinti" (major_00, major_05, major_09, major_12, swords_10). They were rephrased as "her şeyi bilmeden", "sert", "bölünmeden", "sapma" and "geri dönüşü olmayan".
   - "büyü"/"büyüsü" never appear on their own. "Büyücü" and "büyümek" are allowed.
6. **Style-file avoid list.**
   - No "kartlar gösteriyor".
   - No -(y)AcAK future about outcomes. The remaining -acak/-ecek forms are participles ("yardım edecek şey"). One outcome-like "önemli olacak" was softened to "olabilecek" (pentacles_10).
   - "yakında" and "zamanla" were removed even where they only meant "nearby" or "with time" (about 10 places), so the Worker's own lint will not trip on them.
   - "yerine" and "… değil, …" are reduced but still used where Turkish needs them. They are not banned.
7. **Reflection voice.** The text says "yansıtabilir", "davet eder", "belki", "fark edebilirsin". "Future"/"outcome" is rendered as "hiçbir şey değişmezse işlerin gidiyor olabileceği yön", and "asla bir kader değil" is kept on the Celtic Cross outcome.
   - Death, the Tower, the Devil and Three/Nine/Ten of Swords keep the en framing: no physical death, no catastrophe, no injury.
8. **Reflection questions.** All 234 questions are open questions with Ne, Hangi, Nasıl, Nerede, Ne zaman or Kim, and none uses "mı/mi".
   - Five en yes/no questions were made open: wands_02, wands_11, major_20, swords_08 and wands_09 ("bu korumaya bugün ne kadar ihtiyacın var?").
9. **ICU and placeholders.** tr has CLDR categories `one`/`other`. Every plural keeps both, plus the en `=0` branches. Nouns after numbers stay singular ("{count} okuma").
   - Placeholders are never followed by a case suffix, because vowel harmony is unknowable at build time. Sentences were restructured instead: "Destek: {country}", "Ara: {number}", "Yazıldığı dil: {language}".
10. **Machine limits.**
    - Keywords are at most 24 characters. 7 overruns were shortened in review.
    - Short texts are at most 160 characters, and questions at most 120.
    - `tools/content/validate --strict-locales` reports no tr errors.

## Compliance strings (05 §3), kept in exact meaning

- **disclaimerShort / disclaimerOnboardingBody / legalDisclaimerBody.** "eğlence ve iç gözlem içindir", "profesyonel tavsiye değildir", "geleceğe dair öngörü değildir", "tıbbi, hukuki, finansal veya psikolojik tavsiye niteliği taşımaz". "kehanet" is banned, so "öngörü" is used.
- **aiConsentBody.** It names OpenAI only. Every factual claim is kept:
  - the data sent: question, spread, cards, app language;
  - never sent: name, e-mail, advertising ID;
  - the question is not stored;
  - the reading is encrypted until delivered, at most 7 days;
  - reports are kept 90 days;
  - no training;
  - readings may be wrong or unexpected.
- **privacyAiAllowedSubtitle** says "(OpenAI)".
- **refusalGeneric / safetyDeclined\*.** All refused categories are kept. Professional referrals are kept: doktor, ebe, avukat, "yetkin bir uzman".
- **crisisTitle / crisisBody / safetyDeclinedSelfHarm / safetyDeclinedHarmToOthers.** "Yalnız değilsin". The text says "hemen birine ulaş", "kriz destek hattı" and "yerel acil durum hizmetleri".
- **Paywall and store disclosures.** `storeConsumableDisclosure`, `restoreNothingFound`, `outOfReadingsFromPrice`, `storeBody` ("okumaların süresi dolmaz") and `rewardedOfferTitle` (says it is an ad) are all kept. "Remove Banner Ads" is "Banner Reklamları Kaldır" everywhere. `storeBestValue` is "En avantajlı", an honest badge with no "en iyi" claim.
- **ATT.** The pre-prompt is neutral ("İki cevap da olur"). `nsUserTrackingUsageDescription` in the ARB and in `tr.lproj/InfoPlist.strings` are identical.

## Deviations from en, for the owner

1. **about.md and faq.md name only OpenAI.** The en articles still say "Anthropic's Claude or OpenAI's GPT models" and "Taro's AI providers". The consent copy is OpenAI-only at launch (05 §3, 2026-10-01), so tr says "Taro’nun yapay zekâ sağlayıcısının bir modeline (OpenAI’ın GPT modelleri)" and "sağlayıcısı" in the singular.
   - **The en articles need the same fix.** That fix will change their `sourceHash` and mark every locale's articles stale, which is wanted.
2. **The FAQ's menu paths use the real tr UI labels**, not literal translations of the en paths:
   - Settings → Privacy is "Ayarlar → Gizlilik tercihleri".
   - "Crisis resources" is "Destek hatları", the `settingsSupportLines` label.
   - Purchases and Your data are "Satın alımlar" and "Verilerin".
   - The en FAQ paths (Settings → Purchases, Your data, Privacy → AI data sharing) do not match the en ARB section names either. The en side should be checked.
3. **`deleteConfirmWord` = "ONAYLA" instead of "SİL".** `delete_data_controller.dart` compares the typed word to the confirm word with Dart's locale-independent `toLowerCase()`, which gives "İ" → "i̇" (dotted). With "SİL", a user who types "sil" or "Sil" would fail the check. A word without I/İ/ı avoids that. The label reads "Silmeyi onaylamak için {word} yaz".
4. **Brand-only keys.** `launchSemantics` is "Taro uygulaması", `settingsVersion` is "Taro sürüm {version} ({build})" and `cardElementValue` is "Elementi: {element}". All three differ from en, so `check_l10n` passes without editing the shared allowlist.

## Open questions for the native reviewer

- **Card names** (from the glossary report):
  - Page = Prens (alternatives: Uşak, Vale)
  - Hierophant = Başrahip (alternative: Aziz)
  - Judgement = Mahkeme (alternative: Yargı)
  - Pentacles = Tılsımlar
  - "Mahkeme" (court) fits the card's "awakening/renewal" theme poorly. If the glossary moves to "Yargı" or "Diriliş", re-emit the names, since `name` is forced.
- **Pentacles imagery.** Card texts call the objects "sikke" (coin) because the art shows coins, while the suit is "Tılsım". Confirm that this reads naturally.
- **The disclaimer wording differs** from `tools/store_copy/required_sentences.yaml` `tr`:
  - The app says "eğlence ve iç gözlem içindir". The store sentence says "kendini yansıtma", which is a calque.
  - The reviewer should choose one term for self-reflection and use it in both places.
- **"Yapay zekâ"** is written with the circumflex, like the existing tr strings. Confirm that over "yapay zeka".
- **Register for UI chrome.** Buttons use the bare imperative ("Tekrar dene", "İptal", "Kartı aç"). Error titles use second person ("Çevrimdışısın"). Confirm this is the wanted tone for a reflective app.
- **iOS settings path.** `attPrepromptFootnote` assumes the tr iOS labels "Gizlilik ve Güvenlik > İzleme". Check them against a Turkish iPhone.
- **`homeGreetingAfternoon` = "İyi günler".** "Tünaydın" exists but is dated.

## Needs native review before release (launch gate)

- All 05 §3 compliance keys: `disclaimer*`, `aiConsent*`, `aiLabel`, `refusalGeneric`, `crisisTitle`, `crisisBody`, `reportReading*`, plus `safetyDeclined*`, `questionCharge*`, `storeConsumableDisclosure`, `restoreNothingFound`, `att*` and `nsUserTrackingUsageDescription` (InfoPlist.strings).
- The glossary block `review.tr` (still `machine`).
- The 78 cards, spreads and both articles, especially about.md §"Yapay zekâ okumaları nasıl çalışır" and faq.md §"Yapay zekâ ve gizlilik" (the OpenAI-only deviation above).

## Not done here

- **`project.pbxproj` was not edited.** `knownRegions` lists only `en` and `Base`, and no `InfoPlist.strings` variant group exists for any locale yet. To make Xcode bundle `tr.lproj/InfoPlist.strings`, someone must add `tr` to `knownRegions` and add a PBXVariantGroup `InfoPlist.strings` with a `tr` child to the Runner Resources build phase. This is one shared edit for all 11 locales.
- **`apps/taro/assets/deck/tr.json` was not built.** `tools/content build` runs once all locales are ready.
