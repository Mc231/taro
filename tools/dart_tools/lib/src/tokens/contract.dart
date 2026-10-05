/// The design-token contract of 01_PRODUCT.md §14 (names, owned by 01, RC15)
/// and the contrast pairs checked in docs/design/REVIEW.md (K6–K11).
library;

/// The text scripts every `font.family.{role}` covers (01 §14.2).
const List<String> kFontScripts = [
  'latin',
  'cyrillic',
  'arabic',
  'cjk',
  'hangul',
];

/// The `type.*` roles (01 §14.2).
const List<String> kTypeRoles = [
  'display',
  'headline',
  'cardName',
  'bodyReading',
  'title',
  'titleSmall',
  'body',
  'label',
  'caption',
  'numeral',
];

/// Properties every `type.*` role defines (01 §14.2; REVIEW K5).
const List<String> kTypeProperties = [
  'fontFamily',
  'fontSize',
  'fontWeight',
  'lineHeight',
  'letterSpacing',
];

const List<String> _colors = [
  'bg.canvas',
  'bg.surface',
  'bg.surfaceRaised',
  'bg.sunken',
  'bg.scrim',
  'text.primary',
  'text.secondary',
  'text.tertiary',
  'text.disabled',
  'text.inverse',
  'text.onAccent',
  'accent.primary',
  'accent.primaryPressed',
  'accent.secondary',
  'accent.subtle',
  'border.subtle',
  'border.strong',
  'border.focus',
  'status.success',
  'status.onSuccess',
  'status.warning',
  'status.onWarning',
  'status.error',
  'status.onError',
  'status.info',
  'status.onInfo',
  'card.back',
  'card.frame',
  'card.glow',
  'card.reversedBadge',
  'suit.major',
  'suit.wands',
  'suit.cups',
  'suit.swords',
  'suit.pentacles',
  'chart.suit.major',
  'chart.suit.wands',
  'chart.suit.cups',
  'chart.suit.swords',
  'chart.suit.pentacles',
  'ad.container',
  'skeleton.base',
  'skeleton.highlight',
];

/// Every token name of the 01 §14 contract (167 names).
final List<String> kContractTokenNames = List.unmodifiable([
  for (final c in _colors) 'color.$c',
  for (final role in kTypeRoles) 'type.$role',
  for (final role in kTypeRoles)
    for (final script in kFontScripts) 'font.family.$role.$script',
  for (var i = 0; i <= 12; i++) 'space.$i',
  'space.adGap',
  'layout.gutter',
  'layout.maxContentWidth',
  'layout.maxContentWidthWide',
  'layout.readingMaxWidth',
  'size.touchTarget.min',
  for (final s in ['sm', 'md', 'lg']) 'size.icon.$s',
  'size.card.aspectRatio',
  for (final s in ['thumb', 'sm', 'md', 'lg']) 'size.card.$s',
  for (final r in [
    'none',
    'xs',
    'sm',
    'md',
    'lg',
    'xl',
    'full',
    'card',
    'sheet',
  ])
    'radius.$r',
  for (var i = 0; i <= 4; i++) ...[
    'elevation.$i.shadow',
    'elevation.$i.overlay',
  ],
  for (final o in ['disabled', 'scrim', 'pressed']) 'opacity.$o',
  for (final d in ['instant', 'fast', 'base', 'slow']) 'motion.duration.$d',
  for (final r in ['shuffle', 'dealStagger', 'flip', 'readingReveal'])
    'motion.ritual.$r',
  for (final e in ['standard', 'emphasized', 'decelerate', 'accelerate'])
    'motion.easing.$e',
  for (final h in ['pick', 'flip', 'ready']) 'haptic.$h',
]);

/// Allowed `haptic.*` values (01 §14.4; `TaroHaptics`).
const Set<String> kHapticValues = {
  'selection',
  'light',
  'medium',
  'heavy',
  'vibrate',
};

/// A foreground/background pair and its minimum WCAG contrast ratio.
final class ContrastPair {
  /// Creates a pair.
  const ContrastPair(this.foreground, this.background, this.minimum, this.rule);

  /// Foreground colour token.
  final String foreground;

  /// Background colour token.
  final String background;

  /// Minimum ratio (4.5 text, 3 large text / UI).
  final double minimum;

  /// The REVIEW.md row it comes from.
  final String rule;
}

const List<String> _fourBackgrounds = [
  'color.bg.canvas',
  'color.bg.surface',
  'color.bg.surfaceRaised',
  'color.bg.sunken',
];

/// The contrast pairs of 01 §14.1 as computed in docs/design/REVIEW.md
/// (K6–K10: 44 pairs over both modes = 22 per mode) plus K11 (the
/// `color.suit.major` text pairs). Checked in every mode.
final List<ContrastPair> kContrastPairs = List.unmodifiable([
  for (final fg in ['color.text.primary', 'color.text.secondary'])
    for (final bg in _fourBackgrounds) ContrastPair(fg, bg, 4.5, 'K6'),
  for (final bg in ['color.bg.canvas', 'color.bg.surface'])
    ContrastPair('color.text.tertiary', bg, 4.5, 'K7'),
  for (final bg in _fourBackgrounds)
    ContrastPair('color.border.focus', bg, 3, 'K8'),
  for (final s in ['success', 'warning', 'error', 'info'])
    ContrastPair(
      'color.status.on${s[0].toUpperCase()}${s.substring(1)}',
      'color.status.$s',
      4.5,
      'K9',
    ),
  const ContrastPair('color.text.onAccent', 'color.accent.primary', 4.5, 'K10'),
  for (final bg in _fourBackgrounds.take(3))
    ContrastPair('color.border.strong', bg, 3, 'K10'),
  for (final bg in ['color.bg.canvas', 'color.bg.surface', 'color.bg.sunken'])
    ContrastPair('color.suit.major', bg, 4.5, 'K11'),
]);
