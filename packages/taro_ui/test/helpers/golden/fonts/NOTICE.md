# Golden test fonts

Test-only fonts for `loadTaroTestFonts()` (06 QA8). They are never bundled into
the app. All four are licensed under the SIL Open Font License 1.1 (`OFL.txt`).

| File | Source (github.com/google/fonts, `main`, 2026-09-28) | Processing |
|---|---|---|
| `NotoSans-Regular.ttf` | `ofl/notosans/NotoSans[wdth,wght].ttf` | instanced at `wght=400`, `wdth=100`; full cmap (Latin, Greek, Cyrillic) |
| `NotoSansArabic-Regular.ttf` | `ofl/notosansarabic/NotoSansArabic[wdth,wght].ttf` | instanced at `wght=400`, `wdth=100`; full cmap |
| `NotoSansJP-Regular.ttf` | `ofl/notosansjp/NotoSansJP[wght].ttf` | instanced at `wght=400`; subset to ASCII, Latin-1, punctuation, CJK symbols, kana, half/full-width forms and the 6,355 JIS X 0208 kanji |
| `NotoSansKR-Regular.ttf` | `ofl/notosanskr/NotoSansKR[wght].ttf` | instanced at `wght=400`; subset to ASCII, Latin-1, punctuation, Hangul Jamo, compatibility Jamo and the 2,350 KS X 1001 syllables |

The subsets keep the repository small (about 4.3 MB instead of 23 MB). Recipe
(fontTools 4.x): `fontTools.varLib.instancer.instantiateVariableFont(font,
{'wght': 400, 'wdth': 100})`, then `fontTools.subset` with
`layout_features=['*']` over the code points above (JIS X 0208 kanji = the
U+4E00–U+9FFF code points that encode to two bytes in `shift_jis`; KS X 1001
syllables = the U+AC00–U+D7A3 code points that encode to two bytes in
`euc_kr`). A glyph outside a subset renders as a box in a golden; widen the
subset with the same recipe if a locale's content needs it.

The family names are unchanged; no Reserved Font Name (`Source`) is used.
