# German expansion test: the 15 longest UI strings

Purpose (Phase 14 Sprint 14.1, 01 §13): layouts must tolerate **+40%** text expansion (de, nl). Below are the 15 longest UI strings on the canvas (`docs/design/screens/*.dc.html`, English artboards), with a German translation in the app's register (`de` uses "du", 03 §9.2 `style.de.md`), plus the tight-fit short strings where German hurts most. Designers check each string in its container at 100% and at 200% text scale.

Scope: ARB UI copy only. Excluded: authored content (card texts, AI reading text, the About/Legal/FAQ articles), the sample user note, and the art `aria-label`s. Those strings are long by design and scroll inside `ReadingTextView`.

Terminology (provisional until `glossary.yaml` de is reviewed, 01 §11 step 2): reading = *Legung*, spread = *Legemuster*, interpretation = *Deutung*, journal = *Tagebuch*, daily card = *Tageskarte*, Learn = *Lernen*, balance = *Guthaben*, AI = *KI*. The German translates the **canvas** English. For the compliance strings owned by 05 §3 (`crisisBody`, `reportReadingDisclosure`, `disclaimerOnboarding*`, `aiConsent*`), the ARB wording wins in code wherever it differs from the canvas, so those rows must be re-checked once the ARB de strings exist. The German here tests length only and is not the reviewed copy.

Ratio = German characters ÷ English characters. **Bold** marks ≥ 1.25, and anything at or above 1.40 needs a layout check.

## A. The 15 longest strings

**Stale rows (canvas fix pass, 2026-09-27):** rows 1, 3, 4, 6, 7, 14 and 15 quote copy that the canvas no longer uses. S27 now shows `crisisBody`, S33 `reportReadingDisclosure`, S03 `disclaimerOnboardingBody` + new notice-card copy, and S04 the full `aiConsentBody` (about 620 characters, now the longest UI string on the canvas; the S04 fact rows are gone). New long strings: the S07 guidance line and the S11 consumable disclosure. Regenerate this table before the Phase 14 check.

| # | Screen | Artboard | Where | en (chars) | de (chars) | Ratio |
|---|---|---|---|---|---|---|
| 1 | S27 | `Crisis.dc.html` | Body (canvas copy; the ARB `crisisBody` differs) | Taro can't give a reading on this. If you're thinking about harming yourself, talking to someone can help, now or whenever you're ready. (136) | Zu diesem Thema kann Taro keine Legung geben. Wenn du daran denkst, dir etwas anzutun, kann es helfen, mit jemandem zu sprechen – jetzt oder wann immer du bereit bist. (167) | 1.23 |
| 2 | S13 | `DailyCard.dc.html` | Footnote under the actions | Your daily card is free, works offline and uses no AI. Reflecting deeper starts a single-card reading and uses one reading. (123) | Deine Tageskarte ist kostenlos, funktioniert offline und nutzt keine KI. „Tiefer reflektieren“ startet eine Legung mit einer Karte und verbraucht eine Legung. (158) | **1.28** |
| 3 | S33 | `Report.dc.html` | Disclosure panel | Your question and this reading will be sent to us and kept for 90 days so we can review them. Then they are deleted. (116) | Deine Frage und diese Legung werden an uns gesendet und 90 Tage lang aufbewahrt, damit wir sie prüfen können. Danach werden sie gelöscht. (137) | 1.18 |
| 4 | S04 | `AiConsent.dc.html` | Fact row "What is kept" | Your question is not stored. The reading text stays on our server only until it reaches your phone, at most 7 days. (115) | Deine Frage wird nicht gespeichert. Der Text der Legung bleibt nur so lange auf unserem Server, bis er dein Handy erreicht – höchstens 7 Tage. (142) | 1.23 |
| 5 | S04 | `AiConsent.dc.html` | Footnote under the buttons | Without AI you still get the daily card, classic readings, Learn and the journal. Change this any time in Settings. (115) | Auch ohne KI hast du die Tageskarte, klassische Legungen, „Lernen“ und dein Tagebuch. Du kannst das jederzeit in den Einstellungen ändern. (138) | 1.20 |
| 6 | S03 | `Disclaimer.dc.html` | Lead paragraph | Taro is for reflection and entertainment. A reading is a prompt to think, not a prediction of what will happen. (111) | Taro dient der Reflexion und Unterhaltung. Eine Legung ist ein Denkanstoß, keine Vorhersage dessen, was geschehen wird. (119) | 1.07 |
| 7 | S03 | `Disclaimer.dc.html` | Notice card 1 | Readings aren't medical, legal, financial or psychological advice. For those, please talk to a professional. (108) | Legungen sind keine medizinische, rechtliche, finanzielle oder psychologische Beratung. Wende dich dafür bitte an eine Fachperson. (130) | 1.20 |
| 8 | S31 | `ReadingsPaused.dc.html` | Status card body | This is on our side, and nothing has been used from your balance. Your question is kept here for later. (103) | Das liegt an uns, und von deinem Guthaben wurde nichts verbraucht. Deine Frage bleibt hier für später gespeichert. (114) | 1.11 |
| 9 | S11 | `Store.dc.html` | Subtitle | One reading is one spread of any size. Readings don't expire, and your free daily reading continues. (100) | Eine Legung ist ein Legemuster beliebiger Größe. Legungen verfallen nicht, und deine kostenlose tägliche Legung bleibt bestehen. (128) | **1.28** |
| 10 | S02 | `Main.dc.html` | Lead paragraph | Draw a spread, read a thoughtful interpretation, and keep what you notice in a private journal. (95) | Lege ein Legemuster, lies eine durchdachte Deutung und halte fest, was dir auffällt – in einem privaten Tagebuch. (113) | 1.19 |
| 11 | S21 | `Language.dc.html` | Info notice | Past readings in your journal keep the language they were written in. Only new readings change. (95) | Frühere Legungen in deinem Tagebuch behalten die Sprache, in der sie geschrieben wurden. Nur neue Legungen ändern sich. (119) | **1.25** |
| 12 | S07 | `Question.dc.html` | Charge note under Begin | Uses your free reading. Your question is sent to an AI service to write the reading and isn't stored. (101) | Verbraucht deine kostenlose Legung. Deine Frage wird an einen KI-Dienst gesendet, um die Deutung zu schreiben, und nicht gespeichert. (133) | **1.32** |
| 13 | S03 | `Disclaimer.dc.html` | Notice card 3 | If you're going through something hard, you'll find support lines under Help at any time. (89) | Wenn du gerade etwas Schweres durchmachst, findest du unter „Hilfe“ jederzeit Anlaufstellen und Hotlines. (105) | 1.18 |
| 14 | S03 | `Disclaimer.dc.html` | Notice card 2 | You decide what a card means for you. Taro offers angles; it never tells you what to do. (88) | Du entscheidest, was eine Karte für dich bedeutet. Taro bietet Blickwinkel an, sagt dir aber nie, was du tun sollst. (116) | **1.32** |
| 15 | S04 | `AiConsent.dc.html` | Lead paragraph | Taro uses Claude, an AI model by Anthropic, to write a reading for the cards you draw. (86; superseded: the canvas now shows the exact RC97 `aiConsentBody`, which names Anthropic and OpenAI) | Taro nutzt Claude, ein KI-Modell von Anthropic, um eine Deutung für die Karten zu schreiben, die du ziehst. (107) | 1.24 |

