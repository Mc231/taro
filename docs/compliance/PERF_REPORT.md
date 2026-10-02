# Performance report (Phase 19.5)

Budgets: 01 §16 and 02 §17. Phase 19 enforces them on profile builds on mid-tier devices (Pixel 6a, iPhone 12). This report holds the automated part, which runs on the simulator. The device runs are **MANUAL**, and their rows are left open below.

## 1. Automated timeline (iOS simulator, 2026-10-02)

Commands: `cd apps/taro && flutter test integration_test/perf -d <sim> --flavor dev --dart-define-from-file=config/dev.json --dart-define=TARO_ENV=test`. Both tests passed, and the numbers come from the `PERF …` lines. Device: iPhone 16e simulator (iOS 26.2) on an Apple Silicon host. Build: a debug JIT build at HEAD `86a1f55`.

**Why not profile mode:** Flutter refuses profile and release builds on the iOS simulator (`flutter run --profile` → "Profile mode is not supported by iPhone 16e"). The only physical iOS device on hand (an iPad, paired over the network) is not in Developer Mode. Simulator numbers are therefore a debug regression baseline, not budget evidence. Profile on a device is the MANUAL step in §3.

| Measure | 2026-10-02 (iPhone 16e sim, debug) | 2026-09-30 baseline (iPhone 17 Pro sim, debug, min–max) | Budget (profile, device) |
|---|---|---|---|
| cold start: `bootstrap()` done | 268 ms | 258–288 ms | — |
| cold start: first frame rasterized | 661 ms | 573–601 ms | ≤ 1.5 s (plus engine start before `main`) |
| cold start: first screen (S02, fresh install) | 665 ms | 577–605 ms | interactive Home ≤ 2.0 s |
| S08 ritual: frames | 40 | 16–17 | — |
| S08 build avg / p90 / p99 / worst | 5.6 / 11.1 / 64.0 / 64.0 ms | 3.8–4.9 / 10.0–21.2 / — / 28.1–31.6 ms | p90 < 8 ms |
| S08 missed build budget (16 ms) | 3 | 1–3 | 0 jank frames |
| S08 raster avg / p90 / worst | 1.0 / 1.7 / 2.9 ms (0 missed) | 0.9–1.4 / 1.5–2.1 / 2.2–7.2 ms | p90 < 8 ms |

Reading the numbers:

- **Cold start** in debug sits well inside the budget even though JIT is slower than AOT. It does not include engine start before `main`, so the device run must time from process start (the `Flutter first frame` log line, or Xcode Instruments "App Launch").
- **S08**: raster is far inside the budget. Build p90 is 11 ms in debug, and the three missed frames are the screen transitions and the reveal (36 ms, 22 ms, 64 ms in `frame_build_times`). JIT build times run several times slower than AOT, so this does not show a profile regression. The device profile run decides it. If a device still shows the reveal frame over 16 ms, look first at the `CardArt.face` decode on reveal: the art is precached on S07 (02 §17), so check that the reveal path hits the cache.
- The frame count went from 16–17 to 40 since 09-30. The new card-back art and precache (`cdde7c5`, `86a1f55`) add animated frames to the ritual, and the averages did not rise.

## 2. Static budget checks

| Budget | Status | Evidence |
|---|---|---|
| No DB queries on the UI isolate | Pass (code) | `data/db/database_location.dart`: `driftDatabase(…, native: DriftNativeOptions(shareAcrossIsolates: true))`, a drift background isolate (02 §6.1). Content JSON is parsed in `Isolate.run` (`AssetMeaningRepository`). |
| Art decode sizes | Pass (code) | `CardArt.cacheWidthOf(context, …)` on the draw panes (`draw_panes.dart`) and the deck browser. The card back decodes via `ResizeImage` at `size.card.sm` (`TaroCardBack`). `import_art --check` enforces ≤ 150 KB per file @3x. |
| Install size ≤ 60 MB iOS / ≤ 40 MB per ABI | MANUAL / nightly | `tools/check_install_size.py` in the nightly `install-size` job (prod builds). Bundled assets are 22 MB (the `codex_v1` art is 16.3 MB of that). Read the latest nightly summary before Phase 21. |

## 3. MANUAL device runs (open)

- [ ] iPhone 12 (or the nearest mid-tier iPhone), profile build: `flutter drive --profile --flavor dev --dart-define-from-file=config/dev.json --dart-define=TARO_ENV=test --driver=<integration_test driver> --target=integration_test/perf/draw_screen_perf_test.dart`, and the same for `cold_start_test.dart`. Also time a cold launch from process start in Instruments "App Launch" (first frame ≤ 1.5 s, Home ≤ 2.0 s).
- [ ] Pixel 6a, profile build: the same two tests, plus `adb shell am start -W` for `TotalTime`.
- [ ] Ritual animations p90 < 8 ms and 0 jank frames on both devices. Check reduced motion as well.
- [ ] Record the device numbers in this file and in `docs/ARCHITECTURE.md` §Integration flows and performance baseline.

## 4. Reading latency (p50 ≤ 8 s, p95 ≤ 20 s per spread size)

**No latency data yet. Sample size 0.** The Phase 19 eval runs in `worker/evals/reports/` (2026-09-30 and 2026-10-01, OpenAI `gpt-6-luna` and `gpt-6.1-sol`, about 4 000 graded cases) record outputs and grader verdicts per case, but not request timing. `evals/lib/live.ts` does not measure latency. So the reports cannot give p50/p95 per spread. They also run the safety probe set rather than real spreads.

Where the numbers do exist, to read on staging (orchestrator or owner; read-only, no config change):

- **D1 `readings.latency_ms` by `spread_id`** (written by `ReadingService` for every completed reading, kept until the daily retention purge). No `wrangler` command is listed here, because it would need the owner's Cloudflare credentials. The query, run against the staging database, is:
  `SELECT spread_id, latency_ms FROM readings WHERE status = 'completed' AND latency_ms IS NOT NULL AND created_at > '<since>' ORDER BY spread_id, latency_ms;`
  Then take the 50th and 95th percentile per `spread_id` and note n per spread. Use n ≥ 20 per spread before you trust a p95.
- **Analytics Engine `reading_completed.latencyMs`** (`double2`) has no spread column (03 §14.1 blob layout), so it gives only an overall or per-model distribution.
- The staging smoke (`npm run smoke -- --env staging`) prints one `single` reading's latency per run.

If p95 is over 20 s for any spread, revisit the model and effort config (BE10) or the length budgets before Phase 21.

## Staging reading latency (2026-10-02, `readings.latency_ms`, openai/gpt-6.1-sol, effort low)

| Spread | n | min | avg | max |
|---|---|---|---|---|
| single | 7 | 10.8 s | 12.3 s | 13.6 s |

Small sample (smoke readings only), but every single-card reading is above the 8 s p50 budget (p95 ≤ 20 s holds). Per the sprint, revisit model/effort (BE10) or the length budgets before launch; larger spreads have no staging data yet.
