# Phase 14: Claude Design Handoff

**Status:** ✅ Complete (2026-09-27), run early right after Phase 1 at the owner's request (the design needs only the specs). Owner signed `docs/design/REVIEW.md` on 2026-09-28.
**Depends on:** Phase 1 (token contract reconciled, RC15), Phase 13 Sprint 13.4 (state inventory frozen)
**Parallel with:** Phase 13 (Sprints 13.5–13.6), the D15 art pipeline, Phases 9–10

---

## Overview

The UI is designed in **Claude Design** (D16), not in code. This phase does four things:
1. packages the design brief from the product spec (design-token contract 01 §14, screen inventory 01 §8, state inventory from Phase 13, compliance rules on screens from 04 §11 and 05 §9.5);
2. runs the design sessions;
3. reviews the output against accessibility, compliance and dark-pattern rules;
4. lands the deliverables in the repo as **data**: the tokens JSON, per-screen specs and exported reference images.

No Flutter UI code is written here. Phases 15–17 implement from these deliverables.

**Output of this phase:**
- `docs/design/BRIEF.md`: the handoff brief given to Claude Design.
- `docs/design/taro.tokens.json`: W3C DTCG tokens, light and dark, with every token name in 01 §14 (RC15).
- `docs/design/screens/S01…S33/`: one folder per screen with the exported reference frames for every ★ state (light/dark, plus `ar` for S05, S08, S09 and S14) and a `spec.md` (layout notes, components used, motion, semantics order).
- `docs/design/components.md`: the component inventory mapped to `taro_ui` names (02 §14.3).
- `docs/design/assets/`: card back, spread layout diagrams, empty-state illustrations (Journal, search), app icon (1024 master + adaptive Android layers), splash.
- `docs/design/REVIEW.md`: the signed-off review checklist.

---

## Specs referenced

`01_PRODUCT.md` PR2, PR13, PR16, PR17, §4.1, §8, §12, §13, §14 (full token contract), §14.5 (deliverables). `02_ARCHITECTURE.md` AR16, §14 (as reconciled by RC15). `04_MONETIZATION.md` §8 (banner slot rules, `space.adGap` ≥ 16 dp, RC59), §11 (paywall rules), MO13, MO18. `05_COMPLIANCE_STORE_ASO.md` CS3, CS6, CS13, §3 (disclaimer placement), §6.1 (art: symbolic, not gory, not child-oriented), §9.5 (banned UI patterns). `06_QUALITY_TESTING_CI.md` §3 (golden list). `00_DECISIONS.md` RC15, RC18–RC20, RC24.

---

## Sprint 14.1: Brief preparation

**Tasks:**
- [x] Write `docs/design/BRIEF.md`: _Done. Uses 01 §8.3 as the state inventory until Phase 13.4 refines it._
  - **Product:** positioning and tone (PR1, 01 §4), personas (01 §5), the differentiation table (01 §4.1).
  - **Platform constraints:** universal: iPhone portrait + iPad with constrained content width (RC24); Android phones and tablets with `layout.maxContentWidth`; 4 tabs (RC17).
  - **Token contract:** the full 01 §14 name list, the constraints (contrast ≥ 4.5:1 and 3:1, body ≥ 16 sp, caption ≥ 12 sp, touch ≥ 48 dp, reading line ≤ 70 chars), fonts per script (Latin, Cyrillic, Arabic, CJK, Hangul) bundled offline (01 §13), motion tokens + reduced-motion values (01 §14.4), and haptics.
  - **Screen list:** S01–S33 with states from `docs/design/STATE_INVENTORY.md`, ★ goldens marked.
  - **Hard rules:**
    - banners only on S05, S14 and S16, in a separate container ≥ `space.adGap` (16 dp) from any tap target, never over content (RC18, RC59, MO11);
    - the disclaimer footer on every reading state; the "AI-generated" label on AI readings; the Classic reading variant (RC20);
    - consent buttons of equal visual weight (CS6);
    - the paywall shows close, restore, terms, privacy and the non-restorable line, with no pre-selection, no fake urgency, no blurred reading behind the paywall, and the free path always visible (04 §11, 05 §9.5);
    - crisis screen: calm, no ads, no upsell;
    - RTL mirroring rules (card art never mirrored; 01 §13);
    - reversed shown by rotation **and** a text label (01 §12);
    - art symbolic, not gory, not child-oriented (05 §6.1).
  - **Deliverables list** (01 §14.5), with file formats and naming.
