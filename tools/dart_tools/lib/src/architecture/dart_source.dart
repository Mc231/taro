/// Lightweight Dart source reading for the import-graph check.
///
/// The check needs only the `import`/`export` directives and a few call
/// sites, so it masks comments and string contents instead of parsing Dart.
library;

/// One `import` or `export` URI and the line of its directive.
class Directive {
  /// Creates a directive.
  const Directive(this.uri, this.line);

  /// The URI as written (conditional-import alternatives are separate
  /// directives with the same line).
  final String uri;

  /// 1-based line of the `import`/`export` keyword.
  final int line;

  @override
  String toString() => 'Directive($uri, $line)';
}

/// A non-directional layout API call (02 §11).
class LayoutUse {
  /// Creates a finding.
  const LayoutUse(this.api, this.line);

  /// The offending API, e.g. `Alignment.centerLeft`.
  final String api;

  /// 1-based line.
  final int line;
}

bool _isQuote(int unit) => unit == 0x27 || unit == 0x22; // ' "

bool _isIdentifierChar(int unit) =>
    (unit >= 0x30 && unit <= 0x39) ||
    (unit >= 0x41 && unit <= 0x5A) ||
    (unit >= 0x61 && unit <= 0x7A) ||
    unit == 0x5F ||
    unit == 0x24;

/// Returns [source] with comments blanked and string contents replaced by
/// spaces. Quotes, offsets and line breaks are kept, so offsets into the
/// result are offsets into [source].
String maskDart(String source) {
  final out = source.codeUnits.toList();
  final n = source.length;

  void blank(int start, int end) {
    for (var k = start; k < end && k < n; k++) {
      if (out[k] != 0x0A) out[k] = 0x20;
    }
  }

  var i = 0;
  while (i < n) {
    if (source.startsWith('//', i)) {
      var end = source.indexOf('\n', i);
      if (end < 0) end = n;
      blank(i, end);
      i = end;
      continue;
    }
    if (source.startsWith('/*', i)) {
      var depth = 1;
      var j = i + 2;
      while (j < n && depth > 0) {
        if (source.startsWith('/*', j)) {
          depth++;
          j += 2;
        } else if (source.startsWith('*/', j)) {
          depth--;
          j += 2;
        } else {
          j++;
        }
      }
      blank(i, j);
      i = j;
      continue;
    }
    var start = i;
    var raw = false;
    final unit = source.codeUnitAt(i);
    if ((unit == 0x72 || unit == 0x52) &&
        i + 1 < n &&
        _isQuote(source.codeUnitAt(i + 1)) &&
        (i == 0 || !_isIdentifierChar(source.codeUnitAt(i - 1)))) {
      raw = true;
      start = i + 1;
    }
    final quoteUnit = source.codeUnitAt(start);
    if (!_isQuote(quoteUnit)) {
      i++;
      continue;
    }
    final quote = String.fromCharCode(quoteUnit);
    final triple = source.startsWith(quote * 3, start);
    final close = triple ? quote * 3 : quote;
    var j = start + close.length;
    while (j < n) {
      if (!raw && source.codeUnitAt(j) == 0x5C) {
        j += 2;
        continue;
      }
      if (source.startsWith(close, j)) break;
      if (!triple && source.codeUnitAt(j) == 0x0A) break;
      j++;
    }
    final contentEnd = j < n ? j : n;
    blank(start + close.length, contentEnd);
    i = source.startsWith(close, contentEnd) ? contentEnd + close.length : j;
  }
  return String.fromCharCodes(out);
}

/// 1-based line number of [offset] in [text].
int lineOf(String text, int offset) {
  var line = 1;
  for (var k = 0; k < offset && k < text.length; k++) {
    if (text.codeUnitAt(k) == 0x0A) line++;
  }
  return line;
}

final _directive = RegExp(r'^[ \t]*(import|export)\b', multiLine: true);

/// Every URI named by an `import` or `export` directive of [source].
List<Directive> parseDirectives(String source) {
  final masked = maskDart(source);
  final directives = <Directive>[];
  for (final match in _directive.allMatches(masked)) {
    var end = masked.indexOf(';', match.end);
    if (end < 0) end = masked.length;
    final line = lineOf(masked, match.start);
    var k = match.end;
    while (k < end) {
      final unit = masked.codeUnitAt(k);
      if (!_isQuote(unit)) {
        k++;
        continue;
      }
      final quote = String.fromCharCode(unit);
      final triple = masked.startsWith(quote * 3, k);
      final width = triple ? 3 : 1;
      var close = masked.indexOf(quote * width, k + width);
      if (close < 0 || close > end) close = end;
      directives.add(Directive(source.substring(k + width, close), line));
      k = close + width;
    }
  }
  return directives;
}

/// Index just past the parenthesis matching the `(` at [open] in [masked].
int _closeParen(String masked, int open) {
  var depth = 0;
  for (var k = open; k < masked.length; k++) {
    final unit = masked.codeUnitAt(k);
    if (unit == 0x28 || unit == 0x5B || unit == 0x7B) depth++;
    if (unit == 0x29 || unit == 0x5D || unit == 0x7D) {
      depth--;
      if (depth == 0) return k + 1;
    }
  }
  return masked.length;
}

/// Named arguments `left:`/`right:` at the top level of `(...)` at [open].
bool _hasHorizontalNamedArg(String masked, int open) {
  final end = _closeParen(masked, open);
  var depth = 0;
  final named = RegExp(r'\b(left|right)\s*:');
  for (var k = open; k < end; k++) {
    final unit = masked.codeUnitAt(k);
    if (unit == 0x28 || unit == 0x5B || unit == 0x7B) depth++;
    if (unit == 0x29 || unit == 0x5D || unit == 0x7D) depth--;
    if (depth == 1) {
      final match = named.matchAsPrefix(masked, k);
      if (match != null &&
          (k == 0 || !_isIdentifierChar(masked.codeUnitAt(k - 1)))) {
        return true;
      }
    }
  }
  return false;
}

final _simpleLayout = RegExp(
  r'\b(Alignment\.(?:centerLeft|centerRight)|TextAlign\.(?:left|right))\b',
);
final _callLayout = RegExp(r'\b(EdgeInsets\.only|Positioned)\s*\(');

/// Non-directional layout APIs used in [source]: `EdgeInsets.only` or
/// `Positioned` with `left:`/`right:`, `Alignment.centerLeft|Right` and
/// `TextAlign.left|right` (02 §11; use the `…Directional` / `start`/`end`
/// forms).
List<LayoutUse> findLayoutUses(String source) {
  final masked = maskDart(source);
  final uses = <LayoutUse>[
    for (final match in _simpleLayout.allMatches(masked))
      LayoutUse(match.group(1)!, lineOf(masked, match.start)),
  ];
  for (final match in _callLayout.allMatches(masked)) {
    if (_hasHorizontalNamedArg(masked, match.end - 1)) {
      uses.add(
        LayoutUse(
          '${match.group(1)!}(left/right:)',
          lineOf(masked, match.start),
        ),
      );
    }
  }
  uses.sort((a, b) => a.line.compareTo(b.line));
  return uses;
}
