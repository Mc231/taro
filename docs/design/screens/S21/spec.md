# S21 · Language picker

| | |
|---|---|
| Route | `/settings/language` |
| Banner | none |
| Artboards | [`../Language.dc.html`](../Language.dc.html) |
| Frames | [`Language.png`](../frames/Language.png) (PNG @2x, from the artboards above) |

## Layout (top → bottom)
Padding `space.10` / `layout.gutter` / 28; gap `space.5`.
1. Back.
2. Title "Language" serif 28; body `type.label` `color.text.secondary`: "Menus, card meanings and new readings use this language."
3. Radio group (legend "App language", visually hidden):
   - the "Use phone language" tile (min 64, `color.bg.surface`, `radius.lg`), subtitle `type.caption` "English, from your phone settings", radio at the end;
   - the caption "Choose a language" (hidden from semantics, since the legend covers it);
   - the list in one `color.bg.surface` `radius.lg` group, rows 48, radio at the end. The 12 locales appear as endonyms, each rendered in its own script font with `lang` set: English, العربية (IBM Plex Sans Arabic, RTL), Deutsch, Español, Français, Italiano, 日本語, 한국어, Nederlands, Português, Türkçe, Українська.
4. Info notice (`color.bg.sunken`, `radius.md`, info icon): "Past readings in your journal keep the language they were written in. Only new readings change." (01 §13).

## Components
`SettingsTile` (radio variant), radio, `TaroInlineNotice(info)`.

## States (01 §8.3)
| State | ★ | Source |
|---|---|---|
| `content` | | **Designed**: `Language.dc.html` |

Selecting a language applies immediately: the app rebuilds in the new locale, and choosing العربية flips `Directionality`. No confirmation is needed.

## Motion
Locale switch: cross-fade the whole app `motion.duration.base`; reduced: instant.

## Semantics / reading order
Back → title (header) → body → radio group "App language": "Use phone language, English, from your phone settings, selected" → each language, spoken in its own language (`Semantics` with the row locale) → info notice.

## RTL
In ar the radios sit on the left. Each endonym keeps its own direction (العربية RTL inside an LTR UI and the reverse).

## Banner
None.

---

**Conventions (same in every S-spec).** Canvas px = dp/sp. Spacing 2/4/8/12/16/20/24/32/40/48/56/64 = `space.1`…`space.12`; odd canvas values (6, 10, 14, 18, 28) snap to the nearest token. Radius: 4 `radius.xs`, 8 `radius.sm`, 10 `radius.card`, 12 `radius.md`, 16 `radius.lg`, 24 `radius.xl`, 28 `radius.sheet`, 999 `radius.full`. Type: serif 40 `type.display`; serif 28 `type.headline`; serif 20–24 `type.cardName`; serif 16–18 paragraphs `type.bodyReading`; sans 20/600 `type.title`; sans 17–18/600 `type.titleSmall`; sans 16 `type.body`; sans 14–15/500 `type.label`; sans 12–13 `type.caption`; numerals `type.numeral`. Nothing renders below 12 sp (canvas 9–11 px badges become `type.caption`). Side gutter `layout.gutter` (16; onboarding pages use `space.7` = 24). Tablet: the content column is `layout.maxContentWidth` (600) centred, long text is capped at `layout.readingMaxWidth`. Controls drawn at 40–44 px keep their look but get a ≥ `size.touchTarget.min` (48) hit area. Colours are tokens only (`color.*`, names in 01 §14.1). Every ★ state is a golden in light + dark at phone and tablet width (01 §8.3, RC24). *Derived* means that no artboard exists: Phase 16/17 builds the state from the designed states, the tokens and the shared state widgets (01 §8.2), and REVIEW.md checks it.
