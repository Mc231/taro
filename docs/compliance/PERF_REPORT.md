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

## Reading latency breakdown and fix (2026-10-03)

**Method.** A throwaway probe (not committed) used the Worker's own `buildReadingPrompt`, `openAiBody`, `maxTokensFor`, `parseModelText` and `validateReadingOutput` and called the OpenAI API directly from a laptop, one call at a time. The cases were normal `evals/cases/quality.jsonl` cases: 5–6 `single` (en, es, it, nl, tr, ar, fr) and 3 three-card (`three_ppf` / `three_sao`; en, ar, de) per variant. It ran 30 model calls plus moderation, about $0.29 in total. Every answer passed L3 (`answered`).

**Where the time goes (baseline: `gpt-6.1-sol`, effort `low`, standard tier, moderation before and after):**

| Spread | n | question moderation | model call | output moderation | sequential total | output tokens (reasoning) | words |
|---|---|---|---|---|---|---|---|
| single | 6 | median 0.89 s (0.26–1.38) | mean 10.8 s (9.7–12.4) | median 0.51 s (0.33–1.65) | **12.3 s** (staging: 12.3 s) | 353 (34) | 180 |
| three-card | 3 | median 0.28 s (0.26–1.13) | mean 16.2 s (15.7–16.5) | median 0.37 s | **17.1 s** | 650 (45) | 320 |

- The model call is **output-bound**: about 17 ms per output token plus a fixed 3–5 s. Reasoning is only 25–60 tokens at `low`, and `low` is sol's lowest effort (it rejects `none` / `minimal`). Prompt-cache hits (2 619 of about 3 400 input tokens once warm) did not change the time measurably.
- `text.verbosity: "low"` is accepted but did not shorten the output, because the prompt fixes the length: single 10.2 s and 356 tokens, three-card 16.2 s and 633 tokens. It was **not adopted**.
- A tighter `max_output_tokens` does not help either. The answers use 300–700 tokens of the 2 500 / 4 000 cap, so a lower cap only risks truncation. **The 01 §7.4 length budgets are unchanged.**
- The two moderation calls are 0.2–2.7 s, median 0.3 s for the question and 0.4 s for the output.
- Streaming (`stream: true`): the first event arrives after 0.4–0.7 s and the first `output_text` delta after 2.2–3.7 s. The total time is the same as non-streaming: single 9.3 s, three-card 16.6 s.
- **Fast mode** (`service_tier: "fast"`, formerly Priority processing, 2x token price): the same outputs (single 353 tokens, three-card 611 tokens) in 40 % less time. Single took mean 6.2 s (5.5–6.9 s, n = 5) and three-card took mean 9.7 s (9.3–10.3 s, n = 3). The response reported `service_tier: "fast"` every time.

**Implemented** (worker CHANGELOG, 03 §8.2, §9.1, §9.3, §9.4, §9.6):

1. `ai.serviceTier` = `"fast"` (new server key, default `fast`): the OpenAI adapter sends `service_tier: "fast"` and prices each call at 2x when the response says `fast` / `priority`. A `default` downgrade is priced standard. `"standard"` by config restores the old price and speed.
2. Question moderation runs **in parallel** with the first model call. A flagged question is still declined (L2, refunded), the answer is discarded and its spend recorded. Moderation errors and throws never block.

**Before → after (model path = question moderation ∥ model call + output moderation; Worker and D1 overhead not included, on staging it was < 0.1 s):**

| Spread | Before (sequential, standard) | After (parallel, fast) | p50 budget 8 s |
|---|---|---|---|
| single | mean 12.3 s (11.4–13.5) | mean **6.7 s** (5.8–7.6) | met |
| three-card | mean 17.1 s (17.0–17.3) | mean **10.1 s** (9.6–10.8) | **not met** |
| 5-card / Celtic Cross (estimate, about 17 ms/token fast) | ≈ 20–30 s | ≈ 13–18 s | not met |

