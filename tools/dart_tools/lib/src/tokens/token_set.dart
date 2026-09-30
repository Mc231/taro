/// The DTCG token file as a flat, ordered set of [DesignToken]s with modes
/// (`$extensions["taro.modes"]`), reduced-motion values
/// (`$extensions["taro.reducedMotion"]`) and alias resolution.
library;

/// The extension key for per-mode values (and the declared mode list).
const String kModesExtension = 'taro.modes';

/// The extension key for reduced-motion values on `motion.*` tokens.
const String kReducedMotionExtension = 'taro.reducedMotion';

/// Token types whose value must be given for every mode.
const Set<String> kModedTypes = {'color'};

/// A malformed token file or an unresolvable token.
final class TokenException implements Exception {
  /// Creates the exception.
  const TokenException(this.message);

  /// What is wrong, prefixed with the token name where there is one.
  final String message;

  @override
  String toString() => message;
}

/// One token (a JSON object with a `$value`).
final class DesignToken {
  /// Creates a token.
  const DesignToken({
    required this.name,
    required this.type,
    required this.value,
    this.modes,
    this.reducedMotion,
    this.description,
  });

  /// Dot path, e.g. `color.bg.canvas`.
  final String name;

  /// `$type` (own or inherited from a group).
  final String type;

  /// `$value`.
  final Object? value;

  /// Per-mode values, or null when the token is the same in every mode.
  final Map<String, Object?>? modes;

  /// The reduced-motion `$value`, when given.
  final Object? reducedMotion;

  /// `$description`.
  final String? description;

  /// The path segments.
  List<String> get path => name.split('.');

  /// Whether the value differs per mode.
  bool get isModed => modes != null;

  /// The raw value in [mode] (the default value when not moded).
  Object? rawIn(String mode) => modes == null ? value : modes![mode];
}

/// All tokens of one file, in document order.
final class TokenSet {
  TokenSet._(this.modes, this.tokens);

  /// Parses a decoded DTCG document. Throws [TokenException] on a missing
  /// mode list, a token without `$type`, a moded token missing a declared
  /// mode, or a colour without per-mode values.
  factory TokenSet.parse(Object? json) {
    if (json is! Map<String, Object?>) {
      throw const TokenException('top level must be a JSON object');
    }
    final declared = _extensions(json, '<root>')[kModesExtension];
    if (declared is! List ||
        declared.isEmpty ||
        declared.any((m) => m is! String)) {
      throw const TokenException(
        '<root>: \$extensions["$kModesExtension"] must list the modes',
      );
    }
    final modes = List<String>.unmodifiable(declared.cast<String>());
    final tokens = <String, DesignToken>{};
    _walk(json, const [], null, modes, tokens);
    if (tokens.isEmpty) throw const TokenException('no tokens found');
    return TokenSet._(modes, Map.unmodifiable(tokens));
  }

  /// Declared modes, e.g. `[light, dark]`.
  final List<String> modes;

  /// Tokens by name, in document order.
  final Map<String, DesignToken> tokens;

  /// The token called [name]; throws when there is none.
  DesignToken operator [](String name) {
    final token = tokens[name];
    if (token == null) throw TokenException('unknown token "$name"');
    return token;
  }

  /// The value of [name] in [mode] with every alias (`{a.b}`) resolved,
  /// including aliases nested in composite values. Throws on an unknown
  /// alias target or an alias cycle.
  Object? resolve(String name, String mode) =>
      _resolveToken(name, mode, const []);

  /// Resolves [value] (which may itself be or contain aliases) in [mode].
  Object? resolveValue(Object? value, String mode, {String owner = ''}) =>
      _resolveValue(value, mode, [if (owner.isNotEmpty) owner]);

  /// The alias target of [value] (`{a.b}` → `a.b`), or null.
  static String? aliasOf(Object? value) {
    if (value is! String) return null;
    final m = RegExp(r'^\{([^{}]+)\}$').firstMatch(value.trim());
    return m?.group(1);
  }

