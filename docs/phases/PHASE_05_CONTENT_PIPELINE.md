# Phase 5: Deck Content Pipeline (English source)

**Status:** 🚧 Pipeline and EN drafts complete (2026-09-28); owner review pending
**Depends on:** Phase 4
**Parallel with:** Phases 6–8 (the Worker consumes this phase's generated feed from Sprint 5.4)

---

## Overview

This phase builds the content pipeline from 01 §11: YAML source → validation → compiled per-locale JSON for the app, plus the Worker prompt feed. It authors the **English** source for all 78 cards, 6 spreads, the Learn articles, the FAQ and the crisis-resources directory.

Translation into the other 11 locales and native review happen in Phase 18, once the pipeline and the English voice are stable. Until the D15 art arrives, a generated typographic placeholder card is used everywhere, including tests and goldens.

**Output of this phase:**
- `docs/content/STYLE_GUIDE.md` and `docs/content/REVIEW_CHECKLIST.md`.
- `apps/taro/content/source/`: `glossary.yaml` (12 locales), `en/cards/*.yaml` ×78, `en/spreads.yaml`, `en/articles/*.md`, `crisis/crisis_resources.yaml`.
- `tools/content/` (`validate`, `build`, `translate`, `sync_check`) with tests.
- Generated assets:
  - `apps/taro/assets/deck/{deck_meta.json,en.json,spreads.json,crisis_resources.json}`;
  - `worker/src/generated/deck/{cards,spreads}.json`, `worker/src/generated/deck_prompt.en.json`, `worker/src/generated/crisis_resources.json`.
- Bundled-content repositories in `apps/taro/lib/data/content/` implementing `ContentRepository` and `CrisisResourcesRepository`.

Reconciled by 00_DECISIONS.md RC95: there is no content package; the authored source lives in `apps/taro/content/source/`, the generated app assets in `apps/taro/assets/deck/`, and the repositories in the app's `lib/data/content/`.

---

## Specs referenced

`01_PRODUCT.md` PR1, PR2, PR15, §7.5, §7.9, §10, §11, §13, §17.4. `02_ARCHITECTURE.md` AR15, §2.2 (`apps/taro/content/source/`, `assets/deck/`, `lib/data/content/`), §4 (`CardMeaning`), §11. `03_BACKEND_WORKER.md` §9.2 (card context), §9.5, cross-spec (deck sync). `05_COMPLIANCE_STORE_ASO.md` CS3, §4.2, §9.5, 4.1/5.2 row (art provenance). `00_DECISIONS.md` RC1, RC2, RC25, RC26, RC95.

---

## Sprint 5.1: Style guide, glossary, schemas

**Tasks:**
- [x] `docs/content/STYLE_GUIDE.md`: reflection voice (PR1), the banned-claims list (cross-link `tools/store_copy/banned_phrases.yaml`), length rules (01 §10.1), gender-neutral "you", no religious or medical claims, and how "future"/"outcome" positions are worded (01 §10.3). Evidence: `docs/content/STYLE_GUIDE.md` (voice, claims, bounds table, reversed/future wording) and `REVIEW_CHECKLIST.md`; owner sign-off is Batch 0 below.
- [x] `apps/taro/content/source/glossary.yaml`: card names ×78, suit names, position names and key terms in 12 locales (01 §11 step 2). EN is complete now; the other locales are drafted here and native-checked in Phase 18. The glossary must be 100% reviewed before any card translation. Evidence: 78 cards, 4 suits, 2 arcana, 22 positions, 36 terms × 12 locales, every locale `review.<locale>: machine` (EN awaits Batch 0 sign-off; the 11 others Phase 18); `validate` checks card names against it.
- [x] JSON Schemas `tools/content/schema/card.schema.json`, `spreads.schema.json`, `crisis.schema.json` (the `CardText` fields and bounds in 01 §10.1; the crisis schema per 03 §9.5 with `verifiedAt` per entry). Evidence: `tools/content/schema/{card,spreads,crisis}.schema.json` (Draft 2020-12), `tools/content/examples/card.example.yaml` conforms.
- [x] `docs/ART_PROVENANCE.md` stub (05 §1 row 4.1/5.2). It records the art source and licence per card once D15 delivers. Evidence: `docs/ART_PROVENANCE.md` (`placeholder` set and its project-owned pixel font recorded; D15 fields TBD).

---

## Sprint 5.2: Tooling (`tools/content`, Dart in `tools/dart_tools`)

**Tasks:**
- [x] `tools/content/validate`, run in CI and as a unit test. It checks:
  - every card × locale is present, with list and length bounds;
  - glossary names match exactly;
  - the per-locale forbidden-terms list (imports `banned_phrases.yaml`);
  - no Markdown or HTML in card text;
  - RTL control-character sanity for `ar`;
  - a `sourceHash` staleness report (en changed → locale flagged);
  - spread positions have x/y within 0..1 and no duplicate position IDs. Evidence: `tools/dart_tools/lib/src/content/validator.dart`; `validate_test.dart`; runs in `verify.sh` and `reusable-static.yml`.
- [x] `tools/content/build`: reads `apps/taro/content/source/` and compiles `apps/taro/assets/deck/{locale}.json` + `deck_meta.json` with a checksum, `apps/taro/assets/deck/spreads.json`, the Worker feeds (`worker/src/generated/deck/cards.json` with canonical EN names and upright/reversed keywords, `spreads.json` with position meanings, `deck_prompt.{locale}.json`), and `crisis_resources.json` for both the app asset (`apps/taro/assets/deck/crisis_resources.json`) and the Worker (`worker/src/generated/crisis_resources.json`) (RC25, RC26, RC95). The output is deterministic (sorted keys) and the build is idempotent. Evidence: `builder.dart`; two consecutive runs on 2026-09-29: "0 written, 0 deleted, 8 unchanged"; `build --check` in CI.
- [x] `tools/content/translate`: calls Claude with the style guide, glossary and EN source; writes YAML with `sourceHash` and `reviewStatus: machine`. Supports `--locale`, `--cards`, `--dry-run`. The API key comes from the environment, never the repo. The real network call is behind an interface; tests use a fake. Evidence: `translate.dart` + `claude_client.dart` (key from `ANTHROPIC_API_KEY`), refuses until `review.<locale>: reviewed`; `translate_test.dart` with a fake client.
- [x] `tools/content/sync_check`: the parity check between app assets and Worker feeds (replaces `tools/sync_deck`, RC26). It runs in `reusable-static.yml`. Evidence: `sync_check.dart`; wired in `reusable-static.yml` and `verify.sh`.
- [x] `check_l10n.py`: enable the deck-content completeness rule. Evidence: requires the 78 `en` cards and built `en.json`; untranslated locales are notices (`--require-all-locales` for Phase 18); `check_l10n: OK`.
- [x] Tests: `tools/dart_tools/test/content/{validate,build,translate,sync_check}_test.dart` with fixture sources covering each failure mode. Evidence: plus `rules_test`, `claude_client_test`, `placeholder_art_test`; 298 tests, dart_tools 99.41 %.

---

## Sprint 5.3: English content authoring *(owner + LLM-assisted, MANUAL review)*

**Tasks:**
Each card has: name, upright and reversed keywords (3–6 each), short upright and reversed texts (≤ 160 chars), long meanings (120–220 / 100–200 words), aspects (relationships, work, growth; 40–90 words each, upright and reversed), 3 reflection questions, imagery note, element and astrology keys. Workflow per batch: LLM draft → owner edit pass → `reviewStatus: reviewed`. Written against the original art's symbolism, not copied from any book (01 §11 step 3). **Done criteria for every batch below:** `tools/content/validate` green for the batch, every card `reviewStatus: reviewed`, and an owner edit pass recorded in `docs/content/AUTHORING_LOG.md` (date, cards, reviewer). Target dates per batch are recorded with the Phase 1 D15/content owner decision (about 58k reviewed EN words in total).

- [ ] Batch 0: `STYLE_GUIDE.md` and the EN glossary signed off by the owner (prerequisite for all batches). *(MANUAL, owner. LLM drafts of both files are done; see AUTHORING_LOG.)*
- [ ] Batch 1: Major Arcana, 22 cards (`major_00`–`major_21`). *(LLM drafts done 2026-09-28, `validate` green, `reviewStatus: machine`; owner edit pass pending.)*
- [ ] Batch 2: Wands, 14 cards. *(LLM drafts done 2026-09-28, `validate` green, `reviewStatus: machine`; owner edit pass pending.)*
- [ ] Batch 3: Cups, 14 cards. *(LLM drafts done 2026-09-28, `validate` green, `reviewStatus: machine`; owner edit pass pending.)*
- [ ] Batch 4: Swords, 14 cards. *(LLM drafts done 2026-09-28, `validate` green, `reviewStatus: machine`; owner edit pass pending.)*
- [ ] Batch 5: Pentacles, 14 cards. *(LLM drafts done 2026-09-28, `validate` green, `reviewStatus: machine`; owner edit pass pending.)*
- [x] `source/en/spreads.yaml`: 6 spreads with positions, layout coordinates, `rotationDeg` (Celtic Cross `challenge` = 90), when-to-use text, and suggestion-chip ARB keys (01 §10.2–10.3). Evidence: 6 spreads, 27 positions (1/3/3/5/5/10), Celtic Cross `challenge` `rotationDeg: 90`; LLM draft (`machine`). The 20 `spread_*_suggestion_*` ARB keys are a `validate` report until they are added to the ARBs.
- [ ] Batch 6: `source/en/articles/about.md` (About tarot & Taro, including how the AI works and its limits, 01 §7.9). *(LLM draft done 2026-09-28; owner edit pass pending.)*
- [ ] Batch 7: `source/en/articles/faq.md`. The FAQ covers: credits are not restorable after deleting the app, reinstall behaviour per platform, export/import, Delete my data, AI consent, Report a reading, and the Support ID (01 §9.5, 04 §12.9, 05 §9.6). *(LLM draft done 2026-09-28; owner edit pass pending.)*
- [x] `source/crisis/crisis_resources.yaml`: at least the 05 §4.2 set plus `international` (findahelpline.com). Every entry has `verifiedAt: null` until the owner verifies it in Phase 18.4. A test fails the **release** build (not dev) if any entry is unverified or older than 200 days (03 §9.5, BE Q3). Evidence: 18 entries incl. `international`, all `verifiedAt: null`; `validate --release` fails on unverified/over-200-day entries (`validate_test.dart`), dev only reports. Wiring `--release` into the release pipeline and the owner verification (Phase 18.4) are still to do.
- [x] `tools/content/validate` is green for `en`, with a staleness report of 11 locales × "missing" (expected until Phase 18). Evidence (2026-09-29): "content validate: OK (complete locales: en; 65 report item(s))": 11 locales missing, 20 chip ARB keys, 18 unverified crisis entries.

---

## Sprint 5.4: Content repositories (`apps/taro/lib/data/content/`) & placeholder art

**Tasks:**
- [x] In `apps/taro/lib/data/content/`: `AssetDeckRepository`, `AssetSpreadRepository`, `AssetMeaningRepository` (lazy per-locale JSON parse in `Isolate.run`, cached; 02 §17), `AssetCrisisResourcesRepository` (country → locale default → international, at most 3 entries). Together they implement `ContentRepository` and `CrisisResourcesRepository`. Evidence: `asset_{deck,spread,meaning,crisis_resources,content}_repository.dart`, `content_asset_store.dart`; DI in `lib/di/providers.dart`.
- [x] `ContentManifest`: verifies checksums at load and throws a `StorageFailure` on a mismatch. Evidence: `content_manifest.dart` (`ContentIntegrityException.failure` is a `StorageFailure`); `content_manifest_test.dart` "verify throws a StorageFailure-carrying exception on mismatch".
- [x] Placeholder art generator `tools/content/placeholder_art`: 78 typographic WebP cards (name + numeral + suit glyph) and a card back → `apps/taro/assets/deck/art/placeholder/`, with `artSet: placeholder`. Deterministic output. Evidence: `tools/dart_tools/lib/src/content/{placeholder_art,pixel_font}.dart`, `bin/placeholder_art.dart`, `tools/content/placeholder_art [--check]`; lossless WebP via the pure-Dart `image` encoder (no PNG fallback needed); `test/content/placeholder_art_test.dart`.
- [x] Tests: load the real assets through a test `AssetBundle` (78 cards, 6 spreads, crisis lookup), run the contract suites from `packages/taro_core/test/contracts/`, and check the checksum-mismatch path. Evidence: `apps/taro/test/data/content/{asset_content_repository,asset_crisis_resources_repository,content_manifest,content_assets}_test.dart` with `DiskAssetBundle`; `runContentRepositoryContract` (real `Isolate.run`) and `runCrisisResourcesRepositoryContract`; apps/taro 100 % lines.
- [x] Worker parity test stub: `worker/test/unit/content/deck_parity.test.ts` asserts that `deck_prompt.en.json` IDs equal `generated/deck/cards.json` IDs. The Worker suite owns it from Phase 8. Evidence: `worker/test/unit/content/deck_parity.test.ts` (3 tests; `npm run test:coverage` green).

---

## Done when

- [ ] `tools/content/validate` and `sync_check` are green in CI. The generated assets are committed and their builds reproducible (`git diff --exit-code` after a rebuild). *(Green locally in `verify.sh` and reproducible; waits for the first CI run after the commit.)*
- [x] `apps/taro` (incl. `lib/data/content/`) ≥ 90%, and `tools/dart_tools` ≥ 90% (`check_coverage.py`). Evidence: apps/taro 100 % (319/319), dart_tools 99.41 %, tools 99.52 %, worker 100 % (`verify.sh`, 2026-09-29).
- [x] Docs: STYLE_GUIDE, REVIEW_CHECKLIST, ART_PROVENANCE stub, and `docs/ARCHITECTURE.md` §Content pipeline. CHANGELOG updated. Evidence: `docs/ARCHITECTURE.md` "Content pipeline (Phase 5)"; `CHANGELOG.md` Unreleased.
- [ ] One commit: `feat(taro): Phase 5 — Deck content pipeline`.

## Next phase

Phase 11 (client data layer) on the client track. Phase 8 consumes the Worker feeds.
