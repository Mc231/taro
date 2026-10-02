# Processors and third parties

Sprint 19.2 (05 §5, RC97). This file is the source for every processor claim in the AI consent copy (`aiConsentBody`, 05 §3), the privacy policy (`web/privacy.{locale}.md`) and the store privacy forms (`PRIVACY_LABELS.md`). If a row changes, those texts change in the same PR.

**Scope at launch (2026-10-01, 00_DECISIONS):** `ai.disclosedProviders = ["openai"]` and `ai.moderation.provider = "openai"` (`worker/config/remote_config.default.json`). Anthropic is **not** a processor at launch and is not named anywhere user-facing. If a provider is added to `ai.disclosedProviders`, it gets a row here first, `ai.consentVersion` is bumped, and the policy and consent copy are updated together.

Checked on **2026-10-02** by the Phase 19 agent with WebFetch against the official pages below. Pages that refused automated fetching (HTTP 403) are marked **verify manually**.

## Summary

| Processor | Role | Data received | Training on our data | Retention at the processor | Transfer basis |
|---|---|---|---|---|---|
| OpenAI (API: `/v1/responses`, `/v1/moderations`) | Processor: writes AI readings; moderates questions and output | Question, drawn cards, spread, locale (readings); question and output (moderation). No install ID, no vendor user ID (03 §13) | **No** (API data not used for training unless the customer opts in) | Abuse-monitoring logs up to **30 days** for `/v1/responses`; **none** for `/v1/moderations`. We send `store: false`, so no application state is kept. ZDR: `/v1/responses` is eligible on approval (not requested for v1) | OpenAI DPA with SCCs (verify manually) |
| Cloudflare (Workers, D1, KV, Workers Logs, Analytics Engine) | Processor: hosts the API and its data | All Worker traffic and the data in 03 §13 | **No** (DPA limits processing to providing the services; no marketing use) | Our data per 03 §13; Workers Logs **7 days** on the paid plan (3 days free) | Cloudflare Customer DPA v6.4 with EU SCCs (Modules 2 and 3), UK Addendum, Swiss adaptation |
| Google: Firebase Crashlytics | Processor | Crash stack traces, Crashlytics installation UUID, device and OS data | Not stated as training; used to provide the service | **90 days** | Firebase Data Processing and Security Terms (SCCs) |
| Google: Google Analytics for Firebase | Processor (with consent mode, RC68) | App interactions, app-instance ID, coarse device data; never question, reading or journal text | Not used for ads while consent is denied (consent mode) | Property setting: **2 or 14 months** (owner sets 14 months, **MANUAL** in the GA console) | Google Ads Data Processing Terms v8.0 (SCCs) |
| Google: AdMob (+ UMP) | Independent controller for personalised ads; processor for non-personalised ads, per Google's terms | Advertising ID (IDFA only after ATT allow), IP-derived coarse location, ad interactions; reward `intentId` via SSV, never the install ID (03 §13) | Google's own ads terms | Google's own retention | Google Ads Data Processing Terms / Controller-Controller terms (SCCs) |
| Apple (App Store, StoreKit, DeviceCheck, App Attest) | Independent controller (store); service provider (attestation) | Purchase receipts / signed transactions; DeviceCheck bit; attestation | n/a | Apple's own | Apple Developer Program License Agreement |
| Google Play (Billing, Play Integrity) | Independent controller (store); service provider (integrity) | Purchase tokens; integrity verdicts | n/a | Google's own | Google Play Developer Distribution Agreement |

## Sources

