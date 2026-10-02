# Translation self-review reports (Phase 18)

One report per locale from the LLM self-review pass (01 Q5, Phase 18 Sprint
18.3) over the machine translation. Every translated file is still
`reviewStatus: machine`; a native reviewer flips it (01 §11 step 6,
`docs/content/REVIEW_CHECKLIST.md`). `tools/content/validate --launch-gate`
lists what the launch gate still needs.

| Locale | Report | Register |
|---|---|---|
| ar | [ar.md](ar.md) | Modern Standard Arabic, gender-neutral phrasing |
| de | [de.md](de.md) | du |
| es | [es.md](es.md) | tú, neutral (no vosotros) |
| fr | [fr.md](fr.md) | vous (per `style.fr.md` and the glossary) |
| it | [it.md](it.md) | tu |
| ja | [ja.md](ja.md) | polite (です・ます) |
| ko | [ko.md](ko.md) | 해요체 |
| nl | [nl.md](nl.md) | je |
| pt | [pt.md](pt.md) | pt-BR, você |
| tr | [tr.md](tr.md) | sen |
| uk | [uk.md](uk.md) | formal Ви (per `style.uk.md`; owner to confirm) |

## Open questions shared by every locale

1. **AI provider in the en articles.** `en/articles/about.md` and `faq.md`
   still name "Anthropic's Claude or OpenAI's GPT models", while the AI
   consent copy (RC97) names OpenAI only. Fix en first; every locale's
   articles then turn stale and are re-translated (tr already says OpenAI
   only).
2. **Settings paths in the en FAQ** ("Settings → Purchases / Your data /
   Privacy") do not match the real section labels.
3. **Glossary** `review.<locale>` is `machine` in all locales; the native
   glossary check comes first (01 §11 step 2).
4. **Delete confirmation words** (`deleteConfirmWord`): tr uses "ONAYLA"
   because `toLowerCase()` maps "İ" to a dotted "i̇"; de "LÖSCHEN" and the
   other non-ASCII words need a check of the case-insensitive comparison.
