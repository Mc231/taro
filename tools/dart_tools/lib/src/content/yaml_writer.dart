/// A small deterministic YAML emitter for the files `translate` writes.
///
/// Maps keep insertion order; strings with a line break become literal
/// blocks (`|-`), long single-line strings folded blocks (`>-`, one line so
/// nothing is re-folded), everything else double-quoted JSON strings. The
/// output parses back to exactly the input (tested).
library;

import 'dart:convert';

bool _blockSafe(String s) =>
    s.isNotEmpty &&
    s.trim() == s &&
    !s.contains('\r') &&
    !s.contains('\t') &&
    !s.split('\n').any((l) => l != l.trimRight() || l.startsWith(' ')) &&
    !s.runes.any((r) => r < 0x20 && r != 0x0A || r == 0xFEFF);

void _scalar(StringBuffer out, Object? value, String indent) {
  if (value is String) {
    if (value.contains('\n') && _blockSafe(value)) {
      out.writeln('|-');
      for (final line in value.split('\n')) {
        out.writeln(line.isEmpty ? '' : '$indent  $line');
      }
    } else if (value.length > 60 && _blockSafe(value)) {
      out
        ..writeln('>-')
        ..writeln('$indent  $value');
    } else {
      out.writeln(jsonEncode(value));
    }
  } else {
    out.writeln(jsonEncode(value));
  }
}

void _node(StringBuffer out, Object? value, String indent) {
  if (value is Map) {
    for (final MapEntry(:key, value: v) in value.entries) {
      out.write('$indent$key:');
      if (v is Map && v.isNotEmpty) {
        out.writeln();
        _node(out, v, '$indent  ');
      } else if (v is List && v.isNotEmpty) {
        out.writeln();
        _node(out, v, '$indent  ');
      } else if (v is Map) {
        out.writeln(' {}');
      } else if (v is List) {
        out.writeln(' []');
      } else {
        out.write(' ');
        _scalar(out, v, indent);
      }
    }
  } else if (value is List) {
    for (final item in value) {
      out.write('$indent-');
      if (item is Map || item is List) {
        out.writeln();
        _node(out, item, '$indent  ');
      } else {
        out.write(' ');
        _scalar(out, item, indent);
      }
    }
  }
}

/// Emits [document] (a map of maps, lists and scalars) as YAML, preceded
/// by [header] comment lines.
String toYaml(Map<String, Object?> document, {List<String> header = const []}) {
  final out = StringBuffer();
  for (final line in header) {
    out.writeln('# $line');
  }
  _node(out, document, '');
  return out.toString();
}
