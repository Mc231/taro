/// Parsing and matching of `tools/coverage_exclusions.txt` (06 QA3, §5.3).
library;

/// The parsed list of repo-relative exclusion globs.
///
/// `**` spans any number of path segments (including none), `*` and `?`
/// stay inside one segment. The Python checker (`tools/check_coverage.py`)
/// uses the same rules, so both sides agree on what is excluded.
class CoverageExclusions {
  /// Creates the list from already-parsed [patterns].
  CoverageExclusions(List<String> patterns)
    : patterns = List.unmodifiable(patterns),
      _regexps = [for (final p in patterns) globToRegExp(p)];

  /// Parses the file format: one glob per line, `#` comments, blank lines.
  factory CoverageExclusions.parse(String content) => CoverageExclusions([
    for (final raw in content.split('\n'))
      if (raw.trim().isNotEmpty && !raw.trim().startsWith('#')) raw.trim(),
  ]);

  /// The globs in file order.
  final List<String> patterns;

  final List<RegExp> _regexps;

  /// Whether the repo-relative [path] (forward slashes) is excluded.
  bool matches(String path) => _regexps.any((r) => r.hasMatch(path));

  /// Patterns for `lcov --remove` on a tracefile whose `SF:` paths are
  /// relative to the unit at repo-relative [unitPath] (for example
  /// `apps/taro`, whose lcov lists `lib/main.dart`).
  ///
  /// lcov turns `*` into `.*` and anchors the whole path, so the output is
  /// a superset of the glob; the checker re-applies the exact globs.
  List<String> lcovPatterns(String unitPath) {
    final prefix = unitPath.endsWith('/') ? unitPath : '$unitPath/';
    final out = <String>[];
    void add(String p) {
      if (!out.contains(p)) out.add(p);
    }

    for (final pattern in patterns) {
      String rest;
      if (pattern.startsWith('**/')) {
        rest = pattern.substring(3);
        add(_lcov(rest));
        add('*/${_lcov(rest)}');
        continue;
      } else if (pattern.startsWith(prefix)) {
        rest = pattern.substring(prefix.length);
      } else {
        continue; // Belongs to another unit.
      }
      add(_lcov(rest));
    }
    return out;
  }

  static String _lcov(String glob) => glob.replaceAll('**', '*');
}

/// Converts a repo-relative glob to an anchored [RegExp].
RegExp globToRegExp(String glob) {
  final buf = StringBuffer('^');
  var i = 0;
  while (i < glob.length) {
    final c = glob[i];
    if (c == '*') {
      final isDouble = i + 1 < glob.length && glob[i + 1] == '*';
      if (isDouble) {
        final slashAfter = i + 2 < glob.length && glob[i + 2] == '/';
        if (slashAfter) {
          // `**/` matches zero or more whole segments.
          buf.write('(?:.*/)?');
          i += 3;
        } else {
          buf.write('.*');
          i += 2;
        }
        continue;
      }
      buf.write('[^/]*');
    } else if (c == '?') {
      buf.write('[^/]');
    } else {
      buf.write(RegExp.escape(c));
    }
    i++;
  }
  buf.write(r'$');
  return RegExp(buf.toString());
}
