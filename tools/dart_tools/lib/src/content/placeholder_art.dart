/// `tools/content/placeholder_art`: the typographic placeholder deck used
/// until the D15 art lands (Phase 5 Sprint 5.4; 00_DECISIONS D15).
///
/// 78 cards (card name + numeral + suit glyph) and a card back, written as
/// lossless WebP to `apps/taro/assets/deck/art/placeholder/<artKey>.webp`
/// (`artKey` = card ID, `card_back`). Text uses the project-owned
/// [kPixelGlyphs] font and every shape is drawn in code, so the set has no
/// third-party imagery (docs/ART_PROVENANCE.md). The output is a pure
/// function of the English glossary names: byte-identical on every run.
library;

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:taro_dart_tools/src/content/common.dart';
import 'package:taro_dart_tools/src/content/ids.dart';
import 'package:taro_dart_tools/src/content/pixel_font.dart';

/// The placeholder art set key (`artSet` in `deck.yaml`).
const String kPlaceholderArtSet = 'placeholder';

/// Where the placeholder art is written, relative to the repository root.
const String kPlaceholderArtDir = '$kAppDeckDir/art/$kPlaceholderArtSet';

/// The art key of the card back.
const String kCardBackKey = 'card_back';

/// Card width in pixels (3:5 portrait).
const int kArtWidth = 480;

/// Card height in pixels.
const int kArtHeight = 800;

/// The repository-relative path of the placeholder art for [artKey].
String placeholderArtPath(String artKey) => '$kPlaceholderArtDir/$artKey.webp';

/// Every art key of the set: the 78 card IDs, then [kCardBackKey].
List<String> placeholderArtKeys() => [...kCardIds, kCardBackKey];

// Palette of the placeholder set only (not UI code, rule 15 does not apply).
final img.Color _background = img.ColorRgb8(27, 21, 48);
final img.Color _ink = img.ColorRgb8(243, 234, 214);
final Map<String, img.Color> _accents = {
  'major': img.ColorRgb8(201, 168, 92),
  'wands': img.ColorRgb8(224, 122, 72),
  'cups': img.ColorRgb8(96, 156, 214),
  'swords': img.ColorRgb8(176, 184, 200),
  'pentacles': img.ColorRgb8(122, 178, 110),
};

const List<(int, String)> _roman = [
  (10, 'X'),
  (9, 'IX'),
  (5, 'V'),
  (4, 'IV'),
  (1, 'I'),
];

/// [n] (0..21) as a Roman numeral; `0` for the Fool.
String romanNumeral(int n) {
  if (n == 0) return '0';
  final out = StringBuffer();
  var rest = n;
  for (final (value, symbol) in _roman) {
    while (rest >= value) {
      out.write(symbol);
      rest -= value;
    }
  }
  return out.toString();
}

/// The numeral printed at the top of [cardId]: a Roman numeral for majors
/// and pips 2–10, `ACE` and the court titles otherwise.
String numeralOf(String cardId) {
  final n = numberOf(cardId);
  if (arcanaOf(cardId) == 'major') return romanNumeral(n);
  return switch (n) {
    1 => 'ACE',
    11 => 'PAGE',
    12 => 'KNIGHT',
    13 => 'QUEEN',
    14 => 'KING',
    _ => romanNumeral(n),
  };
}

/// Splits [text] into upper-case lines of at most [maxChars] characters
/// (a longer single word keeps its own line).
List<String> wrapWords(String text, int maxChars) {
  final lines = <String>[];
  var line = '';
  for (final word in text.toUpperCase().split(RegExp(r'\s+'))) {
    if (word.isEmpty) continue;
    if (line.isEmpty) {
      line = word;
    } else if (line.length + 1 + word.length <= maxChars) {
      line = '$line $word';
    } else {
      lines.add(line);
      line = word;
    }
  }
  if (line.isNotEmpty) lines.add(line);
  return lines;
}

