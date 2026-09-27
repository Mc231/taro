# Taro design

- **Design system (Claude Design):** https://claude.ai/artifact/C94hpvYCJKqrqYn5o8VnRb — brand book, tokens, component previews. Approved by the owner 2026-09-27.
- **`taro.tokens.json`:** W3C DTCG export of the approved tokens (light + dark via `$extensions.taro.modes`). Token paths follow `01_PRODUCT.md` §14 (`color.bg.canvas` …). `tools/tokens/` (Phase 15) generates `TaroTokens` from this file.
- **Fonts:** Literata (reading/display), IBM Plex Sans + Arabic/JP/KR (UI), IM Fell English SC (card numerals); Noto Serif Arabic/JP/KR as reading fallbacks. All bundled in the app (no runtime fetch).
- Screens (S01–S33) follow in Claude Design (Phase 14).
- **Screens (Claude Design canvas):** https://claude.ai/artifact/1d29x21T1WhcFhFaeo3QxL — 58 artboards: S01–S33 (dark, English) with extra ★ states, light / Arabic RTL / iPad / 200% text variants, ATT pre-prompt, spread diagrams, store screenshot frame, app icon master and card-back artwork. `screens/` holds a snapshot of the canvas sources (`*.dc.html` + `canvas.json`) for reference in Phases 15–17; the canvas is the source of truth.
