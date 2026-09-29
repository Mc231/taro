import 'dart:convert';
import 'dart:io';

/// The Worker's exported OpenAPI document (`worker/openapi/openapi.json`,
/// `npm run openapi`), read from the monorepo.
final class OpenApiDocument {
  OpenApiDocument(this.json);

  /// Loads the document relative to `apps/taro/` (the test working
  /// directory).
  factory OpenApiDocument.load() => OpenApiDocument(
    jsonDecode(File('../../worker/openapi/openapi.json').readAsStringSync())
        as Map<String, dynamic>,
  );

  final Map<String, dynamic> json;

  Map<String, dynamic> get _schemas =>
      (json['components'] as Map<String, dynamic>)['schemas']
          as Map<String, dynamic>;

  /// The component schema [name].
  Map<String, dynamic> schema(String name) =>
      _schemas[name] as Map<String, dynamic>? ??
      (throw ArgumentError.value(name, 'name', 'no such schema'));

  /// Validates [value] against component [name]; returns the problems (empty
  /// when valid). With [strict], properties the schema does not declare are
  /// problems too (the client must not send fields the Worker ignores).
  List<String> validate(String name, Object? value, {bool strict = true}) {
    final problems = <String>[];
    _check(schema(name), value, r'$', problems, strict: strict);
    return problems;
  }

  void _check(
    Map<String, dynamic> schema,
    Object? value,
    String path,
    List<String> problems, {
    required bool strict,
  }) {
    final ref = schema[r'$ref'] as String?;
    if (ref != null) {
      return _check(
        this.schema(ref.split('/').last),
        value,
        path,
        problems,
        strict: strict,
      );
    }
    final oneOf = schema['oneOf'] as List<dynamic>?;
    if (oneOf != null) {
      final matches = oneOf.where((option) {
        final sub = <String>[];
        _check(
          option as Map<String, dynamic>,
          value,
          path,
          sub,
          strict: strict,
        );
        return sub.isEmpty;
      }).length;
      if (matches != 1) problems.add('$path matches $matches oneOf branches');
      return;
    }
    final type = schema['type'];
    final types = type is List
        ? type.cast<String>()
        : [if (type != null) '$type'];
    if (types.isNotEmpty && !types.any((t) => _isType(t, value))) {
      problems.add('$path is not ${types.join('|')}: $value');
      return;
    }
    final enumValues = schema['enum'] as List<dynamic>?;
    if (enumValues != null && !enumValues.contains(value)) {
      problems.add('$path = $value is not in $enumValues');
    }
    if (value is String) _checkString(schema, value, path, problems);
    if (value is Map<String, dynamic>) {
      _checkObject(schema, value, path, problems, strict: strict);
    }
    if (value is List) {
      final items = schema['items'] as Map<String, dynamic>?;
      for (var i = 0; i < value.length && items != null; i++) {
        _check(items, value[i], '$path[$i]', problems, strict: strict);
      }
    }
  }

  void _checkString(
    Map<String, dynamic> schema,
    String value,
    String path,
    List<String> problems,
  ) {
    final min = schema['minLength'] as int?;
    final max = schema['maxLength'] as int?;
    if (min != null && value.length < min) problems.add('$path too short');
    if (max != null && value.length > max) problems.add('$path too long');
    final pattern = schema['pattern'] as String?;
    if (pattern != null && !RegExp(pattern).hasMatch(value)) {
      problems.add('$path does not match $pattern');
    }
    final ok = switch (schema['format']) {
      'uuid' => RegExp(
        r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
        caseSensitive: false,
      ).hasMatch(value),
      'date-time' => DateTime.tryParse(value) != null && value.contains('T'),
      'date' => RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value),
      _ => true,
    };
    if (!ok) problems.add('$path is not a ${schema['format']}');
  }

  void _checkObject(
    Map<String, dynamic> schema,
    Map<String, dynamic> value,
    String path,
    List<String> problems, {
    required bool strict,
  }) {
    final properties =
        schema['properties'] as Map<String, dynamic>? ?? const {};
    for (final key in (schema['required'] as List<dynamic>? ?? const [])) {
      if (!value.containsKey(key)) problems.add('$path.$key is required');
    }
    for (final entry in value.entries) {
      final sub = properties[entry.key] as Map<String, dynamic>?;
      if (sub != null) {
        _check(
          sub,
          entry.value,
          '$path.${entry.key}',
          problems,
          strict: strict,
        );
      } else if (strict && schema['additionalProperties'] == null) {
        problems.add('$path.${entry.key} is not declared');
      }
    }
  }

  static bool _isType(String type, Object? value) => switch (type) {
    'string' => value is String,
    'integer' => value is int,
    'number' => value is num,
    'boolean' => value is bool,
    'object' => value is Map,
    'array' => value is List,
    'null' => value == null,
    _ => true,
  };
}
