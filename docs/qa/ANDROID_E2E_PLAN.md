# Android end-to-end test plan

Scope: every user-facing feature of Taro v1 on Android, derived from 01 §7–§9 (screens S01–S33, flows F1–F8), `docs/design/STATE_INVENTORY.md`, 04 (paywall, rewarded, banners, Remove Banner Ads, restore), 05 (disclaimers, consent, crisis) and the existing `apps/taro/integration_test/flows/*`.

## Environment

| Item | Value |
|---|---|
| Device | emulator-5554, Android 16, `sdk_gphone64_arm64`, Google Play services. Tablet and real-device cases as noted. |
| Build | `cd apps/taro && flutter test integration_test/<file> --flavor <f> --dart-define-from-file=config/<f>.json` (or `flutter run` / `flutter build apk` for C and M) |
| Backend | A: in-process fakes (`integration_test/support/flow_harness.dart`). B, C and M: staging Worker `https://api-staging.taro.vshyrochuk.com`, with the debug attestation bypass (`--dart-define=TARO_DEBUG_ATTESTATION_TOKEN=…`, read from the secrets bundle inside the consuming command only). |
| Ads | Staging uses the Google sample AdMob IDs (`ca-app-pub-3940256099942544/…`), so test ads only. |
| IAP | Real purchases need a Play internal-testing track plus license testers. The emulator side-load can't buy, so those cases are M. |
| Reset | `adb shell pm clear com.vshyrochuk.taro.staging` (confirm the applicationId suffix) gives a fresh install. Staging allows one free reading per install per day, so B tests that spend a reading each need a fresh install. |

## Execution methods

| Code | Meaning | Location |
|---|---|---|
| A | Existing fake-backed integration flow. Deterministic, no network. | `apps/taro/integration_test/flows/*.dart` |
| B | New real-staging integration test. Real composition root, flavor `staging`, debug attestation. Gated by `TARO_STAGING_SMOKE=1`, the same as `staging/smoke_test.dart`. | `apps/taro/integration_test/qa/*.dart` (new) |
| C | Screenshot tour. An integration test drives navigation and calls `binding.takeScreenshot` per screen and state, and a human reviews the shots. | `apps/taro/integration_test/qa/screenshot_tour_test.dart` (new) |
| M | Manual, or needs a real device, a Play sandbox or OS UI that Flutter can't drive (system dialogs, share sheet, TalkBack, notifications shade, browser). | checklist in this file |

Priority: **P0** blocks release or store review. **P1** is a core feature. **P2** is polish or an edge case.

Known gap: the UMP debug geography (`debugEea`) exists in `ConsentOrchestrator`/`UmpConsentService` (allowed outside prod), but nothing in `lib/` wires it to a define, so the EEA form can't be forced from a build flag. Plan: the B test overrides the orchestrator's `debugEea` in a test-only provider override. Otherwise it's M with the emulator registered as a UMP test device behind an EEA VPN.

## 1. First launch, onboarding, disclaimer, consent

