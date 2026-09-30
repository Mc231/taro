/// The `Redactor` (02 §13, 03 §3.1): scrubs secrets and user content from
/// every log record, breadcrumb and crash context before it reaches a sink.
///
/// It is a safety net, not a licence (the `Logger` port): callers still
/// never log question, note or reading text, tokens or the install ID.
library;

/// What replaces a secret or a user-content value.
const String kRedacted = '<redacted>';

/// What replaces a JWS / JWT / JWE (App Store transactions, Play Integrity
/// tokens, install tokens).
const String kRedactedJws = '<jws>';

/// How many characters of an install ID survive (02 §13).
const int kInstallIdVisibleChars = 8;

/// Keys (normalized: lowercase, no `_`, `-`, `.` or spaces) whose values are
/// user content and are always removed (02 §13; Phase 12.4).
const Set<String> _contentKeys = {
  'question',
  'questiontext',
  'note',
  'notetext',
  'body',
  'reading',
  'readingtext',
};

/// Keys whose values are install IDs: kept to their first 8 characters.
const Set<String> _installIdKeys = {'installid', 'xtaroinstallid'};

/// Exact secret keys that do not contain one of [_secretKeyParts].
const Set<String> _secretKeys = {
  'authorization',
  'devicekey',
  'purchasebinding',
  'playaccountid',
  'clientdatahash',
  'password',
};

/// Key fragments that mark a secret: every `…token`, `…secret`, JWS,
/// signed transaction, attestation object and assertion (03 §3.1, §3.4,
/// §6.1).
const List<String> _secretKeyParts = [
  'token',
  'secret',
  'jws',
  'signed',
  'attestation',
  'assertion',
];

/// `key: value`, `"key": value`, `key=value` (JSON, Dart `toString`,
/// headers and query strings). Group 2 is the key.
final RegExp _keyValue = RegExp(
  r'''(["']?)([A-Za-z][A-Za-z0-9_.\-]*)\1[ \t]*[:=][ \t]*''',
);

final RegExp _bearer = RegExp(
  r'\b(Bearer|Basic)[ \t]+[A-Za-z0-9._~+/=\-]+',
  caseSensitive: false,
);

/// A compact JWS / JWT / JWE: base64url JSON header (`eyJ`) plus 2–4 more
/// dot-separated segments.
final RegExp _jws = RegExp(
  r'eyJ[A-Za-z0-9_\-]*(?:\.[A-Za-z0-9_\-]*){2,4}',
);

/// A long opaque blob (Play purchase tokens, device keys, attestation
/// objects); dots included, because Play tokens are dotted.
final RegExp _blob = RegExp(
  r'(?<![A-Za-z0-9_+/=.\-])[A-Za-z0-9_+/=.\-]{40,}(?![A-Za-z0-9_+/=.\-])',
);

final RegExp _upperCase = RegExp('[A-Z]');
final RegExp _lowerCase = RegExp('[a-z]');
final RegExp _digit = RegExp('[0-9]');

/// How a keyed value is rewritten.
enum _Treatment {
  /// A secret: the value is replaced.
  remove,

  /// User content: the value is replaced; unquoted, up to the line end.
  content,

  /// An install ID: the first 8 characters are kept.
  truncate,
}

/// Scrubs log text and structured context.
///
/// Besides the static rules, the exact values of the install secret, device
/// key and similar ([registerSecret]) and of the install ID
/// ([registerInstallId]) are replaced wherever they appear.
final class Redactor {
  /// Creates a redactor with no registered values.
  Redactor();

  final Set<String> _secrets = {};
  final Set<String> _installIds = {};

  /// Replaces every later occurrence of [value] with [kRedacted]. Values
  /// shorter than 4 characters are ignored (they would erase ordinary text).
  void registerSecret(String value) {
    if (value.length >= 4) _secrets.add(value);
  }

  /// Truncates every later occurrence of [installId] to its first 8
  /// characters.
  void registerInstallId(String installId) {
    if (installId.length > kInstallIdVisibleChars) _installIds.add(installId);
  }

  /// [installId] as it may appear in a log: its first 8 characters and `…`.
  static String truncateInstallId(String installId) =>
      installId.length <= kInstallIdVisibleChars
      ? installId
      : '${installId.substring(0, kInstallIdVisibleChars)}…';

