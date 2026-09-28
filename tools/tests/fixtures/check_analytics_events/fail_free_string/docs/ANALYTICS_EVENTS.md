# Analytics events

Consent gating: every event goes through `ConsentAwareAnalytics`.

| Sealed group | Event | Params (type) | When fired |
|---|---|---|---|
| `ReadingEvent` | `reading_generated` | `spread_id` (enum), `latency_ms` (int), `error?` (enum) | a reading arrives |
| | `classic_reading_started` / `classic_reading_completed` | `spread_id`, `reason` (no_consent\|region\|paused) | classic flow |
| `AppEvent` | `rate_prompt_shown` | – | review prompt |

| User property | Values |
|---|---|
| `theme` | light\|dark |
