/// `validate_tokens`: the 01 §14 contract checks over a [TokenSet]
/// (Phase 15 Sprint 15.1, moved from Phase 14.3; REVIEW.md K1–K11).
library;

import 'package:taro_dart_tools/src/tokens/contract.dart';
import 'package:taro_dart_tools/src/tokens/token_set.dart';
import 'package:taro_dart_tools/src/tokens/token_values.dart';

/// What to check a token set against (tests pass a smaller contract).
final class TokenContract {
  /// Creates a contract.
  const TokenContract({
    required this.names,
    this.contrastPairs = const [],
    this.typeRoles = const [],
    this.fontScripts = const [],
    this.checkConstraints = false,
  });

  /// The full 01 §14 contract.
  factory TokenContract.product() => TokenContract(
    names: kContractTokenNames,
    contrastPairs: kContrastPairs,
    typeRoles: kTypeRoles,
    fontScripts: kFontScripts,
    checkConstraints: true,
  );

  /// Every name that must exist; no other name may.
  final List<String> names;

  /// Pairs checked in every mode.
  final List<ContrastPair> contrastPairs;

  /// `type.*` roles whose properties and `font.family.{role}.*` are checked.
  final List<String> typeRoles;

  /// Scripts every `font.family.{role}` must cover.
  final List<String> fontScripts;

  /// Whether the 01 §14 value constraints (sizes, gaps, targets) apply.
  final bool checkConstraints;
}

/// Names missing from [set] or not in [contract], as messages.
List<String> checkNames(TokenSet set, TokenContract contract) {
  final expected = contract.names.toSet();
  return [
    for (final name in contract.names)
      if (!set.tokens.containsKey(name)) '$name: missing (01 §14)',
    for (final name in set.tokens.keys)
      if (!expected.contains(name)) '$name: unknown name (not in 01 §14)',
  ];
}

/// Every check of `validate_tokens`; an empty list means the file passes.
List<String> validateTokens(TokenSet set, TokenContract contract) {
  final issues = <String>[...checkNames(set, contract)];

  void guard(void Function() check) {
    try {
      check();
    } on TokenException catch (e) {
      issues.add(e.message);
    }
  }

  // Every token resolves and parses in every mode.
  for (final token in set.tokens.values) {
    for (final mode in set.modes) {
      guard(() => _checkType(token, set.resolve(token.name, mode), mode));
    }
  }

  // Colours are defined per mode (01 §14.1); TokenSet.parse already rejects
  // a moded token with a missing mode.
  for (final token in set.tokens.values) {
    if (token.type == 'color' &&
        !token.isModed &&
        TokenSet.aliasOf(token.value) == null) {
      issues.add('${token.name}: no per-mode values');
    }
  }

  // Reduced motion on every motion.* token (01 §14.4).
  for (final token in set.tokens.values) {
    if (!token.name.startsWith('motion.')) continue;
    if (token.reducedMotion == null) {
      issues.add('${token.name}: no \$extensions["$kReducedMotionExtension"]');
    } else {
      guard(() => _checkType(token, token.reducedMotion, 'reducedMotion'));
    }
  }

  // Haptic values are ones TaroHaptics can play.
  for (final token in set.tokens.values) {
    if (token.name.startsWith('haptic.') &&
        !kHapticValues.contains(token.value)) {
      issues.add(
        '${token.name}: "${token.value}" is not one of '
        '${kHapticValues.join('|')}',
      );
    }
  }

  // Type roles: every property, and font.family.{role}.{script} complete.
  for (final role in contract.typeRoles) {
    final token = set.tokens['type.$role'];
    if (token == null) continue;
    final value = token.value;
    if (value is! Map<String, Object?>) {
      issues.add('type.$role: value must be an object');
      continue;
    }
    for (final property in kTypeProperties) {
      if (!value.containsKey(property)) {
        issues.add('type.$role: no $property (01 §14.2)');
      }
    }
    for (final script in contract.fontScripts) {
      if (!set.tokens.containsKey('font.family.$role.$script')) {
        issues.add('font.family.$role.$script: missing (01 §14.2)');
      }
    }
  }

  if (contract.checkConstraints) guard(() => issues.addAll(_constraints(set)));

  for (final mode in set.modes) {
    for (final pair in contract.contrastPairs) {
      guard(() {
        final ratio = contrastRatio(set, pair, mode);
        if (ratio + 1e-9 < pair.minimum) {
          issues.add(
            '${pair.foreground} on ${pair.background} ($mode): '
            '${ratio.toStringAsFixed(2)} < ${dartNum(pair.minimum)} '
            '(${pair.rule})',
          );
        }
      });
    }
  }
  return issues;
}