| ID | Area | Preconditions | Steps | Expected | Exec | Pri |
|---|---|---|---|---|---|---|
| ONB-01 | F1 first launch | Fresh install, online | Launch | Native splash, then S01 bootstrapping, then S02 Welcome. `GET /v1/config` and `POST /v1/installs` run in the background and never block. | A `first_launch_free_reading_test` + B `qa/onboarding_staging_test` | P0 |
| ONB-02 | Welcome pages | ONB-01 | Swipe 3 pages; also tap Skip | Pages Reflect/Learn/Journal appear. Skip goes to S03. | C | P1 |
| ONB-03 | Disclaimer | S03 | Try to proceed without acknowledging, then tap "I understand" | Can't continue until acknowledged. Text says entertainment/self-reflection only, no advice, AI-generated. | A + C | P0 |
| ONB-04 | AI consent grant | S04 undecided | Tap **Allow AI readings** | `granted(version)` is persisted. Next step is UMP (if required), then Home with the coachmark. The privacy link opens. | A + B | P0 |
| ONB-05 | AI consent decline | S04 undecided | Tap **Not now** | `declined`. Home still works. The two buttons have equal visual weight and nothing is pre-checked. | A `consent_denied_test` + C | P0 |
| ONB-06 | Consent copy | S04 | Read the screen | Names what is sent (question, card IDs, locale), the providers (Anthropic, OpenAI via Taro's server), retention (≤7 days undelivered, 90 days if reported), and links the privacy policy. | C + M review | P0 |
| ONB-07 | Kill mid-onboarding | On S03 | `adb shell am force-stop`, relaunch | Resumes at S03, not S02. | M (adb) | P1 |
| ONB-08 | Offline first launch | Fresh install, airplane mode | Complete onboarding | Onboarding finishes. Home shows `balanceStale` and "Connect to start AI readings". Daily card and Learn work. UMP is retried on the next launch. | A (fake offline) + M | P0 |
| ONB-09 | Update required | Staging `app.minVersion.android` > build (or fake) | Launch | S30 blocks, with only a store link. | A (fake config) | P1 |
| ONB-10 | Update available | `app.recommendedVersion` > build | Launch, dismiss the notice, relaunch | Inline notice on S05, shown at most once per version. | A (fake config) | P2 |
| ONB-11 | Device unverified | Attestation fails (no debug token) | Launch staging without the token | Home chip shows "Readings unavailable on this device" + Retry. Learn and daily card work. | B `qa/unverified_staging_test` | P1 |
| UMP-01 | UMP required (EEA) | Fresh install, debug geography EEA | Complete S04 | The UMP form appears after S04, not customised. The Mobile Ads SDK starts only after it. | B (debugEea override) or M (EEA VPN + test device) | P0 |
| UMP-02 | UMP decline all | UMP-01 | Choose "Do not consent" / manage → reject | `canRequestAds` per SDK. No personalised ads. Banners only if consent allows (otherwise collapsed). Rewarded is offered only when a compliant request is possible. | M | P0 |
| UMP-03 | Privacy options entry | UMP required | Settings → Privacy → Ad privacy choices | The UMP privacy options form reopens. The row is hidden when not required. | M | P0 |
| UMP-04 | Non-EEA | Default geography | Fresh install | No UMP form. Ads initialise. | B | P1 |

## 2. Today (Home) and daily card

| ID | Area | Preconditions | Steps | Expected | Exec | Pri |
|---|---|---|---|---|---|---|
| HOME-01 | Balance chip | Registered | Open Home | Shows syncing, then "1 free today". The reset hint counts down to real local midnight. | A + B | P0 |
| HOME-02 | Chip variants | Fake balances | free available / free used + credits / zero | Copy matches 01 §7.1 ("Free reading used · 3 readings"). | A + C | P1 |
| HOME-03 | Stale chip | Airplane mode after sync | Resume app | Offline glyph, last-known value, TaroOfflineBanner. | A + M | P1 |
| HOME-04 | Coachmark | First run | Arrive at Home | The coachmark points at "Start a reading" once and doesn't return after it's dismissed. | C | P2 |
| HOME-05 | Chip → S10 | Zero readings | Tap the chip | S10 opens. | A | P1 |
| HOME-06 | Recent readings | ≥1 reading | Tap a recent entry | Opens S15. | A | P2 |
| DAY-01 | Daily card draw | Not drawn today | Home → Daily card → tap to reveal | One flip. Name, orientation as text, keywords, short meaning, one reflection question. Saved as a `DailyCard` entry. | A + C | P0 |
| DAY-02 | Same card same day | DAY-01 | Kill and relaunch the same day | The same card shows (`drawn`). | A + M | P1 |
| DAY-03 | Reversals off | Settings reversals off | Draw over several days (fake clock) | Never reversed. | A | P2 |
| DAY-04 | Daily card note | DAY-01 | Add a note | Autosaved; visible in the Journal entry. | A | P1 |
| DAY-05 | Reflect deeper | DAY-01, credits | "Reflect deeper with AI" | S07 with `single` and the card pre-set. The gate applies and uses 1 credit. The reading shows that card. | A + B | P1 |
| DAY-06 | Reminder offer yes | First reveal ever | Tap **Yes, remind me** | Then the OS POST_NOTIFICATIONS dialog appears. On grant, the reminder is scheduled for 09:00. The offer never shows again. | M (system dialog; or patrol native) | P0 |
| DAY-07 | Reminder offer no | First reveal | **No thanks** | No OS prompt. The offer never returns. | A/C | P1 |
| DAY-08 | Daily reset | Drawn yesterday | Fake clock past local midnight, resume | `notDrawn` again. Balance resyncs to "1 free today". | A `daily_reset_resume_test` | P0 |
| DAY-09 | Timezone change | Drawn | Change device TZ | Day boundary and reminder reschedule follow the new TZ. | A `timezone_change_test` + M | P1 |

## 3. Reading flow (spreads, question, safety, ritual, result)

| ID | Area | Preconditions | Steps | Expected | Exec | Pri |
|---|---|---|---|---|---|---|
| RD-01 | Spread picker | Home | Start a reading | S06 lists the 6 spreads: single, three_ppf, three_sao, relationship, two_paths, celtic_cross. Spreads disabled by config are hidden. | A + C | P0 |
| RD-02..07 | Each spread end to end | Credits (fake) | For each of the 6 spreads: question → Begin → shuffle → pick N (1/3/3/5/5/10) → reveal → result | Each card flies to the correct slot. Picking position i takes `shuffled[i]`. The reveal is in position order. The result has a section per position with the right position names. Celtic Cross fits the screen. | A (new param case if missing) + B for `three_ppf` + `single` (1 free/day) + C | P0 |
| RD-08 | Question limits | S07 | Type 300 chars; try 301; emoji-only; email/phone | The counter appears at ≥250 and the field is capped at 300. Emoji-only is rejected. A PII warning shows but doesn't block. | A/C | P1 |
| RD-09 | Suggestion chips | S07 | Tap a chip | Fills the field. 3–4 localized chips per spread. Guidance line present. | C | P2 |
| RD-10 | Empty question | S07 | Begin with no text | Allowed. The result header shows the spread name. | A | P1 |
| RD-11 | Rephrase (canRephrase) | Staging, credit | Ask "Will I win the lottery?" / a health question | Back on S07 with the question kept, a hint and example rewordings, and the "can't help" card for advice categories. "Reflect on the cards without a question" is offered. **Balance unchanged.** | B `qa/safety_staging_test` (+A fake) | P0 |
| RD-12 | Crisis | Staging | Question with self-harm intent | S27 opens immediately with country-aware hotlines and findahelpline.com. No reading, no ads, no upsell. Credit not consumed. | B + A | P0 |
| RD-13 | sexual_minors | Fake | Declined `sexual_minors` | A neutral "can't help" message, with no rewording hint. | A | P1 |
| RD-14 | Draw ritual | Gate ok | Hold Shuffle; pick; "Draw for me"; "Reveal all" | Shuffle runs for at least the minimum duration. The fan of 78 scrolls. Auto-pick and reveal-all work. Reversed is labelled in text. | A + C | P0 |
| RD-15 | Reduced motion | Android "Remove animations" on (`settings put global animator_duration_scale 0`, plus accessibility) | Run a draw | `reducedMotion` variant: no flying or flip animation, and the ritual is still completable. | C + M | P1 |
| RD-16 | Back on draw | ≥1 card picked | System Back / predictive back gesture | The "Leave this reading?" dialog appears. Leaving keeps the reading `pending` in the Journal. | A/M | P1 |
| RD-17 | Back on result | S09 | Back | Goes to Home, never to S08. | A | P1 |
| RD-18 | Slow and timeout | Fake slow Worker | Wait 20 s / 60 s | `slowReading` copy, then a poll of `GET /v1/readings/{id}`, then `generationFailed` with Try again / Finish later. "You haven't been charged." | A `reading_failure_refund_test` | P0 |
| RD-19 | Hold lost | Fake 402/409 on renew | Complete the picks | S10 with the cards face-down, then the same draw is resubmitted. | A `hold_lost_test` | P1 |
| RD-20 | Delivery expired | Fake 410 | Journal Finish reading | "We couldn't deliver… weren't charged" + Try again with the same cards. | A | P1 |
| RD-21 | Result content | Completed reading | Scroll S09 | Header (spread, date, question, mini layout), summary, expandable positions, synthesis, 2–3 reflection prompts, and the footer "AI-generated interpretation · … Not advice." with a disclaimer link. | A + B + C | P0 |
| RD-22 | Write about this | S09 | Tap the prompt's "Write about this" | The note editor opens, prefilled with the prompt as a heading. | A | P2 |
| RD-23 | Favourite / note | S09 | Toggle favourite, add a note | Reflected in the Journal. | A | P1 |
| RD-24 | Share | S09 | Share | The Android share sheet opens with the reading text or image. Cancel returns cleanly. | M (system sheet) | P1 |
| RD-25 | Rating | S09 | 👍; then on another reading 👎 + reason chip | The rating persists. Reason chips only, no free text. | A | P2 |
| RD-26 | Review prompt | 3 positive readings | Third 👍 | Play in-app review is requested at most per policy. Classic readings don't count. | M (Play review API is a no-op on side-load) | P2 |
| RD-27 | Report reading | S09 menu | Report → chip + note → Send | The disclosure "kept for 90 days" is shown. `submitted`, after which the menu shows "Reported". Offline disables Send. | A `report_reading_test` + B | P0 |
| RD-28 | Rate limit burst | Fake 429 burst/dailyLimit | Begin | `rateLimited` / `dailyLimitReached` copy, no paywall. | A | P2 |

## 4. Classic reading and AI consent re-entry (F7/F8)

| ID | Area | Preconditions | Steps | Expected | Exec | Pri |
|---|---|---|---|---|---|---|
| CL-01 | Consent re-entry | Consent declined | S07 Begin | S04 declined re-entry ("AI readings need your permission"). Allow returns to S07 and re-runs the gate. | A `consent_denied_test` | P0 |
| CL-02 | Classic from Not now | CL-01 → Not now | Tap **Classic reading** | Ritual, then S32: authored meanings per position, the "Classic reading" label, disclaimer footer, no AI sections. Works offline, uses no credit. | A `classic_reading_test` + C | P0 |
| CL-03 | Classic from paused | `readings.enabled=false` | Begin | S31 "Readings are resting" with daily/Learn/Classic links. **Never a paywall.** | A `kill_switch_test` | P0 |
| CL-04 | Classic from region | Fake 403 AI_UNAVAILABLE_REGION | Begin | Classic offered. | A | P1 |
| CL-05 | Classic not reportable | S32 | Open the menu | No Report item. Doesn't count toward banners or the review prompt. | A | P1 |
| CL-06 | Consent version bump | Consent v1, config v2 | Begin | Re-asked (S04). | A | P1 |

## 5. Monetisation: paywall, store, rewarded, banners, Remove Banner Ads, restore

| ID | Area | Preconditions | Steps | Expected | Exec | Pri |
|---|---|---|---|---|---|---|
| PAY-01 | Paywall before draw | 0 readings | S07 Begin | S10 opens **before** any draw with the question kept. "Next free reading in …" uses a real countdown, no fake urgency, and the close button is always visible. | A `out_of_credits_purchase_test` + B (second reading of the day on staging) | P0 |
| PAY-02 | S10 option matrix | Fake config | rewarded available / cooldown / capped / disabled / no fill; store unavailable | Each variant's copy is correct. No-fill greys out for 60 s. | A + C | P1 |
| PAY-03 | Store content | Online | Settings → Store | Packs for readings_3/10/30 with store-localized prices. "Best value" only if mathematically true. Remove Banner Ads row. Nothing pre-selected. | B (prices need Play) / M | P0 |
| PAY-04 | Purchase pack | Play internal track + license tester | Buy readings_3 | `verifying`, then `success`, and the balance goes up by the Worker grant. The purchase is consumed only after the grant. | A (fake) + M (Play sandbox) | P0 |
| PAY-05 | Purchase cancelled | M sandbox | Cancel the Play sheet | Silent return to S10/S11. | A + M | P1 |
| PAY-06 | Pending purchase | Play test card "slow/pending" | Buy | "Waiting for approval". Credits arrive on a later sync. | A + M | P1 |
| PAY-07 | Verification delayed | Worker unreachable after Play success | Buy offline-ish | "Your purchase is safe…". Retried on resume. | A `os_restore_test` / M | P1 |
| PAY-08 | Purchases blocked | Fake `purchasesBlocked` | Open S11 | Pack buttons hidden. Free, rewarded and restore remain. | A | P2 |
| PAY-09 | Remove Banner Ads | Sandbox | Buy remove_ads | Banners hide immediately on all 3 screens. Settings shows "Banner ads removed ✓". | A `remove_ads_restore_test` + M | P0 |
| PAY-10 | Restore | remove_ads owned, reinstall | Settings → Restore purchases | "Remove Banner Ads restored", or "No purchases to restore" when there's nothing. Consumables are not restored, and the copy explains this. | A + M | P0 |
| PAY-11 | Move readings | Prior purchase on another install | Help → "Move readings from another device" | The transfer code is shown with the Support ID. | M | P2 |
| RW-01 | Rewarded happy path | Staging, free used, test ads | S10 → Watch ad → watch the Google test rewarded ad fully | `POST /v1/rewards/intents` → test ad → `granting` (poll) → `granted` → back to S07 with Begin enabled (no auto start). Balance +1 from the Worker (SSV). | A `rewarded_ad_test` + B `qa/rewarded_staging_test` (test ad SSV may not fire on sample IDs, in which case grantDelayed is the expected outcome) | P0 |
| RW-02 | Dismiss early | RW-01 | Close the ad early | `dismissedEarly` with neutral copy, no reward, intent cancelled. | A + M | P1 |
| RW-03 | Cooldown/cap | After a grant | Reopen S10 | "Another ad reward is available in 4 min"; after the cap, "You've used today's ad rewards". | A | P1 |
| RW-04 | Never auto-shown | Any | Go through the whole app | A rewarded ad only ever starts from an explicit tap. | A + C | P0 |
| BAN-01 | Banner allow-list | ≥1 completed AI reading, ads consent | Visit every screen | A banner appears only on Home, Journal list and Learn deck. None on reading, draw, result, S10/S11, sheets, dialogs or settings. | C (full tour) + A | P0 |
| BAN-02 | Banner gate | Fresh install, 0 AI readings | Visit the 3 screens | No banner until the first AI reading completes. Classic readings don't count. | A + B | P0 |
| BAN-03 | Banner spacing | Banner shown | Inspect | ≥16 dp gap to any tap target. One per screen. The container collapses on failure. | C + M | P1 |
| BAN-04 | Kill switches | `ads.enabled=false` / `bannerEnabled=false` / `rewarded.enabled=false` / `store.enabled=false` | Launch | The corresponding UI is hidden, with no errors. | A `kill_switch_test` | P1 |

## 6. Journal

| ID | Area | Preconditions | Steps | Expected | Exec | Pri |
|---|---|---|---|---|---|---|
| JR-01 | Empty | Fresh | Journal tab | "Your readings will live here" + Start a reading. | A + C | P1 |
| JR-02 | List | Readings + daily cards | Journal | Grouped by month, newest first. Rows show the date, icon, thumbnails, question/spread name, and favourite/note indicators. | A + C | P0 |
| JR-03 | Filters | JR-02 | All / Readings / Daily / Favourites; spread; contains card | Correct subsets. `filteredEmpty` when nothing matches. | A | P1 |
| JR-04 | Search | JR-02 | Search question and note text (incl. non-Latin) | FTS/LIKE matches. `searchEmpty` when there's no hit. | A (+ fts5 spike) | P1 |
| JR-05 | Entry detail | JR-02 | Open an entry | Same renderer as S09, plus the note editor. Notes up to 5,000 chars, autosaved. | A | P1 |
| JR-06 | Delete + undo | Entry | Swipe/menu delete → confirm → Undo within 5 s | Entry restored. Without Undo it's gone. | A + C | P1 |
| JR-07 | Finish pending | Pending reading | Entry → "Finish reading" | Goes to S08 awaitingReading, then complete. | A `reading_failure_refund_test` | P0 |
| JR-08 | Patterns | ≥5 entries | Journal top | Patterns card (most drawn, suits, major/minor, reversed). Links go to Learn. Says "not predictions". | A + C | P2 |

## 7. Learn

| ID | Area | Preconditions | Steps | Expected | Exec | Pri |
|---|---|---|---|---|---|---|
| LRN-01 | Deck grid | Offline OK | Learn tab | 78 cards grouped by Major/Wands/Cups/Swords/Pentacles. | A + C | P1 |
| LRN-02 | Deck search | LRN-01 | Search by name and keyword (e.g. in `uk`) | Matches. `searchEmpty`. | A | P2 |
| LRN-03 | Card detail | LRN-01 | Open a card; Reversed toggle; tap art; prev/next | Upright and reversed meanings and aspects, full-screen zoom, "drawn N times" linking to the filtered journal. | A + C | P1 |
| LRN-04 | Spreads guide | Learn | Spreads → each of the 6 → "Start this spread" | Layout diagram and position meanings. Start goes to S07 with that spread. | A + C | P1 |
| LRN-05 | About | Learn | About tarot & Taro | Article including AI limits and the disclaimer. | C | P1 |
| LRN-06 | Learn offline | Airplane mode | All of the above | Fully works, no gating. | M (airplane) / A | P1 |

## 8. Settings, data, help, legal

| ID | Area | Preconditions | Steps | Expected | Exec | Pri |
|---|---|---|---|---|---|---|
| SET-01 | Language ×12 | Settings → Language | Select each of the 12 locales plus System | All visible strings change. No overflow. Deck content is localized. | C (tour per locale) + A | P0 |
| SET-02 | RTL Arabic | Select `ar` | Tour all tabs and a reading | Mirrored layout, directional padding, correct digits and text alignment. | A `rtl_locale_test` + C | P0 |
| SET-03 | Theme | Settings → Theme Light/Dark/System; system dark mode | Tour | Tokens are applied in dark mode with no unreadable text, including the reading result and S10. | C | P1 |
| SET-04 | Reversals / haptics | Toggle | Draw | Reversals respected. Haptics on/off. | A + M (haptics) | P2 |
| SET-05 | Reminder | Settings → Reminder | Enable, set 21:30; grant POST_NOTIFICATIONS | Notification at that time with a rotating variant, never revealing a card. Tapping it opens `taro://daily` (S13). | M (adb `cmd alarm` / wait) | P1 |
| SET-06 | Reminder permission denied | Deny the OS permission | Enable the toggle | "Notifications are off in system settings" + Open settings, which opens the app notification settings. | M | P1 |
| SET-07 | Privacy toggles | S23 | AI sharing view/grant/revoke; usage analytics toggle | Revoke makes the next Begin show S04. The analytics toggle persists. Ad privacy row as in UMP-03. Android shows no ATT row. | A + C | P0 |
| SET-08 | Export | Journal data | Settings → Export | `taro-backup-YYYY-MM-DD.json` is created and the share sheet opens. Works offline. | A `export_import_test` + M (share sheet) | P1 |
| SET-09 | Import merge | Backup file pushed via adb to Downloads | Import → pick → preview → Merge | Preview counts and "balance not part of backups". Merge unions entries. | A + M (system file picker) | P1 |
| SET-10 | Import replace | Same | Replace → confirm | Journal replaced. | A | P1 |
| SET-11 | Import invalid | Non-Taro JSON / newer schema / corrupted checksum / extra `credits` key | Import | `invalid(notTaro / newerVersion "Update Taro…" / corrupt)`. | A | P1 |
| SET-12 | Delete all data | Data + credits | Delete → confirm ×2 | Local journal and prefs are wiped, `DELETE /v1/installs/me` is called, and the copy says "Your remaining readings and Remove Banner Ads are kept". The balance stays the same after relaunch. | A + B `qa/delete_data_staging_test` | P0 |
| SET-13 | Delete offline | Airplane | Delete | `partial`: local wiped, Worker deletion queued, then sent when back online. | A | P2 |
| HLP-01 | FAQ | Settings → Help | Open FAQ | Offline authored content. Explains that readings are tied to the install and that consumables aren't restorable. | C | P1 |
| HLP-02 | Crisis from Help | Settings → Help → Crisis resources | Open | Device-region resources plus findahelpline. Works offline. Phone/URL taps open the dialer/browser. | C + M | P0 |
| HLP-03 | Contact support | Help | Contact support | A mailto intent with app version, OS, locale and Support ID (8 hex chars, matching About). | M | P1 |
| HLP-04 | Legal | About | Disclaimer / Terms / Privacy / Licenses | Terms and privacy open `taro.vshyrochuk.com` in a custom tab or webview. The licenses page lists the packages. The disclaimer is in-app. | C + M | P0 |
| HLP-05 | No iOS/Apple text | Whole tour (Android build) | Review strings | No "App Store", "iOS" or "Apple" mentions on Android. No banned claims. | C review | P0 |

## 9. Deep links

| ID | Area | Preconditions | Steps | Expected | Exec | Pri |
|---|---|---|---|---|---|---|
| DL-01 | taro://daily | Onboarded | `adb shell am start -a android.intent.action.VIEW -d "taro://daily"` | Opens S13. | M (adb) / B | P1 |
| DL-02 | taro://reading/new | Onboarded | `-d "taro://reading/new?spread=celtic_cross"` | S07 with the Celtic Cross. An unknown spread falls back safely. | M | P1 |
| DL-03 | taro://journal/{id} | Existing / missing id | Open | S15, or an empty/error state for an unknown id with no crash. | M | P2 |
| DL-04 | taro://learn/card/{id} | – | `major_17` | S17. | M | P2 |
| DL-05 | taro://store | – | Open | S11. | M | P2 |
| DL-06 | App Links | `assetlinks.json` live | `adb shell pm get-app-links <pkg>`; open `https://taro.vshyrochuk.com/app/daily` | Domain is verified. The link opens the app, not the browser. | M | P1 |
| DL-07 | During onboarding | Fresh install | Fire `taro://store` on S02 | Queued until Home, then S11. | M | P1 |
| DL-08 | Cold vs warm | Killed / backgrounded | Each link | Both paths route correctly. | M | P2 |

## 10. Platform behaviour, resilience, accessibility

| ID | Area | Preconditions | Steps | Expected | Exec | Pri |
|---|---|---|---|---|---|---|
| PLT-01 | Offline mode | Airplane mid-session | Start a reading; daily card; Learn; Journal | S07 `offline`: Begin disabled with a notice. Classic reading available. Other areas work. Back online leads to a resync. | A + M | P0 |
| PLT-02 | Resume re-sync | App open across midnight | Background, advance the clock, resume | Balance, daily card and reminder recomputed (SyncCoordinator). | A `daily_reset_resume_test` + M | P0 |
| PLT-03 | Process death | On S09 / S07 / mid-draw | Developer options "Don't keep activities", or `am kill` in the background | State restored or a safe pending reading. No lost credit. | A `os_restore_test` + M | P1 |
| PLT-04 | Reinstall | Purchased install | Uninstall/reinstall (Android: no Keychain) | A new install ID. Credits not carried over (FAQ copy). The transfer flow is available. | A `reinstall_same_install_id_test` (iOS semantics) + M | P2 |
| PLT-05 | Text scale 200% | `adb shell settings put system font_scale 2.0` | Tour all screens | No clipping or overflow. Buttons still reachable. Key screens are usable. | C | P0 |
| PLT-06 | TalkBack basics | TalkBack on | Onboarding, start a reading, pick cards, reveal, read the result, close S10 | Every interactive element and card has a label. Orientation is spoken. Targets are ≥48 dp. Focus order is logical. | M | P0 |
| PLT-07 | Back button | Each screen | System back / predictive back | Tabs: back on a non-Today tab goes to Today, then exits. Sheets close. S08 shows the confirm dialog. S09 goes to Home. S30 can't be bypassed. | A partial + M | P1 |
| PLT-08 | Rotation | Phone | Rotate on Home, S07, S08, S09 | No crash or state loss. The layout adapts or orientation is locked per spec. | M | P2 |
| PLT-09 | Tablet layout | Pixel Tablet AVD | Tour ★ screens | Tablet layouts (S05, S06, S07, S08, S09, S10, S11, S13, S14, S16, S20, S25, S27, S30, S32) look correct. | C (tablet AVD) | P1 |
| PLT-10 | Kill switches | Fake config | `readings.enabled=false`, a spread disabled, store/ads/rewarded off | Paused state rather than a paywall. Hidden spreads. No broken entry points. | A `kill_switch_test` | P0 |
| PLT-11 | Review guidelines | – | Run the existing flow | Close buttons, disclaimers, no pre-checks. | A `review_guidelines_test` | P0 |
| PLT-12 | Cold start perf | Release build | Cold start | Within the 06 budget. | A `perf/cold_start_test` | P2 |

## Execution order

1. **A**: run the 17 existing flows on emulator-5554 (`flutter test integration_test/flows -d emulator-5554 --flavor dev --dart-define-from-file=config/dev.json`).
2. **B**: write and run `integration_test/qa/` staging tests: onboarding, safety (rephrase + crisis), rewarded, delete data, unverified, and one `single` plus one `three_ppf` reading. Use `pm clear` between tests that need a fresh free reading.
3. **C**: the screenshot tour for phone (en, ar, de at 200 % text, dark) and the tablet AVD.
4. **M**: adb-driven manual checklist (deep links, notifications, share/file picker, TalkBack, rotation, airplane mode). Play sandbox cases wait for an internal-testing upload.

## Case count by method

A case can carry more than one method, so the method counts overlap.

| Method | Cases using it |
|---|---|
| A (existing fake-backed flows) | 97 |
| B (new real-staging) | 23 |
| C (screenshot tour) | 43 |
| M (manual / real device / sandbox) | 48 |
| Total distinct cases | 135 (P0: 53, P1: 60, P2: 22) |
