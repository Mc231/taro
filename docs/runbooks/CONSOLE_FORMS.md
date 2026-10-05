# Console forms runbook (Phase 20.4, M6, M8, M10)

The store forms that no API can fill. Every answer below comes from a spec. Do not improvise: if an answer looks wrong, change the spec first (05 owns store and legal answers, `docs/compliance/PRIVACY_LABELS.md` owns the privacy rows). Record each completed form with its date in `STORE_SUBMISSION.md` → Evidence log.

Identifiers: ASC app `6818775977`, bundle and package `com.vshyrochuk.taro`, version 1.0. Website `https://taro.vshyrochuk.com` (privacy `/privacy`, terms `/terms`, support `/support`). Contact `volodymyr.shyrochuk@gmail.com`. Phone: `~/pet/secure/taro/review_contact` (never commit it).

Status on 2026-10-05 (read back from both stores, see `STORE_SUBMISSION.md`): ASC listing text, age rating 13+, Lifestyle / Entertainment, availability (154 territories) and IAP localizations (4 × 12) are already live. Missing on ASC: screenshots, App Review details, IAP review screenshots, the forms below. Play listing text (12 locales) is live; screenshots, feature graphic and every App content form are missing.

---

## Part A. App Store Connect

### A1. App Privacy (05 §5.1, `PRIVACY_LABELS.md`)

ASC → Apps → Taro → **App Privacy** (left sidebar, under General).

1. **Privacy Policy URL** → Edit → `https://taro.vshyrochuk.com/privacy` → Save.
2. **Data Collection** → Get Started → "Do you or your third-party partners collect data from this app?" → **Yes, we collect data from this app** → Next.
3. Tick exactly these types, then Save:
   - Identifiers: **User ID**, **Device ID**
   - Purchases: **Purchase History**
   - User Content: **Other User Content**
   - Usage Data: **Product Interaction**, **Advertising Data**
   - Location: **Coarse Location**
   - Diagnostics: **Crash Data**, **Performance Data**
   - Leave unticked: Contact Info, Health & Fitness, Financial Info, Precise Location, Sensitive Info, Contacts, Browsing History, Search History, Other Diagnostic Data, Other Data.
4. For each type, click **Set Up** and answer the three questions:

| Data type | Purposes (tick only these) | Linked to the user's identity? | Used for tracking? |
|---|---|---|---|
| User ID | App Functionality | **Yes** | No |
| Device ID | Third-Party Advertising | No | **Yes** |
| Purchase History | App Functionality | **Yes** | No |
| Other User Content | App Functionality | **No** (05 §5.1; see D1 below) | No |
| Product Interaction | Analytics | No | No |
| Advertising Data | Third-Party Advertising | No | **Yes** |
| Coarse Location | Third-Party Advertising | No | **Yes** |
| Crash Data | App Functionality | No | No |
| Performance Data | App Functionality | No | No |

5. **Publish** (top right). Check that the preview shows "Data Used to Track You": Device ID, Advertising Data, Coarse Location; "Data Linked to You": User ID, Purchase History.

**D1 is still open** (`PRIVACY_LABELS.md` → Findings). The recommendation is **Linked: Yes** for Other User Content. If you take it, answer Yes in step 4 and update 05 §5.1, `PrivacyInfo.xcprivacy` and `tools/check_manifests.py` in the same change before you submit.

### A2. Content rights (05 §1 Apple technical declarations)

ASC → Taro → **App Information** (General) → **Content Rights** → Edit (or Set Up Content Rights).
- "Does your app contain, show, or access third-party content?" → **No, it does not contain, show, or access third-party content.** → Done → **Save**.

### A3. Export compliance (encryption)

The Info.plist sets `ITSAppUsesNonExemptEncryption = false` (HTTPS/TLS only), so builds normally skip the question. If ASC still asks (build page → "Missing Compliance", or at submission):
- "What type of encryption algorithms does your app implement?" → **None of the algorithms mentioned above** (the app only uses the encryption built into the operating system, for HTTPS). If the form instead asks "Does your app use encryption?" → **Yes**, then "Does your app qualify for any of the exemptions…?" → **Yes** (standard HTTPS only).
- "Is your app going to be available on the French store?" → answer as asked; no documentation is needed for exempt apps.
- Result: no export compliance documents to upload.

### A4. EU Digital Services Act trader status (05 §1, owner: individual trader)

ASC → **Business** (top bar) → your account → **Digital Services Act** → Edit / Complete compliance requirements.
1. "Are you a trader?" → **Yes, I am a trader** (the app is monetized).
2. Fill in the public contact details (these appear on the EU product page; they are already public in the privacy policy):
   - Name: Volodymyr Shyrochuk
   - Address: Skrypnuka St 278, Lviv 79049, Ukraine
   - Phone: from `~/pet/secure/taro/review_contact`
   - Email: volodymyr.shyrochuk@gmail.com
