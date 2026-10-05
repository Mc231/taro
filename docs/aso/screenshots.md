# Store screenshots (05 §9.4, Phase 20.2)

The store set is captured from the real app on fakes and composed on the Phase 14 `ScreenshotFrame` template (`docs/design/screens/ScreenshotFrame.dc.html`, `docs/design/assets/store/frame-template.png`). Nothing is mocked up by hand: every frame is a Flutter-layer capture of a shipped screen.

## Pipeline

```bash
tools/screenshots/take_screenshots.sh                    # all 4 captures × 12 locales, compose, feature graphic, verify
tools/screenshots/take_screenshots.sh --captures iphone --locales en,ar --keep-raw
tools/screenshots/upload_store_assets.sh --dry-run       # asa ios/android upload-screenshots + upload-feature-graphic
```

1. **Capture** (`apps/taro/integration_test/screenshots/screenshots_test.dart`, skipped unless `--dart-define=STORE_SHOTS=<iphone|ipad|phone|tablet>`): `bootstrap(FakeTaroEnvironment)` with `TARO_ENV=test`, one device at a time, every locale in one run (the test sets the app locale; the device language never changes). Per locale two flows: frames 1–3 in the light theme, frames 4–7 in the dark theme. Frames are `OffsetLayer.toImage` at the device's physical size, so there is no OS status bar (no other platform's chrome can leak in). The script pulls them from the app container while the test runs (`simctl get_app_container` / `adb run-as … code_cache`) into `build/screenshots/raw/<capture>/<locale>/`.
2. **Compose** (`tools/screenshots/screenshots.py compose`): one HTML page per frame from the template geometry (headline + subtext over the device frame, the two `card.back` slabs and the `accent.subtle` band; dark tokens), rendered with headless Chrome. Headline fonts are the bundled ones (`packages/taro_ui/fonts`): Literata (Latin, Cyrillic), TaroSans Arabic, Noto Serif JP (with `word-break: auto-phrase`), TaroSans KR.
3. **Feature graphic** (`screenshots.py feature-graphic`): 1024 × 500, the wordmark "Taro", the tagline "Tarot for self-reflection" and a fan of the three frame-1 cards (`codex_v1` art) on the brand gradient.
4. **Verify** (`screenshots.py verify`): every file exists at its exact size. The raw captures are then deleted (`--keep-raw` keeps them).

| Capture | Device | Raw size | Store set | Output size | Output folder |
|---|---|---|---|---|---|
| `iphone` | iPhone 17 Pro Max simulator | 1320 × 2868 | App Store iPhone 6.9" | 1320 × 2868 | `build/screenshots/ios/iphone/<locale>/` |
| `ipad` | iPad Pro 13-inch (M5) simulator | 2064 × 2752 | App Store iPad 13" | 2064 × 2752 | `build/screenshots/ios/ipad/<locale>/` |
| `phone` | `Pixel_9a` emulator | 1080 × 2424 | Play phone | 1080 × 1920 | `build/screenshots/android/phone/<locale>/` |
| `tablet` | `Pixel_Tablet` emulator, portrait | 1600 × 2560 | Play 7" tablet | 1080 × 1920 | `build/screenshots/android/tab7/<locale>/` |
| `tablet` | (same capture) | 1600 × 2560 | Play 10" tablet | 1620 × 2880 | `build/screenshots/android/tab10/<locale>/` |
| — | — | — | Play feature graphic | 1024 × 500 | `build/store/feature_graphic.png` |

Play sizes keep the 9:16 ratio Play requires; the device frame keeps the capture's own ratio inside it. Both Play tablet sets come from the one 10" tablet capture (the app has no separate 7" layout).

## Frames

Order matters: frames 1–3 show in search results.

| # | File | Screen | State | Theme |
|---|---|---|---|---|
| 1 | `01_spread.png` | S08 Draw | Three-card spread (`three_ppf`) on the table, real art, Past and Present turned, the question and the disclaimer in view | light |
| 2 | `02_reading.png` | S09 Reading | The spread, the question, "AI-generated", the reading title and overview, the first position section | light |
| 3 | `03_daily.png` | S13 Daily card | Today's card drawn (The Sun) | light |
| 4 | `04_journal.png` | S14 Journal | The frame-1 reading, today's daily card and two earlier readings | dark |
| 5 | `05_learn.png` | S17 Card detail | The World, upright meaning | dark |
| 6 | `06_deck.png` | S16 Learn library | Opened at Cups (phone) or Wands (tablet) | dark |
| 7 | `07_private.png` | S24 Export | What a backup includes; no account | dark |

