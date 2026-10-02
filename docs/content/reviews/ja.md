# Japanese (ja): translation self-review

- **Scope:** Phase 18 machine translation of everything shown to Japanese users: `apps/taro/lib/l10n/arb/app_ja.arb`, `apps/taro/ios/Runner/ja.lproj/InfoPlist.strings`, and `apps/taro/content/source/ja/**` (78 cards, `spreads.yaml`, `articles/about.md`, `articles/faq.md`).
- **Translator:** Claude (in-session; no API run of `tools/content translate`). Every content file has `reviewStatus: machine` and the current en `sourceHash`.
- **Pass:** this is the LLM self-review required by 01 §11 step 6 and Q5. It is **not** a native review. Only a native reviewer may set `reviewed`.
- **Date:** 2026-10-02.

## 1. What was checked

| Check | How | Result |
|---|---|---|
| Meaning against en | Re-read each file against its en source: every paragraph, keyword, question and image note | Done. Mistranslations and register slips were fixed (§2). |
| Register | `worker/prompts/reading/v1/style.ja.md`: polite です/ます, 「あなた」 used sparingly, 「相手」「身近な人」 for others | です/ます throughout. Others are referred to as 相手, 身近な人 or 誰か. No gendered pronouns (彼/彼女). Card figures are called 人物. |
| Glossary | `glossary.yaml` ja for all 78 card names, 4 suits, 2 arcana, 22 positions and the terms | Card `name` fields equal the glossary (validated). The ARB `spread_*_name` values equal `terms.spread_*`, and the `spread_*_pos_*_name` values equal `positions.*`. In running text the suits are always ワンド／カップ／ソード／ペンタクル (never 剣 or コイン), and orientation is 正位置／逆位置, written as 「逆位置の{card}」 with no parentheses. |
| Reading voice | STYLE_GUIDE §1 and style.ja.md "avoid" list | No 「カードは〜を示しています」 claims about the reader. The remaining 〜を示しています lines describe imagery and were changed to 描いています／照らしています／促しています. No 「〜になるでしょう」 about outcomes (it appears only in questions such as 「何が助けになるでしょうか」). 「やがて」 was removed (6 occurrences), and there is no 「もうすぐ」. |
| Banned claims | `tools/store_copy/banned_phrases.yaml` (common + ja substring list) | None in the ja content or the ARB. Two near misses were fixed while drafting: 「必ずしも」 (major_18) and 「必ず削除されます」 (faq). |
| Compliance copy (05 §3) | Compared word by word: disclaimerShort, disclaimerOnboardingBody, aiConsent* (OpenAI only), aiLabel, refusalGeneric, crisisTitle/Body, reportReading*, storeConsumableDisclosure, paywall and rewarded copy, the ATT pre-prompt and NSUserTrackingUsageDescription | The meaning is unchanged. Nothing is softened or added, and no incentive or urgency was introduced. Every rewarded offer says that it is an ad (広告を見て…). |
| ICU / placeholders | `check_l10n.py`: ja uses CLDR `other` plus the `=N` branches of en | Placeholders are identical. `=1` is used where the en `one` text has its own wording (questionChargeCredits, drawPickTitle, journalPatternsMostDrawn, cardDrawnTimes). |
| Machine rules | `tools/content/validate`, `--strict-locales` | No ja errors and no ja report items. |

## 2. Issues found and fixed during the pass

1. `必ず` (banned, ja substring rule) appeared in 「必ずしも」 (major_18) and in the faq sentence on deleting the app. Both were reworded.
2. 「〜を示しています」 was used for card descriptions in 24 places. Imagery lines now use 描いています, and lines about the reader use 照らしています／促しています, matching the style.ja.md guidance not to say "the card shows".
3. 「やがて」 was used in 6 places, which could read as a prediction. It was replaced with 時が来たら, しだいに, 時間をかけて and similar, or removed.
4. `launchSemantics` (the brand "Taro") was flagged as untranslated. It was added to `tools/l10n_untranslated_allowlist.yaml` `keys` as a brand string, like `appTitle`.

