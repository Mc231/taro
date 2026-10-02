# Privacy labels: App Store App Privacy and Play Data Safety

Sprint 19.2. Final answers for both store forms, derived from 05 §5.1 / §5.2 and cross-checked against what the code actually does. Processors and their terms: `PROCESSORS.md`. The iOS privacy manifest (`apps/taro/ios/Runner/PrivacyInfo.xcprivacy`) declares the same App Store rows; `tools/check_manifests.py` fails if the manifest and the table below (its `COLLECTED` map) drift.

Launch scope: the only AI processor is OpenAI (readings and moderation, `ai.disclosedProviders = ["openai"]`, 2026-10-01).

## Cross-check sources

| Ref | Source | What it contributes |
|---|---|---|
| W | 03 §13 Worker data inventory (as amended by RC22, RC37, RC51, RC53, RC69) | install UUID, device-key hash (Android), timezone/locale, ledger and purchases, reading metadata, encrypted reading text ≤ 7 days, reports 90 days, reward intents, daily counters, logs 7 days; question never stored; no install ID to the AI provider |
| F | Firebase Analytics + Crashlytics (AR19, consent mode RC68) | app interactions (consent mode: denied until UMP resolves), crash and performance data; Crashlytics UUID is not our install ID |
| A | AdMob + UMP + ATT (RC18, RC19, RC59) | IDFA only after ATT allow, AAID on Android (`AD_ID` permission, merged manifest), IP-derived coarse location, ad interactions; SSV carries the opaque `intentId`, never the install ID |
| R | Report flow (RC22, CS7) | question, reading text and note, AES-GCM, `reading_reports` keyed by `install_id`, 90 days |

## App Store App Privacy

| Data type | Collected | Linked to user | Tracking | Purposes | Cross-check |
|---|---|---|---|---|---|
| Identifiers → User ID (install UUID) | Yes | Yes | No | App Functionality | W: `installs`, ledger, purchases keyed by it |
| Identifiers → Device ID (IDFA) | Yes, only after ATT allow | No | **Yes** | Third-Party Advertising | A |
| Purchases → Purchase History | Yes | Yes | No | App Functionality | W: `purchases`, `ledger` (7 years) |
| User Content → Other User Content (questions; reported readings) | Yes | **No (05 §5.1), see D1** | No | App Functionality | W: question sent to OpenAI, not stored; R: report stored with `install_id` |
| Usage Data → Product Interaction | Yes | No | No | Analytics | F |
| Usage Data → Advertising Data | Yes | No | **Yes** | Third-Party Advertising | A |
| Location → Coarse Location (IP-derived, AdMob) | Yes | No | **Yes** | Third-Party Advertising | A. The Worker does not store IP or country (W) |
| Diagnostics → Crash Data | Yes | No | No | App Functionality | F (Crashlytics) |
| Diagnostics → Performance Data | Yes | No | No | App Functionality | F |
| Contact info, Health and Fitness, Financial info, Precise location, Contacts, Browsing/Search history, Sensitive info, Other Diagnostic Data | No | | | | W, F, A: none collected |

Tracking: **Yes** (NSPrivacyTracking = true; tracking domains come from the Google Mobile Ads SDK's own privacy manifest).

## Google Play Data Safety

| Question / data type | Answer | Cross-check |
|---|---|---|
| Collects or shares required user data types | Yes | |
| All collected data encrypted in transit | Yes (HTTPS only; cleartext only in the dev flavor, `usesCleartextTraffic`) | merged manifest |
| Users can request deletion | Yes: in-app "Delete all data" (S26, RC37) and support email | W: `DELETE /v1/installs/me` |
| Location → Approximate location | Collected, shared (AdMob); Advertising or marketing; required for the ads SDK; not ephemeral | A |
| Financial info → Purchase history | Collected, not shared; App functionality, Fraud prevention / security | W |
| App activity → Other user-generated content (questions, reports) | Collected, not shared (OpenAI is a service provider); App functionality; optional (only when AI readings are used) | W, R |
| App activity → App interactions | Collected, not shared; Analytics | F |
| App info and performance → Crash logs, Diagnostics | Collected, not shared; Analytics, App functionality | F |
| Device or other IDs (install ID, Android device key, Advertising ID) | Collected; Advertising ID shared with AdMob for Advertising; install ID and device key not shared, App functionality, Fraud prevention / security and compliance (RC53) | W, A; `AD_ID` declared in the merged manifest (`check_manifests.py`) |
| Personal info, Health and fitness, Messages, Photos and videos, Audio, Files and docs, Calendar, Contacts, Web browsing | Not collected | |
| Independent security review | No | |

## Findings from the cross-check

- **D1 (owner decision, open).** Reported readings are stored in `reading_reports` with `install_id` (03 §3, migration `0001`), and 05 §5.1 marks the install UUID as data *linked* to the user. Under Apple's definition, the reported question and reading are therefore linked through the install ID. 05 §5.1 (the owner of this row) says "Linked: No". **Recommendation:** answer **Linked: Yes** for Other User Content. Over-declaring is safe in review, and under-declaring is a 5.1.2 risk. If the owner agrees, update 05 §5.1, `PrivacyInfo.xcprivacy` (`NSPrivacyCollectedDataTypeLinked = true` for OtherUserContent) and `COLLECTED` in `tools/check_manifests.py` together. Until then, all three follow 05 §5.1.
- The question for a normal reading is not stored (W). It is still "collected" under both stores' definitions because it leaves the device. That is why the row is "Yes" for both stores.
- The Android device key (`installs.device_key_hash`) is a Play "Device or other IDs" item only. iOS uses DeviceCheck, whose bit Apple holds, so nothing extra is collected on iOS.
- The Worker keeps no IP addresses or country, only short-lived keyed prefix hashes (≤ 48 h, W). The coarse-location row exists only because of AdMob.
- Analytics consent defaults are `false` on both platforms (RC68), verified by `tools/check_manifests.py` on the release `Info.plist` and the merged `AndroidManifest.xml`.

## Sign-off

- [ ] D1 decided by the owner. Date / initials: ______
- [ ] Owner confirms these answers before entering them in App Store Connect and Play Console (M6, Phase 20/21) *(MANUAL)*. Date / initials: ______
- [ ] Xcode privacy report of the release archive matches this table (Organizer → Generate Privacy Report) *(MANUAL)*.