3. Verify the phone and email with the codes Apple sends → Submit. Apple reviews the details; the app cannot be released in the EU until they are verified.

### A5. App Review Information (CS11)

`asa ios update-review-info` has not been run yet (owner approval of live pushes pending). Either run it (Part C) and then add the phone by hand, or fill it by hand:
ASC → Taro → **iOS App 1.0** → scroll to **App Review Information**:
- **Sign-in required**: unticked (no login exists).
- Contact: Volodymyr / Shyrochuk / phone from `~/pet/secure/taro/review_contact` / volodymyr.shyrochuk@gmail.com.
- **Notes**: paste `app_review_information.notes` from `apps/taro/store/aso.yaml` (3,527 characters; it is the same text as `docs/compliance/REVIEW_NOTES.md`).
- Attachment: none.
- Save.

### A6. Version page leftovers

On the same **iOS App 1.0** page:
- **Copyright**: `2026 Volodymyr Shyrochuk` → Save.
- **License agreement** (App Information → License Agreement): keep **Apple's Standard License Agreement**. The terms link is already in every description (`https://taro.vshyrochuk.com/terms`).
- **Build**: pick the release build when Phase 21/22 uploads it.
- **Release**: "Manually release this version".
- **Age rating**: already 13+ (`ageRatingOverrideV2 = THIRTEEN_PLUS`, read back 2026-10-05). Nothing to do.

### A7. IAP review screenshots (M10)

Files: `build/store/iap_review/{readings_3,readings_10,readings_30,remove_ads}.png` (1290 × 2796, the S11 store screen with all four products, from the `s11_store_content` golden `phone_large_light_en`; regenerate with `sips -z 2796 1290 apps/taro/test/golden/goldens/s11_store_content/phone_large_light_en.png --out build/store/iap_review/<id>.png`).

For each of the four products: ASC → Taro → **Monetization → In-App Purchases** → product →
1. **Review Information** → Screenshot → Choose File → `build/store/iap_review/<product>.png`.
2. Review Notes (optional): `Purchased on the "More readings" screen (Settings → Store, or after the free daily reading). Readings are added by our server after Apple verifies the transaction.` For `remove_ads`: `Removes banner ads. Optional rewarded videos stay available.`
3. Save. Status changes from "Missing Metadata" to **Ready to Submit**. (If it does not, check Price Schedule and Availability: both were set in Phase 10.)
4. At submission (Phase 22): on the 1.0 version page → **In-App Purchases and Subscriptions** → Select → tick all four. First IAPs must go with the first version.

### A8. Agreements (check only)

ASC → **Business** → Agreements: the **Paid Apps** agreement must be Active (bank and tax done). Small Business Program enrolment (M12) is a separate form at developer.apple.com/app-store/small-business-program.

---

## Part B. Google Play Console

All steps: Play Console → **Taro: Tarot Card Reading**.

### B1. Store settings (M6)

Grow users → Store presence → **Store settings**:
- App category: **App**, category **Lifestyle**. Tags: Tarot, Self-improvement or the closest available (up to 5; optional).
- Store listing contact details: Email **volodymyr.shyrochuk@gmail.com**; Phone: leave empty; Website **https://taro.vshyrochuk.com** (this is the URL AdMob checks for `app-ads.txt`).
- External marketing: on (default).
- Save.

### B2. Policy → App content

Monitor and improve → Policy and programs → **App content**. Fill each card, then **Save** (and **Submit** where shown).

1. **Privacy policy**: `https://taro.vshyrochuk.com/privacy`.
2. **App access**: **All functionality in my app is available without any access restrictions.** (No login. The paid features are IAPs, which reviewers test with their own accounts.)
3. **Ads**: "Does your app contain ads?" → **Yes, my app contains ads.**
4. **Content rating** (IARC, 05 §6.2) → Start questionnaire:
   - Email: volodymyr.shyrochuk@gmail.com. Category: **All Other App Types** (not Game; not Reference, News or Educational; not Social or Communication).
   - Violence: **No**. Sexuality: **No**. Language (profanity, crude humour): **No**. Controlled substances: **No**. Gambling (real or simulated): **No**. Fear / horror: **No**.
   - User interaction: "Does the app allow users to interact or exchange content with each other?" → **No**. "Does the app share the user's current physical location with other users?" → **No**.
   - "Does the app allow users to purchase digital goods?" → **Yes**.
   - "Does the app contain web browsing / unrestricted internet access?" → **No**.
   - "Is the app a web browser or search engine?" → No.
   - Other questions (miscellaneous: swastikas, etc.) → **No**.
   - Save → Next → expected result PEGI 3 / ESRB Everyone / USK 0 → **Submit**. Accept the computed rating.
