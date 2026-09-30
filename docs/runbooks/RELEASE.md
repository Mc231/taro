# Release runbook

Living copy of the release checklist in `06_QUALITY_TESTING_CI.md` §12, with the command for each step. Filled in Phases 10 and 21.

## Build and automated checks

- [ ] `eval:safety` passed against staging with the production prompt version for **every routed provider + model** (the `ai.provider.*` / `ai.model.*` pair of `paid`, `free` and `freeFallback`, plus `ai.outageFallback.*` when set; 05 §4.3, RC60, RC97), and the full report is committed under `worker/evals/reports/`. The weekly Monday `eval:safety` smoke run in `nightly.yml` is green. Command: `cd worker && npm run eval:safety -- --env staging --provider <p> --model <m> --prompt <v> --max-usd <approved>` (see `docs/runbooks/AI_SAFETY.md`).

## Real-device checks

## Store

## Tag and submit

## Evidence log