  /// [text] with every secret, token and user-content value scrubbed.
  String redact(String text) {
    var out = text;
    for (final secret in _secrets) {
      out = out.replaceAll(secret, kRedacted);
    }
    for (final id in _installIds) {
      out = out.replaceAll(id, truncateInstallId(id));
    }
    out = _redactKeyed(out);
    out = out.replaceAllMapped(_bearer, (m) => '${m[1]} $kRedacted');
    out = out.replaceAll(_jws, kRedactedJws);
    return out.replaceAllMapped(
      _blob,
      (m) => _looksOpaque(m[0]!) ? kRedacted : m[0]!,
    );
  }

  /// [context] with sensitive keys scrubbed and every value [redact]ed.
  Map<String, String> redactMap(Map<String, Object?> context) => {
    for (final MapEntry(:key, :value) in context.entries)
      key: switch (_treatmentFor(key)) {
        _Treatment.remove || _Treatment.content => kRedacted,
        _Treatment.truncate => truncateInstallId(redact('$value')),
        null => redact('$value'),
      },
  };

  static bool _looksOpaque(String candidate) =>
      candidate.contains(_upperCase) &&
      candidate.contains(_lowerCase) &&
      candidate.contains(_digit);

  static String _normalize(String key) =>
      key.toLowerCase().replaceAll(RegExp(r'[_\-.\s]'), '');

  static _Treatment? _treatmentFor(String key) {
    final normalized = _normalize(key);
    if (_installIdKeys.contains(normalized)) return _Treatment.truncate;
    if (_contentKeys.contains(normalized)) return _Treatment.content;
    if (_secretKeys.contains(normalized) ||
        _secretKeyParts.any(normalized.contains)) {
      return _Treatment.remove;
    }
    return null;
  }

  String _redactKeyed(String text) {
    final out = StringBuffer();
    var cursor = 0;
    for (final match in _keyValue.allMatches(text)) {
      if (match.start < cursor || match.end >= text.length) continue;
      final treatment = _treatmentFor(match[2]!);
      if (treatment == null) continue;
      final end = _valueSpan(
        text,
        match.end,
        toLineEnd: treatment == _Treatment.content,
      );
      out
        ..write(text.substring(cursor, match.end))
        ..write(_rewrite(text.substring(match.end, end), treatment));
      cursor = end;
    }
    out.write(text.substring(cursor));
    return out.toString();
  }

  static String _rewrite(String value, _Treatment treatment) {
    final quote = value.isNotEmpty && (value[0] == '"' || value[0] == "'")
        ? value[0]
        : '';
    final inner = quote.isEmpty || value.length < 2
        ? value
        : value.substring(1, value.length - 1);
    final rewritten = switch (treatment) {
      _Treatment.remove || _Treatment.content => kRedacted,
      _Treatment.truncate => truncateInstallId(inner),
    };
    return '$quote$rewritten$quote';
  }

  /// The end (exclusive) of the value starting at [start]: a quoted string,
  /// a balanced `{…}` / `[…]`, or everything up to a separator (up to the
  /// line end when [toLineEnd], so a comma in a question leaks nothing).
  static int _valueSpan(String text, int start, {required bool toLineEnd}) {
    final first = text[start];
    if (first == '"' || first == "'") return _quotedEnd(text, start, first);
    if (first == '{' || first == '[') return _balancedEnd(text, start);
    final stops = toLineEnd ? '\n\r' : ',;&)}]\n\r';
    var end = start;
    while (end < text.length && !stops.contains(text[end])) {
      end++;
    }
    // `Bearer abc` style values keep their inner space; trailing spaces go.
    while (end > start && text[end - 1] == ' ') {
      end--;
    }
    return end;
  }

  static int _quotedEnd(String text, int start, String quote) {
    var i = start + 1;
    while (i < text.length) {
      final char = text[i];
      if (char == r'\') {
        i += 2;
        continue;
      }
      if (char == quote) return i + 1;
      i++;
    }
    return text.length;
  }

  static int _balancedEnd(String text, int start) {
    var depth = 0;
    var i = start;
    while (i < text.length) {
      final char = text[i];
      if (char == '"' || char == "'") {
        i = _quotedEnd(text, i, char);
        continue;
      }
      if (char == '{' || char == '[') depth++;
      if (char == '}' || char == ']') {
        depth--;
        if (depth == 0) return i + 1;
      }
      i++;
    }
    return text.length;
  }
}
