# Store copy: native-speaker review (MANUAL, Phase 20.1)

The 11 non-English listings in `apps/taro/store/aso.yaml` (App Store name, subtitle, keywords, promo text, description; Play title, short and full description; IAP display names and descriptions) and `apps/taro/store/whats_new/{locale}.txt` are machine-assisted translations. All automated checks are green (`asa validate`, `check_store_copy`, `check_pack_sizes`, `check_iap_ids`, `check_l10n`, `check_urls`), but a native speaker must read each locale before the Phase 20.3 push.

What every reviewer checks, in every locale:

1. The first line of the description is the disclaimer (entertainment and self-reflection, no prediction, no professional advice) and reads naturally. Keep its meaning exactly (`tools/store_copy/required_sentences.yaml`).
2. No claim of prediction, accuracy, psychic or supernatural ability, guarantee, healing or spells (05 §9.5), including softer local idioms ("the cards will tell you", "real answers").
3. "One free AI reading every day" and "a free daily card" stay two separate things (RC64).
4. The terms for *spread*, *reading*, *daily card*, *journal* and *Learn* match the app's ARB strings for that locale, so the store and the app use the same words.
5. `Taro` stays in Latin script in the name and the text. No mention of the other store's platform.
6. Limits after edits: name/subtitle/Play title ≤ 30, keywords ≤ 100 (no spaces, no word from the name or subtitle), promo ≤ 170, Play short ≤ 80. Re-run the checks after any change.

Sign off by adding a row to the table at the end.

## Per-locale points

### ar (ar-SA, RTL)
- `فرشة` / `فرشات` for "spread": confirm against the ARB term; `انتشار` or `توزيع البطاقات` may be more natural.
- `أوراكل` (oracle) is a transliteration; confirm it is a real search term or replace it.
- Check that Latin fragments (`Taro`, the 12 language names, URLs) render correctly inside RTL paragraphs.
- Keywords have ~21 characters of headroom.

### de
- Name `Taro: Tarot Karten legen`: standard spelling is `Tarotkarten legen`; the split form may be a better search match. Decide and keep keywords free of repeats.
- `Legungen` (subtitle) vs `Legesysteme`: confirm which word users and the ARB use.
- Informal *du* throughout; confirm consistency with the app.

### es (Spain and Latin America share one listing)
- Neutral Spanish: `vídeos` (es-ES) vs `videos` (LatAm); prefer the form that fits both markets.
- `novatos` in keywords: confirm it is a real query (vs `principiantes`, which did not fit).
- `Cruz Celta` capitalization and `tiradas` term.

### fr
- Subtitle `Carte du jour, journal intime` drops the spreads cluster; check whether `tirages` can fit.
- `jeu` in keywords (deck) is ambiguous with "game"; replace with `cartes de tarot` style terms if better.
- `Une lecture IA offerte chaque jour`: confirm `offerte` does not read as a promotion.

### it
- `Benvenuto in Taro` (What's New, promo) is masculine; consider the neutral `Ti diamo il benvenuto in Taro`.
- `stese` for spreads: confirm against the ARB.

### ja
- `占い` in the name is the genre noun (allowed by 05 §9.3); make sure no sentence implies the app foretells events.
- `今日の一枚`, `ジャーナル`, `スプレッド`: match the ARB terms.
- Check line breaks (`tools/check_ja_linebreak.py` covers ARB only).

### ko
- `운세` in the name is the genre noun (allowed); same check as ja about implied prediction.
- Politeness level (합니다체) consistent across description, promo and What's New.

### nl
- `leggingen` (spreads, subtitle and description) can be read as the garment "leggings". Strongly consider `legpatronen` or `kaartleggingen`, and match the ARB.
- Name capitalization `Tarotkaarten Lezen` (Dutch would use `lezen`).

### pt (pt-BR)
- Brazilian Portuguese: `tarô`, `Boas-vindas ao Taro`. `tiragens` vs `tiradas` for spreads: confirm against the ARB.

### tr
- `Falı` in the name is the genre noun (allowed); make sure no sentence promises a future outcome.
- `yansıma` (keywords, journal) is a literal "reflection"; `içgözlem` or `düşünme` may fit better.
- `kelt,haçı`: confirm the usual term for Celtic Cross (`Kelt Haçı açılımı`).

### uk
- `ворожіння` (fortune-telling) in keywords: confirm it does not read as a prediction claim in the store context; replace from the rotation pool (`розклад`, `інтуїція`) if in doubt.
- `ШІ` for AI and `тлумачення` for reading: match the ARB.

### en (owner pass)
- ~~Daily card paragraph "Come back to it in your journal at night"~~: resolved 2026-10-05, shortened to "It is saved in your journal." in all 12 locales (no evening feature ships).

## Sign-off

| Locale | Reviewer | Date | Changes made |
|---|---|---|---|
