# S25 · Import backup (pick → validate → preview → mode → result)

| | |
|---|---|
| Route | `/settings/import` |
| Banner | none |
| Artboards | [`../Import.dc.html`](../Import.dc.html) (`preview`) · [`../ImportInvalid.dc.html`](../ImportInvalid.dc.html) (`invalid(notTaro)`) |
| Frames | [`Import.png`](../frames/Import.png) · [`ImportInvalid.png`](../frames/ImportInvalid.png) (PNG @2x, from the artboards above) |

## Layout (top → bottom), `preview`
Padding `space.10` / `layout.gutter` / 28; gap `space.5`.
1. Back; title "Import backup" serif 28; body "Check what's in the file, then choose how to bring it in."
2. File card (`color.bg.surface`, `radius.lg`): an icon tile 40 (`color.accent.subtle`, `radius.card`); the file name `type.label`/600; "Exported 12 September 2026" `type.caption`; the summary `type.label` "96 readings · 40 notes · settings"; a divider; the status row (`role=status`, success icon `color.status.success`) "File checked. Everything looks right."
3. Link "Choose another file" (44 → 48 hit).
4. Fieldset "How to bring it in": two radio cards (`color.bg.surface`, `radius.lg`, padding 14 / `space.5`): **Merge with my journal** ("Adds what you don't have yet. If an entry is in both, the newer version is kept.") and **Replace my journal** ("Removes the journal on this phone and uses the backup instead. You'll confirm first."). Merge is the default (the non-destructive option).
5. Flexible spacer.
6. `TaroButton.primary` "Import" + caption "Backups don't include readings balance or purchases, so yours stays exactly as it is." (01 F5).

## Components
File summary card (**new**: `FileSummaryCard`), radio card (`SettingsTile` radio variant), `TaroButton`, `TaroDialog`, progress bar, `TaroInlineNotice`.

## States (01 §8.3)
| State | ★ | Source |
|---|---|---|
| `picking` | | Derived: the intro text + `TaroButton.primary` "Choose a file" → OS file picker (`.json`) |
| `validating` | | Derived: the file card with an indeterminate progress row "Checking the file…" |
| `invalid(reason)` | ★ | **Designed** for `notTaro`: `ImportInvalid.dc.html` ("This file isn't a Taro backup"; the ARB copy wins over the wording below if they differ at review). The other reasons are derived from it: the file card the status row in `color.status.error` with the reason copy: `notTaro` "This isn't a Taro backup file", `newerVersion` "Update Taro to import this backup" (+ store link), `corrupt` "This file is damaged and can't be imported", `tooLarge` "This file is larger than 20 MB". The mode fieldset is hidden; the primary becomes "Choose another file". Each reason needs a golden (only `notTaro` is drawn) |
| `preview` | ★ | **Designed**: `Import.dc.html` |
| `confirmReplace` | | Derived: `TaroDialog` "Replace your journal? The 128 entries on this phone will be removed." [Replace] (destructive, `color.status.error`) [Cancel] |
| `importing(progress)` | | Derived: a determinate progress bar + "Importing 40 of 96…"; back disabled |
| `done(summary)` | | Derived: a success notice "Imported 96 readings and 40 daily cards" + `TaroButton.primary` "Open Journal" |
| `failed` | | Derived: `TaroInlineNotice(error)` + Retry; the journal is unchanged |

## Motion
Card status changes cross-fade over `motion.duration.base`; progress is linear; reduced: no cross-fade.

## Semantics / reading order
Back → title → body → file card (one node: name, export date, summary, status) → Choose another file → the "How to bring it in" radio group → Import → caption. Validation results and progress are announced (polite; errors assertive).

## RTL
Mirrored; the file name is bidi-isolated LTR; radios sit on the right.

## Banner
None. Import never calls AI and never touches the balance.

---

**Conventions (same in every S-spec).** Canvas px = dp/sp. Spacing 2/4/8/12/16/20/24/32/40/48/56/64 = `space.1`…`space.12`; odd canvas values (6, 10, 14, 18, 28) snap to the nearest token. Radius: 4 `radius.xs`, 8 `radius.sm`, 10 `radius.card`, 12 `radius.md`, 16 `radius.lg`, 24 `radius.xl`, 28 `radius.sheet`, 999 `radius.full`. Type: serif 40 `type.display`; serif 28 `type.headline`; serif 20–24 `type.cardName`; serif 16–18 paragraphs `type.bodyReading`; sans 20/600 `type.title`; sans 17–18/600 `type.titleSmall`; sans 16 `type.body`; sans 14–15/500 `type.label`; sans 12–13 `type.caption`; numerals `type.numeral`. Nothing renders below 12 sp (canvas 9–11 px badges become `type.caption`). Side gutter `layout.gutter` (16; onboarding pages use `space.7` = 24). Tablet: the content column is `layout.maxContentWidth` (600) centred, long text is capped at `layout.readingMaxWidth`. Controls drawn at 40–44 px keep their look but get a ≥ `size.touchTarget.min` (48) hit area. Colours are tokens only (`color.*`, names in 01 §14.1). Every ★ state is a golden in light + dark at phone and tablet width (01 §8.3, RC24). *Derived* means that no artboard exists: Phase 16/17 builds the state from the designed states, the tokens and the shared state widgets (01 §8.2), and REVIEW.md checks it.
