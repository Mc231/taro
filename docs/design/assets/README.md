# Design assets (Phase 14, A36)

Exported from the Claude Design canvas (`../screens/*.dc.html`). All CSS variables are replaced with the literal **dark-mode** hex values from `../taro.tokens.json`, since the artboards are drawn in dark mode:

| Token | Hex (dark) | Used in |
|---|---|---|
| `color.card.back` | `#23308F` (same in light) | card back field, icon background, splash mark |
| `color.card.frame` | `#D4A63A` (light `#B8820F`) | card-back ornament, icon frame and star, spread outlines and numbers, empty-state strokes |
| `color.bg.canvas` | `#0F1120` (light `#EEF0F4`) | icon card body, empty-state front-card and lens fill |
| `color.bg.surface` | `#171A2D` (light `#F8F9FB`) | filled spread boxes that cover a line or card (Two Paths, Celtic Cross card 2) |
| `color.border.strong` | `#6A7196` | Two Paths connector lines |

In code (`taro_ui`) the spread diagrams and empty-state illustrations are drawn or tinted with the tokens, so light mode follows the theme; these files are the geometry masters. The card back and the icon are fixed art and use the same values in both modes (only `card.frame` differs in light; the card back keeps the dark-mode ochre, which is what the art is signed off with).

| File | Size | Source artboard | Usage |
|---|---|---|---|
| `card-back.svg` | 580 × 1000 | `CardBack` | Master art. `TaroCardBack` (all card backs: S01 mark, S05, S08 fan/shuffle, S13 not drawn, journal thumbnails). Rounded 40, clip included. |
| `card-back@3x.png` | 660 × 1138 RGBA | `CardBack` | Raster of the master at `size.card.lg` (220) @3x. Store/marketing use and a fallback where SVG is not wanted. |
| `card-back-580x1000.png` | 580 × 1000 RGBA | `CardBack` | 1:1 raster of the master (artboard size). |
| `spreads/single.svg` | 80 × 126 | `SpreadDiagrams` | Single card layout diagram: S06 spread picker tile, S07 header, S18 spread guide. |
| `spreads/three_ppf.svg` | 292 × 113 | `SpreadDiagrams` | Past · Present · Future layout diagram: S06 spread picker tile, S07 header, S18 spread guide. |
| `spreads/three_sao.svg` | 292 × 113 | `SpreadDiagrams` | Situation · Action · Outcome layout diagram: S06 spread picker tile, S07 header, S18 spread guide. |
| `spreads/relationship.svg` | 280 × 222 | `SpreadDiagrams` | Relationship layout diagram: S06 spread picker tile, S07 header, S18 spread guide. |
| `spreads/two_paths.svg` | 304 × 222 | `SpreadDiagrams` | Two Paths layout diagram: S06 spread picker tile, S07 header, S18 spread guide. |
| `spreads/celtic_cross.svg` | 194 × 272 | `SpreadDiagrams` | Celtic Cross layout diagram: S06 spread picker tile, S07 header, S18 spread guide. |
| `empty/journal.svg` | 200 × 150 | `JournalEmpty` | S14 Journal `empty` state (`TaroEmptyView`). |
| `empty/search.svg` | 200 × 150 | new; drawn to match `empty/journal.svg` | `searchEmpty` states: S14 Journal, S16 Learn, S28 Help "search no results" (`TaroEmptyView`). |
| `icon/app-icon.svg` | 1024 × 1024 | `AppIcon` | Vector master of the app icon. |
| `icon/app-icon-1024.png` | 1024 × 1024 RGB | `AppIcon` | iOS App Store / Xcode single-size icon. Opaque RGB, no alpha, square corners (iOS masks it). |
| `icon/android-foreground.svg` | 432 × 432 | `AppIcon` (mark only) | Android adaptive icon foreground (`mipmap-anydpi-v26/ic_launcher.xml` → foreground). Transparent. |
| `icon/android-foreground.png` | 432 × 432 RGBA | `AppIcon` (mark only) | Same, raster at 432 px (xxxhdpi 108 dp). |
| `icon/android-background.svg` | 432 × 432 | `AppIcon` | Adaptive icon background: flat `color.card.back`. |
| `icon/android-background.png` | 432 × 432 RGB | `AppIcon` | Same, raster at 432 px. |
| `icon/android-monochrome.svg` | 432 × 432 | derived from `AppIcon` | Android 13+ themed icon (`<monochrome>`): card frame + star, alpha only. |
| `icon/android-monochrome.png` | 432 × 432 RGBA | derived from `AppIcon` | Same, raster at 432 px. |
| `splash/splash-mark.svg` | 96 × 164 | `Launch` | S01 native splash mark (iOS LaunchScreen, Android 12 splash icon) on `color.bg.canvas`. |
| `store/frame-template.png` | 1320 × 2868 RGB | `ScreenshotFrame` | App Store screenshot frame template, 6.9" (1320 × 2868) (Phase 20; captions per CS13). |

## Notes

- **Spread diagrams**: cards and numbers only. The position names in the board are localised UI text, so they are not baked in; each position is a `<g id="pos-N" data-position="<spreads.json id>">` with a `<title>`, and the order is listed in `<desc>`. Numbers use IBM Plex Sans 600 (`type.caption` or larger in code; the board draws Celtic Cross card 1 at 11 px, see REVIEW "Other carry-overs"). The viewBox is the cards bounding box + 8. In RTL the x positions mirror; the numbers do not.
- **Android adaptive icon**: 108 dp canvas as a 432 × 432 viewBox (4 units per dp). The mark is scaled to 220 units tall so its bounding box diagonal (254) fits the 66 dp safe circle (264); everything is inside the visible central 72 dp (288). Foreground and monochrome share the geometry.
- **Monochrome**: white on transparent; the launcher uses alpha only. The dark card body is dropped because a filled body would read as a blob once tinted.
- **iOS icon**: `app-icon-1024.png` has no alpha channel (App Store requirement). Smaller sizes are generated by Xcode / `flutter_launcher_icons` from it.
- **Search empty state**: new in this pass (REVIEW A36 noted it was not designed). Same stroke language as the Journal illustration: fanned card outlines, dashed inner frame, baseline, plus a magnifier with an empty lens.
- Rasters were produced with headless Chrome from the SVGs in this folder.
