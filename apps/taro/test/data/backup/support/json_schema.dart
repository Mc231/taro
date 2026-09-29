import 'dart:convert';
import 'dart:io';

/// The app's copy of the frozen backup schema, read relative to
/// `apps/taro/` (the test working directory).
const String kAppSchemaPath = 'lib/data/backup/backup_schema_v1.json';

/// The canonical schema in the monorepo.
const String kSpecSchemaPath = '../../docs/specs/backup_schema_v1.json';

/// The golden fixture of this app, and the one `taro_core` pins its
/// canonicalisation with.
const String kAppFixturePath = 'test/fixtures/backup_v1_sample.json';

/// `taro_core`'s golden fixture.
const String kCoreFixturePath =
    '../../packages/taro_core/test/src/logic/fixtures/backup_v1_sample.json';

/// The known checksum of the golden fixture's `data`.
const String kFixtureChecksum =
    'a83d19893d77cfdfb279fd3d3999a52b03b1115d50dcd35e400ee96d91752389';

/// A JSON Schema (2020-12) checker for the keywords
/// `backup_schema_v1.json` uses: `$ref` to `#/$defs/…`, `type` (single or
/// list), `const`, `enum`, `anyOf`, `required`, `properties`,
/// `additionalProperties: false`, `items`, `minItems`, `maxItems`,
/// `maxLength` (code points), `pattern` and `format: uuid | date-time`.
final class BackupJsonSchema {
  BackupJsonSchema(this.json);

  /// Loads the app's copy.
  factory BackupJsonSchema.load() => BackupJsonSchema(
    jsonDecode(File(kAppSchemaPath).readAsStringSync()) as Map<String, Object?>,
  );

  final Map<String, Object?> json;

  static const Set<String> _known = {
    r'$schema',
    r'$id',
    r'$defs',
    r'$ref',
    'title',
    'description',
    'type',
    'const',
    'enum',
    'anyOf',
    'required',
    'properties',
    'additionalProperties',
    'items',
    'minItems',
    'maxItems',
    'maxLength',
    'pattern',
    'format',
  };

  static final RegExp _uuid = RegExp(
    '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-'
    r'[0-9a-fA-F]{12}$',
  );

  /// Every keyword of the schema that this checker does not implement
  /// (empty: the checker covers the whole schema).
  List<String> unknownKeywords() {
    final out = <String>[];
    void walk(Object? node, String path, {bool inProperties = false}) {
      if (node is List) {
        for (var i = 0; i < node.length; i++) {
          walk(node[i], '$path[$i]');
        }
      }
      if (node is! Map<String, Object?>) return;
      for (final e in node.entries) {
        final isKeyword = !inProperties;
        if (isKeyword && !_known.contains(e.key)) out.add('$path.${e.key}');
        final childIsMap = e.key == 'properties' || e.key == r'$defs';
        walk(
          e.value,
          '$path.${e.key}',
          inProperties: isKeyword && childIsMap,
        );
      }
    }

    walk(json, r'$');
    return out;
  }

  /// The problems of [value] against the whole schema (empty when valid).
  List<String> validate(Object? value) {
    final problems = <String>[];
    _check(json, value, r'$', problems);
    return problems;
  }

  Map<String, Object?> _def(String ref) {
    final name = ref.replaceFirst(r'#/$defs/', '');
    return (json[r'$defs']! as Map<String, Object?>)[name]!
        as Map<String, Object?>;
  }

  void _check(
    Map<String, Object?> schema,
    Object? value,
    String path,
    List<String> problems,
  ) {
    final ref = schema[r'$ref'] as String?;
    if (ref != null) return _check(_def(ref), value, path, problems);
    final anyOf = schema['anyOf'] as List<Object?>?;
    if (anyOf != null) {
      final ok = anyOf.any((option) {
        final sub = <String>[];
        _check(option! as Map<String, Object?>, value, path, sub);
        return sub.isEmpty;
      });
      if (!ok) problems.add('$path matches no anyOf branch');
      return;
    }
    if (schema.containsKey('const') && schema['const'] != value) {
      problems.add('$path must be ${schema['const']}');
    }
    final enumValues = schema['enum'] as List<Object?>?;
    if (enumValues != null && !enumValues.contains(value)) {
      problems.add('$path = $value is not in $enumValues');
    }
    final type = schema['type'];
    final types = type is List ? type.cast<String>() : [?type as String?];
    if (types.isNotEmpty && !types.any((t) => _isType(t, value))) {
      problems.add('$path is not ${types.join('|')}');
      return;
    }
    switch (value) {
      case final Map<String, Object?> map:
        _object(schema, map, path, problems);
      case final List<Object?> list:
        _array(schema, list, path, problems);
      case final String s:
        _string(schema, s, path, problems);
    }
  }

  void _object(
    Map<String, Object?> schema,
    Map<String, Object?> map,
    String path,
    List<String> problems,
  ) {
    final props = schema['properties'] as Map<String, Object?>? ?? const {};
    for (final r in (schema['required'] as List<Object?>?) ?? const []) {
      if (!map.containsKey(r)) problems.add('$path.$r is required');
    }
    for (final e in map.entries) {
      final sub = props[e.key] as Map<String, Object?>?;
      if (sub == null) {
        if (schema['additionalProperties'] == false) {
          problems.add('$path.${e.key} is not allowed');
        }
        continue;
      }
      _check(sub, e.value, '$path.${e.key}', problems);
    }
  }

  void _array(
    Map<String, Object?> schema,
    List<Object?> list,
    String path,
    List<String> problems,
  ) {
    final min = schema['minItems'] as int?;
    final max = schema['maxItems'] as int?;
    if (min != null && list.length < min) problems.add('$path < $min items');
    if (max != null && list.length > max) problems.add('$path > $max items');
    final items = schema['items'] as Map<String, Object?>?;
    if (items == null) return;
    for (var i = 0; i < list.length; i++) {
      _check(items, list[i], '$path[$i]', problems);
    }
  }

  void _string(
    Map<String, Object?> schema,
    String s,
    String path,
    List<String> problems,
  ) {
    final maxLength = schema['maxLength'] as int?;
    if (maxLength != null && s.runes.length > maxLength) {
      problems.add('$path is longer than $maxLength');
    }
    final pattern = schema['pattern'] as String?;
    if (pattern != null && !RegExp(pattern).hasMatch(s)) {
      problems.add('$path does not match $pattern');
    }
    switch (schema['format']) {
      case 'uuid' when !_uuid.hasMatch(s):
        problems.add('$path is not a uuid');
      case 'date-time' when DateTime.tryParse(s) == null:
        problems.add('$path is not a date-time');
    }
  }

  static bool _isType(String type, Object? value) => switch (type) {
    'object' => value is Map,
    'array' => value is List,
    'string' => value is String,
    'boolean' => value is bool,
    'integer' => value is int,
    'number' => value is num,
    'null' => value == null,
    _ => throw ArgumentError.value(type, 'type'),
  };
}
