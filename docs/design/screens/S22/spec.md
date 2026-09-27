# S22 · Reminder settings

| | |
|---|---|
| Route | `/settings/reminder` |
| Banner | none |
| Artboards | [`../Reminder.dc.html`](../Reminder.dc.html) |
| Frames | [`Reminder.png`](../frames/Reminder.png) (PNG @2x, from the artboards above) |

## Layout (top → bottom)
Padding `space.10` / `layout.gutter` / `space.8`; gap `space.6`.
1. Back.
2. Title "Daily reminder" serif 28; body "A gentle nudge for your daily card."
3. Group (`color.bg.surface`, `radius.lg`):
   - switch row "Daily card reminder" (min 60);
   - time block (padding `space.5`): caption "Remind me at" + a big time button (min 64, `color.bg.sunken`, `radius.md`) with the time in serif 30 (`type.headline`; 12/24 h per the device setting) and "Change" at the end → the platform time picker;
   - no days block: the reminder is daily only. 01 §7.7/§7.10 define a toggle + time, and the backup schema v1 (frozen, RC70) stores `reminder: {enabled, time}` only. **Resolved**: the weekday picker ("On these days · Weekdays", 7 round toggles) was removed from `Reminder.dc.html`. Adding days later is a spec change (01 + backup schema v2).
4. Preview: caption "What you'll see" + a notification mock (`color.bg.surfaceRaised`, radius 18 → `radius.lg`; app icon 36; "Taro" + the time `type.caption`; the title `type.label`/600 "A quiet moment for your daily card"; body `type.caption`/14). Caption: "The wording changes a little from day to day. It never shows your card." (6 rotating ARB variants; no urgency, no badges, 01 §7.7).
5. Flexible spacer.
6. Info notice (`color.accent.subtle`, `radius.md`): "Your phone asks for permission to send notifications when you turn this on."

The default time is 09:00 local (01 §7.7); 8:00 PM on the canvas is a sample value.

## Components
`SettingsTile` (switch), time button (**new**: `TimeField`; add to `components.md`), notification preview (static), `TaroInlineNotice`.

## States (01 §8.3)
| State | ★ | Source |
|---|---|---|
| `content` (on) | | **Designed**: `Reminder.dc.html` |
| off | | Derived: the time block and preview at `opacity.disabled`, not interactive |
| `permissionDenied` | | Derived: the switch off + `TaroInlineNotice(warning)` "Notifications are off in system settings" + "Open settings" |

## Motion
The time block expands/collapses with the switch over `motion.duration.base`; reduced: instant.

## Semantics / reading order
Back → title → body → "Daily card reminder, switch, on" → "Remind me at 8:00 PM, Change, button" → "Example notification: A quiet moment for your daily card…" (one node) → caption → permission note.

## RTL
Mirrored; the time keeps locale digits and AM/PM order per `intl`.

## Banner
None.

---

**Conventions (same in every S-spec).** Canvas px = dp/sp. Spacing 2/4/8/12/16/20/24/32/40/48/56/64 = `space.1`…`space.12`; odd canvas values (6, 10, 14, 18, 28) snap to the nearest token. Radius: 4 `radius.xs`, 8 `radius.sm`, 10 `radius.card`, 12 `radius.md`, 16 `radius.lg`, 24 `radius.xl`, 28 `radius.sheet`, 999 `radius.full`. Type: serif 40 `type.display`; serif 28 `type.headline`; serif 20–24 `type.cardName`; serif 16–18 paragraphs `type.bodyReading`; sans 20/600 `type.title`; sans 17–18/600 `type.titleSmall`; sans 16 `type.body`; sans 14–15/500 `type.label`; sans 12–13 `type.caption`; numerals `type.numeral`. Nothing renders below 12 sp (canvas 9–11 px badges become `type.caption`). Side gutter `layout.gutter` (16; onboarding pages use `space.7` = 24). Tablet: the content column is `layout.maxContentWidth` (600) centred, long text is capped at `layout.readingMaxWidth`. Controls drawn at 40–44 px keep their look but get a ≥ `size.touchTarget.min` (48) hit area. Colours are tokens only (`color.*`, names in 01 §14.1). Every ★ state is a golden in light + dark at phone and tablet width (01 §8.3, RC24). *Derived* means that no artboard exists: Phase 16/17 builds the state from the designed states, the tokens and the shared state widgets (01 §8.2), and REVIEW.md checks it.