/// The contrast ratio of [pair] in [mode].
double contrastRatio(TokenSet set, ContrastPair pair, String mode) {
  final fg = TokenColor.parse(
    set.resolve(pair.foreground, mode),
    pair.foreground,
  );
  final bg = TokenColor.parse(
    set.resolve(pair.background, mode),
    pair.background,
  );
  return fg.contrastOn(bg);
}

void _checkType(DesignToken token, Object? value, String mode) {
  final where = '${token.name} ($mode)';
  switch (token.type) {
    case 'color':
      TokenColor.parse(value, where);
    case 'dimension':
      parseDimension(value, where);
    case 'number':
      parseNumber(value, where);
    case 'duration':
      parseDurationMicros(value, where);
    case 'cubicBezier':
      parseCubicBezier(value, where);
    case 'shadow':
      parseShadow(value, where);
    case 'fontWeight':
      parseFontWeight(value, where);
    case 'fontFamily' || 'string':
      if (value is! String || value.isEmpty) {
        throw TokenException('$where: must be a non-empty string');
      }
    case 'typography':
      if (value is! Map<String, Object?>) {
        throw TokenException('$where: typography must be an object');
      }
      final family = value['fontFamily'];
      if (family is! String || family.isEmpty) {
        throw TokenException('$where: fontFamily must be a string');
      }
      parseDimension(value['fontSize'], '$where.fontSize');
      parseFontWeight(value['fontWeight'], '$where.fontWeight');
      parseDimension(value['lineHeight'], '$where.lineHeight');
      parseDimension(value['letterSpacing'] ?? 0, '$where.letterSpacing');
    default:
      throw TokenException('$where: unsupported \$type "${token.type}"');
  }
}

List<String> _constraints(TokenSet set) {
  final issues = <String>[];
  final mode = set.modes.first;

  double dim(String name) => parseDimension(set.resolve(name, mode), name);

  double typeValue(String role, String property) {
    final value = set.resolve('type.$role', mode);
    if (value is! Map<String, Object?>) {
      throw TokenException('type.$role: value must be an object');
    }
    return parseDimension(value[property], 'type.$role.$property');
  }

  void atLeast(String what, double value, double minimum, String rule) {
    if (value < minimum) {
      issues.add('$what: ${dartNum(value)} < ${dartNum(minimum)} ($rule)');
    }
  }

  atLeast('type.body.fontSize', typeValue('body', 'fontSize'), 16, '01 §14.2');
  atLeast(
    'type.caption.fontSize',
    typeValue('caption', 'fontSize'),
    12,
    '01 §14.2',
  );
  atLeast(
    'type.bodyReading line height ratio',
    typeValue('bodyReading', 'lineHeight') /
        typeValue('bodyReading', 'fontSize'),
    1.5,
    '01 §14.2',
  );
  atLeast('space.adGap', dim('space.adGap'), 16, 'RC59');
  atLeast('layout.gutter', dim('layout.gutter'), 16, '01 §14.3');
  if (dim('size.touchTarget.min') != 48) {
    issues.add('size.touchTarget.min: must be 48 (01 §14.3)');
  }
  return issues;
}