p95 ≤ 20 s holds for single and three-card in both runs. The samples are small (n = 3–6, one client, one day), so re-check on staging with n ≥ 20 per spread (`readings.latency_ms` query above) after the config is pushed.

**Cost.** Fast mode doubles model spend: about $0.008 per `single` and $0.012 per three-card reading, instead of $0.004 / $0.006. Free-tier cost rises from about $0.006 to $0.012 per DAU-day. The budget tiers (03 §10.2) count the real, doubled spend. **The owner confirms this trade-off before production.** It is a config switch, with no release needed.

**Owner decision (2026-10-06): launch on `ai.serviceTier = "standard"`.** The Worker default is now `standard`, so a `single` reading takes ≈ 12 s end to end (model ≈ 10.8 s + moderation; the question moderation still runs in parallel) and three-card ≈ 16–17 s, above the 8 s p50 budget, at the standard price (≈ $0.004 / $0.006 per reading). `fast` can be pushed by config later (00_DECISIONS "Launch config and crisis-line sources").

**What streaming would need (not implemented).** Three-card and larger spreads stay above 8 s to the full answer, because the time is spent writing tokens. Only showing text sooner would change the perceived wait: sol's first text token comes after about 2–3.5 s, or about 1.5–2 s on fast if it scales the same way. That would need:
- **Worker:** an SSE (or chunked NDJSON) variant of `POST /v1/readings`. The OpenAI adapter would stream (`stream: true`, parsing `response.output_text.delta`) and an incremental JSON parser would release whole sections (title, overview, each card, synthesis, prompts) only after per-section L3 checks. Output moderation would run per section, or the full-text moderation would gate a final `commit` event. Idempotent replay would still return the full JSON. The deadline and retry policy (RC52) and the regeneration path would have to handle a stream that was already partly shown: the client would replace the content or show the failure state. Hold commit and refund would stay on the final event.
- **Client:** a streaming `WorkerClient` method and a reading state that renders sections as they arrive. It would also need to retract and replace content on a late L3 or moderation failure (a "Couldn't finish this reading" state with a refund), resume and status polling for a cut stream, and an outbox and journal write only on the final event.
- **Specs:** BE9 and RC31 ("Worker → client returns one complete JSON response"; output moderation sees the full text before the user does) would need an owner decision. Streaming shows text before output moderation has finished, which weakens the 05 safety bar unless sections are held back until checked. Holding them back costs most of the gain.

## Reading latency breakdown and fix (2026-10-03)

**Method.** A measurement-only script, run outside the repo, used the Worker's real `buildReadingPrompt`, `openAiBody`, `maxTokensFor`, the zod parse and L3 (`validateReadingOutput`), and the default config. It made 30 direct calls to `openai/gpt-6.1-sol`, about $0.29 in total. The cases were normal cases from `evals/cases/quality.jsonl`: `single` en, es, it, nl, tr, ar and fr, and three-card en, ar, de (`three_ppf` / `three_sao`). Each case timed the question moderation, `POST /v1/responses` and the output moderation separately. Every answer passed L3, and the lengths stayed inside 01 §7.4 (single 141–200 words, three-card 301–350).

| Variant (gpt-6.1-sol, effort `low`) | Spread | n | Model call median / mean (min–max) | Output tokens (mean) | Reasoning tokens |
|---|---|---|---|---|---|
| baseline (as deployed) | single | 6 | 10.5 / 10.8 s (9.7–12.4) | 353 | 27–38 |
| baseline | three-card | 3 | 16.4 / 16.2 s (15.7–16.5) | 650 | 29–60 |
| `text.verbosity: "low"` | single | 5 | 10.6 / 10.2 s (8.5–11.3) | 356 | 31–46 |
| `text.verbosity: "low"` | three-card | 3 | 16.6 / 16.2 s (14.5–17.6) | 633 | 44–61 |
| **`service_tier: "fast"`** | single | 5 | **6.2 / 6.2 s** (5.5–6.9) | 353 | 23–54 |
| **`service_tier: "fast"`** | three-card | 3 | **9.4 / 9.7 s** (9.3–10.3) | 611 | 38–52 |
| streamed (standard tier) | single | 3 | 9.0 / 9.3 s; first text after 2.2–3.2 s | 350 | 28–44 |
| streamed (standard tier) | three-card | 2 | 16.6 s; first text after 2.2–3.7 s | 630 | 32–45 |