- [x] Attach the real content samples: _Done in `docs/design/samples/` (cards_en.md, readings/{single,three_ppf,relationship,celtic_cross}.json, strings_de_longest.md, samples_ar_ja.md). Readings are hand-written to the 03 wire format; swap for Phase 8.6 staging outputs later._ EN card texts for 5 cards, a sample AI reading JSON for each spread size, the longest `de` strings (the +40% expansion test), and the `ar` and `ja` samples. Phase 14 does **not** wait for Phase 8: the reading samples come from the `FakeAiProvider` fixtures in `worker/test/fixtures/readings/` (realistic lengths per 01 §7.4) and are swapped for Phase 8.6 staging outputs when available, before the S09 designs are signed off.
- [x] Owner review of the brief *(MANUAL)*. _Owner approved the design system and screens in chat, 2026-09-27._

---

## Sprint 14.2: Design sessions in Claude Design *(MANUAL, owner-driven)*

**Tasks:**
- [x] Session 1, the **design system** (_https://claude.ai/artifact/C94hpvYCJKqrqYn5o8VnRb_): colour (light and dark), typography per script, spacing, radius, elevation, motion, the component set (buttons, fields, sheets, dialogs, card face/back/flip, spread canvas, reading text view, list rows, balance pill, badge, countdown text, banner container, state views).
- [x] Session 2, **core flow screens** (_canvas https://claude.ai/artifact/1d29x21T1WhcFhFaeo3QxL_): S01–S09, S13, S27, S31, and the Classic reading. The draw ritual (S08) covers the shuffle, fan/pick, reveal, awaiting-reading keyword view and reduced-motion variants.
- [x] Session 3, **monetization and supporting screens**: S10–S12, S14–S26, S28–S30, plus the ATT neutral pre-prompt and the Report sheet.
- [x] Session 4, **assets** (_`docs/design/assets/`; final 78-card art stays in Phase 18_): the card back, spread layout diagrams ×6, empty-state illustrations, app icon, splash, store screenshot frame template (used in Phase 20; captions follow CS13).
- [x] Export the tokens as DTCG JSON → `docs/design/taro.tokens.json`. Export the frames → `docs/design/screens/**`.

---

## Sprint 14.3: Review & sign-off

**Tasks:**
- [x] ~~`tools/tokens/validate_tokens.dart`~~ _Moved to Phase 15 Sprint 15.1 (no Dart tooling before Phases 2–3). The same checks ran as a script: all 01 §14 names, both modes, reduced motion, 44 contrast pairs pass (REVIEW K-section)._: every 01 §14 token name exists in both modes. Check the contrast pairs (`color.text.primary`/`secondary` on `bg.canvas` and `bg.surface` ≥ 4.5:1; `border.focus` ≥ 3:1; `status.*` on-pairs), and the reduced-motion values exist. Run it in CI from now on.
- [x] `docs/design/REVIEW.md` checklist (97 items: 82 PASS, 15 derived in code, 0 FAIL after fixes). _Signed by the owner 2026-09-28._ It covers:
  - every ★ state exists in light and dark, and in `ar` where required;
  - the banned patterns (05 §9.5) are absent;
  - paywall and consent rules;
  - banner placement;
  - text scale 200% layouts for S05, S09 and S13 (01 §12);
  - touch targets;
  - RTL mirrors;
  - screenshot frames 1–3 contain no Death, Devil or Tower close-ups (CS13).
- [x] Map each designed component to a `taro_ui` class name in `docs/design/components.md`. Mark any new component not in 02 §14.3 and add it to the Phase 15 task list.
- [x] Any token **name** change _(none needed: fixes were to the export, which now matches the 01 §14 names)_ needed by the design is a spec change: edit 01 §14 + `00_DECISIONS.md` in the same commit (the contract is names, not values).

---

## Done when

- [x] All deliverables are present under `docs/design/`. _(validate_tokens.dart → Phase 15.1; REVIEW signature pending)_ `validate_tokens.dart` is green. REVIEW.md is signed.
- [x] Coverage: n/a in this phase (no Dart code yet; validator moved to Phase 15). `tools/dart_tools` stays ≥ 90% with the token validator tests. No app code changes.
- [x] Docs: BRIEF, REVIEW, components.md; (`docs/ARCHITECTURE.md` does not exist until Phase 2, which must point its Design tokens section at `docs/design/taro.tokens.json`) `docs/ARCHITECTURE.md` §Design tokens points to the file.
- [x] One commit: `docs(taro): Phase 14 — Claude Design handoff`.

## Next phase

Phase 15: Design System Implementation.