| Item | Source URL | Checked | Result |
|---|---|---|---|
| OpenAI API data controls (training, retention per endpoint, ZDR) | https://developers.openai.com/api/docs/guides/your-data (redirect from platform.openai.com/docs/guides/your-data) | 2026-10-02 | "As of March 1, 2023, data sent to the OpenAI API is not used to train or improve OpenAI models (unless you explicitly opt in…)". Abuse monitoring "retained for up to 30 days, unless longer retention is required by law". `/v1/moderations`: abuse-monitoring retention None, application state None. `/v1/responses`: 30 days, application state None (with `store: false`). |
| OpenAI Data Processing Addendum | https://openai.com/policies/data-processing-addendum/ | 2026-10-02 | HTTP 403 to automated fetch. **Verify manually**: version/date, SCC modules, sub-processor list. Execute the DPA in the OpenAI dashboard (**MANUAL**, owner). |
| OpenAI Business Terms / Services Agreement | https://openai.com/policies/business-terms | 2026-10-02 | HTTP 403. **Verify manually**: effective date; "we will not use Customer Content to develop or improve the Services". |
| OpenAI enterprise privacy page | https://openai.com/enterprise-privacy/ | 2026-10-02 | HTTP 403. **Verify manually**. |
| Cloudflare Customer DPA | https://www.cloudflare.com/cloudflare-customer-dpa/ | 2026-10-02 | Version 6.4, effective 3 April 2026. EU SCCs Module 2 and 3, UK Addendum, Swiss FADP. §3.1: processing only for providing the Services; no marketing or advertising use. |
| Cloudflare Workers Logs retention | https://developers.cloudflare.com/workers/observability/logs/workers-logs/ | 2026-10-02 | Free plan 3 days, Paid plan 7 days. Matches 03 §13 "Logs 7 days" on the paid plan (**MANUAL**: confirm the account is on Workers Paid). |
| Firebase Data Processing and Security Terms | https://firebase.google.com/terms/data-processing-terms | 2026-10-02 | Last modified 21 August 2024; covers Firebase services incl. Crashlytics; SCCs (C2P, P2C, P2P) via Google's Data Transfer Solution. |
| Firebase privacy and Crashlytics retention | https://firebase.google.com/support/privacy | 2026-10-02 | Crashlytics keeps stack traces and identifiers (Crashlytics installation UUIDs, Firebase installation IDs) for 90 days. Google Analytics is "subject to separate terms". |
| Google Ads Data Processing Terms (AdMob, Analytics) | https://business.safety.google/adsprocessorterms/ | 2026-10-02 | Version 8.0, last modified 30 May 2024; SCCs (C2P, P2C, P2P); US state law appendix 3B. Product list: https://business.safety.google/adsservices/ |
| GA4 data retention | https://support.google.com/analytics/answer/7667196 | 2026-10-02 | Standard properties: 2 or 14 months for event-level data. |

## Claims derived from this file

| Claim | Where | Holds because |
|---|---|---|
| "OpenAI does not use this data to train its models." | `aiConsentBody` (12 locales), privacy §AI processing | OpenAI API data controls (row 1); OpenAI is the only entry in `ai.disclosedProviders`. Must hold for **every** listed provider (RC97). |
| "OpenAI may keep API requests for up to 30 days to detect abuse; moderation requests are not retained." | privacy §AI processing | Row 1, `/v1/responses` and `/v1/moderations`; the Worker calls only these (`worker/src/adapters/openai/OpenAiProvider.ts`, `store: false`). |
| "We never send your name, email, installation ID or advertising ID." | `aiConsentBody`, privacy | 03 §13: no install ID and no `user`/`safety_identifier`/`metadata.user_id` sent in v1. |
| "Server logs are kept for 7 days." | privacy §Retention | Workers Logs paid-plan retention (row Cloudflare) = 03 §13. |
| Processors and SCCs: Cloudflare, OpenAI, Google | privacy §Security and international transfers | Summary table. |

## Territory availability (CS16, RC29)

There is one config file for every environment (`worker/config/remote_config.default.json`, pushed by `npm run config:push -- --env prod`), so there is no prod overlay. Prod `ai.blockedCountries` is the value in that file: **70 codes** = the CS16 fixed list (CN RU SA AE QA KW BH OM) + the union of the Anthropic and OpenAI unsupported-country snapshots of 2026-09-30 (00_DECISIONS CS16). With OpenAI as the only routable provider since 2026-10-01, the Anthropic-only exclusions (AF AW AX BL BM FO GF GL GP KY MF MM MQ NC PF PM RE SH SJ TF WF YE YT) could be reopened. That is an **owner decision**, and it must stay in step with the store availability list (ASA-9, Phase 20). The list is unchanged until then.

## Sign-off

- [ ] Owner confirms the provider list (`ai.disclosedProviders = ["openai"]`) and the claims above *(MANUAL, before Phase 22 submission)*. Date / initials: ______
- [ ] OpenAI DPA executed and the 403 rows above verified by hand *(MANUAL)*.
- [ ] GA4 retention set to 14 months; Workers Paid plan confirmed *(MANUAL)*.