/// Draws [text] with its top edge at [top], horizontally centred, at
/// [scale] image pixels per font pixel.
void drawText(
  img.Image image,
  String text, {
  required int top,
  required int scale,
  required img.Color color,
}) {
  var left = (image.width - textWidth(text) * scale) ~/ 2;
  for (final char in text.split('')) {
    final rows = glyphOf(char);
    for (var y = 0; y < kGlyphHeight; y++) {
      for (var x = 0; x < kGlyphWidth; x++) {
        if (rows[y][x] != '#') continue;
        img.fillRect(
          image,
          x1: left + x * scale,
          y1: top + y * scale,
          x2: left + (x + 1) * scale - 1,
          y2: top + (y + 1) * scale - 1,
          color: color,
        );
      }
    }
    left += kGlyphAdvance * scale;
  }
}

List<img.Point> _star(int cx, int cy, int points, int outer, int inner) => [
  for (var i = 0; i < points * 2; i++)
    () {
      final r = i.isEven ? outer : inner;
      final a = -math.pi / 2 + i * math.pi / points;
      // Rounded to whole pixels so the output does not depend on the last
      // bit of the platform's sin/cos.
      return img.Point(
        (cx + r * math.cos(a)).round(),
        (cy + r * math.sin(a)).round(),
      );
    }(),
];

/// A rectangular band [thickness] pixels wide, [inset] pixels in from every
/// edge, symmetric under `(x, y) → (width − x, height − y)`.
void _band(img.Image image, img.Color color, int inset, int thickness) {
  final w = image.width;
  final h = image.height;
  final t = thickness - 1;
  for (final (x1, y1, x2, y2) in [
    (inset, inset, w - inset, inset + t),
    (inset, h - inset - t, w - inset, h - inset),
    (inset, inset, inset + t, h - inset),
    (w - inset - t, inset, w - inset, h - inset),
  ]) {
    img.fillRect(image, x1: x1, y1: y1, x2: x2, y2: y2, color: color);
  }
}

void _frame(img.Image image, img.Color accent) {
  _band(image, accent, 16, 6);
  _band(image, accent, 32, 2);
}

/// Draws the glyph of [group] (`major` or a suit) centred on ([cx], [cy]).
void drawSuitGlyph(img.Image image, String group, int cx, int cy) {
  final accent = _accents[group]!;
  switch (group) {
    case 'wands':
      img.fillRect(
        image,
        x1: cx - 12,
        y1: cy - 100,
        x2: cx + 12,
        y2: cy + 110,
        color: accent,
        radius: 10,
      );
      img.fillCircle(image, x: cx - 30, y: cy - 60, radius: 14, color: accent);
      img.fillCircle(image, x: cx + 30, y: cy - 20, radius: 14, color: accent);
      img.fillCircle(image, x: cx - 30, y: cy + 20, radius: 14, color: accent);
    case 'cups':
      img.fillCircle(image, x: cx, y: cy - 40, radius: 80, color: accent);
      img.fillRect(
        image,
        x1: cx - 90,
        y1: cy - 130,
        x2: cx + 90,
        y2: cy - 41,
        color: _background,
      );
      img.fillRect(
        image,
        x1: cx - 12,
        y1: cy + 30,
        x2: cx + 12,
        y2: cy + 90,
        color: accent,
      );
      img.fillRect(
        image,
        x1: cx - 60,
        y1: cy + 90,
        x2: cx + 60,
        y2: cy + 110,
        color: accent,
        radius: 8,
      );
    case 'swords':
      img.fillRect(
        image,
        x1: cx - 10,
        y1: cy - 80,
        x2: cx + 10,
        y2: cy + 50,
        color: accent,
      );
      img.fillPolygon(
        image,
        vertices: [
          img.Point(cx - 10, cy - 80),
          img.Point(cx + 10, cy - 80),
          img.Point(cx, cy - 115),
        ],
        color: accent,
      );
      img.fillRect(
        image,
        x1: cx - 60,
        y1: cy + 50,
        x2: cx + 60,
        y2: cy + 66,
        color: accent,
        radius: 6,
      );
      img.fillRect(
        image,
        x1: cx - 8,
        y1: cy + 66,
        x2: cx + 8,
        y2: cy + 100,
        color: accent,
      );
      img.fillCircle(image, x: cx, y: cy + 108, radius: 14, color: accent);
    case 'pentacles':
      img.fillCircle(image, x: cx, y: cy, radius: 105, color: accent);
      img.fillCircle(image, x: cx, y: cy, radius: 93, color: _background);
      img.fillPolygon(
        image,
        vertices: _star(cx, cy, 5, 88, 36),
        color: accent,
      );
    default:
      img.fillPolygon(
        image,
        vertices: _star(cx, cy, 8, 110, 46),
        color: accent,
      );
      img.fillCircle(image, x: cx, y: cy, radius: 30, color: _background);
      img.fillCircle(image, x: cx, y: cy, radius: 18, color: accent);
  }
}

