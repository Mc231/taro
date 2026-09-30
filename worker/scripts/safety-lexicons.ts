export { main, USAGE } from '../src/admin/safetyLexicons';

/**
 * `npm run safety:lexicons [-- --check]`
 *
 * Compiles `safety/lexicons/<locale>.json` and
 * `tools/store_copy/banned_phrases.yaml` into
 * `src/generated/safety_lexicons.json` (03 §9.4, RC39). All logic lives in
 * `src/admin/safetyLexicons.ts` (RC61).
 */
