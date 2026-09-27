# Reference frames

PNG snapshots of every Claude Design artboard (`../<Board>.dc.html`), rendered with headless Chrome at device scale 2 (so a 390 × 844 phone board is 780 × 1688 and the 1032 × 1376 iPad board is 2064 × 2752, the @2x sizes in BRIEF §6). The boards are static markup; `support.js` (the Claude Design runtime) was replaced by a stub that unwraps `<x-dc>` and moves `<helmet>` into `<head>`. Fonts are the Google Fonts named in each board. The canvas remains the source of truth: re-render after any board change.

File names are the artboard names, not the `Sxx-<state>-<mode>-<locale>-<device>.png` scheme in BRIEF §6: one board can serve several screens (e.g. `ReadingLight` for S09 and S32), so the S-ID → frame mapping lives here and in the "Frames" row of each `../Sxx/spec.md`.

## By screen

| S-ID | Frames |
|---|---|
| S01 | [`Launch.png`](Launch.png): S01 Launch<br>[`CardBack.png`](CardBack.png): Card back artwork |
| S02 | [`Main.png`](Main.png): S02 Welcome |
| S03 | [`Disclaimer.png`](Disclaimer.png): S03 Disclaimer |
| S04 | [`AiConsent.png`](AiConsent.png): S04 AI consent<br>[`AttPrompt.png`](AttPrompt.png): ATT pre-prompt (iOS) |
| S05 | [`Today.png`](Today.png): S05 Today<br>[`TodayLight.png`](TodayLight.png): S05 Today · light<br>[`TodayAr.png`](TodayAr.png): S05 Today · Arabic RTL<br>[`TodayTablet.png`](TodayTablet.png): S05 Today · iPad 13"<br>[`TodayLargeText.png`](TodayLargeText.png): S05 Today · 200% text<br>[`TodayFirstRun.png`](TodayFirstRun.png): S05 Today · first run<br>[`ScreenshotFrame.png`](ScreenshotFrame.png): App Store screenshot frame |
| S06 | [`Spreads.png`](Spreads.png): S06 Spread picker<br>[`SpreadDiagrams.png`](SpreadDiagrams.png): Spread layout diagrams ×6 |
| S07 | [`Question.png`](Question.png): S07 Question<br>[`QuestionRefused.png`](QuestionRefused.png): S07 Question · declined<br>[`ReadingsPaused.png`](ReadingsPaused.png): S31 Readings paused<br>[`OutOfReadings.png`](OutOfReadings.png): S10 Out of readings |
| S08 | [`Draw.png`](Draw.png): S08 Draw ritual (pick)<br>[`DrawShuffle.png`](DrawShuffle.png): S08 Draw · shuffle<br>[`DrawReveal.png`](DrawReveal.png): S08 Draw · reveal<br>[`DrawAwaiting.png`](DrawAwaiting.png): S08 Draw · awaiting reading<br>[`DrawAr.png`](DrawAr.png): S08 Draw · Arabic RTL |
| S09 | [`Reading.png`](Reading.png): S09 Reading<br>[`ReadingLight.png`](ReadingLight.png): S09 Reading · light<br>[`ReadingAr.png`](ReadingAr.png): S09 Reading · Arabic RTL<br>[`ReadingLargeText.png`](ReadingLargeText.png): S09 Reading · 200% text<br>[`ReadingRated.png`](ReadingRated.png): S09 Reading · rated + toast<br>[`ScreenshotFrame.png`](ScreenshotFrame.png): App Store screenshot frame |
| S10 | [`OutOfReadings.png`](OutOfReadings.png): S10 Out of readings |
| S11 | [`Store.png`](Store.png): S11 Store<br>[`StoreLoading.png`](StoreLoading.png): S11 Store · loading |
| S12 | [`Rewarded.png`](Rewarded.png): S12 Rewarded (granting)<br>[`RewardedGranted.png`](RewardedGranted.png): S12 Rewarded · granted |
| S13 | [`DailyCard.png`](DailyCard.png): S13 Daily card<br>[`DailyCardNotDrawn.png`](DailyCardNotDrawn.png): S13 Daily card · not drawn |
| S14 | [`Journal.png`](Journal.png): S14 Journal<br>[`JournalEmpty.png`](JournalEmpty.png): S14 Journal · empty<br>[`JournalAr.png`](JournalAr.png): S14 Journal · Arabic RTL |
| S15 | [`JournalEntry.png`](JournalEntry.png): S15 Journal entry |
| S16 | [`Learn.png`](Learn.png): S16 Learn deck |
| S17 | [`CardDetail.png`](CardDetail.png): S17 Card detail |
| S18 | [`SpreadsGuide.png`](SpreadsGuide.png): S18 Spread guide · Celtic Cross<br>[`SpreadDiagrams.png`](SpreadDiagrams.png): Spread layout diagrams ×6 |
| S19 | [`AboutTaro.png`](AboutTaro.png): S19 About tarot & Taro |
| S20 | [`Settings.png`](Settings.png): S20 Settings |
| S21 | [`Language.png`](Language.png): S21 Language |
| S22 | [`Reminder.png`](Reminder.png): S22 Reminder |
| S23 | [`PrivacyChoices.png`](PrivacyChoices.png): S23 Privacy choices |
| S24 | [`Export.png`](Export.png): S24 Export backup |
| S25 | [`Import.png`](Import.png): S25 Import backup<br>[`ImportInvalid.png`](ImportInvalid.png): S25 Import · invalid file |
| S26 | [`DeleteData.png`](DeleteData.png): S26 Delete all data |
| S27 | [`Crisis.png`](Crisis.png): S27 Support lines |
| S28 | [`Help.png`](Help.png): S28 Help & FAQ |
| S29 | [`Legal.png`](Legal.png): S29 Legal · disclaimer |
| S30 | [`UpdateRequired.png`](UpdateRequired.png): S30 Update required |
| S31 | [`ReadingsPaused.png`](ReadingsPaused.png): S31 Readings paused |
| S32 | [`ClassicReading.png`](ClassicReading.png): S32 Classic reading<br>[`ReadingLight.png`](ReadingLight.png): S09 Reading · light<br>[`ReadingAr.png`](ReadingAr.png): S09 Reading · Arabic RTL<br>[`ReadingLargeText.png`](ReadingLargeText.png): S09 Reading · 200% text |
| S33 | [`Report.png`](Report.png): S33 Report reading |

