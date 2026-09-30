# Bundled fonts (`taro_ui`)

The typefaces named by the `font.family.{role}.{script}` tokens (01 §13, 01 §14.2, `docs/design/BRIEF.md` §3.3), bundled so the app never fetches fonts at runtime. Declared in `../pubspec.yaml` (`flutter.fonts`) under the token family names; the generated token text styles set `package: 'taro_ui'`, so the app reaches them as `packages/taro_ui/<family>`.

All faces are licensed under the SIL Open Font License 1.1; each family's licence is in `licenses/OFL-<family>.txt`, bundled as an asset and added to the app's licences page by `registerTaroFontLicenses()` (OFL 1.1 condition 2). Rebuild everything with `build_fonts.sh` (fontTools 4.66.0; the output is deterministic).

## Sources and processing

Source: the official Google Fonts repository, `github.com/google/fonts` at commit `23e54b51ddffbc7713c583748e3bd86f62b1fa4a` (2026-09-24), `ofl/<family>/`.

| Token family | File(s) | Source | Processing |
|---|---|---|---|
| Literata | `Literata-{Regular,Medium,SemiBold}.ttf` | `literata/Literata[opsz,wght].ttf` | instanced at `wght` 400/500/600, `opsz` 12; Latin + Cyrillic subset |
| IBM Plex Sans | `TaroSans-{Regular,Medium,SemiBold}.ttf` | `ibmplexsans/IBMPlexSans[wdth,wght].ttf` | instanced at `wght` 400/500/600, `wdth` 100; Latin + Cyrillic subset; renamed (RFN, below) |
| IBM Plex Sans Arabic | `TaroSansArabic-{Regular,Medium,SemiBold}.ttf` | `ibmplexsansarabic/IBMPlexSansArabic-*.ttf` | Arabic + ASCII subset; renamed |
| IBM Plex Sans JP | `TaroSansJP-{Regular,SemiBold}.ttf` | `ibmplexsansjp/IBMPlexSansJP-*.ttf` | Japanese subset; renamed |
| IBM Plex Sans KR | `TaroSansKR-{Regular,SemiBold}.ttf` | `ibmplexsanskr/IBMPlexSansKR-*.ttf` | Korean subset; renamed |
| Noto Serif Arabic | `NotoNaskhArabic-{Regular,Medium,SemiBold}.ttf` | `notonaskharabic/NotoNaskhArabic[wght].ttf` | instanced at 400/500/600; Arabic + ASCII subset |
| Noto Serif JP | `NotoSerifJP-{Regular,SemiBold}.ttf` | `notoserifjp/NotoSerifJP[wght].ttf` | instanced at 400/600; Japanese subset |
| Noto Serif KR | `NotoSerifKR-{Regular,SemiBold}.ttf` | `notoserifkr/NotoSerifKR[wght].ttf` | instanced at 400/600; Korean subset |
| IM Fell English SC | `IMFellEnglishSC-Regular.ttf` | `imfellenglishsc/IMFeENsc28P.ttf` | ASCII + Latin-1 subset (Roman numerals in every locale) |

Subsets (all keep every OpenType layout feature; hinting is dropped):

- **Latin:** U+0020–007E, U+00A0–017F (Latin-1, Latin Extended-A incl. Turkish), U+02C6–02DD, combining marks U+0300–036F, general punctuation U+2000–206F, €, ™, arrows, minus.
- **Cyrillic:** U+0400–04FF (Ukrainian included).
- **Arabic:** U+0600–06FF, U+0750–077F, presentation forms U+FB50–FDFF and U+FE70–FEFF, ZWNJ/ZWJ/LRM/RLM.
- **Japanese:** ASCII, CJK symbols and punctuation, full/half-width forms, kana (U+3040–30FF, U+31F0–31FF) and the 2,965 JIS X 0208 level-1 kanji.
- **Korean:** ASCII, CJK symbols and punctuation, full/half-width forms, compatibility jamo and the 2,350 KS X 1001 Hangul syllables.

A glyph outside a subset (a rare level-2 kanji, an uncommon Hangul syllable) falls back to the system font; widen the subset in `build_fonts.sh` if content needs it.

Weights follow the type roles: serif roles use 400 (bodyReading), 500 (display, headline) and 600 (cardName); sans roles use 400 (body, caption), 500 (label) and 600 (title, titleSmall). The CJK faces ship 400 and 600 only, to hold the size budget; a 500 request renders with the 400 face.

## Deviations

- **Noto Serif Arabic.** The tokens name "Noto Serif Arabic", which Google Fonts (and the Noto project) does not publish; Noto's serif Arabic design is **Noto Naskh Arabic**. Its files are declared under the token family name so the tokens stay unchanged. Open item for the design owner: rename the token value to "Noto Naskh Arabic" in Claude Design and `taro.tokens.json`.
- **IBM Plex Reserved Font Name.** IBM Plex carries the Reserved Font Name "Plex" (OFL 1.1 condition 3). A subset is a Modified Version, so the subset files' internal names (name table, except copyright, trademark and licence records) say "Taro Sans" and the files are called `TaroSans*.ttf`. The Flutter family key stays the token value ("IBM Plex Sans"); it is an internal lookup key, never shown to users.

## Size budget (02 §17)

| Group | Raw bytes |
|---|---|
| Latin + Cyrillic (Literata ×3, Taro Sans ×3, IM Fell) | 932,180 |
| Arabic (Taro Sans Arabic ×3, Noto Naskh Arabic ×3) | 760,936 |
| Japanese (Taro Sans JP ×2, Noto Serif JP ×2) | 5,988,948 |
| Korean (Taro Sans KR ×2, Noto Serif KR ×2) | 4,011,084 |
| **Total** | **11,693,148 (11.2 MiB); ≈ 6.0 MB deflated** |

Against the 02 §17 download budgets (≤ 60 MB iOS, ≤ 40 MB Android AAB per ABI), the fonts take about 6 MB compressed (≈ 10 % of iOS, ≈ 15 % of Android). The CI size report (06) tracks the total.
