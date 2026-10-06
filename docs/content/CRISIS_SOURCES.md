# Crisis resources: verification sources

Source file: `apps/taro/content/source/crisis/crisis_resources.yaml` (05 §4.2, 03 §9.5, RC25, RC81).
Compiled by `tools/content build` into `apps/taro/assets/deck/crisis_resources.json` and
`worker/src/generated/crisis_resources.json`. `tools/content/validate --release` fails when an
entry is unverified or its `verifiedAt` is older than 200 days, so re-verify by **2027-04-23**.

Verification on 2026-10-05: each number, name, URL and hours were read from the organisation's own
site or a government page (fetched that day). Entries confirmed that way carry
`verifiedAt: 2026-10-05`. This was a web check only; nobody dialled the numbers (see "Owner to do").
Owner decisions on 2026-10-06 (recorded in `00_DECISIONS.md`, "Launch config and crisis-line sources"):
NL 0800-0113 removed, UA La Strada-Ukraine and JP #いのちSOS confirmed. `validate --release` passes.

| Entry | Country | Number(s) | Official source | Verified | What was confirmed / notes |
|---|---|---|---|---|---|
| 988 Suicide & Crisis Lifeline | US | call/text 988 | https://988lifeline.org | 2026-10-05 | Call and text 988, chat, 24/7/365, English and Spanish. |
| Samaritans | GB | 116 123 | https://www.samaritans.org/how-we-can-help/contact-samaritan/ | 2026-10-05 | Free, day or night, 365 days. The Welsh line 0808 164 0123 is not listed. |
| Samaritans Ireland | IE | 116 123 | https://www.samaritans.org/samaritans-ireland/ | 2026-10-05 | Free, day or night, Republic of Ireland. URL changed from `/ireland/` to the canonical `/samaritans-ireland/`. |
| 9-8-8 Suicide Crisis Helpline | CA | call/text 988 | https://988.ca | 2026-10-05 | "24/7/365", English and French ("Ligne d'aide en cas de crise de suicide"). |
| Lifeline Australia | AU | 13 11 14; text 0477 13 11 14 | https://www.lifeline.org.au | 2026-10-05 | Phone, text and chat, 24/7. **Added** the SMS number. |
| TelefonSeelsorge | DE | 0800 111 0 111 | https://www.telefonseelsorge.de | 2026-10-05 | Site lists 0800 111 0 111, 0800 111 0 222 and 116 123, free, "Tag und Nacht". |
| 3114 Numéro national de prévention du suicide | FR | 3114 | https://3114.fr | 2026-10-05 | Free, 24h/24 7j/7, mainland and overseas France. |
| Línea 024 de atención a la conducta suicida | ES | 024 | https://www.sanidad.gob.es/linea024/home.htm | 2026-10-05 | Ministerio de Sanidad: free, 24 h, 365 days. **Added** the official URL. |
| Telefono Amico Italia | IT | 02 2327 2327 | https://www.telefonoamico.it | 2026-10-05 | "tutti i giorni 24 ore su 24". **Added** `hours: 24/7`. WhatsApp 324 011 72 52 exists, but the schema has no field for it. |
| 113 Zelfmoordpreventie | NL | 113 | https://www.113.nl/english | 2026-10-05 | "Call us, free of charge, on 113 ... 24 hours a day". 113 works only from inside the Netherlands; chat works from abroad. |
| ~~113 Zelfmoordpreventie (0800)~~ | NL | ~~0800-0113~~ | (none current) | removed | The number no longer appears on 113.nl. Only 2020 press and third-party pages list it. It was a free fallback while 113 was a paid call, and 113 is now free. **Removed (owner, 2026-10-06).** |
| #いのちSOS | JP | 0120-061-338 | https://www.mhlw.go.jp/mamorouyokokoro/soudan/tel/ | 2026-10-05 | MHLW list: 24時間 365日, free. **Added** because いのちの電話 is not 24 h. |
| いのちの電話 | JP | 0570-783-556 | https://www.inochinodenwa.org ; MHLW page above | 2026-10-05 | Navi-dial 10:00–22:00 every day (paid call). The free 0120-783-556 runs only 16:00–21:00 plus the 10th of each month. **Fixed** the hours (they were missing). |
| 자살예방상담전화 109 | KR | 109 | https://www.kfsp.or.kr (MOHW banner "보건복지부 자살예방 상담 전화 109") | 2026-10-05 | 24 h, 365 days, free. It replaced 1393, 1577-0199 and 1388 in 2024. The 24 h and free claims come from MOHW statements in Korean press. The site banner confirms the number. |
| 112 Acil Çağrı Merkezi | TR | 112 | https://www.112.gov.tr | 2026-10-05 | Ministry of Interior: the single national emergency number (police, fire, gendarmerie, coast guard, ambulance). Türkiye has no national suicide line: Alo 182 "Umut Işığı" closed in 2008, and findahelpline lists none. |
| Національна гаряча лінія «Ла Страда-Україна» | UA | 116 123 (mobile) | https://la-strada.org.ua/en/faq/faq.html ; https://la-strada.org.ua/garyachi-liniyi | 2026-10-05 | "functioning around the clock ... 0 800 500 335 (free from stationary), 116 123 (free from mobile)". Psychologists, lawyers and social workers answer. The Kyiv National Police list (2025-07-22) also gives 24/7. Remit: domestic violence, trafficking and gender discrimination, with psychological support for anyone. **Replaces Lifeline Ukraine.** |
| Ла Страда-Україна (landline) | UA | 0 800 500 335 | same | 2026-10-05 | Same line, free from a landline. |
| ~~Lifeline Ukraine~~ | UA | ~~7333~~ | https://lifelineukraine.com | removed | The site says "Робота гарячої лінії на паузі. Короткий номер і чати тимчасово не приймають звернення." Kyiv Post reports the line paused on 2025-10-01 for lack of funding. **Removed.** Restore it when 7333 is back. |
| CVV – Centro de Valorização da Vida | BR | 188 | https://cvv.org.br | 2026-10-05 | "LIGUE 188", 24 horas, free nationwide. Chat and e-mail are also available. |
| SOS Voz Amiga | PT | 213 544 545 | https://www.sosvozamiga.org | 2026-10-05 | Also 912 802 669, 963 524 660 and 930 712 500. Daily 15:30–00:30, ordinary call rates (not free, not 24 h). **Added** the phone number and hours. |
| Find A Helpline | international | n/a | https://findahelpline.com | 2026-10-05 | A free directory run by ThroughLine: 175+ countries, with IASP as key partner. |