  Object? _resolveToken(String name, String mode, List<String> stack) {
    if (stack.contains(name)) {
      throw TokenException('alias cycle: ${[...stack, name].join(' -> ')}');
    }
    final token = tokens[name];
    if (token == null) {
      final from = stack.isEmpty ? '' : '${stack.last}: ';
      throw TokenException('${from}alias to unknown token "$name"');
    }
    return _resolveValue(token.rawIn(mode), mode, [...stack, name]);
  }

  Object? _resolveValue(Object? value, String mode, List<String> stack) {
    final alias = aliasOf(value);
    if (alias != null) return _resolveToken(alias, mode, stack);
    if (value is Map<String, Object?>) {
      return {
        for (final e in value.entries)
          e.key: _resolveValue(e.value, mode, stack),
      };
    }
    if (value is List) {
      return [for (final v in value) _resolveValue(v, mode, stack)];
    }
    return value;
  }

  static Map<String, Object?> _extensions(
    Map<String, Object?> node,
    String at,
  ) {
    final ext = node[r'$extensions'];
    if (ext == null) return const {};
    if (ext is! Map<String, Object?>) {
      throw TokenException('$at: \$extensions must be an object');
    }
    return ext;
  }

  static void _walk(
    Map<String, Object?> node,
    List<String> path,
    String? inheritedType,
    List<String> modes,
    Map<String, DesignToken> out,
  ) {
    final groupType = node[r'$type'] as String? ?? inheritedType;
    for (final MapEntry(:key, :value) in node.entries) {
      if (key.startsWith(r'$')) continue;
      if (key.contains('.') || key.contains('{') || key.contains('}')) {
        throw TokenException('${[...path, key].join('.')}: invalid name');
      }
      final childPath = [...path, key];
      final name = childPath.join('.');
      if (value is! Map<String, Object?>) {
        throw TokenException('$name: must be a token or a group');
      }
      if (value.containsKey(r'$value')) {
        out[name] = _token(value, name, groupType, modes);
      } else {
        _walk(value, childPath, groupType, modes, out);
      }
    }
  }

  static DesignToken _token(
    Map<String, Object?> node,
    String name,
    String? inheritedType,
    List<String> modes,
  ) {
    final type = node[r'$type'] as String? ?? inheritedType;
    if (type == null) throw TokenException('$name: no \$type');
    final ext = _extensions(node, name);
    final rawModes = ext[kModesExtension];
    Map<String, Object?>? byMode;
    if (rawModes != null) {
      if (rawModes is! Map<String, Object?>) {
        throw TokenException('$name: "$kModesExtension" must be an object');
      }
      for (final mode in modes) {
        if (!rawModes.containsKey(mode)) {
          throw TokenException('$name: missing mode "$mode"');
        }
      }
      for (final mode in rawModes.keys) {
        if (!modes.contains(mode)) {
          throw TokenException('$name: undeclared mode "$mode"');
        }
      }
      byMode = {for (final mode in modes) mode: rawModes[mode]};
    } else if (kModedTypes.contains(type) &&
        TokenSet.aliasOf(node[r'$value']) == null) {
      throw TokenException(
        '$name: missing modes (every $type needs ${modes.join(' and ')})',
      );
    }
    final reduced = ext[kReducedMotionExtension];
    Object? reducedValue;
    if (reduced != null) {
      if (reduced is! Map<String, Object?> || !reduced.containsKey(r'$value')) {
        throw TokenException(
          '$name: "$kReducedMotionExtension" needs a \$value',
        );
      }
      final reducedType = reduced[r'$type'] as String? ?? type;
      if (reducedType != type) {
        throw TokenException(
          '$name: reduced-motion \$type "$reducedType" differs from "$type"',
        );
      }
      reducedValue = reduced[r'$value'];
    }
    return DesignToken(
      name: name,
      type: type,
      value: node[r'$value'],
      modes: byMode,
      reducedMotion: reducedValue,
      description: node[r'$description'] as String?,
    );
  }
}