Moderation (`omni-moderation-latest`) took 0.2–1.4 s for the question (median ≈ 0.3 s, 0.9 s on the baseline run) and 0.3–2.7 s for the output (median ≈ 0.4 s). Prompt-cache hits (2 619–3 749 cached tokens) made no visible difference to latency.

**Where the time goes.** On the deployed path, a `single` reading is question moderation (≈ 0.9 s) + model (≈ 10.8 s) + output moderation (≈ 0.5 s) ≈ 12.2 s, which matches the staging 12.3 s. The model call is output-bound: reasoning is only 25–60 tokens at `low`, and output runs at about 35–40 tokens/s with a ≈ 2–3 s first-token delay. The levers the owner allowed while keeping sol do not help:

- `low` is already sol's lowest effort (it rejects `none` / `minimal`).
- Verbosity `low` changes neither the length nor the time, because the prompt fixes the length.
- A tighter `max_output_tokens` only truncates. No reading came near its cap (2500 / 4000).
- Shorter 01 §7.4 budgets were not needed.

**Changes (Worker):**

1. `ai.serviceTier = "fast"` (OpenAI Fast mode): about 40 % faster at 2x the token price. Model cost per reading goes from about $0.004 to $0.008 (`single`) and from $0.006 to $0.012 (three-card). The Worker prices the call from the response's `service_tier`.
2. The question moderation runs in parallel with the model call. This saves 0.2–1.4 s per reading with a question.

**Before → after (estimated Worker time = question moderation ∥ model + output moderation; staging adds D1 / network overhead of ≈ 0.1 s):**

| Spread | Before (sequential, standard) | After (parallel, fast) | p50 budget 8 s |
|---|---|---|---|
| single | ≈ 12.2 s (staging measured 12.3 s, n=7) | ≈ 6.7 s | met |
| three-card | ≈ 16.9 s | ≈ 10.0 s | **not met** |
| larger spreads (not measured) | output-bound, more than three-card | ≈ 1.6 s per 100 output tokens + ≈ 2 s | not met |

p95 ≤ 20 s holds for single and three-card readings in both states. Re-measure on staging after the next deploy with the D1 query in §4 (n ≥ 20 per spread).

**Still above 8 s (three-card and larger): what streaming would need (not implemented).** Streaming shows the first text after 2–4 s, but BE9 and RC31 require the whole output to be moderated and L3-validated before the user sees it. So a streamed reading needs:

- **Worker:** a streaming adapter (Responses `stream: true`, SSE parse, usage from `response.completed`); a new SSE route variant of `POST /v1/readings`, or a status-poll channel; incremental L3 per completed section (title, overview, each card) with output moderation per section; a "retract" event when a later check fails (the reading becomes `failed`, refunded, and its partial text is discarded); and replay or idempotency of a streamed body (03 §2.3).
- **Client:** an SSE client in `WorkerClient`; a progressive reading renderer, with persistence only after the final `completed` event; and handling of retract, timeout and resume via `GET /v1/readings/{id}`.
- **Specs:** an amendment to BE9, RC31 and RC51 (00_DECISIONS), plus new contract fixtures.

A cheaper alternative is to show a "writing your reading" progress state; the client already shows one. The owner could also accept the 8 s p50 for `single` only and a 12 s p50 for three-card readings.

## Staging re-measure after the fast tier + parallel moderation (2026-10-03, Worker caee95cf)

Five `tools/worker_smoke.sh staging` single-card readings: 6.10, 5.48, 6.18, 5.52, 7.05 s (median 6.1 s, max 7.0 s) — within the 8 s p50 budget (was 12.3 s). Three-card spreads still estimated ≈ 10 s (not yet measured on staging).