## Locale fallback coverage (12 app locales)

| Locale | Fallback | Result |
|---|---|---|
| en | US | 988 |
| ar | null | Find A Helpline only (no Arabic-language national line was verified; see proposals) |
| de | DE | TelefonSeelsorge |
| es | ES | 024 |
| fr | FR | 3114 |
| it | IT | Telefono Amico |
| ja | JP | #いのちSOS, いのちの電話 |
| ko | KR | 109 |
| nl | NL | 113 |
| pt | BR | CVV 188 |
| tr | TR | 112 |
| uk | UA | La Strada 116 123 / 0 800 500 335 |

Every 05 §4.2 country is present: US, GB, IE, CA, AU, DE, FR, ES, IT, NL, JP, KR, TR, UA, BR, PT, plus
the international entry.

## Proposed additions (not added; owner decision)

None of these was verified for this change. Verify each one from its official source before adding it.

- **AT** (de): TelefonSeelsorge Österreich 142. **CH** (de/fr/it): Die Dargebotene Hand / La Main Tendue 143.
- **BE** (fr/nl): Centre de Prévention du Suicide 0800 32 123; Zelfmoordlijn 1813.
- **MX / AR / CO** (es): Latin American Spanish users currently get Find A Helpline only, because `es` falls back to ES.
- **ar**: per-country lines (for example EG, SA, AE, MA, JO, LB: Embrace Lebanon 1564). Arabic users outside these countries keep Find A Helpline.
- **PT**: SNS 24 (808 24 24 24, government line with psychological counselling) as a 24 h complement to SOS Voz Amiga. The official page could not be read on 2026-10-05.
- **DE**: second entry 0800 111 0 222 (verified on telefonseelsorge.de, not added to keep one entry per number family).
- **UA**: national children and youth hotline 116 111 / 0 800 500 225 (La Strada), and line 2345 for men (14:00–06:00).

## Owner to do (Phase 18 Sprint 18.4)

1. ~~Dial-test, or decide on, NL 0800-0113.~~ Removed 2026-10-06; 113 stays (free, 24/7).
2. ~~Confirm the UA replacement and the JP addition.~~ Confirmed 2026-10-06; 05 §4.2 and `00_DECISIONS.md` updated.
3. Optional: dial-test the 2026-10-05 entries that were verified only from the web, mainly KR 109 from abroad and TR 112.
4. Re-verify before 2027-04-23 (200 days).