5. **Target audience and content** (RC93 overrides the 13–15 in the phase file; 05 §6.2):
   - Target age groups: tick **16–17** and **18 and over** only (not 13–15 or younger).
   - "Could your app unintentionally appeal to children?" → **No**.
   - Store presence / ads: confirm (ads are not designed for children; AdMob max rating T).
6. **News apps**: **No**, it is not a news app.
7. **COVID-19 contact tracing and status apps**: My app is **not** a publicly available COVID-19 app.
8. **Data safety** (05 §5.2, `PRIVACY_LABELS.md`) → Start:
   - Overview → Next.
   - Data collection and security: "Does your app collect or share any of the required user data types?" **Yes**. "Is all of the user data collected by your app encrypted in transit?" **Yes**. "Which of the following methods of account creation does your app support?" **My app does not allow users to create an account**. "Do you provide a way for users to request that their data is deleted?" **Yes** (in-app "Delete all data" and the support email). URL for deletion requests if asked: `https://taro.vshyrochuk.com/support`.
   - Data types: tick **Location → Approximate location**; **Financial info → Purchase history**; **App activity → App interactions** and **Other user-generated content**; **App info and performance → Crash logs** and **Diagnostics**; **Device or other IDs**. Nothing else.
   - Usage per type:

| Data type | Collected | Shared | Ephemeral | Required or optional | Purposes |
|---|---|---|---|---|---|
| Approximate location | Yes | **Yes** (AdMob) | No | Required | Advertising or marketing |
| Purchase history | Yes | No | No | Required | App functionality; Fraud prevention, security and compliance |
| App interactions | Yes | No | No | Required | Analytics |
| Other user-generated content | Yes | No (OpenAI is a service provider) | No | **Optional** | App functionality |
| Crash logs | Yes | No | No | Required | Analytics; App functionality |
| Diagnostics | Yes | No | No | Required | Analytics; App functionality |
| Device or other IDs | Yes | **Yes** (Advertising ID to AdMob) | No | Required | Collected for: App functionality; Advertising or marketing; Fraud prevention, security and compliance. Shared for: Advertising or marketing |

   - Independent security review: **No**. Preview → **Submit**.
9. **Advertising ID**: "Does your app use advertising ID?" → **Yes** → purposes: **Advertising or marketing**, **Analytics** (AdMob + Firebase); Save. The merged manifest declares `com.google.android.gms.permission.AD_ID` (`check_manifests.py`).
10. **Government apps**: **No**.
11. **Financial features**: **My app doesn't provide any financial features.**
12. **Health**: **My app does not have any health features** (health questions are refused, 05 §4.1).
13. **Actions on Google / other declarations** if shown: not applicable.

### B3. In-app products (check only)

Monetize → Products → **In-app products**: `readings_3`, `readings_10`, `readings_30`, `remove_ads` exist and are Active (Phase 10, `asa android setup-iap`). Do **not** recreate them. Check per-country prices once (asa known issue). Play does not need IAP review screenshots.

### B4. Play pricing programme (M12)

Setup → Advanced settings or Account → **15% service fee** enrolment (account group). Manual, once per account.

---

## Part C. Live pushes still pending (owner runs or approves)

The read-back on 2026-10-05 found these not yet live. From the repo root:

```bash
A=~/pet/app-store-automation/.venv/bin/asa; ASO=apps/taro/store/aso.yaml
$A ios update-review-info -c $ASO --platform ios     # then add the phone by hand (A5)
tools/screenshots/upload_store_assets.sh --dry-run   # 24 ASC + 36 Play uploads + feature graphic
tools/screenshots/upload_store_assets.sh             # ASC iphone-67 + ipad-129, Play phone/7"/10" x 12 locales, feature graphic
```

Notes:
- Both `asa … upload-screenshots` commands **append**; they do not replace. Run the upload once. To redo, delete the sets in the console first.
- asa prints failed uploads but still exits 0. Re-run the read-back (`STORE_SUBMISSION.md`) afterwards and check 7 screenshots per set.
- `push-localizations` (both stores), `localize-all-iaps`, `set-age-rating`, `set-app-availability` and `setup-iap` need no re-run: the read-back matched `aso.yaml`. ASC What's New is empty on purpose (Apple refuses it on a first version).

---

## Owner checklist

- [ ] A1 App Privacy (decide D1 first)
- [ ] A2 Content rights
- [ ] A3 Export compliance (only if asked)
- [ ] A4 EU DSA trader
- [ ] A5 App Review Information (phone)
- [ ] A6 Copyright, licence, release option
- [ ] A7 IAP review screenshots ×4 → Ready to Submit
- [ ] A8 Paid Apps agreement Active
- [ ] B1 Play store settings
- [ ] B2 App content: privacy, app access, ads, IARC, target audience, news, COVID, Data safety, Advertising ID, government, financial, health
- [ ] B3 Play IAP prices checked
- [ ] Part C pushes run and read back
- [ ] Each step dated in `STORE_SUBMISSION.md` → Evidence log
