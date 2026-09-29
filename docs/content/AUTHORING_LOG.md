# Content authoring log

One row per authoring or review pass over deck content (Phase 5 Sprint 5.3,
Phase 18). Append rows at the bottom; never edit or delete earlier rows.

- **date:** `YYYY-MM-DD` of the pass.
- **batch:** `glossary`, `style_guide`, `0`–`7` (Phase 5 Sprint 5.3 batches), `spreads`, `crisis`, or `phase18-<locale>`.
- **cards:** card IDs or ranges (`major_00`–`major_21`, `cups_01`–`cups_14`), or the file(s) touched.
- **author:** `LLM draft` (an LLM wrote or translated it) or `owner` / `native reviewer (<locale>)` (a person edited and reviewed it).
- **reviewStatus:** the value the pass left in the files: `machine` (LLM draft, not yet reviewed) or `reviewed`.

Done criteria per batch (PHASE_05 Sprint 5.3): `tools/content validate` green for the batch, every card `reviewed`, and an `owner` row here.

| date | batch | cards | author | reviewStatus |
|---|---|---|---|---|
| 2026-09-29 | glossary | `apps/taro/content/source/glossary.yaml` (78 cards, suits, arcana, 22 positions, key terms; 12 locales) | LLM draft | machine |
| 2026-09-29 | style_guide | `docs/content/STYLE_GUIDE.md`, `docs/content/REVIEW_CHECKLIST.md` | LLM draft | machine |
| 2026-09-28 | spreads, 6, 7, crisis | `en/spreads.yaml` (6 spreads), `en/articles/about.md`, `en/articles/faq.md`, `crisis/crisis_resources.yaml` (16 countries + international, all `verifiedAt: null`) | LLM draft | machine |
| 2026-09-28 | 2 | `wands_01`–`wands_14` | LLM draft | machine |
| 2026-09-28 | 4 | `swords_01`–`swords_14` (`apps/taro/content/source/en/cards/`) | LLM draft | machine |
| 2026-09-28 | 5 | `pentacles_01`–`pentacles_14` (`apps/taro/content/source/en/cards/`) | LLM draft | machine |
| 2026-09-28 | 3 | `cups_01`–`cups_14` (`apps/taro/content/source/en/cards/cups_*.yaml`) | LLM draft | machine |
| 2026-09-28 | 1 | `major_00`–`major_21` (`apps/taro/content/source/en/cards/major_*.yaml`) | LLM draft | machine |
| 2026-09-29 | 1–7, spreads | all 78 `en/cards/*.yaml`, `en/spreads.yaml`, `en/articles/*.md`: LLM QA pass (US spelling, 23 templated growth openers varied, `swords_10` short text and keyword softened; 6-gram overlap between any two cards' long texts ≤ 12 %) | LLM draft | machine |