Uint8List _encode(img.Image image) => img.WebPEncoder().encode(image);

img.Image _canvas() {
  final image = img.Image(width: kArtWidth, height: kArtHeight);
  img.fill(image, color: _background);
  return image;
}

/// The placeholder face of [cardId] titled [name], as lossless WebP.
Uint8List renderCard(String cardId, String name) {
  final group = suitOf(cardId) ?? 'major';
  final accent = _accents[group]!;
  final image = _canvas();
  _frame(image, accent);

  final numeral = numeralOf(cardId);
  final numeralScale = math.min(8, 380 ~/ textWidth(numeral));
  drawText(image, numeral, top: 72, scale: numeralScale, color: accent);

  drawSuitGlyph(image, group, kArtWidth ~/ 2, 370);

  const lineScale = 5;
  const lineHeight = kGlyphHeight * lineScale + 14;
  const usable = kArtWidth - 100;
  final lines = wrapWords(name, usable ~/ (kGlyphAdvance * lineScale));
  var top = kArtHeight - 90 - lines.length * lineHeight;
  for (final line in lines) {
    final scale = math.max(1, math.min(lineScale, usable ~/ textWidth(line)));
    drawText(image, line, top: top, scale: scale, color: _ink);
    top += lineHeight;
  }
  return _encode(image);
}

/// The placeholder card back, point-symmetric about the pixel
/// (`kArtWidth / 2`, `kArtHeight / 2`) so it reads the same when a card is
/// drawn reversed, as lossless WebP.
Uint8List renderCardBack() {
  final accent = _accents['major']!;
  final image = _canvas();
  _frame(image, accent);
  const cx = kArtWidth ~/ 2;
  const cy = kArtHeight ~/ 2;
  img.drawCircle(image, x: cx, y: cy, radius: 150, color: accent);
  img.drawCircle(image, x: cx, y: cy, radius: 146, color: accent);
  img.fillPolygon(image, vertices: _star(cx, cy, 8, 120, 50), color: accent);
  img.fillCircle(image, x: cx, y: cy, radius: 32, color: _background);
  img.fillCircle(image, x: cx, y: cy, radius: 20, color: accent);
  for (final (x, y) in const [(80, 80), (400, 80), (80, 720), (400, 720)]) {
    img.fillPolygon(image, vertices: _star(x, y, 4, 26, 9), color: accent);
  }
  for (final y in const [230, 570]) {
    img.fillCircle(image, x: cx, y: y, radius: 8, color: accent);
  }
  return _encode(image);
}

/// Every file of the set: repository-relative path → WebP bytes, for the
/// English [names] by card ID (the glossary `cards.<id>.en`).
Map<String, Uint8List> generatePlaceholderArt(Map<String, String> names) => {
  for (final id in kCardIds) placeholderArtPath(id): renderCard(id, names[id]!),
  placeholderArtPath(kCardBackKey): renderCardBack(),
};

/// The English card names from a parsed `glossary.yaml`; throws a
/// [ContentFormatException] when one is missing.
Map<String, String> englishCardNames(Object? glossary) {
  final cards = glossary is Map ? glossary['cards'] : null;
  final names = <String, String>{};
  for (final id in kCardIds) {
    final entry = cards is Map ? cards[id] : null;
    final name = entry is Map ? entry[kSourceLocale] : null;
    if (name is! String || name.trim().isEmpty) {
      throw ContentFormatException(
        '$kSourceDir/glossary.yaml',
        'no en name for $id',
      );
    }
    names[id] = name;
  }
  return names;
}
