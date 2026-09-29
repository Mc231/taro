# Support: move readings between installs

Owner-run support procedures for paid credits: moving readings to a new install, manual ledger adjustments, refund debts and blocking. Specs: 03 §6.5–§6.6, 04 §12.9, RC43, RC84, BE-R3. There is **no admin HTTP route and no admin secret**: everything runs from `worker/` on the owner's machine through `wrangler d1 execute`, with the logic in tested modules (`src/admin/creditsTransfer.ts`, `src/admin/ledgerAdjust.ts`, RC61).

Never paste a full install ID, a transfer code or a secret into an issue, a chat, a commit or the drill log. The scripts print install prefixes (8 characters) only.

## When to use

| The user writes… | Procedure |
|---|---|
| "I reinstalled / got a new phone and my readings are gone" | [Move readings](#move-readings-lost-credits-after-reinstall) |
| "I watched an ad and got nothing" (grant never arrived) | [Manual adjustment](#manual-adjustment) on `bonus` |
| "I can't buy readings, it says contact support" (`purchasesBlockedReason = refundDebt`) | [Settle a refund debt](#settle-a-refund-debt) |
| Abuse (repeated refunds that the automatic threshold missed) | [Block an install](#block-or-unblock-an-install) |

Why a transfer is needed: paid credits belong to an install ID. iOS keeps it in the Keychain across reinstalls, so it is lost only on a new iPhone without Keychain migration; Android loses it on every reinstall (Auto Backup is excluded). Free readings do not reset on a new install (device key, 03 §3.7), so nothing is owed for those. Remove Banner Ads is restored by the store itself ("Restore purchases"), never by support.

## Before you start (once per machine)

1. `cd worker && npm ci` (Node 22).
2. `npx wrangler login` with the owner Cloudflare account (D1 edit on staging and prod).
3. Know where the secrets are: `SECRETS_PASSPHRASE=$TARO_SECRETS tools/secrets-manager.sh list` shows the section and key name of `TRANSFER_TOKEN_KEY` for each environment. Do not print its value.

## Move readings (lost credits after reinstall)

What the user needs to send: the **transfer code** and the **Support ID** of the **new** install. An order ID or a receipt screenshot is never enough (order IDs appear on emailed receipts).

### 1. Reply to the user with these steps

> 1. Install the app on the new device and open it once, signed in to the **same** App Store / Google Play account you used to buy.
> 2. Go to **Settings → Help → "Move readings from another device"**. The app re-submits your earlier purchases.
> 3. The app shows a **transfer code** (it starts with `tt1.`). It is valid for 7 days.
> 4. Open **Settings → About** and copy the **Support ID** (8 characters).
> 5. Reply with the transfer code and the Support ID.

If the app shows no transfer code, the purchases were granted to the new install directly (the balance should already show them) or were never claimed by another install. Ask the user to pull to refresh the balance; if readings are still missing, ask for the store order ID and handle it as a [manual adjustment](#manual-adjustment) after checking the purchase.

### 2. Check what you received

- The code starts with `tt1.` and has three dot-separated parts. Copy it exactly (no line breaks).
- The Support ID is 8 hex characters (`0-9`, `a-f`). Case and surrounding spaces do not matter.
- Pick a ticket ID: the support thread ID, e.g. `T-2026-0142`. Allowed: letters, digits, `.`, `_`, `-`, at most 64 characters. **One ticket ID per transfer code.** If a user sends two codes (two purchases), use `T-2026-0142-a` and `T-2026-0142-b`.
- A code older than 7 days is refused: ask the user to repeat step 1.2–1.5 for a new one.

### 3. Dry run (staging first if you are unsure)

```bash
cd worker
export TRANSFER_TOKEN_KEY="$(SECRETS_PASSPHRASE=$TARO_SECRETS ../tools/secrets-manager.sh get <prod section> TRANSFER_TOKEN_KEY)"
npm run credits-transfer -- --env prod --ticket T-2026-0142 \
  --code 'tt1.…' --support-id 1a2b3c4d --dry-run
```

The dry run verifies the code (HMAC, 7-day TTL), checks that the Support ID is the hash prefix of the install the code was issued to, reads the purchase, both installs and this ticket's ledger rows, and prints the plan:

```
[dry-run] apply: ticket T-2026-0142: 7 paid credit(s) 0c5f1e2a → 9b8d7c6e (purchase 01923a4b)
INSERT INTO ledger … (IDs shown as <0c5f1e2a…>)
nothing written (--dry-run).
```

The amount is `min(unspent paid credits of the old install, credits of the proven purchase)`. Readings already used on the old install are not moved again. A line `note: the purchase is a sandbox/test purchase` means the code came from TestFlight or a license tester: do not transfer on prod for a customer ticket.

### 4. Apply

Run the same command without `--dry-run`:

```
transferred (prod, remote): ticket T-2026-0142: 7 paid credit(s) 0c5f1e2a → 9b8d7c6e (purchase 01923a4b)
```

What it wrote, in one `wrangler d1 execute` call: two paired `admin_adjust` ledger entries on `paid` (`ref_type = 'admin'`), `ref_id = 'T-2026-0142#out'` (old install, `-7`) and `'T-2026-0142#in'` (new install, `+7`), both with the note `transfer purchase=<id> token=<digest> from=<old8> to=<new8>`, and a `state_version` bump on both installs so both apps refresh their balance. The script then reads the rows back and only reports success when both legs exist.

Exit codes: `0` moved (or already moved), `1` refused or failed, `2` usage.

### 5. Tell the user

> Done: 7 readings are now on your new device. Open the app (or pull to refresh the balance) to see them.

Then [record the transfer](#record-the-transfer).

### Refusals and what to do

| Message | Meaning / action |
|---|---|
| `transfer code is invalid or expired` | Typo, truncated code, or older than 7 days (or `TRANSFER_TOKEN_KEY` of the wrong environment). Ask for a fresh code. |
| `Support ID does not match the install that requested this transfer code` | The Support ID is from another device or mistyped. Ask for the Support ID of the device that showed the code. |
| `purchase was already transferred under ticket …; a transfer code works once` | This purchase already moved. Look up that ticket; do not transfer again. |
| `ticket … was already used for a different transfer` | Pick a new ticket ID (e.g. append `-b`). |
| `already applied: …` (exit 0) | This exact ticket already ran; nothing was written again. Safe. |
| `the old install has no unspent paid credits left; nothing to move` | Everything from the purchase was used, or refunded. Explain politely; no transfer. |
| `purchase was refunded (revoked)` | The store refunded it; nothing to transfer. |
| `the new install is unknown or erased` | The user has not opened the new app yet, or erased data. Ask them to open the app once, then retry. |
| `not applied: … the old install's paid balance changed; re-run to re-plan` | The old device used a reading in between. Re-run the same command; it plans again with the new balance. |
| `wrangler d1 execute failed … re-run the same command` | Network or auth problem. Re-run the same command: every statement is guarded, a partly written ticket is completed (`resume`), never doubled. |

## Manual adjustment

For a lost rewarded grant, a goodwill credit or a correction. The user sends their Support ID; a store order ID helps (`--txn`).

```bash
cd worker
npm run ledger-adjust -- --env prod --ticket T-2026-0150 --support-id 1a2b3c4d \
  --bucket bonus --delta 1 --note "SSV grant lost" --dry-run
npm run ledger-adjust -- --env prod --ticket T-2026-0150 --support-id 1a2b3c4d \
  --bucket bonus --delta 1 --note "SSV grant lost"
```

- The install is found by Support ID alone (the script scans install IDs page by page and hashes them locally), or faster with `--txn <Apple transactionId | Google order ID>` or `--install <full ID>` when you already have it. The Support ID must always match.
- `--delta` is a non-zero integer between -1000 and 1000. A negative delta never takes a bucket below 0.
- `--note` is short plain text (letters, digits, spaces, `. , : _ # / ( ) + -`); never paste the user's message.
- One adjustment per ticket and bucket (`ref_id = ticket`); a re-run prints `already applied`.
- Prefer `bonus` for goodwill. Use `paid` only to correct paid credits (it changes what a refund would claw back).

## Settle a refund debt

A negative paid balance means the user was refunded for readings they had already used (03 §6.5). New pack purchases stay disabled (`purchasesBlockedReason = refundDebt`) until the debt is settled. Settle it when the refund was a store error or you decide to forgive it:

```bash
npm run ledger-adjust -- --env prod --ticket T-2026-0160 --support-id 1a2b3c4d --settle-debt --dry-run
npm run ledger-adjust -- --env prod --ticket T-2026-0160 --support-id 1a2b3c4d --settle-debt
```

It adds `+|paid|` on `paid` with `ref_id = 'T-2026-0160#settle'`, only if the balance is still the one it planned for. `paid` is then 0 and purchases are allowed again.

## Block or unblock an install

Installs are blocked automatically at `abuse.refundBlockThreshold` refunds. To block or unblock by hand:

```bash
npm run ledger-adjust -- --env prod --ticket T-2026-0170 --support-id 1a2b3c4d --block
npm run ledger-adjust -- --env prod --ticket T-2026-0170 --support-id 1a2b3c4d --unblock
```

A blocked install keeps free readings, bonus and any positive paid credits; only purchases are disabled. A verified purchase is still granted and raises a `blocked_purchase` alert (support may refund it through the store).

## Record the transfer

In the support log (not in the repo): date, ticket ID, environment, the two install prefixes, the purchase prefix and the amount, exactly as the script printed them. The ledger keeps the durable record (`admin_adjust` rows with `ref_id` starting with the ticket ID, 7-year retention).

## Monitoring

`npm run metrics -- --query <events|verify|purchases|rewards|ssv-lag|alerts>` queries Analytics Engine (`CLOUDFLARE_ACCOUNT_ID`, `CLOUDFLARE_API_TOKEN` from the environment; `--print-sql` shows the SQL). `--query alerts` exits 3 when a rule fires: verify error rate > 2 % over 10 min, `ssv_rejected` spike, sandbox volume at half of `purchases.sandboxGlobalCreditsPerDay`, and any `blocked_purchase` in the last hour. Until the Phase 8 `AlertService` runs these in the 15-minute cron, check them when a user reports missing credits.
