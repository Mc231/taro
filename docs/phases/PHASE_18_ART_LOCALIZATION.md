# Phase 18: Deck Art & Full Localization (12 locales)

**Status:** ⬜ Not Started
**Depends on:** Phase 5 (pipeline + EN source), Phase 13 (ARB keys), Phase 16. The UI strings must be stable, so Sprint 18.2 starts after Phase 17 is feature-complete.
**Parallel with:** Phase 17 (Sprints 18.1 and 18.3 can start earlier)

---

## Overview

This phase covers the two content workstreams that make Taro distinct (PR2) and that App Review looks at:
1. **Original deck art** (D15): import, optimise, provenance, and replacing the placeholders.
2. **Full localization**: UI ARB strings in 11 more locales, deck content (78 cards × 11 locales), articles, FAQ, the Worker safety lexicons, and store-facing helper strings.

It also includes native review to the 01 §11 launch gate, and verification of the crisis-line numbers (BE Q3).

**Output of this phase:**
- `packages/taro_content/assets/art/<art_set>/` with 78 cards + card back (WebP @2x/@3x, ≤ 150 KB @3x per card), `artSet` switched from `placeholder`, and `docs/ART_PROVENANCE.md` complete.
- `app_{ar,de,es,fr,it,ja,ko,nl,pt,tr,uk}.arb` fully translated. No `x-translate` markers remain outside the allowlist.
- `packages/taro_content/source/{locale}/**` for 11 locales, with the launch gate met (§11 step 6) and `worker/src/generated/deck_prompt.{locale}.json` regenerated.
- `worker/safety/lexicons/<locale>.json` ×12 native-reviewed.
- `crisis_resources.yaml` with every entry verified (`verifiedAt` set).

---

## Specs referenced

`01_PRODUCT.md` PR2, PR15, §10.1, §11 (steps 2–8), §13, §16 (install size), §18 risks, Q5. `02_ARCHITECTURE.md` AR15, §11, §17 (art budget). `03_BACKEND_WORKER.md` §9.4 (lexicons), §9.5, BE-R6, Q3. `05_COMPLIANCE_STORE_ASO.md` 4.1/5.2 row, §4.2, §6.1 (art rules), CS13. `06_QUALITY_TESTING_CI.md` §3.1, §6.2 (`check_l10n.py`), §12 (reviewed translations). `../CONTEXT.md` D14, D15. `00_DECISIONS.md` RC1, RC25, RC26.

---

## Sprint 18.1: Deck art (D15) *(MANUAL art production + scripted import)*

**Tasks:**
- [ ] Receive the art per the Phase 1 decision: 78 cards + card back, consistent visual language, symbolic rather than gory (Death, Devil, Tower), not child-oriented, and no Rider-Waite-Smith scans or trademarks (05 §6.1, 4.1/5.2 row).
- [ ] `tools/content/import_art`: validates the file set (78 + back), aspect ratio (`size.card.aspectRatio`), size budget (≤ 150 KB @3x; the 02 §17 budget is the stricter of 01 and 02), WebP conversion, and `cacheWidth` hints. It writes `assets/art/<art_set>/` and updates `deck_meta.json` `artSet`. Tests use a fixture art set.
- [ ] `docs/ART_PROVENANCE.md`: source, tool and licence per card; commercial-use confirmation.
- [ ] `imageryNote` in the EN card YAML is updated to match the final art symbolism (01 §10.1); re-run `validate` + `build`.
- [ ] CI install-size report: the iOS download is ≤ 60 MB and each Android per-ABI AAB split ≤ 40 MB (01 §16, 02 §17). Add it to `nightly.yml`.
- [ ] Regenerate **all** goldens once with the final art (06 risks: one bulk commit).

---

## Sprint 18.2: UI string translation (ARB)

**Tasks:**
- [ ] Machine-translate `app_en.arb` into 11 locales with the glossary and style guide (`tools/content/translate --arb`). Keep the ICU plural and select structure; `pt` = pt-BR tone (02 Open question 8).
- [ ] Compliance strings (05 §3 keys, refusal, crisis, disclaimer, AI consent, paywall disclosures, ATT pre-prompt, `NSUserTrackingUsageDescription` via `ios/Runner/<locale>.lproj/InfoPlist.strings`) get **native review in all 12 locales** before release *(MANUAL, reviewers)*.
- [ ] `check_l10n.py` in strict mode: no `x-translate` markers left, placeholders identical, no non-EN value equal to EN outside `tools/l10n_untranslated_allowlist.yaml`.
- [ ] Re-run the 12-locale smoke test, the text-expansion goldens (`de`), CJK line breaking (`ja`) and the RTL goldens (`ar`).

---

## Sprint 18.3: Deck content translation & native review (01 §11)

**Tasks:**
- [ ] Glossary: native check for all 11 locales. The glossary must be 100% reviewed before step 4 (01 §11 step 2) *(MANUAL)*.
- [ ] `tools/content/translate` for 78 cards × 11 locales, plus spreads, articles (About, FAQ) and crisis descriptions. The output carries `sourceHash` and `reviewStatus: machine`.
- [ ] LLM self-review pass on every machine text (01 Q5), producing a findings report in `docs/content/reviews/<locale>.md`.
- [ ] **Launch gate** (01 §11 step 6) *(MANUAL, reviewers)*:
  - all 22 Major Arcana, and all names, keywords and short meanings, `reviewed` in all 12 locales;
  - minor long texts ≥ 20% sampled per locale, the rest `machine` + self-review.
  - `tools/content/validate --launch-gate` enforces this.
- [ ] `tools/content/build` → the per-locale app assets and `deck_prompt.{locale}.json`. Run the Worker parity test. Deploy to staging.
- [ ] Re-run the Worker quality eval (Phase 8.6) across the 12 locales with the localized deck names. The language-correctness score must not regress.

---

## Sprint 18.4: Safety lexicons & crisis resources *(MANUAL verification)*

**Tasks:**
- [ ] Native review of `worker/safety/lexicons/<locale>.json` for the 11 non-EN locales: L1 crisis patterns (high precision) and the L3 forbidden-claims list (BE-R6). Bump the lexicon version and re-run the safety regression corpus plus `eval:safety` on staging.
- [ ] The owner verifies every crisis-resource entry against its official source (05 §4.2 minimum set + `localeFallback`), sets `verifiedAt`, and records the sources in `docs/content/CRISIS_SOURCES.md` (BE Q3). The 200-day staleness test goes green in release mode.
- [ ] The `banned_phrases.yaml` per-locale table (05 §9.5) is reviewed by native speakers. `check_store_copy.py` is re-run over the ARB files and deck content.

---

## Done when

- [ ] `tools/content/validate --launch-gate`, `check_l10n.py` (strict), `check_store_copy.py` and `sync_check` are green.
- [ ] Coverage: `taro_content`, `taro_l10n`, `tools/dart_tools` and `worker` are still ≥ 90%. All goldens are regenerated with the final art and green.
- [ ] The eval and safety reports for all 12 locales pass on staging and are committed.
- [ ] Docs: ART_PROVENANCE, CRISIS_SOURCES, the content review reports, CHANGELOG.
- [ ] One commit: `feat(taro): Phase 18 — Deck art & full localization`.

## Next phase

Phase 19: Compliance, Accessibility & Performance Hardening.