## All boards

| Frame | Board title | Board size (pt) | PNG (px) | Screens |
|---|---|---|---|---|
| [`AttPrompt.png`](AttPrompt.png) | ATT pre-prompt (iOS) | 390 × 844 | 780 × 1688 | S04 |
| [`ScreenshotFrame.png`](ScreenshotFrame.png) | App Store screenshot frame | 1320 × 2868 | 2640 × 5736 | S05, S09 |
| [`AppIcon.png`](AppIcon.png) | App icon master | 1024 × 1024 | 2048 × 2048 | (asset board, see `../../assets/README.md`) |
| [`CardBack.png`](CardBack.png) | Card back artwork | 580 × 1000 | 1160 × 2000 | S01 |
| [`Launch.png`](Launch.png) | S01 Launch | 390 × 844 | 780 × 1688 | S01 |
| [`Main.png`](Main.png) | S02 Welcome | 390 × 844 | 780 × 1688 | S02 |
| [`Disclaimer.png`](Disclaimer.png) | S03 Disclaimer | 390 × 844 | 780 × 1688 | S03 |
| [`AiConsent.png`](AiConsent.png) | S04 AI consent | 390 × 844 | 780 × 1688 | S04 |
| [`Today.png`](Today.png) | S05 Today | 390 × 844 | 780 × 1688 | S05 |
| [`TodayLargeText.png`](TodayLargeText.png) | S05 Today · 200% text | 390 × 1880 | 780 × 3760 | S05 |
| [`TodayAr.png`](TodayAr.png) | S05 Today · Arabic RTL | 390 × 844 | 780 × 1688 | S05 |
| [`TodayFirstRun.png`](TodayFirstRun.png) | S05 Today · first run | 390 × 844 | 780 × 1688 | S05 |
| [`TodayTablet.png`](TodayTablet.png) | S05 Today · iPad 13" | 1032 × 1376 | 2064 × 2752 | S05 |
| [`TodayLight.png`](TodayLight.png) | S05 Today · light | 390 × 844 | 780 × 1688 | S05 |
| [`Spreads.png`](Spreads.png) | S06 Spread picker | 390 × 844 | 780 × 1688 | S06 |
| [`Question.png`](Question.png) | S07 Question | 390 × 844 | 780 × 1688 | S07 |
| [`QuestionRefused.png`](QuestionRefused.png) | S07 Question · declined | 390 × 844 | 780 × 1688 | S07 |
| [`Draw.png`](Draw.png) | S08 Draw ritual (pick) | 390 × 844 | 780 × 1688 | S08 |
| [`DrawAr.png`](DrawAr.png) | S08 Draw · Arabic RTL | 390 × 844 | 780 × 1688 | S08 |
| [`DrawAwaiting.png`](DrawAwaiting.png) | S08 Draw · awaiting reading | 390 × 844 | 780 × 1688 | S08 |
| [`DrawReveal.png`](DrawReveal.png) | S08 Draw · reveal | 390 × 844 | 780 × 1688 | S08 |
| [`DrawShuffle.png`](DrawShuffle.png) | S08 Draw · shuffle | 390 × 844 | 780 × 1688 | S08 |
| [`Reading.png`](Reading.png) | S09 Reading | 390 × 844 | 780 × 1688 | S09 |
| [`ReadingLargeText.png`](ReadingLargeText.png) | S09 Reading · 200% text | 390 × 2300 | 780 × 4600 | S09, S32 |
| [`ReadingAr.png`](ReadingAr.png) | S09 Reading · Arabic RTL | 390 × 844 | 780 × 1688 | S09, S32 |
| [`ReadingLight.png`](ReadingLight.png) | S09 Reading · light | 390 × 844 | 780 × 1688 | S09, S32 |
| [`ReadingRated.png`](ReadingRated.png) | S09 Reading · rated + toast | 390 × 844 | 780 × 1688 | S09 |
| [`OutOfReadings.png`](OutOfReadings.png) | S10 Out of readings | 390 × 844 | 780 × 1688 | S07, S10 |
| [`Store.png`](Store.png) | S11 Store | 390 × 844 | 780 × 1688 | S11 |
| [`StoreLoading.png`](StoreLoading.png) | S11 Store · loading | 390 × 844 | 780 × 1688 | S11 |
| [`Rewarded.png`](Rewarded.png) | S12 Rewarded (granting) | 390 × 844 | 780 × 1688 | S12 |
| [`RewardedGranted.png`](RewardedGranted.png) | S12 Rewarded · granted | 390 × 844 | 780 × 1688 | S12 |
| [`DailyCard.png`](DailyCard.png) | S13 Daily card | 390 × 1040 | 780 × 2080 | S13 |
| [`DailyCardNotDrawn.png`](DailyCardNotDrawn.png) | S13 Daily card · not drawn | 390 × 844 | 780 × 1688 | S13 |
| [`Journal.png`](Journal.png) | S14 Journal | 390 × 844 | 780 × 1688 | S14 |
| [`JournalAr.png`](JournalAr.png) | S14 Journal · Arabic RTL | 390 × 844 | 780 × 1688 | S14 |
| [`JournalEmpty.png`](JournalEmpty.png) | S14 Journal · empty | 390 × 844 | 780 × 1688 | S14 |
| [`JournalEntry.png`](JournalEntry.png) | S15 Journal entry | 390 × 1040 | 780 × 2080 | S15 |
| [`Learn.png`](Learn.png) | S16 Learn deck | 390 × 844 | 780 × 1688 | S16 |
| [`CardDetail.png`](CardDetail.png) | S17 Card detail | 390 × 1040 | 780 × 2080 | S17 |
| [`SpreadsGuide.png`](SpreadsGuide.png) | S18 Spread guide · Celtic Cross | 390 × 1040 | 780 × 2080 | S18 |
| [`AboutTaro.png`](AboutTaro.png) | S19 About tarot & Taro | 390 × 1040 | 780 × 2080 | S19 |
| [`Settings.png`](Settings.png) | S20 Settings | 390 × 844 | 780 × 1688 | S20 |
| [`Language.png`](Language.png) | S21 Language | 390 × 1040 | 780 × 2080 | S21 |
| [`Reminder.png`](Reminder.png) | S22 Reminder | 390 × 844 | 780 × 1688 | S22 |
| [`PrivacyChoices.png`](PrivacyChoices.png) | S23 Privacy choices | 390 × 844 | 780 × 1688 | S23 |
| [`Export.png`](Export.png) | S24 Export backup | 390 × 844 | 780 × 1688 | S24 |
| [`Import.png`](Import.png) | S25 Import backup | 390 × 844 | 780 × 1688 | S25 |
| [`ImportInvalid.png`](ImportInvalid.png) | S25 Import · invalid file | 390 × 844 | 780 × 1688 | S25 |
| [`DeleteData.png`](DeleteData.png) | S26 Delete all data | 390 × 844 | 780 × 1688 | S26 |
| [`Crisis.png`](Crisis.png) | S27 Support lines | 390 × 844 | 780 × 1688 | S27 |
| [`Help.png`](Help.png) | S28 Help & FAQ | 390 × 1040 | 780 × 2080 | S28 |
| [`Legal.png`](Legal.png) | S29 Legal · disclaimer | 390 × 1040 | 780 × 2080 | S29 |
| [`UpdateRequired.png`](UpdateRequired.png) | S30 Update required | 390 × 844 | 780 × 1688 | S30 |
| [`ReadingsPaused.png`](ReadingsPaused.png) | S31 Readings paused | 390 × 844 | 780 × 1688 | S07, S31 |
| [`ClassicReading.png`](ClassicReading.png) | S32 Classic reading | 390 × 844 | 780 × 1688 | S32 |
| [`Report.png`](Report.png) | S33 Report reading | 390 × 844 | 780 × 1688 | S33 |
| [`SpreadDiagrams.png`](SpreadDiagrams.png) | Spread layout diagrams ×6 | 1320 × 900 | 2640 × 1800 | S06, S18 |
