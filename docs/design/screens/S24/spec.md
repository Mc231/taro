# S24 · Export backup

| | |
|---|---|
| Route | `/settings/export` |
| Banner | none |
| Artboards | [`../Export.dc.html`](../Export.dc.html) (a composite: the idle content + the `done` status notice) |
| Frames | [`Export.png`](../frames/Export.png) (PNG @2x, from the artboards above) |

## Layout (top → bottom)
Padding `space.10` / `layout.gutter` / 28; gap `space.5`.
1. Back; title "Export backup" serif 28; body "Keep a copy of your journal in one file."
2. "Included" panel (`color.bg.surface`, `radius.lg`, padding `space.5`): check icons (`color.status.success`) + `type.label` items: "Your journal" + the count at the end ("128 readings"), "Your notes", "Favourites", "Settings: theme, language, reminder".
3. "Not included" panel: minus icons (`color.text.tertiary`), each an item + a caption: "Readings balance and purchases / They stay with this install."; "Privacy and AI choices / You make them again on a new phone." (01 §7.11 exclusions).
4. File name chip (`color.bg.sunken`, `radius.md`, min 52, file icon): "taro-backup-2026-09-27.json" (`taro-backup-YYYY-MM-DD.json`).
5. Flexible spacer.
6. Status notice (`role=status`, `color.bg.surface`, `radius.md`): "**Backup saved.** Keep it somewhere private: it holds your questions and notes." (`done` only).
7. `TaroButton.primary` "Export backup" + caption "Opens the share sheet: Files, Drive, email and more."

## Components
Include/exclude list panel (**new**: `ChecklistPanel`, shared with S26), `TaroButton` (loading), `TaroInlineNotice`.

## States (01 §8.3)
| State | ★ | Source |
|---|---|---|
| idle | | **Designed** (the artboard without the status notice) |
| `preparing` | | Derived: the button in its loading state "Preparing…" (JSON built in an isolate) |
| `shareSheetOpen` | | OS share sheet; the button stays disabled |
| `done` | | **Designed** (the status notice) |
| `failed(storage)` | | Derived: `TaroInlineNotice(error)` "We couldn't create the backup file." + Retry |

## Motion
The notice fades in over `motion.duration.base`; reduced: instant.

## Semantics / reading order
Back → title → body → "Included" (header) + items → "Not included" (header) + items → file name → Export backup → caption. `done`/`failed` are announced politely.

## RTL
Mirrored; the file name stays LTR (bidi-isolated).

## Banner
None. No network is needed.

---

**Conventions (same in every S-spec).** Canvas px = dp/sp. Spacing 2/4/8/12/16/20/24/32/40/48/56/64 = `space.1`…`space.12`; odd canvas values (6, 10, 14, 18, 28) snap to the nearest token. Radius: 4 `radius.xs`, 8 `radius.sm`, 10 `radius.card`, 12 `radius.md`, 16 `radius.lg`, 24 `radius.xl`, 28 `radius.sheet`, 999 `radius.full`. Type: serif 40 `type.display`; serif 28 `type.headline`; serif 20–24 `type.cardName`; serif 16–18 paragraphs `type.bodyReading`; sans 20/600 `type.title`; sans 17–18/600 `type.titleSmall`; sans 16 `type.body`; sans 14–15/500 `type.label`; sans 12–13 `type.caption`; numerals `type.numeral`. Nothing renders below 12 sp (canvas 9–11 px badges become `type.caption`). Side gutter `layout.gutter` (16; onboarding pages use `space.7` = 24). Tablet: the content column is `layout.maxContentWidth` (600) centred, long text is capped at `layout.readingMaxWidth`. Controls drawn at 40–44 px keep their look but get a ≥ `size.touchTarget.min` (48) hit area. Colours are tokens only (`color.*`, names in 01 §14.1). Every ★ state is a golden in light + dark at phone and tablet width (01 §8.3, RC24). *Derived* means that no artboard exists: Phase 16/17 builds the state from the designed states, the tokens and the shared state widgets (01 §8.2), and REVIEW.md checks it.