## Captions

Source: `apps/taro/store/aso.yaml` `store_screenshots` (`screenshots` = en, `translations` = the other 11 locales, same order). Linted by `check_store_copy.py` (banned phrases, platform names) and `screenshots.py lint` (12 locales × 7 frames, headline ≤ 34 and subtext ≤ 44 characters); both run in `tools/verify.sh` (`tools/screenshots/check_screenshots.py`).

| # | en headline | en subtext |
|---|---|---|
| 1 | Ask. Draw. Reflect. | Tarot for self-reflection |
| 2 | Readings that fit your spread | Every card in its position |
| 3 | Your daily card | A free card every day |
| 4 | Journal your insights | Linked to every reading |
| 5 | Learn all 78 cards | Meanings, upright & reversed |
| 6 | An original deck | One consistent art style |
| 7 | No account needed | Export your data anytime |

Frame 3's caption speaks of the free daily *card*, not the free AI reading (RC64). Frame 6 says "original" and "one consistent art style", not "hand-crafted" (the art provenance is `docs/ART_PROVENANCE.md`). The 11 translations await the native-speaker pass with the rest of the store copy (`docs/aso/REVIEW_NEEDED.md`).

## Fixtures

`apps/taro/test/fixtures/store_readings/{locale}.json`, one per locale:

- `question`, `spreadId: three_ppf` and the fixed draw: Past `cups_03` (Three of Cups), Present `major_17` (The Star), Future `pentacles_01` (Ace of Pentacles), all upright.
- `reading`: the 03 §9.1 wire object (title, overview, one interpretation per position, synthesis, two reflection prompts), written in the style of the staging outputs: self-reflection, no predictions ("a beginning you can choose", not "will happen"), no certainty or advice claims (05 §9.5).
- `dailyCardId: major_19` (The Sun), `learnCardId: major_21` (The World), and two earlier journal readings (`single` Two of Cups; `three_sao` Three of Wands, The Empress, Eight of Pentacles) with question, title and overview.

The device cannot read host files, so `screenshots.py fixtures` embeds them in `apps/taro/integration_test/screenshots/store_readings.g.dart`; `fixtures --check` (in `check_screenshots.py`) fails when it is stale. Edit the JSON, then run `tools/.venv/bin/python tools/screenshots/screenshots.py fixtures`.

The draw is staged, not seeded: `_StagedDraw` answers `CardDrawer.shuffle`'s Fisher–Yates calls so the fixture's cards land in positions 1–3 of the bundled deck order, and `nextBool` keeps every card upright. The AI reading is `FakeReadingRepository.completeNextWith(fixture.reading)`. Content (card names, meanings, art) is the bundled `AssetContentRepository` (`TaroFakes.contentPort`).

## Forbidden content (asserted on every frame)

- No ad: no `AdGapFrame` (the banner band); Remove Ads is owned (entitlement cache and store ownership), so the allow-listed tabs keep their slot collapsed.
- No paywall: S10, S11, S12 absent.
- No price: no visible text with a currency sign or code next to a number.
- No countdown: no text matching `balanceNextFreeIn`, `balanceNextFreeInAt`, `rewardedCoolingDown` or `balanceNextFreeTomorrow` in the locale.
- Frames 1–3: no Death, Devil or Tower (`major_13`, `major_15`, `major_16`) among the card IDs shown (the fixture draw, checked against the cards actually drawn, and the daily card); `screenshots.py lint` checks the same on the fixtures.
- Frame 6: none of Death, Devil, Tower, Nine or Ten of Swords painted inside the screen (their localized names).
- No other platform's status bar: frames are Flutter-layer captures without OS chrome.

## Upload

`tools/screenshots/upload_store_assets.sh` maps the locales (App Store `en-US`, `ar-SA`, `de-DE`, `es-ES`, `fr-FR`, `it`, `ja`, `ko`, `nl-NL`, `pt-BR`, `tr`, `uk`; Play `en-US`, `ar`, `de-DE`, `es-ES`, `fr-FR`, `it-IT`, `ja-JP`, `ko-KR`, `nl-NL`, `pt-BR`, `tr-TR`, `uk`) and calls `asa ios upload-screenshots` (`iphone-67`, `ipad-129`), `asa android upload-screenshots` (`phoneScreenshots`, `sevenInchScreenshots`, `tenInchScreenshots`) and `asa android upload-feature-graphic`. Run it with `--dry-run` first; the push itself is Sprint 20.3.