Average ratio for the long strings: 1.22. The long strings wrap within their containers (full-width paragraphs, footnotes, notice cards), so German adds lines, not overflow. Check that sheets (S10, S33) and fixed-height frames (S04 and S03 on a 390 × 844 phone) still fit, or that they scroll, at 200%.

## B. Tight-fit short strings (single line, fixed or shared width)

| Screen | Container | en (chars) | de (chars) | Ratio | Layout rule |
|---|---|---|---|---|---|
| S05/S14/S16/S20 | Tab bar (4 × ~97 dp, 12 sp) | Settings (8) | Einstellungen (13) | **1.62** | one line, no truncation; at 200% the label may drop to two lines inside the 64 dp bar |
| S05 | Balance chip (header row, beside the greeting) | Free reading used · 3 readings (30) | Kostenlose Legung verbraucht · 3 Legungen (41) | **1.37** | the chip wraps below the greeting when it does not fit; never ellipsize the numbers |
| S05 | Balance chip | 1 free reading (14) | 1 kostenlose Legung (19) | **1.36** | as above |
| S05, S10 | `CountdownText` | Next free reading in 5 h 12 min (31) | Nächste kostenlose Legung in 5 Std. 12 Min. (43) | **1.39** | allow two lines in S10; abbreviations from `intl` duration formatting |
| S05, S13 | Overline (letter-spaced caps) | YOUR DAILY CARD (15) | DEINE TAGESKARTE (16) | 1.07 | one line; caps are not forced in locales without case |
| S05 | Primary button (start-aligned, hugs text) | Start a reading (15) | Legung beginnen (15) | 1.00 | the button grows; full width at ≥ 1.5× scale |
| S06, S07, S14 | Spread name (row title / overline / meta) | Past · Present · Future (23) | Vergangenheit · Gegenwart · Zukunft (35) | **1.52** | wraps to two lines in S06 rows; the S14 meta line may ellipsize the spread name but never the date |
| S06 | Spread name | Situation · Action · Outcome (28) | Situation · Handlung · Ergebnis (31) | 1.11 | as above |
| S08 | Two buttons side by side | Draw for me / Pick this card (28) | Für mich ziehen / Diese Karte wählen (36) | **1.29** | stack vertically when either label needs two lines |
| S04 | Consent buttons (equal weight) | Allow AI readings / Not now (27) | KI-Legungen erlauben / Jetzt nicht (34) | **1.26** | stacked full width already; both keep the same size |
| S16 | Segmented control, 5 across | Major Arcana · Wands · Cups · Swords · Pentacles (48) | Große Arkana · Stäbe · Kelche · Schwerter · Münzen (50) | 1.04 | horizontal scroll when the labels do not fit (S16 spec) |
| S14 | Filter chips | All · Readings · Daily cards · Favourites (41) | Alle · Legungen · Tageskarten · Favoriten (41) | 1.00 | horizontal scroll row |
| S11, S20 | Row title | Remove Banner Ads (17) | Bannerwerbung entfernen (23) | **1.35** | wraps; the price stays on the first line |
| S13 | Primary button | Reflect deeper with AI (22) | Mit KI tiefer reflektieren (26) | 1.18 | full width, wraps to two lines if needed |
| S31 | Primary button | Try a classic reading (21) | Klassische Legung ausprobieren (30) | **1.43** | full width, wraps to two lines if needed |

## How to use

1. Paste column **de** into the matching artboard (a duplicate with a `De` suffix, not the en frame) and check wrapping at phone width, and at tablet width with `layout.maxContentWidth`.
2. Table B has three strings at ≥ 1.40: the "Einstellungen" tab label, "Vergangenheit · Gegenwart · Zukunft" and "Klassische Legung ausprobieren". Close behind are the countdown and the balance chip (1.36–1.39); the Learn segments are the widest row in absolute terms. The per-screen specs already name the fallback for each (S05, S06, S08, S16, S31).
3. The golden runs in 06 cover `de` for the ★ states. These strings seed the ARB for those goldens until the reviewed translations land.
