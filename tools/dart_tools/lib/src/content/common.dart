/// Shared plumbing of the content tools: issues, YAML/JSON I/O, hashing and
/// repository paths.
library;

import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:yaml/yaml.dart';

/// Authored source, relative to the repository root.
const String kSourceDir = 'apps/taro/content/source';

/// Generated app assets, relative to the repository root.
const String kAppDeckDir = 'apps/taro/assets/deck';

/// Generated Worker inputs, relative to the repository root.
const String kWorkerGeneratedDir = 'worker/src/generated';

/// Banned phrases (RC39), relative to the repository root.
const String kBannedPhrasesPath = 'tools/store_copy/banned_phrases.yaml';

/// Required disclaimer sentences, relative to the repository root.
const String kRequiredSentencesPath =
    'tools/store_copy/required_sentences.yaml';

/// The content style guide fed to `translate` (Sprint 5.1).
const String kStyleGuidePath = 'docs/content/STYLE_GUIDE.md';

/// How bad an [Issue] is.
enum Severity {
  /// Fails the command.
  error,

  /// Printed only (staleness, unverified crisis entries); an error with
  /// `--strict-locales`.
  report,
}

/// One finding, anchored to a repository-relative [path].
final class Issue {
  /// Creates an issue.
  const Issue(this.severity, this.path, this.message, {this.locale});

  /// An error.
  const Issue.error(this.path, this.message, {this.locale})
    : severity = Severity.error;

  /// A report line.
  const Issue.report(this.path, this.message, {this.locale})
    : severity = Severity.report;

  /// Error or report.
  final Severity severity;

  /// Repository-relative file (or folder) the issue is about.
  final String path;

  /// What is wrong, in one line.
  final String message;

  /// The locale a report line belongs to, for the per-locale summary.
  final String? locale;

  @override
  String toString() => '${severity.name}: $path: $message';
}

/// A source file that cannot be parsed at all.
final class ContentFormatException implements Exception {
  /// Creates the exception.
  const ContentFormatException(this.path, this.message);

  /// Repository-relative path.
  final String path;

  /// Parser message.
  final String message;

  @override
  String toString() => '$path: $message';
}

/// Converts parsed YAML into plain Dart maps (string keys only) and lists.
Object? plain(Object? node, String path) {
  if (node is YamlMap || node is Map) {
    final map = node! as Map;
    final out = <String, Object?>{};
    for (final entry in map.entries) {
      final key = entry.key is YamlScalar
          ? (entry.key as YamlScalar).value
          : entry.key;
      if (key is! String) {
        throw ContentFormatException(path, 'mapping key $key is not a string');
      }
      out[key] = plain(entry.value, path);
    }
    return out;
  }
  if (node is List) return [for (final item in node) plain(item, path)];
  if (node is YamlScalar) return node.value;
  return node;
}

/// Parses [text] as YAML (duplicate keys are errors) into plain Dart values.
Object? parseYaml(String text, String path) {
  try {
    return plain(loadYaml(text, sourceUrl: Uri.file(path)), path);
  } on YamlException catch (e) {
    throw ContentFormatException(path, e.message);
  }
}

/// Reads and parses the YAML file at [root]/[path].
Object? readYaml(Directory root, String path) =>
    parseYaml(File('${root.path}/$path').readAsStringSync(), path);

/// Returns [value] with every map's keys sorted, recursively.
Object? sortKeys(Object? value) {
  if (value is Map) {
    final keys = value.keys.cast<String>().toList()..sort();
    return {for (final k in keys) k: sortKeys(value[k])};
  }
  if (value is List) return [for (final v in value) sortKeys(v)];
  return value;
}

const _encoder = JsonEncoder.withIndent('  ');

/// Deterministic JSON: sorted keys, 2-space indent, trailing newline.
String canonicalJson(Object? value) => '${_encoder.convert(sortKeys(value))}\n';

/// Compact deterministic JSON (the input of [sha256Hex] for hashes).
String compactJson(Object? value) => jsonEncode(sortKeys(value));

/// Lower-case hex SHA-256 of the UTF-8 bytes of [text].
String sha256Hex(String text) => sha256.convert(utf8.encode(text)).toString();

/// Lower-case hex SHA-256 of [bytes].
String sha256Bytes(List<int> bytes) => sha256.convert(bytes).toString();

/// A 64-character lower-case hex hash.
final RegExp kHashPattern = RegExp(r'^[0-9a-f]{64}$');

/// The nearest ancestor of [start] (inclusive) that contains `docs/specs`.
Directory? findRepoRoot(Directory start) {
  var current = start.absolute;
  while (true) {
    if (Directory('${current.path}/docs/specs').existsSync()) return current;
    final parent = current.parent;
    if (parent.path == current.path) return null;
    current = parent;
  }
}
