# Phase 5: Deck Content Pipeline (English source)

**Status:** ⬜ Not Started
**Depends on:** Phase 4
**Parallel with:** Phases 6–8 (the Worker consumes this phase's generated feed from Sprint 5.4)

---

## Overview

This phase builds the content pipeline from 01 §11: YAML source → validation → compiled per-locale JSON for the app, plus the Worker prompt feed. It authors the **English** source for all 78 cards, 6 spreads, the Learn articles, the FAQ and the crisis-resources directory.

Translation into the other 11 locales and native review happen in Phase 18, once the pipeline and the English voice are stable. Until the D15 art arrives, a generated typographic placeholder card is used everywhere, including tests and goldens.

**Output of this phase:**
- `docs/content/STYLE_GUIDE.md` and `docs/content/REVIEW_CHECKLIST.md`.
- `packages/taro_content/source/`: `glossary.yaml` (12 locales), `en/cards/*.yaml` ×78, `en/spreads.yaml`, `en/articles/*.md`, `crisis/crisis_resources.yaml`.
- `tools/content/` (`validate`, `build`, `translate`, `sync_check`) with tests.
- Generated assets:
  - `packages/taro_content/assets/deck/{deck_meta.json,en.json}` and `assets/spreads/spreads.json`;
  - `worker/src/generated/deck/{cards,spreads}.json`, `worker/src/generated/deck_prompt.en.json`, `worker/src/generated/crisis_resources.json`.
- `taro_content` repositories implementing `ContentRepository` and `CrisisResourcesRepository`.

---

## Specs referenced

`01_PRODUCT.md` PR1, PR2, PR15, §7.5, §7.9, §10, §11, §13, §17.4. `02_ARCHITECTURE.md` AR15, §2.2 (`taro_content`), §4 (`CardMeaning`), §11. `03_BACKEND_WORKER.md` §9.2 (card context), §9.5, cross-spec (deck sync). `05_COMPLIANCE_STORE_ASO.md` CS3, §4.2, §9.5, 4.1/5.2 row (art provenance). `00_DECISIONS.md` RC1, RC2, RC25, RC26.

---

## Sprint 5.1: Style guide, glossary, schemas

**Tasks:**
- [ ] `docs/content/STYLE_GUIDE.md`: reflection voice (PR1), the banned-claims list (cross-link `tools/store_copy/banned_phrases.yaml`), length rules (01 §10.1), gender-neutral "you", no religious or medical claims, and how "future"/"outcome" positions are worded (01 §10.3).
- [ ] `packages/taro_content/source/glossary.yaml`: card names ×78, suit names, position names and key terms in 12 locales (01 §11 step 2). EN is complete now; the other locales are drafted here and native-checked in Phase 18. The glossary must be 100% reviewed before any card translation.
- [ ] JSON Schemas `tools/content/schema/card.schema.json`, `spreads.schema.json`, `crisis.schema.json` (the `CardText` fields and bounds in 01 §10.1; the crisis schema per 03 §9.5 with `verifiedAt` per entry).
- [ ] `docs/ART_PROVENANCE.md` stub (05 §1 row 4.1/5.2). It records the art source and licence per card once D15 delivers.

---

## Sprint 5.2: Tooling (`tools/content`, Dart in `tools/dart_tools`)

**Tasks:**
- [ ] `tools/content/validate`, run in CI and as a unit test. It checks:
  - every card × locale is present, with list and length bounds;
  - glossary names match exactly;
  - the per-locale forbidden-terms list (imports `banned_phrases.yaml`);
  - no Markdown or HTML in card text;
  - RTL control-character sanity for `ar`;
  - a `sourceHash` staleness report (en changed → locale flagged);
  - spread positions have x/y within 0..1 and no duplicate position IDs.
- [ ] `tools/content/build`: compiles `assets/deck/{locale}.json` + `deck_meta.json` with a checksum, `assets/spreads/spreads.json`, the Worker feeds (`worker/src/generated/deck/cards.json` with canonical EN names and upright/reversed keywords, `spreads.json` with position meanings, `deck_prompt.{locale}.json`), and `crisis_resources.json` for both the app asset and the Worker (RC25, RC26). The output is deterministic (sorted keys) and the build is idempotent.
- [ ] `tools/content/translate`: calls Claude with the style guide, glossary and EN source; writes YAML with `sourceHash` and `reviewStatus: machine`. Supports `--locale`, `--cards`, `--dry-run`. The API key comes from the environment, never the repo. The real network call is behind an interface; tests use a fake.
- [ ] `tools/content/sync_check`: the parity check between app assets and Worker feeds (replaces `tools/sync_deck`, RC26). It runs in `reusable-static.yml`.
- [ ] `check_l10n.py`: enable the deck-content completeness rule.
- [ ] Tests: `tools/dart_tools/test/content/{validate,build,translate,sync_check}_test.dart` with fixture sources covering each failure mode.

---

## Sprint 5.3: English content authoring *(owner + LLM-assisted, MANUAL review)*

**Tasks:**
Each card has: name, upright and reversed keywords (3–6 each), short upright and reversed texts (≤ 160 chars), long meanings (120–220 / 100–200 words), aspects (relationships, work, growth; 40–90 words each, upright and reversed), 3 reflection questions, imagery note, element and astrology keys. Workflow per batch: LLM draft → owner edit pass → `reviewStatus: reviewed`. Written against the original art's symbolism, not copied from any book (01 §11 step 3). **Done criteria for every batch below:** `tools/content/validate` green for the batch, every card `reviewStatus: reviewed`, and an owner edit pass recorded in `docs/content/AUTHORING_LOG.md` (date, cards, reviewer). Target dates per batch are recorded with the Phase 1 D15/content owner decision (about 58k reviewed EN words in total).

- [ ] Batch 0: `STYLE_GUIDE.md` and the EN glossary signed off by the owner (prerequisite for all batches).
- [ ] Batch 1: Major Arcana, 22 cards (`major_00`–`major_21`).
- [ ] Batch 2: Wands, 14 cards.
- [ ] Batch 3: Cups, 14 cards.
- [ ] Batch 4: Swords, 14 cards.
- [ ] Batch 5: Pentacles, 14 cards.
- [ ] `source/en/spreads.yaml`: 6 spreads with positions, layout coordinates, `rotationDeg` (Celtic Cross `challenge` = 90), when-to-use text, and suggestion-chip ARB keys (01 §10.2–10.3).
- [ ] Batch 6: `source/en/articles/about.md` (About tarot & Taro, including how the AI works and its limits, 01 §7.9).
- [ ] Batch 7: `source/en/articles/faq.md`. The FAQ covers: credits are not restorable after deleting the app, reinstall behaviour per platform, export/import, Delete my data, AI consent, Report a reading, and the Support ID (01 §9.5, 04 §12.9, 05 §9.6).
- [ ] `source/crisis/crisis_resources.yaml`: at least the 05 §4.2 set plus `international` (findahelpline.com). Every entry has `verifiedAt: null` until the owner verifies it in Phase 18.4. A test fails the **release** build (not dev) if any entry is unverified or older than 200 days (03 §9.5, BE Q3).
- [ ] `tools/content/validate` is green for `en`, with a staleness report of 11 locales × "missing" (expected until Phase 18).

---

## Sprint 5.4: `taro_content` package & placeholder art

**Tasks:**
- [ ] `AssetDeckRepository`, `AssetSpreadRepository`, `AssetMeaningRepository` (lazy per-locale JSON parse in `Isolate.run`, cached; 02 §17), `AssetCrisisResourcesRepository` (country → locale default → international, at most 3 entries). Together they implement `ContentRepository` and `CrisisResourcesRepository`.
- [ ] `ContentManifest`: verifies checksums at load and throws a `StorageFailure` on a mismatch.
- [ ] Placeholder art generator `tools/content/placeholder_art`: 78 typographic WebP cards (name + numeral + suit glyph) and a card back → `packages/taro_content/assets/art/placeholder/`, with `artSet: placeholder`. Deterministic output.
- [ ] Tests: load the real assets through a test `AssetBundle` (78 cards, 6 spreads, crisis lookup), run the contract suites from `taro_testing`, and check the checksum-mismatch path.
- [ ] Worker parity test stub: `worker/test/unit/content/deck_parity.test.ts` asserts that `deck_prompt.en.json` IDs equal `generated/deck/cards.json` IDs. The Worker suite owns it from Phase 8.

---

## Done when

- [ ] `tools/content/validate` and `sync_check` are green in CI. The generated assets are committed and their builds reproducible (`git diff --exit-code` after a rebuild).
- [ ] `taro_content` ≥ 90%, and `tools/dart_tools` ≥ 90% (`check_coverage.py`).
- [ ] Docs: STYLE_GUIDE, REVIEW_CHECKLIST, ART_PROVENANCE stub, and `docs/ARCHITECTURE.md` §Content pipeline. CHANGELOG updated.
- [ ] One commit: `feat(taro): Phase 5 — Deck content pipeline`.

## Next phase

Phase 11 (client data layer) on the client track. Phase 8 consumes the Worker feeds.
