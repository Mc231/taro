# Phase 23: Post-Launch v1.1 — Widget, Share Images & ASO Iteration

**Status:** ⬜ Not Started (post-launch; **Sprint 23.1 is pulled forward if the 1.0 review rejects under 4.3**, see Phase 22)
**Depends on:** Phase 22 (or Phase 21 if it is triggered as a 4.3 escalation)

---

## Overview

This phase delivers the committed v1.1 backlog from 01 §6.2:
- the home-screen daily-card widget (PR11);
- share-as-image cards (PR19 follow-up);
- two extra spreads (Horseshoe 7, Year Ahead 12).

It also runs the 4- and 8-week ASO reads with `portfolio-audit`, and re-evaluates the monetization open questions against real data (subscriptions MO Q1, interstitials MO Q2, Play Integrity device recall MO Q5, Apple consumption info BE Q4).

The widget adds native code (WidgetKit / Glance). It gets its own coverage units, following RC40.

**Output of this phase:**
- The `DailyCardWidgetBridge` port (added to `taro_core` now, not in v1, RC89), its prod adapter (`home_widget`, added to 02 §18 now) and native widgets: iOS WidgetKit extension `TaroWidget` (small + medium) and Android Glance `DailyCardWidget`. They read the daily-card data written by the app; there is no network access from the widget. Native tests are gated at ≥ 90%.
- Share images: a `ShareCardRenderer` (offscreen `RepaintBoundary` → PNG) with the final art, the disclaimer line and an optional question.
- Spreads `horseshoe_7` and `year_ahead_12` in the content YAML, ARB strings, Worker spreads feed and `ai.maxTokensBySpread`.
- ASO iteration rows in `docs/aso/ASO_TRACKER.md` and a v1.1 decision memo in `00_DECISIONS.md`.

---

## Specs referenced

`01_PRODUCT.md` PR4, PR11, PR19, §6.2, Q2. `02_ARCHITECTURE.md` Open question 7 (`home_widget`, `DailyCardWidgetBridge`), §18. `05_COMPLIANCE_STORE_ASO.md` CS17, §9.3 rotation pool, §9.7. `04_MONETIZATION.md` §17 Q1, Q2, Q5. `03_BACKEND_WORKER.md` Q2, Q4. `06_QUALITY_TESTING_CI.md` QA1 (native units, per RC40). `00_DECISIONS.md` RC40.

---

## Sprint 23.1: Home-screen widget (PR11)

**Tasks:**
- [ ] Add the `DailyCardWidgetBridge` port to `taro_core` (with its Fake and contract suite in `packages/taro_core/test/fakes/` and `test/contracts/`, RC95) and the `home_widget` dependency (RC89).
- [ ] `apps/taro/lib/services/widget/home_widget_bridge.dart` implements `DailyCardWidgetBridge` (writes the card ID, orientation, localized name, short meaning and art key to App Group / SharedPreferences storage on daily-card draw and on locale change). Tested with the `home_widget` platform fake.
- [ ] iOS: add a WidgetKit extension target `TaroWidget` (small + medium) with an App Group, the art from a shared asset catalog, "Draw today's card" when not drawn, and a deep link to `taro://daily`. XCTest for the timeline provider.
- [ ] Android: Glance `DailyCardWidget` with the same states. JUnit/Robolectric tests.
- [ ] Add the native coverage units `taro_widget_ios` and `taro_widget_android` to `check_coverage.py`.
- [ ] Ensure there is no ad in the widget (04 §8). Add widget screenshots to the store assets (optional frame 8).

---

## Sprint 23.2: Share images & new spreads

**Tasks:**
- [ ] `ShareCardRenderer`: a designed share card (template from Claude Design), localized, RTL-aware, with the disclaimer footer (05 §3 `disclaimerShort`) and no question unless the toggle is on. Goldens in light/dark × en/ar.
- [ ] Spreads `horseshoe_7` and `year_ahead_12`: authored positions and layouts; ARB strings in 12 locales; `tools/content build`; Worker `ai.maxTokensBySpread` entries; an eval run for the new spreads; the `SpreadCanvas` layout goldens.
- [ ] Store copy: add the new spreads to the descriptions only after they ship (05 §8.1 rule).

---

## Sprint 23.3: ASO & monetization iteration (CS17)

**Tasks:**
- [ ] Weekly for 8 weeks:
  - `portfolio.py summary --app taro`;
  - `snapshot fetch --report discovery`;
  - `snapshot fetch --report downloads --group-by "Source Type"`;
  - `ga4 retention --app taro`;
  - `admob <csv>`;
  - Play acquisition read manually.
- [ ] Week-4 and week-8 reads using the Blocks decision rules (05 §9.7): if impressions are up but downloads are flat, iterate screenshot 1; if one locale is flat, swap its 5 weakest keywords from the rotation pool; if everything is flat, go further into the long tail. There is no icon change in the same release as a keyword change. Every change gets a row in `ASO_TRACKER.md`.
- [ ] Decision memo against the 04 §14 KPIs:
  - subscriptions ("Taro Plus", MO Q1, would need asa ASA-8);
  - interstitials (MO Q2, only via a spec amendment);
  - Play Integrity device recall (MO Q5);
  - Apple consumption info (BE Q4);
  - prompt A/B (BE Q2);
  - free-reading model (BE Q1 revisit).
  - Record it in `00_DECISIONS.md`.

---

## Done when

- [ ] v1.1 is released through the same pipeline (Phases 21–22 checklists, abbreviated to the changed areas + the full safety eval).
- [ ] All units, including the new native widget units, are ≥ 90%.
- [ ] Docs: ARCHITECTURE (widget), ANALYTICS_EVENTS (widget and share events), ASO_TRACKER, CHANGELOG `[1.1.0]`.
- [ ] One commit: `feat(taro): Phase 23 — v1.1 widget, share images & spreads`.