## 3. Open questions for the native reviewer / owner

1. **Provider disclosure in the en articles (compliance, needs an owner decision).** `en/articles/about.md` and `en/articles/faq.md` still say 「AnthropicのClaude、またはOpenAIのGPTモデル」. RC97 (2026-10-01) set `ai.disclosedProviders = ["openai"]`, and the ARB consent copy names only OpenAI. The ja articles translate the en text faithfully, so they inherit the mismatch, and so do the de and pt articles. Fix the en articles; the ja files will then report as stale and need re-translation.
2. **The glossary is still `review.ja: machine`.** 01 §11 requires the glossary to be 100 % `reviewed` before translation, and `tools/content translate` refuses to run otherwise. Everything here was built on the machine glossary, so terms that change in review must be updated in the cards, ARB and articles.
3. **Spread name `ワンオラクル`** (glossary `terms.spread_single`). This is the common Japanese name for a one-card draw. 「1枚引き」 would also work.
4. **Page = ペイジ** (glossary). Some decks use ペイジ and others ページ.
5. **`deleteConfirmWord` = 削除.** The user types it to confirm. The comparison is case-insensitive, and it should be checked that IME input (全角／半角) matches reliably. Otherwise use a Latin word.
6. **Menu paths in the articles.** The en text names paths such as 「設定」→「あなたのデータ」→「バックアップを書き出す」 and 「設定」→「プライバシー」→「AIへのデータ共有」. These were translated literally, but they do not match the actual ARB section labels (settingsSectionPrivacyData = 「プライバシーとデータ」 and others). The en source has the same gap.
7. **The `=1` plural branches** were added for natural wording (§1). ARCHITECTURE.md says that ja copies "keep only the CLDR other branch", but `check_l10n` allows `=N`. Confirm this is acceptable.
8. **The JP crisis entry** (`crisis_resources.yaml`, いのちの電話 0570-783-556) has no `hours`, and `verifiedAt` is null. A native reviewer should verify the number and hours, and consider adding a 24-hour free line (for example よりそいホットライン) per 05 §4.2 before the release check.
9. **Justice's sword** is written 剣 (major_11), as it is part of the figure's attribute and not the suit. Confirm or change it to ソード.
10. **「ではなく」／「というより」** appear about 190 times in the cards, where they translate the en "rather than / not … but". style.ja.md lists them under "avoid" for AI readings. Decide whether the authored card texts should follow the same rule. If so, a bulk rewrite is needed.

## 4. Items that need native review (launch gate, 01 §11 step 6)

**Required (all of them):**

- All 22 Major Arcana files: `ja/cards/major_00.yaml` … `major_21.yaml` (full text).
- Names, keywords and short meanings of all 78 cards (`name`, `keywordsUpright`, `keywordsReversed`, `shortUpright`, `shortReversed`).
- Every compliance string in `app_ja.arb`: disclaimer*, aiConsent*, aiLabel, refusalGeneric, safety/refusal copy, crisis*, reportReading*, store*/rewarded*/outOfReadings* (paywall disclosures), att*, and `nsUserTrackingUsageDescription` together with `ios/Runner/ja.lproj/InfoPlist.strings`.
- `ja/articles/about.md` and `ja/articles/faq.md` (privacy and disclaimer sections), after open question 1 is resolved.

**Minor long texts, at least a 20 % sample (12 of 56 suggested):** wands_01, wands_10, wands_14, cups_01, cups_05, cups_10, swords_03, swords_09, swords_10, pentacles_01, pentacles_05, pentacles_13. These cover each suit's Ace, the cards that touch distress and crisis wording (cups_05, swords_03, swords_09, swords_10, pentacles_05) and one court card per suit. The remaining minor long texts stay `machine` after this self-review.

## 5. Volume

| Part | en source | ja output |
|---|---|---|
| ARB (673 keys) | about 3,700 words | about 15,700 characters |
| 78 cards | 61,122 words | about 173,900 characters |
| spreads.yaml (6 texts) | about 280 words | about 900 characters |
| about.md and faq.md | 2,712 words | about 8,900 characters |
